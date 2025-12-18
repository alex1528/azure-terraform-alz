param(
    [string]$Prefix = "bingohr",
    [string]$Region = "eastasia",
    [string]$ConnectivityRgName = $null,
    [string]$ComputeRgName = $null,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

function Write-Result {
    param([string]$Title,[string]$Status,[string]$Detail)
    $color = switch ($Status) {
        "OK" { 'Green' }
        "WARN" { 'Yellow' }
        default { 'Red' }
    }
    Write-Host ("[{0}] {1} - {2}" -f $Status,$Title,$Detail) -ForegroundColor $color
}

# Derive names
if (-not $ConnectivityRgName) { $ConnectivityRgName = "$Prefix-connectivity-$Region-rg" }
if (-not $ComputeRgName) { $ComputeRgName = "$Prefix-compute-$Region-rg" }
$HubVnetName = "$Prefix-hub-$Region-vnet"
$ComputeVnetName = "$Prefix-compute-$Region-vnet"
$BastionName = "$Prefix-hub-$Region-vnet-bastion"
$FirewallName = "$Prefix-hub-$Region-vnet-fw"

$fail = $false

Write-Host "Checking subscription and tenant..." -ForegroundColor Cyan
$acct = az account show --only-show-errors | ConvertFrom-Json
if ($acct -and $acct.id -and $acct.tenantId) {
    Write-Result -Title "Account" -Status "OK" -Detail ("sub: {0}, tenant: {1}" -f $acct.id,$acct.tenantId)
} else {
    Write-Result -Title "Account" -Status "FAIL" -Detail "Unable to read az account show"
    $fail = $true
}

# Identity / Management Groups presence
Write-Host "Checking management groups (identity, platform, landingzones)..." -ForegroundColor Cyan
$mgNames = @("$Prefix-identity","$Prefix-platform","$Prefix-landingzones")
foreach ($mg in $mgNames) {
    try {
        $mgObj = az account management-group show --name $mg --only-show-errors 2>$null | ConvertFrom-Json
        if ($mgObj -and $mgObj.name) { Write-Result -Title "MG:$mg" -Status "OK" -Detail "exists" }
        else { Write-Result -Title "MG:$mg" -Status "WARN" -Detail "not found" }
    } catch { Write-Result -Title "MG:$mg" -Status "WARN" -Detail "not found" }
}

# Network topology (hub/spoke)
Write-Host "Checking hub/spoke connectivity resources..." -ForegroundColor Cyan
try {
    $rg = az group show -n $ConnectivityRgName --only-show-errors | ConvertFrom-Json
    if ($rg) { Write-Result -Title "RG:$ConnectivityRgName" -Status "OK" -Detail "exists" } else { throw "rg missing" }
} catch { Write-Result -Title "RG:$ConnectivityRgName" -Status "FAIL" -Detail "missing"; $fail = $true }

try {
    $hub = az network vnet show -g $ConnectivityRgName -n $HubVnetName --only-show-errors | ConvertFrom-Json
    if ($hub) { Write-Result -Title "Hub VNet:$HubVnetName" -Status "OK" -Detail "exists" } else { throw "hub vnet missing" }
} catch { Write-Result -Title "Hub VNet:$HubVnetName" -Status "FAIL" -Detail "missing"; $fail = $true }

try {
    $bast = az network bastion show -g $ConnectivityRgName -n $BastionName --only-show-errors | ConvertFrom-Json
    if ($bast) { Write-Result -Title "Bastion:$BastionName" -Status "OK" -Detail "exists" } else { throw "bastion missing" }
} catch { Write-Result -Title "Bastion:$BastionName" -Status "WARN" -Detail "not found (optional)" }

try {
    $fw = az network firewall show -g $ConnectivityRgName -n $FirewallName --only-show-errors | ConvertFrom-Json
    if ($fw) { Write-Result -Title "Firewall:$FirewallName" -Status "OK" -Detail "exists" } else { throw "fw missing" }
} catch { Write-Result -Title "Firewall:$FirewallName" -Status "WARN" -Detail "not found (optional)" }

# Hybrid connectivity (VPN/ExpressRoute) - presence check, warn if none
try {
    $gw = az network vnet-gateway list -g $ConnectivityRgName --only-show-errors | ConvertFrom-Json
    if ($gw -and $gw.Count -gt 0) {
        $names = ($gw | ForEach-Object { $_.name }) -join ", "
        Write-Result -Title "VNet Gateway" -Status "OK" -Detail $names
    } else {
        Write-Result -Title "Hybrid Connectivity" -Status "WARN" -Detail "No VPN/ExpressRoute gateway detected"
    }
} catch { Write-Result -Title "Hybrid Connectivity" -Status "WARN" -Detail "Check failed" }

# Resource organization - tags presence on RGs
Write-Host "Checking resource organization (tags on RGs)..." -ForegroundColor Cyan
$tagKeys = @("CostCenter","Environment","ManagedBy","Owner","Project")
$rgNames = @($ConnectivityRgName,$ComputeRgName)
foreach ($name in $rgNames) {
    try {
        $g = az group show -n $name --only-show-errors | ConvertFrom-Json
        $missing = @()
        foreach ($k in $tagKeys) { if (-not $g.tags.$k) { $missing += $k } }
        if ($missing.Count -eq 0) { Write-Result -Title "RG Tags:$name" -Status "OK" -Detail "required tags present" }
        else { Write-Result -Title "RG Tags:$name" -Status "WARN" -Detail ("missing: {0}" -f ($missing -join ', ')) }
    } catch { Write-Result -Title "RG Tags:$name" -Status "WARN" -Detail "rg not found" }
}

# Policy assignment for required tags (optional check)
Write-Host "Checking tag policy assignments on platform/landingzones MG..." -ForegroundColor Cyan
$scopes = @("/providers/Microsoft.Management/managementGroups/$Prefix-platform","/providers/Microsoft.Management/managementGroups/$Prefix-landingzones")
$requiredTagKeys = @("Environment","CostCenter","Owner")
foreach ($s in $scopes) {
    try {
        $assigns = az policy assignment list --scope $s | ConvertFrom-Json
        if (-not $assigns) { Write-Result -Title "Policy:$s" -Status "WARN" -Detail "no assignments found"; continue }

        $detected = @{}
        foreach ($k in $requiredTagKeys) { $detected[$k] = $false }

        foreach ($a in $assigns) {
            $pd = $a.policyDefinitionId
            $dn = $a.displayName
            $p  = $a.parameters
            $tagName = $null
            if ($p -and $p.tagName -and $p.tagName.value) { $tagName = $p.tagName.value }
            if ($pd -match '/providers/Microsoft.Authorization/policyDefinitions/' -and ($dn -match 'Require a tag' -or $pd -match 'tags')) {
                if ($tagName -and $requiredTagKeys -contains $tagName) { $detected[$tagName] = $true }
            }
        }

        $missing = ($requiredTagKeys | Where-Object { -not $detected[$_] })
        if ($missing.Count -eq 0) {
            Write-Result -Title "Policy:$s" -Status "OK" -Detail "Environment/CostCenter/Owner enforced"
        } else {
            Write-Result -Title "Policy:$s" -Status "WARN" -Detail ("missing: {0}" -f ($missing -join ', '))
        }
    } catch { Write-Result -Title "Policy:$s" -Status "WARN" -Detail "query failed" }
}

if ($Strict -and $fail) { exit 1 } else { exit 0 }
