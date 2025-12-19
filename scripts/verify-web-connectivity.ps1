param(
  [Parameter(Mandatory = $true)] [string]$Prefix,
  [Parameter(Mandatory = $true)] [string]$Region,
  [int]$TimeoutSec = 15,
  [string]$Path = "/"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-AzCli() {
  if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) 未安装或不可用。请先安装并登录: https://aka.ms/azcli'
  }
  $acct = az account show -o json 2>$null | ConvertFrom-Json
  if (-not $acct) {
    throw 'Azure CLI 未登录。请运行 az login 后重试。'
  }
}

function Get-WebPublicIp([string]$rg, [string]$vmName) {
  $info = az vm list-ip-addresses -g $rg -n $vmName -o json | ConvertFrom-Json
  if (-not $info -or -not $info[0].virtualMachine.network.publicIpAddresses) { return $null }
  return $info[0].virtualMachine.network.publicIpAddresses[0].ipAddress
}

function Test-Http([string]$ip, [string]$path, [int]$timeoutSec) {
  $uri = "http://$ip$path"
  try {
    $res = Invoke-WebRequest -Uri $uri -Method GET -TimeoutSec $timeoutSec -UseBasicParsing
    return @{ ok = $true; code = $res.StatusCode; length = ($res.Content?.Length) }
  } catch {
    return @{ ok = $false; error = $_.Exception.Message }
  }
}

Ensure-AzCli

$targets = @(
  @{ env = 'prod';    rg = "$Prefix-prod-webmysql-$Region-rg";    vm = "$Prefix-prod-web"    },
  @{ env = 'nonprod'; rg = "$Prefix-nonprod-webmysql-$Region-rg"; vm = "$Prefix-nonprod-web" }
)

$allOk = $true

foreach ($t in $targets) {
  Write-Host ("\n[{0}] Resolving public IP for {1} in RG {2}" -f $t.env, $t.vm, $t.rg) -ForegroundColor Cyan
  $ip = Get-WebPublicIp -rg $t.rg -vmName $t.vm
  if (-not $ip) {
    Write-Host "WARN: 未发现公共 IP，跳过 HTTP 连通性测试" -ForegroundColor Yellow
    $allOk = $false
    continue
  }
  Write-Host "IP: $ip"
  $res = Test-Http -ip $ip -path $Path -timeoutSec $TimeoutSec
  if ($res.ok) {
    Write-Host ("PASS: HTTP 连接成功 StatusCode={0} ContentLength={1}" -f $res.code, $res.length) -ForegroundColor Green
  } else {
    Write-Host ("FAIL: HTTP 连接失败 {0}" -f $res.error) -ForegroundColor Red
    $allOk = $false
  }
}

if ($allOk) { exit 0 } else { exit 1 }
