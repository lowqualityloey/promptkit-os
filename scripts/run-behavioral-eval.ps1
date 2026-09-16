# PromptKit OS Behavioral Evaluation Harness (PowerShell)
#
# Scores model transcripts against scenario rubrics — observable properties of
# OUTPUTS, never prose equality. Complements the grep-based
# documentation-contract suite. Honesty contract: sampled compliance for named
# models at a named commit, not a guarantee. See docs/BEHAVIORAL-EVAL.md.
#
# Run from repository root:
#   pwsh -NoProfile -File .\scripts\run-behavioral-eval.ps1 -SelfTest
#       Offline CI mode. Scores embedded PASS/FAIL fixtures through the same
#       check engine as live scoring. No network, no API keys.
#   pwsh -NoProfile -File .\scripts\run-behavioral-eval.ps1 -Score <scenario> <transcript-file>
#
# Output: machine-parseable SCENARIO|MODE|RESULT|EVIDENCE lines.

param(
    [switch]$SelfTest,
    [string]$Score = "",
    [string]$Transcript = ""
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$ScenDir = Join-Path $RepoRoot "scripts/tests/eval-scenarios"

$script:PassCount = 0
$script:FailCount = 0

function Get-Section {
    param([string]$File, [string]$Heading)
    $lines = Get-Content -Path $File
    $out = @()
    $capture = $false
    foreach ($l in $lines) {
        if ($l -eq "## $Heading") { $capture = $true; continue }
        if ($l.StartsWith("## ")) { $capture = $false; continue }
        if ($capture) { $out += $l }
    }
    return $out
}

function Test-Checks {
    param([string[]]$TranscriptLines, [string[]]$CheckLines)
    $ok = 0
    $total = 0
    $first = if ($TranscriptLines.Count -gt 0) { $TranscriptLines[0] } else { "" }
    $text = $TranscriptLines -join "`n"
    foreach ($line in $CheckLines) {
        $line = $line -replace '^- ', ''
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $sep = $line.IndexOf(': ')
        if ($sep -lt 0) { Write-Host "    ✗ malformed check '$line'"; continue }
        $type = $line.Substring(0, $sep)
        $pat = $line.Substring($sep + 2)
        $total++
        switch ($type) {
            'first-line-matches' {
                if ($first -cmatch $pat) { $ok++ }
                else { Write-Host "    ✗ first-line-matches '$pat' (got: $first)" } }
            'contains' {
                if ($text -cmatch $pat) { $ok++ }
                else { Write-Host "    ✗ missing '$pat'" } }
            'not-contains' {
                if ($text -cmatch $pat) { Write-Host "    ✗ forbidden '$pat' present" }
                else { $ok++ } }
            'contains-any' {
                $hit = $false
                foreach ($alt in ($pat -split '\|')) {
                    if ($text -cmatch $alt) { $hit = $true; break }
                }
                if ($hit) { $ok++ }
                else { Write-Host "    ✗ none of '$pat' present" } }
            default { Write-Host "    ✗ unknown check type '$type'" }
        }
    }
    return ($ok -eq $total) -and ($total -gt 0)
}

function Invoke-SelfTest {
    Write-Host ""
    Write-Host "🧪 Behavioral Eval Offline Self-Test (fixtures through the live scoring path)"
    Write-Host "==========================================================================="
    foreach ($f in Get-ChildItem $ScenDir -Filter "*.md") {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        $passFix = Get-Section $f.FullName "Transcript-PASS"
        $failFix = Get-Section $f.FullName "Transcript-FAIL"
        $checks = Get-Section $f.FullName "Checks"
        if (Test-Checks $passFix $checks) {
            if (Test-Checks $failFix $checks) {
                Write-Host "  ❌ FAIL: $name — FAIL fixture unexpectedly satisfies all checks" -ForegroundColor Red
                Write-Output "$name|self-test|FAIL|fail-fixture-satisfies-all-checks"
                $script:FailCount++
            } else {
                Write-Host "  ✅ PASS: $name (pass-fixture holds, fail-fixture violates)" -ForegroundColor Green
                Write-Output "$name|self-test|PASS|pass-holds-fail-violates"
                $script:PassCount++
            }
        } else {
            Write-Host "  ❌ FAIL: $name — PASS fixture violates checks:" -ForegroundColor Red
            Write-Output "$name|self-test|FAIL|pass-fixture-violates-checks"
            $script:FailCount++
        }
    }
    Write-Host "==========================================================================="
    Write-Host "Passed: $($script:PassCount) | Failed: $($script:FailCount)"
    if ($script:FailCount -gt 0) { exit 1 }
}

function Invoke-Score {
    param([string]$Name, [string]$TranscriptPath)
    $f = Join-Path $ScenDir "$Name.md"
    if (-not (Test-Path $f)) { Write-Error "Unknown scenario '$Name' (see $ScenDir)"; exit 2 }
    if (-not (Test-Path $TranscriptPath)) { Write-Error "Transcript file '$TranscriptPath' not found"; exit 2 }
    $t = Get-Content -Path $TranscriptPath
    $checks = Get-Section $f "Checks"
    if (Test-Checks $t $checks) { Write-Output "$Name|live|PASS|all-checks-hold" }
    else { Write-Output "$Name|live|FAIL|check-violations"; exit 1 }
}

if ($SelfTest) { Invoke-SelfTest }
elseif ($Score -ne "") { Invoke-Score $Score $Transcript }
else { Write-Error "Usage: run-behavioral-eval.ps1 -SelfTest | -Score <scenario> -Transcript <file>"; exit 2 }
