<#
.SYNOPSIS
    PromptKit OS 1-Click Setup Script for Windows (PowerShell)
    Supports profiles: --lite, --balanced (default), --turbo --experimental
.DESCRIPTION
    Initializes PromptKit OS in your project:
    - Scaffolds project documentation directories (docs/adrs, docs/specs, docs/rca, docs/spikes, docs/design)
    - Creates PROMPTKIT.md project profile if missing, injects profile: lite|balanced|turbo
    - Injects or updates PromptKit OS directives in AGENTS.md, CLAUDE.md, GEMINI.md, .cursorrules, .cursor/rules/*.mdc, .windsurfrules, .github/copilot-instructions.md, .clinerules, .traerules, .opencode/rules.md, or CONVENTIONS.md (Aider)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [Alias("ProjectRoot")]
    [string]$TargetDir = "",
    [ValidateSet("lite","balanced","turbo")]
    [string]$Profile = "balanced",
    [switch]$Lite,
    [switch]$Balanced,
    [switch]$Turbo,
    [switch]$Experimental,
    [ValidateSet("local","github","jira","linear")]
    [string]$Tracking = "local",
    [string]$Hosts = "",
    [string]$AddHost = "",
    [string[]]$Target = @(),
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Remaining = @()
)

$ErrorActionPreference = "Stop"

# Host map + probes (defined up front: param handling below calls Get-HostFile).
function Get-HostFile($Name) {
    switch ($Name) {
        "agents" { return "AGENTS.md" }
        "claude" { return "CLAUDE.md" }
        "opencode" { return ".opencode/rules.md" }
        "cursor" { return ".cursorrules" }
        "gemini" { return "GEMINI.md" }
        "windsurf" { return ".windsurfrules" }
        "copilot" { return ".github/copilot-instructions.md" }
        "cline" { return ".clinerules" }
        "trae" { return ".traerules" }
        "aider" { return "CONVENTIONS.md" }
        default { return "" }
    }
}
$KnownHostsList = @("claude","opencode","cursor","gemini","windsurf","copilot","cline","trae","aider")

if ($Help) {
    Write-Host "`nPromptKit OS init.ps1 — 1-Click Setup`n" -ForegroundColor Cyan
    Write-Host "Usage: .\init.ps1 [options] [project-root]`n"
    Write-Host "Options:"
    Write-Host "  --lite              Lite profile: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value"
    Write-Host "  --balanced          Balanced profile: the full workflow set, Level 0-3 adaptive ceremony (default)"
    Write-Host "  --turbo             Turbo profile: Balanced + parallel subagent waves, up to ~2x measured token cost"
    Write-Host "  --experimental      Required for --turbo, acknowledges experimental cost and warnings"
    Write-Host "  --tracking=local|github|jira|linear  Task tracker (default: local; jira/linear = manual import)"
    Write-Host "  --host=a,b,c        AI hosts to configure (comma-separated from: claude,opencode,cursor,gemini,windsurf,copilot,cline,trae,aider)"
    Write-Host "  --add-host=name     Add one host to an existing install (agents = universal AGENTS.md)"
    Write-Host "  --target=rel/path   Custom directive file (project-relative, repeatable; e.g. docs/AI.md)"
    Write-Host "  -Help               Show this help`n"
    Write-Host "Interactive (TTY): If no profile flag is given and running in interactive host,"
    Write-Host "  prompts visually: 1) Lite (Recommended) 2) Balanced (default) 3) Turbo (Experimental)"
    Write-Host "  Env escape hatch: PROMPTKIT_NO_INTERACTIVE=1 skips the picker even in a TTY`n"
    Write-Host "Profiles stored in PROMPTKIT.md as 'profile: lite|balanced|turbo'"
    Write-Host "Examples:"
    Write-Host "  .\init.ps1 --lite"
    Write-Host "  .\init.ps1 --balanced C:\path\to\project"
    Write-Host "  .\init.ps1 --turbo --experimental"
    Write-Host "  .\init.ps1 (interactive picker when TTY)`n"
    exit 0
}

# Handle switch aliases (allow --lite style via PS args parsing quirks)
$ProfileSet = $false
$TrackingSet = $false
$HostSet = $false
if ($Hosts -ne "") { $HostSet = $true }
if ($AddHost -ne "") {
    if ((Get-HostFile $AddHost) -eq "") {
        Write-Host "[!] Unknown host: $AddHost" -ForegroundColor Red
        exit 1
    }
    $Hosts = "agents,$AddHost"
    $HostSet = $true
}
$ExtraTargets = @() + $Target
if ($PSBoundParameters.ContainsKey("Tracking")) { $TrackingSet = $true }
if ($Lite) { $Profile = "lite"; $ProfileSet = $true }
if ($Balanced) { $Profile = "balanced"; $ProfileSet = $true }
if ($Turbo) { $Profile = "turbo"; $ProfileSet = $true }

# Also check $args for --lite style (when called via pwsh -File with --lite).
# Tokens PowerShell cannot bind (notably --name=value with a double dash) land
# in $Remaining instead of throwing, so merge both sources before parsing.
$AllArgs = @($args) + @($Remaining)
foreach ($a in $AllArgs) {
    switch ($a) {
        "--lite" { $Profile = "lite"; $ProfileSet = $true }
        "--balanced" { $Profile = "balanced"; $ProfileSet = $true }
        "--turbo" { $Profile = "turbo"; $ProfileSet = $true }
        "--experimental" { $Experimental = $true }
        "--tracking=local" { $Tracking = "local"; $TrackingSet = $true }
        "--tracking=github" { $Tracking = "github"; $TrackingSet = $true }
        "--tracking=jira" { $Tracking = "jira"; $TrackingSet = $true }
        "--tracking=linear" { $Tracking = "linear"; $TrackingSet = $true }
        { $_ -like "--host=*" } { $Hosts = $_.Substring(7); $HostSet = $true }
        { $_ -like "--add-host=*" } {
            $ah = $_.Substring(11)
            if ((Get-HostFile $ah) -eq "" -and $ah -ne "agents") {
                Write-Host "[!] Unknown host: $ah" -ForegroundColor Red
                exit 1
            }
            $Hosts = "agents,$ah"
            $HostSet = $true
        }
        { $_ -like "--target=*" } {
            $tp = $_.Substring(9)
            if ($tp.StartsWith("/") -or $tp -match '\.\.' -or [string]::IsNullOrWhiteSpace($tp)) {
                Write-Host "[!] --target must be a project-relative path without '..': $tp" -ForegroundColor Red
                exit 1
            }
            $ExtraTargets += $tp
        }
        "--help" { 
            Write-Host "`nPromptKit OS init.ps1 — 1-Click Setup`n" -ForegroundColor Cyan
            Write-Host "Usage: .\init.ps1 [options] [project-root]`n"
            Write-Host 'PROMPTKIT_NO_PREFLIGHT=1 skips advisory local security inspection independently of PROMPTKIT_NO_INTERACTIVE.'
            exit 0
        }
        default {
            if ($a -notlike "--*" -and $TargetDir -eq "") {
                $TargetDir = $a
            }
        }
    }
}

# Interactive TTY picker when no profile flag provided (visual decision for onboarding)
# Shell-level equivalent of native interactive selection tools (ask_question)
# Agent-level picker is in workflows/onboard.md
# Non-interactive safety (#144): VS Code integrated terminals can report UserInteractive with
# redirected streams, so also require stdout not redirected, and honor the documented
# PROMPTKIT_NO_INTERACTIVE escape hatch to force the flag/default (non-interactive) path.
if (-not $ProfileSet -and -not $Experimental -and [Environment]::UserInteractive `
    -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected `
    -and [string]::IsNullOrEmpty($env:PROMPTKIT_NO_INTERACTIVE)) {
    Write-Host "`n💡 PromptKit OS Profile Selection (visual decision)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  1) Lite (Recommended for new users) — 6 utility workflows, 961 tok, 80% value, fastest onboarding" -ForegroundColor Yellow
    Write-Host "  2) Balanced (Recommended for teams) — 24 workflows, 2,319 tok, Level 0-3 adaptive ceremony [default]" -ForegroundColor White
    Write-Host "  3) Turbo (Experimental) — Balanced + parallel waves, ~2x measured cost, still requires human L3 approval" -ForegroundColor DarkGray
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "Profiles stored in PROMPTKIT.md as 'profile: lite|balanced|turbo'"
    Write-Host "For CI/non-interactive, use flags: --lite, --balanced, --turbo --experimental`n" -ForegroundColor DarkGray
    $choice = Read-Host "Choose profile [1-3, default 2]"
    switch ($choice) {
        "1" { $Profile = "lite"; $ProfileSet = $true }
        "3" { 
            Write-Host "`n⚠️  Turbo requires --experimental flag" -ForegroundColor Yellow
            Write-Host "   Turbo uses parallel subagent waves (up to ~2x measured token cost) and is experimental." -ForegroundColor DarkGray
            $confirm = Read-Host "Acknowledge experimental cost and proceed with Turbo? [y/N]"
            if ($confirm -match "^[Yy]$") {
                $Profile = "turbo"
                $Experimental = $true
                $ProfileSet = $true
            } else {
                Write-Host "Defaulting to Balanced" -ForegroundColor DarkGray
                $Profile = "balanced"
                $ProfileSet = $true
            }
        }
        default { $Profile = "balanced"; $ProfileSet = $true }
    }
    Write-Host ""
}

if (-not $TrackingSet -and [Environment]::UserInteractive `
    -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected `
    -and [string]::IsNullOrEmpty($env:PROMPTKIT_NO_INTERACTIVE)) {
    Write-Host "`n💡 Task Tracker Selection (visual decision)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  1) Local Markdown (Recommended for solo / offline) — docs/tasks/ only" -ForegroundColor Yellow
    Write-Host "  2) GitHub Issues — via gh CLI or MCP, needs gh auth" -ForegroundColor White
    Write-Host "  3) Jira — manual import, no auto-push" -ForegroundColor DarkGray
    Write-Host "  4) Linear — manual import, no auto-push" -ForegroundColor DarkGray
    Write-Host "  Tip: combine local with GitHub projection, e.g. '1,2' or '1 and 2'."
    Write-Host ""
    $TrackingProjection = ""
    $trackerAttempts = 0
    while ($true) {
        $tchoice = Read-Host "Choose tracker [1-4, combos like 1,2 allowed, default 1]"
        if ([string]::IsNullOrWhiteSpace($tchoice)) { $Tracking = "local"; break }
        $norm = $tchoice.ToLower() -replace '\band\b',' ' -replace '[,&+]',' ' -replace '[^0-9 ]',''
        $norm = ($norm -split '\s+' | Where-Object { $_ -ne '' }) -join ' '
        $toks = @($norm -split ' ' | Where-Object { $_ -ne '' })
        $bad = @($toks | Where-Object { $_ -notin @('1','2','3','4') }).Count -gt 0
        if ($toks.Count -eq 0) { $bad = $true }
        $has1 = $toks -contains '1'; $has2 = $toks -contains '2'
        $has3 = $toks -contains '3'; $has4 = $toks -contains '4'
        $comboOk = -not $bad -and (($has3 -eq $false) -or (-not $has1 -and -not $has2 -and -not $has4)) -and (($has4 -eq $false) -or (-not $has1 -and -not $has2 -and -not $has3))
        if ($comboOk) {
            if ($has1 -or (-not $has2 -and -not $has3 -and -not $has4)) {
                $Tracking = "local"
                if ($has2) { $TrackingProjection = "github" }
            } elseif ($has2) { $Tracking = "github" }
            elseif ($has3) { $Tracking = "jira" }
            else { $Tracking = "linear" }
            break
        }
        $trackerAttempts++
        if ($trackerAttempts -ge 3) {
            Write-Host "[!] Unrecognized tracker selection after 3 attempts — defaulting to Local Markdown." -ForegroundColor Yellow
            $Tracking = "local"
            break
        }
        Write-Host "[!] Could not parse '$tchoice'. Use numbers 1-4 (e.g. 1, 2, or 1,2 for local + GitHub projection)." -ForegroundColor Yellow
    }
    $TrackingSet = $true
    Write-Host ""
}

if ($Profile -eq "turbo" -and -not $Experimental) {
    Write-Host "`n[!] --turbo requires --experimental flag" -ForegroundColor Red
    Write-Host "   Turbo uses parallel subagent waves (up to ~2x measured token cost) and is experimental." -ForegroundColor DarkGray
    Write-Host "   It still requires human approval for Level 3 (releases/tags/deploys)." -ForegroundColor DarkGray
    Write-Host "   Run: .\init.ps1 --turbo --experimental [project-root]`n" -ForegroundColor DarkGray
    exit 1
}

# Determine PromptKit OS directory and Host Project Root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($TargetDir -ne "") {
    $ProjectRoot = Resolve-Path $TargetDir
} elseif ((Split-Path -Leaf $ScriptDir) -in @(".promptkit", "promptkit")) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..")
} else {
    $ProjectRoot = Resolve-Path "."
}

$ProjectRootPath = if ($ProjectRoot.Path) { $ProjectRoot.Path } else { $ProjectRoot.ToString() }

Write-Host "`n🚀 Initializing PromptKit OS ($Profile profile)..." -ForegroundColor Cyan
Write-Host "   Host Project: $ProjectRoot" -ForegroundColor DarkGray
Write-Host "   Engine Path:  $ScriptDir" -ForegroundColor DarkGray
Write-Host "   Profile:      $Profile" -ForegroundColor DarkGray
Write-Host "   Tracking:     $Tracking" -ForegroundColor DarkGray
if ($Profile -eq "turbo") {
    Write-Host "   ⚠️  Turbo: up to ~2x measured token cost, experimental, parallel waves. Human approval still required for L3." -ForegroundColor Yellow
}
if ($Profile -eq "lite") {
    Write-Host "   ✨ Lite: 6 utility workflows, <1,500 tok, 80% value — perfect for onboarding" -ForegroundColor Green
}
Write-Host ""

if ($env:PROMPTKIT_NO_PREFLIGHT -eq '1') {
    Write-Output 'PREFLIGHT|SKIPPED|USER_OPT_OUT'
} else {
    $savedExitCode = $global:LASTEXITCODE
    try {
        & (Join-Path $ScriptDir 'scripts/check-harness-security.ps1') -Root $ProjectRootPath
        if ($LASTEXITCODE -ne 0) {
            Write-Output 'PREFLIGHT|ADVISORY|Review findings or incomplete checks; installation continues'
        }
    } catch {
        Write-Output 'PREFLIGHT|INCOMPLETE|SCANNER_UNAVAILABLE'
    } finally {
        $global:LASTEXITCODE = $savedExitCode
    }
}

# 1. Ensure Core Documentation Directories Exist in Host Project
$DocDirs = @(
    "docs/tasks",
    "docs/specs",
    "docs/adrs",
    "docs/tests"
)

foreach ($dir in $DocDirs) {
    $fullPath = Join-Path $ProjectRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  [+] Created directory: $dir" -ForegroundColor Green
    }
}

# 2. Scaffold PROMPTKIT.md if missing + inject profile
$ProjectProfile = Join-Path $ProjectRoot "PROMPTKIT.md"
$TemplateProfile = Join-Path $ScriptDir "templates/project-profile-template.md"

if (-not (Test-Path $ProjectProfile)) {
    if (Test-Path $TemplateProfile) {
        Copy-Item -Path $TemplateProfile -Destination $ProjectProfile
        Write-Host "  [+] Created: PROMPTKIT.md (project profile & guardrails)" -ForegroundColor Green
    }
} else {
    Write-Host "  [✓] PROMPTKIT.md already present" -ForegroundColor DarkGray
}

# Inject or update profile field in PROMPTKIT.md (2+1 modes)
if (Test-Path $ProjectProfile) {
    $content = Get-Content $ProjectProfile -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { $content = "" }
    if ($content -match "^profile:") {
        $content = $content -replace "^profile:.*", "profile: $Profile"
        $content = $content -replace "^- \*\*Profile\*\*:.*", "- **Profile**: $Profile"
        [System.IO.File]::WriteAllText($ProjectProfile, $content, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  [✓] Updated PROMPTKIT.md profile: $Profile" -ForegroundColor Yellow
    } else {
        $firstLine = (Get-Content $ProjectProfile -TotalCount 1 -ErrorAction SilentlyContinue)
        $rest = ""
        if ((Get-Content $ProjectProfile | Measure-Object).Count -gt 1) {
            $rest = (Get-Content $ProjectProfile | Select-Object -Skip 1 | Out-String)
        }
        $profileSection = @"

## 0. PromptKit OS Profile
- **Profile**: $Profile
- **Installed**: $(Get-Date -Format "yyyy-MM-dd")
- **Engine**: .promptkit
- **Upgrade**: Run `.promptkit/init.ps1 --balanced` for the full Balanced profile, or `--turbo --experimental` for parallel waves

"@
        $newContent = "$firstLine`n$profileSection`n$rest`n`nprofile: $Profile`n"
        [System.IO.File]::WriteAllText($ProjectProfile, $newContent, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  [+] Set PROMPTKIT.md profile: $Profile" -ForegroundColor Green
    }
    $tcontent = Get-Content $ProjectProfile -Raw -ErrorAction SilentlyContinue
    if ($tcontent -match "^tracking:") {
        $tcontent = $tcontent -replace "^tracking:.*", "tracking: $Tracking"
    } else {
        $tcontent = "$tcontent`n`ntracking: $Tracking`n"
    }
    [System.IO.File]::WriteAllText($ProjectProfile, $tcontent, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  [✓] Updated PROMPTKIT.md tracking: $Tracking" -ForegroundColor Yellow
    if (-not [string]::IsNullOrEmpty($TrackingProjection)) {
        $pcontent = Get-Content $ProjectProfile -Raw -ErrorAction SilentlyContinue
        if ($pcontent -match "^projection:") {
            $pcontent = $pcontent -replace "^projection:.*", "projection: $TrackingProjection"
        } else {
            $pcontent = "$pcontent`n`nprojection: $TrackingProjection`n"
        }
        [System.IO.File]::WriteAllText($ProjectProfile, $pcontent, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  [✓] Updated PROMPTKIT.md projection: $TrackingProjection" -ForegroundColor Yellow
    }
}

$DesignProfile = Join-Path $ProjectRoot "DESIGN.md"
if (Test-Path $DesignProfile) {
    Write-Host "  [✓] DESIGN.md detected (brand identity & anti-slop rules)" -ForegroundColor DarkGray
}

# Scaffold docs/STATE.md if missing
$DocsDir = Join-Path $ProjectRoot "docs"
$StateTracker = Join-Path $DocsDir "STATE.md"
$TemplateState = Join-Path $ScriptDir "templates/state-tracker-template.md"

if (-not (Test-Path $StateTracker)) {
    if (Test-Path $TemplateState) {
        if (-not (Test-Path $DocsDir)) {
            New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
        }
        Copy-Item -Path $TemplateState -Destination $StateTracker
        Write-Host "  [+] Created: docs/STATE.md (living project & state tracker)" -ForegroundColor Green
    }
} else {
    Write-Host "  [✓] docs/STATE.md already present" -ForegroundColor DarkGray
}

# Scaffold .github/pull_request_template.md if missing
$GitHubDir = Join-Path $ProjectRoot ".github"
$PrTemplateTarget = Join-Path $GitHubDir "pull_request_template.md"
$TemplatePr = Join-Path $ScriptDir "templates/pull-request-template.md"

if (-not (Test-Path $PrTemplateTarget)) {
    if (Test-Path $TemplatePr) {
        if (-not (Test-Path $GitHubDir)) {
            New-Item -ItemType Directory -Path $GitHubDir -Force | Out-Null
        }
        Copy-Item -Path $TemplatePr -Destination $PrTemplateTarget
        Write-Host "  [+] Created: .github/pull_request_template.md (staff-level PR specification)" -ForegroundColor Green
    }
} else {
    Write-Host "  [✓] .github/pull_request_template.md already present" -ForegroundColor DarkGray
}

# Scaffold .github/ISSUE_TEMPLATE/task.md if missing
$IssueTemplateDir = Join-Path $GitHubDir "ISSUE_TEMPLATE"
$TaskTemplateTarget = Join-Path $IssueTemplateDir "task.md"
$TemplateTask = Join-Path $ScriptDir "templates/github-issue-template.md"

if (-not (Test-Path $TaskTemplateTarget)) {
    if (Test-Path $TemplateTask) {
        if (-not (Test-Path $IssueTemplateDir)) {
            New-Item -ItemType Directory -Path $IssueTemplateDir -Force | Out-Null
        }
        Copy-Item -Path $TemplateTask -Destination $TaskTemplateTarget
        Write-Host "  [+] Created: .github/ISSUE_TEMPLATE/task.md (standard task specification)" -ForegroundColor Green
    }
} else {
    Write-Host "  [✓] .github/ISSUE_TEMPLATE/task.md already present" -ForegroundColor DarkGray
}



# 2b. Host probing + selection (which AI assistants get directive files)
# Probes are best-effort suggestions only; the TTY menu (or --host=) is authoritative.
# AGENTS.md is always created fresh as the universal fallback standard.
if ($HostSet) {
    foreach ($h in ($Hosts -split ',')) {
        if ((Get-HostFile $h) -eq "") {
            Write-Host "[!] Unknown host: $h (use comma-separated from: $($KnownHostsList -join ','))" -ForegroundColor Red
            exit 1
        }
    }
}
function Test-HostDetected($Name) {
    switch ($Name) {
        "claude" { return ($null -ne (Get-Command claude -ErrorAction SilentlyContinue)) }
        "opencode" { return ($null -ne (Get-Command opencode -ErrorAction SilentlyContinue)) -or (Test-Path (Join-Path $HOME ".config/opencode")) }
        "cursor" { return ($null -ne (Get-Command cursor -ErrorAction SilentlyContinue)) -or (Test-Path (Join-Path $HOME ".cursor")) }
        "gemini" { return ($null -ne (Get-Command gemini -ErrorAction SilentlyContinue)) }
        "windsurf" { return ($null -ne (Get-Command windsurf -ErrorAction SilentlyContinue)) -or (Test-Path (Join-Path $HOME ".windsurf")) }
        "copilot" { return ($null -ne (Get-Command copilot -ErrorAction SilentlyContinue)) }
        "cline" { return (Test-Path (Join-Path $HOME ".config/cline")) -or (Test-Path (Join-Path $HOME ".cline")) }
        "trae" { return ($null -ne (Get-Command trae -ErrorAction SilentlyContinue)) }
        "aider" { return ($null -ne (Get-Command aider -ErrorAction SilentlyContinue)) }
        default { return $false }
    }
}
$DetectedHosts = @()
if (-not $HostSet) {
    foreach ($h in $KnownHostsList) {
        if (Test-HostDetected $h) { $DetectedHosts += $h }
    }
}
$IsTTY = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected -and [string]::IsNullOrEmpty($env:PROMPTKIT_NO_INTERACTIVE)
if (-not $HostSet -and -not $IsTTY) {
    # Non-interactive: a single unambiguous probe hit wins; zero or many
    # fall back to the deterministic legacy pair (never guess among several).
    if ($DetectedHosts.Count -eq 1) {
        $Hosts = $DetectedHosts[0]
        $HostSet = $true
    }
}
if (-not $HostSet -and $IsTTY) {
    Write-Host "`n💡 AI Host Selection (visual decision)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    $idx = 0
    foreach ($h in $KnownHostsList) {
        $idx++
        $marker = ""
        if ($DetectedHosts -contains $h) { $marker = " [detected]" }
        Write-Host "  $idx) $h$marker — $(Get-HostFile $h)"
    }
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    if ($DetectedHosts.Count -gt 0) {
        Write-Host "Comma-separated numbers, Enter = detected ($($DetectedHosts -join ',')) + AGENTS.md" -ForegroundColor DarkGray
    } else {
        Write-Host "Comma-separated numbers, Enter = AGENTS.md + CLAUDE.md (default)" -ForegroundColor DarkGray
    }
    Write-Host ""
    $hchoice = Read-Host "Choose hosts"
    if ($hchoice -ne "") {
        $picked = @()
        foreach ($n in ($hchoice -split ',')) {
            $nn = 0
            if ([int]::TryParse($n.Trim(), [ref]$nn) -and $nn -ge 1 -and $nn -le $KnownHostsList.Count) {
                $picked += $KnownHostsList[$nn - 1]
            }
        }
        $Hosts = ($picked | Select-Object -Unique) -join ','
        $HostSet = $true
    } elseif ($DetectedHosts.Count -gt 0) {
        $Hosts = ($DetectedHosts -join ',')
        $HostSet = $true
    }
    Write-Host ""
}

# 3. Detect Agent Files or Default to AGENTS.md
$AgentFileCandidates = @(
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    ".cursorrules",
    ".cursor/rules/promptkit.mdc",
    ".windsurfrules",
    ".github/copilot-instructions.md",
    ".clinerules",
    ".clinerules/promptkit.md",
    ".traerules",
    ".opencode/rules.md",
    "CONVENTIONS.md"   # Aider conventions file
)

$TargetsFound = @()
foreach ($file in $AgentFileCandidates) {
    $path = Join-Path $ProjectRoot $file
    if (Test-Path $path) {
        if (Test-Path $path -PathType Container) {
            if ($file -eq ".clinerules") {
                $dirTarget = Join-Path $path "promptkit.md"
                if (-not (Test-Path $dirTarget)) {
                    New-Item -ItemType File -Path $dirTarget -Force | Out-Null
                }
                $TargetsFound += $dirTarget
            }
        } else {
            $TargetsFound += $path
        }
    }
}

# Custom --target paths ride the same create/inject machinery as host files
foreach ($xp in $ExtraTargets) {
    $xfull = Join-Path $ProjectRoot $xp
    if ($TargetsFound -notcontains $xfull) {
        $xparent = Split-Path -Parent $xfull
        if ($xparent -ne "" -and -not (Test-Path $xparent)) {
            New-Item -ItemType Directory -Path $xparent -Force | Out-Null
        }
        if (-not (Test-Path $xfull)) { New-Item -ItemType File -Path $xfull -Force | Out-Null }
        $TargetsFound += $xfull
        Write-Host "  [+] Added custom target: $xp" -ForegroundColor Green
    }
}
function New-TargetFile($Rel) {
    if ($Rel -eq ".clinerules") {
        $dir = Join-Path $ProjectRoot ".clinerules"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $inner = Join-Path $dir "promptkit.md"
        if (-not (Test-Path $inner)) { New-Item -ItemType File -Path $inner -Force | Out-Null }
        $script:TargetsFound += $inner
        return
    }
    $p = Join-Path $ProjectRoot $Rel
    $parent = Split-Path -Parent $p
    if ($parent -ne "" -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (-not (Test-Path $p)) { New-Item -ItemType File -Path $p -Force | Out-Null }
    $script:TargetsFound += $p
}
$Fresh = ($TargetsFound.Count -eq 0)
# Add selected-host files missing from the detected set (new hosts on existing installs)
if ($HostSet -and $Hosts -ne "") {
    foreach ($h in ($Hosts -split ',')) {
        $rel = Get-HostFile $h.Trim()
        $want = Join-Path $ProjectRoot $rel
        if ($rel -eq ".clinerules") { $want = Join-Path $want "promptkit.md" }
        if ($TargetsFound -notcontains $want) {
            New-TargetFile $rel
            Write-Host "  [+] Added host configuration: $rel" -ForegroundColor Green
        }
    }
}
if ($Fresh) {
    New-TargetFile "AGENTS.md"
    if ($HostSet -and $Hosts -ne "") {
        foreach ($h in ($Hosts -split ',')) {
            $rel = Get-HostFile $h.Trim()
            if ($rel -eq "AGENTS.md") { continue }
            $want = Join-Path $ProjectRoot $rel
            if ($rel -eq ".clinerules") { $want = Join-Path $want "promptkit.md" }
            if ($TargetsFound -notcontains $want) { New-TargetFile $rel }
        }
    } else {
        New-TargetFile "CLAUDE.md"
    }
    $created = @($TargetsFound | ForEach-Object {
        $_.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    }) -join ' '
    Write-Host "  [+] Created default agent configurations: $created" -ForegroundColor Green
}

# 4. Directive Block (Loaded from Canonical Template based on profile)
$KitDirRel = if ($ScriptDir.StartsWith($ProjectRootPath)) {
    $ScriptDir.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
} else {
    ".promptkit"
}

# Select template based on profile: lite uses lite template (961 tok), balanced/turbo use full (2099 tok)
if ($Profile -eq "lite") {
    $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-lite-template.md"
    if (-not (Test-Path $TemplateDirective)) {
        Write-Host "Warning: Lite template not found, falling back to full template" -ForegroundColor Yellow
        $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
    }
} else {
    $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
}

if (Test-Path $TemplateDirective) {
    $RawTemplate = [System.IO.File]::ReadAllText($TemplateDirective, [System.Text.Encoding]::UTF8)
    $Directive = ($RawTemplate -replace '\$KIT_DIR_REL', $KitDirRel).TrimEnd("`r", "`n")
} else {
    throw "Error: Canonical directive template not found at $TemplateDirective"
}

# 5. Inject or Replace Directives (Idempotent)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($targetPath in $TargetsFound) {
    $relTarget = if ($targetPath.StartsWith($ProjectRootPath)) {
        $targetPath.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    } else {
        $targetPath -replace "\\", "/"
    }

    $content = if (Test-Path $targetPath) {
        [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
    } else {
        ""
    }

    $hasStart = $content -match "<!-- PROMPTKIT_START -->"
    $hasEnd = $content -match "<!-- PROMPTKIT_END -->"

    if ($hasStart -or $hasEnd) {
        $lines = $content -split "\r?\n"
        $startIndex = -1
        $endIndex = -1
        $startCount = 0
        $endCount = 0

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $trimmed = $lines[$i].Trim()
            if ($trimmed -eq "<!-- PROMPTKIT_START -->") {
                $startCount++
                if ($startIndex -eq -1) { $startIndex = $i }
            }
            if ($trimmed -eq "<!-- PROMPTKIT_END -->") {
                $endCount++
                if ($endIndex -eq -1) { $endIndex = $i }
            }
        }

        if ($startCount -ne 1 -or $endCount -ne 1 -or $startIndex -ge $endIndex) {
            [System.Console]::Error.WriteLine("Error: Cannot safely update ${relTarget}: expected exactly one complete PromptKit directive block with START before END.")
            throw "Error: Cannot safely update ${relTarget}: expected exactly one complete PromptKit directive block with START before END."
        }

        $isCrlf = $content.Contains("`r`n")
        $targetDirective = if ($isCrlf) {
            ($Directive -split "`r?`n") -join "`r`n"
        } else {
            ($Directive -split "`r?`n") -join "`n"
        }

        $pattern = '(?s)<!-- PROMPTKIT_START -->.*?<!-- PROMPTKIT_END -->'
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $targetDirective }
        $updated = [regex]::Replace($content, $pattern, $evaluator)

        [System.IO.File]::WriteAllText($targetPath, $updated, $utf8NoBom)
        Write-Host "  [✓] Updated PromptKit OS directives in: $relTarget (profile: $Profile)" -ForegroundColor Yellow
    } else {
        $isCrlf = $content.Contains("`r`n")
        $targetDirective = if ($isCrlf) {
            ($Directive -split "`r?`n") -join "`r`n"
        } else {
            ($Directive -split "`r?`n") -join "`n"
        }
        $prefix = ""
        if ($content.Length -gt 0) {
            if ($content.EndsWith("`r`n")) {
                $prefix = "`r`n"
            } elseif ($content.EndsWith("`n")) {
                $prefix = "`n"
            } else {
                $prefix = if ($isCrlf) { "`r`n`r`n" } else { "`n`n" }
            }
        }
        $updated = $content + $prefix + $targetDirective
        [System.IO.File]::WriteAllText($targetPath, $updated, $utf8NoBom)
        Write-Host "  [+] Injected PromptKit OS directives into: $relTarget (profile: $Profile)" -ForegroundColor Green
    }
}

Write-Host "`n✨ PromptKit OS successfully configured for $ProjectRoot! ($Profile profile)" -ForegroundColor Cyan
if ($Profile -eq "lite") {
    Write-Host "   Lite: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) — 80% value, <1,500 tok" -ForegroundColor Green
    Write-Host "   Upgrade anytime: .promptkit/init.ps1 --balanced for the full Balanced profile" -ForegroundColor DarkGray
} elseif ($Profile -eq "balanced") {
    Write-Host "   Balanced: 24 workflows, Level 0-3 adaptive ceremony — full power" -ForegroundColor White
    Write-Host "   For onboarding: .promptkit/init.ps1 --lite for minimal setup" -ForegroundColor DarkGray
} else {
    Write-Host "   Turbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost" -ForegroundColor Yellow
    Write-Host "   Human approval still required for Level 3 (releases/tags/deploys)" -ForegroundColor DarkGray
}
Write-Host "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'`n" -ForegroundColor White
