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

# Write-Changelog <root> <line>... writes CHANGELOG.md verbatim (one argument
# per line) so a fixture can pin an exact heading layout.
function Write-Changelog {
    param([string]$RootPath, [string[]]$Lines)
    $text = (($Lines -join "`n") + "`n")
    [IO.File]::WriteAllText((Join-Path $RootPath 'CHANGELOG.md'), $text, $utf8)
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

    # C4: a version section that repeats a heading is rejected even though the
    # range carries a CHANGELOG.md entry. The fixture reproduces the exact shape
    # the [Unreleased] section had before it was collapsed: two ### Added groups
    # split by another heading.
    Begin-Scenario
    $root4 = New-Repo 'c4'
    Write-Changelog -RootPath $root4 -Lines @(
        '# Changelog',
        '',
        '## [Unreleased]',
        '',
        '### Added',
        '',
        '- first added bullet',
        '',
        '### Fixed',
        '',
        '- a fixed bullet',
        '',
        '### Added',
        '',
        '- second added bullet',
        '',
        '## [1.0.0] - 2026-01-01',
        '',
        '### Added',
        '',
        '- released bullet'
    )
    Add-HeadCommit -RootPath $root4 -Paths @('benchmarks/run-ab-benchmark.sh')
    Invoke-Gate -RootPath $root4
    Want-Status 1
    Want-Contains 'CHANGELOG_GATE|DUPLICATE-HEADING|'
    Want-Contains '## [Unreleased] -> ### Added (2 occurrences)'
    Want-Contains 'CHANGELOG_GATE|REMEDIATION|'
    Want-NotContains 'CHANGELOG_GATE|PASS|'
    Report-Scenario 'C4 duplicate heading inside one version section -> DUPLICATE-HEADING'

    # C5: the same range with one heading per kind passes, so the check rejects
    # only the duplicate shape and not every CHANGELOG.md entry.
    Begin-Scenario
    $root5 = New-Repo 'c5'
    Write-Changelog -RootPath $root5 -Lines @(
        '# Changelog',
        '',
        '## [Unreleased]',
        '',
        '### Added',
        '',
        '- first added bullet',
        '- second added bullet',
        '',
        '### Fixed',
        '',
        '- a fixed bullet',
        '',
        '## [1.0.0] - 2026-01-01',
        '',
        '### Added',
        '',
        '- released bullet'
    )
    Add-HeadCommit -RootPath $root5 -Paths @('benchmarks/run-ab-benchmark.sh')
    Invoke-Gate -RootPath $root5
    Want-Status 0
    Want-Contains 'CHANGELOG_GATE|PASS|behavior-surface changes carry a CHANGELOG.md entry'
    Want-NotContains 'CHANGELOG_GATE|DUPLICATE-HEADING|'
    Report-Scenario 'C5 one heading per kind per version section -> PASS'
} catch {
    Write-Fail ('harness aborted: ' + $_.Exception.Message)
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Output ''
Write-Output ("CHANGELOG_GATE_TESTS|{0} passed|{1} failed" -f $script:PASS, $script:FAIL)
if ($script:FAIL -ne 0) { exit 1 }
exit 0
