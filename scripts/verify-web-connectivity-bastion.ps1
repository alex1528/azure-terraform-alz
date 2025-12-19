param(
  [Parameter(Mandatory = $true)] [string]$Prefix,
  [Parameter(Mandatory = $true)] [string]$Region,
  [int]$TimeoutSec = 15,
  [int]$ProdLocalPort = 8081,
  [int]$NonprodLocalPort = 8082,
  [int]$ResourcePort = 80,
  [string]$Path = "/"
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

function Start-BastionTunnel([string]$bstName, [string]$rgConn, [string]$vmId, [int]$localPort, [int]$resourcePort) {
  $args = @(
    'network','bastion','tunnel',
    '--name', $bstName,
    '--resource-group', $rgConn,
    '--target-resource-id', $vmId,
    '--port', $localPort,
    '--resource-port', $resourcePort
  )
  $proc = Start-Process -FilePath 'az' -ArgumentList $args -NoNewWindow -PassThru
  # Wait for local port ready (up to ~12s)
  $maxTries = 12
  for ($i=0; $i -lt $maxTries; $i++) {
    try {
      $tcp = New-Object System.Net.Sockets.TcpClient
      $tcp.Connect('127.0.0.1', $localPort)
      if ($tcp.Connected) { $tcp.Close(); break }
    } catch {}
    Start-Sleep -Milliseconds 1000
  }
  return $proc
}

function Stop-Proc($proc) {
  try { if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force } } catch {}
}

function Test-HttpLocal([int]$localPort, [string]$path, [int]$timeoutSec) {
  $uri = "http://127.0.0.1:$localPort$path"
  try {
    $res = Invoke-WebRequest -Uri $uri -Method GET -TimeoutSec $timeoutSec -UseBasicParsing
    return @{ ok = $true; code = $res.StatusCode; length = ($res.Content?.Length) }
  } catch {
    return @{ ok = $false; error = $_.Exception.Message }
  }
}

Ensure-AzCli

$rgConn = "$Prefix-connectivity-$Region-rg"
$bstName = "$Prefix-hub-$Region-vnet-bastion"

$targets = @(
  @{ env = 'prod';    rg = "$Prefix-prod-webmysql-$Region-rg";    vm = "$Prefix-prod-web";    port = $ProdLocalPort },
  @{ env = 'nonprod'; rg = "$Prefix-nonprod-webmysql-$Region-rg"; vm = "$Prefix-nonprod-web"; port = $NonprodLocalPort }
)

$allOk = $true

foreach ($t in $targets) {
  Write-Host ("\n[{0}] Starting Bastion tunnel for {1} (local {2} -> remote {3})" -f $t.env, $t.vm, $t.port, $ResourcePort) -ForegroundColor Cyan
  $vmId = az vm show -g $t.rg -n $t.vm --query id -o tsv
  if (-not $vmId) { Write-Host 'VM ID 未找到' -ForegroundColor Red; $allOk = $false; continue }

  $proc = $null
  try {
    $proc = Start-BastionTunnel -bstName $bstName -rgConn $rgConn -vmId $vmId -localPort $t.port -resourcePort $ResourcePort
    # Retry HTTP probe few times to avoid transient startup delays
    $res = $null
    for ($i=0; $i -lt 3; $i++) {
      $res = Test-HttpLocal -localPort $t.port -path $Path -timeoutSec $TimeoutSec
      if ($res.ok) { break } else { Start-Sleep -Seconds 2 }
    }
    if ($res.ok) {
      Write-Host ("PASS: HTTP via Bastion tunnel StatusCode={0} ContentLength={1}" -f $res.code, $res.length) -ForegroundColor Green
    } else {
      Write-Host ("FAIL: HTTP via Bastion tunnel {0}" -f $res.error) -ForegroundColor Red
      $allOk = $false
    }
  } finally {
    Stop-Proc $proc
    Start-Sleep -Seconds 1
  }
}

if ($allOk) { exit 0 } else { exit 1 }
