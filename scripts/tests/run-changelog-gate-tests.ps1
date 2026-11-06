# Regression harness for the CHANGELOG behavior-surface gate.
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-changelog-gate-tests.ps1
#
# Every case builds a throwaway repository with a base commit and one head
# commit, then runs the real gate against that committed range. A repository
# fixture keeps the gate on its real code path: git range, synthetic-base
# preflight, and path classification are all exercised, not mocked.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$gate = Join-Path $repoRoot 'scripts/check-changelog-entry.ps1'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-changelog-gate-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)

$script:PASS = 0
$script:FAIL = 0
$script:SCENARIO_OK = $true
$script:STATUS = 0
$script:OUT = ''

function Write-Pass { param([string]$Label) Write-Output "PASS: $Label"; $script:PASS++ }
function Write-Fail { param([string]$Label) Write-Output "FAIL: $Label"; $script:FAIL++ }
function Begin-Scenario { $script:SCENARIO_OK = $true }
function Report-Scenario { param([string]$Label) if ($script:SCENARIO_OK) { Write-Pass $Label } else { Write-Fail $Label } }
function Assert-Scenario {
    param([bool]$Condition, [string]$Description)
    if (-not $Condition) { Write-Output "  - $Description"; $script:SCENARIO_OK = $false }
}
function Want-Status { param([int]$Expected) Assert-Scenario ($script:STATUS -eq $Expected) "expected exit $Expected, got $($script:STATUS)" }
function Want-Contains { param([string]$Needle) Assert-Scenario ($script:OUT.Contains($Needle)) "stdout missing: $Needle" }
function Want-NotContains { param([string]$Needle) Assert-Scenario (-not $script:OUT.Contains($Needle)) "stdout unexpectedly contains: $Needle" }

function Invoke-Gate {
    param([string]$RootPath)
    Push-Location -LiteralPath $RootPath
    try {
        $raw = @(& pwsh -NoProfile -File $gate -Base 'HEAD~1' -Head 'HEAD' 2>&1)
        $script:STATUS = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $script:OUT = ((@($raw | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
}

function New-Repo {
    param([string]$Name)
    $dir = Join-Path $tmp $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    & git -C $dir init -q | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git init failed for $Name" }
    & git -C $dir config user.name Fixture | Out-Null
    & git -C $dir config user.email fixture@example.invalid | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'file.txt'), "base`n", $utf8)
    & git -C $dir add -A | Out-Null
    & git -C $dir commit -qm 'base' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "base commit failed for $Name" }
    return $dir
}

function Add-HeadCommit {
    param([string]$RootPath, [string[]]$Paths)
    foreach ($rel in $Paths) {
        $full = Join-Path $RootPath $rel
        $parent = Split-Path -Parent $full
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        [IO.File]::WriteAllText($full, "change`n", $utf8)
    }
    & git -C $RootPath add -A | Out-Null
    & git -C $RootPath commit -qm 'change' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "head commit failed for $RootPath" }
}

try {
    # C1: a benchmark driver change without an entry is a behavior-surface miss.
    Begin-Scenario
    $root1 = New-Repo 'c1'
    Add-HeadCommit -RootPath $root1 -Paths @('benchmarks/run-ab-benchmark.sh')
    Invoke-Gate -RootPath $root1
    Want-Status 1
    Want-Contains 'CHANGELOG_GATE|MISSING|'
    Want-Contains 'benchmarks/run-ab-benchmark.sh'
    Want-NotContains 'CHANGELOG_GATE|PASS|'
    Report-Scenario 'C1 benchmark driver without CHANGELOG -> MISSING'

    # C2: the same driver change with an [Unreleased] entry passes.
    Begin-Scenario
    $root2 = New-Repo 'c2'
    Add-HeadCommit -RootPath $root2 -Paths @('benchmarks/run-ab-benchmark.sh', 'CHANGELOG.md')
    Invoke-Gate -RootPath $root2
    Want-Status 0
    Want-Contains 'CHANGELOG_GATE|PASS|behavior-surface changes carry a CHANGELOG.md entry'
    Report-Scenario 'C2 benchmark driver with CHANGELOG -> PASS'

    # C3: documentation under benchmarks/ is not a behavior surface.
    Begin-Scenario
    $root3 = New-Repo 'c3'
    Add-HeadCommit -RootPath $root3 -Paths @('benchmarks/README.md')
    Invoke-Gate -RootPath $root3
    Want-Status 0
    Want-Contains 'CHANGELOG_GATE|PASS|no behavior-surface paths in range'
    Report-Scenario 'C3 benchmark documentation without CHANGELOG -> PASS (not gated)'
} catch {
    Write-Fail ('harness aborted: ' + $_.Exception.Message)
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Output ''
Write-Output ("CHANGELOG_GATE_TESTS|{0} passed|{1} failed" -f $script:PASS, $script:FAIL)
if ($script:FAIL -ne 0) { exit 1 }
exit 0
