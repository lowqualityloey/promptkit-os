<#
.SYNOPSIS
    PromptKit OS 1-Click Setup Script for Windows (PowerShell)
.DESCRIPTION
    Initializes PromptKit OS in your project:
    - Scaffolds project documentation directories (docs/adrs, docs/specs, docs/rca, docs/spikes, docs/design)
    - Creates PROMPTKIT.md project profile if missing
    - Injects or updates PromptKit OS directives in AGENTS.md, CLAUDE.md, GEMINI.md, .cursorrules, .cursor/rules/*.mdc, .windsurfrules, .github/copilot-instructions.md, .clinerules, .traerules, or .opencode/rules.md
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [Alias("ProjectRoot")]
    [string]$TargetDir = ""
)

$ErrorActionPreference = "Stop"

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

Write-Host "`n🚀 Initializing PromptKit OS..." -ForegroundColor Cyan
Write-Host "   Host Project: $ProjectRoot" -ForegroundColor DarkGray
Write-Host "   Engine Path:  $ScriptDir`n" -ForegroundColor DarkGray

# 1. Ensure Core Documentation Directories Exist in Host Project
# (Specialized subdirectories like docs/auth, docs/data are created on-demand by workflows)
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

# 2. Scaffold PROMPTKIT.md if missing
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
            # Target is a directory (e.g., modern .clinerules/ folder layout)
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

# 4. Directive Block (Loaded from Canonical Template)
$KitDirRel = if ($ScriptDir.StartsWith($ProjectRootPath)) {
    $ScriptDir.Substring($ProjectRootPath.Length).TrimStart("\", "/") -replace "\\", "/"
} else {
    ".promptkit"
}

$TemplateDirective = Join-Path $ScriptDir "templates/agent-directive-template.md"
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
        Write-Host "  [✓] Updated PromptKit OS directives in: $relTarget" -ForegroundColor Yellow
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
        Write-Host "  [+] Injected PromptKit OS directives into: $relTarget" -ForegroundColor Green
    }
}

Write-Host "`n✨ PromptKit OS successfully configured for $ProjectRoot!" -ForegroundColor Cyan
Write-Host "   Start by asking your AI: 'pk:sync', 'pk:plan', or 'pk:tutor'`n" -ForegroundColor White
