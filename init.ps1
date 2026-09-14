<#
.SYNOPSIS
    PromptKit OS 1-Click Setup Script for Windows (PowerShell)
    Supports profiles: --lite, --balanced (default), --turbo --experimental
.DESCRIPTION
    Initializes PromptKit OS in your project:
    - Scaffolds project documentation directories (docs/adrs, docs/specs, docs/rca, docs/spikes, docs/design)
    - Creates PROMPTKIT.md project profile if missing, injects profile: lite|balanced|turbo
    - Injects or updates PromptKit OS directives in AGENTS.md, CLAUDE.md, GEMINI.md, .cursorrules, .cursor/rules/*.mdc, .windsurfrules, .github/copilot-instructions.md, .clinerules, .traerules, or .opencode/rules.md
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
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "`nPromptKit OS init.ps1 — 1-Click Setup`n" -ForegroundColor Cyan
    Write-Host "Usage: .\init.ps1 [options] [project-root]`n"
    Write-Host "Options:"
    Write-Host "  --lite              Lite profile: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value"
    Write-Host "  --balanced          Balanced profile: the full workflow set, Level 0-3 adaptive ceremony (default)"
    Write-Host "  --turbo             Turbo profile: Balanced + parallel subagent waves, up to ~2x measured token cost"
    Write-Host "  --experimental      Required for --turbo, acknowledges experimental cost and warnings"
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
if ($Lite) { $Profile = "lite"; $ProfileSet = $true }
if ($Balanced) { $Profile = "balanced"; $ProfileSet = $true }
if ($Turbo) { $Profile = "turbo"; $ProfileSet = $true }

# Also check $args for --lite style (when called via pwsh -File with --lite)
foreach ($a in $args) {
    switch ($a) {
        "--lite" { $Profile = "lite"; $ProfileSet = $true }
        "--balanced" { $Profile = "balanced"; $ProfileSet = $true }
        "--turbo" { $Profile = "turbo"; $ProfileSet = $true }
        "--experimental" { $Experimental = $true }
        "--help" { 
            Write-Host "`nPromptKit OS init.ps1 — 1-Click Setup`n" -ForegroundColor Cyan
            Write-Host "Usage: .\init.ps1 [options] [project-root]`n"
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
    Write-Host "  2) Balanced (Recommended for teams) — 23 workflows, 2,319 tok, Level 0-3 adaptive ceremony [default]" -ForegroundColor White
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
if ($Profile -eq "turbo") {
    Write-Host "   ⚠️  Turbo: up to ~2x measured token cost, experimental, parallel waves. Human approval still required for L3." -ForegroundColor Yellow
}
if ($Profile -eq "lite") {
    Write-Host "   ✨ Lite: 6 utility workflows, <1,500 tok, 80% value — perfect for onboarding" -ForegroundColor Green
}
Write-Host ""

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
}

$DesignProfile = Join-Path $ProjectRoot "DESIGN.md"
if (Test-Path $DesignProfile) {
    Write-Host "  [✓] DESIGN.md detected (brand identity & anti-slop rules)" -ForegroundColor DarkGray
}

# Scaffold docs/STATE.md if missing
$StateTracker = Join-Path $ProjectRoot "docs/STATE.md"
$TemplateState = Join-Path $ScriptDir "templates/state-tracker-template.md"

if (-not (Test-Path $StateTracker)) {
    if (Test-Path $TemplateState) {
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
    ".opencode/rules.md"
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

if ($TargetsFound.Count -eq 0) {
    $defaultAgent = Join-Path $ProjectRoot "AGENTS.md"
    $defaultClaude = Join-Path $ProjectRoot "CLAUDE.md"
    New-Item -ItemType File -Path $defaultAgent -Force | Out-Null
    New-Item -ItemType File -Path $defaultClaude -Force | Out-Null
    $TargetsFound += $defaultAgent
    $TargetsFound += $defaultClaude
    Write-Host "  [+] Created default agent configurations: AGENTS.md & CLAUDE.md" -ForegroundColor Green
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
    Write-Host "   Balanced: 23 workflows, Level 0-3 adaptive ceremony — full power" -ForegroundColor White
    Write-Host "   For onboarding: .promptkit/init.ps1 --lite for minimal setup" -ForegroundColor DarkGray
} else {
    Write-Host "   Turbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost" -ForegroundColor Yellow
    Write-Host "   Human approval still required for Level 3 (releases/tags/deploys)" -ForegroundColor DarkGray
}
Write-Host "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'`n" -ForegroundColor White
