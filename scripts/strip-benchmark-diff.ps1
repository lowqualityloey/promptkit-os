<#
.SYNOPSIS
    PromptKit OS Benchmark Diff Stripper (PowerShell)
.DESCRIPTION
    Filters a unified diff (as produced by git diff between a benchmark run's
    seed and post-run states) so blind graders see code changes only: whole
    file sections for PromptKit framework artifacts are dropped —
    PROMPTKIT.md, AGENTS.md, docs/STATE.md, docs/tasks/, docs/specs/,
    .promptkit/, .github/pull_request_template.md, and .github/ISSUE_TEMPLATE/.
    Everything else passes through verbatim. The Bash twin reaches identical
    verdicts from identical input.

    Known limitation (v1): section paths are taken from the trailing b/
    operand of each `diff --git` line, so quoted paths containing spaces are
    not parsed.
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0)][string]$TargetPath
)

$ErrorActionPreference = "Stop"
$DropPatterns = @("PROMPTKIT.md", "AGENTS.md", "docs/STATE.md", "docs/tasks/", "docs/specs/", "docs/adrs/", "docs/reviews/", "docs/releases/", "docs/tests/", ".promptkit/", ".promptkit", ".github/pull_request_template.md", ".github/ISSUE_TEMPLATE/")

function Show-Usage {
    Write-Host "Usage: strip-benchmark-diff.ps1 -TargetPath <run.diff>"
    Write-Host "Drops PromptKit-artifact file sections from a unified diff and prints"
    Write-Host "the code-change diff on stdout; a STRIP|... status line goes to stderr."
    Write-Host "Exit 0 on success; exit 2 on empty/non-diff input."
}

function Write-StripError {
    param ([string]$Kind, [string]$Detail)
    [Console]::Error.WriteLine("STRIP|ERROR|$Kind|$Detail")
    exit 2
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    Show-Usage
    exit 2
}
if (-not (Test-Path $TargetPath) -or (Get-Item $TargetPath).Length -eq 0) {
    Write-StripError "UNREADABLE" $TargetPath
}
$firstLine = (Get-Content $TargetPath | Where-Object { $_ -match '\S' } | Select-Object -First 1)
if ($null -eq $firstLine -or -not $firstLine.StartsWith("diff --git ")) {
    Write-StripError "NOT_A_DIFF" $TargetPath
}

function Test-Artifact {
    param ([string]$Path)
    foreach ($p in $DropPatterns) {
        if ($p.EndsWith("/")) {
            if ($Path.StartsWith($p, [System.StringComparison]::Ordinal)) { return $true }
        } elseif ($Path -eq $p) {
            return $true
        }
    }
    return $false
}

$inFiles = 0; $outFiles = 0; $dropped = 0
$buf = New-Object System.Collections.Generic.List[string]
$keep = $false

foreach ($line in (Get-Content $TargetPath)) {
    if ($line.StartsWith("diff --git ")) {
        if ($inFiles -gt 0) {
            if ($keep) { $buf | ForEach-Object { Write-Output $_ }; $outFiles++ } else { $dropped++ }
            $buf = New-Object System.Collections.Generic.List[string]
        }
        $inFiles++
        $path = ($line -split '\s+')[-1]
        $path = $path -replace '^b/', ''
        $keep = -not (Test-Artifact -Path $path)
    }
    $buf.Add($line)
}
if ($inFiles -gt 0) {
    if ($keep) { $buf | ForEach-Object { Write-Output $_ }; $outFiles++ } else { $dropped++ }
}
[Console]::Error.WriteLine("STRIP|OK|in_files=$inFiles|out_files=$outFiles|dropped=$dropped")
exit 0
