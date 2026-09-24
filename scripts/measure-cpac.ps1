<#
.SYNOPSIS
    PromptKit OS Cost Per Accepted Change (CPAC) Measurement Utility (PowerShell)
.DESCRIPTION
    Computes empirical telemetry metrics, token economics, and rework costs.
#>
[CmdletBinding()]
param (
    [switch]$SelfTest,
    [string]$TargetPath
)

$PriceInPerToken = 0.000003   # $3.00 per 1M input tokens
$PriceOutPerToken = 0.000015  # $15.00 per 1M output tokens
$ReworkPenaltyUsd = 0.05      # Execution penalty per failed loop
$HumanInterventionUsd = 8.33  # 5 minutes of engineering review @ $100/hr

# Calculate-Cpac implements the successful-turn/rework split:
# TokensIn: T_successful_in (prompt tokens from successful conversation turns)
# TokensOut: T_successful_out (completion tokens from successful conversation turns)
# ReworkLoops: R (failed verification loop iterations)
# HumanInterventions: N_human (developer intervention units)
# Accepted: boolean flag
function Calculate-Cpac {
    param (
        [double]$TokensIn,
        [double]$TokensOut,
        [double]$ReworkLoops,
        [double]$HumanInterventions,
        [bool]$Accepted
    )

    $infCost = ($TokensIn * $PriceInPerToken) + ($TokensOut * $PriceOutPerToken)
    $rewCost = $ReworkLoops * $ReworkPenaltyUsd
    $humCost = $HumanInterventions * $HumanInterventionUsd
    $totalCost = [math]::Round($infCost + $rewCost + $humCost, 4)

    if ($Accepted) {
        return "$totalCost"
    } else {
        return "INF (REJECTED)"
    }
}

function Run-SelfTest {
    Write-Host "`n🧪 PromptKit OS CPAC Measurement Self-Test (PowerShell)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    # Test 1: Ideal Clean Run
    $cpacIdeal = Calculate-Cpac -TokensIn 15000 -TokensOut 1500 -ReworkLoops 0 -HumanInterventions 0 -Accepted $true
    if ($cpacIdeal -eq "0.0675") {
        Write-Host "✅ Test 1 Passed: Ideal run CPAC = `$$cpacIdeal" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 1 Failed: Expected 0.0675, got $cpacIdeal" -ForegroundColor Red
        exit 1
    }

    # Test 2: Unconstrained Run with Rework
    $cpacRework = Calculate-Cpac -TokensIn 45000 -TokensOut 6000 -ReworkLoops 3 -HumanInterventions 1 -Accepted $true
    if ($cpacRework -eq "8.705") {
        Write-Host "✅ Test 2 Passed: Rework run CPAC = `$$cpacRework" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 2 Failed: Expected 8.705, got $cpacRework" -ForegroundColor Red
        exit 1
    }

    # Test 3: Rejected Run
    $cpacRejected = Calculate-Cpac -TokensIn 20000 -TokensOut 2000 -ReworkLoops 2 -HumanInterventions 1 -Accepted $false
    if ($cpacRejected -eq "INF (REJECTED)") {
        Write-Host "✅ Test 3 Passed: Rejected run CPAC = $cpacRejected" -ForegroundColor Green
    } else {
        Write-Host "❌ Test 3 Failed: Expected INF (REJECTED), got $cpacRejected" -ForegroundColor Red
        exit 1
    }

    Write-Host "`n✅ All CPAC measurement self-tests PASSED.`n" -ForegroundColor Green
    exit 0
}

if ($SelfTest) {
    Run-SelfTest
}

Write-Host "`n📊 PromptKit OS Benchmark Scorecard (Simulated Comparison)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
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
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "Methodology: docs/BENCHMARK-METHODOLOGY.md | Scenarios: docs/specs/SPEC-empirical-benchmark.md"
