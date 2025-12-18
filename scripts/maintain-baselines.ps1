param(
    [string[]]$PlanPaths = @(
        "plans/baseline-policy.plan",
        "plans/baseline-network.plan",
        "plans/tag-value-enforce.plan",
        "plans/baseline-defender.plan"
    ),
    [switch]$NoPush,
    [switch]$SkipComplianceSnapshot
)

$ErrorActionPreference = "Stop"

function Write-PlanSummary {
    param(
        [Parameter(Mandatory=$true)][string]$PlanPath
    )
    if (!(Test-Path $PlanPath)) {
        throw "Plan file not found: $PlanPath"
    }

    Write-Host "Generating summary for $PlanPath" -ForegroundColor Cyan
    $planText = terraform show "$PlanPath" | Out-String

    # Extract plan counts
    $planLine = [Regex]::Match($planText, 'Plan:\s*(\d+)\s*to add,\s*(\d+)\s*to change,\s*(\d+)\s*to destroy', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (!$planLine.Success) {
        # Fallback: derive counts from resource change markers
        $addCount      = ([Regex]::Matches($planText, '^\s*#\s+.+?\s+will be created', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
        $changeCount   = ([Regex]::Matches($planText, '^\s*#\s+.+?\s+will be updated in-place', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
        $destroyCount  = ([Regex]::Matches($planText, '^\s*#\s+.+?\s+will be destroyed', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    } else {
        $addCount = $planLine.Groups[1].Value
        $changeCount = $planLine.Groups[2].Value
        $destroyCount = $planLine.Groups[3].Value
    }

    # Extract exact resource instance changes
    $resourceMatches = [Regex]::Matches($planText, '^\s*#\s+(.+?)\s+will be\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $changedResources = @()
    foreach ($m in $resourceMatches) {
        $addr = $m.Groups[1].Value.Trim()
        $action = $m.Groups[2].Value.Trim()
        $changedResources += "- ${addr}: ${action}"
    }

    # Build summary markdown
    $date = Get-Date -Format 'yyyy-MM-dd'
    $planFileRel = $PlanPath
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($PlanPath)
    $summaryPath = Join-Path (Split-Path $PlanPath -Parent) ("$baseName.changes.md")

    $content = @(
        "# Baseline Change Summary: $baseName",
        "",
        "Date: $date",
        "Plan file: $planFileRel",
        "Summary: $addCount to add, $changeCount to change, $destroyCount to destroy",
        "",
        "Detailed Resource Changes (exact instances):",
        $changedResources,
        "",
        "Notes:",
        "- Tag updates and provider-managed fields (e.g., subplan) may normalize without functional impact.",
        "- Re-generate baseline before next changes to minimize drift and compare against this summary."
    ) -join "`r`n"

    Set-Content -Path $summaryPath -Value $content -Encoding UTF8
    Write-Host "Summary written: $summaryPath" -ForegroundColor Green
    return $summaryPath
}

# 1) Clean date-stamped files in plans/
Write-Host "Cleaning date-stamped files in plans/" -ForegroundColor Cyan
$dated = Get-ChildItem -Path "plans" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\\d{4}-\\d{2}-\\d{2}' }
if ($dated -and $dated.Count -gt 0) {
    $dated | Remove-Item -Force
    $dated | Select-Object -ExpandProperty Name | ForEach-Object { Write-Host "Removed: $_" -ForegroundColor Yellow }
} else {
    Write-Host "No date-stamped files found." -ForegroundColor DarkGray
}

# 2) Refresh summaries for provided plan paths
$summaryFiles = @()
foreach ($p in $PlanPaths) {
    $summaryFiles += (Write-PlanSummary -PlanPath $p)
}

# 3) Git add/commit/push
Write-Host "Staging plans and summaries..." -ForegroundColor Cyan
try {
    git add --all
    $msg = "chore(baselines): clean dated plans and refresh summaries"
    git commit -m $msg | Out-Null
    if (-not $NoPush) {
        git push | Out-Null
        Write-Host "Git changes pushed." -ForegroundColor Green
    } else {
        Write-Host "Git push skipped (NoPush)." -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Git commit/push failed: $($_.Exception.Message)"
    throw
}

Write-Host "Baseline maintenance complete." -ForegroundColor Green

# 4) Export compliance snapshot (JSON + Markdown)
if (-not $SkipComplianceSnapshot) {
    try {
        Write-Host "Exporting compliance snapshot..." -ForegroundColor Cyan
        # Use pwsh to run exporter in the repo context
        pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "scripts/export-compliance-snapshot.ps1" | Out-Null
        Write-Host "Compliance snapshot exported." -ForegroundColor Green

        # Stage and commit compliance artifacts
        Write-Host "Staging compliance artifacts..." -ForegroundColor Cyan
        try {
            git add "plans/compliance" | Out-Null
            $msg2 = "chore(reports): export compliance snapshot"
            git commit -m $msg2 | Out-Null
            if (-not $NoPush) {
                git push | Out-Null
                Write-Host "Compliance snapshot pushed." -ForegroundColor Green
            } else {
                Write-Host "Compliance snapshot push skipped (NoPush)." -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Git commit/push (compliance) failed: $($_.Exception.Message)"
        }
    } catch {
        Write-Warning "Compliance snapshot export failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "Compliance snapshot skipped (SkipComplianceSnapshot)." -ForegroundColor Yellow
}
