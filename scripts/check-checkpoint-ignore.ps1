# Read-only gitignore preflight for pk:checkpoint targets.
# Usage: scripts/check-checkpoint-ignore.ps1 [-Root PATH] [-TargetsFile PATH]
#
# Reports checkpoint artifacts that Git cannot see because an ignore rule
# matches them. It never stages, force-adds, commits, resets, or un-ignores
# anything: the matching rule is surfaced as evidence and the author decides.

[CmdletBinding()]
param(
    [string]$Root = '.',
    [string]$TargetsFile = (Join-Path $PSScriptRoot 'checkpoint-targets.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:scanned = 0
$script:ignored = 0
$script:policyLines = [System.Collections.Generic.List[string]]::new()
$script:gitStatus = 0

function ConvertTo-Sanitized {
    param([string]$Value)
    return ($Value -replace '[\r\n|]', ' ')
}

function Add-PolicyLine {
    param([string]$Line)
    $script:policyLines.Add($Line)
}

function Write-Incomplete {
    param([string]$Reason, [string]$Path)
    # Print any evidence already gathered, then the single INCOMPLETE summary.
    # A success summary is never printed on an unmeasured result.
    foreach ($line in $script:policyLines) { Write-Output $line }
    Write-Output "CHECKPOINT_IGNORE|INCOMPLETE|$Reason|$Path"
    exit 2
}

# Fail closed on an unreadable rules file before measuring anything.
if (-not (Test-Path -LiteralPath $TargetsFile -PathType Leaf)) {
    Write-Output 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|.'
    exit 2
}
try {
    $targetsText = Get-Content -LiteralPath $TargetsFile -Raw -ErrorAction Stop
} catch {
    Write-Output 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|.'
    exit 2
}
if ($null -eq $targetsText) { $targetsText = '' }

try {
    $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
} catch {
    Write-Output 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.'
    exit 2
}
if (-not $rootItem.PSIsContainer -or ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Output 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.'
    exit 2
}
$rootPath = $rootItem.FullName
$gitDir = Join-Path $rootPath '.git'
if (-not (Test-Path -LiteralPath $gitDir)) {
    Write-Output 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.'
    exit 2
}

# Strict row validation pre-pass: after the trailing-CR strip and the
# blank/`#` skips, every remaining row must be `path|kind` with a non-empty
# pipe-free path and kind exactly `file` or `dir`. Validate all rows before
# measuring anything; fail closed on the first violating row.
$rows = [System.Collections.Generic.List[object]]::new()
foreach ($rawLine in ($targetsText -split "`n")) {
    $line = $rawLine
    if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
    if ($line -notmatch '\S') { continue }
    if ($line.StartsWith('#')) { continue }
    if (-not [regex]::IsMatch($line, '^[^|]+\|(file|dir)$')) {
        Write-Incomplete 'RULES' (ConvertTo-Sanitized $line)
    }
    $pipeIndex = $line.IndexOf('|')
    $rows.Add([pscustomobject]@{
        Relative = $line.Substring(0, $pipeIndex)
        Kind     = $line.Substring($pipeIndex + 1)
    })
}

function Invoke-LocalGit {
    param([string[]]$GitArgs)
    # No hooks, configured commands, optional index writes, or network calls.
    # A git that cannot be started (command-not-found / invocation throws) is
    # folded into the same unexpected-status path as any other failure: use a
    # non-0/1 sentinel so Check-Target fails closed instead of leaking the raw
    # exception with exit 1.
    try {
        & git --no-optional-locks "--git-dir=$gitDir" "--work-tree=$rootPath" -c core.fsmonitor=false @GitArgs 2>$null
        $script:gitStatus = $LASTEXITCODE
    } catch {
        $script:gitStatus = 127
    }
}

function Check-Target {
    param([string]$Relative)
    $script:scanned++
    # No --no-index: a tracked file is visible to git and must not be reported
    # as ignored. Three-way branch on the exit status, fail closed otherwise.
    $out = @(Invoke-LocalGit @('check-ignore', '-v', '--', $Relative))
    $status = $script:gitStatus
    if ($status -eq 0) {
        $rule = (($out -join "`n") -split "`t", 2)[0]
        Add-PolicyLine ("POLICY_LIMITATION|CHECKPOINT_IGNORE|" + (ConvertTo-Sanitized $Relative) +
            '|Checkpoint target is ignored by ' + (ConvertTo-Sanitized $rule) +
            '|Author may add a ! negation exception or relocate the artifact; pk:checkpoint does not stage, force-add, or un-ignore')
        $script:ignored++
    } elseif ($status -eq 1) {
        # Not ignored: visible to git, no finding.
    } else {
        Write-Incomplete 'GIT_IGNORE' (ConvertTo-Sanitized $Relative)
    }
}

foreach ($row in $rows) {
    if ($row.Kind -eq 'file') {
        Check-Target $row.Relative
    } elseif ($row.Kind -eq 'dir') {
        # Probe the directory itself first (trailing slashes trimmed to exactly
        # one), then each existing direct *.md entry, ordinal-sorted.
        Check-Target ($row.Relative.TrimEnd('/') + '/')
        $dirPath = if ($row.Relative.Length -gt 0) { Join-Path $rootPath $row.Relative } else { $rootPath }
        $entries = @()
        if (Test-Path -LiteralPath $dirPath -PathType Container) {
            # Missing dir (and an unreadable one) is a no-op, matching nullglob.
            try { $entries = @(Get-ChildItem -LiteralPath $dirPath -File -ErrorAction Stop) } catch { $entries = @() }
        }
        $names = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $entries) {
            if ($entry.Name -clike '*.md') { $names.Add($entry.Name) }
        }
        $names.Sort([System.StringComparer]::Ordinal)
        foreach ($name in $names) {
            Check-Target "$($row.Relative)/$name"
        }
    }
}

if ($script:ignored -gt 0) {
    foreach ($line in $script:policyLines) { Write-Output $line }
    Write-Output "CHECKPOINT_IGNORE|DEGRADED|IGNORED=$($script:ignored)|SCANNED=$($script:scanned)"
    exit 0
}
Write-Output "CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=$($script:scanned)"
exit 0
