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
if ((ProfileOf $d) -eq "lite" -and $agents -match "PromptKit OS Lite") { Ok "--lite sets profile lite and injects Lite directive" }
else { NotOk "--lite install (profile=$(ProfileOf $d))" }

# 3. --balanced: profile balanced + full directive header.
$d = NewDir "t3"
& pwsh -NoProfile -File $Init --balanced $d 2>&1 | Out-Null
$agents = (Get-Content (Join-Path $d "AGENTS.md") -ErrorAction SilentlyContinue -Raw) -replace "\r\n", "`n"
if ((ProfileOf $d) -eq "balanced" -and $agents -match "(?m)^## PromptKit OS: Engineering Operating System$") { Ok "--balanced sets profile balanced and injects full directive" }
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
$markerCount = ([regex]::Matches($agentsRaw, "(?m)^<!-- PROMPTKIT_START -->$")).Count
if ((ProfileOf $d) -eq "balanced" -and $markerCount -eq 1 -and $agentsRaw -match "(?m)^## PromptKit OS: Engineering Operating System$") { Ok "lite -> balanced upgrade is idempotent (profile flips, one directive block)" }
else { NotOk "upgrade re-run (profile=$(ProfileOf $d), markers=$markerCount)" }

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "Passed: $script:Pass | Failed: $script:Fail"

Remove-Item -Recurse -Force $TestRoot -ErrorAction SilentlyContinue

if ($script:Fail -gt 0) {
    Write-Host "❌ init.ps1 profile matrix FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "✅ init.ps1 profile matrix passed" -ForegroundColor Green
exit 0
