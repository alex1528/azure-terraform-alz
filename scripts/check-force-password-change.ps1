$ErrorActionPreference = "Stop"

$tfOut = terraform -chdir="d:\azure-terraform-alz" output -json | ConvertFrom-Json
$upns = @()
if ($tfOut.iam_user_upn) { $upns += $tfOut.iam_user_upn.value }
if ($tfOut.alz_group_user_upns) {
  $tfOut.alz_group_user_upns.value.psobject.Properties | ForEach-Object {
    if ($_.Value -and $_.Value.Trim().Length -gt 0) { $upns += $_.Value }
  }
}

Write-Host "Checking ForcePasswordChangeOnNextSignIn for:" -ForegroundColor Cyan
$upns | ForEach-Object { Write-Host " - $_" }

$token = az account get-access-token --resource "https://graph.microsoft.com/" --query accessToken -o tsv

$result = @()
foreach ($upn in $upns) {
  $uri = "https://graph.microsoft.com/v1.0/users/$upn`?`$select=passwordProfile"
  $json = az rest --method get --headers "Authorization=Bearer $token" --uri $uri
  $obj = $json | ConvertFrom-Json
  $result += [PSCustomObject]@{
    UPN = $upn
    ForceChangeOnNextSignIn = $obj.passwordProfile.forceChangePasswordNextSignIn
  }
}

$result | Format-Table -AutoSize
