# PromptKit OS Git Worktree Isolation Tests (PowerShell)
# Verifies worktree creation, error handling on collisions, merge failure detection,
# and safe removal.

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pk-worktree-test-" + [System.Guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
    $testRepo = Join-Path $testRoot "repo"
    New-Item -ItemType Directory -Path $testRepo -Force | Out-Null

    Push-Location $testRepo
    git init -b main | Out-Null
    git config user.name "PromptKit Test"
    git config user.email "test@promptkit.dev"

    Set-Content -Path "README.md" -Value "# Initial"
    git add README.md
    git commit -m "initial commit" | Out-Null

    $isolateScript = Join-Path $repoRoot "scripts\isolate-worktree.ps1"

    Write-Host "🧪 Running Worktree Isolation PowerShell Tests..." -ForegroundColor Cyan

    # Test 1: Successful create
    Write-Host "  [Test 1] Create worktree task-1"
    & $isolateScript create task-1
    if (-not (Test-Path ".worktrees\task-1")) {
        throw "Test 1 failed: Directory .worktrees\task-1 does not exist"
    }
    Write-Host "  ✅ Test 1 passed" -ForegroundColor Green

    # Test 2: Failed create on existing branch collision
    Write-Host "  [Test 2] Failed create when branch already exists elsewhere"
    git branch "worktree/task-conflict" | Out-Null
    $failed = $false
    $errOut = ""
    try {
        $errOut = & $isolateScript create task-conflict 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            $failed = $true
        }
    } catch {
        $failed = $true
        $errOut = $_.ToString()
    }
    if (-not $failed) {
        throw "Test 2 failed: Expected failure on branch collision, but succeeded."
    }
    if ($errOut -match "Worktree created successfully") {
        throw "Test 2 failed: Found false success output in error case: $errOut"
    }
    Write-Host "  ✅ Test 2 passed: Collision halted without false success" -ForegroundColor Green

    # Test 3: Successful merge
    Write-Host "  [Test 3] Successful merge"
    Push-Location ".worktrees\task-1"
    Set-Content -Path "feature.txt" -Value "Feature work"
    git add feature.txt
    git commit -m "add feature" | Out-Null
    Pop-Location

    & $isolateScript merge task-1
    if (-not (Test-Path "feature.txt")) {
        throw "Test 3 failed: feature.txt not present after merge"
    }
    Write-Host "  ✅ Test 3 passed" -ForegroundColor Green

    # Test 4: Failed merge on conflict
    Write-Host "  [Test 4] Failed merge on conflict"
    & $isolateScript create task-conflict2 | Out-Null
    Push-Location ".worktrees\task-conflict2"
    Set-Content -Path "README.md" -Value "Conflict from branch"
    git commit -am "branch conflicting change" | Out-Null
    Pop-Location
    Set-Content -Path "README.md" -Value "Conflict on main"
    git commit -am "main conflicting change" | Out-Null

    $failedMerge = $false
    $mergeErrOut = ""
    try {
        $mergeErrOut = & $isolateScript merge task-conflict2 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            $failedMerge = $true
        }
    } catch {
        $failedMerge = $true
        $mergeErrOut = $_.ToString()
    }
    if (-not $failedMerge) {
        throw "Test 4 failed: Expected failure on merge conflict, but succeeded."
    }
    if ($mergeErrOut -match "Merge completed") {
        throw "Test 4 failed: Found false success output on merge conflict: $mergeErrOut"
    }
    Write-Host "  ✅ Test 4 passed: Merge conflict halted without false success" -ForegroundColor Green

    git merge --abort 2>&1 | Out-Null

    # Test 5: Remove worktrees
    Write-Host "  [Test 5] Remove worktrees"
    & $isolateScript remove task-1
    if (Test-Path ".worktrees\task-1") {
        throw "Test 5 failed: .worktrees\task-1 still exists"
    }
    & $isolateScript remove task-conflict2 -Force
    if (Test-Path ".worktrees\task-conflict2") {
        throw "Test 5 failed: .worktrees\task-conflict2 still exists"
    }
    Write-Host "  ✅ Test 5 passed" -ForegroundColor Green

    Pop-Location
    Write-Host "✅ All Worktree Isolation PowerShell tests passed!" -ForegroundColor Green
} finally {
    if (Test-Path $testRoot) {
        Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
