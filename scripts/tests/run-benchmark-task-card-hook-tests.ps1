# Regression harness for scripts\install-benchmark-task-card-hook.ps1.
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-benchmark-task-card-hook-tests.ps1
#
# Every case builds a throwaway git repository, installs the hook there, and
# commits through it. The gate under test is the repository's real
# check-benchmark-task-cards.sh, so a passing case proves the installed hook
# blocks a badly ordered card and lets a compliant one through.
#
# Cases are 1:1 with the Bash twin except the executable-bit assertions, which
# Windows has no mode bit to satisfy (23 here, 27 there).

$ErrorActionPreference = 'Stop'
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentCulture = $invariant

$installer = Join-Path $PSScriptRoot '..\install-benchmark-task-card-hook.ps1'
$tempRoot = Join-Path $env:TEMP ("taskcard-hook-" + [guid]::NewGuid().ToString("N").Substring(0, 8))

$script:Pass = 0
$script:Fail = 0
$script:Status = 0
$script:Out = ""
$script:Repo = ""

function Write-Pass([string]$Name) { Write-Host "PASS: $Name"; $script:Pass += 1 }
function Write-Fail([string]$Name) { Write-Host "FAIL: $Name"; $script:Fail += 1 }

function Invoke-Installer {
    param([string[]]$Extra = @())
    $script:Status = 0
    $script:Out = ""
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $script:Out = (& $installer -Root $script:Repo @Extra 6>&1 | Out-String)
        if ($null -ne $LASTEXITCODE) { $script:Status = $LASTEXITCODE }
    }
    finally { $ErrorActionPreference = $previous }
}

function Invoke-Commit {
    param([string]$Message)
    $script:Status = 0
    $script:Out = ""
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $script:Out = (& git -C $script:Repo commit -qm $Message 2>&1 | Out-String)
        if ($null -ne $LASTEXITCODE) { $script:Status = $LASTEXITCODE }
    }
    finally { $ErrorActionPreference = $previous }
}

function Get-Head {
    return ((& git -C $script:Repo rev-parse HEAD 2>$null | Out-String).Trim())
}

function New-Repo {
    param([string]$Name)
    $script:Repo = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Force -Path (Join-Path $script:Repo 'benchmarks/tasks') | Out-Null
    & git init -q $script:Repo | Out-Null
    & git -C $script:Repo config user.name test | Out-Null
    & git -C $script:Repo config user.email test@example.com | Out-Null
    & git -C $script:Repo config commit.gpgsign false | Out-Null
    Set-Content -LiteralPath (Join-Path $script:Repo 'README.md') -Value '# seed'
    & git -C $script:Repo add README.md | Out-Null
    & git -C $script:Repo commit -qm seed | Out-Null
}

$script:BadVerify = 'node --test && node --input-type=module -e "1"'
$script:GoodVerify = 'node --input-type=module -e "1"; probe=$?; node --test; tests=$?; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]'

function Write-Card {
    param([string]$Name, [string]$Id, [string]$Verify)
    $lines = @(
        '# Task Spec: fixture',
        '',
        ('- **Task ID**: `' + $Id + '`'),
        ('- **Verify**: `' + $Verify + '`')
    )
    Set-Content -LiteralPath (Join-Path $script:Repo ('benchmarks/tasks/' + $Name)) -Value $lines
}

function Write-BadCard { Write-Card -Name 'TASK-BENCH-T-01.md' -Id 'BENCH-T-01' -Verify $script:BadVerify }
function Write-GoodCard { Write-Card -Name 'TASK-BENCH-T-02.md' -Id 'BENCH-T-02' -Verify $script:GoodVerify }

function Test-Status([string]$Expected) {
    $want = [int]$Expected
    if ($script:Status -eq $want) { return $true }
    Write-Host "  - expected exit $want, got $($script:Status)"
    Write-Host "  - output: $($script:Out.Trim())"
    return $false
}

function Test-NonZero([string]$Ignored) {
    if ($script:Status -ne 0) { return $true }
    Write-Host "  - expected a non-zero exit, got 0"
    Write-Host "  - output: $($script:Out.Trim())"
    return $false
}

function Test-Contains([string]$Needle) {
    if ($script:Out.Contains($Needle)) { return $true }
    Write-Host "  - output missing: $Needle"
    Write-Host "  - output: $($script:Out.Trim())"
    return $false
}

function Test-File([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return $true }
    Write-Host "  - expected file: $Path"
    return $false
}

function Test-NoFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $true }
    Write-Host "  - expected no file: $Path"
    return $false
}

function Test-SameBytes([string]$Pair) {
    # one argument: "<file-a>|<file-b>"
    $parts = $Pair.Split('|')
    $a = $parts[0]
    $b = $parts[1]
    if (-not (Test-Path -LiteralPath $a) -or -not (Test-Path -LiteralPath $b)) {
        Write-Host "  - missing file: $a or $b"
        return $false
    }
    $ha = (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash
    $hb = (Get-FileHash -LiteralPath $b -Algorithm SHA256).Hash
    if ($ha -eq $hb) { return $true }
    Write-Host "  - files differ: $a vs $b"
    return $false
}

function Invoke-Scenario {
    param([string]$Name, [scriptblock]$Body)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $ok = & $Body }
    finally { $ErrorActionPreference = $previous }
    if ($ok) { Write-Pass $Name } else { Write-Fail $Name }
}

try {
    # --- 1. install creates an executable hook with the managed block -----
    New-Repo 'install'
    Invoke-Installer
    $hook = Join-Path $script:Repo '.git/hooks/pre-commit'
    Invoke-Scenario 'install writes an executable pre-commit hook' {
        (Test-Status 0) -and (Test-Contains 'TASK_CARD_HOOK|INSTALLED') -and (Test-File $hook)
    }
    if ((Test-File $hook) -and (Get-Content -LiteralPath $hook -Raw).Contains('PROMPTKIT_TASK_CARD_GATE')) {
        Write-Pass 'hook carries the managed markers'
    }
    else { Write-Fail 'hook carries the managed markers' }

    # --- 2. install is idempotent ----------------------------------------
    $once = Join-Path $tempRoot 'hook-once'
    Copy-Item -LiteralPath $hook -Destination $once -Force
    Invoke-Installer
    Invoke-Scenario 'second install is byte-identical' {
        (Test-Status 0) -and (Test-SameBytes ($once + '|' + $hook))
    }

    # --- 3. a badly ordered card cannot be committed ----------------------
    New-Repo 'blocks'
    Invoke-Installer
    Write-BadCard
    & git -C $script:Repo add benchmarks/tasks/TASK-BENCH-T-01.md | Out-Null
    $headBefore = Get-Head
    Invoke-Commit 'bad card'
    Invoke-Scenario 'badly ordered card is blocked before commit' {
        (Test-NonZero 'x') -and (Test-Contains 'Commit blocked') -and (Test-Contains 'runs before the behavioral probe')
    }
    if ((Get-Head) -eq $headBefore) { Write-Pass 'blocked commit leaves HEAD untouched' }
    else { Write-Fail 'blocked commit leaves HEAD untouched' }

    # --- 4. a compliant card commits -------------------------------------
    New-Repo 'passes'
    Invoke-Installer
    Write-GoodCard
    & git -C $script:Repo add benchmarks/tasks/TASK-BENCH-T-02.md | Out-Null
    $headBefore = Get-Head
    Invoke-Commit 'good card'
    Invoke-Scenario 'compliant card commits through the hook' { (Test-Status 0) }
    if ((Get-Head) -ne $headBefore) { Write-Pass 'compliant commit advanced HEAD' }
    else { Write-Fail 'compliant commit advanced HEAD' }

    # --- 5. unrelated commits are not gated ------------------------------
    New-Repo 'scoped'
    Invoke-Installer
    Write-BadCard
    Add-Content -LiteralPath (Join-Path $script:Repo 'README.md') -Value '# changed'
    & git -C $script:Repo add README.md | Out-Null
    Invoke-Commit 'unrelated'
    Invoke-Scenario 'unrelated commit runs the hook as a no-op' { (Test-Status 0) }

    # --- 6. an existing shell hook body is preserved and still runs ------
    New-Repo 'chained'
    $hookDir = Join-Path $script:Repo '.git/hooks'
    New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
    $existing = Join-Path $hookDir 'pre-commit'
    Set-Content -LiteralPath $existing -Value @('#!/bin/sh', 'echo ran >> "$(git rev-parse --show-toplevel)/hooked.txt"')
    Invoke-Installer
    Write-GoodCard
    & git -C $script:Repo add benchmarks/tasks/TASK-BENCH-T-02.md | Out-Null
    Invoke-Commit 'good card'
    Invoke-Scenario 'existing hook body still runs after the gate' {
        (Test-Status 0) -and (Test-File (Join-Path $script:Repo 'hooked.txt'))
    }

    # --- 7. remove restores the original body ----------------------------
    New-Repo 'restore'
    $hookDir = Join-Path $script:Repo '.git/hooks'
    New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
    $existing = Join-Path $hookDir 'pre-commit'
    Set-Content -LiteralPath $existing -Value @('#!/bin/sh', 'echo original')
    $original = Join-Path $tempRoot 'original-hook'
    Copy-Item -LiteralPath $existing -Destination $original -Force
    Invoke-Installer
    Invoke-Installer @('--remove')
    Invoke-Scenario 'remove restores the original hook byte-for-byte' {
        (Test-Status 0) -and (Test-Contains 'TASK_CARD_HOOK|REMOVED') -and (Test-SameBytes ($original + '|' + $existing))
    }

    # --- 8. remove deletes a hook it created entirely --------------------
    New-Repo 'created'
    Invoke-Installer
    Invoke-Installer @('--remove')
    Invoke-Scenario 'remove deletes a hook it created' {
        (Test-Status 0) -and (Test-Contains 'TASK_CARD_HOOK|REMOVED') -and (Test-NoFile (Join-Path $script:Repo '.git/hooks/pre-commit'))
    }

    # --- 9. a non-shell hook is wrapped, not corrupted -------------------
    New-Repo 'nonshell'
    $hookDir = Join-Path $script:Repo '.git/hooks'
    New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
    $existing = Join-Path $hookDir 'pre-commit'
    Set-Content -LiteralPath $existing -Value @('#!/usr/bin/env python3', 'print("original")')
    $originalPy = Join-Path $tempRoot 'original-python-hook'
    Copy-Item -LiteralPath $existing -Destination $originalPy -Force
    Invoke-Installer
    Invoke-Scenario 'non-shell hook is preserved as promptkit-orig' {
        (Test-Status 0) -and (Test-File ($existing + '.promptkit-orig')) -and (Test-SameBytes ($originalPy + '|' + $existing + '.promptkit-orig'))
    }
    Invoke-Installer @('--remove')
    Invoke-Scenario 'remove restores a wrapped non-shell hook' {
        (Test-Status 0) -and (Test-SameBytes ($originalPy + '|' + $existing)) -and (Test-NoFile ($existing + '.promptkit-orig'))
    }

    # --- 10. no repository -----------------------------------------------
    $script:Repo = Join-Path $tempRoot 'not-a-repo'
    New-Item -ItemType Directory -Force -Path $script:Repo | Out-Null
    Invoke-Installer
    Invoke-Scenario 'missing repository fails closed' {
        (Test-Status 2) -and (Test-Contains 'TASK_CARD_HOOK|INCOMPLETE|NO_REPO')
    }

    # --- 11. a card is judged as staged, not as it sits on disk -----------
    New-Repo 'staged-not-worktree'
    Invoke-Installer
    Write-BadCard
    & git -C $script:Repo add benchmarks/tasks/TASK-BENCH-T-01.md | Out-Null
    Write-Card -Name 'TASK-BENCH-T-01.md' -Id 'BENCH-T-01' -Verify $script:GoodVerify
    $headBefore = Get-Head
    Invoke-Commit 'bad card staged, fixed only on disk'
    Invoke-Scenario 'a bad card staged and fixed only on disk is blocked' {
        (Test-NonZero 'x') -and (Test-Contains 'Commit blocked') -and (Test-Contains 'runs before the behavioral probe')
    }
    if ((Get-Head) -eq $headBefore) { Write-Pass 'partial-staging block leaves HEAD untouched' }
    else { Write-Fail 'partial-staging block leaves HEAD untouched' }

    # --- 12. a compliant staged card survives a broken working-tree copy --
    New-Repo 'worktree-not-staged'
    Invoke-Installer
    Write-GoodCard
    & git -C $script:Repo add benchmarks/tasks/TASK-BENCH-T-02.md | Out-Null
    Write-Card -Name 'TASK-BENCH-T-02.md' -Id 'BENCH-T-02' -Verify $script:BadVerify
    Invoke-Commit 'good card staged, broken only on disk'
    Invoke-Scenario 'a compliant staged card commits despite a broken working-tree copy' { (Test-Status 0) }
    $blob = (& git -C $script:Repo show 'HEAD:benchmarks/tasks/TASK-BENCH-T-02.md' 2>$null | Out-String)
    if ($blob.Contains('probe=$?')) { Write-Pass 'the committed blob is the staged compliant card' }
    else { Write-Fail 'the committed blob is the staged compliant card' }

    # --- 13. an unstaged card cannot block a staged one -------------------
    New-Repo 'staged-only'
    Invoke-Installer
    Write-BadCard
    Write-GoodCard
    & git -C $script:Repo add benchmarks/tasks/TASK-BENCH-T-02.md | Out-Null
    Invoke-Commit 'staged good card beside an unstaged bad card'
    Invoke-Scenario 'an unstaged card elsewhere in the tree does not block' { (Test-Status 0) }

    # --- 14. remove strips a CRLF hook ------------------------------------
    # A hook edited on Windows carries `r on every line; the marker match used
    # to fail, so -Remove reported success and left the managed block in place.
    New-Repo 'crlf-remove'
    Invoke-Installer
    $crlfHook = Join-Path $script:Repo '.git/hooks/pre-commit'
    $crlfText = (Get-Content -LiteralPath $crlfHook -Raw) -replace "`r?`n", "`r`n"
    [IO.File]::WriteAllText($crlfHook, $crlfText, [Text.UTF8Encoding]::new($false))
    Invoke-Installer @('--remove')
    Invoke-Scenario 'remove strips a CRLF hook' { (Test-Status 0) -and (Test-Contains 'TASK_CARD_HOOK|REMOVED') }
    $crlfLeft = if (Test-Path -LiteralPath $crlfHook) { (Get-Content -LiteralPath $crlfHook -Raw) } else { '' }
    if (-not $crlfLeft.Contains('PROMPTKIT_TASK_CARD_GATE')) { Write-Pass 'CRLF remove left no managed block' }
    else { Write-Fail 'CRLF remove left no managed block' }

    # --- 15. a non-ASCII card name is still gated -------------------------
    # git C-quotes a non-ASCII path unless core.quotepath=false, so the
    # staged-card lookup saw no card and the gate skipped the commit.
    New-Repo 'unicode-card'
    Invoke-Installer
    $u = [char]0x00DC
    $uName = "TASK-BENCH-$u-01.md"
    Write-Card -Name $uName -Id "BENCH-$u-01" -Verify $script:BadVerify
    & git -C $script:Repo add "benchmarks/tasks/$uName" | Out-Null
    $uBefore = Get-Head
    Invoke-Commit 'badly ordered card with a non-ASCII filename'
    Invoke-Scenario 'a non-ASCII card name is still gated' { (Test-NonZero '') }
    if ((Get-Head) -eq $uBefore) { Write-Pass 'the non-ASCII blocked commit left HEAD untouched' }
    else { Write-Fail 'the non-ASCII blocked commit left HEAD untouched' }

}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "RESULTS|passed=$script:Pass|failed=$script:Fail"
if ($script:Fail -gt 0) { exit 1 }
exit 0
