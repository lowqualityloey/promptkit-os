#!/usr/bin/env pwsh
# PromptKit OS Turbo Overhead Estimator (PowerShell twin) (issue #145)
# Static, deterministic analysis of the Turbo profile's parallel subagent-wave
# protocol versus sequential (Balanced) delegation.
#
# MODEL (documented in docs/BENCHMARKS.md section 8):
#   A subagent under Turbo runs in a FRESH CONTEXT. Per parallel branch beyond
#   the first, the protocol costs:
#     LOWER bound: directive reload + 250 tok compact-synthesis return
#     UPPER bound: full task-path context reload per branch + 250 tok synthesis
#   turbo_tok(t) = balanced_tok(t) + SUM_over_touchpoints (k - 1) * X   , X in {L,U}
#   "Time saved est" is the STRUCTURAL UPPER BOUND only: (k-1)/k of the
#   parallelized segment wall-time. It is NOT a measured second-count; real
#   hosts vary. Never restate it as an empirical latency figure.
#
# Fan-out touchpoints (grep-verifiable anchors, verified 2026-09-14):
#   pk:fix   : workflows/route.md Tier 3 (>3-file offload = single branch, k=1)
#   pk:plan  : protocols/subagent-delegation.md Pattern A (competing-candidate
#              spike fan-out, k=2) reached via pk:spike during planning
#   pk:ship  : Pattern B dual-axis QA review (k=2) + Pattern C single-pass
#              verifier (k=1) in the release evidence path
#
# Usage: pwsh -File scripts/measure-turbo-overhead.ps1 [--strict]
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KitDir = Resolve-Path (Join-Path $ScriptDir "..")

$STRICT = 0
foreach ($arg in $args) {
    switch ($arg) {
        "--strict" { $STRICT = 1 }
        "-h" { Write-Output "Usage: measure-turbo-overhead.ps1 [--strict]"; exit 0 }
        "--help" { Write-Output "Usage: measure-turbo-overhead.ps1 [--strict]"; exit 0 }
        default { Write-Error "Unknown argument: $arg"; exit 2 }
    }
}

# --- live inputs (bytes/4 convention, same as measure-tokens.ps1) ---
function TokOf {
    param([string]$File)
    $bytes = [System.IO.File]::ReadAllBytes($File)
    $cleanBytes = $bytes | Where-Object { $_ -ne 13 }
    return [int](($cleanBytes.Count + 2) / 4)
}

$DIR_TOK = TokOf (Join-Path $KitDir "templates/agent-directive-template.md")
$GATE_TOK = TokOf (Join-Path $KitDir "protocols/code-quality-gate.md")
$FIX_TOK = TokOf (Join-Path $KitDir "workflows/fix.md")
$PLAN_TOK = TokOf (Join-Path $KitDir "workflows/plan.md")
$SHIP_TOK = TokOf (Join-Path $KitDir "workflows/ship.md")
$TECH_TOK = TokOf (Join-Path $KitDir "templates/tech-spec-template.md")
$RELIST_TOK = TokOf (Join-Path $KitDir "templates/release-checklist.md")
$SYNTH_TOK = 250

$BAL_FIX = $DIR_TOK + $FIX_TOK + $GATE_TOK
$BAL_PLAN = $DIR_TOK + $PLAN_TOK + $TECH_TOK + $GATE_TOK
$BAL_SHIP = $DIR_TOK + $SHIP_TOK + $RELIST_TOK + $GATE_TOK

# touchpoints: count, k per touchpoint (see header anchors)
# fix: 1 tp k=1 ; plan: 1 tp k=2 ; ship: 2 tps k=2 + k=1
$L_BRANCH = $DIR_TOK + $SYNTH_TOK

function Calc-Turbo {
    param([int]$Bal, [string]$Key)
    $extra_lo = 0
    $extra_hi = 0
    $time_bound = ""
    switch ($Key) {
        "fix" {
            $extra_lo = 0
            $extra_hi = 0
            $time_bound = "0% (single-thread path)"
        }
        "plan" {
            $extra_lo = 1 * $L_BRANCH
            $extra_hi = 1 * ($bal + $SYNTH_TOK)
            $time_bound = "<=50% of spike segment"
        }
        "ship" {
            $extra_lo = 1 * $L_BRANCH + 0
            $extra_hi = 1 * ($bal + $SYNTH_TOK)
            $time_bound = "<=50% of QA-review segment"
        }
    }
    $TUR_LO = $bal + $extra_lo
    $TUR_HI = $bal + $extra_hi
    return @{ Lo = $TUR_LO; Hi = $TUR_HI; TimeBound = $time_bound }
}

function FmtMult {
    param([int]$Bal, [int]$Lo, [int]$Hi)
    $l = $Lo / $Bal
    $h = $Hi / $Bal
    return "{0:N2}x-{1:N2}x" -f $l, $h
}

Write-Output ""
Write-Output "📊 PromptKit OS Turbo Protocol Overhead (static bounds, bytes/4)"
Write-Output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Output "Directive: ${DIR_TOK} tok · per-task balanced payloads measured live · synthesis return cap: ${SYNTH_TOK} tok"
Write-Output ""

$header = "| Task     | Balanced tok | Turbo tok (lower-upper) | Multiplier    | Time saved est (bound)     | Notes                        |"
$separator = "|----------|--------------|-------------------------|---------------|----------------------------|------------------------------|"
Write-Output $header
Write-Output $separator

$results = @()
foreach ($key in @("fix", "plan", "ship")) {
    switch ($key) {
        "fix"  { $bal = $BAL_FIX;  $note = "Tier-3 offload only; Turbo adds no wave" }
        "plan" { $bal = $BAL_PLAN; $note = "Pattern A spike, k=2 branches" }
        "ship" { $bal = $BAL_SHIP; $note = "Pattern B QA axes k=2 + Pattern C verifier" }
    }
    $calc = Calc-Turbo $bal $key
    $mult = FmtMult $bal $calc.Lo $calc.Hi
    $results += "| pk:$key | $bal | $($calc.Lo)-$($calc.Hi) | $mult | $($calc.TimeBound) | $note |"
}

foreach ($line in $results) { Write-Output $line }

# --- AC-3 safety invariant (grep-asserted) ---
$sources = @(
    (Join-Path $KitDir "templates/lite-profile.md"),
    (Join-Path $KitDir "workflows/onboard.md"),
    (Join-Path $KitDir "workflows/profile.md"),
    (Join-Path $KitDir "init.sh")
)
$pattern = 'human (approval|L3|decision).*turbo|turbo.*human (approval|L3|decision)'
$inv_count = 0
foreach ($src in $sources) {
    if (Test-Path $src) {
        $content = Get-Content $src -Raw
        if ($content -match $pattern) { $inv_count++ }
    }
}

Write-Output ""
if ($inv_count -ge 3) {
    Write-Output "AC-3 invariant: OK (human L3 approval required under Turbo, asserted in ${inv_count} shipped sources)"
} else {
    Write-Error "AC-3 invariant: VIOLATED (found in only ${inv_count}/4 Turbo sources)"
    exit 1
}

if ($STRICT -eq 1) {
    # Claim window recorded in docs/BENCHMARKS.md section 8. If the measured
    # UPPER-bound multiplier exceeds DOC_MAX (or the path model collapses below
    # DOC_MIN where waves exist), the docs claim is stale -> CI fails.
    $DOC_MIN = 1.00
    $DOC_MAX = 2.60
    
    $plan_calc = Calc-Turbo $BAL_PLAN "plan"
    $ship_calc = Calc-Turbo $BAL_SHIP "ship"
    
    $m_hi_plan = $plan_calc.Hi / $BAL_PLAN
    $m_hi_ship = $ship_calc.Hi / $BAL_SHIP
    
    foreach ($pair in @("plan:$m_hi_plan", "ship:$m_hi_ship")) {
        $parts = $pair -split ':'
        $name = $parts[0]
        $m = [double]$parts[1]
        
        if ($m -ge $DOC_MIN -and $m -le $DOC_MAX) {
            Write-Output "STRICT|${name}|${m}|claim-window ${DOC_MIN}-${DOC_MAX}|PASS"
        } else {
            Write-Error "STRICT|${name}|${m}|claim-window ${DOC_MIN}-${DOC_MAX}|FAIL"
            Write-Error "❌ Turbo overhead gate FAILED: measured upper multiplier ${m} outside docs claim (BENCHMARKS §8)."
            exit 1
        }
    }
    Write-Output "✅ Turbo overhead claim within documented window."
}
exit 0
