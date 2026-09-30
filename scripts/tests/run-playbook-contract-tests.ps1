# Regression tests for Playbook Contract validator (PowerShell)
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Write-Host "[TEST] Running Playbook Contract Test Suite (PowerShell)..." -ForegroundColor Cyan
& (Join-Path $RepoRoot "scripts\validate-playbooks.ps1") -TestSchema

$stacksDir = Join-Path $RepoRoot "docs\stacks"
if (Test-Path -LiteralPath $stacksDir -PathType Container) {
    & (Join-Path $RepoRoot "scripts\validate-playbooks.ps1") -TargetPath $stacksDir
}

$recipesDir = Join-Path $RepoRoot "docs\recipes"
if (Test-Path -LiteralPath $recipesDir -PathType Container) {
    & (Join-Path $RepoRoot "scripts\validate-playbooks.ps1") -TargetPath $recipesDir
}
$concurrencyScript = Join-Path $RepoRoot "scripts\tests\verify-auth-session-concurrency.mjs"
if ((Get-Command node -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $concurrencyScript)) {
    Write-Host "[TEST] Running Recipe Concurrency Verification (Node)..." -ForegroundColor Cyan
    node $concurrencyScript
}

Write-Host "[PASS] All Playbook Contract tests PASSED" -ForegroundColor Green
