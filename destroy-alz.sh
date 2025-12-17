#!/bin/bash
# destroy-alz.sh - Azure Landing Zone Terraform Destroy Script
#
# Purpose:
#   One-click teardown of all resources created by this ALZ Terraform configuration.
#   Performs safe checks, previews the destroy plan, and executes destroy.
#
# Usage:
#   ./destroy-alz.sh                 # Preview destroy, prompt to confirm
#   ./destroy-alz.sh --auto-approve  # One-click destroy without prompt
#   ./destroy-alz.sh --verbose       # Stream live output
#   ./destroy-alz.sh --full          # Keep full logs on disk
#
# Requirements:
#   - Run in the same directory as your Terraform config (this repo root)
#   - Use the same backend/workspace as your apply stage
#   - terraform.tfvars present and consistent

set -e

VERBOSE=false
FULL=false
AUTO_APPROVE=false
BACKEND_CONF="backend.conf"

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true; shift ;;
    --full)
      FULL=true; shift ;;
    --auto-approve)
      AUTO_APPROVE=true; shift ;;
    *)
      shift ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
  local level=$1; local msg=$2
  case $level in
    INFO)    echo -e "${BLUE}ℹ️  ${msg}${NC}" ;;
    SUCCESS) echo -e "${GREEN}✅ ${msg}${NC}" ;;
    WARNING) echo -e "${YELLOW}⚠️  ${msg}${NC}" ;;
    ERROR)   echo -e "${RED}❌ ${msg}${NC}" ;;
  esac
}

echo "🗑️  Azure Landing Zone Terraform Destroy"
echo "======================================"
echo ""

# Prechecks
print_status INFO "Checking prerequisites..."
if ! command -v az &> /dev/null; then
  print_status ERROR "Azure CLI is not installed. Install it first."; exit 1
fi
if ! az account show &> /dev/null; then
  print_status ERROR "Not logged into Azure CLI. Run 'az login' first."; exit 1
fi
print_status SUCCESS "Azure CLI ready"

if ! command -v terraform &> /dev/null; then
  print_status ERROR "Terraform is not installed. Install it first."; exit 1
fi
TFVER=$(terraform version -json | jq -r '.terraform_version')
print_status SUCCESS "Terraform ${TFVER} detected"

if [ ! -f "terraform.tfvars" ]; then
  print_status ERROR "terraform.tfvars not found in current directory"; exit 1
fi
print_status SUCCESS "terraform.tfvars found"

SUB_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)
print_status INFO "Current subscription: ${SUB_NAME} (${SUB_ID})"

# Init with backend if present
print_status INFO "Initializing Terraform backend..."
INIT_EXIT=0
if [ -f "$BACKEND_CONF" ]; then
  if terraform init -no-color -backend-config="$BACKEND_CONF" &> /dev/null; then
    print_status SUCCESS "Terraform init (with backend.conf)"
  else
    INIT_EXIT=$?
  fi
else
  if terraform init -no-color &> /dev/null; then
    print_status SUCCESS "Terraform init"
  else
    INIT_EXIT=$?
  fi
fi
if [ $INIT_EXIT -ne 0 ]; then
  print_status ERROR "Terraform init failed. Verify backend configuration."
  terraform init -no-color
  exit 1
fi

# Destroy plan preview
PLAN_LOG="terraform_destroy_plan_$(date +%Y%m%d_%H%M%S).log"
print_status INFO "Creating destroy plan preview..."
set +e
if [ "$VERBOSE" = true ] || [ "$FULL" = true ]; then
  set -o pipefail
  terraform plan -no-color -destroy -var-file=terraform.tfvars 2>&1 | tee "$PLAN_LOG"
  PLAN_EXIT=${PIPESTATUS[0]}
  set +o pipefail
else
  terraform plan -no-color -destroy -var-file=terraform.tfvars > "$PLAN_LOG" 2>&1
  PLAN_EXIT=$?
fi
set -e

if [ $PLAN_EXIT -ne 0 ]; then
  print_status ERROR "Destroy plan preview failed"
  print_status INFO "Last 80 lines from ${PLAN_LOG}:"
  tail -n 80 "$PLAN_LOG" 2>/dev/null || true
  print_status INFO "Full log saved to ${PLAN_LOG}"
  exit 1
fi
print_status SUCCESS "Destroy plan preview completed"

if [ "$AUTO_APPROVE" != true ]; then
  echo ""
  echo "This will destroy all Terraform-managed resources in the current state."
  read -r -p "Type 'destroy' to proceed: " CONFIRM
  if [ "$CONFIRM" != "destroy" ]; then
    print_status WARNING "Destroy canceled by user"
    exit 0
  fi
fi

# Execute destroy
DESTROY_LOG="terraform_destroy_$(date +%Y%m%d_%H%M%S).log"
print_status INFO "Executing terraform destroy..."
CMD=(terraform destroy -no-color -var-file=terraform.tfvars)
if [ "$AUTO_APPROVE" = true ]; then
  CMD+=( -auto-approve )
fi

set +e
if [ "$VERBOSE" = true ] || [ "$FULL" = true ]; then
  set -o pipefail
  "${CMD[@]}" 2>&1 | tee "$DESTROY_LOG"
  DESTROY_EXIT=${PIPESTATUS[0]}
  set +o pipefail
else
  "${CMD[@]}" > "$DESTROY_LOG" 2>&1
  DESTROY_EXIT=$?
fi
set -e

if [ $DESTROY_EXIT -eq 0 ]; then
  print_status SUCCESS "Terraform destroy completed"
  if [ "$FULL" = true ]; then
    print_status INFO "Logs saved to ${DESTROY_LOG}"
  else
    rm -f "$PLAN_LOG" "$DESTROY_LOG" 2>/dev/null || true
  fi
else
  print_status ERROR "Terraform destroy failed"
  print_status INFO "Last 80 lines from ${DESTROY_LOG}:"
  tail -n 80 "$DESTROY_LOG" 2>/dev/null || true
  print_status INFO "Full log saved to ${DESTROY_LOG}"
  exit 1
fi

# Guidance for special cases
echo ""
print_status INFO "Notes:"
echo " - If policies/locks prevent deletion, set policy_enforcement_mode=DoNotEnforce and retry."
echo " - Ensure you are using the same workspace/backend as apply."
echo " - For selective cleanup, use 'terraform destroy -target=...' on specific modules/resources."