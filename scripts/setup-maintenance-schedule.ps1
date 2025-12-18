param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$DailyTime = "02:00",
    [string]$WeeklyDay = "Sunday",
    [string]$WeeklyTime = "02:30",
    [string]$TaskUser = $env:USERNAME,
    [switch]$CreateDaily,
    [switch]$CreateWeekly,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

function New-TaskAction([string]$repo, [string]$scriptPath) {
    $cmd = "Push-Location '" + $repo + "'; pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File '" + $scriptPath + "'; Pop-Location"
    New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -Command \"$cmd\""
}

function Ensure-AdminNote {
    Write-Host "Note: Registering tasks may require admin rights depending on policy." -ForegroundColor Yellow
}

if ($Remove) {
    foreach ($name in @('AzureALZ_Baselines_Daily','AzureALZ_Baselines_Weekly')) {
        try { Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction Stop; Write-Host "Removed task: $name" -ForegroundColor Green } catch { Write-Host "Skip remove: $name not found" -ForegroundColor DarkGray }
    }
    return
}

Ensure-AdminNote

$maintScript = Join-Path $RepoRoot 'scripts/maintain-baselines.ps1'
if (-not (Test-Path $maintScript)) { throw "Cannot find maintain-baselines script at $maintScript" }

if (-not $CreateDaily -and -not $CreateWeekly) { $CreateDaily = $true }

if ($CreateDaily) {
    $trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($DailyTime,'HH:mm',$null))
    $action  = New-TaskAction -repo $RepoRoot -scriptPath 'scripts/maintain-baselines.ps1'
    $principal = New-ScheduledTaskPrincipal -UserId $TaskUser -RunLevel Highest
    Register-ScheduledTask -TaskName 'AzureALZ_Baselines_Daily' -Trigger $trigger -Action $action -Principal $principal -Description 'Daily: Refresh baselines and export compliance snapshot' -Force
    Write-Host "Registered daily task at $DailyTime" -ForegroundColor Green
}

if ($CreateWeekly) {
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $WeeklyDay -At ([datetime]::ParseExact($WeeklyTime,'HH:mm',$null))
    $action  = New-TaskAction -repo $RepoRoot -scriptPath 'scripts/maintain-baselines.ps1'
    $principal = New-ScheduledTaskPrincipal -UserId $TaskUser -RunLevel Highest
    Register-ScheduledTask -TaskName 'AzureALZ_Baselines_Weekly' -Trigger $trigger -Action $action -Principal $principal -Description 'Weekly: Refresh baselines and export compliance snapshot' -Force
    Write-Host "Registered weekly task: $WeeklyDay at $WeeklyTime" -ForegroundColor Green
}

Write-Host "Setup complete." -ForegroundColor Green
