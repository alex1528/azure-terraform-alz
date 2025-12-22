$ErrorActionPreference = "Stop"

function Get-UpnsFromTerraform {
  try {
    $json = terraform -chdir="d:\azure-terraform-alz" output -json | ConvertFrom-Json
    $upns = @()
    if ($json.iam_user_upn) { $upns += $json.iam_user_upn.value }
    if ($json.alz_group_user_upns) {
      $json.alz_group_user_upns.value.psobject.Properties | ForEach-Object {
        if ($_.Value -and $_.Value.Trim().Length -gt 0) { $upns += $_.Value }
      }
    }
    return $upns | Sort-Object -Unique
  } catch {
    return @()
  }
}

function Get-UpnsFromGraphFallback {
  $filter = "startswith(userPrincipalName,'bingohr') or startswith(displayName,'ALZ Standard User') or startswith(displayName,'BingoHR')"
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
function New-TempPassword {
  param([int]$Length = 18)
  $upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
  $lower = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
  $digits = "0123456789".ToCharArray()
  $special = "!@#-_?".ToCharArray()
  $all = $upper + $lower + $digits + $special
  $rand = New-Object System.Random
  $chars = @()
  # Ensure complexity by including at least one from each set
  $chars += $upper[$rand.Next($upper.Length)]
  $chars += $lower[$rand.Next($lower.Length)]
  $chars += $digits[$rand.Next($digits.Length)]
  $chars += $special[$rand.Next($special.Length)]
  for ($i = $chars.Count; $i -lt $Length; $i++) { $chars += $all[$rand.Next($all.Length)] }
  -join $chars
}

$resetResults = @()

foreach ($upn in $upns) {
  $tempPassword = New-TempPassword
  az ad user update --id $upn --password $tempPassword --force-change-password-next-sign-in true | Out-Null
  $resetResults += [PSCustomObject]@{ UPN = $upn; TempPassword = $tempPassword }
}

Write-Host "Done. Verifying..." -ForegroundColor Green
pwsh -NoProfile -File "d:\azure-terraform-alz\scripts\check-force-password-change.ps1"

Write-Host "\nTemporary passwords (use for first login, then change):" -ForegroundColor Yellow
$resetResults | Format-Table -AutoSize
