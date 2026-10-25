<#
.SYNOPSIS
    PromptKit OS Benchmark Tools Fixture Harness (PowerShell)
.DESCRIPTION
    Pins the benchmark tooling twins against fixtures with hand-computed
    expectations. Run: pwsh -NoProfile -File scripts\tests\run-benchmark-tools-tests.ps1
    The .sh twin must reach identical verdicts from identical fixtures.
    Fixture arithmetic (default pricing $3/1M in, $15/1M out, $0.05/loop):
      strip run.diff    -> in_files=5, out_files=1 (src/app.ts kept), dropped=4
      aggregate 4 records + grading.tsv ->
        bare:         n=2 accepted=1 rate=0.50 tokens 19500 wall 180 rework 1.00
                      cpac_n=1 cpac 0.2200
        promptkit_os: n=2 accepted=2 rate=1.00 tokens 17200 wall 195 rework 0.50
                      cpac_n=2 cpac mean/median 0.0970
#>
[CmdletBinding()]
param ()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$fixtures = Join-Path $repoRoot "scripts\tests\fixtures\benchmark-tools"
$stripScript = Join-Path $repoRoot "scripts\strip-benchmark-diff.ps1"
$aggregateScript = Join-Path $repoRoot "scripts\aggregate-benchmark-runs.ps1"

$script:pass = 0
$script:fail = 0
function Ok([string]$m) { $script:pass++; Write-Host "  ok - $m" }
function NotOk([string]$m) { $script:fail++; Write-Host "  FAIL - $m" }

function Invoke-ToolMerged {
    # Runs a twin as a child pwsh, returning stdout+stderr merged and the exit code.
    param ([string]$Script, [string[]]$ScriptArgs)
    $out = & pwsh -NoProfile -File $Script @ScriptArgs 2>&1
    $rc = $LASTEXITCODE
    [pscustomobject]@{ Out = (($out | ForEach-Object { $_.ToString() }) -join "`n"); Rc = $rc }
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("bench-tools-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    Write-Host "🧪 Benchmark Tools Fixture Harness (PowerShell)"

    # --- strip-benchmark-diff ---
    $r = Invoke-ToolMerged -Script $stripScript -ScriptArgs @("-TargetPath", (Join-Path $fixtures "run.diff"))
    $kept = @($r.Out -split "`n" | Where-Object { $_.StartsWith("diff --git ") }).Count
    if ($r.Rc -eq 0 -and $kept -eq 1 -and $r.Out.Contains("diff --git a/src/app.ts b/src/app.ts") -and $r.Out.Contains("STRIP|OK|in_files=7|out_files=1|dropped=6")) {
        Ok "strip keeps code changes and drops all six PromptKit artifacts (incl. scaffold dirs)"
    } else {
        NotOk "strip valid diff (rc=$($r.Rc), kept=$kept)"
    }

    # CRLF parity: both twins must reach the identical verdict on a CRLF copy
    $crlfDiff = Join-Path $tmp "run-crlf.diff"
    [System.IO.File]::WriteAllText($crlfDiff, (([System.IO.File]::ReadAllText((Join-Path $fixtures "run.diff"))) -replace "`n", "`r`n"))
    $r = Invoke-ToolMerged -Script $stripScript -ScriptArgs @("-TargetPath", $crlfDiff)
    if ($r.Rc -eq 0 -and $r.Out.Contains("STRIP|OK|in_files=7|out_files=1|dropped=6") -and -not $r.Out.Contains("PROMPTKIT.md")) {
        Ok "CRLF diff strips identically (no artifact leak under CRLF)"
    } else {
        NotOk "strip CRLF (rc=$($r.Rc))"
    }

    $r = Invoke-ToolMerged -Script $stripScript -ScriptArgs @("-TargetPath", (Join-Path $fixtures "not-a-diff.txt"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("STRIP|ERROR|NOT_A_DIFF")) { Ok "non-diff input fails closed (exit 2)" } else { NotOk "strip non-diff (rc=$($r.Rc))" }

    $empty = Join-Path $tmp "empty.diff"
    [System.IO.File]::WriteAllText($empty, "")
    $r = Invoke-ToolMerged -Script $stripScript -ScriptArgs @("-TargetPath", $empty)
    if ($r.Rc -eq 2 -and $r.Out.Contains("STRIP|ERROR|UNREADABLE")) { Ok "empty diff fails closed (exit 2)" } else { NotOk "strip empty (rc=$($r.Rc))" }

    # --- aggregate-benchmark-runs ---
    $records = "{0},{1},{2},{3}" -f (Join-Path $fixtures "rec-bare-1.json"), (Join-Path $fixtures "rec-bare-2.json"), (Join-Path $fixtures "rec-pk-1.json"), (Join-Path $fixtures "rec-pk-2.json")
    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", (Join-Path $fixtures "grading.tsv"), "-Records", $records)
    $sumBare = 'BENCH|SUMMARY|arm=bare|n=2|accepted=1|graded_n=2|accept_rate=0.50|tokens_mean=19500.0|tokens_median=19500.0|wall_mean=180.0|wall_median=180.0|rework_mean=1.00|cpac_n=1|cpac_mean=0.2200|cpac_median=0.2200'
    $sumPk = 'BENCH|SUMMARY|arm=promptkit_os|n=2|accepted=2|graded_n=2|accept_rate=1.00|tokens_mean=17200.0|tokens_median=17200.0|wall_mean=195.0|wall_median=195.0|rework_mean=0.50|cpac_n=2|cpac_mean=0.0970|cpac_median=0.0970'
    if ($r.Rc -eq 0 `
            -and $r.Out.Contains($sumBare) `
            -and $r.Out.Contains($sumPk) `
            -and $r.Out.Contains('RUN|BENCH-BARE-1|arm=bare|model=test-model-v1|accepted=1|graded=1|rubric=5/5|tokens_total=28000|wall_clock_seconds=240|rework_loops=2|cpac_usd=0.2200') `
            -and $r.Out.Contains('RUN|BENCH-BARE-2|arm=bare|model=test-model-v1|accepted=0|graded=1|rubric=1/5|tokens_total=11000|wall_clock_seconds=120|rework_loops=0|cpac_usd=INF')) {
        Ok "aggregate emits hand-computed RUN rows and both arm summaries"
    } else {
        NotOk "aggregate valid (rc=$($r.Rc), out=$($r.Out.Substring(0, [Math]::Min(220, $r.Out.Length))))"
    }

    $mismatch = Join-Path $tmp "mismatch.tsv"
    [System.IO.File]::WriteAllText($mismatch, (([System.IO.File]::ReadAllText((Join-Path $fixtures "grading.tsv"))).Replace("BENCH-BARE-2`t1`t5`tfalse", "BENCH-BARE-2`t1`t5`ttrue")))
    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", $mismatch, "-Records", (Join-Path $fixtures "rec-bare-2.json"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("BENCH|ERROR|ACCEPTED_MISMATCH|BENCH-BARE-2")) { Ok "grading-vs-record accepted mismatch fails closed (exit 2)" } else { NotOk "accepted mismatch (rc=$($r.Rc))" }

    $badg = Join-Path $tmp "badg.tsv"
    [System.IO.File]::WriteAllText($badg, "BENCH-X`tok`t5`n")
    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", $badg, "-Records", (Join-Path $fixtures "rec-bare-1.json"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("BENCH|ERROR|BAD_GRADING")) { Ok "malformed grading row fails closed (exit 2)" } else { NotOk "bad grading (rc=$($r.Rc))" }

    # exact-column discipline: an extra tab-separated column is BAD_GRADING
    $extracol = Join-Path $tmp "extracol.tsv"
    [System.IO.File]::WriteAllText($extracol, "BENCH-BARE-1`t5`t5`ttrue`textra`n")
    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", $extracol, "-Records", (Join-Path $fixtures "rec-bare-1.json"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("BENCH|ERROR|BAD_GRADING")) { Ok "extra grading column fails closed (exit 2)" } else { NotOk "extra column (rc=$($r.Rc))" }

    # CRLF + missing final newline parity: a CRLF sheet grades identically
    # (records precomputed: an inline -f inside the array literal would bind
    # to the whole array, since the comma operator binds tighter than -f)
    $crlfSheet = Join-Path $tmp "grading-crlf.tsv"
    $crlfRows = (([System.IO.File]::ReadAllText((Join-Path $fixtures "grading.tsv"))) -replace "`n", "`r`n") -split "`r`n" | Select-Object -First 3
    [System.IO.File]::WriteAllText($crlfSheet, ($crlfRows -join "`r`n"))   # no trailing newline
    $twoBare = "{0},{1}" -f (Join-Path $fixtures "rec-bare-1.json"), (Join-Path $fixtures "rec-bare-2.json")
    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", $crlfSheet, "-Records", $twoBare)
    if ($r.Rc -eq 0 -and $r.Out.Contains('BENCH|SUMMARY|arm=bare|n=2|accepted=1|graded_n=2|accept_rate=0.50')) {
        Ok "CRLF sheet without final newline grades identically (final row included)"
    } else {
        NotOk "CRLF grading (rc=$($r.Rc))"
    }

    # MISSING_GRADING: a record absent from the mandatory sheet fails closed
    $partial = Join-Path $tmp "partial.tsv"
    [System.IO.File]::WriteAllText($partial, "BENCH-BARE-1`t5`t5`ttrue`n")
    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", $partial, "-Records", $twoBare)
    if ($r.Rc -eq 2 -and $r.Out.Contains("BENCH|ERROR|MISSING_GRADING|BENCH-BARE-2")) { Ok "record missing from the grading sheet fails closed (exit 2)" } else { NotOk "missing grading (rc=$($r.Rc))" }

    $r = Invoke-ToolMerged -Script $aggregateScript -ScriptArgs @("-Grading", (Join-Path $fixtures "grading.tsv"))
    if ($r.Rc -eq 2) { Ok "missing records exits 2 with usage" } else { NotOk "no records (rc=$($r.Rc))" }

    Write-Host ""
    Write-Host "Benchmark tools harness (PowerShell): $script:pass passed, $script:fail failed."
    if ($script:fail -ne 0) { exit 1 }
    exit 0
} finally {
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
}
