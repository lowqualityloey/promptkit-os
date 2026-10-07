# Regression harness for the read-only gitignore preflight of pk:checkpoint.
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-checkpoint-ignore-tests.ps1
#
# Each scenario runs in its own throwaway git repository. The scanner is
# read-only: S1-S4 also assert the index and worktree status are byte-identical
# before and after the scan (the removed force-add regression lock).

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$scanner = Join-Path $repoRoot 'scripts/check-checkpoint-ignore.ps1'

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-checkpoint-ignore-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)

$script:PASS = 0
$script:FAIL = 0
$script:SCENARIO_OK = $true
$script:STATUS = 0
$script:OUT = ''
$script:exitCode = 0

function Write-Pass {
    param([string]$Label)
    Write-Output "PASS: $Label"
    $script:PASS++
}

function Write-Fail {
    param([string]$Label)
    Write-Output "FAIL: $Label"
    $script:FAIL++
}

function Begin-Scenario { $script:SCENARIO_OK = $true }

function Report-Scenario {
    param([string]$Label)
    if ($script:SCENARIO_OK) { Write-Pass $Label } else { Write-Fail $Label }
}

function Assert-Scenario {
    param([bool]$Condition, [string]$Description)
    if (-not $Condition) {
        Write-Output "  - $Description"
        $script:SCENARIO_OK = $false
    }
}

function Want-Status {
    param([int]$Expected)
    Assert-Scenario ($script:STATUS -eq $Expected) "expected exit $Expected, got $($script:STATUS)"
}

function Want-Contains {
    param([string]$Needle)
    Assert-Scenario ($script:OUT.Contains($Needle)) "stdout missing: $Needle"
}

function Want-NotContains {
    param([string]$Needle)
    Assert-Scenario (-not $script:OUT.Contains($Needle)) "stdout unexpectedly contains: $Needle"
}

function Want-Unchanged {
    param([string]$Before, [string]$After)
    Assert-Scenario ($Before -eq $After) 'git index/status changed across the scan'
}

function Get-ReadOnlySnapshot {
    param([string]$RootPath)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @(& git -C $RootPath diff --cached --name-only 2>$null)) {
        $lines.Add($line.ToString())
    }
    foreach ($line in @(& git -C $RootPath status --porcelain=v1 --untracked-files=all 2>$null)) {
        $lines.Add($line.ToString())
    }
    return (($lines | ForEach-Object { $_ }) -join "`n")
}

function Invoke-Scanner {
    param([string]$ScannerRoot, [string[]]$ExtraArgs = @())
    $arguments = @('-NoProfile', '-File', $scanner, '-Root', $ScannerRoot) + $ExtraArgs
    $raw = @(& pwsh @arguments 2>$null)
    $script:STATUS = $LASTEXITCODE
    $script:OUT = ((@($raw | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '').Replace('\', '/')
}

function New-Repo {
    param([string]$Name)
    $dir = Join-Path $tmp $Name
    New-Item -ItemType Directory -Path (Join-Path $dir 'docs/tasks') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'docs/STATE.md'), "# State`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $dir 'docs/tasks/TASK-1.md'), "# Task 1`n", $utf8)
    & git -C $dir init -q | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git init failed for $Name" }
    return $dir
}

try {
    # S1: no ignore rule => clean, nothing reported, index untouched.
    Begin-Scenario
    $root1 = New-Repo 's1'
    $before1 = Get-ReadOnlySnapshot $root1
    Invoke-Scanner $root1
    $after1 = Get-ReadOnlySnapshot $root1
    Want-Status 0
    Want-Contains 'CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=5'
    Want-NotContains 'POLICY_LIMITATION|'
    Want-Unchanged $before1 $after1
    Report-Scenario 'S1 no .gitignore -> clean'

    # S2: docs/ ignored => both targets reported with the verbatim rule, degraded.
    Begin-Scenario
    $root2 = New-Repo 's2'
    [IO.File]::WriteAllText((Join-Path $root2 '.gitignore'), "docs/`n", $utf8)
    $before2 = Get-ReadOnlySnapshot $root2
    Invoke-Scanner $root2
    $after2 = Get-ReadOnlySnapshot $root2
    Want-Status 0
    Want-Contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/STATE.md|'
    Want-Contains '.gitignore:1:docs/'
    Want-Contains 'CHECKPOINT_IGNORE|DEGRADED|IGNORED=5|SCANNED=5'
    Want-Unchanged $before2 $after2
    Report-Scenario 'S2 docs/ ignored -> degraded, verbatim rule'

    # S3: broken git (exit 3) => fail-closed INCOMPLETE, never a success summary.
    Begin-Scenario
    $root3 = New-Repo 's3'
    $stub3 = Join-Path $tmp 's3-stub'
    New-Item -ItemType Directory -Path $stub3 -Force | Out-Null
    if ($IsWindows) {
        [IO.File]::WriteAllText((Join-Path $stub3 'git.cmd'), "@exit /b 3`r`n", $utf8)
    } else {
        $stubGit = Join-Path $stub3 'git'
        [IO.File]::WriteAllText($stubGit, "#!/bin/sh`nexit 3`n", $utf8)
        & chmod +x $stubGit
    }
    $savedPath = $env:PATH
    try {
        $env:PATH = "$stub3$([IO.Path]::PathSeparator)$savedPath"
        Invoke-Scanner $root3
    } finally {
        $env:PATH = $savedPath
    }
    Want-Status 2
    Want-Contains 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_IGNORE|'
    Want-NotContains 'NO_FINDINGS'
    Want-NotContains 'DEGRADED'
    Report-Scenario 'S3 broken git -> INCOMPLETE GIT_IGNORE'

    # S4: tracked-but-matches-ignore is visible to git => not reported (no --no-index).
    Begin-Scenario
    $root4 = New-Repo 's4'
    [IO.File]::WriteAllText((Join-Path $root4 '.gitignore'), "docs/`n", $utf8)
    & git -C $root4 add -f docs/STATE.md | Out-Null
    $before4 = Get-ReadOnlySnapshot $root4
    Invoke-Scanner $root4
    $after4 = Get-ReadOnlySnapshot $root4
    Want-Status 0
    Want-NotContains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/STATE.md|'
    Want-Contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/TASK-1.md|'
    Want-Contains 'CHECKPOINT_IGNORE|DEGRADED|IGNORED=4|SCANNED=5'
    Want-Unchanged $before4 $after4
    Report-Scenario 'S4 tracked matches ignore -> not reported'

    # S5: unreadable targets file => INCOMPLETE RULES.
    Begin-Scenario
    $root5 = New-Repo 's5'
    Invoke-Scanner $root5 @('-TargetsFile', '/nonexistent/checkpoint-targets.txt')
    Want-Status 2
    Want-Contains 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|.'
    Report-Scenario 'S5 missing targets file -> INCOMPLETE RULES'

    # S6: no .git under root => INCOMPLETE GIT_METADATA.
    Begin-Scenario
    $dir6 = Join-Path $tmp 's6'
    New-Item -ItemType Directory -Path (Join-Path $dir6 'docs/tasks') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir6 'docs/STATE.md'), "# State`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $dir6 'docs/tasks/TASK-1.md'), "# Task 1`n", $utf8)
    Invoke-Scanner $dir6
    Want-Status 2
    Want-Contains 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.'
    Report-Scenario 'S6 no .git -> INCOMPLETE GIT_METADATA'

    # S7: custom targets file skips comments/blanks and scans only its row.
    Begin-Scenario
    $root7 = New-Repo 's7'
    $targets7 = Join-Path $tmp 's7-targets.txt'
    [IO.File]::WriteAllText($targets7, "# comment`n`ncustom/notes.md|file`n", $utf8)
    Invoke-Scanner $root7 @('-TargetsFile', $targets7)
    Want-Status 0
    Want-Contains 'CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=1'
    Report-Scenario 'S7 custom targets file skips comments/blanks'

    # S8: malformed rows => INCOMPLETE RULES before any measurement.
    Begin-Scenario
    $badRows = @('docs/STATE.md', 'docs/STATE.md|bogus', '|file', 'a|b|file')
    $badIndex = 0
    foreach ($badRow in $badRows) {
        $badIndex++
        $root8 = New-Repo "s8-$badIndex"
        $targets8 = Join-Path $tmp "s8-$badIndex-targets.txt"
        [IO.File]::WriteAllText($targets8, "$badRow`n", $utf8)
        Invoke-Scanner $root8 @('-TargetsFile', $targets8)
        Want-Status 2
        Want-Contains 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|'
        Want-NotContains 'NO_FINDINGS'
        Want-NotContains 'DEGRADED'
    }
    # The final row is `a|b|file`; its row text is printed pipes-as-spaces.
    Want-Contains 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|a b file'
    Report-Scenario 'S8 malformed rows -> INCOMPLETE RULES'

    # S9: ignored empty records dir => dir self-probe is reported, degraded.
    Begin-Scenario
    $root9 = New-Repo 's9'
    Remove-Item -LiteralPath (Join-Path $root9 'docs/tasks/TASK-1.md') -Force
    [IO.File]::WriteAllText((Join-Path $root9 '.gitignore'), "docs/tasks/`n", $utf8)
    $before9 = Get-ReadOnlySnapshot $root9
    Invoke-Scanner $root9
    $after9 = Get-ReadOnlySnapshot $root9
    Want-Status 0
    Want-Contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/|'
    Want-Contains '.gitignore:1:docs/tasks/'
    Want-Contains 'DEGRADED'
    Want-NotContains 'NO_FINDINGS'
    Want-Unchanged $before9 $after9
    Report-Scenario 'S9 ignored empty records dir -> degraded'

    # S10: prospective record name ignored => that name reported, degraded.
    Begin-Scenario
    $root10 = New-Repo 's10'
    [IO.File]::WriteAllText((Join-Path $root10 '.gitignore'), "*.checkpoint-*.md`n", $utf8)
    $before10 = Get-ReadOnlySnapshot $root10
    Invoke-Scanner $root10
    $after10 = Get-ReadOnlySnapshot $root10
    Want-Status 0
    Want-Contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/pk-probe.checkpoint-1.md|'
    Want-Contains '.gitignore:1:*.checkpoint-*.md'
    Want-NotContains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/pk-probe.handoff-1.md|'
    Want-Unchanged $before10 $after10
    Report-Scenario 'S10 prospective record name ignored -> degraded'

    # S11: git cannot be started at all => INCOMPLETE GIT_IGNORE (exit 2),
    # not a leaked CommandNotFoundException with exit 1. The child pwsh is
    # launched by absolute path with an empty PATH so `git` genuinely does
    # not resolve (no stub).
    Begin-Scenario
    $root11 = New-Repo 's11'
    $emptyPath = Join-Path $tmp 's11-empty-path'
    New-Item -ItemType Directory -Path $emptyPath -Force | Out-Null
    $pwshExe = (Get-Process -Id $PID).Path
    if (-not $pwshExe) { $pwshExe = Join-Path $PSHOME 'pwsh' }
    $savedPath11 = $env:PATH
    try {
        $env:PATH = $emptyPath
        $args11 = @('-NoProfile', '-File', $scanner, '-Root', $root11)
        $raw11 = @(& $pwshExe @args11 2>$null)
        $script:STATUS = $LASTEXITCODE
        $script:OUT = ((@($raw11 | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '').Replace('\', '/')
    } finally {
        $env:PATH = $savedPath11
    }
    Want-Status 2
    Want-Contains 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_IGNORE|docs/STATE.md'
    Want-NotContains 'NO_FINDINGS'
    Want-NotContains 'DEGRADED'
    Report-Scenario 'S11 git not launchable -> INCOMPLETE GIT_IGNORE'

    Write-Output "Passed: $($script:PASS) | Failed: $($script:FAIL)"
    if ($script:FAIL -ne 0) { $script:exitCode = 1 } else { $script:exitCode = 0 }
} finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}
exit $script:exitCode
