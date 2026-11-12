# GitHub Project Sync

This folder contains a sync system that copies these projects from `Documents` to GitHub:

- `C:\Users\adama\Documents\twitter viral strategy` -> repo `twitter`
- `C:\Users\adama\Documents\zeph ai projects` -> repo `zeph-ai`
- `C:\Users\adama\Documents\crypto-ai-desk` -> repo `crypto-ai-desk`
- `C:\Users\adama\Documents\Obsidian Vault` -> repo `obsidian-vault`
- `C:\Users\adama\Documents\polymarket_cross_market_scanner` -> repo `cross-market-scanner`
- `C:\Users\adama\Documents\polymarket_wallet_researcher` -> repo `polymarket-wallet-researcher`
- `C:\Users\adama\Documents\polymarket_cross_market_scanner` -> repo `probability-bot`

## GitHub categories

GitHub personal accounts do not support folders for repositories, so this sync system categorizes repos with descriptions and topics:

- `social-marketing`: `twitter`
- `ai-projects`: `zeph-ai`
- `ai-trading`: `crypto-ai-desk`
- `knowledge-base`: `obsidian-vault`
- `polymarket-tools`: `cross-market-scanner`
- `polymarket-research`: `polymarket-wallet-researcher`
- `probability-trading`: `probability-bot`

## What the script does

`sync-projects-to-github.ps1`:

1. Checks or creates GitHub repositories.
2. Mirrors files from your local folders into a dedicated local workdir.
3. Copies everything except `.git` (required to keep destination repo metadata safe).
4. Commits and pushes only when there are changes.

## One-time setup

Set environment variables in PowerShell:

```powershell
setx GITHUB_USERNAME "your_github_username"
setx GITHUB_TOKEN "your_personal_access_token"
```

Then open a new terminal window.

## Run sync

From this folder:

```powershell
.\sync-projects-to-github.ps1
```

Or double-click:

- `run-sync.bat`

## Safe test mode

```powershell
.\sync-projects-to-github.ps1 -DryRun
```

## Optional auto-run (Windows Task Scheduler)

Run every 2 hours:

```powershell
.\install-scheduled-sync.ps1
```

Custom interval (for example, every 6 hours):

```powershell
.\install-scheduled-sync.ps1 -IntervalHours 6
```

Remove scheduled sync:

```powershell
.\remove-scheduled-sync.ps1
```

## Live auto-sync on file changes

Install watcher task (starts at Windows logon and runs in background):

```powershell
.\install-live-autosync.ps1
```

If Task Scheduler is blocked by policy, installer automatically creates Startup fallback:

- `C:\Users\adama\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\github-live-project-sync.cmd`

Customize debounce window (seconds):

```powershell
.\install-live-autosync.ps1 -DebounceSeconds 30
```

Run watcher manually in current terminal:

```powershell
.\watch-and-sync.ps1
```

Remove live watcher task:

```powershell
.\remove-live-autosync.ps1
```

## Notes

- Default visibility for newly created repos is `private`.
- You can change visibility on first run:

```powershell
.\sync-projects-to-github.ps1 -Visibility public
```
- If a token was shared in chat/logs, revoke it in GitHub and create a new one.
