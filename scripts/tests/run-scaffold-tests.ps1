$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $ScriptDir "..\..")
$InitPs1 = Join-Path $RootDir "init.ps1"
$TestDir = Join-Path $RootDir "test-output-saas-ps"

Write-Host "Running SaaS Scaffold tests (PowerShell)..."

# Cleanup
if (Test-Path $TestDir) {
    Remove-Item -Path $TestDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null

$env:PROMPTKIT_NO_INTERACTIVE = "1"

Write-Host "1. Standard init still works (no scaffold runs)"
New-Item -ItemType Directory -Path (Join-Path $TestDir "standard") -Force | Out-Null
& $InitPs1 -Lite (Join-Path $TestDir "standard") | Out-Null
if (Test-Path (Join-Path $TestDir "standard\package.json")) {
    Write-Host "FAILED: package.json should not exist in standard init" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Standard init passes" -ForegroundColor Green

Write-Host "2. Scaffold creates expected file tree"
New-Item -ItemType Directory -Path (Join-Path $TestDir "scaffolded") -Force | Out-Null
& $InitPs1 -Saas (Join-Path $TestDir "scaffolded") | Out-Null
if (-not (Test-Path (Join-Path $TestDir "scaffolded\package.json"))) {
    Write-Host "FAILED: package.json should exist in scaffolded init" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $TestDir "scaffolded\app\api\auth\[...nextauth]\route.ts"))) {
    Write-Host "FAILED: route.ts should exist" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $TestDir "scaffolded\.env.example"))) {
    Write-Host "FAILED: .env.example should exist" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Scaffold file tree passes" -ForegroundColor Green

Write-Host "3. Non-empty directory aborts"
$NonEmptyDir = Join-Path $TestDir "nonempty"
New-Item -ItemType Directory -Path $NonEmptyDir -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $NonEmptyDir "existing.txt") -Force | Out-Null

$ErrorActionPreference = "Continue"
try {
    & $InitPs1 -Saas $NonEmptyDir 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "FAILED: Should have aborted on non-empty directory" -ForegroundColor Red
        exit 1
    }
} catch {
    # Expected to fail
}
$ErrorActionPreference = "Stop"
Write-Host "✓ Non-empty directory check passes" -ForegroundColor Green

Write-Host "All PowerShell Scaffold tests passed!" -ForegroundColor Green
