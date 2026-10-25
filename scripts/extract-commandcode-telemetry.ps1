<#
.SYNOPSIS
    PromptKit OS Command Code Telemetry Extractor (PowerShell)
.DESCRIPTION
    Converts a Command Code session transcript (JSONL, schema v3, as written
    under ~/.commandcode/projects/<slug>/<session>.jsonl) into the standardized
    telemetry record defined in docs/BENCHMARK-METHODOLOGY.md §5, for scoring by
    scripts/measure-cpac.ps1. The Bash twin reaches identical field values from
    identical input.

    v1 mapping and known approximations (documented in BENCHMARK-METHODOLOGY §5):
    - tokens_in/tokens_out sum usage over SUCCESSFUL assistant turns; a turn whose
      tool results since the previous assistant turn include a failure (per the
      error-pattern heuristic) is a rework turn (rework_tokens_in/out).
    - Command Code schema v3 records no tool exit codes, so failed loops are a
      documented heuristic over tool_result text (default patterns below,
      overridable with -ErrorPatterns "a|b").
    - cache_read_tokens is reported but excluded from C_inference (the §5
      pricing model has no cache-read price; this is the v1 convention).
    - human_interventions counts user prompts after the first.
    - tool_calls_search/edit/verify classify tool names and shell commands with
      best-effort keyword rules; the remainder is tool_calls_other.
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0)][string]$TranscriptPath,
    [string]$ScenarioId = "",
    [string]$Condition = "unspecified",
    [ValidateSet("true", "false")][string]$Accepted = "false",
    [int]$InvariantsChecked = 0,
    [int]$InvariantsPassed = 0,
    [string]$ErrorPatterns = "No tool named|command not found|Error:|error:|ERROR:|Traceback|Exception|Permission denied|FAILED|npm ERR!"
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: extract-commandcode-telemetry.ps1 -TranscriptPath <session.jsonl> [options]"
    Write-Host "Options:"
    Write-Host "  -ScenarioId ID           §5 scenario_id (default: the session id)"
    Write-Host "  -Condition NAME          §5 condition label (default: unspecified)"
    Write-Host "  -Accepted true|false     §5 accepted gate (default: false — acceptance is a human judgment)"
    Write-Host "  -InvariantsChecked N     §5 invariants_checked (default: 0)"
    Write-Host "  -InvariantsPassed N      §5 invariants_passed (default: 0)"
    Write-Host "  -ErrorPatterns 'a|b'     rework-loop detection patterns (default: built-in list)"
}

if ([string]::IsNullOrWhiteSpace($TranscriptPath)) {
    Show-Usage
    exit 2
}
if ([string]::IsNullOrWhiteSpace($ErrorPatterns)) {
    [Console]::Error.WriteLine("EXTRACT|ERROR|BAD_VALUE|error-patterns")
    exit 2
}
foreach ($strval in @($ScenarioId, $Condition)) {
    if ($strval -match '[\"\\]') {
        [Console]::Error.WriteLine("EXTRACT|ERROR|BAD_VALUE|scenario-or-condition")
        exit 2
    }
}
if (-not (Test-Path $TranscriptPath) -or (Get-Item $TranscriptPath).Length -eq 0) {
    [Console]::Error.WriteLine("EXTRACT|ERROR|NOT_FOUND|$TranscriptPath")
    exit 2
}

$patterns = $ErrorPatterns -split '\|'

function Classify-Tool {
    # Mirrors the Bash twin's keyword rules exactly (same lists, same order).
    param ([string]$Name, [string]$Tail)
    if ($Name -match '^(read|grep|glob|list|fd|search|view|ls)') { return "search" }
    if ($Name -match '^(edit|write|apply|multiedit|create|notebook)') { return "edit" }
    if ($Name -match '^(shell|bash|terminal|exec|run)') {
        $m = [regex]::Match($Tail, '"command":"[^"]*')
        if ($m.Success) {
            $cmd = $m.Value
            if ($cmd -match 'test|jest|vitest|pytest|cargo|make|gradle|mvn|tsc|eslint|ruff|lint|check|audit|compile|build') { return "verify" }
            if ($cmd -match 'grep|rg |fd |find|ls |cat|head|tail|glob|list') { return "search" }
            if ($cmd -match 'sed -i|patch|tee |mkdir|touch|mv |cp |rm |chmod|truncate') { return "edit" }
        }
        return "other"
    }
    return "other"
}

$seen = $false
$sessionId = ""
$model = "unknown"
$firstTs = ""
$lastTs = ""
$succIn = 0; $succOut = 0; $rewIn = 0; $rewOut = 0
$cache = 0; $cost = 0.0
$loops = 0; $accumFail = $false
$toolTotal = 0; $toolSearch = 0; $toolEdit = 0; $toolVerify = 0; $toolOther = 0
$users = 0

foreach ($line in (Get-Content $TranscriptPath)) {
    $tsMatch = [regex]::Match($line, '"timestamp":"([^"]+)"')
    if ($tsMatch.Success) {
        if ($firstTs -eq "") { $firstTs = $tsMatch.Groups[1].Value }
        $lastTs = $tsMatch.Groups[1].Value
    }

    if (-not $seen -and $line -match '"type":"session"') {
        $seen = $true
        $idMatch = [regex]::Match($line, '"id":"([^"]+)"')
        if ($idMatch.Success) { $sessionId = $idMatch.Groups[1].Value }
    }

    if ($line -match '"meta":\{"source":"user"') { $users++ }

    if ($line -match '"type":"tool_result"') {
        # Failure flags OR across consecutive tool_result lines between
        # assistant turns (parallel tool calls): the next assistant turn is a
        # rework turn when ANY result since the previous assistant turn failed.
        $isFail = $false
        foreach ($p in $patterns) {
            if ($p -ne "" -and $line.Contains($p)) { $isFail = $true; break }
        }
        if ($isFail) { $loops++; $accumFail = $true }
    }

    if ($line -match '"role":"assistant"') {
        $turnFail = $accumFail
        $accumFail = $false
        if ($line -match '"usage":\{') {
            $uin = [regex]::Match($line, '"inputTokens":([0-9.]+)')
            $uout = [regex]::Match($line, '"outputTokens":([0-9.]+)')
            $ucache = [regex]::Match($line, '"cacheReadTokens":([0-9.]+)')
            $ucost = [regex]::Match($line, '"costUsd":([0-9.]+)')
            if ($uin.Success) {
                if ($turnFail) {
                    $rewIn += [double]$uin.Groups[1].Value
                    if ($uout.Success) { $rewOut += [double]$uout.Groups[1].Value }
                } else {
                    $succIn += [double]$uin.Groups[1].Value
                    if ($uout.Success) { $succOut += [double]$uout.Groups[1].Value }
                }
                if ($ucache.Success) { $cache += [double]$ucache.Groups[1].Value }
                if ($ucost.Success) { $cost += [double]$ucost.Groups[1].Value }
            }
        }
        $modelMatch = [regex]::Match($line, '"model":"([^"]+)"')
        if ($modelMatch.Success) { $model = $modelMatch.Groups[1].Value }

        # Tool calls are counted per "type":"tool_use" block, and each block
        # name/command are matched only INSIDE that block — an earlier tool_use
        # without a command can never borrow a later block command (cross-tool
        # tail bleed). Tool names may contain any non-quote character.
        $tl = '"type":"tool_use"'
        $cursor = $line
        while ($true) {
            $p = $cursor.IndexOf($tl, [System.StringComparison]::Ordinal)
            if ($p -lt 0) { break }
            $after = $cursor.Substring($p + $tl.Length)
            $nxt = $after.IndexOf($tl, [System.StringComparison]::Ordinal)
            $block = if ($nxt -ge 0) { $after.Substring(0, $nxt) } else { $after }
            $nameMatch = [regex]::Match($block, '"name":"([^"]+)"')
            if ($nameMatch.Success) {
                $toolTotal++
                $tail = $block.Substring($nameMatch.Index + $nameMatch.Length)
                $cls = Classify-Tool -Name $nameMatch.Groups[1].Value.ToLowerInvariant() -Tail $tail
                switch ($cls) {
                    "search" { $toolSearch++ }
                    "edit" { $toolEdit++ }
                    "verify" { $toolVerify++ }
                    default { $toolOther++ }
                }
            }
            $cursor = $after
        }
    }
}

if (-not $seen) {
    [Console]::Error.WriteLine("EXTRACT|ERROR|NO_SESSION_LINE|$TranscriptPath")
    exit 2
}

$wall = 0
if ($firstTs -ne "" -and $lastTs -ne "") {
    try {
        $wall = [DateTimeOffset]::Parse($firstTs, [System.Globalization.CultureInfo]::InvariantCulture).ToUnixTimeSeconds()
        $wallEnd = [DateTimeOffset]::Parse($lastTs, [System.Globalization.CultureInfo]::InvariantCulture).ToUnixTimeSeconds()
        $wall = [Math]::Max(0, $wallEnd - $wall)
    } catch {
        $wall = 0
    }
}
$humans = [Math]::Max(0, $users - 1)
if ($ScenarioId -eq "") { $ScenarioId = $sessionId }
# Every emitted string field — including the session id when it becomes the
# scenario_id fallback — must be free of shell-expansion and JSON-structure
# characters; the Bash twin enforces the identical character class so both
# twins reach the same verdict on adversarial values.
foreach ($strval in @($ScenarioId, $Condition, $model, $firstTs)) {
    if ($strval -match '["\\$`]') {
        [Console]::Error.WriteLine("EXTRACT|ERROR|BAD_VALUE|emitted-string-field")
        exit 2
    }
}
$tokensTotal = [long]($succIn + $succOut + $rewIn + $rewOut)
$transcriptCost = $cost.ToString("0.00", [System.Globalization.CultureInfo]::InvariantCulture)
$succIn = [long]$succIn; $succOut = [long]$succOut; $rewIn = [long]$rewIn; $rewOut = [long]$rewOut
$cache = [long]$cache; $loops = [long]$loops

$record = @"
{
  "scenario_id": "$ScenarioId",
  "condition": "$Condition",
  "model": "$model",
  "timestamp": "$firstTs",
  "metrics": {
    "tokens_in": $succIn,
    "tokens_out": $succOut,
    "tokens_total": $tokensTotal,
    "cache_read_tokens": $cache,
    "tool_calls_total": $toolTotal,
    "tool_calls_search": $toolSearch,
    "tool_calls_edit": $toolEdit,
    "tool_calls_verify": $toolVerify,
    "tool_calls_other": $toolOther,
    "rework_loops": $loops,
    "rework_tokens_in": $rewIn,
    "rework_tokens_out": $rewOut,
    "wall_clock_seconds": $wall,
    "invariants_checked": $InvariantsChecked,
    "invariants_passed": $InvariantsPassed,
    "human_interventions": $humans,
    "accepted": $Accepted
  },
  "costs": {
    "transcript_cost_usd": $transcriptCost
  }
}
"@
Write-Output $record

if ($Accepted -eq "false") {
    [Console]::Error.WriteLine("EXTRACT|NOTE|accepted defaulted to false — pass -Accepted true only after human acceptance")
}
[Console]::Error.WriteLine(("EXTRACT|OK|session={0}|model={1}|tokens_in={2}|tokens_out={3}|rework_loops={4}|tool_calls={5}|wall_clock_seconds={6}" -f $sessionId, $model, $succIn, $succOut, $loops, $toolTotal, $wall))
exit 0
