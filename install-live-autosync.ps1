[CmdletBinding()]
param(
    [string]$TaskName = "GitHubLiveProjectSync",
    [int]$DebounceSeconds = 20,
    [int]$PeriodicSyncHours = 12
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($DebounceSeconds -lt 3) {
    throw "DebounceSeconds must be >= 3."
}
if ($PeriodicSyncHours -lt 1) {
    throw "PeriodicSyncHours must be >= 1."
}

$watcherScriptPath = Join-Path $PSScriptRoot "watch-and-sync.ps1"
if (-not (Test-Path -LiteralPath $watcherScriptPath)) {
    throw "Watcher script not found: $watcherScriptPath"
}

$launcherCmdPath = Join-Path $PSScriptRoot "github-live-project-sync.cmd"
$launcherContent = @(
    "@echo off",
    "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watcherScriptPath`" -DebounceSeconds $DebounceSeconds -PeriodicSyncHours $PeriodicSyncHours"
)
Set-Content -LiteralPath $launcherCmdPath -Value $launcherContent -Encoding ASCII

if (-not $env:GITHUB_TOKEN) {
    Write-Warning "GITHUB_TOKEN is not set in environment. Set it with: setx GITHUB_TOKEN '<new_token>'"
}
if (-not $env:GITHUB_USERNAME) {
    Write-Warning "GITHUB_USERNAME is not set in environment. Set it with: setx GITHUB_USERNAME '<your_login>'"
}

$argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watcherScriptPath`" -DebounceSeconds $DebounceSeconds -PeriodicSyncHours $PeriodicSyncHours"
$installedWithScheduler = $false
try {
    schtasks /Delete /TN $TaskName /F 2>$null | Out-Null
    schtasks /Create /F /TN $TaskName /SC ONLOGON /TR $launcherCmdPath | Out-Null
    schtasks /Run /TN $TaskName | Out-Null
    $installedWithScheduler = $true
    Write-Host "Task '$TaskName' installed and started via Task Scheduler."
}
catch {
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $startupCmdPath = Join-Path $startupFolder "github-live-project-sync.cmd"
    $startupContent = @("@echo off", "`"$launcherCmdPath`"")
    Set-Content -LiteralPath $startupCmdPath -Value $startupContent -Encoding ASCII
    Write-Warning "Task Scheduler setup failed ($($_.Exception.Message)). Startup fallback installed: $startupCmdPath"
}

if (-not $installedWithScheduler) {
    Start-Process -FilePath "powershell.exe" -ArgumentList $argument -WindowStyle Hidden
    Write-Host "Watcher started with Startup fallback."
}
