param(
    [Parameter(Mandatory = $true)] [string]$Prefix,
    [Parameter(Mandatory = $true)] [string]$Region
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Result([string]$Scope, [string]$Check, [bool]$Pass, [string]$Detail) {
    $status = if ($Pass) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1}: {2} - {3}" -f $Scope, $Check, $status, $Detail)
}

function Ensure-AzCli() {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'Azure CLI (az) 未安装或不可用。请先安装并登录: https://aka.ms/azcli'
    }
    $acct = az account show -o json 2>$null | ConvertFrom-Json
    if (-not $acct) {
        throw 'Azure CLI 未登录。请运行 az login 后重试。'
    }
}

Ensure-AzCli

# Names
$connectivityRg = "$Prefix-connectivity-$Region-rg"
$hubVnetName    = "$Prefix-hub-$Region-vnet"
$bastionName    = "$hubVnetName-bastion"
$platformIP     = '168.63.129.16'

# Fetch Bastion and Bastion subnet CIDR
$bastion = az network bastion show -g $connectivityRg -n $bastionName -o json | ConvertFrom-Json
if (-not $bastion) { throw "未找到 Bastion: RG=$connectivityRg, Name=$bastionName" }

$azureBastionSubnet = az network vnet subnet show -g $connectivityRg --vnet-name $hubVnetName -n 'AzureBastionSubnet' -o json | ConvertFrom-Json
$bastionPrefix = $azureBastionSubnet.addressPrefix
if (-not $bastionPrefix) { throw '未获取到 AzureBastionSubnet 的地址前缀' }

Write-Host "检测 Bastion 资源: $($bastion.id)"
Write-Host "AzureBastionSubnet 前缀: $bastionPrefix"

$allPass = $true

$envs = @('prod','nonprod')
foreach ($env in $envs) {
    $rg = "$Prefix-$env-webmysql-$Region-rg"
    $webVmName = "$Prefix-$env-web"
    $mysqlVmName = "$Prefix-$env-mysql"
    $webNic = "$Prefix-$env-web-nic"
    $mysqlNic = "$Prefix-$env-mysql-nic"

    foreach ($vmName in @($webVmName, $mysqlVmName)) {
        $scope = "$env/$vmName"
        # Identity check
        $identityType = az vm show -g $rg -n $vmName --query 'identity.type' -o tsv 2>$null
        $hasMSI = $identityType -eq 'SystemAssigned'
        if (-not $hasMSI) { $allPass = $false }
        Write-Result $scope 'MSI(SystemAssigned)' $hasMSI "identity.type=$identityType"

        # Extension check
        $exts = az vm extension list -g $rg --vm-name $vmName -o json | ConvertFrom-Json
        $aadExt = $exts | Where-Object {
            $_.name -eq 'AADLoginForLinux' -and
            (
                $_.typePropertiesType -eq 'AADSSHLoginForLinux' -or
                ($_.type -match 'AADSSHLoginForLinux')
            ) -and
            $_.publisher -eq 'Microsoft.Azure.ActiveDirectory'
        }
        $hasAAD = [bool]$aadExt
        if (-not $hasAAD) { $allPass = $false }
        $aadDetail = if ($hasAAD) { "version=$($aadExt.typeHandlerVersion)" } else { 'not found' }
        Write-Result $scope 'AADSSHLoginForLinux extension' $hasAAD $aadDetail
    }

    foreach ($nicName in @($webNic, $mysqlNic)) {
        $scope = "$env/$nicName"
        $nsgId = az network nic show -g $rg -n $nicName --query 'networkSecurityGroup.id' -o tsv 2>$null
        if (-not $nsgId) {
            $allPass = $false
            Write-Result $scope 'NSG associated' $false '未关联 NSG'
            continue
        }
        Write-Result $scope 'NSG associated' $true $nsgId
        $nsg = az network nsg show --ids $nsgId -o json | ConvertFrom-Json
        $rules = $nsg.securityRules

        # Allow SSH from Azure platform IP
        $allowAzureIP = $rules | Where-Object { $_.direction -eq 'Inbound' -and $_.access -eq 'Allow' -and $_.destinationPortRange -eq '22' -and $_.sourceAddressPrefix -eq $platformIP }
        $hasAllowAzureIP = [bool]$allowAzureIP
        if (-not $hasAllowAzureIP) { $allPass = $false }
        $allowAzureDetail = if ($hasAllowAzureIP) { "rule=$($allowAzureIP.name)" } else { 'missing' }
        Write-Result $scope 'Allow SSH from 168.63.129.16' $hasAllowAzureIP $allowAzureDetail

        # Allow SSH from Bastion subnet CIDR (handle both Prefix and Prefixes)
        $allowBastion = $rules | Where-Object {
            $_.direction -eq 'Inbound' -and $_.access -eq 'Allow' -and $_.destinationPortRange -eq '22' -and (
                $_.sourceAddressPrefix -eq $bastionPrefix -or
                ($_.sourceAddressPrefixes -and ($_.sourceAddressPrefixes -contains $bastionPrefix))
            )
        }
        $hasAllowBastion = [bool]$allowBastion
        if (-not $hasAllowBastion) { $allPass = $false }
        $allowBastionDetail = if ($hasAllowBastion) { "rule=$($allowBastion.name)" } else { 'missing' }
        Write-Result $scope 'Allow SSH from Bastion CIDR' $hasAllowBastion $allowBastionDetail

        # Deny SSH from Internet (defense-in-depth)
        $denyInternet = $rules | Where-Object { $_.direction -eq 'Inbound' -and $_.access -eq 'Deny' -and $_.destinationPortRange -eq '22' -and $_.sourceAddressPrefix -eq 'Internet' }
        $hasDenyInternet = [bool]$denyInternet
        if (-not $hasDenyInternet) { $allPass = $false }
        $denyInternetDetail = if ($hasDenyInternet) { "rule=$($denyInternet.name)" } else { 'missing' }
        Write-Result $scope 'Deny SSH from Internet' $hasDenyInternet $denyInternetDetail
    }
}

if ($allPass) {
    Write-Host "\n所有检查通过，可在门户中使用 Bastion 的 AAD 登录。" -ForegroundColor Green
    exit 0
} else {
    Write-Host "\n部分检查未通过，请修正后重试。" -ForegroundColor Yellow
    exit 1
}
