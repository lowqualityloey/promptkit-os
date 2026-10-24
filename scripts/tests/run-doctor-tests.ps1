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
$script:SKIPPED = 0
$script:SCENARIO_OK = $true
$script:STATUS = 0
$script:OUT = ''

function Skip-Scenario { param([string]$Label) Write-Output "SKIP: $Label"; $script:SKIPPED++ }

function Test-ReadableFile {
    param([string]$Path)
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $stream.Dispose()
        return $true
    } catch { return $false }
}

function Test-AccessDenied {
    param([string]$Path, [switch]$Directory)
    if ($Directory) {
        try {
            $null = Get-Item -LiteralPath (Join-Path $Path '2026-01-01-intake-fixture.md') -Force -ErrorAction Stop
            return $false
        } catch { return $true }
    }
    return (-not (Test-ReadableFile $Path))
}

# Runs one doctor invocation while the target genuinely cannot be read, then
# always restores access. Returns $false when this platform/user cannot deny
# read, so callers report an explicit capability skip instead of a false pass.
function Invoke-DoctorWithoutRead {
    param([string]$Root, [string]$Path, [switch]$Directory)
    if ($IsWindows) {
        $user = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } elseif ($env:USERNAME) { $env:USERNAME } else { [Environment]::UserName }
        $right = if ($Directory) { '(X)' } else { '(RD)' }
        & icacls $Path /deny "${user}:$right" *> $null
        if ($LASTEXITCODE -ne 0) { return $false }
        try {
            if (-not (Test-AccessDenied $Path -Directory:$Directory)) { return $false }
            Invoke-Doctor -Root $Root
        } finally {
            & icacls $Path /remove:d $user *> $null
        }
        return $true
    }
    $orig = [IO.File]::GetUnixFileMode($Path)
    try {
        [IO.File]::SetUnixFileMode($Path, [IO.UnixFileMode]::None)
        if (-not (Test-AccessDenied $Path -Directory:$Directory)) { return $false }
        Invoke-Doctor -Root $Root
    } finally {
        [IO.File]::SetUnixFileMode($Path, $orig)
    }
    return $true
}

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
    param([string]$Root, [string[]]$ExtraArgs = @(), [hashtable]$EnvOverrides = @{}, [string]$Checker = '')
    if ([string]::IsNullOrEmpty($Checker)) {
        $Checker = Join-Path $Root '.promptkit/scripts/check-doctor.ps1'
        if (-not (Test-Path -LiteralPath $Checker -PathType Leaf)) { $Checker = $script:SrcChecker }
    }
    $arguments = @('-NoProfile', '-File', $Checker, '-KitRoot', $Root) + $ExtraArgs
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

$script:IntakeRecordRel = 'docs/specs/2026-01-01-intake-fixture.md'

function Write-IntakeComplete {
    param([string]$Dir)
    New-Item -ItemType Directory -Path (Join-Path $Dir 'docs/specs') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $Dir $script:IntakeRecordRel), "# Intake Record`n`n- **close_reason**: complete`n", $utf8)
    [IO.File]::AppendAllText((Join-Path $Dir 'PROMPTKIT.md'), "intake-status: complete`nintake-record: $($script:IntakeRecordRel)`n", $utf8)
}

function Set-IntakeLines {
    param([string]$Dir, [string]$Status = '', [string]$Record = '')
    $content = "profile: balanced`n"
    if (-not [string]::IsNullOrEmpty($Status)) { $content += "intake-status: $Status`n" }
    if (-not [string]::IsNullOrEmpty($Record)) { $content += "intake-record: $Record`n" }
    [IO.File]::WriteAllText((Join-Path $Dir 'PROMPTKIT.md'), $content, $utf8)
}

function New-HealthyKit {
    param([string]$Name, [string]$Profile = 'balanced')
    $dir = New-Kit $Name $Profile
    $sha = Get-ShortSha (Join-Path $dir '.promptkit')
    Write-Hosts $dir $sha
    Write-State $dir $sha
    Write-Task $dir 'TASK-2026-01-01-fixture' 'completed'
    Write-IntakeComplete $dir
    return $dir
}

$script:SymlinkCapable = $false
try {
    $probeRoot = Join-Path $tmp 'symlink-probe'
    New-Item -ItemType Directory -Path (Join-Path $probeRoot 'target') -Force | Out-Null
    $probeLink = Join-Path $probeRoot 'link'
    New-Item -ItemType SymbolicLink -Path $probeLink -Target (Join-Path $probeRoot 'target') -ErrorAction Stop | Out-Null
    $script:SymlinkCapable = $null -ne (Get-Item -LiteralPath $probeLink -Force -ErrorAction SilentlyContinue)
} catch {
    $script:SymlinkCapable = $false
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
    Want-Contains "docs-drift`tDIVERGED(STATE 3A vs Task Record: Task ID; Execution State)"

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

    # (d) two fields diverge -> one verdict naming every diverging field (#670)
    $stateN3d = @'
# Project State
- **Engine Version**: v1.2.3 @ __SHA__

## 3A. Execution-Control Projection (Optional)
- **Task ID**: `TASK-2026-01-01-n3`
- **Task Record**: `docs/tasks/TASK-2026-01-01-n3.md`
- **Execution State**: `in_progress`
- **Next Action**: `Finalize the fixture`
- **Owner / Current Actor**: `Implementor`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/STATE.md'), $stateN3d.Replace('__SHA__', $shaN3), $utf8)
    $recN3d = @'
# Task Record: n3
- **Task ID**: `TASK-2026-01-01-n3`
- **Execution State**: `in_progress`
- **Next Action**: `Ship the different action`
- **Owner / Actor**: `Reviewer`
'@
    [IO.File]::WriteAllText((Join-Path $rootN3 'docs/tasks/TASK-2026-01-01-n3.md'), $recN3d, $utf8)
    Invoke-Doctor -Root $rootN3
    Want-Status 1
    Want-Contains "docs-drift`tDIVERGED(STATE 3A vs Task Record: Next Action; Owner / Current Actor)"
    Want-NotContains "docs-drift`tDIVERGED(STATE 3A vs Task Record: Task ID)"
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

    # N5: the engine lives OUTSIDE the project root (a project that does not
    # contain the running kit). The kit-directory ignore row must degrade to
    # SKIP(engine outside project root); the phantom basename must never be OK.
    Begin-Scenario
    $rootN5 = Join-Path $tmp 'n5-project'
    $engineN5 = Join-Path $tmp 'n5-engine'
    New-Item -ItemType Directory -Path (Join-Path $rootN5 'docs/tasks') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $rootN5 '.opencode') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $rootN5 '.github') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $rootN5 'PROMPTKIT.md'), "profile: balanced`n", $utf8)
    foreach ($sub in @('scripts', 'templates', 'workflows')) {
        New-Item -ItemType Directory -Path (Join-Path $engineN5 $sub) -Force | Out-Null
    }
    Copy-Item -LiteralPath $script:SrcChecker -Destination (Join-Path $engineN5 'scripts/check-doctor.ps1')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'templates/agent-directive-template.md') -Destination (Join-Path $engineN5 'templates/agent-directive-template.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'templates/agent-directive-lite-template.md') -Destination (Join-Path $engineN5 'templates/agent-directive-lite-template.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'workflows/route.md') -Destination (Join-Path $engineN5 'workflows/route.md')
    Invoke-SetupGit $engineN5 @('init', '-q')
    Invoke-SetupGit $engineN5 @('config', 'user.name', 'Fixture')
    Invoke-SetupGit $engineN5 @('config', 'user.email', 'fixture@example.invalid')
    [IO.File]::WriteAllText((Join-Path $engineN5 'ENGINE.md'), "# engine`n", $utf8)
    Invoke-SetupGit $engineN5 @('add', '-A')
    Invoke-SetupGit $engineN5 @('commit', '-qm', 'engine base')
    Invoke-SetupGit $engineN5 @('branch', '-M', 'main')
    Invoke-SetupGit $engineN5 @('update-ref', 'refs/remotes/origin/main', 'HEAD')
    Invoke-SetupGit $rootN5 @('init', '-q')
    $shaN5 = Get-ShortSha $engineN5
    Write-Hosts $rootN5 $shaN5
    Write-State $rootN5 $shaN5
    Write-Task $rootN5 'TASK-2026-01-01-fixture' 'completed'
    Invoke-Doctor -Root $rootN5 -Checker (Join-Path $engineN5 'scripts/check-doctor.ps1')
    Want-Status 0
    Want-Contains "ignore:n5-engine`tSKIP(engine outside project root)`t-`t-"
    Want-NotContains "ignore:n5-engine`tOK"
    Want-NotContains "ignore:n5-engine`tINCOMPLETE"
    Report-Scenario 'N5 engine outside project root -> kit-dir ignore SKIP, no phantom OK'

    # S11: a directory-form cline install (.clinerules/promptkit.md) is OK.
    Begin-Scenario
    $root11 = New-HealthyKit 's11' 'balanced'
    $sha11 = Get-ShortSha (Join-Path $root11 '.promptkit')
    Remove-Item -LiteralPath (Join-Path $root11 '.clinerules') -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path (Join-Path $root11 '.clinerules') -Force | Out-Null
    $block11 = "<!-- PROMPTKIT_START -->`n## PromptKit OS`nEngine: v1.2.3 ($sha11) - stamped at install time`n<!-- PROMPTKIT_END -->`n"
    [IO.File]::WriteAllText((Join-Path $root11 '.clinerules/promptkit.md'), $block11, $utf8)
    Invoke-Doctor -Root $root11
    Want-Status 0
    Want-Contains "host:.clinerules/promptkit.md`tOK"
    Want-NotContains 'host file unreadable'
    Report-Scenario 'S11 cline directory-form install -> host OK'

    # S12: a cursor mdc-only install (.cursor/rules/promptkit.mdc) is OK.
    Begin-Scenario
    $root12 = New-HealthyKit 's12' 'balanced'
    $sha12 = Get-ShortSha (Join-Path $root12 '.promptkit')
    Remove-Item -LiteralPath (Join-Path $root12 '.cursorrules') -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path (Join-Path $root12 '.cursor/rules') -Force | Out-Null
    $block12 = "<!-- PROMPTKIT_START -->`n## PromptKit OS`nEngine: v1.2.3 ($sha12) - stamped at install time`n<!-- PROMPTKIT_END -->`n"
    [IO.File]::WriteAllText((Join-Path $root12 '.cursor/rules/promptkit.mdc'), $block12, $utf8)
    Invoke-Doctor -Root $root12
    Want-Status 0
    Want-Contains "host:.cursor/rules/promptkit.mdc`tOK"
    Report-Scenario 'S12 cursor mdc-only install -> host OK'

    # P1: a completed intake with a resolvable record path is OK.
    Begin-Scenario
    $rootP1 = New-HealthyKit 'p1' 'balanced'
    Invoke-Doctor -Root $rootP1
    Want-Status 0
    Want-Contains "provenance`tOK"
    Want-Contains 'intake-record resolves to'
    Report-Scenario 'P1 completed intake with resolvable record -> provenance OK'

    # P2: complete without intake-record is a non-fatal compatibility advisory (#641).
    Begin-Scenario
    $rootP2 = New-HealthyKit 'p2' 'balanced'
    Set-IntakeLines $rootP2 'complete'
    Invoke-Doctor -Root $rootP2
    Want-Status 0
    Want-Contains "provenance`tSKIP(no intake-record line)"
    Report-Scenario 'P2 complete without intake-record -> non-fatal advisory'

    # P3: a placeholder record path is an advisory, never a completed-intake OK.
    Begin-Scenario
    $rootP3 = New-HealthyKit 'p3' 'balanced'
    Set-IntakeLines $rootP3 'complete' '[docs/specs/YYYY-MM-DD-intake-<project>.md]'
    Invoke-Doctor -Root $rootP3
    Want-Status 0
    Want-Contains "provenance`tSKIP(placeholder intake-record)"
    Report-Scenario 'P3 placeholder intake-record -> non-fatal advisory'

    # P4: a record path that does not exist is MISSING, exit 1.
    Begin-Scenario
    $rootP4 = New-HealthyKit 'p4' 'balanced'
    Set-IntakeLines $rootP4 'complete' 'docs/specs/missing.md'
    Invoke-Doctor -Root $rootP4
    Want-Status 1
    Want-Contains "provenance`tMISSING"
    Want-Contains 'intake-record not found at docs/specs/missing.md'
    Report-Scenario 'P4 nonexistent intake-record -> MISSING, exit 1'

    # P5: parent-directory traversal is rejected as INCOMPLETE, exit 1.
    Begin-Scenario
    $rootP5 = New-HealthyKit 'p5' 'balanced'
    Set-IntakeLines $rootP5 'complete' '../../outside.md'
    Invoke-Doctor -Root $rootP5
    Want-Status 1
    Want-Contains "provenance`tINCOMPLETE"
    Want-Contains 'not a project-relative path'
    Report-Scenario 'P5 parent-traversal intake-record -> INCOMPLETE, exit 1'

    # P6: an absolute path is rejected as INCOMPLETE, exit 1.
    Begin-Scenario
    $rootP6 = New-HealthyKit 'p6' 'balanced'
    Set-IntakeLines $rootP6 'complete' '/etc/passwd'
    Invoke-Doctor -Root $rootP6
    Want-Status 1
    Want-Contains "provenance`tINCOMPLETE"
    Report-Scenario 'P6 absolute intake-record -> INCOMPLETE, exit 1'

    # P7: every non-complete status stays compatible and is never treated as complete.
    Begin-Scenario
    $rootP7 = New-HealthyKit 'p7' 'balanced'
    foreach ($st in @('unanswered', 'partial', 'legacy-partial', 'invented-value')) {
        Set-IntakeLines $rootP7 $st
        Invoke-Doctor -Root $rootP7
        Want-Status 0
        Want-Contains "provenance`tSKIP("
        Want-NotContains "provenance`tOK"
    }
    Set-IntakeLines $rootP7 ''
    Invoke-Doctor -Root $rootP7
    Want-Status 0
    Want-Contains "provenance`tSKIP(no intake-status line)"
    Report-Scenario 'P7 non-complete intake statuses -> SKIP, never OK'

    # P8: a Windows-separator record path resolves on both twins.
    Begin-Scenario
    $rootP8 = New-HealthyKit 'p8' 'balanced'
    New-Item -ItemType Directory -Path (Join-Path $rootP8 'docs/specs') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $rootP8 'docs/specs/2026-01-01-intake-fixture.md'), "# Intake Record`n", $utf8)
    Set-IntakeLines $rootP8 'complete' 'docs\specs\2026-01-01-intake-fixture.md'
    Invoke-Doctor -Root $rootP8
    Want-Status 0
    Want-Contains "provenance`tOK"
    Report-Scenario 'P8 Windows-separator intake-record -> OK on both twins'

    # P9: trailing spaces on intake-status are trimmed, not reclassified.
    Begin-Scenario
    $rootP9 = New-HealthyKit 'p9' 'balanced'
    Set-IntakeLines $rootP9 'complete   ' 'docs/specs/2026-01-01-intake-fixture.md'
    Invoke-Doctor -Root $rootP9
    Want-Status 0
    Want-Contains "provenance`tOK"
    Report-Scenario 'P9 trailing spaces on intake-status -> OK'

    # P10: trailing spaces on intake-record are trimmed.
    Begin-Scenario
    $rootP10 = New-HealthyKit 'p10' 'balanced'
    Set-IntakeLines $rootP10 'complete' 'docs/specs/2026-01-01-intake-fixture.md   '
    Invoke-Doctor -Root $rootP10
    Want-Status 0
    Want-Contains "provenance`tOK"
    Report-Scenario 'P10 trailing spaces on intake-record -> OK'

    # P11: trailing tabs on intake-record are trimmed.
    Begin-Scenario
    $rootP11 = New-HealthyKit 'p11' 'balanced'
    Set-IntakeLines $rootP11 'complete' ("docs/specs/2026-01-01-intake-fixture.md" + "`t`t")
    Invoke-Doctor -Root $rootP11
    Want-Status 0
    Want-Contains "provenance`tOK"
    Report-Scenario 'P11 trailing tabs on intake-record -> OK'

    # P12: a parent-directory symlink that escapes the root is rejected.
    if ($script:SymlinkCapable) {
        Begin-Scenario
        $rootP12 = New-HealthyKit 'p12' 'balanced'
        $outsideP12 = Join-Path $tmp 'p12-outside'
        New-Item -ItemType Directory -Path $outsideP12 -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $outsideP12 'rec.md'), "# outside record`n", $utf8)
        New-Item -ItemType SymbolicLink -Path (Join-Path $rootP12 'linked') -Target $outsideP12 -ErrorAction Stop | Out-Null
        Set-IntakeLines $rootP12 'complete' 'linked/rec.md'
        Invoke-Doctor -Root $rootP12
        Want-Status 1
        Want-Contains "provenance`tINCOMPLETE"
        Want-Contains 'outside the project root'
        Report-Scenario 'P12 parent-directory symlink escape -> INCOMPLETE, exit 1'
    } else {
        Skip-Scenario 'P12 parent-directory symlink escape (symlink creation unavailable on this platform)'
    }

    # P13: a final-file symlink that escapes the root is rejected.
    if ($script:SymlinkCapable) {
        Begin-Scenario
        $rootP13 = New-HealthyKit 'p13' 'balanced'
        $outsideP13 = Join-Path $tmp 'p13-outside'
        New-Item -ItemType Directory -Path $outsideP13 -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $outsideP13 'rec.md'), "# outside record`n", $utf8)
        New-Item -ItemType SymbolicLink -Path (Join-Path $rootP13 'docs/specs/outlink.md') -Target (Join-Path $outsideP13 'rec.md') -ErrorAction Stop | Out-Null
        Set-IntakeLines $rootP13 'complete' 'docs/specs/outlink.md'
        Invoke-Doctor -Root $rootP13
        Want-Status 1
        Want-Contains "provenance`tINCOMPLETE"
        Want-Contains 'outside the project root'
        Report-Scenario 'P13 final-file symlink escape -> INCOMPLETE, exit 1'
    } else {
        Skip-Scenario 'P13 final-file symlink escape (symlink creation unavailable on this platform)'
    }

    # P14: an in-root final-file symlink resolves and stays OK.
    if ($script:SymlinkCapable) {
        Begin-Scenario
        $rootP14 = New-HealthyKit 'p14' 'balanced'
        New-Item -ItemType SymbolicLink -Path (Join-Path $rootP14 'docs/specs/inlink.md') -Target (Join-Path $rootP14 'docs/specs/2026-01-01-intake-fixture.md') -ErrorAction Stop | Out-Null
        Set-IntakeLines $rootP14 'complete' 'docs/specs/inlink.md'
        Invoke-Doctor -Root $rootP14
        Want-Status 0
        Want-Contains "provenance`tOK"
        Report-Scenario 'P14 in-root final-file symlink -> OK'
    } else {
        Skip-Scenario 'P14 in-root final-file symlink (symlink creation unavailable on this platform)'
    }

    # P15: an in-root parent-directory symlink stays OK.
    if ($script:SymlinkCapable) {
        Begin-Scenario
        $rootP15 = New-HealthyKit 'p15' 'balanced'
        $aliasTarget = Join-Path $rootP15 'docs/alias-target'
        New-Item -ItemType Directory -Path $aliasTarget -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $aliasTarget 'rec.md'), "# intake`n", $utf8)
        New-Item -ItemType SymbolicLink -Path (Join-Path $rootP15 'docs/alias-parent') -Target $aliasTarget -ErrorAction Stop | Out-Null
        Set-IntakeLines $rootP15 'complete' 'docs/alias-parent/rec.md'
        Invoke-Doctor -Root $rootP15
        Want-Status 0
        Want-Contains "provenance`tOK"
        Report-Scenario 'P15 in-root parent-directory symlink -> OK'
    } else {
        Skip-Scenario 'P15 in-root parent-directory symlink (symlink creation unavailable on this platform)'
    }

    # P16: a dangling link to a missing in-root target is MISSING, exit 1.
    if ($script:SymlinkCapable) {
        Begin-Scenario
        $rootP16 = New-HealthyKit 'p16' 'balanced'
        New-Item -ItemType SymbolicLink -Path (Join-Path $rootP16 'docs/specs/dangling-in.md') -Target (Join-Path $rootP16 'docs/specs/ghost.md') -ErrorAction Stop | Out-Null
        Set-IntakeLines $rootP16 'complete' 'docs/specs/dangling-in.md'
        Invoke-Doctor -Root $rootP16
        Want-Status 1
        Want-Contains "provenance`tMISSING"
        Report-Scenario 'P16 dangling in-root link -> MISSING, exit 1'
    } else {
        Skip-Scenario 'P16 dangling in-root link (symlink creation unavailable on this platform)'
    }

    # P17: a link whose target directory does not exist fails closed, exit 1.
    if ($script:SymlinkCapable) {
        Begin-Scenario
        $rootP17 = New-HealthyKit 'p17' 'balanced'
        New-Item -ItemType SymbolicLink -Path (Join-Path $rootP17 'docs/specs/dangling-noparent.md') -Target (Join-Path $rootP17 'no-such-dir/ghost.md') -ErrorAction Stop | Out-Null
        Set-IntakeLines $rootP17 'complete' 'docs/specs/dangling-noparent.md'
        Invoke-Doctor -Root $rootP17
        Want-Status 1
        Want-Contains "provenance`tINCOMPLETE"
        Want-Contains 'could not be resolved'
        Report-Scenario 'P17 link with missing target directory -> INCOMPLETE, exit 1'
    } else {
        Skip-Scenario 'P17 link with missing target directory (symlink creation unavailable on this platform)'
    }

    # P18: the scaffold's own placeholder intake-status is an advisory skip.
    Begin-Scenario
    $rootP18 = New-HealthyKit 'p18' 'balanced'
    Set-IntakeLines $rootP18 '[unanswered | partial | legacy-partial | complete]' $script:IntakeRecordRel
    Invoke-Doctor -Root $rootP18
    Want-Status 0
    Want-Contains "provenance`tSKIP(placeholder intake-status)"
    Want-NotContains "provenance`tOK"
    Report-Scenario 'P18 scaffold placeholder intake-status -> SKIP, exit 0'

    # P19: an unreadable PROMPTKIT.md is the exit-2 prerequisite, never a partial report.
    Begin-Scenario
    $rootP19 = New-HealthyKit 'p19' 'balanced'
    if (Invoke-DoctorWithoutRead -Root $rootP19 -Path (Join-Path $rootP19 'PROMPTKIT.md')) {
        Want-Status 2
        Want-Contains "prereq`tINCOMPLETE"
        Want-NotContains "provenance`tOK"
        Report-Scenario 'P19 unreadable PROMPTKIT.md -> exit 2 prerequisite'
    } else {
        Skip-Scenario 'P19 unreadable PROMPTKIT.md (cannot deny read on this platform/user)'
    }

    # P20: an inaccessible record directory fails closed, never healthy.
    Begin-Scenario
    $rootP20 = New-HealthyKit 'p20' 'balanced'
    if (Invoke-DoctorWithoutRead -Root $rootP20 -Path (Join-Path $rootP20 'docs/specs') -Directory) {
        Want-Status 1
        Want-Contains "provenance`tMISSING"
        Want-NotContains "provenance`tOK"
        Report-Scenario 'P20 inaccessible docs/specs -> MISSING, exit 1'
    } else {
        Skip-Scenario 'P20 inaccessible docs/specs (cannot deny read on this platform/user)'
    }

    # P21: a component beyond the platform name limit cannot exist -> MISSING.
    Begin-Scenario
    $rootP21 = New-HealthyKit 'p21' 'balanced'
    Set-IntakeLines $rootP21 'complete' ('a' * 260)
    Invoke-Doctor -Root $rootP21
    Want-Status 1
    Want-Contains "provenance`tMISSING"
    Report-Scenario 'P21 overlong record component -> MISSING, exit 1'

    # P22: canonical single-backtick wrapping is unwrapped, matching the bash twin.
    Begin-Scenario
    $rootP22 = New-HealthyKit 'p22' 'balanced'
    $bt = [char]96
    Set-IntakeLines $rootP22 'complete' ($bt + $script:IntakeRecordRel + $bt)
    Invoke-Doctor -Root $rootP22
    Want-Status 0
    Want-Contains "provenance`tOK"
    Report-Scenario 'P22 single-backtick wrapping -> OK'

    # P23: non-canonical double-backtick wrapping resolves to nothing -> MISSING.
    Begin-Scenario
    $rootP23 = New-HealthyKit 'p23' 'balanced'
    Set-IntakeLines $rootP23 'complete' ($bt + $bt + $script:IntakeRecordRel + $bt + $bt)
    Invoke-Doctor -Root $rootP23
    Want-Status 1
    Want-Contains "provenance`tMISSING"
    Want-NotContains "provenance`tOK"
    Report-Scenario 'P23 double-backtick wrapping -> MISSING, exit 1'

    # P24: a trailing separator is normalized instead of changing the classification.
    Begin-Scenario
    $rootP24 = New-HealthyKit 'p24' 'balanced'
    Set-IntakeLines $rootP24 'complete' ($script:IntakeRecordRel + '/')
    Invoke-Doctor -Root $rootP24
    Want-Status 0
    Want-Contains "provenance`tOK"
    Report-Scenario 'P24 trailing-separator record -> OK'

    # P25: an existing but unreadable record is not path-healthy.
    Begin-Scenario
    $rootP25 = New-HealthyKit 'p25' 'balanced'
    if (Invoke-DoctorWithoutRead -Root $rootP25 -Path (Join-Path $rootP25 $script:IntakeRecordRel)) {
        Want-Status 1
        Want-Contains "provenance`tMISSING"
        Want-Contains 'is not readable at'
        Want-NotContains "provenance`tOK"
        Report-Scenario 'P25 unreadable record file -> MISSING, exit 1'
    } else {
        Skip-Scenario 'P25 unreadable record file (cannot deny read on this platform/user)'
    }
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Passed: $($script:PASS) | Failed: $($script:FAIL) | Skipped: $($script:SKIPPED)"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
