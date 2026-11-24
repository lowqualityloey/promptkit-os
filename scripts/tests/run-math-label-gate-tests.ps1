# Regression tests for the math-label gate's file scope.
# The gate must see the same *.md set locally as CI checks out: git-tracked plus
# untracked-but-not-ignored files. Before this scope existed the gate scanned every
# *.md on disk, so 4,844 gitignored files (benchmarks, scratch, tmp, .qa-evidence)
# made it green in CI and red on a developer machine.
#
# Run from repository root: pwsh -NoProfile -File ./scripts/tests/run-math-label-gate-tests.ps1

param()

$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).ProviderPath
$Gate = Join-Path $RepoRoot 'scripts/check-math-labels.ps1'

$script:Pass = 0
$script:Fail = 0

function Check {
    param([string]$Label, [int]$ExpectedExit, [int]$ActualExit, [string]$Out)
    if ($ActualExit -eq $ExpectedExit) {
        Write-Host "  PASS: $Label"
        $script:Pass++
    } else {
        Write-Host "  FAIL: $Label (expected exit $ExpectedExit, got $ActualExit)"
        Write-Host "     Output: $Out"
        $script:Fail++
    }
}

function CheckContains {
    param([string]$Label, [string]$Needle, [string]$Out)
    if ($Out.Contains($Needle)) {
        Write-Host "  PASS: $Label"
        $script:Pass++
    } else {
        Write-Host "  FAIL: $Label (missing: $Needle)"
        Write-Host "     Output: $Out"
        $script:Fail++
    }
}

function Invoke-Gate {
    param([string]$Root)
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $Gate -Root $Root 2>&1 | Out-String
    return @{ Exit = $LASTEXITCODE; Out = $out }
}

function New-Repo {
    param([string]$Dir)
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    & git -C $Dir init -q .
    & git -C $Dir config user.email 't@example.com'
    & git -C $Dir config user.name 't'
}

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ('math-label-gate-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Work -Force | Out-Null

$Violation = 'A label like $\text{dev\_hourly}$ breaks.'

try {
    Write-Host '=== Math Label Gate Scope Tests (PowerShell) ==='

    # Case 1: a tracked violation fails the gate.
    $r1 = Join-Path $Work 'tracked'
    New-Repo $r1
    Set-Content -LiteralPath (Join-Path $r1 'docs.md') -Value $Violation
    & git -C $r1 add docs.md
    $res = Invoke-Gate $r1
    Check 'Tracked violation fails the gate' 1 $res.Exit $res.Out
    CheckContains 'Tracked violation is reported by relative path' 'docs.md:1:' $res.Out
    CheckContains 'Gate announces git scope' 'MATH_LABEL_GATE|SCOPE|mode=git|files=1' $res.Out

    # Case 2: a gitignored violation passes, because CI never sees that file.
    $r2 = Join-Path $Work 'ignored'
    New-Repo $r2
    Set-Content -LiteralPath (Join-Path $r2 '.gitignore') -Value 'scratch/'
    New-Item -ItemType Directory -Path (Join-Path $r2 'scratch') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $r2 'scratch/notes.md') -Value $Violation
    Set-Content -LiteralPath (Join-Path $r2 'docs.md') -Value 'Clean tracked file.'
    & git -C $r2 add .gitignore docs.md
    $res = Invoke-Gate $r2
    Check 'Gitignored violation passes' 0 $res.Exit $res.Out
    CheckContains 'Gitignored file is out of scope' 'MATH_LABEL_GATE|SCOPE|mode=git|files=1' $res.Out

    # Case 3: an untracked-but-not-ignored violation fails, because CI would see it.
    $r3 = Join-Path $Work 'untracked'
    New-Repo $r3
    Set-Content -LiteralPath (Join-Path $r3 'new.md') -Value $Violation
    $res = Invoke-Gate $r3
    Check 'Untracked-but-not-ignored violation fails' 1 $res.Exit $res.Out
    CheckContains 'Untracked file is in scope' 'MATH_LABEL_GATE|SCOPE|mode=git|files=1' $res.Out

    # Case 4: exempt classes pass even when they carry the violation.
    $r4 = Join-Path $Work 'exempt'
    New-Repo $r4
    foreach ($sub in @('docs/releases', 'docs/archive', 'docs/internal', 'docs/tasks')) {
        New-Item -ItemType Directory -Path (Join-Path $r4 $sub) -Force | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $r4 'docs/releases/r.md') -Value $Violation
    Set-Content -LiteralPath (Join-Path $r4 'docs/archive/a.md') -Value $Violation
    Set-Content -LiteralPath (Join-Path $r4 'docs/internal/i.md') -Value $Violation
    Set-Content -LiteralPath (Join-Path $r4 'docs/tasks/t.md') -Value $Violation
    Set-Content -LiteralPath (Join-Path $r4 'CHANGELOG.md') -Value $Violation
    & git -C $r4 add -A
    $res = Invoke-Gate $r4
    Check 'Exempt classes pass' 0 $res.Exit $res.Out
    CheckContains 'All five exempt files are in scope but skipped' 'MATH_LABEL_GATE|SCOPE|mode=git|files=5' $res.Out

    # Case 5: a non-git root still detects, via the recursive fallback.
    $r5 = Join-Path $Work 'plain'
    New-Item -ItemType Directory -Path (Join-Path $r5 'nested') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $r5 'nested/notes.md') -Value $Violation
    $res = Invoke-Gate $r5
    Check 'Non-git root still detects a violation' 1 $res.Exit $res.Out
    CheckContains 'Fallback announces scan scope' 'MATH_LABEL_GATE|SCOPE|mode=scan|files=1' $res.Out

    # Case 6: a clean tree passes.
    $r6 = Join-Path $Work 'clean'
    New-Repo $r6
    Set-Content -LiteralPath (Join-Path $r6 'docs.md') -Value 'A label like $\text{dev-hourly}$ is fine.'
    & git -C $r6 add docs.md
    $res = Invoke-Gate $r6
    Check 'Clean tree passes' 0 $res.Exit $res.Out
    CheckContains 'Clean tree reports PASS' 'MATH_LABEL_GATE|PASS' $res.Out

    # Case 7: the repository itself is green under git scope.
    $res = Invoke-Gate $RepoRoot
    Check 'Repository passes under git scope' 0 $res.Exit $res.Out
    CheckContains 'Repository scope is git mode' 'MATH_LABEL_GATE|SCOPE|mode=git|' $res.Out
}
finally {
    Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "MATH_LABEL_GATE_TESTS|$script:Pass passed|$script:Fail failed"
if ($script:Fail -gt 0) { exit 1 }
exit 0
