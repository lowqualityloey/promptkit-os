<#
.SYNOPSIS
    PromptKit OS CPAC Ingestion Fixture Harness (PowerShell)
.DESCRIPTION
    Pins the CPAC twins' telemetry-ingestion behavior and the Command Code
    extractor's §5 record emission against fixtures with hand-computed totals.
    Run: pwsh -NoProfile -File scripts\tests\run-cpac-ingestion-tests.ps1
    The .sh twin must reach identical verdicts from identical fixtures.
    Fixture arithmetic (default pricing $3/1M in, $15/1M out, $0.05/loop):
      telemetry-valid.json     -> CPAC 0.2200   (rejected variant -> INF)
      session-basic.jsonl      -> succ 11000/2200, rework 4000/800 (1 loop),
                                  cache 3500, 4 tool calls (1/1/2/0), wall 60s,
                                  and end-to-end CPAC 0.1400 once accepted.
#>
[CmdletBinding()]
param ()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$fixtures = Join-Path $repoRoot "scripts\tests\fixtures\cpac-ingestion"
$measureScript = Join-Path $repoRoot "scripts\measure-cpac.ps1"
$extractScript = Join-Path $repoRoot "scripts\extract-commandcode-telemetry.ps1"

$script:pass = 0
$script:fail = 0
function Ok([string]$m) { $script:pass++; Write-Host "  ok - $m" }
function NotOk([string]$m) { $script:fail++; Write-Host "  FAIL - $m" }

function Invoke-CpacMerged {
    # Runs a twin as a child pwsh, returning stdout+stderr merged and the exit code.
    param ([string]$Script, [string[]]$ScriptArgs)
    $out = & pwsh -NoProfile -File $Script @ScriptArgs 2>&1
    $rc = $LASTEXITCODE
    [pscustomobject]@{ Out = (($out | ForEach-Object { $_.ToString() }) -join "`n"); Rc = $rc }
}

function Invoke-CpacStdout {
    # Runs a twin as a child pwsh, returning stdout only (stderr passes through).
    param ([string]$Script, [string[]]$ScriptArgs)
    $out = & pwsh -NoProfile -File $Script @ScriptArgs
    $rc = $LASTEXITCODE
    [pscustomobject]@{ Out = (($out | ForEach-Object { $_.ToString() }) -join "`n"); Rc = $rc }
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cpac-ingestion-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    Write-Host "🧪 CPAC Ingestion Fixture Harness (PowerShell)"

    # --- measure-cpac.ps1 modes ---
    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-SelfTest")
    if ($r.Rc -eq 0 -and $r.Out -like "*All CPAC measurement self-tests PASSED.*") { Ok "self-test passes with the §2B formula expectations" } else { NotOk "self-test (rc=$($r.Rc))" }

    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-Demo")
    if ($r.Rc -eq 0 -and $r.Out -like "*SIMULATED*" -and $r.Out -notlike "*CPAC|MEASURED*") { Ok "-Demo prints the labeled simulated scorecard only" } else { NotOk "-Demo (rc=$($r.Rc))" }

    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @()
    if ($r.Rc -eq 0 -and $r.Out -like "*measure-cpac.ps1*") { Ok "bare invocation prints usage (no default simulation)" } else { NotOk "bare invocation (rc=$($r.Rc))" }

    # --- measured ingestion ---
    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-TargetPath", (Join-Path $fixtures "telemetry-valid.json"))
    $machine = 'CPAC|MEASURED|scenario=BENCH-01|condition=bare|model=test-model-v1|tokens_in=20000|tokens_out=2000|cache_read_tokens=4000|rework_loops=2|rework_tokens_in=5000|rework_tokens_out=1000|wall_clock_seconds=240|human_interventions=0|inference_usd=0.0900|rework_usd=0.1300|human_usd=0.0000|cpac_usd=0.2200'
    if ($r.Rc -eq 0 -and $r.Out.Contains($machine)) { Ok "valid §5 record scores cpac_usd=0.2200 with the full machine line" } else { NotOk "valid record scoring (rc=$($r.Rc), out=$($r.Out.Substring(0, [Math]::Min(200, $r.Out.Length))))" }

    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-TargetPath", (Join-Path $fixtures "telemetry-rejected.json"))
    if ($r.Rc -eq 0 -and $r.Out.Contains("INF (REJECTED)") -and $r.Out.Contains("cpac_usd=INF")) { Ok "accepted=false record reports INF (REJECTED) with cpac_usd=INF" } else { NotOk "rejected record (rc=$($r.Rc))" }

    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-TargetPath", (Join-Path $fixtures "telemetry-missing-key.json"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("CPAC|ERROR|MISSING_KEY|rework_loops")) { Ok "missing rework_loops fails closed (exit 2)" } else { NotOk "missing-key record (rc=$($r.Rc))" }

    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-TargetPath", (Join-Path $fixtures "telemetry-bad-accepted.json"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("CPAC|ERROR|BAD_VALUE|accepted")) { Ok "string-typed accepted fails closed (exit 2)" } else { NotOk "bad-accepted record (rc=$($r.Rc))" }

    $empty = Join-Path $tmp "empty.json"
    [System.IO.File]::WriteAllText($empty, "")
    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-TargetPath", $empty)
    if ($r.Rc -eq 2 -and $r.Out.Contains("CPAC|ERROR|UNREADABLE")) { Ok "empty record fails closed (exit 2)" } else { NotOk "empty record (rc=$($r.Rc))" }

    # --- extractor: known session, exact record fields ---
    $r = Invoke-CpacStdout -Script $extractScript -ScriptArgs @("-TranscriptPath", (Join-Path $fixtures "session-basic.jsonl"), "-ScenarioId", "BENCH-01", "-Condition", "bare", "-Accepted", "true")
    $out = $r.Out
    if ($r.Rc -eq 0 `
            -and $out.Contains('"tokens_in": 11000') `
            -and $out.Contains('"tokens_out": 2200') `
            -and $out.Contains('"tokens_total": 18000') `
            -and $out.Contains('"cache_read_tokens": 3500') `
            -and $out.Contains('"tool_calls_total": 4') `
            -and $out.Contains('"tool_calls_search": 1') `
            -and $out.Contains('"tool_calls_edit": 1') `
            -and $out.Contains('"tool_calls_verify": 2') `
            -and $out.Contains('"tool_calls_other": 0') `
            -and $out.Contains('"rework_loops": 1') `
            -and $out.Contains('"rework_tokens_in": 4000') `
            -and $out.Contains('"rework_tokens_out": 800') `
            -and $out.Contains('"wall_clock_seconds": 60') `
            -and $out.Contains('"human_interventions": 0') `
            -and $out.Contains('"accepted": true') `
            -and $out.Contains('"model": "test-model-v1"') `
            -and $out.Contains('"scenario_id": "BENCH-01"') `
            -and $out.Contains('"transcript_cost_usd": 0.00')) {
        Ok "session fixture extracts the hand-computed §5 record exactly"
    } else {
        NotOk "extraction record (rc=$($r.Rc), out=$($out.Substring(0, [Math]::Min(200, $out.Length))))"
    }

    $r2 = Invoke-CpacMerged -Script $extractScript -ScriptArgs @("-TranscriptPath", (Join-Path $fixtures "session-basic.jsonl"))
    if ($r2.Out.Contains("EXTRACT|OK|session=f1x0-dead-beef-42")) { Ok "stderr carries the EXTRACT|OK status line" } else { NotOk "stderr status line" }

    # --- end-to-end: extraction feeds scoring ---
    $recordPath = Join-Path $tmp "record.json"
    [System.IO.File]::WriteAllText($recordPath, $out)
    $r = Invoke-CpacMerged -Script $measureScript -ScriptArgs @("-TargetPath", $recordPath)
    if ($r.Rc -eq 0 -and $r.Out.Contains("cpac_usd=0.1400")) { Ok "extraction → scoring end-to-end yields cpac_usd=0.1400" } else { NotOk "end-to-end scoring (rc=$($r.Rc))" }

    # --- extractor: negative cases ---
    $r = Invoke-CpacMerged -Script $extractScript -ScriptArgs @("-TranscriptPath", (Join-Path $fixtures "session-nosession.jsonl"))
    if ($r.Rc -eq 2 -and $r.Out.Contains("EXTRACT|ERROR|NO_SESSION_LINE")) { Ok "transcript without a session line fails closed (exit 2)" } else { NotOk "no-session transcript (rc=$($r.Rc))" }

    $r = Invoke-CpacMerged -Script $extractScript -ScriptArgs @()
    if ($r.Rc -eq 2) { Ok "missing transcript argument exits 2 with usage" } else { NotOk "missing argument (rc=$($r.Rc))" }

    Write-Host ""
    Write-Host "CPAC ingestion harness (PowerShell): $script:pass passed, $script:fail failed."
    if ($script:fail -ne 0) { exit 1 }
    exit 0
} finally {
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
}
