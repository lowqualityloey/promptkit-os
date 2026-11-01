# Cross-platform fixture harness for the read-only CI triage validator.
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-ci-triage-fixtures.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
$repoRoot = (Split-Path -Parent (Split-Path -Parent $scriptDir)).TrimEnd([char]92, [char]47)
$fixtureRoot = Join-Path $repoRoot 'scripts/tests/fixtures/ci-triage'
$validator = Join-Path $repoRoot 'scripts/validate-ci-triage.ps1'
$tempBase = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } elseif ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
$tempRoot = Join-Path $tempBase ('promptkit-ci-triage-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

function Fail-Harness { param([string]$Message); throw "HARNESS_FAILURE|$Message" }
# Hashes are collected in one Get-FileHash call per snapshot instead of one call
# per file. A partial mapping would silently weaken the read-only assertion, so
# a count mismatch fails the harness rather than producing hashless lines.
function Get-FileSnapshot {
    $items = @(Get-ChildItem -LiteralPath $repoRoot -File -Recurse | Where-Object { $_.FullName -notlike "$repoRoot\.git\*" } | Sort-Object FullName)
    if ($items.Count -eq 0) { return @() }
    $hashes = @{}
    foreach ($h in (Get-FileHash -LiteralPath $items.FullName -Algorithm SHA256)) { $hashes[$h.Path] = $h.Hash }
    if ($hashes.Count -ne $items.Count) { Fail-Harness "Snapshot hash mapping incomplete: $($hashes.Count) of $($items.Count) files" }
    return @($items | ForEach-Object { $relative = $_.FullName.Substring($repoRoot.Length).TrimStart([char]92, [char]47) -replace '\\','/'; "$relative|$($hashes[$_.FullName])" })
}
function Get-StatusSnapshot { $status = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all 2>&1); if ($LASTEXITCODE -ne 0) { Fail-Harness 'Unable to read Git status' }; return @($status | ForEach-Object { $_.ToString() }) }
function Assert-Unchanged { param([string[]]$BeforeFiles,[string[]]$BeforeStatus,[string]$Label); $afterFiles = @(Get-FileSnapshot); $afterStatus = @(Get-StatusSnapshot); if (($BeforeFiles -join "`n") -ne ($afterFiles -join "`n")) { Fail-Harness "Repository file hashes changed during $Label validation" }; if (($BeforeStatus -join "`n") -ne ($afterStatus -join "`n")) { Fail-Harness "Git status changed during $Label validation" } }
function Assert-Diagnostics { param([string[]]$Lines,[string]$Expected,[string]$Name); $actual = @($Lines | Where-Object { $_.ToString() -notmatch '^(VALID|FAILED)\|' } | ForEach-Object { $_.ToString() } | Sort-Object); if ($Expected -eq '-') { if ($actual.Count -ne 0) { Fail-Harness "$Name produced unexpected diagnostics" }; return }; $expectedLines = @($Expected -split ';;' | Sort-Object); if (($actual -join "`n") -ne ($expectedLines -join "`n")) { Fail-Harness "$Name complete normalized diagnostic set did not match the shared contract" } }
function Run-Case { param([string]$Name,[string]$Root,[int]$ExpectedExit,[string]$ExpectedSummary,[string]$ExpectedDiagnostics); $outputPath = Join-Path $tempRoot "$Name.output.txt"; $lines = @(& pwsh -NoProfile -File $validator -Root $Root -Strict 2>&1); $exitCode = $LASTEXITCODE; $text = ($lines | ForEach-Object { $_.ToString() }) -join "`n"; $text | Set-Content -LiteralPath $outputPath -Encoding utf8; if ($exitCode -ne $ExpectedExit) { Write-Output $text; Fail-Harness "$Name expected exit $ExpectedExit but received $exitCode" }; if (-not ($lines | Where-Object { $_.ToString() -ceq $ExpectedSummary })) { Write-Output $text; Fail-Harness "$Name did not contain the exact expected summary $ExpectedSummary" }; Assert-Diagnostics $lines $ExpectedDiagnostics $Name }

try {
    foreach ($required in @($validator, (Join-Path $fixtureRoot 'valid'), (Join-Path $fixtureRoot 'invalid'), (Join-Path $fixtureRoot 'expected/cases.tsv'))) { if (-not (Test-Path -LiteralPath $required)) { Fail-Harness "Missing harness input: $required" } }
    $beforeFiles = @(Get-FileSnapshot); $beforeStatus = @(Get-StatusSnapshot); Run-Case 'valid' (Join-Path $fixtureRoot 'valid') 0 'VALID|RECORDS=1|ROOT=.' '-'; Assert-Unchanged $beforeFiles $beforeStatus 'valid'
    $beforeFiles = @(Get-FileSnapshot); $beforeStatus = @(Get-StatusSnapshot); Run-Case 'invalid' (Join-Path $fixtureRoot 'invalid') 1 'FAILED|ERRORS=7|RECORDS=1' 'INVALID_TRANSITION|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Invalid CI transition: evidence_requested -> classified|Follow the evidence-first state graph and conditional action branch;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Check Identity|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Configuration Context|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Execution Time|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Failed Job or Command|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Failure Output|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Revision Identifier|Provide a non-placeholder value for the required field'; Assert-Unchanged $beforeFiles $beforeStatus 'invalid'
    $caseCount = 0
    foreach ($line in @(Get-Content -LiteralPath (Join-Path $fixtureRoot 'expected/cases.tsv'))) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        $parts = $line -split "`t", 4; if ($parts.Count -ne 4) { Fail-Harness "Invalid case manifest row: $line" }
        $name = $parts[0]; $expectedExit = [int]$parts[1]; $expectedSummary = $parts[2]; $expectedDiagnostics = $parts[3]; if ([string]::IsNullOrWhiteSpace($expectedDiagnostics)) { Fail-Harness "Missing diagnostic contract for case $name" }; $caseRoot = Join-Path $fixtureRoot "cases/$name"; if (-not (Test-Path -LiteralPath $caseRoot)) { Fail-Harness "Missing case root: $caseRoot" }
        $beforeFiles = @(Get-FileSnapshot); $beforeStatus = @(Get-StatusSnapshot); Run-Case $name $caseRoot $expectedExit $expectedSummary $expectedDiagnostics; Assert-Unchanged $beforeFiles $beforeStatus $name; $caseCount++
    }
    Write-Output "CI triage PowerShell matrix cases passed: $caseCount isolated contracts."
    Write-Output 'CI triage validation is deterministic, network-free, and read-only; it cannot execute remote actions or approve release resumption.'
    Write-Output 'CI triage PowerShell fixture harness passed: complete normalized diagnostic contracts cover state, action, blocked/resume, and release-handoff behavior.'
}
finally { if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force } }
