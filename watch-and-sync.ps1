[CmdletBinding()]
param(
    [int]$DebounceSeconds = 20,
    [int]$PeriodicSyncHours = 12,
    [string]$GitHubUsername = $env:GITHUB_USERNAME,
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$LogPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($DebounceSeconds -lt 3) {
    throw "DebounceSeconds must be >= 3."
}
if ($PeriodicSyncHours -lt 1) {
    throw "PeriodicSyncHours must be >= 1."
}
if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $LogPath = Join-Path $PSScriptRoot "logs\watch-and-sync.log"
}

$logDir = Split-Path -Parent $LogPath
if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

$syncScriptPath = Join-Path $PSScriptRoot "sync-projects-to-github.ps1"
if (-not (Test-Path -LiteralPath $syncScriptPath)) {
    throw "Sync script not found: $syncScriptPath"
}

$mutex = New-Object System.Threading.Mutex($false, "Global\GitHubLiveProjectSyncWatcher")
if (-not $mutex.WaitOne(0, $false)) {
    Write-Log "Watcher is already running. Exiting."
    exit 0
}

$projectPaths = @(
    "C:\Users\adama\Documents\twitter viral strategy",
    "C:\Users\adama\Documents\zeph ai projects",
    "C:\Users\adama\Documents\crypto-ai-desk",
    "C:\Users\adama\Documents\Obsidian Vault",
    "C:\Users\adama\Documents\polymarket_cross_market_scanner",
    "C:\Users\adama\Documents\polymarket_wallet_researcher"
)

foreach ($path in $projectPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Watched path not found: $path"
    }
}

$script:pendingChanges = $true
$script:lastEventAt = Get-Date
$script:isSyncRunning = $false
$script:lastSyncFinishedAt = $null
$watchers = @()
$eventSubscriptions = @()

function Invoke-SyncNow {
    if ($script:isSyncRunning) {
        return
    }

    $script:isSyncRunning = $true
    try {
        Write-Log "Sync started"
        $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $syncScriptPath)
        if ($GitHubUsername) {
            $args += @("-GitHubUsername", $GitHubUsername)
        }
        if ($GitHubToken) {
            $args += @("-GitHubToken", $GitHubToken)
        }

        & powershell @args
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Sync exited with code $LASTEXITCODE" "WARN"
        }
        else {
            Write-Log "Sync finished"
        }
        $script:lastSyncFinishedAt = Get-Date
    }
    catch {
        Write-Log "Sync failed: $($_.Exception.Message)" "ERROR"
        $script:lastSyncFinishedAt = Get-Date
    }
    finally {
        $script:isSyncRunning = $false
    }
}

for ($i = 0; $i -lt $projectPaths.Count; $i++) {
    $path = $projectPaths[$i]
    $suffix = "p$i"
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $path
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, DirectoryName, LastWrite, CreationTime, Size'
    $watcher.EnableRaisingEvents = $true
    $watchers += $watcher

    $eventSubscriptions += Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier "sync.changed.$suffix" -Action {
        $script:pendingChanges = $true
        $script:lastEventAt = Get-Date
    }
    $eventSubscriptions += Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier "sync.created.$suffix" -Action {
        $script:pendingChanges = $true
        $script:lastEventAt = Get-Date
    }
    $eventSubscriptions += Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier "sync.deleted.$suffix" -Action {
        $script:pendingChanges = $true
        $script:lastEventAt = Get-Date
    }
    $eventSubscriptions += Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier "sync.renamed.$suffix" -Action {
        $script:pendingChanges = $true
        $script:lastEventAt = Get-Date
    }
}

Write-Log "Watching changes in source folders. Debounce=$DebounceSeconds s, periodic sync every $PeriodicSyncHours h"

try {
    while ($true) {
        Start-Sleep -Seconds 2
        $secondsSinceEvent = ((Get-Date) - $script:lastEventAt).TotalSeconds
        $periodicDue = $false
        if (-not $script:isSyncRunning -and $null -ne $script:lastSyncFinishedAt) {
            $hoursSinceSync = ((Get-Date) - $script:lastSyncFinishedAt).TotalHours
            $periodicDue = $hoursSinceSync -ge $PeriodicSyncHours
        }

        if ($script:pendingChanges -and $secondsSinceEvent -ge $DebounceSeconds) {
            $script:pendingChanges = $false
            Invoke-SyncNow
        }
        elseif ($periodicDue) {
            Write-Log "Periodic sync due"
            Invoke-SyncNow
        }
    }
}
finally {
    foreach ($sub in $eventSubscriptions) {
        Unregister-Event -SourceIdentifier $sub.SourceIdentifier -ErrorAction SilentlyContinue
        Remove-Job -Id $sub.Id -Force -ErrorAction SilentlyContinue
    }
    foreach ($watcher in $watchers) {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
    $mutex.ReleaseMutex() | Out-Null
    $mutex.Dispose()
}
