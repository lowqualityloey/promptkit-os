# Regression harness for the read-only pk:doctor detector (#547).
# Run from repository root: /usr/bin/pwsh -NoProfile -File scripts/tests/run-doctor-tests.ps1
#
# Every fixture is a real nested install: the project root ($root) holds
# PROMPTKIT.md, docs/, host files and the project git repo, while the engine
# lives at $root/.promptkit (a copy of the real checker plus the templates and
# workflows it references). Git-init the engine for version fixtures and the
# project for ignore fixtures. S10 asserts the default (no -Fix) run leaves the
# tree byte-identical.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd('\', '/')
$script:SrcChecker = Join-Path $repoRoot 'scripts/check-doctor.ps1'
$pwshExe = '/usr/bin/pwsh'
if (-not (Test-Path -LiteralPath $pwshExe)) { $pwshExe = 'pwsh' }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('pk-doctor-' + [guid]::NewGuid().ToString('N'))
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
function Want-AllOk {
    $bad = @($script:OUT -split "`n" | Where-Object { @($_.Split("`t")).Count -ge 2 -and @($_.Split("`t"))[1] -ne 'OK' })
    Assert-Scenario ($bad.Count -eq 0) "expected every row OK; offending rows: $($bad -join '; ')"
}

function Invoke-Doctor {
    param([string]$Root, [string[]]$ExtraArgs = @(), [hashtable]$EnvOverrides = @{})
    $checkerLocal = Join-Path $Root '.promptkit/scripts/check-doctor.ps1'
    if (-not (Test-Path -LiteralPath $checkerLocal -PathType Leaf)) { $checkerLocal = $script:SrcChecker }
    $arguments = @('-NoProfile', '-File', $checkerLocal, '-KitRoot', $Root) + $ExtraArgs
    $saved = @{}
    foreach ($key in $EnvOverrides.Keys) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, [string]$EnvOverrides[$key], 'Process')
    }
    try {
        $raw = @(& $pwshExe @arguments 2>$null)
        $script:STATUS = $LASTEXITCODE
    } finally {
        foreach ($key in $EnvOverrides.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process') }
    }
    $script:OUT = ((@($raw | ForEach-Object { $_.ToString() }) -join "`n")).Replace("`r", '')
}

function Get-TreeSnapshot {
    param([string]$Root)
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } | Sort-Object FullName)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($f in $files) {
        $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA1).Hash
        [void]$sb.Append($f.FullName.Substring($Root.Length)).Append('|').Append($hash).Append("`n")
    }
    return $sb.ToString()
}

$hostRels = @(
    'AGENTS.md', 'CLAUDE.md', '.opencode/rules.md', '.cursorrules', 'GEMINI.md',
    '.windsurfrules', '.github/copilot-instructions.md', '.clinerules', '.traerules', 'CONVENTIONS.md'
)

function Invoke-SetupGit {
    param([string]$Dir, [string[]]$GitArgs)
    & git -C $Dir @GitArgs 2>$null | Out-Null
}

# Lay down the engine copy at $Dir/.promptkit: the real checker plus the
# templates and the route workflow its rendered block references.
function Install-Engine {
    param([string]$Dir)
    $engine = Join-Path $Dir '.promptkit'
    foreach ($sub in @('scripts', 'templates', 'workflows')) {
        New-Item -ItemType Directory -Path (Join-Path $engine $sub) -Force | Out-Null
    }
    Copy-Item -LiteralPath $script:SrcChecker -Destination (Join-Path $engine 'scripts/check-doctor.ps1')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'templates/agent-directive-template.md') -Destination (Join-Path $engine 'templates/agent-directive-template.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'templates/agent-directive-lite-template.md') -Destination (Join-Path $engine 'templates/agent-directive-lite-template.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'workflows/route.md') -Destination (Join-Path $engine 'workflows/route.md')
}

function Initialize-EngineRepo {
    param([string]$Dir)
    $engine = Join-Path $Dir '.promptkit'
    Invoke-SetupGit $engine @('init', '-q')
    Invoke-SetupGit $engine @('config', 'user.name', 'Fixture')
    Invoke-SetupGit $engine @('config', 'user.email', 'fixture@example.invalid')
    [IO.File]::WriteAllText((Join-Path $engine 'ENGINE.md'), "# engine`n", $utf8)
    Invoke-SetupGit $engine @('add', '-A')
    Invoke-SetupGit $engine @('commit', '-qm', 'engine base')
    Invoke-SetupGit $engine @('branch', '-M', 'main')
    Invoke-SetupGit $engine @('update-ref', 'refs/remotes/origin/main', 'HEAD')
}

function New-Kit {
    param([string]$Name, [string]$Profile = 'balanced')
    $dir = Join-Path $tmp $Name
    New-Item -ItemType Directory -Path (Join-Path $dir 'docs/tasks') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir '.opencode') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir '.github') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'PROMPTKIT.md'), "profile: $Profile`n", $utf8)
    Install-Engine $dir
    Initialize-EngineRepo $dir
    Invoke-SetupGit $dir @('init', '-q')
    return $dir
}

function Get-ShortSha {
    param([string]$Dir)
    return ((& git -C $Dir rev-parse --short HEAD | Out-String)).Trim()
}

function Write-Hosts {
    param([string]$Dir, [string]$Sha)
    foreach ($rel in $hostRels) {
        $full = Join-Path $Dir $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
        $content = "<!-- PROMPTKIT_START -->`n## PromptKit OS`nEngine: v1.2.3 ($Sha) - stamped at install time`nLite - 6 workflows`n<!-- PROMPTKIT_END -->`n"
        [IO.File]::WriteAllText($full, $content, $utf8)
    }
}

function Write-State {
    param([string]$Dir, [string]$Sha, [string]$ExecState = 'completed', [string]$Id = 'TASK-2026-01-01-fixture')
    $template = @'
# Project State & Living Execution Tracker

## 1. Executive Summary & Current Position
- **Engine Version**: v1.2.3 @ __SHA__

---

## 3A. Execution-Control Projection (Optional)

- **Task ID**: `__ID__`
- **Task Record**: `docs/tasks/__ID__.md`
- **Execution State**: `__EXEC__`
- **Owner / Current Actor**: `Implementor`
- **Ceremony Level**: `Level 2 (Controlled)`

---

## 4. Locked Technical Invariants (Do Not Undo)
- none
'@
    $content = $template.Replace('__SHA__', $Sha).Replace('__ID__', $Id).Replace('__EXEC__', $ExecState)
    [IO.File]::WriteAllText((Join-Path $Dir 'docs/STATE.md'), $content, $utf8)
}

function Write-Task {
    param([string]$Dir, [string]$Id, [string]$ExecState = 'completed')
    $template = @'
# Task Record: fixture

- **Task ID**: `__ID__`
- **Owner / Actor**: `Implementor`

## 5. State and Active Ownership
- **Execution State**: `__EXEC__`
'@
    $content = $template.Replace('__ID__', $Id).Replace('__EXEC__', $ExecState)
    [IO.File]::WriteAllText((Join-Path $Dir "docs/tasks/$Id.md"), $content, $utf8)
}

function New-HealthyKit {
    param([string]$Name, [string]$Profile = 'balanced')
    $dir = New-Kit $Name $Profile
    $sha = Get-ShortSha (Join-Path $dir '.promptkit')
    Write-Hosts $dir $sha
    Write-State $dir $sha
    Write-Task $dir 'TASK-2026-01-01-fixture' 'completed'
    return $dir
}

try {
    # S1 (Scenario 1): a healthy Balanced install reports every row OK, exit 0.
    Begin-Scenario
    $root1 = New-HealthyKit 's1' 'balanced'
    Invoke-Doctor -Root $root1
    Want-Status 0
    Want-AllOk
    Report-Scenario 'S1 healthy Balanced install -> all OK, exit 0'

    # S2 (Scenario 2): stale engine, ignored managed path, diverged projection.
    Begin-Scenario
    $root2 = New-HealthyKit 's2' 'balanced'
    $engine2 = Join-Path $root2 '.promptkit'
    Invoke-SetupGit $engine2 @('checkout', '-q', '-b', 'stale')
    for ($i = 1; $i -le 8; $i++) {
        [IO.File]::AppendAllText((Join-Path $engine2 'stale.txt'), "stale $i`n", $utf8)
        Invoke-SetupGit $engine2 @('add', 'stale.txt')
        Invoke-SetupGit $engine2 @('commit', '-qm', "stale $i")
    }
    $tip2 = ((& git -C $engine2 rev-parse HEAD | Out-String)).Trim()
    Invoke-SetupGit $engine2 @('checkout', '-q', 'main')
    Invoke-SetupGit $engine2 @('update-ref', 'refs/remotes/origin/main', $tip2)
    [IO.File]::WriteAllText((Join-Path $root2 '.gitignore'), "docs/`n", $utf8)
    Write-State $root2 (Get-ShortSha $engine2) 'in_progress'
    Invoke-Doctor -Root $root2
    Want-Status 1
    Want-Contains "version`tSTALE(+8)"
    Want-Contains 'engine v1.2.3 is 8 commit(s) behind'
    Want-Contains "ignore:docs`tIGNORED("
    Want-Contains '.gitignore:1:docs/'
    Want-Contains "docs-drift`tDIVERGED("
    Want-Contains 'Execution State'
    Report-Scenario 'S2 stale engine + ignored path + diverged projection -> exit 1'

    # S3 (Scenario 3): an intentional ignore alone does not fail health.
    Begin-Scenario
    $root3 = New-HealthyKit 's3' 'balanced'
    [IO.File]::WriteAllText((Join-Path $root3 '.gitignore'), "docs/`n", $utf8)
    Invoke-Doctor -Root $root3
    Want-Status 0
    Want-Contains "ignore:docs`tIGNORED(.gitignore:1:docs/)"
    Want-NotContains 'STALE'
    Want-NotContains "`tMISSING"
    Want-NotContains 'DIVERGED'
    Report-Scenario 'S3 intentional ignore alone -> IGNORED, exit 0'

    # S4 (Scenario 4): no handoff.md and no canonical Task Record -> SKIP.
    Begin-Scenario
    $root4 = New-Kit 's4' 'balanced'
    $sha4 = Get-ShortSha (Join-Path $root4 '.promptkit')
    Write-Hosts $root4 $sha4
    $state4 = @'
# Project State
- **Engine Version**: v1.2.3 @ __SHA__

## 3A. Execution-Control Projection (Optional)
- **Task ID**: `TASK-<task-id>`
- **Task Record**: `docs/tasks/<task-id>.md`
- **Execution State**: `[planned]`
'@
    [IO.File]::WriteAllText((Join-Path $root4 'docs/STATE.md'), $state4.Replace('__SHA__', $sha4), $utf8)
    Invoke-Doctor -Root $root4
    Want-Status 0
    Want-Contains "docs-drift`tSKIP(no task record)"
    Want-NotContains 'DIVERGED'
    Report-Scenario 'S4 no handoff and no Task Record -> docs-drift SKIP'

    # S5 (Scenario 5): a Lite install is not flagged for Balanced-only workflows.
    Begin-Scenario
    $root5 = New-HealthyKit 's5' 'lite'
    Invoke-Doctor -Root $root5
    Want-Status 0
    Want-AllOk
    Want-NotContains "`tMISSING"
    Report-Scenario 'S5 Lite install -> no MISSING for Balanced-only'

    # S6 (Scenario 6): an unexpected git exit status is fail-closed INCOMPLETE.
    Begin-Scenario
    $root6 = New-HealthyKit 's6' 'balanced'
    $fakebin6 = Join-Path $tmp 's6-bin'
    New-Item -ItemType Directory -Path $fakebin6 -Force | Out-Null
    # Windows PATH resolution ignores extensionless scripts, so ship a .cmd/.bat
    # shim alongside the POSIX shell shim; each returns exit code 3.
    [IO.File]::WriteAllText((Join-Path $fakebin6 'git'), "#!/bin/sh`nexit 3`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $fakebin6 'git.cmd'), "@echo off`nexit /b 3`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $fakebin6 'git.bat'), "@echo off`nexit /b 3`n", $utf8)
    if (Get-Command chmod -ErrorAction SilentlyContinue) {
        & chmod +x (Join-Path $fakebin6 'git') 2>$null | Out-Null
    }
    $overridePath = $fakebin6 + [IO.Path]::PathSeparator + $env:PATH
    Invoke-Doctor -Root $root6 -EnvOverrides @{ PATH = $overridePath }
    Want-Status 1
    Want-Contains "ignore:.promptkit`tINCOMPLETE"
    Want-Contains 'unexpected status 3'
    Want-NotContains "ignore:.promptkit`tOK"
    Report-Scenario 'S6 unexpected git status -> INCOMPLETE, exit 1'

    # S7 (Scenario 7): a host file present but missing the block is MISSING.
    Begin-Scenario
    $root7 = New-Kit 's7' 'balanced'
    $sha7 = Get-ShortSha (Join-Path $root7 '.promptkit')
    Write-Hosts $root7 $sha7
    [IO.File]::WriteAllText((Join-Path $root7 'AGENTS.md'), "# Agent notes without the managed block`n", $utf8)
    Invoke-Doctor -Root $root7
    Want-Status 1
    Want-Contains "host:AGENTS.md`tMISSING"
    Report-Scenario 'S7 host file missing the block -> MISSING'

    # S8 (Scenario 8): absent PROMPTKIT.md is the exit-2 could-not-run prerequisite.
    Begin-Scenario
    $root8 = Join-Path $tmp 's8'
    New-Item -ItemType Directory -Path $root8 -Force | Out-Null
    Invoke-Doctor -Root $root8
    Want-Status 2
    Want-Contains "prereq`tINCOMPLETE"
    Want-Contains 'no PROMPTKIT.md at KIT_ROOT'
    Report-Scenario 'S8 absent PROMPTKIT.md -> exit 2'

    # S9 (-Fix): re-emits the missing block and leaves a healthy run.
    Begin-Scenario
    $root9 = New-Kit 's9' 'balanced'
    $sha9 = Get-ShortSha (Join-Path $root9 '.promptkit')
    Write-Hosts $root9 $sha9
    [IO.File]::WriteAllText((Join-Path $root9 'AGENTS.md'), "# Agent notes without the managed block`n", $utf8)
    Invoke-Doctor -Root $root9
    Want-Status 1
    Want-Contains "host:AGENTS.md`tMISSING"
    Invoke-Doctor -Root $root9 -ExtraArgs @('-Fix')
    Want-Status 0
    Want-Contains 're-emitted by --fix'
    Want-Contains "host:AGENTS.md`tOK"
    $fixed9 = Get-Content -LiteralPath (Join-Path $root9 'AGENTS.md') -Raw
    Assert-Scenario ([bool]([regex]::IsMatch($fixed9, '(?m)^[ \t]*<!-- PROMPTKIT_START -->[ \t\r]*$'))) 'AGENTS.md does not contain the managed block after -Fix'
    Report-Scenario 'S9 -Fix re-emits the missing block'

    # S10: without -Fix the doctor is read-only; the tree is byte-identical.
    Begin-Scenario
    $root10 = New-HealthyKit 's10' 'balanced'
    $before10 = Get-TreeSnapshot $root10
    Invoke-Doctor -Root $root10
    $after10 = Get-TreeSnapshot $root10
    Want-Status 0
    Assert-Scenario ($before10 -eq $after10) 'tree changed across a default (no -Fix) run'
    Report-Scenario 'S10 default run is read-only (tree unchanged)'

    # N1: a nested engine one commit behind its OWN origin/main is STALE(+1), and
    # a project ignore rule on the engine directory is reported against .promptkit.
    Begin-Scenario
    $rootN1 = New-HealthyKit 'n1' 'balanced'
    $engineN1 = Join-Path $rootN1 '.promptkit'
    [IO.File]::WriteAllText((Join-Path $engineN1 'extra.txt'), "engine +1`n", $utf8)
    Invoke-SetupGit $engineN1 @('add', 'extra.txt')
    Invoke-SetupGit $engineN1 @('commit', '-qm', 'engine +1')
    $tipN1 = ((& git -C $engineN1 rev-parse HEAD | Out-String)).Trim()
    Invoke-SetupGit $engineN1 @('reset', '-q', '--hard', 'HEAD~1')
    Invoke-SetupGit $engineN1 @('update-ref', 'refs/remotes/origin/main', $tipN1)
    Write-Hosts $rootN1 (Get-ShortSha $engineN1)
    [IO.File]::WriteAllText((Join-Path $rootN1 '.gitignore'), ".promptkit/`n", $utf8)
    Invoke-Doctor -Root $rootN1
    Want-Status 1
    Want-Contains "version`tSTALE(+1)"
    Want-Contains 'engine v1.2.3 is 1 commit(s) behind'
    Want-Contains "ignore:.promptkit`tIGNORED("
    Want-Contains '.gitignore:1:.promptkit/'
    Want-NotContains "ignore:.`t"
    Report-Scenario 'N1 nested engine STALE(+1) against its own origin/main + engine ignore'

    # N2: -Fix renders <engine_relpath>/workflows/... and that path exists.
    Begin-Scenario
    $rootN2 = New-Kit 'n2' 'balanced'
    [IO.File]::WriteAllText((Join-Path $rootN2 'AGENTS.md'), "# Agent notes without the managed block`n", $utf8)
    Invoke-Doctor -Root $rootN2 -ExtraArgs @('-Fix')
    Want-Status 0
    Want-Contains 're-emitted by --fix'
    Assert-Scenario (Test-Path -LiteralPath (Join-Path $rootN2 '.promptkit/workflows/route.md') -PathType Leaf) 'engine route.md missing before -Fix check'
    $fixedN2 = Get-Content -LiteralPath (Join-Path $rootN2 'AGENTS.md') -Raw
    Assert-Scenario ($fixedN2.Contains('.promptkit/workflows/route.md')) 'rendered block does not reference .promptkit/workflows/route.md'
    Assert-Scenario (-not $fixedN2.Contains('KIT_DIR_REL')) 'rendered block left an unsubstituted $KIT_DIR_REL token'
    Report-Scenario 'N2 -Fix renders <engine_relpath>/workflows/... and path exists'

    # N3: docs-drift compares every shared 3A/Task-Record field and never bare-OKs
    # without a concrete comparison.
    Begin-Scenario
    $rootN3 = New-Kit 'n3' 'balanced'
    $shaN3 = Get-ShortSha (Join-Path $rootN3 '.promptkit')
    Write-Hosts $rootN3 $shaN3
    $stateN3a = @'
# Project State
- **Engine Version**: v1.2.3 @ __SHA__

## 3A. Execution-Control Projection (Optional)
- **Task ID**: `TASK-<task-id>`
- **Task Record**: `docs/tasks/TASK-2026-01-01-n3.md`
- **Execution State**: `[planned]`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/STATE.md'), $stateN3a.Replace('__SHA__', $shaN3), $utf8)
    $recN3 = @'
# Task Record: n3
- **Task ID**: `TASK-2026-01-01-n3`
- **Execution State**: `in_progress`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/tasks/TASK-2026-01-01-n3.md'), $recN3, $utf8)
    Invoke-Doctor -Root $rootN3
    Want-Status 1
    Want-Contains "docs-drift`tDIVERGED(STATE 3A vs Task Record: Task ID)"

    $stateN3b = @'
# Project State
- **Engine Version**: v1.2.3 @ __SHA__

## 3A. Execution-Control Projection (Optional)
- **Task ID**: `TASK-2026-01-01-n3`
- **Task Record**: `docs/tasks/TASK-2026-01-01-n3.md`
- **Execution State**: `in_progress`
- **Next Action**: `Finalize the fixture`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/STATE.md'), $stateN3b.Replace('__SHA__', $shaN3), $utf8)
    $recN3b = @'
# Task Record: n3
- **Task ID**: `TASK-2026-01-01-n3`
- **Execution State**: `in_progress`
- **Next Action**: `Ship the different action`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/tasks/TASK-2026-01-01-n3.md'), $recN3b, $utf8)
    Invoke-Doctor -Root $rootN3
    Want-Status 1
    Want-Contains "docs-drift`tDIVERGED(STATE 3A vs Task Record: Next Action)"

    $stateN3c = @'
# Project State
- **Engine Version**: v1.2.3 @ __SHA__

## 3A. Execution-Control Projection (Optional)
- **Task ID**: `TASK-<task-id>`
- **Task Record**: `docs/tasks/TASK-2026-01-01-n3-ph.md`
- **Execution State**: `[planned]`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/STATE.md'), $stateN3c.Replace('__SHA__', $shaN3), $utf8)
    $recN3c = @'
# Task Record: n3-ph
- **Task ID**: `TASK-<task-id>`
- **Execution State**: `[planned]`
- **Next Action**: `[action]`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/tasks/TASK-2026-01-01-n3-ph.md'), $recN3c, $utf8)
    Invoke-Doctor -Root $rootN3
    Want-Status 0
    Want-Contains "docs-drift`tSKIP(no comparable field)"
    Want-NotContains "docs-drift`tOK"
    Want-NotContains 'DIVERGED'
    Report-Scenario 'N3 docs-drift compares shared fields, DIVERGED/SKIP, never bare OK'

    # N4: a deleted universal AGENTS.md is MISSING (re-run the installer), exit 1.
    Begin-Scenario
    $rootN4 = New-HealthyKit 'n4' 'balanced'
    Remove-Item -LiteralPath (Join-Path $rootN4 'AGENTS.md') -Force
    Invoke-Doctor -Root $rootN4
    Want-Status 1
    Want-Contains "host:AGENTS.md`tMISSING"
    Want-Contains 'universal host file absent'
    Report-Scenario 'N4 deleted AGENTS.md -> MISSING, exit 1'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Passed: $($script:PASS) | Failed: $($script:FAIL)"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
