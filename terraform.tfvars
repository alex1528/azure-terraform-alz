# terraform.tfvars - Azure Landing Zone Configuration

# ============================================================================
# CORE ALZ CONFIGURATION
# ============================================================================

# Root management group name - this appears under the tenant root
root_management_group_name = "BingoHR ALZ"

# Prefix for naming resources (used in management group names and resource names)
resource_prefix = "bingohr"

# Organization name for consistent naming
org_name = "bingohr"

# Primary Azure region for resource deployments
location = "eastasia"

# ============================================================================
# SUBSCRIPTION ASSIGNMENTS (OPTIONAL)
# ============================================================================

# Replace these with actual subscription IDs or leave empty/null if not needed
connectivity_subscription_id = null
identity_subscription_id     = null
management_subscription_id   = null

# ============================================================================
# NETWORKING ARCHITECTURE CHOICE
# ============================================================================

# Choose your network architecture: 
# - "hub_spoke" for traditional hub and spoke (recommended for most scenarios)
# - "vwan" for Virtual WAN (recommended for multi-region, complex connectivity)
# - "none" for no connectivity resources
network_architecture = "hub_spoke"

# Deploy connectivity resources (VNet/Virtual WAN)
deploy_connectivity_resources = true

# ============================================================================
# HUB & SPOKE CONFIGURATION (when network_architecture = "hub_spoke")
# ============================================================================

# Hub virtual network address space
hub_vnet_address_space = ["10.100.0.0/22"]

# Hub subnets configuration
hub_subnets = {
  "snet-shared-services" = {
    address_prefixes = ["10.100.0.0/24"]
  }
  "snet-management" = {
    address_prefixes = ["10.100.1.0/24"]
  }
  "AzureBastionSubnet" = {
    address_prefixes = ["10.100.2.0/26"]
  }
  "AzureFirewallSubnet" = {
    address_prefixes = ["10.100.3.0/26"]
  }
}

# Deploy Azure Bastion for secure VM access (when using Hub & Spoke)
# Bastion allows you to access VMs without exposing them to the internet
deploy_azure_bastion = true

# ============================================================================
# VIRTUAL WAN CONFIGURATION (when network_architecture = "vwan")
# ============================================================================

# Virtual WAN name (optional, will be auto-generated if not provided)
virtual_wan_name = ""

# Virtual hub address prefix
virtual_hub_address_prefix = "10.100.0.0/24"

# Deploy optional gateways in Virtual WAN hub
deploy_express_route_gateway = false
deploy_vpn_gateway           = false

# ============================================================================
# MANAGEMENT GROUP CUSTOMIZATION (OPTIONAL)
# ============================================================================

# Custom names for the management groups (optional)
decommissioned_group_name = "Decommissioned"
landing_zones_group_name  = "Landing Zones"
platform_group_name       = "Platform"
sandboxes_group_name      = "Sandboxes"

# Landing Zones sub-groups
prod_group_name     = "Production"
non_prod_group_name = "Non-Production"

# Platform sub-groups
connectivity_group_name = "Connectivity"
identity_group_name     = "Identity"
management_group_name   = "Management"

# ============================================================================
# POLICY CONFIGURATION
# ============================================================================

# Deploy core security and compliance policies
deploy_core_policies = true

# Policy enforcement mode:
# - "DoNotEnforce" = Audit mode (recommended for initial deployment)
# - "Default" = Enforce mode (recommended for production)
policy_enforcement_mode = "DoNotEnforce"

# ============================================================================
# OPTIONAL MANAGEMENT RESOURCES
# ============================================================================

# Deploy Log Analytics Workspaces for centralized logging
deploy_log_analytics_workspace = true

# Deploy Azure Automation Account for management tasks
deploy_automation_account = true

# Deploy Data Collection Rules for Azure Monitor
deploy_data_collection_rules = false

# Deploy User Assigned Managed Identity
deploy_managed_identity = true

# ============================================================================
# COMPUTE RESOURCES (VIRTUAL MACHINE)
# ============================================================================

# Deploy VM instance (4 vCPU, 8GB RAM)
deploy_compute_resources = true

# Virtual machine size
# Options: Standard_B2s (2vCPU, 4GB - economical), Standard_D2s_v3 (2vCPU, 8GB - general purpose)
vm_size = "Standard_D2s_v3"

# Operating system: "linux" (Ubuntu 22.04) or "windows" (Windows Server 2022)
vm_os_type = "linux"

# VM administrator username
admin_username = "azureuser"

# VM administrator password (only used for Windows VMs)
# For production, consider using Azure Key Vault
admin_password = ""

# Path to SSH public key for Linux VM (ignored if generate_ssh_key = true)
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Generate SSH key pair via Terraform instead of using local key file
# Set to true to have Terraform generate a new SSH key (stored in state file)
# Set to false (default) to use existing local SSH key at ssh_public_key_path
generate_ssh_key = true

# Assign a public IP address to the VM
assign_public_ip = true

# Create new VNet for compute resources (set to false to use existing subnet)
create_compute_vnet = true

# ============================================================================
# AZURE MONITOR & LOGGING CONFIGURATION
# ============================================================================

# Enable Azure Monitor Agent on VMs for metrics collection
enable_azure_monitor = true

# ============================================================================
# RESOURCE TAGGING
# ============================================================================

# Default tags applied to all resources
tags = {
  Environment = "BingoHR-ALZ"
  Project     = "BingoHR-Azure-Landing-Zone"
  ManagedBy   = "Terraform"
  Framework   = "Azure-Landing-Zones"
  CostCenter  = "IT-Infrastructure"
  Owner       = "BHR-Platform-Team@bingohr.com"
  CreatedDate = "2025-12-16"
}