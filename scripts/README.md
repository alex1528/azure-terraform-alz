# Validation Scripts

This folder contains helper scripts to validate Azure Bastion AAD SSH login enablement and NSG hardening.

## validate-bastion-aad-login.ps1

Validates that:
- `AADLoginForLinux` VM extension is present and `Succeeded` for target VMs
- NSG SSH rules allow from Bastion subnet CIDR and Azure platform IP `168.63.129.16`
- An explicit `Deny` rule exists for SSH from `Internet`

### Usage

```powershell
pwsh scripts/validate-bastion-aad-login.ps1 -Prefix "bingohr" -Region "eastasia" -BastionCidr "10.100.2.0/26"
```

Exit code is `0` on PASS, `1` on FAIL.

### Portal Verification (Bastion AAD)

For each VM (prod/nonprod web + mysql):
1. Azure Portal → Virtual machines → select VM
2. Click `Connect` → choose `Bastion`
3. Authentication type: select `Azure AD`
4. Username: `stduser@gdjiuyun.onmicrosoft.com`
5. Click `Connect` to initiate session
6. Confirm successful login prompt on the Bastion session

If login fails, re-run the validation script and check extension status and NSG rules.
