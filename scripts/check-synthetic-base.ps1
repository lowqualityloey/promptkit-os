# Read-only synthetic-base preflight.
# Usage: scripts/check-synthetic-base.ps1 [-Root PATH] [-Commit REF] [-SignalsFile PATH]
#
# Refuses to let a caller derive a comparison base from a commit that is
# positively tool-owned -- a synthetic workspace commit carried by a
# tool-namespace ref (e.g. refs/gitbutler/*, refs/orca/*) and by no branch.
# Read-only by construction: rev-parse/for-each-ref only. It never stages,
# commits, fetches, rebases, invokes a vendor CLI, or writes any file.

[CmdletBinding()]
param(
    [string]$Root = '.',
    [string]$Commit = 'HEAD',
    [string]$SignalsFile = (Join-Path $PSScriptRoot 'synthetic-base-signals.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:gitStatus = 0

function ConvertTo-Sanitized {
    param([string]$Value)
    return ($Value -replace '[\r\n|]', ' ')
}

# Fail closed on an unreadable signals file before measuring anything.
if (-not (Test-Path -LiteralPath $SignalsFile -PathType Leaf)) {
    Write-Output 'SYNTHETIC_BASE|INCOMPLETE|RULES|.'
    exit 2
}
try {
    $signalsText = Get-Content -LiteralPath $SignalsFile -Raw -ErrorAction Stop
} catch {
    Write-Output 'SYNTHETIC_BASE|INCOMPLETE|RULES|.'
    exit 2
}
if ($null -eq $signalsText) { $signalsText = '' }

# Strict row validation, fail closed: every non-comment row is
# `ref-namespace|<prefix>` with exactly one pipe and a non-empty prefix.
$namespaces = [System.Collections.Generic.List[string]]::new()
foreach ($rawLine in ($signalsText -split "`n")) {
    $line = $rawLine
    if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
    if ($line -notmatch '\S') { continue }
    if ($line.StartsWith('#')) { continue }
    if (-not [regex]::IsMatch($line, '^ref-namespace\|[^|]+$')) {
        Write-Output ("SYNTHETIC_BASE|INCOMPLETE|RULES|" + (ConvertTo-Sanitized $line))
        exit 2
    }
    $namespaces.Add($line.Substring($line.IndexOf('|') + 1))
}

# Project-supplied extra owned namespaces (whitespace-separated prefixes).
if (-not [string]::IsNullOrWhiteSpace($env:PROMPTKIT_SYNTHETIC_REFS_EXTRA)) {
    foreach ($extra in ($env:PROMPTKIT_SYNTHETIC_REFS_EXTRA -split '\s+')) {
        if (-not [string]::IsNullOrWhiteSpace($extra)) { $namespaces.Add($extra) }
    }
}

try {
    $rootItem = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
} catch {
    Write-Output 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.'
    exit 2
}
if (-not $rootItem.PSIsContainer -or ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Output 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.'
    exit 2
}
$rootPath = $rootItem.FullName

function Invoke-LocalGit {
    param([string[]]$GitArgs)
    # No hooks, configured commands, optional index writes, or network calls.
    # A git that cannot be started is folded into an unexpected-status sentinel
    # so the caller fails closed instead of leaking the raw exception.
    try {
        $out = & git --no-optional-locks -C $rootPath -c core.fsmonitor=false @GitArgs 2>$null
        $script:gitStatus = $LASTEXITCODE
        return $out
    } catch {
        $script:gitStatus = 127
        return $null
    }
}

$null = Invoke-LocalGit @('rev-parse', '--git-dir')
if ($script:gitStatus -ne 0) { Write-Output 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.'; exit 2 }

$sha = Invoke-LocalGit @('rev-parse', '--verify', '--quiet', "$Commit^{commit}")
$sha = (($sha | Out-String)).Trim()
if ($script:gitStatus -ne 0 -or [string]::IsNullOrWhiteSpace($sha)) {
    Write-Output ("SYNTHETIC_BASE|INCOMPLETE|COMMIT|" + (ConvertTo-Sanitized $Commit))
    exit 2
}

# A carrying branch (local or remote-tracking) makes the commit an ordinary
# branch tip. This is the silent, healthy path.
$carrying = @(Invoke-LocalGit @('for-each-ref', '--contains', $sha, '--format=%(refname)', 'refs/heads', 'refs/remotes'))
if ($script:gitStatus -ne 0) { Write-Output 'SYNTHETIC_BASE|INCOMPLETE|REFS|.'; exit 2 }
if ($carrying.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$carrying[0])) {
    Write-Output ("SYNTHETIC_BASE|OK|$sha|carried-by=" + (ConvertTo-Sanitized ([string]$carrying[0])))
    exit 0
}

# Positive evidence only: the commit is owned by a tool namespace. Absence of a
# carrying branch is corroborating, never sufficient on its own -- a detached
# real commit is exactly "no carrying branch" and must fall through to UNKNOWN.
foreach ($ns in $namespaces) {
    $owned = @(Invoke-LocalGit @('for-each-ref', '--contains', $sha, '--format=%(refname)', $ns))
    if ($script:gitStatus -ne 0) { Write-Output 'SYNTHETIC_BASE|INCOMPLETE|REFS|.'; exit 2 }
    if ($owned.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$owned[0])) {
        Write-Output ("SYNTHETIC_BASE|REFUSE|$sha|owned-ref=" + (ConvertTo-Sanitized ([string]$owned[0])))
        Write-Output 'SYNTHETIC_BASE|RECOVERY|Return to the carrying branch or rebase onto a real branch tip before deriving a base; never derive a base from a synthetic workspace commit (docs/MAXIMS.md)'
        exit 1
    }
}

Write-Output "SYNTHETIC_BASE|UNKNOWN|$sha|no-carrying-branch-no-owned-ref"
exit 0
