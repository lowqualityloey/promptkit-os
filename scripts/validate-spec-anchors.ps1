#!/usr/bin/env pwsh
# Validate spec anchor citations (PowerShell twin of scripts/validate-spec-anchors.sh).
#
# A spec that cites `path/to/file.ext:142` rots silently: the line number drifts the
# moment an unrelated edit lands above it. This gate accepts content anchors instead --
# `path/to/file.ext` (anchor: `verbatim content`) -- and fails when the cited file no
# longer contains that text.
#
# Usage: pwsh -NoProfile -File scripts/validate-spec-anchors.ps1 [-Root DIR] [Spec...]
#        with no Spec, validates every committed file in docs/specs/.
#
# Exit: 0 all anchors resolve, 1 one or more unresolved, 2 usage/root error.

param(
    [string]$Root = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Spec = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Error "error: root '$Root' is not a directory"
    exit 2
}
$Root = (Resolve-Path -LiteralPath $Root).Path

if (-not $Spec -or $Spec.Count -eq 0) {
    $specDir = Join-Path $Root "docs/specs"
    if (Test-Path -LiteralPath $specDir -PathType Container) {
        $Spec = @(Get-ChildItem -LiteralPath $specDir -File -Filter '*.md' | Sort-Object Name | ForEach-Object { $_.FullName })
    } else {
        $Spec = @()
    }
}

if ($Spec.Count -eq 0) {
    Write-Host "No specification files found to validate."
    exit 0
}

# `path` (anchor: `verbatim`) -- path may contain spaces, so match up to the closing backtick.
# Must match the Bash twin's shape and separator exactly, or the two gates disagree on how
# many citations a spec contains.
$pattern = '`([^`]+)`\s+\(anchor:\s*`([^`]+)`\)'

# A spec that still cites `path.ext:142` is citing a line number, which is the exact rot this
# gate exists to prevent. Reject it outright rather than letting a spec with no anchors pass
# vacuously. The Bash twin counts each distinct citation once per line; match that.
$barePattern = '`[A-Za-z0-9_./-]+\.(sh|ps1|md|js|mjs|json|yml|ymlc):[0-9]+`'

$total = 0
$bad = 0
$bareCount = 0

foreach ($specFile in $Spec) {
    if (-not (Test-Path -LiteralPath $specFile -PathType Leaf)) {
        Write-Error "error: no such spec: $specFile"
        exit 2
    }
    $label = $specFile
    if ($label.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $label = $label.Substring($Root.Length).TrimStart('\', '/')
    }
    $specTotal = 0
    $specBad = 0
    $lineNo = 0
    foreach ($line in (Get-Content -LiteralPath $specFile)) {
        $lineNo++
        # Applied to the whole line, exactly as the Bash twin does, so both count each
        # distinct offending citation once per line.
        $refs = [regex]::Matches($line, $barePattern) |
            ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($r in $refs) {
            $bareCount++
            $specBad++
            Write-Host "  [X] ${label}:${lineNo}  line-number citation $r -- use ``path`` (anchor: ``content``) instead"
        }
        $rest = $line
        while ($true) {
            $m = [regex]::Match($rest, $pattern)
            if (-not $m.Success) { break }
            $path = $m.Groups[1].Value
            $anchor = $m.Groups[2].Value
            $total++
            $specTotal++
            $target = if ([System.IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $Root $path }
            $reason = ""
            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
                $reason = "file not found"
            } else {
                $content = Get-Content -LiteralPath $target -Raw -ErrorAction SilentlyContinue
                if ($null -eq $content -or -not $content.Contains($anchor, [System.StringComparison]::Ordinal)) {
                    $reason = "anchor text absent"
                }
            }
            if ($reason) {
                $bad++
                $specBad++
                Write-Host "  [X] ${label}:${lineNo}  $path -- $reason"
                Write-Host "       anchor: $anchor"
            }
            $rest = $rest.Substring($m.Index + $m.Length)
        }
    }
    if ($specBad -eq 0) {
        Write-Host "  [OK] $label -- $specTotal anchor(s) resolve"
    }
}

Write-Host ""
Write-Host "Anchor citations checked: $total | unresolved: $bad | line-number citations rejected: $bareCount"
if ($bad -gt 0 -or $bareCount -gt 0) {
    Write-Host "[X] spec anchor validation FAILED"
    exit 1
}
Write-Host "[OK] every spec anchor resolves to current content and no line-number citation remains"
exit 0