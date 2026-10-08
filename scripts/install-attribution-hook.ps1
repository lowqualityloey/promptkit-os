<#
.SYNOPSIS
  install-attribution-hook.ps1 — opt-in, reversible commit-msg integration (PowerShell twin).

.DESCRIPTION
  Adds/removes a managed block in the repository's commit-msg hook that runs the
  AI-attribution checker against the pending message. The destination is Git's
  effective hooks directory (honors core.hooksPath and linked worktrees). For sh
  hooks the block is inserted immediately after the shebang so it fires even when
  a pre-existing hook body ends in an unconditional exit; the original body still
  runs afterward when the check passes (chained, content preserved verbatim). For
  non-sh hooks (python, node, ...) the original is preserved verbatim as
  commit-msg.promptkit-orig and a sh wrapper runs the check then execs it, so the
  interpreter is never corrupted. -Remove restores the original byte-for-byte and
  mode-for-mode. Installing and removing are explicit and idempotent. It never
  stages, commits, amends, or rewrites history.

  Exit codes: 0 installed/removed; 2 incomplete (no git repository).
#>
[CmdletBinding()]
param(
    [string]$Root = '.',
    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$checkerSh = (Join-Path $scriptDir 'check-ai-attribution.sh') -replace '\\', '/'
$checkerPs1 = (Join-Path $scriptDir 'check-ai-attribution.ps1') -replace '\\', '/'

$start = '# >>> PROMPTKIT_AI_ATTRIBUTION >>>'
$end = '# <<< PROMPTKIT_AI_ATTRIBUTION <<<'

$gitDir = ''
try { $gitDir = ((& git -C $Root rev-parse --absolute-git-dir 2>$null | Out-String)).Trim() } catch { $gitDir = '' }
if ([string]::IsNullOrEmpty($gitDir)) {
    Write-Output 'AI_ATTRIBUTION_HOOK|INCOMPLETE|NO_REPO|.'
    exit 2
}

function Get-RepoTopLevel {
    $top = ''
    try { $top = ((& git -C $Root rev-parse --show-toplevel 2>$null | Out-String)).Trim() } catch { $top = '' }
    if ([string]::IsNullOrEmpty($top)) { return $Root }
    return $top
}

function Test-AbsolutePath {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return $false }
    if ($Value.StartsWith('/')) { return $true }
    if ($Value -match '^[A-Za-z]:[\\/]') { return $true }
    return $false
}

$hookDir = ''
try { $hookDir = ((& git -C $Root rev-parse --path-format=absolute --git-path hooks 2>$null | Out-String)).Trim() } catch { $hookDir = '' }
if ([string]::IsNullOrEmpty($hookDir)) {
    $hooksCfg = ''
    try { $hooksCfg = ((& git -C $Root config --get core.hooksPath 2>$null | Out-String)).Trim() } catch { $hooksCfg = '' }
    if (-not [string]::IsNullOrEmpty($hooksCfg)) { $hookDir = $hooksCfg }
}
if ([string]::IsNullOrEmpty($hookDir)) { $hookDir = Join-Path $gitDir 'hooks' }
elseif ($hookDir.StartsWith('~/')) { $hookDir = Join-Path $HOME $hookDir.Substring(2) }
if (-not (Test-AbsolutePath $hookDir)) {
    $top = Get-RepoTopLevel
    $hookDir = ($top.TrimEnd('\', '/')) + '/' + ($hookDir.TrimEnd('\', '/'))
}
$hookPath = Join-Path $hookDir 'commit-msg'
$origPath = "$hookPath.promptkit-orig"

function Get-ShebangInterpreter {
    param([string]$Line)
    if ([string]::IsNullOrEmpty($Line) -or -not $Line.StartsWith('#!')) { return '' }
    $rest = $Line.Substring(2).TrimStart()
    if ([string]::IsNullOrEmpty($rest)) { return '' }
    $parts = @($rest -split '\s+')
    $base = [System.IO.Path]::GetFileName($parts[0])
    if ($base -eq 'env') {
        $i = 1
        while ($i -lt $parts.Count) {
            $w = $parts[$i]
            if ($w.StartsWith('-') -or $w.Contains('=')) { $i++; continue }
            $base = [System.IO.Path]::GetFileName($w)
            break
        }
    }
    return $base
}

function Test-IsShellInterpreter {
    param([string]$Name)
    return @('sh', 'bash', 'dash', 'ash', 'ksh', 'mksh', 'zsh', 'posh', 'busybox') -contains $Name
}

function Remove-ManagedBlock {
    param([string[]]$Lines)
    $out = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    foreach ($line in $Lines) {
        if ($line -ceq $start) { $inBlock = $true; continue }
        if ($inBlock -and $line -ceq $end) { $inBlock = $false; continue }
        if (-not $inBlock) { $out.Add($line) }
    }
    return $out
}

if ($Remove) {
    if ((Test-Path -LiteralPath $hookPath -PathType Leaf)) {
        $rawText = Get-Content -LiteralPath $hookPath -Raw -ErrorAction SilentlyContinue
        $lines = @()
        if ($null -ne $rawText) { $lines = @($rawText -split "`n") }
        if ($lines -contains $start) {
            if (Test-Path -LiteralPath $origPath -PathType Leaf) {
                Move-Item -LiteralPath $origPath -Destination $hookPath -Force
            } else {
                $kept = Remove-ManagedBlock -Lines $lines
                $meaningful = @($kept | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^#!' })
                if ($meaningful.Count -eq 0) {
                    Remove-Item -LiteralPath $hookPath -Force
                } else {
                    [IO.File]::WriteAllText($hookPath, (($kept -join "`n")), [Text.UTF8Encoding]::new($false))
                }
            }
            Write-Output "AI_ATTRIBUTION_HOOK|REMOVED|$hookPath"
        } else {
            Write-Output "AI_ATTRIBUTION_HOOK|ABSENT|$hookPath"
        }
    } else {
        Write-Output "AI_ATTRIBUTION_HOOK|ABSENT|$hookPath"
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $hookDir)) { New-Item -ItemType Directory -Path $hookDir -Force | Out-Null }

# A pre-existing non-shell hook cannot host the POSIX block under its shebang;
# keep the original verbatim and let a sh wrapper chain to it instead.
$rawExisting = ''
$hasBlock = $false
if (Test-Path -LiteralPath $hookPath -PathType Leaf) {
    $rawExisting = Get-Content -LiteralPath $hookPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $rawExisting) { $rawExisting = '' }
    $hasBlock = $rawExisting.Contains($start)
    if (-not $hasBlock) {
        $existingLines = @($rawExisting -split "`n")
        if ($existingLines.Count -gt 0) {
            $interp = Get-ShebangInterpreter $existingLines[0]
            if (-not [string]::IsNullOrEmpty($interp) -and -not (Test-IsShellInterpreter $interp)) {
                $copied = $false
                try { & cp -p -- $hookPath $origPath 2>$null; if ($LASTEXITCODE -eq 0) { $copied = $true } } catch { $copied = $false }
                if (-not $copied) { Copy-Item -LiteralPath $hookPath -Destination $origPath -Force }
            }
        }
    }
}

if (Test-Path -LiteralPath $origPath -PathType Leaf) {
    $origSh = $origPath -replace '\\', '/'
    $origToken = '__PK_ATTR_ORIG__'
    $wrapper = @(
        '#!/bin/sh',
        $start,
        '# Managed by PromptKit OS. Remove with scripts/install-attribution-hook.ps1 -Remove.',
        '__pk_attr_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"',
        "__pk_attr_sh=""$checkerSh""",
        "__pk_attr_ps1=""$checkerPs1""",
        "__pk_attr_orig=""$origToken""",
        'if command -v bash >/dev/null 2>&1 && [ -f "$__pk_attr_sh" ]; then',
        '  bash "$__pk_attr_sh" --root "$__pk_attr_root" --message-file "$1" || exit 1',
        'elif command -v pwsh >/dev/null 2>&1 && [ -f "$__pk_attr_ps1" ]; then',
        '  pwsh -NoProfile -File "$__pk_attr_ps1" -Root "$__pk_attr_root" -MessageFile "$1" || exit 1',
        'fi',
        $end,
        'if [ -x "$__pk_attr_orig" ]; then',
        '  exec "$__pk_attr_orig" "$@"',
        'fi',
        '__pk_attr_shebang="$(head -n 1 "$__pk_attr_orig" 2>/dev/null || true)"',
        'case "$__pk_attr_shebang" in',
        '  ''#!''*) exec ${__pk_attr_shebang#\#!} "$__pk_attr_orig" "$@" ;;',
        '  *) exec /bin/sh "$__pk_attr_orig" "$@" ;;',
        'esac'
    )
    $wrapperText = ((($wrapper -join "`n") + "`n")).Replace($origToken, $origSh)
    [IO.File]::WriteAllText($hookPath, $wrapperText, [Text.UTF8Encoding]::new($false))
    try { & chmod +x $hookPath 2>$null } catch { }
    Write-Output "AI_ATTRIBUTION_HOOK|INSTALLED|$hookPath"
    exit 0
}

$shebang = '#!/bin/sh'
$body = @()
if (Test-Path -LiteralPath $hookPath -PathType Leaf) {
    $existing = @($rawExisting -split "`n")
    if ($existing.Count -gt 0 -and $existing[0].StartsWith('#!')) {
        $shebang = $existing[0]
        $body = @(Remove-ManagedBlock -Lines @($existing | Select-Object -Skip 1))
    } else {
        $body = @(Remove-ManagedBlock -Lines $existing)
    }
}

$block = @(
    $shebang,
    $start,
    '# Managed by PromptKit OS. Remove with scripts/install-attribution-hook.ps1 -Remove.',
    '__pk_attr_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"',
    "__pk_attr_sh=""$checkerSh""",
    "__pk_attr_ps1=""$checkerPs1""",
    'if command -v bash >/dev/null 2>&1 && [ -f "$__pk_attr_sh" ]; then',
    '  bash "$__pk_attr_sh" --root "$__pk_attr_root" --message-file "$1" || exit 1',
    'elif command -v pwsh >/dev/null 2>&1 && [ -f "$__pk_attr_ps1" ]; then',
    '  pwsh -NoProfile -File "$__pk_attr_ps1" -Root "$__pk_attr_root" -MessageFile "$1" || exit 1',
    'fi',
    $end
)

$all = @($block) + @($body)
[IO.File]::WriteAllText($hookPath, ($all -join "`n"), [Text.UTF8Encoding]::new($false))
try { & chmod +x $hookPath 2>$null } catch { }

Write-Output "AI_ATTRIBUTION_HOOK|INSTALLED|$hookPath"
exit 0
