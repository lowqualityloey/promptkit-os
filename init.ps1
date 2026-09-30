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
    [switch]$Reconfigure,
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

# Canonical path resolution and containment verification (F04 - P2, R3 - P2, R4 - P2)
function Resolve-CanonicalPath {
    param(
        [string]$Path,
        [int]$HopCount = 0
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    if ($HopCount -ge 25) { return [System.IO.Path]::GetFullPath($Path) }

    $p = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($p)
    $remainder = $p.Substring($root.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $parts = $remainder.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    $current = $root
    $i = 0
    while ($i -lt $parts.Length) {
        $part = $parts[$i]
        $i++
        if ([string]::IsNullOrEmpty($part)) { continue }
        $current = [System.IO.Path]::Combine($current, $part)
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($null -ne $item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                $target = $null
                if ($item.PSObject.Properties['Target'] -and $item.Target) {
                    $target = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
                } elseif ($item.PSObject.Properties['LinkTarget'] -and $item.LinkTarget) {
                    $target = $item.LinkTarget
                }
                if (-not [string]::IsNullOrEmpty($target)) {
                    if (-not [System.IO.Path]::IsPathRooted($target)) {
                        $parentDir = [System.IO.Path]::GetDirectoryName($item.FullName)
                        $target = [System.IO.Path]::Combine($parentDir, $target)
                    }
                    if ($i -lt $parts.Length) {
                        $remParts = $parts[$i..($parts.Length - 1)]
                        $target = [System.IO.Path]::Combine(@($target) + @($remParts))
                    }
                    return Resolve-CanonicalPath -Path $target -HopCount ($HopCount + 1)
                }
            }
        }
    }
    return [System.IO.Path]::GetFullPath($current)
}

function Test-PathContained {
    param(
        [string]$ProjectRootPath,
        [string]$TargetPath
    )
    $canonicalRoot = Resolve-CanonicalPath $ProjectRootPath
    $canonicalTarget = Resolve-CanonicalPath $TargetPath
    $canonicalRoot = $canonicalRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }

    if ($canonicalTarget.Equals($canonicalRoot, $comparison)) {
        return $true
    }
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $prefix = $canonicalRoot + $sep
    if ($canonicalTarget.StartsWith($prefix, $comparison)) {
        return $true
    }
    return $false
}

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
    Write-Host "  --reconfigure       Force interactive host re-selection on existing installations"
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
$ExtraTargets = @()
if ($Target) {
    foreach ($t in $Target) {
        if (-not [string]::IsNullOrWhiteSpace($t)) {
            $ExtraTargets += $t
        }
    }
}
if ($PSBoundParameters.ContainsKey("Profile")) { $ProfileSet = $true }
if ($PSBoundParameters.ContainsKey("Tracking")) { $TrackingSet = $true }
if ($PSBoundParameters.ContainsKey("Hosts")) { $HostSet = $true }
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
        "--reconfigure" { $Reconfigure = $true }
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

# Keep installed settings on update re-runs (flags always win over installed values)
$TrackingProjection = ""
$probeRoot = if ($TargetDir -ne "") { $TargetDir } elseif ((Split-Path -Leaf (Split-Path -Parent $MyInvocation.MyCommand.Path)) -in @(".promptkit", "promptkit")) { Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".." } else { (Get-Location).Path }
$probeProfile = Join-Path $probeRoot "PROMPTKIT.md"
if (-not $ProfileSet -and (Test-Path $probeProfile)) {
    $ip = Select-String -Path $probeProfile -Pattern '^profile:\s*(\S+)' | Select-Object -Last 1
    if ($null -ne $ip -and $ip.Matches[0].Groups[1].Value -in @('lite', 'balanced')) {
        $Profile = $ip.Matches[0].Groups[1].Value; $ProfileSet = $true
        Write-Host "  Keeping installed profile: $Profile (pass a flag to change)" -ForegroundColor DarkGray
    } elseif ($null -ne $ip -and $ip.Matches[0].Groups[1].Value -eq 'turbo') {
        $Profile = "turbo"; $Experimental = $true; $ProfileSet = $true
        Write-Host "  Keeping installed profile: turbo (previously acknowledged --experimental)" -ForegroundColor DarkGray
    }
}
if (-not $TrackingSet -and (Test-Path $probeProfile)) {
    $it = Select-String -Path $probeProfile -Pattern '^tracking:\s*(\S+)' | Select-Object -Last 1
    if ($null -ne $it -and $it.Matches[0].Groups[1].Value -in @('local', 'github', 'jira', 'linear')) {
        $Tracking = $it.Matches[0].Groups[1].Value; $TrackingSet = $true
        if ($Tracking -eq "local") {
            $ipr = Select-String -Path $probeProfile -Pattern '^projection:\s*(\S+)' | Select-Object -Last 1
            if ($null -ne $ipr -and $ipr.Matches[0].Groups[1].Value -eq 'github') { $TrackingProjection = "github" }
        }
        $projNote = if ($TrackingProjection -ne "") { " + $TrackingProjection projection" } else { "" }
        Write-Host "  Keeping installed tracker: $Tracking$projNote (pass --tracking= to change)" -ForegroundColor DarkGray
    }
}
if (-not $HostSet -and -not $Reconfigure -and (Test-Path $probeProfile)) {
    $installedHosts = @()
    foreach ($h in $KnownHostsList) {
        $hf = Get-HostFile $h
        if ($hf -ne "" -and (Test-Path (Join-Path $probeRoot $hf))) {
            $installedHosts += $h
        } elseif ($h -eq "cline" -and ((Test-Path (Join-Path $probeRoot ".clinerules")) -or (Test-Path (Join-Path $probeRoot ".clinerules/promptkit.md")))) {
            $installedHosts += $h
        } elseif ($h -eq "cursor" -and ((Test-Path (Join-Path $probeRoot ".cursorrules")) -or (Test-Path (Join-Path $probeRoot ".cursor/rules/promptkit.mdc")))) {
            $installedHosts += $h
        }
    }
    if ($installedHosts.Count -gt 0) {
        $Hosts = ($installedHosts | Select-Object -Unique) -join ','
        $HostSet = $true
        Write-Host "  Keeping installed hosts: $Hosts (pass -Hosts or -Reconfigure to change)" -ForegroundColor DarkGray
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
    Write-Host "  1) Lite (Recommended for new users) — 6 utility workflows, 1,269 tok, 80% value, fastest onboarding" -ForegroundColor Yellow
    Write-Host "  2) Balanced (Recommended for teams) — 25 workflows, 2,318 tok, Level 0-3 adaptive ceremony [default]" -ForegroundColor White
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
            $TrackingProjection = ""
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
            $TrackingProjection = ""
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

$DocDirs = @(
    "docs/tasks",
    "docs/specs",
    "docs/adrs",
    "docs/tests"
)

$ProjectProfile = Join-Path $ProjectRoot "PROMPTKIT.md"
$TemplateProfile = Join-Path $ScriptDir "templates/project-profile-template.md"
$DesignProfile = Join-Path $ProjectRoot "DESIGN.md"
$DocsDir = Join-Path $ProjectRoot "docs"
$StateTracker = Join-Path $DocsDir "STATE.md"
$TemplateState = Join-Path $ScriptDir "templates/state-tracker-template.md"
$GitHubDir = Join-Path $ProjectRoot ".github"
$PrTemplateTarget = Join-Path $GitHubDir "pull_request_template.md"
$TemplatePr = Join-Path $ScriptDir "templates/pull-request-template.md"
$IssueTemplateDir = Join-Path $GitHubDir "ISSUE_TEMPLATE"
$TaskTemplateTarget = Join-Path $IssueTemplateDir "task.md"
$TemplateTask = Join-Path $ScriptDir "templates/github-issue-template.md"
$EngineDir = Split-Path $ScriptDir -Leaf

if (Test-Path -LiteralPath $DesignProfile) {
    Write-Host "  [✓] DESIGN.md detected (brand identity & anti-slop rules)" -ForegroundColor DarkGray
}# 2b. Host probing + selection (which AI assistants get directive files)
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
    $hf = Get-HostFile $Name
    if ($hf -ne "" -and (Test-Path (Join-Path $probeRoot $hf))) { return $true }
    if ($Name -eq "cline" -and ((Test-Path (Join-Path $probeRoot ".clinerules")) -or (Test-Path (Join-Path $probeRoot ".clinerules/promptkit.md")))) { return $true }
    if ($Name -eq "cursor" -and ((Test-Path (Join-Path $probeRoot ".cursorrules")) -or (Test-Path (Join-Path $probeRoot ".cursor/rules/promptkit.mdc")))) { return $true }
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

function Test-IsManagedDestination {
    param([string]$CandidatePath)
    $canonCand = Resolve-CanonicalPath $CandidatePath
    $managed = @($ProjectProfile, $StateTracker, $PrTemplateTarget, $TaskTemplateTarget)
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }
    foreach ($m in $managed) {
        $canonM = Resolve-CanonicalPath $m
        if ($canonCand.Equals($canonM, $comparison)) {
            return $true
        }
    }
    return $false
}

function Add-TargetUnique {
    param([string]$TargetPath)
    $canonWant = Resolve-CanonicalPath $TargetPath
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }
    foreach ($existing in $script:TargetsFound) {
        $canonExist = Resolve-CanonicalPath $existing
        if ($canonWant.Equals($canonExist, $comparison)) {
            return $false
        }
    }
    $script:TargetsFound += $TargetPath
    return $true
}

$TargetsFound = @()
foreach ($file in $AgentFileCandidates) {
    $path = Join-Path $ProjectRoot $file
    if (Test-Path -LiteralPath $path) {
        if (Test-Path -LiteralPath $path -PathType Container) {
            if ($file -eq ".clinerules") {
                Add-TargetUnique (Join-Path $path "promptkit.md") | Out-Null
            }
        } else {
            Add-TargetUnique $path | Out-Null
        }
    }
}

# Custom --target paths (F06 - P2, R6 - P2, R7 - P2)
foreach ($xp in $ExtraTargets) {
    $xfull = Join-Path $ProjectRoot $xp
    if (Test-IsManagedDestination $xfull) {
        throw "Error: Custom target cannot be a managed PromptKit OS file: $xp"
    }
    if (Test-Path -LiteralPath $xfull -PathType Container) {
        throw "Error: Target destination cannot be a directory: $xp"
    }
    if (Add-TargetUnique $xfull) {
        Write-Host "  [+] Added custom target: $xp" -ForegroundColor Green
    }
}

function Register-TargetFile($Rel) {
    $want = Join-Path $ProjectRoot $Rel
    if ($Rel -eq ".clinerules") {
        if (Test-Path -LiteralPath $want -PathType Leaf) {
            # Existing file layout
        } elseif (Test-Path -LiteralPath $want -PathType Container) {
            $want = Join-Path $want "promptkit.md"
        } else {
            $want = Join-Path $want "promptkit.md"
        }
    }
    return (Add-TargetUnique $want)
}

$Fresh = ($TargetsFound.Count -eq 0)
if ($HostSet -and $Hosts -ne "") {
    foreach ($h in ($Hosts -split ',')) {
        $rel = Get-HostFile $h.Trim()
        if (Register-TargetFile $rel) {
            Write-Host "  [+] Added host configuration: $rel" -ForegroundColor Green
        }
    }
}
if ($Fresh) {
    Register-TargetFile "AGENTS.md" | Out-Null
    if ($HostSet -and $Hosts -ne "") {
        foreach ($h in ($Hosts -split ',')) {
            $rel = Get-HostFile $h.Trim()
            if ($rel -eq "AGENTS.md") { continue }
            Register-TargetFile $rel | Out-Null
        }
    } else {
        Register-TargetFile "CLAUDE.md" | Out-Null
    }
    $created = @($TargetsFound | ForEach-Object {
        $_.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    }) -join ' '
    Write-Host "  [+] Created default agent configurations: $created" -ForegroundColor Green
}

# 4. Containment Verification (F04 - P2)
$AllDestinations = @($ProjectProfile, $StateTracker, $PrTemplateTarget, $TaskTemplateTarget) + $TargetsFound
foreach ($dest in $AllDestinations) {
    if (-not (Test-PathContained $ProjectRoot $dest)) {
        $relDest = if ($dest.StartsWith($ProjectRootPath)) {
            $dest.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
        } else {
            $dest -replace "\\", "/"
        }
        [System.Console]::Error.WriteLine("Error: Target destination escapes project root: $relDest")
        throw "Error: Target destination escapes project root: $relDest"
    }
}

# 5. Directive Block (Loaded from Canonical Template based on profile)
$KitDirRel = if ($ScriptDir.StartsWith($ProjectRootPath)) {
    $ScriptDir.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
} else {
    ".promptkit"
}

if ($Profile -eq "lite") {
    $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-lite-template.md"
    if (-not (Test-Path -LiteralPath $TemplateDirective)) {
        Write-Host "Warning: Lite template not found, falling back to full template" -ForegroundColor Yellow
        $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
    }
} else {
    $TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
}

if (Test-Path -LiteralPath $TemplateDirective) {
    $RawTemplate = [System.IO.File]::ReadAllText($TemplateDirective, [System.Text.Encoding]::UTF8)
    $Directive = ($RawTemplate -replace '\$KIT_DIR_REL', $KitDirRel).TrimEnd("`r", "`n")
} else {
    throw "Error: Canonical directive template not found at $TemplateDirective"
}

# 6. Pre-validation and Transformation Staging (F07 - P2)
$StagedTargetUpdates = [System.Collections.Generic.List[PSObject]]::new()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($targetPath in $TargetsFound) {
    $relTarget = if ($targetPath.StartsWith($ProjectRootPath)) {
        $targetPath.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    } else {
        $targetPath -replace "\\", "/"
    }

    if (Test-Path -LiteralPath $targetPath -PathType Container) {
        throw "Error: Target destination cannot be a directory: $relTarget"
    }

    $content = if (Test-Path -LiteralPath $targetPath) {
        [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
    } else {
        ""
    }

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

    if ($startCount -gt 0 -or $endCount -gt 0) {
        if ($startCount -ne 1 -or $endCount -ne 1 -or $startIndex -ge $endIndex) {
            [System.Console]::Error.WriteLine("Error: Cannot safely update ${relTarget}: expected exactly one complete PromptKit directive block with START before END.")
            throw "Error: Cannot safely update ${relTarget}: expected exactly one complete PromptKit directive block with START before END."
        }

        $isCrlf = $content.Contains("`r`n")
        $nl = if ($isCrlf) { "`r`n" } else { "`n" }
        $targetDirective = ($Directive -split "`r?`n") -join $nl

        # Calculate exact character offsets to preserve original bytes outside the managed block
        $currentOffset = 0
        $blockStartChar = -1
        $blockEndChar = -1

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $lineLen = $lines[$i].Length
            if ($i -eq $startIndex) {
                $blockStartChar = $currentOffset
            }
            if ($i -eq $endIndex) {
                $blockEndChar = $currentOffset + $lineLen
                break
            }

            $nextOffset = $currentOffset + $lineLen
            if ($nextOffset -lt $content.Length) {
                if ($content.Substring($nextOffset).StartsWith("`r`n")) {
                    $currentOffset = $nextOffset + 2
                } elseif ($content.Substring($nextOffset).StartsWith("`n")) {
                    $currentOffset = $nextOffset + 1
                } else {
                    $currentOffset = $nextOffset
                }
            } else {
                $currentOffset = $nextOffset
            }
        }

        $before = if ($blockStartChar -gt 0) { $content.Substring(0, $blockStartChar) } else { "" }
        $after = if ($blockEndChar -lt $content.Length) { $content.Substring($blockEndChar) } else { "" }

        $updated = $before + $targetDirective + $after
        $StagedTargetUpdates.Add([PSCustomObject]@{
            TargetPath = $targetPath
            Content    = $updated
            Mode       = "update"
            RelTarget  = $relTarget
        })
    } elseif (Test-Path -LiteralPath $targetPath) {
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
        $StagedTargetUpdates.Add([PSCustomObject]@{
            TargetPath = $targetPath
            Content    = $updated
            Mode       = "inject"
            RelTarget  = $relTarget
        })
    } else {
        $isCrlf = $Directive.Contains("`r`n")
        $targetNl = if ($isCrlf) { "`r`n" } else { "`n" }
        $targetDirective = ($Directive -split "`r?`n") -join $targetNl
        $StagedTargetUpdates.Add([PSCustomObject]@{
            TargetPath = $targetPath
            Content    = $targetDirective + $targetNl
            Mode       = "create"
            RelTarget  = $relTarget
        })
    }
}

# Pre-calculate PROMPTKIT.md content
function Get-UpdatedProfileContent {
    param(
        [string]$CurrentContent,
        [string]$Profile,
        [string]$Tracking,
        [string]$TrackingProjection,
        [string]$EngineDir
    )
    $text = $CurrentContent
    if ($text -match "(?m)^profile:") {
        $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^profile:" })
        $lines += "profile: $Profile"
        $text = ($lines -join "`n") + "`n"
        if ($text -match "(?m)^- \*\*Profile\*\*:") {
            $text = $text -replace "(?m)^- \*\*Profile\*\*:.*", "- **Profile**: $Profile"
        }
    } else {
        $firstLine = ""
        $rest = ""
        $allLines = $text -split "`r?\n"
        if ($allLines.Length -gt 0) { $firstLine = $allLines[0] }
        if ($allLines.Length -gt 1) { $rest = ($allLines[1..($allLines.Length - 1)] -join "`n") }
        $profileSection = @"

## 0. PromptKit OS Profile
- **Profile**: $Profile
- **Installed**: $(Get-Date -Format "yyyy-MM-dd")
- **Engine**: $EngineDir
- **Upgrade**: Run ``$EngineDir/init.ps1 --balanced`` for the full Balanced profile, or ``--turbo --experimental`` for parallel waves

"@
        $text = "$firstLine`n$profileSection`n$rest`n`n"
        $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^profile:" })
        $lines += "profile: $Profile"
        $text = ($lines -join "`n") + "`n"
    }

    $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^tracking:" })
    $lines += "tracking: $Tracking"
    $text = ($lines -join "`n") + "`n"

    $lines = @($text -split "`r?\n" | Where-Object { $_ -notmatch "^projection:" })
    if (-not [string]::IsNullOrEmpty($TrackingProjection)) {
        $lines += "projection: $TrackingProjection"
    }
    $text = ($lines -join "`n") + "`n"
    return $text
}

# 7. Transactional Commit with Rollback (F07 - P2)
$backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$createdFiles = New-Object System.Collections.Generic.List[string]
$backedUpFiles = New-Object System.Collections.Generic.List[string]
$backupSources = New-Object System.Collections.Generic.List[string]

$comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
    [System.StringComparison]::OrdinalIgnoreCase
} else {
    [System.StringComparison]::Ordinal
}

try {
    # Snapshot all existing destinations ONCE before ANY disk mutation begins (R5 - P2)
    if (Test-Path -LiteralPath $ProjectProfile) {
        $bkp = Join-Path $backupDir "PROMPTKIT.md"
        Copy-Item -LiteralPath $ProjectProfile -Destination $bkp -Force
        $backedUpFiles.Add($ProjectProfile)
        $backupSources.Add($bkp)
    }

    $bIdx = 0
    foreach ($item in $StagedTargetUpdates) {
        $tPath = $item.TargetPath
        if (Test-Path -LiteralPath $tPath) {
            $canonT = Resolve-CanonicalPath $tPath
            $alreadySnapshotted = $false
            foreach ($existingBkp in $backedUpFiles) {
                $canonExist = Resolve-CanonicalPath $existingBkp
                if ($canonT.Equals($canonExist, $comparison)) {
                    $alreadySnapshotted = $true
                    break
                }
            }
            if (-not $alreadySnapshotted) {
                $bkp = Join-Path $backupDir ("target_" + $bIdx)
                Copy-Item -LiteralPath $tPath -Destination $bkp -Force
                $backedUpFiles.Add($tPath)
                $backupSources.Add($bkp)
            }
        }
        $bIdx++
    }

    # Ensure doc directories
    foreach ($dir in $DocDirs) {
        $fullPath = Join-Path $ProjectRoot $dir
        if (-not (Test-Path -LiteralPath $fullPath)) {
            [System.IO.Directory]::CreateDirectory($fullPath) | Out-Null
            Write-Host "  [+] Created directory: $dir" -ForegroundColor Green
        }
    }

    # Commit PROMPTKIT.md
    $profileInitialContent = ""
    if (Test-Path -LiteralPath $ProjectProfile) {
        $profileInitialContent = [System.IO.File]::ReadAllText($ProjectProfile, [System.Text.Encoding]::UTF8)
    } elseif (Test-Path -LiteralPath $TemplateProfile) {
        $profileInitialContent = [System.IO.File]::ReadAllText($TemplateProfile, [System.Text.Encoding]::UTF8)
    }
    $stagedProfile = Get-UpdatedProfileContent -CurrentContent $profileInitialContent -Profile $Profile -Tracking $Tracking -TrackingProjection $TrackingProjection -EngineDir $EngineDir

    if (-not (Test-Path -LiteralPath $ProjectProfile)) {
        $createdFiles.Add($ProjectProfile)
    }
    [System.IO.File]::WriteAllText($ProjectProfile, $stagedProfile, $utf8NoBom)
    if ($backedUpFiles.Contains($ProjectProfile)) {
        Write-Host "  [✓] Updated PROMPTKIT.md profile: $Profile" -ForegroundColor Yellow
        Write-Host "  [✓] Updated PROMPTKIT.md tracking: $Tracking" -ForegroundColor Yellow
        if (-not [string]::IsNullOrEmpty($TrackingProjection)) {
            Write-Host "  [✓] Updated PROMPTKIT.md projection: $TrackingProjection" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [+] Created: PROMPTKIT.md (project profile & guardrails)" -ForegroundColor Green
        Write-Host "  [+] Set PROMPTKIT.md profile: $Profile" -ForegroundColor Green
        Write-Host "  [✓] Updated PROMPTKIT.md tracking: $Tracking" -ForegroundColor Yellow
    }

    # Commit scaffolds
    if (-not (Test-Path -LiteralPath $StateTracker) -and (Test-Path -LiteralPath $TemplateState)) {
        $docsParent = Split-Path -Parent $StateTracker
        if (-not (Test-Path -LiteralPath $docsParent)) { [System.IO.Directory]::CreateDirectory($docsParent) | Out-Null }
        Copy-Item -LiteralPath $TemplateState -Destination $StateTracker -Force
        $createdFiles.Add($StateTracker)
        Write-Host "  [+] Created: docs/STATE.md (living project & state tracker)" -ForegroundColor Green
    }
    if (-not (Test-Path -LiteralPath $PrTemplateTarget) -and (Test-Path -LiteralPath $TemplatePr)) {
        $ghParent = Split-Path -Parent $PrTemplateTarget
        if (-not (Test-Path -LiteralPath $ghParent)) { [System.IO.Directory]::CreateDirectory($ghParent) | Out-Null }
        Copy-Item -LiteralPath $TemplatePr -Destination $PrTemplateTarget -Force
        $createdFiles.Add($PrTemplateTarget)
        Write-Host "  [+] Created: .github/pull_request_template.md (staff-level PR specification)" -ForegroundColor Green
    }
    if (-not (Test-Path -LiteralPath $TaskTemplateTarget) -and (Test-Path -LiteralPath $TemplateTask)) {
        $taskParent = Split-Path -Parent $TaskTemplateTarget
        if (-not (Test-Path -LiteralPath $taskParent)) { [System.IO.Directory]::CreateDirectory($taskParent) | Out-Null }
        Copy-Item -LiteralPath $TemplateTask -Destination $TaskTemplateTarget -Force
        $createdFiles.Add($TaskTemplateTarget)
        Write-Host "  [+] Created: .github/ISSUE_TEMPLATE/task.md (standard task specification)" -ForegroundColor Green
    }

    # Commit targets
    foreach ($item in $StagedTargetUpdates) {
        $tPath = $item.TargetPath
        $pDir = Split-Path -Parent $tPath
        if ($pDir -ne "" -and -not (Test-Path -LiteralPath $pDir)) {
            [System.IO.Directory]::CreateDirectory($pDir) | Out-Null
        }
        if (-not (Test-Path -LiteralPath $tPath)) {
            $createdFiles.Add($tPath)
        }
        [System.IO.File]::WriteAllText($tPath, $item.Content, $utf8NoBom)
        if ($item.Mode -eq "update") {
            Write-Host "  [✓] Updated PromptKit OS directives in: $($item.RelTarget) (profile: $Profile)" -ForegroundColor Yellow
        } else {
            Write-Host "  [+] Injected PromptKit OS directives into: $($item.RelTarget) (profile: $Profile)" -ForegroundColor Green
        }
    }
} catch {
    # Rollback!
    for ($i = $createdFiles.Count - 1; $i -ge 0; $i--) {
        $f = $createdFiles[$i]
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
    }
    for ($i = 0; $i -lt $backedUpFiles.Count; $i++) {
        $dest = $backedUpFiles[$i]
        $bkp = $backupSources[$i]
        if (Test-Path -LiteralPath $bkp) {
            Copy-Item -LiteralPath $bkp -Destination $dest -Force -ErrorAction SilentlyContinue
        }
    }
    throw
} finally {
    if (Test-Path -LiteralPath $backupDir) {
        Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n✨ PromptKit OS successfully configured for $ProjectRoot! ($Profile profile)" -ForegroundColor Cyan
if ($Profile -eq "lite") {
    Write-Host "   Lite: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) — 80% value, <1,500 tok" -ForegroundColor Green
    Write-Host "   Upgrade anytime: .promptkit/init.ps1 --balanced for the full Balanced profile" -ForegroundColor DarkGray
} elseif ($Profile -eq "balanced") {
    Write-Host "   Balanced: 25 workflows, Level 0-3 adaptive ceremony — full power" -ForegroundColor White
    Write-Host "   For onboarding: .promptkit/init.ps1 --lite for minimal setup" -ForegroundColor DarkGray
} else {
    Write-Host "   Turbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost" -ForegroundColor Yellow
    Write-Host "   Human approval still required for Level 3 (releases/tags/deploys)" -ForegroundColor DarkGray
}
Write-Host "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'`n" -ForegroundColor White
