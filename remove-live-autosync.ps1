[CmdletBinding()]
param(
    [string]$TaskName = "GitHubLiveProjectSync"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Task '$TaskName' removed."
}
else {
    Write-Host "Task '$TaskName' does not exist."
}

$startupFolder = [Environment]::GetFolderPath("Startup")
$startupCmdPath = Join-Path $startupFolder "github-live-project-sync.cmd"
if (Test-Path -LiteralPath $startupCmdPath) {
    Remove-Item -LiteralPath $startupCmdPath -Force
    Write-Host "Startup fallback removed: $startupCmdPath"
}
