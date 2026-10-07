# Regression harness for the read-only synthetic-base preflight.
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-synthetic-base-tests.ps1
#
# Each scenario runs in its own throwaway git repository. S11 also asserts the
# index and worktree are byte-identical before and after the scan (the
# read-only lock); every other scenario exercises a verdict or a fail-closed row.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$checker = Join-Path $repoRoot 'scripts/check-synthetic-base.ps1'
$changelogGate = Join-Path $repoRoot 'scripts/check-changelog-entry.ps1'

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-synthetic-base-' + [guid]::NewGuid().ToString('N'))
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
function Want-Unchanged { param([string]$Before, [string]$After) Assert-Scenario ($Before -eq $After) 'worktree/index changed across the scan' }

function Get-ReadOnlySnapshot {
    param([string]$RootPath)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @(& git -C $RootPath diff --cached --name-only 2>$null)) { $lines.Add($line.ToString()) }
    foreach ($line in @(& git -C $RootPath status --porcelain=v1 --untracked-files=all 2>$null)) { $lines.Add($line.ToString()) }
    return (($lines | ForEach-Object { $_ }) -join "`n")
}

function Invoke-Checker {
    param([string]$CheckerRoot, [string[]]$ExtraArgs = @(), [hashtable]$EnvOverrides = @{})
    $arguments = @('-NoProfile', '-File', $checker, '-Root', $CheckerRoot) + $ExtraArgs
    $saved = @{}
    foreach ($key in $EnvOverrides.Keys) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, [string]$EnvOverrides[$key], 'Process')
    }
    try {
        $raw = @(& pwsh @arguments 2>$null)
        $script:STATUS = $LASTEXITCODE
    } finally {
        foreach ($key in $EnvOverrides.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process') }
    }
    $script:OUT = ((@($raw | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '').Replace('\', '/')
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
    & git -C $dir add file.txt | Out-Null
    & git -C $dir commit -qm 'base commit' | Out-Null
    return $dir
}

# A fresh detached commit the branch does not carry: the ordinary shape of both
# a synthetic workspace commit and a legitimate detached checkout, which only
# the owned-ref signal tells apart.
function New-DetachedRepo {
    param([string]$Name)
    $dir = New-Repo $Name
    & git -C $dir checkout -q --detach HEAD | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'detached.txt'), "detached`n", $utf8)
    & git -C $dir add detached.txt | Out-Null
    & git -C $dir commit -qm 'detached commit' | Out-Null
    return $dir
}

function Add-OwnedRef {
    param([string]$Repo, [string]$Ref)
    & git -C $Repo update-ref $Ref HEAD | Out-Null
}

try {
    # S1 (Scenario 1): a normal branch HEAD is silent.
    Begin-Scenario
    $root1 = New-Repo 's1'
    Invoke-Checker -CheckerRoot $root1
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|OK|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S1 normal branch HEAD -> OK'

    # S2 (Scenario 2): an owned tool ref with no carrying branch is refused.
    Begin-Scenario
    $root2 = New-DetachedRepo 's2'
    Add-OwnedRef $root2 'refs/gitbutler/wt'
    Invoke-Checker -CheckerRoot $root2
    Want-Status 1
    Want-Contains 'SYNTHETIC_BASE|REFUSE|'
    Want-Contains 'owned-ref=refs/gitbutler/wt'
    Want-Contains 'SYNTHETIC_BASE|RECOVERY|'
    Want-Contains 'docs/MAXIMS.md'
    Report-Scenario 'S2 owned ref, no carrying branch -> REFUSE'

    # S3 (Scenario 3): a normal carrying branch with unpushed commits proceeds.
    Begin-Scenario
    $root3 = New-Repo 's3'
    [IO.File]::WriteAllText((Join-Path $root3 'file.txt'), "more`n", $utf8)
    & git -C $root3 add file.txt | Out-Null
    & git -C $root3 commit -qm 'unpushed commit' | Out-Null
    Invoke-Checker -CheckerRoot $root3
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|OK|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S3 unpushed carrying branch -> OK'

    # S4 (Scenario 4 + 6): a detached real commit has no positive evidence.
    Begin-Scenario
    $root4 = New-DetachedRepo 's4'
    Invoke-Checker -CheckerRoot $root4
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|UNKNOWN|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S4 detached real commit -> UNKNOWN'

    # S5: a custom signals file narrows the owned namespaces.
    Begin-Scenario
    $root5 = New-DetachedRepo 's5'
    $signals5 = Join-Path $tmp 's5.txt'
    [IO.File]::WriteAllText($signals5, "# comment`n`nref-namespace|refs/custom/`n", $utf8)
    Add-OwnedRef $root5 'refs/gitbutler/wt'
    Invoke-Checker -CheckerRoot $root5 -ExtraArgs @('-SignalsFile', $signals5)
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|UNKNOWN|'
    Want-NotContains 'REFUSE'
    Add-OwnedRef $root5 'refs/custom/thing'
    Invoke-Checker -CheckerRoot $root5 -ExtraArgs @('-SignalsFile', $signals5)
    Want-Status 1
    Want-Contains 'owned-ref=refs/custom/thing'
    Report-Scenario 'S5 custom signals file narrows namespaces'

    # S6: PROMPTKIT_SYNTHETIC_REFS_EXTRA adds a project namespace.
    Begin-Scenario
    $root6 = New-DetachedRepo 's6'
    Add-OwnedRef $root6 'refs/custom/ns'
    Invoke-Checker -CheckerRoot $root6 -EnvOverrides @{ PROMPTKIT_SYNTHETIC_REFS_EXTRA = 'refs/custom/' }
    Want-Status 1
    Want-Contains 'owned-ref=refs/custom/ns'
    Report-Scenario 'S6 PROMPTKIT_SYNTHETIC_REFS_EXTRA extends namespaces'

    # S7: a malformed row and an unreadable file both fail closed.
    Begin-Scenario
    $root7 = New-Repo 's7'
    $bad7 = Join-Path $tmp 's7-bad.txt'
    [IO.File]::WriteAllText($bad7, "not-a-row`n", $utf8)
    Invoke-Checker -CheckerRoot $root7 -ExtraArgs @('-SignalsFile', $bad7)
    Want-Status 2
    Want-Contains 'SYNTHETIC_BASE|INCOMPLETE|RULES|not-a-row'
    Invoke-Checker -CheckerRoot $root7 -ExtraArgs @('-SignalsFile', (Join-Path $tmp 's7-missing.txt'))
    Want-Status 2
    Want-Contains 'SYNTHETIC_BASE|INCOMPLETE|RULES|.'
    Report-Scenario 'S7 malformed/unreadable signals -> INCOMPLETE RULES'

    # S8: no repository under root fails closed.
    Begin-Scenario
    $dir8 = Join-Path $tmp 's8'
    New-Item -ItemType Directory -Path $dir8 -Force | Out-Null
    Invoke-Checker -CheckerRoot $dir8
    Want-Status 2
    Want-Contains 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.'
    Report-Scenario 'S8 no repository -> INCOMPLETE GIT_METADATA'

    # S9: an unresolvable commit fails closed.
    Begin-Scenario
    $root9 = New-Repo 's9'
    Invoke-Checker -CheckerRoot $root9 -ExtraArgs @('-Commit', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
    Want-Status 2
    Want-Contains 'SYNTHETIC_BASE|INCOMPLETE|COMMIT|'
    Report-Scenario 'S9 unresolvable commit -> INCOMPLETE COMMIT'

    # S10: an owned ref also carried by a branch is ordinary.
    Begin-Scenario
    $root10 = New-Repo 's10'
    Add-OwnedRef $root10 'refs/gitbutler/wt'
    Invoke-Checker -CheckerRoot $root10
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|OK|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S10 owned ref carried by a branch -> OK'

    # S11: the scan never mutates the index or worktree.
    Begin-Scenario
    $root11 = New-DetachedRepo 's11'
    Add-OwnedRef $root11 'refs/gitbutler/wt'
    $before11 = Get-ReadOnlySnapshot $root11
    Invoke-Checker -CheckerRoot $root11
    $after11 = Get-ReadOnlySnapshot $root11
    Want-Status 1
    Want-Unchanged $before11 $after11
    Report-Scenario 'S11 scan leaves index/worktree unchanged'

    # S12: the changelog gate refuses a synthetic HEAD before deriving its range.
    Begin-Scenario
    $root12 = New-DetachedRepo 's12'
    Add-OwnedRef $root12 'refs/gitbutler/wt'
    Push-Location $root12
    try {
        $raw12 = @(& pwsh -NoProfile -File $changelogGate -Base HEAD -Head HEAD 2>&1)
        $script:STATUS = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $script:OUT = ((@($raw12 | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
    Want-Status 1
    Want-Contains 'CHANGELOG_GATE|SYNTHETIC-BASE|'
    Want-Contains 'SYNTHETIC_BASE|REFUSE|'
    Report-Scenario 'S12 changelog gate refuses synthetic HEAD'

    # S13: an ordinary commit behind an owned ref tip is not refused.
    Begin-Scenario
    $root13 = New-Repo 's13'
    & git -C $root13 checkout -q --detach HEAD | Out-Null
    [IO.File]::WriteAllText((Join-Path $root13 'a.txt'), "a`n", $utf8)
    & git -C $root13 add a.txt | Out-Null
    & git -C $root13 commit -qm 'ordinary A' | Out-Null
    [IO.File]::WriteAllText((Join-Path $root13 'b.txt'), "b`n", $utf8)
    & git -C $root13 add b.txt | Out-Null
    & git -C $root13 commit -qm 'owned B' | Out-Null
    Add-OwnedRef $root13 'refs/gitbutler/wt'
    $ancestor13 = (& git -C $root13 rev-parse HEAD~1).Trim()
    Invoke-Checker -CheckerRoot $root13 -ExtraArgs @('-Commit', $ancestor13)
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|UNKNOWN|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S13 ordinary ancestor of an owned ref tip -> UNKNOWN'

    # S14: the changelog gate checks both endpoints (synthetic base, normal head).
    Begin-Scenario
    $root14 = New-Repo 's14'
    & git -C $root14 checkout -q --detach HEAD | Out-Null
    [IO.File]::WriteAllText((Join-Path $root14 's.txt'), "s`n", $utf8)
    & git -C $root14 add s.txt | Out-Null
    & git -C $root14 commit -qm 'synthetic S' | Out-Null
    $synthetic14 = (& git -C $root14 rev-parse HEAD).Trim()
    Add-OwnedRef $root14 'refs/gitbutler/wt'
    & git -C $root14 checkout -q - | Out-Null
    Push-Location $root14
    try {
        $raw14 = @(& pwsh -NoProfile -File $changelogGate -Base $synthetic14 -Head HEAD 2>&1)
        $script:STATUS = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $script:OUT = ((@($raw14 | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
    Want-Status 1
    Want-Contains 'CHANGELOG_GATE|SYNTHETIC-BASE|'
    Report-Scenario 'S14 changelog gate refuses a synthetic base with a normal head'

    # S15: a preflight that cannot measure fails the gate closed.
    Begin-Scenario
    $root15 = New-Repo 's15'
    Push-Location $root15
    try {
        $raw15 = @(& pwsh -NoProfile -File $changelogGate -Base HEAD -Head 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' 2>&1)
        $script:STATUS = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $script:OUT = ((@($raw15 | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
    Want-Status 2
    Want-Contains 'CHANGELOG_GATE|INCOMPLETE|'
    Report-Scenario 'S15 changelog gate fails closed on an unmeasurable endpoint'

    # S16: a commit carried only by a tool-owned branch namespace is refused.
    Begin-Scenario
    $root16 = New-DetachedRepo 's16'
    & git -C $root16 update-ref refs/heads/gitbutler/workspace HEAD | Out-Null
    Invoke-Checker -CheckerRoot $root16
    Want-Status 1
    Want-Contains 'SYNTHETIC_BASE|REFUSE|'
    Want-Contains 'owned-branch=refs/heads/gitbutler/workspace'
    Want-Contains 'SYNTHETIC_BASE|RECOVERY|'
    Report-Scenario 'S16 tool-branch-only carrying -> REFUSE'

    # S17: a tool-owned branch namespace plus an ordinary branch is ordinary.
    Begin-Scenario
    $root17 = New-Repo 's17'
    [IO.File]::WriteAllText((Join-Path $root17 'work.txt'), "work`n", $utf8)
    & git -C $root17 add work.txt | Out-Null
    & git -C $root17 commit -qm 'work commit' | Out-Null
    & git -C $root17 update-ref refs/heads/gitbutler/workspace HEAD | Out-Null
    Invoke-Checker -CheckerRoot $root17
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|OK|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S17 tool branch + ordinary branch -> OK'

    # S18: a comments-only signals file yields empty namespaces and reports UNKNOWN.
    Begin-Scenario
    $root18 = New-DetachedRepo 's18'
    $signals18 = Join-Path $tmp 's18.txt'
    [IO.File]::WriteAllText($signals18, "# comments only, no rows`n", $utf8)
    Invoke-Checker -CheckerRoot $root18 -ExtraArgs @('-SignalsFile', $signals18)
    Want-Status 0
    Want-Contains 'SYNTHETIC_BASE|UNKNOWN|'
    Want-NotContains 'REFUSE'
    Report-Scenario 'S18 comments-only signals (empty namespaces) -> UNKNOWN'

    # S19: the changelog gate fails closed when the detector file is absent.
    Begin-Scenario
    $root19 = New-Repo 's19'
    $gateDir19 = Join-Path $tmp 's19-gate'
    New-Item -ItemType Directory -Path $gateDir19 -Force | Out-Null
    Copy-Item -LiteralPath $changelogGate -Destination (Join-Path $gateDir19 'check-changelog-entry.ps1')
    Push-Location $root19
    try {
        $raw19 = @(& pwsh -NoProfile -File (Join-Path $gateDir19 'check-changelog-entry.ps1') -Base HEAD -Head HEAD 2>&1)
        $script:STATUS = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $script:OUT = ((@($raw19 | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
    Want-Status 2
    Want-Contains 'CHANGELOG_GATE|INCOMPLETE|'
    Want-Contains 'preflight missing'
    Report-Scenario 'S19 changelog gate fails closed when preflight is missing'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Passed: $($script:PASS) | Failed: $($script:FAIL)"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
