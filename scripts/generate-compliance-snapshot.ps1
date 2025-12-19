param(
  [string]$Prefix = "bingohr",
  [string]$Region = "eastasia",
  [string]$OutFile = "compliance-snapshot.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-AzCli() {
  if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) 未安装或不可用。请先安装并登录: https://aka.ms/azcli'
  }
  $acct = az account show -o json 2>$null | ConvertFrom-Json
  if (-not $acct) { throw 'Azure CLI 未登录。请运行 az login 后重试。' }
}

Ensure-AzCli

$tenant = az account show -o json | ConvertFrom-Json

# Management groups
$mgRoot = az account management-group show --name "$Prefix-root" -o json 2>$null | ConvertFrom-Json
$mgLanding = az account management-group show --name "$Prefix-landingzones" -o json 2>$null | ConvertFrom-Json
$mgPlatform = az account management-group show --name "$Prefix-platform" -o json 2>$null | ConvertFrom-Json
$mgProd = az account management-group show --name "$Prefix-prod" -o json 2>$null | ConvertFrom-Json
$mgNonprod = az account management-group show --name "$Prefix-nonprod" -o json 2>$null | ConvertFrom-Json
$mgConn = az account management-group show --name "$Prefix-connectivity" -o json 2>$null | ConvertFrom-Json
$mgId = az account management-group show --name "$Prefix-identity" -o json 2>$null | ConvertFrom-Json
$mgMgmt = az account management-group show --name "$Prefix-management" -o json 2>$null | ConvertFrom-Json
$mgSandbox = az account management-group show --name "$Prefix-sandboxes" -o json 2>$null | ConvertFrom-Json
$mgDecom = az account management-group show --name "$Prefix-decommissioned" -o json 2>$null | ConvertFrom-Json

# Policy enforcement mode (from Terraform variable desired state)
$policyMode = "Default"

# Defender pricing
$defenderPlans = az security pricing list -o json | ConvertFrom-Json | ForEach-Object { @{ type = $_.name; tier = $_.pricingTier } }

# Connectivity (Firewall & Bastion)
$rgConn = "$Prefix-connectivity-$Region-rg"
$bastionName = "$Prefix-hub-$Region-vnet-bastion"
$fwName = "$Prefix-hub-$Region-vnet-fw"
$bastion = az network bastion show -g $rgConn -n $bastionName -o json 2>$null | ConvertFrom-Json
$fw = az network firewall show -g $rgConn -n $fwName -o json 2>$null | ConvertFrom-Json

# Workloads (RG budgets & RSV backup)
$rgProd = "$Prefix-prod-webmysql-$Region-rg"
$rgNonprod = "$Prefix-nonprod-webmysql-$Region-rg"
$budgets = az consumption budget list --scope "/subscriptions/$($tenant.id)" -o json 2>$null | ConvertFrom-Json
$rsvProd = az resource list -g $rgProd --resource-type "Microsoft.RecoveryServices/vaults" -o json 2>$null | ConvertFrom-Json
$rsvNonprod = az resource list -g $rgNonprod --resource-type "Microsoft.RecoveryServices/vaults" -o json 2>$null | ConvertFrom-Json

# Private Link (Key Vault)
$optRg = "$Prefix-optional-resources-rg"
$kvName = ("{0}platformkv" -f $Prefix).ToLower()
$kv = az keyvault show -g $optRg -n $kvName -o json 2>$null | ConvertFrom-Json
$peList = az network private-endpoint list -g $optRg -o json 2>$null | ConvertFrom-Json
$dnsZone = az network private-dns zone show -g $optRg -n "privatelink.vaultcore.azure.net" -o json 2>$null | ConvertFrom-Json

$snapshot = [ordered]@{
  tenant             = @{ id = $tenant.tenantId; subscription = $tenant.id; name = $tenant.name }
  managementGroups   = @{ root = $mgRoot; landingZones = $mgLanding; platform = $mgPlatform; prod = $mgProd; nonprod = $mgNonprod; connectivity = $mgConn; identity = $mgId; management = $mgMgmt; sandboxes = $mgSandbox; decommissioned = $mgDecom }
  policyEnforcement  = $policyMode
  defenderPricing    = $defenderPlans
  connectivity       = @{ bastion = $bastion; firewall = $fw }
  workloads          = @{ prod = @{ resourceGroup = $rgProd; rsv = $rsvProd }; nonprod = @{ resourceGroup = $rgNonprod; rsv = $rsvNonprod } }
  budgets            = $budgets
  privateLink        = @{ keyVault = $kv; privateEndpoints = $peList; dnsZone = $dnsZone }
  generatedAt        = (Get-Date).ToString("s")
}

$snapshot | ConvertTo-Json -Depth 8 | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "合规快照已生成: $OutFile" -ForegroundColor Green
