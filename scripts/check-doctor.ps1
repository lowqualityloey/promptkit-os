# Read-only pk:doctor health detector for a PromptKit OS install (#547).
#
# Usage: scripts/check-doctor.ps1 [-KitRoot <path>] [-Fix]
#
# Reports host directive blocks, engine version/drift, managed-path ignore
# state, and docs state-store drift. Read-only by default: it never stages,
# commits, edits, or runs an upgrade. The only permitted write is -Fix, which
# re-emits a MISSING managed directive block into an installed host file (the
# profile-appropriate template with $ENGINE_VERSION/$ENGINE_SHA substituted
# exactly as init.ps1 does). No other write ever happens.
#
# Machine-readable output: exactly one TAB-separated row per check, stable field
# order `<scope>\t<STATUS>\t<detail>\t<remediation>`. STATUS is the base token,
# optionally qualified in parentheses: OK | STALE(+n) | MISSING |
# IGNORED(<rule source>) | DIVERGED(<pair>) | SKIP(<reason>) | INCOMPLETE.
#
# Exit codes (contract):
#   0  every row is OK, IGNORED(...), or SKIP(...)
#   1  at least one STALE(...), MISSING, DIVERGED(...), or INCOMPLETE
#   2  doctor could not run at all (no PROMPTKIT.md at KIT_ROOT, or -Fix
#      requested while no directive template exists)
# IGNORED never contributes to exit 1. INCOMPLETE is fail-closed and does
# (exit 1, never 0 and never 2). Precedence: 2 only when no check could run.

[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$KitRoot = '.',
    [switch]$Fix
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:fail = $false
$script:gitStatus = 0

function ConvertTo-Sanitized {
    param([string]$Value)
    return ($Value -replace '[\r\n\t]', ' ')
}

# Rows are emitted as they are computed. `fail` tracks only statuses that make
# the overall verdict unhealthy; IGNORED and SKIP never set it.
function Emit {
    param([string]$Scope, [string]$Status, [string]$Detail, [string]$Remediation)
    Write-Output ("$Scope`t$Status`t$(ConvertTo-Sanitized $Detail)`t$(ConvertTo-Sanitized $Remediation)")
    $base = $Status
    $idx = $Status.IndexOf('(')
    if ($idx -ge 0) { $base = $Status.Substring(0, $idx) }
    if ($base -in @('STALE', 'MISSING', 'DIVERGED', 'INCOMPLETE')) { $script:fail = $true }
}

# Known host -> directive file map, verbatim from init.ps1 host_file().
$hostIds = @('agents', 'claude', 'opencode', 'cursor', 'gemini', 'windsurf', 'copilot', 'cline', 'trae', 'aider')
function Get-HostRelpath {
    param([string]$Id)
    switch ($Id) {
        'agents' { return 'AGENTS.md' }
        'claude' { return 'CLAUDE.md' }
        'opencode' { return '.opencode/rules.md' }
        'cursor' { return '.cursorrules' }
        'gemini' { return 'GEMINI.md' }
        'windsurf' { return '.windsurfrules' }
        'copilot' { return '.github/copilot-instructions.md' }
        'cline' { return '.clinerules' }
        'trae' { return '.traerules' }
        'aider' { return 'CONVENTIONS.md' }
        default { return '' }
    }
}

function Test-Block {
    param([string]$Path)
    try { $content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop } catch { return $false }
    if ($null -eq $content) { return $false }
    return [bool]([regex]::IsMatch($content, '(?m)^[ \t]*<!-- PROMPTKIT_START -->[ \t\r]*$'))
}

function Get-SedReplacementEscape {
    param([string]$Value)
    return ($Value -replace '([\\&|])', '\$1' -replace "`n", ' ')
}

if (-not (Test-Path -LiteralPath $KitRoot)) {
    Emit 'prereq' 'INCOMPLETE' 'no PROMPTKIT.md at KIT_ROOT' 'Run pk:doctor from the project root that contains PROMPTKIT.md'
    exit 2
}
try {
    $rootItem = Get-Item -LiteralPath $KitRoot -Force -ErrorAction Stop
} catch {
    Emit 'prereq' 'INCOMPLETE' 'no PROMPTKIT.md at KIT_ROOT' 'Run pk:doctor from the project root that contains PROMPTKIT.md'
    exit 2
}
if (-not $rootItem.PSIsContainer -or ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Emit 'prereq' 'INCOMPLETE' 'no PROMPTKIT.md at KIT_ROOT' 'Run pk:doctor from the project root that contains PROMPTKIT.md'
    exit 2
}
$kitRoot = $rootItem.FullName

# Project root vs engine directory (Issue #547 FIX 1). KIT_ROOT is the project
# root: PROMPTKIT.md, the host files, and docs/ live there. The installed engine
# is the directory containing the running script's parent (e.g. <project>/.promptkit).
# Version/ignore-rich git operations and path rendering must target the right one.
$projectRoot = $kitRoot
$scriptDir = $PSScriptRoot
$engineDir = Split-Path -Parent $scriptDir
$engineRelpath = '.'
$engineOutsideProject = $false
if ($engineDir -eq $projectRoot) {
    $engineRelpath = '.'
} elseif ($engineDir.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar) -or $engineDir.StartsWith($projectRoot + [IO.Path]::AltDirectorySeparatorChar)) {
    $engineRelpath = $engineDir.Substring($projectRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
} else {
    # Engine is neither the project root nor under it: engineRelpath is only a
    # display fallback. The basename does not exist under the project, so the
    # ignore-state check must not run git check-ignore on this phantom path.
    $engineRelpath = Split-Path -Leaf $engineDir
    $engineOutsideProject = $true
}
$profilePath = Join-Path $kitRoot 'PROMPTKIT.md'

# The kit root must carry PROMPTKIT.md; without it no check has a scope to run
# against, so this is the exit-2 "could not run at all" prerequisite.
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    Emit 'prereq' 'INCOMPLETE' 'no PROMPTKIT.md at KIT_ROOT' 'Run pk:doctor from the project root that contains PROMPTKIT.md'
    exit 2
}

# Declared profile: mirror the installer's exact parse.
$profile = 'balanced'
try {
    $profileLines = @(Get-Content -LiteralPath $profilePath | Where-Object { $_ -match '^profile:' })
} catch {
    $profileLines = @()
}
if ($profileLines.Count -gt 0) {
    $parts = [regex]::Split([string]$profileLines[-1], '\s+') | Where-Object { $_ -ne '' }
    if ($parts.Count -ge 2) { $profile = [string]$parts[1] }
}

# Engine stamp: first installed host directive carrying an `Engine: <ver> (<sha>)`
# line. This is the reporting authority for the version row.
$stampVer = ''
$stampSha = ''
foreach ($id in $hostIds) {
    $rel = Get-HostRelpath $id
    if ([string]::IsNullOrEmpty($rel)) { continue }
    $path = Join-Path $kitRoot $rel
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    try { $lines = Get-Content -LiteralPath $path } catch { continue }
    foreach ($line in $lines) {
        if ($line -match '^\s*Engine:\s*(\S+)\s*\(([^)]*)\)') {
            $stampVer = $Matches[1]
            $stampSha = $Matches[2]
            break
        }
    }
    if (-not [string]::IsNullOrEmpty($stampVer)) { break }
}

# STATE.md engine stamp (fallback identity source for -Fix; never authoritative).
$stateVer = ''
$stateSha = ''
$statePath = Join-Path $kitRoot 'docs/STATE.md'
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    try { $stateLines = Get-Content -LiteralPath $statePath } catch { $stateLines = @() }
    foreach ($line in $stateLines) {
        if ($line -match '^- \*\*Engine Version\*\*:\s*(.+?)\s*@\s*(\S+)' -and $line -notmatch '\[') {
            $stateVer = $Matches[1]
            $stateSha = $Matches[2]
            break
        }
    }
}

# -Fix template resolution, mirroring init.ps1's lite-fallback behavior.
$template = ''
if ($Fix) {
    if ($profile -eq 'lite') {
        $template = Join-Path $engineDir 'templates/agent-directive-lite-template.md'
        if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
            $template = Join-Path $engineDir 'templates/agent-directive-template.md'
        }
    } else {
        $template = Join-Path $engineDir 'templates/agent-directive-template.md'
    }
    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
        Emit 'fix' 'INCOMPLETE' 'directive template unavailable' 'Restore templates/agent-directive-template.md from the kit'
        exit 2
    }
}

# Render the managed directive block exactly as init.ps1 does.
function Render-Directive {
    $kitDirRel = $engineRelpath
    $ver = $stampVer
    if ([string]::IsNullOrEmpty($ver)) { $ver = $stateVer }
    $sha = $stampSha
    if ([string]::IsNullOrEmpty($sha)) { $sha = $stateSha }
    if ([string]::IsNullOrEmpty($ver) -or [string]::IsNullOrEmpty($sha)) {
        $described = ''
        $shortSha = ''
        try {
            $described = ((& git -C $engineDir describe --tags --match 'v[0-9]*' 2>$null | Out-String)).Trim()
            $shortSha = ((& git -C $engineDir rev-parse --short HEAD 2>$null | Out-String)).Trim()
        } catch {
            $described = ''
            $shortSha = ''
        }
        if ([string]::IsNullOrEmpty($ver)) { $ver = if ([string]::IsNullOrEmpty($described)) { 'unknown' } else { $described } }
        if ([string]::IsNullOrEmpty($sha)) { $sha = if ([string]::IsNullOrEmpty($shortSha)) { 'unknown' } else { $shortSha } }
    }
    $sedKit = Get-SedReplacementEscape $kitDirRel
    $sedVer = Get-SedReplacementEscape $ver
    $sedSha = Get-SedReplacementEscape $sha
    $rendered = Get-Content -LiteralPath $template -Raw
    $rendered = $rendered -replace '\$KIT_DIR_REL', $sedKit
    $rendered = $rendered -replace '\$ENGINE_VERSION', $sedVer
    $rendered = $rendered -replace '\$ENGINE_SHA', $sedSha
    return $rendered
}

function Repair-HostBlock {
    param([string]$Path)
    $rendered = Render-Directive
    $existing = ''
    try { $existing = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop } catch { $existing = '' }
    if ([string]::IsNullOrEmpty($existing)) {
        [IO.File]::WriteAllText($Path, "$rendered`n", [Text.UTF8Encoding]::new($false))
    } else {
        $combined = $existing.TrimEnd("`r", "`n") + "`n`n" + $rendered + "`n"
        [IO.File]::WriteAllText($Path, $combined, [Text.UTF8Encoding]::new($false))
    }
}

# A re-emitted block is only usable if the engine path it embeds actually
# resolves on disk; otherwise the host row is MISSING rather than OK.
function Test-EngineDirectiveUsable {
    $routePath = Join-Path $projectRoot (Join-Path $engineRelpath 'workflows/route.md')
    return (Test-Path -LiteralPath $routePath -PathType Leaf)
}

# --- Check 1: hosts -------------------------------------------------------
# Enumerate the installer's host_file() map. A file that INSTALLED (exists) is
# checked for the managed block; a file not present is SKIP(not installed) and
# is never flagged MISSING. Declared mode scopes expectations: a Lite install
# is not judged against Balanced-only workflow lists, so the only host-level
# expectation is the managed directive block itself, identical for both modes.
$installedHosts = [System.Collections.Generic.List[string]]::new()
foreach ($id in $hostIds) {
    $rel = Get-HostRelpath $id
    if ([string]::IsNullOrEmpty($rel)) { continue }
    $path = Join-Path $kitRoot $rel
    if (-not (Test-Path -LiteralPath $path)) {
        if ($rel -eq 'AGENTS.md') {
            Emit "host:$rel" 'MISSING' 'universal host file absent' 'Re-run the installer to create AGENTS.md'
        } else {
            Emit "host:$rel" 'SKIP(not installed)' 'host file not present' '-'
        }
        continue
    }
    $fileItem = Get-Item -LiteralPath $path -Force
    if ($fileItem.PSIsContainer -or ($fileItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Emit "host:$rel" 'INCOMPLETE' 'host file unreadable' 'Restore read access to the host directive file'
        $installedHosts.Add($rel)
        continue
    }
    if (Test-Block $path) {
        Emit "host:$rel" 'OK' 'managed directive block present' '-'
    } elseif ($Fix) {
        try { Repair-HostBlock $path } catch { }
        if (-not (Test-Block $path)) {
            Emit "host:$rel" 'MISSING' 'no PROMPTKIT_START block' 'Run the installer or pk:doctor --fix to re-emit the managed directive block'
        } elseif (-not (Test-EngineDirectiveUsable)) {
            Emit "host:$rel" 'MISSING' "repaired block references a missing engine path ($engineRelpath/workflows/route.md)" 'Restore the engine workflows/ directory or re-run the installer'
        } else {
            Emit "host:$rel" 'OK' 'managed directive block re-emitted by --fix' '-'
        }
    } else {
        Emit "host:$rel" 'MISSING' 'no PROMPTKIT_START block' 'Run the installer or pk:doctor --fix to re-emit the managed directive block'
    }
    $installedHosts.Add($rel)
}

# --- Check 2: version -----------------------------------------------------
# Issue #545's six-state table (workflows/sync.md, Engine Version & Drift
# Audit), implemented as read-only git comparisons. Tests run top-to-bottom,
# first match wins.
function Invoke-LocalGit {
    param([string]$Dir, [string[]]$GitArgs)
    try {
        $out = & git --no-optional-locks -C $Dir -c core.fsmonitor=false @GitArgs 2>$null
        $script:gitStatus = $LASTEXITCODE
        return $out
    } catch {
        $script:gitStatus = 127
        return $null
    }
}

function Resolve-Upstream {
    $null = Invoke-LocalGit -Dir $engineDir @('symbolic-ref', '-q', 'refs/remotes/origin/HEAD')
    if ($script:gitStatus -eq 0) {
        $sym = ((Invoke-LocalGit -Dir $engineDir @('symbolic-ref', '-q', 'refs/remotes/origin/HEAD')) | Out-String).Trim()
        if (-not [string]::IsNullOrEmpty($sym)) {
            $null = Invoke-LocalGit -Dir $engineDir @('rev-parse', '--verify', '--quiet', "$sym^{commit}")
            if ($script:gitStatus -eq 0) { return $sym }
        }
    }
    foreach ($candidate in @('refs/remotes/origin/main', 'refs/remotes/origin/master', 'refs/remotes/upstream/main', 'origin/main', 'origin/master')) {
        $null = Invoke-LocalGit -Dir $engineDir @('rev-parse', '--verify', '--quiet', "$candidate^{commit}")
        if ($script:gitStatus -eq 0) { return $candidate }
    }
    return ''
}

function Check-Version {
    if ([string]::IsNullOrEmpty($stampVer) -or [string]::IsNullOrEmpty($stampSha)) {
        Emit 'version' 'SKIP(no engine stamp)' 'no Engine: <ver> (<sha>) stamp in any installed host directive' 'Re-run the installer to stamp the engine identity'
        return
    }
    if (-not (Test-Path -LiteralPath (Join-Path $engineDir '.git'))) {
        Emit 'version' 'SKIP(not-a-git-install)' 'no .git in engine dir (courier install)' 'Version comes from the release tarball; no git drift to measure'
        return
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Emit 'version' 'SKIP(shallow-or-offline)' 'git unavailable' 'Install git to enable engine drift checks'
        return
    }
    $shallowRaw = ((Invoke-LocalGit -Dir $engineDir @('rev-parse', '--is-shallow-repository')) | Out-String).Trim()
    if ($script:gitStatus -ne 0 -or $shallowRaw -ne 'false') {
        Emit 'version' 'SKIP(shallow-or-offline)' 'shallow or offline checkout' 'Fetch full history (git fetch --unshallow) to check drift'
        return
    }
    $upstream = Resolve-Upstream
    if ([string]::IsNullOrEmpty($upstream)) {
        Emit 'version' 'SKIP(shallow-or-offline)' 'upstream ref unresolved' 'Resolve origin/main (or the engine default branch) to enable drift checks'
        return
    }
    $null = Invoke-LocalGit -Dir $engineDir @('merge-base', '--is-ancestor', 'HEAD', $upstream)
    $mb = $script:gitStatus
    if ($mb -eq 1) {
        Emit 'version' 'DIVERGED' "engine $stampVer diverged from $upstream" 'Reconcile the engine checkout with upstream manually; doctor never fetches or resets'
        return
    }
    if ($mb -ne 0) {
        Emit 'version' 'SKIP(shallow-or-offline)' "merge-base returned unexpected status $mb" 'Resolve the upstream ref and re-run'
        return
    }
    $countRaw = ((Invoke-LocalGit -Dir $engineDir @('rev-list', '--count', "HEAD..$upstream")) | Out-String).Trim()
    if ($script:gitStatus -ne 0 -or [string]::IsNullOrEmpty($countRaw)) {
        Emit 'version' 'SKIP(shallow-or-offline)' 'rev-list failed' 'Resolve the upstream ref and re-run'
        return
    }
    $count = [int]$countRaw
    if ($count -gt 0) {
        Emit 'version' "STALE(+$count)" "engine $stampVer is $count commit(s) behind $upstream" 'Offer pk:sync upgrade (read-only doctor never upgrades)'
    } else {
        Emit 'version' 'OK' "engine $stampVer ($stampSha) current" '-'
    }
}

Check-Version

# --- Check 3: ignore-state ------------------------------------------------
# Three-way status branch from check-harness-security.sh:58-72. `--no-index`
# matches that precedent: it classifies managed paths by the ignore rules that
# apply to them even when they are tracked, which is the question doctor asks.
# exit 0 -> IGNORED(<rule source>); exit 1 -> OK; anything else -> INCOMPLETE.
function Test-IgnoreOne {
    param([string]$Rel)
    $out = @(Invoke-LocalGit -Dir $projectRoot @('check-ignore', '--no-index', '-v', '--', $Rel))
    if ($script:gitStatus -eq 0) {
        $line = if ($out.Count -gt 0) { [string]$out[0] } else { '' }
        $rule = ($line -split "`t")[0]
        if ([string]::IsNullOrEmpty($rule)) { $rule = '(unknown rule)' }
        Emit "ignore:$Rel" "IGNORED($rule)" 'managed path is matched by an ignore rule' 'Un-ignore the managed path if it must be tracked, or keep the intentional ignore'
    } elseif ($script:gitStatus -eq 1) {
        Emit "ignore:$Rel" 'OK' 'not ignored' '-'
    } else {
        Emit "ignore:$Rel" 'INCOMPLETE' "git check-ignore returned unexpected status $($script:gitStatus)" 'Investigate why git could not classify the path'
    }
}

function Check-IgnoreState {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.git'))) {
        if ($engineOutsideProject) {
            Emit "ignore:$engineRelpath" 'SKIP(engine outside project root)' '-' '-'
        } else {
            Emit "ignore:$engineRelpath" 'SKIP(not-a-git-install)' 'no .git in project root (courier install)' 'Ignore state is not measurable without a git repository'
        }
        Emit 'ignore:PROMPTKIT.md' 'SKIP(not-a-git-install)' 'no .git in project root (courier install)' '-'
        Emit 'ignore:docs' 'SKIP(not-a-git-install)' 'no .git in project root (courier install)' '-'
        return
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        if ($engineOutsideProject) {
            Emit "ignore:$engineRelpath" 'SKIP(engine outside project root)' '-' '-'
        } else {
            Emit "ignore:$engineRelpath" 'SKIP(git unavailable)' 'git unavailable' 'Install git to inspect ignore state'
        }
        return
    }
    if ($engineOutsideProject) {
        Emit "ignore:$engineRelpath" 'SKIP(engine outside project root)' '-' '-'
    } else {
        Test-IgnoreOne $engineRelpath
    }
    Test-IgnoreOne 'PROMPTKIT.md'
    Test-IgnoreOne 'docs'
    foreach ($hrel in $installedHosts) { Test-IgnoreOne $hrel }
}

Check-IgnoreState

# --- Check 4: docs-drift --------------------------------------------------
# Three-store precedence (protocols/context-sync.md §3.2): the Task Record at
# docs/tasks/<task-id>.md is canonical, STATE.md §3A is a synchronized
# projection that must not override it, and a harness handoff store is
# reference-only and can NEVER introduce a DIVERGED verdict. The comparison is
# deliberately conservative: only fields present in both stores with
# unambiguous, non-placeholder values are compared. Any absent store degrades
# to SKIP(<reason>) and never fails the run.
# Shared fields derived from the shipped state-tracker-template.md section 3A
# and the shipped execution-task-record-template.md. Each entry is
# "<3A label>|<Task Record label>"; Owner is projected as "Owner / Current
# Actor" in 3A and "Owner / Actor" in the Task Record. No invented fields.
$sharedProjectionFields = @(
    'Task ID|Task ID',
    'Execution State|Execution State',
    'Active Task Pointer|Active Task Pointer',
    'Next Action|Next Action',
    'Owner / Current Actor|Owner / Actor',
    'Ceremony Level|Ceremony Level',
    'Specification|Specification',
    'Execution Scope|Execution Scope',
    'Start Time|Start Time',
    'Mapped `pk:tasks` Status|Mapped `pk:tasks` Status'
)

function Get-ProjectionField {
    param([string]$Text, [string]$Label)
    $m = [regex]::Match($Text, "(?m)^- \*\*$([regex]::Escape($Label))\*\*:[ \t]*(.*)$")
    if (-not $m.Success) { return '' }
    return $m.Groups[1].Value.Trim().Trim('`').Trim()
}

function Test-Placeholder {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    if ($Value -eq '-' -or $Value -eq 'not tracked') { return $true }
    if ($Value.Contains('<task-id>')) { return $true }
    $first = $Value.Substring(0, 1)
    if ($first -eq '[' -or $first -eq '<') { return $true }
    return $false
}

function Check-DocsDrift {
    $stateFile = Join-Path $kitRoot 'docs/STATE.md'
    if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
        Emit 'docs-drift' 'SKIP(no STATE.md)' 'no docs/STATE.md' 'Create docs/STATE.md to enable the projection comparison'
        return
    }
    $stateText = Get-Content -LiteralPath $stateFile -Raw
    $sectionMatch = [regex]::Match($stateText, '(?ms)^##\s+3A\.(.*?)(?=^##\s|\z)')
    $section = if ($sectionMatch.Success) { $sectionMatch.Groups[1].Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($section)) {
        Emit 'docs-drift' 'SKIP(no execution-control projection)' 'docs/STATE.md has no section 3A' 'Populate 3A when using Controlled Work'
        return
    }
    $taskId = Get-ProjectionField $section 'Task ID'
    $taskRecord = Get-ProjectionField $section 'Task Record'
    if ((Test-Placeholder $taskRecord) -and (Test-Placeholder $taskId)) {
        Emit 'docs-drift' 'SKIP(no task record)' 'no canonical Task Record referenced (no handoff.md and no Task Record)' 'Create docs/tasks/<task-id>.md for Controlled Work'
        return
    }
    $recRel = $taskRecord
    if ((Test-Placeholder $recRel) -and -not (Test-Placeholder $taskId)) { $recRel = "docs/tasks/$taskId.md" }
    if ((Test-Placeholder $recRel) -or $recRel.StartsWith('/') -or $recRel.Contains('..')) {
        Emit 'docs-drift' 'SKIP(no task record)' 'canonical Task Record path is absent or unusable' 'Create docs/tasks/<task-id>.md for Controlled Work'
        return
    }
    $recPath = Join-Path $kitRoot $recRel
    if (-not (Test-Path -LiteralPath $recPath -PathType Leaf)) {
        Emit 'docs-drift' 'SKIP(no task record)' "canonical Task Record not found at $recRel" 'Create the referenced Task Record or fix its path'
        return
    }
    $recText = Get-Content -LiteralPath $recPath -Raw
    $diffField = ''
    $compared = 0
    foreach ($pair in $sharedProjectionFields) {
        $parts = $pair.Split('|')
        $pLabel = $parts[0]
        $rLabel = $parts[1]
        $pVal = Get-ProjectionField $section $pLabel
        $rVal = Get-ProjectionField $recText $rLabel
        if (Test-Placeholder $rVal) { continue }
        if ((Test-Placeholder $pVal) -or ($pVal -ne $rVal)) { $diffField = $pLabel; break }
        $compared++
    }
    if (-not [string]::IsNullOrEmpty($diffField)) {
        Emit 'docs-drift' "DIVERGED(STATE 3A vs Task Record: $diffField)" "projection disagrees with the canonical Task Record on $diffField" 'Reconcile 3A to the Task Record (the Task Record is authoritative)'
    } elseif ($compared -gt 0) {
        Emit 'docs-drift' 'OK' 'projection agrees with the canonical Task Record' '-'
    } else {
        Emit 'docs-drift' 'SKIP(no comparable field)' 'no shared field has concrete values in both stores' 'Populate the 3A projection and the Task Record with concrete, aligned values'
    }
}

Check-DocsDrift

if ($script:fail) { exit 1 }
exit 0
