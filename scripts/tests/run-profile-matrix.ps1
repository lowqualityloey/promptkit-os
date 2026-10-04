<#
.SYNOPSIS
    E2E profile matrix tests for init.ps1 (issue #143, PowerShell parity for run-profile-matrix.sh).
.DESCRIPTION
    Covers the 3-profile flag matrix, the --turbo/--experimental guard, non-interactive
    fallback via PROMPTKIT_NO_INTERACTIVE, and lite -> balanced upgrade idempotency.
    All invocations run with redirected stdin (the CI contract); the real-TTY picker
    skip is a manual check (PTY simulation is out of scope per #144/#143).
.NOTES
    Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-profile-matrix.ps1
#>

[CmdletBinding()]
param ()

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Init = Join-Path $RepoRoot "init.ps1"
$TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pk-matrix-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null

$script:Pass = 0
$script:Fail = 0

function Ok([string]$name)   { Write-Host "  PASS: $name" -ForegroundColor Green; $script:Pass++ }
function NotOk([string]$name){ Write-Host "  FAIL: $name" -ForegroundColor Red;   $script:Fail++ }

function ProfileOf([string]$dir) {
    $file = Join-Path $dir "PROMPTKIT.md"
    if (-not (Test-Path $file)) { return "" }
    $line = (Get-Content $file | Where-Object { $_ -match '^profile:' } | Select-Object -Last 1)
    if ($line) { return ($line -split '\s+' | Select-Object -Last 1) }
    return ""
}

function ManagedBlockMatchesTemplate([string]$target, [string]$template) {
    $hostText = (Get-Content $target -Raw) -replace "`r`n", "`n"
    $templateText = (Get-Content $template -Raw) -replace "`r`n", "`n"
    $templateText = $templateText.Replace('$KIT_DIR_REL', '.promptkit')
    return $hostText.Contains($templateText)
}

function NewDir([string]$name) {
    $d = Join-Path $TestRoot $name
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    return $d
}

Write-Host "`n🧪 init.ps1 Profile Matrix Tests (non-interactive contract)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. No flag: defaults to balanced.
$d = NewDir "t1"
& pwsh -NoProfile -File $Init $d 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0 -and (ProfileOf $d) -eq "balanced") { Ok "no flag defaults to balanced (exit 0)" }
else { NotOk "no flag should default balanced (rc=$LASTEXITCODE, profile=$(ProfileOf $d))" }

# 2. --lite: profile lite + Lite directive injected.
$d = NewDir "t2"
& pwsh -NoProfile -File $Init --lite $d 2>&1 | Out-Null
$agents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
if ((ProfileOf $d) -eq "lite" -and $agents -match "PromptKit OS Lite" -and (ManagedBlockMatchesTemplate (Join-Path $d "AGENTS.md") (Join-Path $RepoRoot "templates/agent-directive-lite-template.md"))) { Ok "--lite sets profile lite and renders the selected directive template" }
else { NotOk "--lite install (profile=$(ProfileOf $d))" }

# 3. --balanced: profile balanced + full directive header.
$d = NewDir "t3"
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$agents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
if ((ProfileOf $d) -eq "balanced" -and $agents -match "(?m)^## PromptKit OS: Engineering Operating System$" -and (ManagedBlockMatchesTemplate (Join-Path $d "AGENTS.md") (Join-Path $RepoRoot "templates/agent-directive-template.md"))) { Ok "--balanced sets profile balanced and renders the selected directive template" }
else { NotOk "--balanced install (profile=$(ProfileOf $d))" }

# 4. --turbo without --experimental: must fail with guard message.
$d = NewDir "t4"
$out = & pwsh -NoProfile -File $Init --turbo $d 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -and $out -match "requires --experimental") { Ok "--turbo alone is rejected with --experimental guard" }
else { NotOk "--turbo alone should exit non-zero with guard (rc=$LASTEXITCODE)" }

# 5. --turbo --experimental: profile turbo accepted.
$d = NewDir "t5"
& pwsh -NoProfile -File $Init --turbo --experimental $d 2>&1 | Out-Null
if ((ProfileOf $d) -eq "turbo") { Ok "--turbo --experimental sets profile turbo" }
else { NotOk "--turbo --experimental install (profile=$(ProfileOf $d))" }

# 6. PROMPTKIT_NO_INTERACTIVE=1: accepted, no picker text, defaults balanced.
$d = NewDir "t6"
$env:PROMPTKIT_NO_INTERACTIVE = "1"
$out = & pwsh -NoProfile -File $Init $d 2>&1 | Out-String
Remove-Item Env:\PROMPTKIT_NO_INTERACTIVE -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0 -and $out -notmatch "Profile Selection" -and (ProfileOf $d) -eq "balanced") { Ok "PROMPTKIT_NO_INTERACTIVE=1 yields non-interactive default" }
else { NotOk "env-var escape test (rc=$LASTEXITCODE, profile=$(ProfileOf $d))" }

# 7. Upgrade path lite -> balanced re-run: profile flips, single directive block.
$d = NewDir "t7"
& pwsh -NoProfile -File $Init --lite $d 2>&1 | Out-Null
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$agentsRaw = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
$profileDoc = (Get-Content (Join-Path $d "PROMPTKIT.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
$markerCount = ([regex]::Matches($agentsRaw, "(?m)^<!-- PROMPTKIT_START -->$")).Count
if ((ProfileOf $d) -eq "balanced" -and $markerCount -eq 1 -and $agentsRaw -match "(?m)^## PromptKit OS: Engineering Operating System$" -and $profileDoc -match "(?m)^- \*\*Profile\*\*: balanced$") { Ok "lite -> balanced upgrade is idempotent (profile + Section 0 body flip, one directive block)" }
else { NotOk "upgrade re-run (profile=$(ProfileOf $d), markers=$markerCount)" }

# 8. Aider parity: existing CONVENTIONS.md receives an idempotent directive block.
$d = NewDir "t8"
Set-Content -Path (Join-Path $d "CONVENTIONS.md") -Value "# My aider notes" -NoNewline
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$c = (Get-Content (Join-Path $d "CONVENTIONS.md") -Raw) -replace "\r\n", "`n"
$cm = ([regex]::Matches($c, "(?m)^<!-- PROMPTKIT_START -->$")).Count
if ($cm -eq 1 -and $c -match "(?m)^# My aider notes$") { Ok "existing CONVENTIONS.md injected idempotently with user content preserved" }
else { NotOk "CONVENTIONS.md injection (markers=$cm)" }

$d = NewDir "t9-agents-only"
$env:PROMPTKIT_NO_PREFLIGHT = "1"
& pwsh -NoProfile -File $Init --balanced --tracking=local --host=agents $d 2>&1 | Out-Null
$initialExitCode = $LASTEXITCODE
if ($initialExitCode -eq 0) {
    $out = & pwsh -NoProfile -File $Init $d 2>&1 | Out-String
    $rerunExitCode = $LASTEXITCODE
    $hostFiles = @("CLAUDE.md", ".opencode/rules.md", ".cursorrules", "GEMINI.md", ".windsurfrules", ".github/copilot-instructions.md", ".clinerules", ".traerules", "CONVENTIONS.md")
    $unexpectedHostFiles = @($hostFiles | Where-Object { Test-Path (Join-Path $d $_) })
    if ($rerunExitCode -eq 0 -and $out -match "Keeping installed hosts: agents" -and (Test-Path (Join-Path $d "AGENTS.md")) -and $unexpectedHostFiles.Count -eq 0) {
        Ok "AGENTS.md-only install preserves universal hosts on rerun"
    } else { NotOk "AGENTS.md-only rerun did not preserve universal host choice (rc=$rerunExitCode)" }
} else { NotOk "AGENTS.md-only initial install (rc=$initialExitCode)" }
Remove-Item Env:\PROMPTKIT_NO_PREFLIGHT -ErrorAction SilentlyContinue

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "Passed: $script:Pass | Failed: $script:Fail"

Remove-Item -Recurse -Force $TestRoot -ErrorAction SilentlyContinue

if ($script:Fail -gt 0) {
    Write-Host "❌ init.ps1 profile matrix FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "✅ init.ps1 profile matrix passed" -ForegroundColor Green
exit 0
