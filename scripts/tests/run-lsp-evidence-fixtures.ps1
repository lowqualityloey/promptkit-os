# Cross-platform fixture harness for the read-only LSP evidence validator.
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-lsp-evidence-fixtures.ps1

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$FixtureRoot = Join-Path $RepoRoot "scripts/tests/fixtures/lsp-evidence"
$Validator = Join-Path $RepoRoot "scripts/validate-lsp-evidence.ps1"
$Diff = Join-Path $FixtureRoot "baseline.diff"

$results = @()

function Invoke-Case($name, $caseDir) {
    $out = (& $Validator -Root $caseDir -DiffFile $Diff 2>&1) | Out-String
    $code = $LASTEXITCODE
    return [pscustomobject]@{ Name = $name; Exit = $code; Out = $out }
}

$cases = @{
    valid                = Invoke-Case "valid" (Join-Path $FixtureRoot "valid")
    hallucinated         = Invoke-Case "hallucinated" (Join-Path $FixtureRoot "invalid-hallucinated")
    outOfRange           = Invoke-Case "outOfRange" (Join-Path $FixtureRoot "invalid-out-of-range")
    notMeasured          = Invoke-Case "notMeasured" (Join-Path $FixtureRoot "not-measured")
}

function Assert-Case($label, $condition) {
    if ($condition) { Write-Output "  PASS: $label"; $script:pass++ }
    else { Write-Output "  FAIL: $label"; $script:failures++ }
}

$script:pass = 0
$script:failures = 0

Assert-Case "valid fixture exits 0" ($cases.valid.Exit -eq 0)
Assert-Case "hallucinated citation flagged with REVIEW id" ($cases.hallucinated.Out -match 'INVALID_EVIDENCE\|REVIEW-lsp-fixture-hallucinated')
Assert-Case "hallucinated fixture exits 1" ($cases.hallucinated.Exit -eq 1)
Assert-Case "out-of-range citation flagged with REVIEW id" ($cases.outOfRange.Out -match 'INVALID_EVIDENCE\|REVIEW-lsp-fixture-out-of-range')
Assert-Case "out-of-range fixture exits 1" ($cases.outOfRange.Exit -eq 1)
Assert-Case "not measured fixture exits 0 (absence is never a failure)" ($cases.notMeasured.Exit -eq 0)
Assert-Case "not measured reports CITED=0 pass-through" ($cases.notMeasured.Out -match 'CITED=0')

$total = 7
Write-Output "==========================================================="
Write-Output "LSP Evidence Fixture Verification Summary (PowerShell)"
Write-Output "Passed: $pass | Failed: $failures"
Write-Output "==========================================================="
if ($failures -gt 0) { exit 1 }
Write-Output "All LSP evidence fixture tests passed successfully!"
exit 0
