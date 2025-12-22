**Overview**
- This guide summarizes Azure RBAC roles used in this implementation, their scopes, typical usage, and verification examples. It clarifies "who has which permission at what scope" and provides copyable az CLI commands.

**Roles and Usage**
- **Reader**: Read-only access for audit, validation, and inspecting resource properties; used across multiple resource groups for non-ops groups.
- **Contributor**: Manage resources but cannot grant access; used on workload resource groups for day-to-day operations (nonprod/prod groups).
- **Virtual Machine Administrator Login**: Sign in to VMs with Entra ID and have administrator privileges (supports `sudo`); used for AAD SSH admin login to workload VMs.
- Deprecated (historical): **Virtual Machine User Login** (no admin privileges, cannot `sudo`). Replaced with Administrator Login on prod/nonprod VM scopes.
- **Monitoring Metrics Publisher**: Allows publishing metrics to Azure Monitor (typically assigned to VM managed identities or extension-related identities).

**Where It’s Implemented**
- RBAC overview and verification steps: see [README.md](README.md) and [VALIDATION_SCRIPTS_GUIDE.md](VALIDATION_SCRIPTS_GUIDE.md).
- Main RBAC assignment logic: [main.tf](main.tf)
  - Workload (nonprod/prod) Resource Groups → `Contributor`
  - Workload (nonprod/prod) VM scopes → `Virtual Machine Administrator Login`
  - Connectivity/Management/Identity/Decommissioned/Sandboxes resource groups → `Reader`
- Monitoring role assignment example: [modules/compute/main.tf](modules/compute/main.tf) (`Monitoring Metrics Publisher`).

**Scope Model**
- **Resource Group (RG) scope**: Used for most `Reader` and `Contributor` assignments. Follows least privilege; avoid subscription-level `Contributor` unless absolutely necessary.
- **VM resource scope**: Used for `Virtual Machine Administrator Login` to enable AAD SSH and `sudo` inside the VM.
- **Management Group scope**: Baseline `Reader` remains for portal browsing and audit. Platform-level role assignments can be controlled via parameters in [modules/core_policies](modules/core_policies).

**az CLI Examples**
- List a user’s role assignments on a given Resource Group
```powershell
# Query a user's RG roles by UPN or objectId
$subId="<subscriptionId>"
$rg="bingohr-nonprod-webmysql-eastasia-rg"
$assignee="<user_upn_or_objectId>"
az role assignment list --assignee $assignee --scope "/subscriptions/$subId/resourceGroups/$rg" --query "[].{Role:roleDefinitionName,Scope:scope}" -o table
```

- Grant `Reader` or `Contributor` on a Resource Group
```powershell
$subId="<subscriptionId>"
$rg="bingohr-prod-webmysql-eastasia-rg"
$assignee="<user_upn_or_objectId>"
# Grant Reader
az role assignment create --assignee $assignee --role "Reader" --scope "/subscriptions/$subId/resourceGroups/$rg"
# Grant Contributor
az role assignment create --assignee $assignee --role "Contributor" --scope "/subscriptions/$subId/resourceGroups/$rg"
```

- Grant `Virtual Machine Administrator Login` on a VM
```powershell
$subId="<subscriptionId>"
$rg="bingohr-nonprod-webmysql-eastasia-rg"
$vmName="bingohr-nonprod-web"
$assignee="<user_upn_or_objectId>"
az role assignment create --assignee $assignee --role "Virtual Machine Administrator Login" --scope "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/$vmName"
```

- Inspect role definition and IDs (avoid hardcoding)
```powershell
# Inspect built-in role definition (example: VM Administrator Login)
az role definition list --name "Virtual Machine Administrator Login" -o json
# List built-in role names and IDs
az role definition list --query "[].{Name:roleName,Id:name}" -o table
```

**Verification and Ops Guidelines**
- **Portal verification**: Resource → Access control (IAM) → Role assignments → Filter by user or role; confirm presence of `Reader`/`Contributor`/`Virtual Machine Administrator Login`. See [README.md](README.md).
- **CLI verification**: Use `az role assignment list` with `assignee` and `scope` as shown above.
- **SSH and sudo verification**: After AAD SSH login, `sudo -l` and `sudo whoami` should succeed (expect `root`). See [README.md](README.md) and [VALIDATION_SCRIPTS_GUIDE.md](VALIDATION_SCRIPTS_GUIDE.md).
- **Least privilege**: Prefer RG scope over higher scopes; avoid subscription or management group `Contributor` unless required.
- **Change records**: Capture plan snapshots and commits (e.g., `plan-summary-YYYYMMDD-HHMMSS.txt`) for audit and rollback.

**Notes**
- Difference between `Virtual Machine Administrator Login` and `Virtual Machine User Login`: the former supports admin elevation and `sudo`; the latter does not. This implementation uses Administrator Login on workload VM scopes.
- Monitoring and extensions: If managed identities need to publish metrics or access resources, grant appropriate roles (e.g., `Monitoring Metrics Publisher`) and follow [modules/compute/main.tf](modules/compute/main.tf).
- Storage access: For AAD-authenticated Blob access, grant `Storage Blob Data Contributor` on the storage account and ensure at least `Reader` on the RG that contains it. See usage details in [README.md](README.md).

**Reference Files**
- Main implementation and RBAC assignments: [main.tf](main.tf)
- Compute module and monitoring role: [modules/compute/main.tf](modules/compute/main.tf)
- Group RBAC model and verification: [README.md](README.md) / [README.zh-CN.md](README.zh-CN.md)
- Validation scripts guide and CLI checks: [VALIDATION_SCRIPTS_GUIDE.md](VALIDATION_SCRIPTS_GUIDE.md)