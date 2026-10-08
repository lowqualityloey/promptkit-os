<#
.SYNOPSIS
  install-attribution-hook.ps1 — opt-in, reversible commit-msg integration (PowerShell twin).

.DESCRIPTION
  Adds/removes a managed block in the repository's commit-msg hook that runs the
  AI-attribution checker against the pending message. The block is inserted
  immediately after the shebang so it fires even when a pre-existing hook body
  ends in an unconditional exit; the original body still runs afterward when the
  check passes (chained, content preserved verbatim). -Remove strips only the
  managed block. Installing/removing is explicit and idempotent. It never stages,
  commits, amends, or rewrites history.

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

$hookDir = Join-Path $gitDir 'hooks'
$hookPath = Join-Path $hookDir 'commit-msg'

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
            $kept = Remove-ManagedBlock -Lines $lines
            $meaningful = @($kept | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^#!' })
            if ($meaningful.Count -eq 0) {
                Remove-Item -LiteralPath $hookPath -Force
            } else {
                [IO.File]::WriteAllText($hookPath, (($kept -join "`n")), [Text.UTF8Encoding]::new($false))
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

$shebang = '#!/bin/sh'
$body = @()
if (Test-Path -LiteralPath $hookPath -PathType Leaf) {
    $existing = @(Get-Content -LiteralPath $hookPath -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0 -and $existing[0].StartsWith('#!')) {
        $shebang = $existing[0]
        $body = @(Remove-ManagedBlock -Lines ($existing[1..($existing.Count - 1)]))
    } else {
        $body = @(Remove-ManagedBlock -Lines $existing)
    }
}

$block = @(
    $shebang,
    '',
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
    $end,
    ''
)

$all = @($block) + @($body)
[IO.File]::WriteAllText($hookPath, ($all -join "`n"), [Text.UTF8Encoding]::new($false))
try { & chmod +x $hookPath 2>$null } catch { }

Write-Output "AI_ATTRIBUTION_HOOK|INSTALLED|$hookPath"
exit 0
