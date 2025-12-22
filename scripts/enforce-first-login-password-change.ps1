$ErrorActionPreference = "Stop"

function Get-UpnsFromTerraform {
  try {
    $json = terraform -chdir "d:\azure-terraform-alz" output -json | ConvertFrom-Json
    $upns = @()
    if ($json.iam_user_upn) { $upns += $json.iam_user_upn.value }
    if ($json.alz_group_user_upns) { $upns += $json.alz_group_user_upns.value.Values }
    return $upns | Sort-Object -Unique
  } catch {
    return @()
  }
}

function Get-UpnsFromGraphFallback {
  $filter = "startswith(userPrincipalName,'bingohr') or startswith(displayName,'ALZ Standard User') or contains(displayName,'BingoHR')"
  $upns = az ad user list --filter $filter --query "[].userPrincipalName" -o tsv 2>$null
  if (-not $upns) { return @() }
  return $upns
}

$upns = @()
$upns += Get-UpnsFromTerraform
$upns += Get-UpnsFromGraphFallback
$upns = $upns | Sort-Object -Unique

if (-not $upns -or $upns.Count -eq 0) {
  Write-Warning "No user UPNs found via Terraform outputs or Graph filter."
  exit 1
}

Write-Host "Enforcing forceChangePasswordNextSignIn=true for:" -ForegroundColor Cyan
$upns | ForEach-Object { Write-Host " - $_" }

$token = az account get-access-token --resource "https://graph.microsoft.com/" --query accessToken -o tsv

foreach ($upn in $upns) {
  $uri = "https://graph.microsoft.com/v1.0/users/$upn"
  $body = '{"passwordProfile": {"forceChangePasswordNextSignIn": true}}'
  az rest --method patch --headers "Authorization=Bearer $token" "Content-Type=application/json" --uri $uri --body $body | Out-Null
}

Write-Host "Done. Verifying..." -ForegroundColor Green
pwsh -NoProfile -File "d:\azure-terraform-alz\scripts\check-force-password-change.ps1"
