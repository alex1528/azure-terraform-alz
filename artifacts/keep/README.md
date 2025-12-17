# Baseline Terraform Plans (versioned)

This folder stores a minimal, curated set of long-lived, versioned Terraform plan artifacts for auditing and reproducibility.

## Naming Convention
- `baseline-<topic>-YYYY-MM-DD.plan`
  - Examples: `baseline-defender-2025-12-17.plan`

## Usage
- Generate a plan and save directly here:
  - `terraform plan -out "artifacts/keep/baseline-defender-2025-12-17.plan"`
- Apply exactly this plan when needed:
  - `terraform apply "artifacts/keep/baseline-defender-2025-12-17.plan"`

## Guidelines
- Keep only essential baselines (aim for 1-3 files).
- Update the baseline after significant posture changes.
- Do NOT store transient plans here; use `plans/` (ignored) for temporary outputs.
