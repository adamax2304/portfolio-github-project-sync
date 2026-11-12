[CmdletBinding()]
param(
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'public',
    [string]$StageRoot = 'F:\GitHubPortfolioExports',
    [string]$GitHubUsername = $env:GITHUB_USERNAME,
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [switch]$Publish,
    [switch]$Resume,
    [string[]]$ProjectNames = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($GitHubUsername)) {
    $GitHubUsername = [Environment]::GetEnvironmentVariable('GITHUB_USERNAME', 'User')
}
if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    $GitHubToken = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN', 'User')
}
if ([string]::IsNullOrWhiteSpace($GitHubUsername) -or [string]::IsNullOrWhiteSpace($GitHubToken)) {
    throw 'GITHUB_USERNAME and GITHUB_TOKEN must be configured. Values are never written to the export or Git remote.'
}

$projects = @(
    @{ Name = 'Hyve'; Repo = 'portfolio-hyve-social-inbox'; Source = 'C:\Users\adama\Documents\New project\social-inbox'; Status = 'product prototype'; Description = 'Omnichannel CRM and shared inbox for customer conversations.'; Topics = @('portfolio', 'saas', 'crm', 'nextjs') },
    @{ Name = 'Maison Lumor'; Repo = 'portfolio-maison-lumor'; Source = 'C:\Users\adama\Desktop\maison lumor'; Status = 'website'; Description = 'E-commerce and brand website project for Maison Lumor.'; Topics = @('portfolio', 'web', 'nextjs', 'ecommerce') },
    @{ Name = 'Football Media Strategy'; Repo = 'portfolio-football-media-strategy'; Source = 'C:\Users\adama\Documents\football-media-strategy'; Status = 'strategy package'; Description = 'Media launch plan, operating model, content system, and financial plan.'; Topics = @('portfolio', 'media', 'strategy', 'content') },
    @{ Name = 'Polymarket 5-Minute Bot'; Repo = 'portfolio-polymarket-5m-bot'; Source = 'C:\Users\adama\Documents\zeph ai projects\poly 3rd try bot'; Status = 'paper research'; Description = 'Research and paper-trading system for near-resolution prediction-market strategies.'; Topics = @('portfolio', 'polymarket', 'rust', 'python', 'paper-trading') },
    @{ Name = 'Kalshi + Polymarket Foundation'; Repo = 'portfolio-kalshi-polymarket-foundation'; Source = 'C:\Users\adama\Documents\_SKLAD_proektov\kalshi+poly system'; Status = 'foundation'; Description = 'Multi-venue market-data and replay foundation for prediction-market research.'; Topics = @('portfolio', 'kalshi', 'polymarket', 'rust', 'data-engineering') },
    @{ Name = 'Polymarket Cross-Market Scanner'; Repo = 'portfolio-polymarket-cross-market-scanner'; Source = 'C:\Users\adama\Documents\_SKLAD_proektov\polymarket_cross_market_scanner'; Status = 'research / paper'; Description = 'Cross-market and cross-venue arbitrage research for prediction markets.'; Topics = @('portfolio', 'polymarket', 'arbitrage', 'python', 'research') },
    @{ Name = 'Polymarket Wallet Researcher'; Repo = 'portfolio-polymarket-wallet-researcher'; Source = 'C:\Users\adama\Documents\_SKLAD_proektov\polymarket_wallet_researcher'; Status = 'research'; Description = 'Public-wallet analysis and strategy classification for Polymarket.'; Topics = @('portfolio', 'polymarket', 'analytics', 'python') },
    @{ Name = 'Crypto AI Desk'; Repo = 'portfolio-crypto-ai-desk'; Source = 'C:\Users\adama\Documents\crypto-ai-desk'; Status = 'research desk'; Description = 'Multi-exchange trading-research desk with deterministic scoring and paper tracking.'; Topics = @('portfolio', 'trading', 'crypto', 'python', 'research') },
    @{ Name = 'AI Trading Desk Control'; Repo = 'portfolio-trading-desk-control'; Source = 'C:\Users\adama\Documents\trading-desk-control'; Status = 'control plane'; Description = 'Telegram control plane and monitoring interface for the trading desk.'; Topics = @('portfolio', 'telegram', 'fastapi', 'react', 'trading') },
    @{ Name = 'Portfolio Strategy OS'; Repo = 'portfolio-portfolio-strategy-os'; Source = 'D:\my ai projects\portfolio-strategy-os'; Status = 'investment research'; Description = 'Portfolio research workflows for CORE, Opportunity, and emerging-business analysis.'; Topics = @('portfolio', 'investing', 'research', 'python', 'automation') },
    @{ Name = 'Options Structure Trader'; Repo = 'portfolio-options-structure-trader'; Source = 'C:\Users\adama\Documents\my ai projects\options-structure-trader.archived-2026-10-06'; Status = 'archived paper research'; Description = 'Deterministic options-structure and level-reclaim research system.'; Topics = @('portfolio', 'options', 'research', 'python', 'paper-trading') },
    @{ Name = 'Residual Grid Research'; Repo = 'portfolio-residual-grid-research'; Source = 'C:\Users\adama\Documents\residual_grid_research'; Status = 'research'; Description = 'Residual-grid and breakout-continuation trading research.'; Topics = @('portfolio', 'quant', 'trading', 'research', 'python') },
    @{ Name = 'News Repricing Trader'; Repo = 'portfolio-news-repricing-trader'; Source = 'C:\Users\adama\Documents\news_repricing_trader'; Status = 'research, no-go edge'; Description = 'Falsification-first research into delayed off-hours news repricing.'; Topics = @('portfolio', 'event-driven', 'research', 'python', 'trading') },
    @{ Name = 'Funding Carry'; Repo = 'portfolio-funding-carry'; Source = 'C:\Users\adama\Documents\zeph ai projects\funding_carry'; Status = 'paper research'; Description = 'Delta-neutral cash-and-carry research across crypto spot and perpetual markets.'; Topics = @('portfolio', 'crypto', 'funding', 'research', 'python') },
    @{ Name = 'Funding Directional'; Repo = 'portfolio-funding-directional'; Source = 'C:\Users\adama\Documents\zeph ai projects\funding_directional'; Status = 'paper research'; Description = 'Extreme-funding mean-reversion research across crypto perpetual markets.'; Topics = @('portfolio', 'crypto', 'funding', 'mean-reversion', 'python') },
    @{ Name = 'Pump Exhaustion Reversal'; Repo = 'portfolio-pump-exhaustion-reversal'; Source = 'C:\Users\adama\Documents\zeph ai projects\pump_exhaustion_reversal'; Status = 'research'; Description = 'Structural short research after failed crypto pumps and failed reclaims.'; Topics = @('portfolio', 'crypto', 'research', 'market-structure', 'python') },
    @{ Name = 'FVG Crypto Research'; Repo = 'portfolio-fvg-crypto-research'; Source = 'C:\Users\adama\Documents\_SKLAD_proektov\fvgbot'; Status = 'archived research'; Description = 'Fair-value-gap crypto trading research, dashboard, and backtests.'; Topics = @('portfolio', 'crypto', 'fvg', 'backtesting', 'python') },
    @{ Name = 'GitHub Project Sync'; Repo = 'portfolio-github-project-sync'; Source = 'C:\Users\adama\Documents\github-project-sync'; Status = 'developer tooling'; Description = 'Windows tooling for controlled, repeatable project synchronization to GitHub.'; Topics = @('portfolio', 'devtools', 'powershell', 'github', 'automation') }
)

if ($ProjectNames.Count -gt 0) {
    $requested = $ProjectNames | ForEach-Object { $_.ToLowerInvariant() }
    $projects = @($projects | Where-Object { $requested -contains $_.Name.ToLowerInvariant() -or $requested -contains $_.Repo.ToLowerInvariant() })
    if ($projects.Count -eq 0) { throw 'No requested portfolio projects matched the manifest.' }
}

$excludedDirectories = @(
    '.git', '.venv', 'venv', 'node_modules', '__pycache__', '.pytest_cache', '.mypy_cache', '.ruff_cache',
    '.next', 'dist', 'build', 'target', 'target_build', 'logs', 'log', 'data', 'db', 'cache', 'state',
    'backups', 'backup', 'archives', 'archive', '_archive', '_development_work', 'credentials', 'secrets',
    'runtime_sessions', 'validation_artifacts', 'observability_data', 'public_receipts', 'workdir', 'london_deploy',
    'exports', 'raw', '.tmp.drivedownload', '.tmp.driveupload'
)
$excludedExtensions = @('.db', '.sqlite', '.sqlite3', '.sqlite-wal', '.sqlite-shm', '.wal', '.shm', '.log', '.lock', '.pyc', '.pyo', '.pyd', '.parquet', '.jsonl', '.tar', '.gz', '.xz', '.7z', '.rar', '.zip', '.vhdx', '.pem', '.key', '.p12', '.pfx', '.pdf', '.example')
$excludedNames = @('.env', '.env.local', '.env.production', '.env.example', '.dev.vars', 'id_rsa', 'id_ed25519')
$textExtensions = @('.py', '.rs', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.json', '.toml', '.yaml', '.yml', '.md', '.txt', '.ps1', '.bat', '.cmd', '.sh', '.ini', '.conf', '.service', '.html', '.css', '.sql', '.csv', '.xml')
$secretRules = @(
    @{ Name = 'provider-secret'; Pattern = '(?im)(api[_-]?key|api[_-]?secret|secret|token|password|private[_-]?key)\s*[:=]\s*["'']?[A-Za-z0-9_./-]{20,}' },
    @{ Name = 'OpenAI-or-OpenRouter-key'; Pattern = 'sk-(?:or-v1-)?[A-Za-z0-9_-]{20,}' },
    @{ Name = 'GitHub-token'; Pattern = 'gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}' },
    @{ Name = 'Google-key'; Pattern = 'AIza[0-9A-Za-z_-]{20,}' },
    @{ Name = 'Telegram-token'; Pattern = '\b\d{8,12}:[A-Za-z0-9_-]{25,}\b' },
    @{ Name = 'AWS-key'; Pattern = 'AKIA[0-9A-Z]{16}' }
)

function Test-ExcludedRelativePath {
    param([string]$RelativePath, [System.IO.FileInfo]$File)
    $segments = $RelativePath -split '[\\/]'
    foreach ($segment in $segments[0..([Math]::Max(0, $segments.Count - 2))]) {
        if ($excludedDirectories -contains $segment) { return $true }
    }
    if ($excludedNames -contains $File.Name) { return $true }
    if ($File.Name -like '.env.*') { return $true }
    if ($excludedExtensions -contains $File.Extension.ToLowerInvariant()) { return $true }
    if ($File.Length -gt 20MB) { return $true }
    return $false
}

function Get-SecretMatchName {
    param([System.IO.FileInfo]$File)
    if ($File.Length -gt 2MB -or $textExtensions -notcontains $File.Extension.ToLowerInvariant()) { return $null }
    try { $content = [System.IO.File]::ReadAllText($File.FullName) } catch { return 'unreadable-text-file' }
    foreach ($rule in $secretRules) {
        if ($content -match $rule.Pattern) { return $rule.Name }
    }
    return $null
}

function Get-PublicSourceFiles {
    param([string]$SourceRoot)

    # Walk only allowed directories. Get-ChildItem -Recurse still enumerates a large
    # node_modules or data tree before a file-level exclusion can reject it.
    $pending = [System.Collections.Generic.Stack[string]]::new()
    $pending.Push($SourceRoot)
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($item in (Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop)) {
            if ($item.PSIsContainer) {
                if ($excludedDirectories -notcontains $item.Name) {
                    $pending.Push($item.FullName)
                }
            } else {
                $item
            }
        }
    }
}

function Write-TextFile {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Git {
    param([string]$WorkingDirectory, [string[]]$Arguments)
    & git -c "safe.directory=$WorkingDirectory" -C $WorkingDirectory @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed in $WorkingDirectory" }
}

function Invoke-GitHubApi {
    param([ValidateSet('Get', 'Post', 'Patch', 'Put')][string]$Method, [string]$Path, [object]$Body)
    $headers = @{ Authorization = "Bearer $GitHubToken"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'portfolio-publisher' }
    $params = @{ Uri = "https://api.github.com$Path"; Headers = $headers; Method = $Method; TimeoutSec = 30 }
    if ($null -ne $Body) { $params.ContentType = 'application/json'; $params.Body = ($Body | ConvertTo-Json -Depth 10) }
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        try { return Invoke-RestMethod @params }
        catch {
            $errorText = "$($_.Exception.Message) $($_.ErrorDetails.Message)"
            $isSecondaryLimit = $errorText -match 'secondary rate limit'
            if (-not $isSecondaryLimit -or $attempt -eq 6) { throw }
            $delaySeconds = [Math]::Min(600, 60 * $attempt)
            Write-Host "GitHub secondary rate limit; retrying $Method $Path in $delaySeconds seconds (attempt $attempt of 6)."
            Start-Sleep -Seconds $delaySeconds
        }
    }
}

function Ensure-GitHubRepository {
    param([hashtable]$Project)
    $repoPath = "/repos/$GitHubUsername/$($Project.Repo)"
    try { $existing = Invoke-GitHubApi -Method Get -Path $repoPath -Body $null }
    catch {
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) {
            $existing = Invoke-GitHubApi -Method Post -Path '/user/repos' -Body @{ name = $Project.Repo; description = $Project.Description; private = ($Visibility -eq 'private'); has_issues = $true; has_projects = $true; auto_init = $false }
        } else { throw }
    }
    if ($existing.private -and $Visibility -eq 'public') {
        throw "Refusing to make an existing private repository public automatically: $($Project.Repo). Use a fresh portfolio repository name or change visibility manually after review."
    }
}

function Test-RemoteMainBranch {
    param([string]$Repo)
    $remote = "https://github.com/$GitHubUsername/$Repo.git"
    $result = & git ls-remote --heads $remote 'refs/heads/main' 2>$null
    return $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($result -join ''))
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot = Join-Path $StageRoot "portfolio-export-$timestamp"
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$manifestRows = @()

foreach ($project in $projects) {
    if (-not (Test-Path -LiteralPath $project.Source)) { throw "Missing canonical source: $($project.Source)" }
    $destination = Join-Path $runRoot $project.Repo
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $copied = 0
    $omitted = @()
    foreach ($sourceFile in (Get-PublicSourceFiles -SourceRoot $project.Source)) {
        $relative = $sourceFile.FullName.Substring($project.Source.TrimEnd('\\').Length).TrimStart('\\')
        if (Test-ExcludedRelativePath -RelativePath $relative -File $sourceFile) {
            $omitted += "$relative | policy-excluded"
        } else {
            $secretReason = Get-SecretMatchName -File $sourceFile
            if ($secretReason) {
                $omitted += "$relative | $secretReason"
            } else {
                $target = Join-Path $destination $relative
                $targetDir = Split-Path -Parent $target
                if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                Copy-Item -LiteralPath $sourceFile.FullName -Destination $target -Force
                $copied++
            }
        }
    }
    $securityReport = @(
        '# Public export security report',
        '',
        "Source: ``$($project.Source)``",
        "Status: $($project.Status)",
        "Files copied: $copied",
        "Files omitted: $($omitted.Count)",
        '',
        'Excluded runtime data includes secrets, environment files, credentials, session files, databases, logs, caches, archives, generated artifacts, and files above 20 MB.',
        '',
        '## Omitted paths',
        ''
    ) + $(if ($omitted.Count) { $omitted | ForEach-Object { "- ``$_``" } } else { '- None.' })
    Write-TextFile -Path (Join-Path $destination 'PUBLIC_EXPORT_SECURITY.md') -Content ($securityReport -join "`n")
    $portfolioNote = @(
        "# $($project.Name)",
        '',
        $project.Description,
        '',
        "**Portfolio status:** $($project.Status).",
        '',
        'This public export is generated from the latest local canonical source. It intentionally excludes runtime credentials, environment files, user sessions, databases, raw market data, logs, caches, and deployment artifacts. See `PUBLIC_EXPORT_SECURITY.md` for the export record.',
        '',
        'Backtest and research material is included where it was available as source-controlled documentation and passed the public-export screening. A result is research evidence, not a claim of future investment performance.'
    ) -join "`n"
    Write-TextFile -Path (Join-Path $destination 'PORTFOLIO.md') -Content $portfolioNote
    Write-TextFile -Path (Join-Path $destination '.gitignore') -Content @"
.env
.env.*
!.env.example
*.db
*.sqlite*
*.log
*.session*
__pycache__/
.venv/
venv/
node_modules/
data/
cache/
logs/
state/
credentials/
secrets/
"@
    $manifestRows += [pscustomobject]@{ Name = $project.Name; Repo = $project.Repo; Status = $project.Status; Source = $project.Source; FilesCopied = $copied; FilesOmitted = $omitted.Count; Url = "https://github.com/$GitHubUsername/$($project.Repo)" }
}

$catalog = @(
    '# Project Portfolio',
    '',
    'This index links public, sanitized source exports of selected software, research, and trading-system projects.',
    '',
    '## Safety and scope',
    '',
    'No repository is a deployment bundle. Credentials, exchange keys, environment files, databases, raw data, user sessions, logs, and oversized generated artifacts are excluded. Trading-related repositories are research and engineering portfolios, not financial advice or an offer to trade.',
    '',
    '## Projects',
    ''
)
foreach ($row in $manifestRows) { $catalog += "- [$($row.Name)]($($row.Url)) — $($row.Status)." }
Write-TextFile -Path (Join-Path $runRoot 'PORTFOLIO_INDEX.md') -Content ($catalog -join "`n")
$manifestRows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runRoot 'portfolio-manifest.json') -Encoding utf8

Write-Host "Staging complete: $runRoot"
$manifestRows | Format-Table Name,Repo,FilesCopied,FilesOmitted,Status -AutoSize

if (-not $Publish) { Write-Host 'Stage-only mode complete. Review the generated export before publishing.'; exit 0 }

$basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$GitHubToken"))
foreach ($row in $manifestRows) {
    $project = $projects | Where-Object { $_.Repo -eq $row.Repo } | Select-Object -First 1
    $repoPath = Join-Path $runRoot $row.Repo
    if ($Resume -and (Test-RemoteMainBranch -Repo $row.Repo)) {
        Write-Host "Skipping already-published repository: $($row.Repo)"
        continue
    }
    Ensure-GitHubRepository -Project $project
    Invoke-Git -WorkingDirectory $repoPath -Arguments @('init', '--initial-branch', 'main')
    Invoke-Git -WorkingDirectory $repoPath -Arguments @('add', '-A')
    & git -c "safe.directory=$repoPath" -C $repoPath diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Invoke-Git -WorkingDirectory $repoPath -Arguments @('-c', 'user.name=Portfolio Publisher', '-c', "user.email=$GitHubUsername@users.noreply.github.com", 'commit', '-m', 'Publish sanitized portfolio export')
    }
    Invoke-Git -WorkingDirectory $repoPath -Arguments @('remote', 'add', 'origin', "https://github.com/$GitHubUsername/$($row.Repo).git")
    & git -c "safe.directory=$repoPath" -C $repoPath -c "http.extraheader=AUTHORIZATION: basic $basic" push --set-upstream origin main
    if ($LASTEXITCODE -ne 0) { throw "Push failed for $($row.Repo)" }
}

$indexRepo = 'portfolio-project-index'
$indexPath = Join-Path $runRoot $indexRepo
New-Item -ItemType Directory -Path $indexPath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $runRoot 'PORTFOLIO_INDEX.md') -Destination (Join-Path $indexPath 'README.md')
Copy-Item -LiteralPath (Join-Path $runRoot 'portfolio-manifest.json') -Destination (Join-Path $indexPath 'portfolio-manifest.json')
$indexProject = @{ Repo = $indexRepo; Description = 'Public index of selected software and research projects.'; Topics = @('portfolio', 'software', 'research'); Name = 'Project Portfolio'; Status = 'index'; Source = $runRoot }
Ensure-GitHubRepository -Project $indexProject
Invoke-Git -WorkingDirectory $indexPath -Arguments @('init', '--initial-branch', 'main')
Invoke-Git -WorkingDirectory $indexPath -Arguments @('add', '-A')
Invoke-Git -WorkingDirectory $indexPath -Arguments @('-c', 'user.name=Portfolio Publisher', '-c', "user.email=$GitHubUsername@users.noreply.github.com", 'commit', '-m', 'Publish portfolio index')
Invoke-Git -WorkingDirectory $indexPath -Arguments @('remote', 'add', 'origin', "https://github.com/$GitHubUsername/$indexRepo.git")
& git -c "safe.directory=$indexPath" -C $indexPath -c "http.extraheader=AUTHORIZATION: basic $basic" push --set-upstream origin main
if ($LASTEXITCODE -ne 0) { throw "Push failed for $indexRepo" }
Write-Host "Published index: https://github.com/$GitHubUsername/$indexRepo"
