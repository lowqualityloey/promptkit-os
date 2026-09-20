#!/usr/bin/env pwsh
# Regression tests for the strict token budget gates (PowerShell twin) (issue #141).
# Covers: strict dual-profile CI gate (pwsh), per-task baseline gate, profile-aware
# budget resolution for the Lite template, and negative-path regression detection.
# Run from repository root: pwsh -File scripts/tests/run-token-budget-tests.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$TmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

function Cleanup {
    if (Test-Path $TmpDir) {
        Remove-Item -Path $TmpDir -Recurse -Force
    }
}
trap Cleanup EXIT

$PASS = 0
$FAIL = 0

function Ok {
    param([string]$Msg)
    Write-Output "  PASS: $Msg"
    $script:PASS += 1
}

function NotOk {
    param([string]$Msg)
    Write-Output "  FAIL: $Msg"
    $script:FAIL += 1
}

function Make-DirectiveFile {
    param([string]$TargetPath, [int]$Size)
    $dir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    @("<!-- PROMPTKIT_START -->") + 
        (@(0..($Size - 1)) | ForEach-Object { "A" }) + 
        (@("", "<!-- PROMPTKIT_END -->")) |
        Set-Content -Path $TargetPath -NoNewline
}

Write-Output "🧪 Token Budget Gate Regression Tests (PowerShell)"
Write-Output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Strict gate passes on the canonical templates (machine-parseable PASS lines).
$measureScript = Join-Path $RepoRoot "scripts/measure-tokens.ps1"
$out = & pwsh -NoProfile -File $measureScript --strict 2>&1
$rc = $LASTEXITCODE
if ($rc -eq 0 -and $out -match "BALANCED.*PASS" -and $out -match "LITE.*PASS") {
    Ok "measure-tokens.ps1 --strict passes canonical templates with PASS lines"
} else {
    NotOk "measure-tokens.ps1 --strict should exit 0 with BALANCED+LITE PASS (rc=$rc)"
    Write-Output $out
}

# 2. Per-task strict gate passes against recorded baselines.
$perTaskScript = Join-Path $RepoRoot "scripts/measure-per-task-tokens.ps1"
$out = & pwsh -NoProfile -File $perTaskScript --strict 2>&1
$rc = $LASTEXITCODE
if ($rc -eq 0 -and $out -match "Per-task baseline gate passed" -and $out -match "BASELINE\|pk:fix/balanced.*PASS") {
    Ok "measure-per-task-tokens.ps1 --strict passes all baseline comparisons"
} else {
    NotOk "measure-per-task-tokens.ps1 --strict should exit 0 (rc=$rc)"
    Write-Output ($out | Select-Object -Last 12)
}

# 3. Negative balanced regression: bloated directive must fail default mode (budget 2500).
$bloatedFile = Join-Path $TmpDir "bloated-AGENTS.md"
Make-DirectiveFile $bloatedFile 12000
& pwsh -NoProfile -File $measureScript $bloatedFile 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    NotOk "bloated directive (12,000 chars) must exceed 2,500-token budget and exit 1"
} else {
    Ok "bloated directive correctly fails the Balanced budget (exit 1)"
}

# 4. Profile-aware Lite budget: a file named agent-directive-lite-template.md over the
#    Lite budget (1,500 tok = 6,000 chars) must fail even though it is under 2,500.
$liteBloatedFile = Join-Path $TmpDir "agent-directive-lite-template.md"
Make-DirectiveFile $liteBloatedFile 6100
& pwsh -NoProfile -File $measureScript $liteBloatedFile 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    NotOk "bloated Lite template (1,525 tok > 1,500 budget) must exit 1"
} else {
    Ok "Lite template path correctly resolves to the 1,500-token budget (exit 1)"
}

# 5. Positive Lite check: small Lite-named directive passes with Lite profile resolution.
$liteOkDir = Join-Path $TmpDir "lite-ok/templates"
$liteOkFile = Join-Path $liteOkDir "agent-directive-lite-template.md"
Make-DirectiveFile $liteOkFile 400
$out = & pwsh -NoProfile -File $measureScript $liteOkFile 2>&1
$rc = $LASTEXITCODE
if ($rc -eq 0 -and $out -match "Profile.*Lite") {
    Ok "small Lite template passes and reports Lite profile budget"
} else {
    NotOk "small Lite template should exit 0 reporting Lite budget (rc=$rc)"
}

# 6. Backward compatibility: bare invocation from the repo root still measures the
#    canonical Balanced template fallback and exits 0.
Push-Location $RepoRoot
$out = & pwsh -NoProfile -File scripts/measure-tokens.ps1 2>&1
$rc = $LASTEXITCODE
Pop-Location
if ($rc -eq 0 -and $out -match "Verification Passed") {
    Ok "bare invocation stays backward compatible (Balanced fallback, exit 0)"
} else {
    NotOk "bare invocation should still pass (rc=$rc)"
}

Write-Output ""
Write-Output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Output "Passed: $PASS | Failed: $FAIL"
if ($FAIL -gt 0) {
    Write-Output "❌ Token budget regression tests FAILED"
    exit 1
}
Write-Output "✅ Token budget regression tests passed"
exit 0
