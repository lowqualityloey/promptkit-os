# check-ai-attribution.ps1 — repository-level AI attribution policy check (read-only).
#
# Reads the optional `ai-attribution: off|host-default` preference from
# PROMPTKIT.md. `off` scans a prepared payload and fails on an unsolicited AI
# signature; a missing line or `host-default` skips without newly blocking.
#
# The payload is a commit message (-MessageFile), a prepared PR/issue body
# (-BodyFile), or stdin (-Stdin). Read-only by construction: it never stages,
# commits, amends, rewrites history, or edits the payload.
#
# Exit codes: 0 clean or skipped; 1 prohibited signature found; 2 incomplete
# (unreadable/malformed rules file, bad preference value, or unreadable payload).

[CmdletBinding()]
param(
    [string]$Root = '.',
    [string]$RulesFile = '',
    [string]$PreferenceFile = '',
    [string]$MessageFile = '',
    [string]$BodyFile = '',
    [switch]$Stdin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot

function ConvertTo-Sanitized { param([string]$Value) return ($Value -replace '[\r\n|]', ' ') }

function Show-Usage {
    [Console]::Error.WriteLine('Usage: scripts/check-ai-attribution.ps1 [-Root PATH] [-RulesFile PATH]')
    [Console]::Error.WriteLine('       (-MessageFile PATH | -BodyFile PATH | -Stdin)')
}

if ([string]::IsNullOrEmpty($RulesFile)) { $RulesFile = Join-Path $scriptDir 'ai-attribution-patterns.txt' }
if ([string]::IsNullOrEmpty($PreferenceFile)) { $PreferenceFile = Join-Path $Root 'PROMPTKIT.md' }

# Preference: absent, unknown, or unreadable resolves to host-default (never
# newly blocking). Only `off` enforces; an unparseable value fails closed.
$preference = 'host-default'
if ((Test-Path -LiteralPath $PreferenceFile -PathType Leaf)) {
    try { $prefText = Get-Content -LiteralPath $PreferenceFile -Raw -ErrorAction Stop } catch { $prefText = '' }
    if ($null -ne $prefText) {
        $prefMatches = [regex]::Matches($prefText, '(?m)^[ \t]*ai-attribution:[ \t]*(\S*)')
        if ($prefMatches.Count -gt 0) {
            $prefValue = $prefMatches[$prefMatches.Count - 1].Groups[1].Value
            switch ($prefValue) {
                'off' { $preference = 'off' }
                { $_ -in '', 'host-default' } { $preference = 'host-default' }
                default { Write-Output ("AI_ATTRIBUTION|INCOMPLETE|preference|" + (ConvertTo-Sanitized $prefValue)); exit 2 }
            }
        }
    }
}

if ($preference -ne 'off') {
    Write-Output ("AI_ATTRIBUTION|SKIP|host-default|" + (ConvertTo-Sanitized $PreferenceFile))
    exit 0
}

if (-not (Test-Path -LiteralPath $RulesFile -PathType Leaf)) {
    Write-Output ("AI_ATTRIBUTION|INCOMPLETE|RULES|" + (ConvertTo-Sanitized $RulesFile))
    exit 2
}

$payload = ''
if ($Stdin) {
    $payload = [Console]::In.ReadToEnd()
} else {
    $chosen = if (-not [string]::IsNullOrEmpty($MessageFile)) { $MessageFile } else { $BodyFile }
    if ([string]::IsNullOrEmpty($chosen)) { Show-Usage; exit 2 }
    if (-not (Test-Path -LiteralPath $chosen -PathType Leaf)) {
        Write-Output ("AI_ATTRIBUTION|INCOMPLETE|PAYLOAD|" + (ConvertTo-Sanitized $chosen))
        exit 2
    }
    try { $payload = Get-Content -LiteralPath $chosen -Raw -ErrorAction Stop } catch {
        Write-Output ("AI_ATTRIBUTION|INCOMPLETE|PAYLOAD|" + (ConvertTo-Sanitized $chosen))
        exit 2
    }
    if ($null -eq $payload) { $payload = '' }
}

$rulesFiles = [System.Collections.Generic.List[string]]::new()
$rulesFiles.Add($RulesFile)
if (-not [string]::IsNullOrWhiteSpace($env:PROMPTKIT_AI_ATTRIBUTION_RULES_EXTRA)) {
    foreach ($extra in ($env:PROMPTKIT_AI_ATTRIBUTION_RULES_EXTRA -split '\s+')) {
        if (-not [string]::IsNullOrWhiteSpace($extra)) { $rulesFiles.Add($extra) }
    }
}

$matchedRule = ''
$matchedTier = ''
$matchedLine = ''
foreach ($rf in $rulesFiles) {
    if (-not (Test-Path -LiteralPath $rf -PathType Leaf)) {
        Write-Output ("AI_ATTRIBUTION|INCOMPLETE|RULES|" + (ConvertTo-Sanitized $rf))
        exit 2
    }
    $rawLines = @(Get-Content -LiteralPath $rf -ErrorAction Stop)
    foreach ($raw in $rawLines) {
        $line = ([string]$raw).TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith('#')) { continue }
        $fields = $line.Split('|')
        if ($fields.Count -ne 3 -or [string]::IsNullOrEmpty($fields[0]) -or [string]::IsNullOrEmpty($fields[1]) -or [string]::IsNullOrEmpty($fields[2])) {
            Write-Output ("AI_ATTRIBUTION|INCOMPLETE|RULES|" + (ConvertTo-Sanitized $line))
            exit 2
        }
        $ruleId = $fields[0]
        $ruleRegex = $fields[1]
        $ruleTier = $fields[2]
        try {
            $match = [regex]::Match($payload, $ruleRegex, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        } catch {
            Write-Output ("AI_ATTRIBUTION|INCOMPLETE|RULES|" + (ConvertTo-Sanitized $line))
            exit 2
        }
        if ($match.Success) {
            $matchedRule = $ruleId
            $matchedTier = $ruleTier
            $lineNo = (($payload.Substring(0, $match.Index) -split "`n").Count)
            $allLines = $payload -split "`n"
            $lineText = if ($lineNo -ge 1 -and $lineNo -le $allLines.Count) { $allLines[$lineNo - 1] } else { $match.Value }
            $matchedLine = "$lineNo`:$lineText"
            break
        }
    }
    if (-not [string]::IsNullOrEmpty($matchedRule)) { break }
}

if (-not [string]::IsNullOrEmpty($matchedRule)) {
    Write-Output ("AI_ATTRIBUTION|PROHIBITED|$matchedRule|$matchedTier|" + (ConvertTo-Sanitized $matchedLine))
    Write-Output 'AI_ATTRIBUTION|REMEDIATION|Remove or rewrite the matched AI signature; keep legitimate human co-authors and required notices (scripts/ai-attribution-patterns.txt)'
    exit 1
}

$payloadName = if ($Stdin) { '-' } elseif (-not [string]::IsNullOrEmpty($MessageFile)) { $MessageFile } else { $BodyFile }
Write-Output ("AI_ATTRIBUTION|OK|" + (ConvertTo-Sanitized $payloadName))
exit 0
