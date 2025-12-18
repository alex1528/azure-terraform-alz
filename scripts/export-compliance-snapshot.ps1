param(
    [string]$OutDir = "plans/compliance",
    [string[]]$ManagementGroups,
    [string[]]$Subscriptions,
    [switch]$Json,
    [switch]$Markdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir($Path) {
    if (-not (Test-Path -Path $Path -PathType Container)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
}

function Get-RepoMeta {
    try {
        $remote = git remote get-url origin 2>$null
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
    } catch { $remote = $null; $branch = $null }
    [pscustomobject]@{
        repository = $remote
        branch     = $branch
        cwd        = (Get-Location).Path
    }
}

function Get-TerraformOutputs {
    $tfOutJson = terraform output -json 2>$null
    if (-not $tfOutJson) { return $null }
    try { ($tfOutJson | ConvertFrom-Json) } catch { return $null }
}

function Get-MgNameFromId([string]$mgId) {
    if (-not $mgId) { return $null }
    # Expect format: /providers/Microsoft.Management/managementGroups/<name>
    $parts = $mgId -split '/'
    $idx = [array]::IndexOf($parts, 'managementGroups')
    if ($idx -ge 0 -and ($idx + 1) -lt $parts.Length) { return $parts[$idx + 1] }
    return $null
}

function Require-AzContext {
    try { az account show 1>$null } catch { throw "Azure CLI context not available. Please run 'az login' and set subscription." }
}

function Get-AssignmentsForMg([string]$mgName) {
    $scope = "/providers/Microsoft.Management/managementGroups/$mgName"
    $json = az policy assignment list --scope $scope -o json
    if ($LASTEXITCODE -ne 0) { throw "Failed to list assignments for $mgName" }
    $json | ConvertFrom-Json
}

function Get-SummaryForMg([string]$mgName) {
    $json = az policy state summarize --management-group $mgName -o json
    if ($LASTEXITCODE -ne 0) { throw "Failed to summarize policy state for $mgName" }
    $json | ConvertFrom-Json
}

function Get-SummaryForSub([string]$subId) {
    $json = az policy state summarize --subscription $subId -o json
    if ($LASTEXITCODE -ne 0) { throw "Failed to summarize policy state for subscription $subId" }
    $json | ConvertFrom-Json
}

function Get-NonCompliantStatesForSub([string]$subId) {
    $json = az policy state list --subscription $subId --query "[?complianceState=='NonCompliant']" -o json
    if ($LASTEXITCODE -ne 0) { throw "Failed to list non-compliant policy states for subscription $subId" }
    $json | ConvertFrom-Json
}

function Build-Markdown([
    object]$data) {
    $sb = [System.Text.StringBuilder]::new()
    $ts = $data.metadata.timestamp
    [void]$sb.AppendLine("# Compliance Snapshot ($ts)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Repository")
    [void]$sb.AppendLine("- Remote: $($data.metadata.repository)")
    [void]$sb.AppendLine("- Branch: $($data.metadata.branch)")
    [void]$sb.AppendLine()

    if ($data.managementGroups) {
        [void]$sb.AppendLine("## Management Groups Summary")
        foreach ($mg in $data.managementGroups) {
            $sumObj = $mg.summary
            $overall = $null
            if ($sumObj -and ($sumObj.PSObject.Properties.Name -contains 'summary')) {
                try { $overall = $sumObj.summary.results } catch {}
            }
            $overallRes = if ($overall) { ($overall | ConvertTo-Json -Compress) } else { 'N/A' }
            [void]$sb.AppendLine("### $($mg.name)")
            [void]$sb.AppendLine("- Assignments: $($mg.assignments.Count)")
            [void]$sb.AppendLine("- Summary: $overallRes")
        }
        [void]$sb.AppendLine()
    }

    if ($data.subscriptions) {
        [void]$sb.AppendLine("## Subscriptions Summary")
        foreach ($sub in $data.subscriptions) {
            $nonCount = ($sub.nonCompliant | Measure-Object).Count
            [void]$sb.AppendLine("### $($sub.id)")
            [void]$sb.AppendLine("- Non-compliant resources: $nonCount")
            if ($nonCount -gt 0) {
                [void]$sb.AppendLine()
                [void]$sb.AppendLine("ResourceId | PolicyAssignment | PolicyDefinition | Timestamp")
                [void]$sb.AppendLine("---|---|---|---")
                foreach ($s in $sub.nonCompliant | Select-Object -First 100) {
                    $rid = $s.resourceId
                    $pa  = ($s.policyAssignmentId -split '/')[-1]
                    $pd  = ($s.policyDefinitionId -split '/')[-1]
                    $t   = $s.timestamp
                    [void]$sb.AppendLine("$rid | $pa | $pd | $t")
                }
                if ($nonCount -gt 100) { [void]$sb.AppendLine("... ($($nonCount-100) more)") }
                [void]$sb.AppendLine()
            }
        }
    }

    $sb.ToString()
}

Require-AzContext
Ensure-Dir $OutDir

$tf = Get-TerraformOutputs
if (-not $ManagementGroups -and $tf) {
    $mgCandidates = @()
    foreach ($key in @('root_management_group_id','platform_group_id','landing_zones_group_id')) {
        if ($tf.$key.value) { $mgCandidates += (Get-MgNameFromId $tf.$key.value) }
    }
    $ManagementGroups = ($mgCandidates | Where-Object { $_ } | Select-Object -Unique)
}
if (-not $ManagementGroups -or $ManagementGroups.Count -eq 0) {
    Write-Warning "No management groups provided or discovered. You can pass -ManagementGroups."
}

if (-not $Subscriptions -or $Subscriptions.Count -eq 0) {
    $current = az account show -o json | ConvertFrom-Json
    $Subscriptions = @($current.id)
}

$timestamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
$repoMeta = Get-RepoMeta

$mgData = @()
foreach ($mg in ($ManagementGroups | Where-Object { $_ })) {
    Write-Host "Collecting management group data for '$mg'..."
    $assign = Get-AssignmentsForMg -mgName $mg
    $sum    = Get-SummaryForMg -mgName $mg
    $mgData += [pscustomobject]@{ name = $mg; assignments = $assign; summary = $sum }
}

$subData = @()
foreach ($sid in $Subscriptions) {
    Write-Host "Collecting subscription data for '$sid'..."
    $ss = Get-SummaryForSub -subId $sid
    $nc = Get-NonCompliantStatesForSub -subId $sid
    $subData += [pscustomobject]@{ id = $sid; summary = $ss; nonCompliant = $nc }
}

$snapshot = [pscustomobject]@{
    metadata = [pscustomobject]@{
        timestamp   = $timestamp
        repository  = $repoMeta.repository
        branch      = $repoMeta.branch
        working_dir = $repoMeta.cwd
    }
    managementGroups = $mgData
    subscriptions    = $subData
}

$baseName = "compliance-$timestamp"
$jsonPath = Join-Path $OutDir ($baseName + '.json')
$mdPath   = Join-Path $OutDir ($baseName + '.md')

if (-not $Markdown -and -not $Json) { $Markdown = $true; $Json = $true }

if ($Json) {
    $snapshot | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Host "JSON snapshot written: $jsonPath"
}
if ($Markdown) {
    (Build-Markdown -data $snapshot) | Out-File -FilePath $mdPath -Encoding UTF8
    Write-Host "Markdown snapshot written: $mdPath"
}

Write-Host "Compliance snapshot complete."