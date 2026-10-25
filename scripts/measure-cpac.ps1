<#
.SYNOPSIS
    PromptKit OS Cost Per Accepted Change (CPAC) Measurement Utility (PowerShell)
.DESCRIPTION
    Scores a standardized telemetry record (docs/BENCHMARK-METHODOLOGY.md §5)
    with the CPAC formula, provides offline self-tests for that formula, and
    prints a SIMULATED demonstration scorecard under -Demo only. Host
    transcript extraction into the §5 record is provided by
    scripts/extract-commandcode-telemetry.ps1 (Command Code sessions). Invalid
    telemetry records fail closed with exit 2.
#>
[CmdletBinding()]
param (
    [switch]$SelfTest,
    [switch]$Demo,
    [string]$TargetPath,
    [double]$PriceIn = 0.000003,     # $3.00 per 1M input tokens
    [double]$PriceOut = 0.000015,    # $15.00 per 1M output tokens
    [double]$ReworkToolCost = 0.05,  # tau_tool: infrastructure execution cost per failed loop
    [double]$HumanRate = 8.33        # 5 minutes of engineering review @ $100/hr
)

function Write-CpacError {
    param ([string]$Kind, [string]$Detail)
    [Console]::Error.WriteLine("CPAC|ERROR|$Kind|$Detail")
    exit 2
}

# Calculate-Cpac implements the successful-turn/rework split of the §2
# methodology, including the §2B per-loop rework formula: loop tokens are
# priced at the same in/out rates and excluded from inference (no double
# counting); each failed loop additionally carries the tau_tool tool cost.
function Calculate-Cpac {
    param (
        [double]$TokensIn,
        [double]$TokensOut,
        [double]$ReworkTokensIn,
        [double]$ReworkTokensOut,
        [double]$ReworkLoops,
        [double]$HumanInterventions,
        [bool]$Accepted
    )

    $infCost = ($TokensIn * $PriceIn) + ($TokensOut * $PriceOut)
    $rewCost = ($ReworkTokensIn * $PriceIn) + ($ReworkTokensOut * $PriceOut) + ($ReworkLoops * $ReworkToolCost)
    $humCost = $HumanInterventions * $HumanRate
    $totalCost = [math]::Round($infCost + $rewCost + $humCost, 4)

    if ($Accepted) {
        return ("{0:0.0000}" -f $totalCost)
    } else {
        return "INF (REJECTED)"
    }
}

function Get-MetricNumber {
    # Returns the metrics value as double; exits with MISSING_KEY when absent
    # or not a numeric JSON type (a string-typed number is as absent as a
    # missing key — the Bash twin's numeric scan behaves identically).
    param ([object]$Metrics, [string]$Key)
    $prop = $Metrics.PSObject.Properties[$Key]
    if ($null -eq $prop -or $null -eq $prop.Value) {
        Write-CpacError "MISSING_KEY" $Key
    }
    $v = $prop.Value
    if ($v -is [string] -or $v -is [bool] -or -not ($v -is [valueuetype] -or $v -is [double] -or $v -is [int64] -or $v -is [int32] -or $v -is [decimal])) {
        Write-CpacError "MISSING_KEY" $Key
    }
    return [double]$v
}

function Run-SelfTest {
    Write-Host "`n🧪 PromptKit OS CPAC Measurement Self-Test (PowerShell)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    # Test 1: Ideal Clean Run
    $cpacIdeal = Calculate-Cpac -TokensIn 15000 -TokensOut 1500 -ReworkTokensIn 0 -ReworkTokensOut 0 -ReworkLoops 0 -HumanInterventions 0 -Accepted $true
    if ($cpacIdeal -eq "0.0675") {
        Write-Host "✅ Test 1 Passed: Ideal run CPAC = `$$cpacIdeal" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 1 Failed: Expected 0.0675, got $cpacIdeal" -ForegroundColor Red
        exit 1
    }

    # Test 2: Run with Rework Loops (loop tokens priced in C_rework per §2B)
    $cpacRework = Calculate-Cpac -TokensIn 45000 -TokensOut 6000 -ReworkTokensIn 12000 -ReworkTokensOut 2100 -ReworkLoops 3 -HumanInterventions 1 -Accepted $true
    if ($cpacRework -eq "8.7725") {
        Write-Host "✅ Test 2 Passed: Rework run CPAC = `$$cpacRework" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 2 Failed: Expected 8.7725, got $cpacRework" -ForegroundColor Red
        exit 1
    }

    # Test 3: Rejected Run
    $cpacRejected = Calculate-Cpac -TokensIn 20000 -TokensOut 2000 -ReworkTokensIn 0 -ReworkTokensOut 0 -ReworkLoops 2 -HumanInterventions 1 -Accepted $false
    if ($cpacRejected -eq "INF (REJECTED)") {
        Write-Host "✅ Test 3 Passed: Rejected run CPAC = $cpacRejected" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 3 Failed: Expected INF (REJECTED), got $cpacRejected" -ForegroundColor Red
        exit 1
    }

    Write-Host "`n✅ All CPAC measurement self-tests PASSED.`n" -ForegroundColor Green
    exit 0
}

function ConvertTo-Invariant4 {
    # Invariant 4-decimal money formatting shared with the Bash twin's %.4f
    param ([double]$Value)
    return ("{0:0.0000}" -f $Value)
}

function Run-Ingest {
    param ([string]$Path)

    if (-not (Test-Path $Path) -or (Get-Item $Path).Length -eq 0) {
        Write-CpacError "UNREADABLE" $Path
    }

    try {
        $record = Get-Content $Path -Raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-CpacError "UNREADABLE" $Path
    }

    if ($null -eq $record -or $null -eq $record.metrics) {
        Write-CpacError "MISSING_KEY" "metrics"
    }
    foreach ($key in @("scenario_id", "condition", "model", "timestamp")) {
        $prop = $record.PSObject.Properties[$key]
        if ($null -eq $prop -or $null -eq $prop.Value -or $prop.Value -isnot [string] -or $prop.Value -eq "") {
            Write-CpacError "MISSING_KEY" $key
        }
    }

    $tokensIn = Get-MetricNumber $record.metrics "tokens_in"
    $tokensOut = Get-MetricNumber $record.metrics "tokens_out"
    $reworkTokensIn = Get-MetricNumber $record.metrics "rework_tokens_in"
    $reworkTokensOut = Get-MetricNumber $record.metrics "rework_tokens_out"
    $reworkLoops = Get-MetricNumber $record.metrics "rework_loops"
    $humanInterventions = Get-MetricNumber $record.metrics "human_interventions"
    $wallClock = Get-MetricNumber $record.metrics "wall_clock_seconds"
    $toolCallsTotal = Get-MetricNumber $record.metrics "tool_calls_total"
    $cacheRead = Get-MetricNumber $record.metrics "cache_read_tokens"

    $acceptedProp = $record.metrics.PSObject.Properties["accepted"]
    if ($null -eq $acceptedProp -or $null -eq $acceptedProp.Value) {
        Write-CpacError "MISSING_KEY" "accepted"
    }
    if ($acceptedProp.Value -isnot [bool]) {
        Write-CpacError "BAD_VALUE" "accepted"
    }
    $accepted = [bool]$acceptedProp.Value

    $infCost = ($tokensIn * $PriceIn) + ($tokensOut * $PriceOut)
    $rewCost = ($reworkTokensIn * $PriceIn) + ($reworkTokensOut * $PriceOut) + ($reworkLoops * $ReworkToolCost)
    $humCost = $humanInterventions * $HumanRate
    $total = [math]::Round($infCost + $rewCost + $humCost, 4)

    $cpacValue = ConvertTo-Invariant4 $total
    if (-not $accepted) { $cpacValue = "INF" }

    Write-Host ""
    Write-Host "📊 PromptKit OS CPAC Scorecard (Measured Telemetry)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "   Scenario: $($record.scenario_id) | Condition: $($record.condition) | Model: $($record.model)"
    Write-Host "   Timestamp: $($record.timestamp) | Wall-Clock: $wallClock`s"
    Write-Host "-----------------------|------------------" -ForegroundColor Gray
    "{0,-24} {1}" -f "Input Tokens (successful):", $tokensIn
    "{0,-24} {1}" -f "Output Tokens (successful):", $tokensOut
    "{0,-24} {1}" -f "Cache-Read Tokens (memo):", $cacheRead
    "{0,-24} {1}" -f "Failed Rework Loops:", $reworkLoops
    "{0,-24} {1}/{2}" -f "Loop Tokens In/Out:", $reworkTokensIn, $reworkTokensOut
    "{0,-24} {1}" -f "Tool Calls (total):", $toolCallsTotal
    "{0,-24} {1}" -f "Human Interventions:", $humanInterventions
    Write-Host "-----------------------|------------------" -ForegroundColor Gray
    "{0,-24} `${1}" -f "Inference Cost:", (ConvertTo-Invariant4 $infCost)
    "{0,-24} `${1} ($2 loops × τ_tool `${3} + loop-token inference)" -f "Rework Cost:", (ConvertTo-Invariant4 $rewCost), $reworkLoops, $ReworkToolCost
    "{0,-24} `${1}" -f "Human Cost:", (ConvertTo-Invariant4 $humCost)
    if ($accepted) {
        Write-Host ("{0,-24} `${1}" -f "Total CPAC:", $cpacValue) -ForegroundColor Green
    } else {
        Write-Host ("{0,-24} {1}" -f "Total CPAC:", "INF (REJECTED)") -ForegroundColor Yellow
    }
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    if (-not $accepted) {
        Write-Host "   ⚠️  accepted=false in the telemetry record: the run was not accepted, so CPAC is infinite by definition." -ForegroundColor Yellow
    }
    Write-Host "Methodology: docs/BENCHMARK-METHODOLOGY.md | Extractor: scripts/extract-commandcode-telemetry.ps1"

    Write-Output ("CPAC|MEASURED|scenario={0}|condition={1}|model={2}|tokens_in={3}|tokens_out={4}|cache_read_tokens={5}|rework_loops={6}|rework_tokens_in={7}|rework_tokens_out={8}|wall_clock_seconds={9}|human_interventions={10}|inference_usd={11}|rework_usd={12}|human_usd={13}|cpac_usd={14}" -f `
        $record.scenario_id, $record.condition, $record.model, $tokensIn, $tokensOut, $cacheRead, `
        $reworkLoops, $reworkTokensIn, $reworkTokensOut, $wallClock, $humanInterventions, `
        (ConvertTo-Invariant4 $infCost), (ConvertTo-Invariant4 $rewCost), (ConvertTo-Invariant4 $humCost), $cpacValue)
}

if ($SelfTest) {
    Run-SelfTest
}

if ($TargetPath) {
    Run-Ingest -Path $TargetPath
    exit 0
}

if ($Demo) {
    Write-Host "`n📊 PromptKit OS Benchmark Scorecard (Simulated Comparison)" -ForegroundColor Cyan
    Write-Host "   ⚠️  SIMULATED demonstration values — no telemetry was read; pass a §5 telemetry record for a measured result." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    "{0,-22} | {1,-16} | {2,-16}" -f "Dimension", "Condition A: Vanilla", "Condition B: PromptKit"
    Write-Host "-----------------------|------------------|------------------" -ForegroundColor Gray
    "{0,-22} | {1,-16} | {2,-16}" -f "Input Tokens", "48,200", "14,800"
    "{0,-22} | {1,-16} | {2,-16}" -f "Output Tokens", "5,400", "1,650"
    "{0,-22} | {1,-16} | {2,-16}" -f "Search / Edit Ratio", "8.4 (Exploratory)", "1.4 (Focused)"
    "{0,-22} | {1,-16} | {2,-16}" -f "Failed Rework Loops", "3 loops", "0 loops"
    "{0,-22} | {1,-16} | {2,-16}" -f "Invariant Violations", "1 (HMAC stringified)", "0 (All Invariants ✓)"
    "{0,-22} | {1,-16} | {2,-16}" -f "Human Intervention", "1 (12 mins)", "0 (Autonomous green)"
    "{0,-22} | {1,-16} | {2,-16}" -f "Wall-Clock Time", "9m 42s", "3m 15s"
    Write-Host "-----------------------|------------------|------------------" -ForegroundColor Gray
    "{0,-22} | {1,-16} | {2,-16}" -f "Inference Cost", "`$0.2256", "`$0.0692"
    "{0,-22} | {1,-16} | {2,-16}" -f "Rework Cost", "`$0.1500", "`$0.0000"
    "{0,-22} | {1,-16} | {2,-16}" -f "Human Cost", "`$20.0000", "`$0.0000"
    Write-Host ("{0,-22} | {1,-16} | {2,-16}" -f "Total CPAC", "`$20.3756", "`$0.0692 (-99.6%)") -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "Methodology: docs/BENCHMARK-METHODOLOGY.md | Scenarios: docs/specs/SPEC-empirical-benchmark.md"
    exit 0
}

Write-Host "Usage: measure-cpac.ps1 [-SelfTest] [-Demo] [-TargetPath telemetry.json]"
Write-Host "       measure-cpac.ps1 [-PriceIn N] [-PriceOut N] [-ReworkToolCost N] [-HumanRate N] -TargetPath telemetry.json"
Write-Host ""
Write-Host "With a telemetry path: scores a standardized telemetry record"
Write-Host "(docs/BENCHMARK-METHODOLOGY.md §5) and prints a measured CPAC scorecard;"
Write-Host "invalid records fail closed with exit 2. -SelfTest runs the CPAC formula"
Write-Host "self-tests. -Demo prints a SIMULATED demonstration scorecard (no"
Write-Host "telemetry is read). Extract telemetry from a Command Code session with"
Write-Host "scripts/extract-commandcode-telemetry.ps1."
