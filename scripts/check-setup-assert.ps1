# Read-only install-door structural assert for the PromptKit OS kit tree.
#
# Usage: scripts/check-setup-assert.ps1 -ProjectRoot <dir> -KitDir <dir> -KitDirRel <rel>
#
# The installer calls this after a successful commit and before printing the
# success banner. It classifies which documented install door produced the kit
# tree and asserts only what is structurally true for that door, so a partial
# copy or a broken submodule registration fails loudly instead of printing
# success. It is read-only: it never stages, commits, mutates the index, or
# touches the network.
#
# Doors: standalone | courier | direct-clone | submodule | partial-copy | tracked-content.
# `partial-copy` is the incomplete-tree outcome: any install missing a required
# engine file. A partial copy is never a passing door.
#
# Records (one per line, `|`-delimited; CR, LF and `|` are replaced with spaces
# in the free-text remedy field only):
#   ASSERT|<door>|missing:<path>|FAIL
#   ASSERT|<door>|<check>|OK|FAIL|INCOMPLETE|SKIP
#   ASSERT|skipped|USER_OPT_OUT|SKIP             ($env:PROMPTKIT_NO_PREFLIGHT=1)
#   ASSERT|<door>|remedy|<prose>                 (human remedy; field 4 is text)
#
# Exit: 0 = OK or explicit opt-out, 1 = structural FAIL, 2 = INCOMPLETE.
# FAIL is an observed structural mismatch the author can fix. INCOMPLETE means
# the condition could not be measured (git missing, an unexpected git status,
# an unreadable manifest); an unmeasured result is never reported as OK.

[CmdletBinding()]
param(
    [string]$ProjectRoot = '',
    [string]$KitDir = '',
    [string]$KitDirRel = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:gitStatus = 0
$script:gitOut = @()

function Write-Verdict {
    param([string]$Door, [string]$Check, [string]$Status)
    Write-Output ("ASSERT|" + $Door + "|" + $Check + "|" + $Status)
}

function ConvertTo-Sanitized {
    param([string]$Value)
    return ($Value -replace '[\r\n|]', ' ')
}

function Write-Remedy {
    param([string]$Door, [string]$Text)
    Write-Output ("ASSERT|" + $Door + "|remedy|" + (ConvertTo-Sanitized $Text))
}

function Exit-Incomplete {
    param([string]$Door, [string]$Check)
    Write-Verdict $Door $Check 'INCOMPLETE'
    exit 2
}

if ([string]::IsNullOrEmpty($ProjectRoot) -or [string]::IsNullOrEmpty($KitDir)) {
    Write-Verdict 'unknown' 'args' 'INCOMPLETE'
    exit 2
}

if ($env:PROMPTKIT_NO_PREFLIGHT -eq '1') {
    Write-Verdict 'skipped' 'USER_OPT_OUT' 'SKIP'
    exit 0
}

$manifest = Join-Path $PSScriptRoot 'setup-assert-files.txt'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { Exit-Incomplete 'unknown' 'rules' }
try {
    $manifestText = Get-Content -LiteralPath $manifest -Raw -ErrorAction Stop
} catch {
    Exit-Incomplete 'unknown' 'rules'
}
if ($null -eq $manifestText) { $manifestText = '' }

# Strict row validation, fail closed before measuring anything.
$rows = [System.Collections.Generic.List[object]]::new()
foreach ($rawLine in ($manifestText -split "`n")) {
    $line = $rawLine
    if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
    if ($line -notmatch '\S') { continue }
    if ($line.StartsWith('#')) { continue }
    if (-not [regex]::IsMatch($line, '^[^|]+\|(file|dir)$')) { Exit-Incomplete 'unknown' 'rules' }
    $pipe = $line.IndexOf('|')
    $rows.Add([pscustomobject]@{
        Relative = $line.Substring(0, $pipe)
        Kind     = $line.Substring($pipe + 1)
    })
}

try {
    $kitItem = Get-Item -LiteralPath $KitDir -Force -ErrorAction Stop
} catch {
    Exit-Incomplete 'unknown' 'kit_metadata'
}
if (-not $kitItem.PSIsContainer) { Exit-Incomplete 'unknown' 'kit_metadata' }
$kitCanon = $kitItem.FullName

$projectCanon = ''
try {
    $projectItem = Get-Item -LiteralPath $ProjectRoot -Force -ErrorAction Stop
    if ($projectItem.PSIsContainer) { $projectCanon = $projectItem.FullName }
} catch {
    $projectCanon = ''
}

$missing = [System.Collections.Generic.List[string]]::new()
foreach ($row in $rows) {
    $target = Join-Path $kitCanon $row.Relative
    if ($row.Kind -eq 'file') {
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { $missing.Add($row.Relative) }
    } else {
        if (-not (Test-Path -LiteralPath $target -PathType Container)) { $missing.Add($row.Relative) }
    }
}

$isWindowsOS = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT

function Test-PathEqual {
    param([string]$A, [string]$B)
    if ($A.Length -eq 0 -or $B.Length -eq 0) { return $false }
    $trimmedA = $A.TrimEnd('\', '/')
    $trimmedB = $B.TrimEnd('\', '/')
    if ($isWindowsOS) {
        return [string]::Equals($trimmedA, $trimmedB, [System.StringComparison]::OrdinalIgnoreCase)
    }
    return [string]::Equals($trimmedA, $trimmedB, [System.StringComparison]::Ordinal)
}

function Write-MissingFailure {
    param([string]$Door)
    foreach ($m in $missing) { Write-Verdict $Door ("missing:" + $m) 'FAIL' }
    Write-Remedy $Door ("Restore the missing file(s) above, or reinstall via a documented method: npx promptkit-os@latest, git submodule update --remote --merge " + $KitDirRel + ", or a full engine-tree copy")
    exit 1
}

# Standalone vault: the kit root is the project root. Classified before any git
# probe, because a checkout carries its own .git and must not read as a clone.
if (Test-PathEqual $kitCanon $projectCanon) {
    if ($missing.Count -eq 0) { Write-Verdict 'standalone' 'tree' 'OK'; exit 0 }
    Write-MissingFailure 'standalone'
}

# Tree completeness is a property of every door, not only the courier: an
# incomplete tree is the partial-copy outcome regardless of any .git present.
if ($missing.Count -gt 0) { Write-MissingFailure 'partial-copy' }

# No .git in the kit (file or directory): a complete non-git tree is the courier
# (tarball) door. `Test-Path` without -PathType accepts both, which is required
# because a real submodule's .git is a file, not a directory.
if (-not (Test-Path -LiteralPath (Join-Path $kitCanon '.git'))) {
    Write-Verdict 'courier' 'tree' 'OK'
    exit 0
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Exit-Incomplete 'unknown' 'git_unavailable' }

# Scoped, read-only probes. `-C` is used instead of `--git-dir=<root>/.git`
# because a worktree host has a .git file, which the --git-dir form cannot read.
# A git that cannot be started is folded into the same unexpected-status path
# via sentinel 127, so the caller fails closed instead of leaking the exception.
function Invoke-HostGit {
    param([string[]]$GitArgs)
    $script:gitOut = @()
    try {
        $script:gitOut = @(& git --no-optional-locks -C $projectCanon -c core.fsmonitor=false @GitArgs 2>$null)
        $script:gitStatus = $LASTEXITCODE
    } catch {
        $script:gitStatus = 127
        $script:gitOut = @()
    }
}

function Invoke-KitGit {
    param([string[]]$GitArgs)
    $script:gitOut = @()
    try {
        $script:gitOut = @(& git --no-optional-locks -C $kitCanon -c core.fsmonitor=false @GitArgs 2>$null)
        $script:gitStatus = $LASTEXITCODE
    } catch {
        $script:gitStatus = 127
        $script:gitOut = @()
    }
}

function Test-GitmodulesListsKit {
    if ($projectCanon.Length -eq 0) { return $false }
    $gm = Join-Path $projectCanon '.gitmodules'
    if (-not (Test-Path -LiteralPath $gm -PathType Leaf)) { return $false }
    $entries = @()
    try {
        $entries = @(& git config -f $gm --get-regexp '^submodule\..*\.path$' 2>$null)
    } catch {
        return $false
    }
    if ($LASTEXITCODE -ne 0) { return $false }
    foreach ($entry in $entries) {
        if ($null -eq $entry) { continue }
        $parts = ([string]$entry) -split ' ', 2
        if ($parts.Count -lt 2) { continue }
        if ($parts[1].Trim() -eq $KitDirRel) { return $true }
    }
    return $false
}

$hostRepo = $false
if ($projectCanon.Length -gt 0) {
    Invoke-HostGit @('rev-parse', '--git-dir')
    if ($script:gitStatus -eq 0) { $hostRepo = $true }
    elseif ($script:gitStatus -eq 128) { $hostRepo = $false }
    else { Exit-Incomplete 'unknown' 'host_git' }
}

$door = ''
if ($hostRepo) {
    Invoke-HostGit @('ls-files', '-s', '--', $KitDirRel)
    if ($script:gitStatus -ne 0) { Exit-Incomplete 'unknown' 'host_index' }
    $entryMode = ''
    foreach ($line in $script:gitOut) {
        if ($null -eq $line) { continue }
        $text = [string]$line
        $tab = $text.IndexOf("`t")
        if ($tab -lt 0) { continue }
        $path = $text.Substring($tab + 1)
        if ($path -ne $KitDirRel) { continue }
        $entryMode = ($text.Substring(0, $tab) -split ' ')[0]
        break
    }
    if ($entryMode.Length -gt 0) {
        switch ($entryMode) {
            '160000' {
                if (-not (Test-GitmodulesListsKit)) {
                    Write-Verdict 'submodule' 'gitmodules' 'FAIL'
                    Write-Remedy 'submodule' ("A gitlink is staged for " + $KitDirRel + " but .gitmodules does not register that path; re-run git submodule update --init --recursive " + $KitDirRel + " or remove the stale index entry")
                    exit 1
                }
                $door = 'submodule'
            }
            '100644' {
                Write-Verdict 'tracked-content' 'mode:100644' 'FAIL'
                Write-Remedy 'tracked-content' ("The host tracks " + $KitDirRel + " as regular content while the kit carries its own .git; remove the nested .git or register the path as a submodule")
                exit 1
            }
            '100755' {
                Write-Verdict 'tracked-content' 'mode:100755' 'FAIL'
                Write-Remedy 'tracked-content' ("The host tracks " + $KitDirRel + " as regular content while the kit carries its own .git; remove the nested .git or register the path as a submodule")
                exit 1
            }
            default {
                Exit-Incomplete 'unknown' ("mode:" + $entryMode)
            }
        }
    } elseif (Test-GitmodulesListsKit) {
        Write-Verdict 'submodule' 'staged' 'FAIL'
        Write-Remedy 'submodule' (".gitmodules registers " + $KitDirRel + " but no gitlink is staged; run git submodule update --init --recursive " + $KitDirRel)
        exit 1
    } else {
        $door = 'direct-clone'
    }
} else {
    $door = 'direct-clone'
}

if ($door -eq 'submodule') {
    Invoke-HostGit @('submodule', 'status', '--', $KitDirRel)
    if ($script:gitStatus -ne 0) { Exit-Incomplete 'submodule' 'status' }
    $first = ''
    if ($script:gitOut.Count -gt 0 -and $null -ne $script:gitOut[0]) { $first = [string]$script:gitOut[0] }
    $prefix = if ($first.Length -gt 0) { $first.Substring(0, 1) } else { '' }
    switch ($prefix) {
        ' ' {
            Write-Verdict 'submodule' 'status' 'OK'
            exit 0
        }
        '-' {
            Write-Verdict 'submodule' 'status' 'FAIL'
            Write-Remedy 'submodule' ("Submodule " + $KitDirRel + " is not initialized; run git submodule update --remote --merge " + $KitDirRel)
            exit 1
        }
        '+' {
            Write-Verdict 'submodule' 'status' 'FAIL'
            Write-Remedy 'submodule' ("Submodule " + $KitDirRel + " is out of sync with the recorded commit; run git submodule update --remote --merge " + $KitDirRel)
            exit 1
        }
        'U' {
            Write-Verdict 'submodule' 'status' 'FAIL'
            Write-Remedy 'submodule' ("Submodule " + $KitDirRel + " has unresolved merge conflicts; resolve them or re-run git submodule update --remote --merge " + $KitDirRel)
            exit 1
        }
        '?' {
            Write-Verdict 'submodule' 'status' 'FAIL'
            Write-Remedy 'submodule' ("Submodule " + $KitDirRel + " is not registered as expected; re-run git submodule update --init --recursive " + $KitDirRel)
            exit 1
        }
        default {
            Exit-Incomplete 'submodule' 'status'
        }
    }
}

if ($door -eq 'direct-clone') {
    Invoke-KitGit @('rev-parse', '--show-toplevel')
    $rc = $script:gitStatus
    if ($rc -eq 128) {
        Write-Verdict 'direct-clone' 'repository' 'FAIL'
        Write-Remedy 'direct-clone' 'The kit .git is present but does not resolve to a valid repository; restore the clone or reinstall'
        exit 1
    }
    if ($rc -ne 0) { Exit-Incomplete 'unknown' 'git_probe' }
    $top = ''
    if ($script:gitOut.Count -gt 0 -and $null -ne $script:gitOut[0]) { $top = [string]$script:gitOut[0] }
    if ($top.Length -eq 0) {
        Write-Verdict 'direct-clone' 'repository' 'FAIL'
        Write-Remedy 'direct-clone' 'The kit .git is present but does not resolve to a valid repository; restore the clone or reinstall'
        exit 1
    }
    $topCanon = ''
    try { $topCanon = (Get-Item -LiteralPath $top -Force -ErrorAction Stop).FullName } catch { $topCanon = '' }
    if (Test-PathEqual $topCanon $kitCanon) {
        Write-Verdict 'direct-clone' 'repository' 'OK'
        exit 0
    }
    Write-Verdict 'direct-clone' 'repository' 'FAIL'
    Write-Remedy 'direct-clone' ("The kit resolves to a different repository root (" + $top + "); restore the direct clone")
    exit 1
}

# Unreachable: every branch above exits.
Write-Verdict 'unknown' 'classify' 'INCOMPLETE'
exit 2
