<#
.SYNOPSIS
  scripts/pk.ps1 — thin PromptKit OS entry-point router shim (PowerShell 7 twin).

.DESCRIPTION
  Not a workflow executor: it classifies and prints. `pk route "<text>"` runs the
  ceremony classifier (scripts/pk-route.ps1) verbatim and propagates its exit code.
  Every other trigger is a file-level prompt contract, not a shell executable, so
  an unknown subcommand fails loudly (exit 2) and names workflows/<cmd>.md.

  Zero-Lock-In (PROMPTKIT.md §7): a hand-written shim — not a binary, not an npm
  dependency, not a daemon; no build step and no committed generated artifact.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot

function Show-Usage {
    @'
Usage: pk route "<task text>"     classify a task (delegates to scripts/pk-route.ps1)
       pk --help                  show this message

Only `route` is a shell entry point. Other pk:* triggers are file-level prompt
contracts under workflows/<name>.md; read the named file in your host agent.
'@
}

if ($null -eq $CommandArgs -or $CommandArgs.Count -eq 0) {
    [Console]::Error.WriteLine((Show-Usage))
    exit 2
}

$subcommand = $CommandArgs[0]
switch ($subcommand) {
    'route' {
        $rest = @()
        if ($CommandArgs.Count -gt 1) { $rest = $CommandArgs[1..($CommandArgs.Count - 1)] }
        # A fresh pwsh re-parses $rest, so router switches (-Offline, -Help,
        # -TimeoutSec, -DryRun) bind as named parameters. In-process array
        # splatting would forward them positionally and swallow them into the
        # prompt, diverging from the Bash twin that execs a fresh process.
        & pwsh -NoProfile -File (Join-Path $scriptDir 'pk-route.ps1') @rest
        exit $LASTEXITCODE
    }
    { $_ -in '--help', '-h', 'help' } {
        Show-Usage
        exit 0
    }
    default {
        [Console]::Error.WriteLine("pk: unknown subcommand: $subcommand")
        [Console]::Error.WriteLine("File-level contract: workflows/$subcommand.md")
        [Console]::Error.WriteLine('Only `route` is an executable entry point; the other pk:* triggers are file-level prompt contracts, not shell commands.')
        exit 2
    }
}
