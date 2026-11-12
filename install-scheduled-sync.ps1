[CmdletBinding()]
param(
    [int]$IntervalHours = 2,
    [string]$TaskName = "GitHubProjectSync"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($IntervalHours -lt 1) {
    throw "IntervalHours must be >= 1."
}

$scriptPath = Join-Path $PSScriptRoot "sync-projects-to-github.ps1"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Sync script not found: $scriptPath"
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$repetitionDuration = New-TimeSpan -Days 3650
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Hours $IntervalHours) -RepetitionDuration $repetitionDuration
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Sync twitter and zeph-ai projects to GitHub." -Force | Out-Null

Write-Host "Scheduled task '$TaskName' is active. Interval: every $IntervalHours hour(s)."
