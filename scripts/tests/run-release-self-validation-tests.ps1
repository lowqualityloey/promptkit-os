# Cross-platform test suite for release self-validation output contract parser and grandfather exemption.
# Exercises clean VALID, allowed legacy FAILED, new records with legacy IDs, mixed diagnostics, crashes,
# empty output, contradictory summaries, and invalid lines.
#
# Run from repository root: pwsh -NoProfile -File scripts/tests/run-release-self-validation-tests.ps1

$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path "$ScriptDir/../..").Path
$Checker = Join-Path $RepoRoot "scripts/check-release-validation-output.ps1"

$Pass = 0
$Fail = 0

function Check([string]$Label, [int]$ExpectedExit, [int]$ActualExit, [string]$Out) {
    if ($ActualExit -eq $ExpectedExit) {
        Write-Host "  ✅ PASS: $Label"
        $script:Pass++
    } else {
        Write-Host "  ❌ FAIL: $Label (expected exit $ExpectedExit, got $ActualExit)"
        Write-Host "     Output: $Out"
        $script:Fail++
    }
}

Write-Host "=== Release Self-Validation Contract Parser Tests (PowerShell) ==="

function Invoke-Checker([string[]]$Lines, [int]$ExitCode) {
    $tmpIn = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllLines($tmpIn, $Lines)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "pwsh"
        $psi.Arguments = "-NoProfile -File `"$Checker`" -ExitCode $ExitCode -InputPath `"$tmpIn`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = [System.Diagnostics.Process]::Start($psi)
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        $combined = ($stdout + "`n" + $stderr).Trim()
        return @{ ExitCode = $p.ExitCode; Output = $combined }
    } finally {
        if (Test-Path $tmpIn) {
            Remove-Item $tmpIn -Force -ErrorAction SilentlyContinue
        }
    }
}

# Case 1: Clean VALID on exit 0
$res = Invoke-Checker @("VALID|RECORDS=47|ROOT=.") 0
Check "Clean VALID on exit 0 passes" 0 $res.ExitCode $res.Output

# Case 2: Allowed legacy FAILED on exit 1
$res = Invoke-Checker @(
    "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field",
    "INVALID_ID|UNKNOWN|docs/releases/2026-09-08-v1.0.0-release-notes-draft.md|Missing field: Evaluation ID|Add field",
    "FAILED|ERRORS=2|RECORDS=47"
) 1
Check "Allowed legacy diagnostics on exit 1 pass with grandfather exemption" 0 $res.ExitCode $res.Output

# Case 3: New record with historical legacy prefix in its Evaluation ID must FAIL (R1 fix)
$res = Invoke-Checker @(
    "MISSING_FIELD|EVAL-2026-09-08-v1.0.0-new|docs/releases/new-feature-evaluation.md|Missing field: Created|Add field",
    "FAILED|ERRORS=1|RECORDS=48"
) 1
Check "New record with legacy Eval ID prefix in field 2 is rejected" 1 $res.ExitCode $res.Output

# Case 4: Mixed legacy and new record diagnostics must FAIL
$res = Invoke-Checker @(
    "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field",
    "MISSING_FIELD|REL-2026-09-10-V110-001|docs/releases/2026-09-10-v1.1.0-evaluation.md|Missing field: Created|Add field",
    "FAILED|ERRORS=2|RECORDS=48"
) 1
Check "Mixed legacy and new diagnostics on exit 1 is rejected" 1 $res.ExitCode $res.Output

# Case 5: Exit 0 with diagnostics must FAIL (R2 contract violation)
$res = Invoke-Checker @(
    "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field",
    "VALID|RECORDS=47|ROOT=."
) 0
Check "Exit 0 with diagnostics is rejected" 1 $res.ExitCode $res.Output

# Case 6: Exit 1 with 0 diagnostics must FAIL (R2 contract violation)
$res = Invoke-Checker @("FAILED|ERRORS=0|RECORDS=47") 1
Check "Exit 1 with zero diagnostics is rejected" 1 $res.ExitCode $res.Output

# Case 7: Exit 1 with mismatched diagnostic count must FAIL (R2 contract violation)
$res = Invoke-Checker @(
    "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field",
    "FAILED|ERRORS=3|RECORDS=47"
) 1
Check "Exit 1 with mismatched error count in summary is rejected" 1 $res.ExitCode $res.Output

# Case 8: Exit 0 with FAILED summary must FAIL (inconsistent status/summary)
$res = Invoke-Checker @("FAILED|ERRORS=1|RECORDS=47") 0
Check "Exit 0 with FAILED summary is rejected" 1 $res.ExitCode $res.Output

# Case 9: Exit 1 with VALID summary must FAIL (inconsistent status/summary)
$res = Invoke-Checker @("VALID|RECORDS=47|ROOT=.") 1
Check "Exit 1 with VALID summary is rejected" 1 $res.ExitCode $res.Output

# Case 10: Crash exit code (e.g. 2) must propagate crash status
$res = Invoke-Checker @("syntax error near unexpected token") 2
Check "Validator crash (exit 2) is rejected" 2 $res.ExitCode $res.Output

# Case 11: Empty output must FAIL
$res = Invoke-Checker @("") 0
Check "Empty output on exit 0 is rejected" 1 $res.ExitCode $res.Output

# Case 12: Foreign/unrecognized line alongside summary must FAIL
$res = Invoke-Checker @(
    "find: /nonexistent: No such file or directory",
    "VALID|RECORDS=47|ROOT=."
) 0
Check "Unrecognized line alongside summary is rejected" 1 $res.ExitCode $res.Output

# Case 13: Contradictory summaries must FAIL
$res = Invoke-Checker @(
    "VALID|RECORDS=47|ROOT=.",
    "FAILED|ERRORS=0|RECORDS=47"
) 0
Check "Contradictory multiple summaries is rejected" 1 $res.ExitCode $res.Output

Write-Host ""
Write-Host "Summary: $Pass passed, $Fail failed"
if ($Fail -gt 0) {
    exit 1
}
exit 0
