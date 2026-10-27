# install-benchmark-task-card-hook.ps1 - opt-in, reversible pre-commit gate.
#
# Adds/removes a managed block in the repository's pre-commit hook that runs
# scripts\check-benchmark-task-cards.sh when the staged set touches a
# benchmarks\tasks\TASK-*.md card, so a card whose Verify command orders the
# suite before the probe (or chains them with &&) fails locally instead of in
# CI. The destination is Git's effective hooks directory (honors
# core.hooksPath and linked worktrees). For sh hooks the block is inserted
# immediately after the shebang so it fires even when a pre-existing hook body
# ends in an unconditional `exit 0`; the original body still runs afterward
# when the gate passes (chained, content preserved verbatim). For non-sh hooks
# (python, node, ...) the original is preserved verbatim as
# pre-commit.promptkit-orig and a sh wrapper runs the gate then execs it, so the
# interpreter is never corrupted. -Remove restores the original byte-for-byte
# and mode-for-mode. Installing and removing are explicit and idempotent. It
# never stages, commits, amends, or rewrites history.
#
# The gate is scoped to the staged card set: a commit that touches no card runs
# the hook as a no-op, so unrelated work is never blocked by a card elsewhere in
# the tree. Each staged card is read from Git's index - `git show :<path>` - into
# a throwaway tree and the checker runs there, so a partially staged card is
# judged by the bytes the commit will carry, not by the working-tree copy, and a
# broken card left unstaged elsewhere cannot block the commit.
#
# Exit codes: 0 installed/removed; 2 incomplete (no git repository).

$Root = '.'
$Remove = $false
$i = 0
while ($i -lt $args.Count) {
    $a = [string]$args[$i]
    if ($a -eq '-h' -or $a -eq '--help') {
        Write-Host 'Usage: scripts/install-benchmark-task-card-hook.ps1 [-Root PATH] [-Remove]'
        exit 0
    }
    elseif ($a -eq '-Root' -or $a -eq '--root') {
        if ($i + 1 -ge $args.Count) {
            Write-Host "$a requires a path"
            exit 2
        }
        $Root = [string]$args[$i + 1]
        $i += 2
    }
    elseif ($a -like '-Root=*') { $Root = $a.Substring(6); $i += 1 }
    elseif ($a -like '--root=*') { $Root = $a.Substring(7); $i += 1 }
    elseif ($a -eq '-Remove' -or $a -eq '--remove') { $Remove = $true; $i += 1 }
    else {
        Write-Host "Usage: scripts/install-benchmark-task-card-hook.ps1 [-Root PATH] [-Remove]"
        Write-Host "Unknown argument: $a"
        exit 2
    }
}

$scriptDir = $PSScriptRoot
$checkerSh = (Join-Path $scriptDir 'check-benchmark-task-cards.sh') -replace '\\', '/'
$checkerPs1 = (Join-Path $scriptDir 'check-benchmark-task-cards.ps1') -replace '\\', '/'

$start = '# >>> PROMPTKIT_TASK_CARD_GATE >>>'
$end = '# <<< PROMPTKIT_TASK_CARD_GATE <<<'

function Get-GitValue {
    param([string[]]$Arguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = (& git -C $Root @Arguments 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) { return $null }
        return $out
    }
    catch { return $null }
    finally { $ErrorActionPreference = $previous }
}

$gitDir = Get-GitValue @('rev-parse', '--absolute-git-dir')
if ([string]::IsNullOrEmpty($gitDir)) {
    Write-Output 'TASK_CARD_HOOK|INCOMPLETE|NO_REPO|.'
    exit 2
}

# Git's effective hooks directory: rev-parse applies core.hooksPath and resolves
# linked worktrees to the shared common dir; the explicit fallbacks cover Git
# without --path-format.
$hookDir = Get-GitValue @('rev-parse', '--path-format=absolute', '--git-path', 'hooks')
if ([string]::IsNullOrEmpty($hookDir)) { $hookDir = Get-GitValue @('config', '--get', 'core.hooksPath') }
if ([string]::IsNullOrEmpty($hookDir)) { $hookDir = Join-Path $gitDir 'hooks' }
elseif ($hookDir.StartsWith('~/')) { $hookDir = Join-Path $HOME $hookDir.Substring(2) }
$isAbsolute = ($hookDir -match '^([A-Za-z]:[\\/]|\\\\|/)')
if (-not $isAbsolute) {
    $top = Get-GitValue @('rev-parse', '--show-toplevel')
    if ([string]::IsNullOrEmpty($top)) { $top = $Root }
    $hookDir = ($top.TrimEnd('\', '/')) + '/' + ($hookDir.TrimEnd('\', '/'))
}
$hookDir = $hookDir.TrimEnd('\', '/')
$hookPath = Join-Path $hookDir 'pre-commit'
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

function Test-ManagedStart {
    param([string[]]$Lines)
    foreach ($line in $Lines) {
        if ($line.TrimEnd("`r") -ceq $start) { return $true }
    }
    return $false
}

function Remove-ManagedBlock {
    param([string[]]$Lines)
    $kept = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    foreach ($line in $Lines) {
        # A CRLF hook carries \r on every line; compare the trimmed copy so a
        # Windows-edited hook is still recognized, and keep the original line.
        $trimmed = $line.TrimEnd("`r")
        if ($trimmed -ceq $start) { $inBlock = $true; continue }
        if ($inBlock -and $trimmed -ceq $end) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }
    return $kept
}

function Get-BlockLines {
    param([string]$OrigSh)
    return @(
        '# Managed by PromptKit OS. Remove with scripts/install-benchmark-task-card-hook.ps1 -Remove.',
        '__pk_card_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"',
        ('__pk_card_sh="' + $checkerSh + '"'),
        ('__pk_card_ps1="' + $checkerPs1 + '"'),
        ('__pk_card_orig="' + $OrigSh + '"'),
        '__pk_card_staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E ''^benchmarks/tasks/TASK-.*\.md$'' || true)"',
        'if [ -n "$__pk_card_staged" ]; then',
        '  __pk_card_rc=0',
        '  __pk_card_unreadable=0',
        '  __pk_card_tmp="$(mktemp -d 2>/dev/null || true)"',
        '  if [ -z "$__pk_card_tmp" ] || ! mkdir -p "$__pk_card_tmp/benchmarks/tasks"; then',
        '    __pk_card_rc=1',
        '    __pk_card_unreadable=1',
        '  else',
        '    # Judge the staged bytes, not the working tree. The heredoc body and its',
        '    # delimiter stay unindented because POSIX sh requires that.',
        '    while IFS= read -r __pk_card_path; do',
        '      [ -n "$__pk_card_path" ] || continue',
        '      git -C "$__pk_card_root" show ":$__pk_card_path" > "$__pk_card_tmp/$__pk_card_path" 2>/dev/null || { __pk_card_rc=1; __pk_card_unreadable=1; }',
        '    done <<__PK_CARD_EOF',
        '$__pk_card_staged',
        '__PK_CARD_EOF',
        '    if [ "$__pk_card_rc" -eq 0 ]; then',
        '      if command -v bash >/dev/null 2>&1 && [ -f "$__pk_card_sh" ]; then',
        '        bash "$__pk_card_sh" --root "$__pk_card_tmp" || __pk_card_rc=$?',
        '      elif command -v pwsh >/dev/null 2>&1 && [ -f "$__pk_card_ps1" ]; then',
        '        pwsh -NoProfile -File "$__pk_card_ps1" -Root "$__pk_card_tmp" || __pk_card_rc=$?',
        '      fi',
        '    fi',
        '  fi',
        '  [ -n "$__pk_card_tmp" ] && rm -rf -- "$__pk_card_tmp"',
        '  if [ "$__pk_card_rc" -ne 0 ]; then',
        '    if [ "$__pk_card_unreadable" -eq 1 ]; then',
        '      echo "[promptkit] could not read a staged benchmark task card from the index; commit blocked." >&2',
        '    else',
        '      echo "[promptkit] a staged benchmark task card breaks the Verify convention: run the behavioral probe first, run the test suite second, and do not chain them with && or ||." >&2',
        '      echo "[promptkit] see benchmarks/tasks/TEMPLATE-task.md. Commit blocked." >&2',
        '    fi',
        '    exit 1',
        '  fi',
        'fi'
    )
}

if ($Remove) {
    if (Test-Path -LiteralPath $hookPath -PathType Leaf) {
        $rawText = Get-Content -LiteralPath $hookPath -Raw -ErrorAction SilentlyContinue
        $lines = @()
        if ($null -ne $rawText) { $lines = @($rawText -split "`n") }
        if (Test-ManagedStart -Lines $lines) {
            if (Test-Path -LiteralPath $origPath -PathType Leaf) {
                Move-Item -LiteralPath $origPath -Destination $hookPath -Force
            }
            else {
                $kept = Remove-ManagedBlock -Lines $lines
                $meaningful = @($kept | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^#!' })
                if ($meaningful.Count -eq 0) {
                    Remove-Item -LiteralPath $hookPath -Force
                }
                else {
                    $newline = if ($rawText.Contains("`r`n")) { "`r`n" } else { "`n" }
                    $keptBody = @($kept | ForEach-Object { $_.TrimEnd("`r") })
                    [IO.File]::WriteAllText($hookPath, ($keptBody -join $newline), [Text.UTF8Encoding]::new($false))
                }
            }
            Write-Output "TASK_CARD_HOOK|REMOVED|$hookPath"
        }
        else {
            Write-Output "TASK_CARD_HOOK|ABSENT|$hookPath"
        }
    }
    else {
        Write-Output "TASK_CARD_HOOK|ABSENT|$hookPath"
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $hookDir)) { New-Item -ItemType Directory -Path $hookDir -Force | Out-Null }

# A pre-existing non-shell hook cannot host the POSIX block under its shebang;
# keep the original verbatim and let a sh wrapper chain to it instead.
$rawExisting = ''
if (Test-Path -LiteralPath $hookPath -PathType Leaf) {
    $rawExisting = Get-Content -LiteralPath $hookPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $rawExisting) { $rawExisting = '' }
    if (-not $rawExisting.Contains($start)) {
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
    $wrapper = @('#!/bin/sh', '') + @($start) + @(Get-BlockLines -OrigSh $origSh) + @($end) + @(
        '',
        'if [ -x "$__pk_card_orig" ]; then',
        '  exec "$__pk_card_orig" "$@"',
        'fi',
        '__pk_card_shebang="$(head -n 1 "$__pk_card_orig" 2>/dev/null || true)"',
        'case "$__pk_card_shebang" in',
        '  ''#!''*) exec ${__pk_card_shebang#\#!} "$__pk_card_orig" "$@" ;;',
        '  *) exec /bin/sh "$__pk_card_orig" "$@" ;;',
        'esac'
    )
    $wrapperText = (($wrapper -join "`n") + "`n")
    [IO.File]::WriteAllText($hookPath, $wrapperText, [Text.UTF8Encoding]::new($false))
    try { & chmod +x $hookPath 2>$null } catch { }
    Write-Output "TASK_CARD_HOOK|INSTALLED|$hookPath"
    exit 0
}

$shebang = '#!/bin/sh'
$body = @()
if (Test-Path -LiteralPath $hookPath -PathType Leaf) {
    $existing = @($rawExisting -split "`n")
    if ($existing.Count -gt 0 -and $existing[0].StartsWith('#!')) {
        $shebang = $existing[0]
        $body = @(Remove-ManagedBlock -Lines @($existing | Select-Object -Skip 1))
    }
    else {
        $body = @(Remove-ManagedBlock -Lines $existing)
    }
}

# Normalize the tail so a second install is byte-identical: no trailing blank
# lines, exactly one terminating newline.
while ($body.Count -gt 0 -and $body[$body.Count - 1] -eq '') {
    $body = @($body | Select-Object -First ($body.Count - 1))
}
$all = @($shebang) + @($start) + @(Get-BlockLines -OrigSh '') + @($end) + @($body)
[IO.File]::WriteAllText($hookPath, ((($all -join "`n") + "`n")), [Text.UTF8Encoding]::new($false))
try { & chmod +x $hookPath 2>$null } catch { }

Write-Output "TASK_CARD_HOOK|INSTALLED|$hookPath"
exit 0
