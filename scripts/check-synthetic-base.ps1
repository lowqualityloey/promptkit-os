# Read-only synthetic-base preflight.
# Usage: scripts/check-synthetic-base.ps1 [-Root PATH] [-Commit REF] [-SignalsFile PATH]
#
# Refuses to let a caller derive a comparison base from a commit that is
# positively tool-owned: either the tip of a tool-namespace ref (ref-namespace|
# rows, e.g. refs/gitbutler/) or carried only by tool-owned branch namespaces
# (branch-namespace| rows, e.g. GitButler's refs/heads/gitbutler/workspace). A
# commit carried by any ordinary branch is silent.
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
# `ref-namespace|<prefix>` or `branch-namespace|<prefix>` with exactly one pipe
# and a non-empty prefix.
$refNamespaces = [System.Collections.Generic.List[string]]::new()
$branchNamespaces = [System.Collections.Generic.List[string]]::new()
foreach ($rawLine in ($signalsText -split "`n")) {
    $line = $rawLine
    if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
    if ($line -notmatch '\S') { continue }
    if ($line.StartsWith('#')) { continue }
    if ([regex]::IsMatch($line, '^ref-namespace\|[^|]+$')) {
        $refNamespaces.Add($line.Substring($line.IndexOf('|') + 1))
        continue
    }
    if ([regex]::IsMatch($line, '^branch-namespace\|[^|]+$')) {
        $branchNamespaces.Add($line.Substring($line.IndexOf('|') + 1))
        continue
    }
    Write-Output ("SYNTHETIC_BASE|INCOMPLETE|RULES|" + (ConvertTo-Sanitized $line))
    exit 2
}

# Project-supplied extra owned ref namespaces (whitespace-separated ref prefixes).
if (-not [string]::IsNullOrWhiteSpace($env:PROMPTKIT_SYNTHETIC_REFS_EXTRA)) {
    foreach ($extra in ($env:PROMPTKIT_SYNTHETIC_REFS_EXTRA -split '\s+')) {
        if (-not [string]::IsNullOrWhiteSpace($extra)) { $refNamespaces.Add($extra) }
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

$carrying = @(Invoke-LocalGit @('for-each-ref', '--contains', $sha, '--format=%(refname)', 'refs/heads', 'refs/remotes'))
if ($script:gitStatus -ne 0) { Write-Output 'SYNTHETIC_BASE|INCOMPLETE|REFS|.'; exit 2 }

# Partition the carrying refs. A commit carried by any ordinary branch is an
# ordinary branch tip and is silent (Scenario 1), even when a tool-owned branch
# namespace also carries it. A ref is tool-owned only when its branch name (after
# refs/heads/ or refs/remotes/<remote>/) begins with a branch-namespace prefix.
$ordinaryCarrying = ''
$toolBranch = ''
foreach ($carryingRef in $carrying) {
    if ([string]::IsNullOrWhiteSpace([string]$carryingRef)) { continue }
    $refName = [string]$carryingRef
    $branchName = $refName
    if ($refName.StartsWith('refs/heads/')) {
        $branchName = $refName.Substring('refs/heads/'.Length)
    } elseif ($refName.StartsWith('refs/remotes/')) {
        $remoteRest = $refName.Substring('refs/remotes/'.Length)
        $slash = $remoteRest.IndexOf('/')
        $branchName = if ($slash -ge 0) { $remoteRest.Substring($slash + 1) } else { $remoteRest }
    }
    $isToolBranch = $false
    foreach ($branchNs in $branchNamespaces) {
        if ($branchName.StartsWith($branchNs, [StringComparison]::Ordinal)) { $isToolBranch = $true; break }
    }
    if ($isToolBranch) {
        if ([string]::IsNullOrEmpty($toolBranch)) { $toolBranch = $refName }
    } elseif ([string]::IsNullOrEmpty($ordinaryCarrying)) {
        $ordinaryCarrying = $refName
    }
}

if (-not [string]::IsNullOrEmpty($ordinaryCarrying)) {
    Write-Output ("SYNTHETIC_BASE|OK|$sha|carried-by=" + (ConvertTo-Sanitized $ordinaryCarrying))
    exit 0
}

# Positive class (b): the commit is carried only by tool-owned branch namespaces
# (GitButler's refs/heads/gitbutler/workspace). Refuse.
if (-not [string]::IsNullOrEmpty($toolBranch)) {
    Write-Output ("SYNTHETIC_BASE|REFUSE|$sha|owned-branch=" + (ConvertTo-Sanitized $toolBranch))
    Write-Output 'SYNTHETIC_BASE|RECOVERY|Return to the carrying branch or rebase onto a real branch tip before deriving a base; never derive a base from a synthetic workspace commit (docs/MAXIMS.md)'
    exit 1
}

# Positive class (a): the commit is the tip of a tool-namespace ref. The ref must
# point AT the commit -- an earlier commit on the same reachable chain is an
# ordinary commit, not a synthetic one, so --contains would falsely refuse it.
# Absence of a carrying branch is corroborating, never sufficient on its own -- a
# detached real commit is exactly "no carrying branch" and must fall through to
# UNKNOWN.
foreach ($ns in $refNamespaces) {
    $owned = @(Invoke-LocalGit @('for-each-ref', '--points-at', $sha, '--format=%(refname)', $ns))
    if ($script:gitStatus -ne 0) { Write-Output 'SYNTHETIC_BASE|INCOMPLETE|REFS|.'; exit 2 }
    if ($owned.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$owned[0])) {
        Write-Output ("SYNTHETIC_BASE|REFUSE|$sha|owned-ref=" + (ConvertTo-Sanitized ([string]$owned[0])))
        Write-Output 'SYNTHETIC_BASE|RECOVERY|Return to the carrying branch or rebase onto a real branch tip before deriving a base; never derive a base from a synthetic workspace commit (docs/MAXIMS.md)'
        exit 1
    }
}

Write-Output "SYNTHETIC_BASE|UNKNOWN|$sha|no-carrying-branch-no-owned-ref"
exit 0
