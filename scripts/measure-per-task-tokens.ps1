#!/usr/bin/env pwsh
# PromptKit OS Per-Task Token Measurement Utility (PowerShell twin)
# Measures directive + workflow + gate payload for pk:fix, pk:plan, pk:ship
# Uses bytes/4 convention, same as measure-tokens.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Modes:
#   default  : informational report (unchanged behavior).
#   --strict : CI gate mode. After the report, asserts every measured per-task payload
#              stays <= its recorded historical baseline below. Machine-parseable lines:
#              BASELINE|task/profile|measured|limit|PASS|FAIL
$STRICT = 0
foreach ($arg in $args) {
    switch ($arg) {
        "--strict" { $STRICT = 1 }
        "-h" { Write-Output "Usage: measure-per-task-tokens.ps1 [--strict]"; exit 0 }
        "--help" { Write-Output "Usage: measure-per-task-tokens.ps1 [--strict]"; exit 0 }
        default { Write-Error "Unknown argument: $arg"; exit 2 }
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KitDir = Resolve-Path (Join-Path $ScriptDir "..")

# Templates
$TemplateFull = Join-Path $KitDir "templates/agent-directive-template.md"
$TemplateLite = Join-Path $KitDir "templates/agent-directive-lite-template.md"

function Measure-File {
    param([string]$File)
    if (-not (Test-Path $File -PathType Leaf)) {
        return 0
    }
    $bytes = [System.IO.File]::ReadAllBytes($File)
    $cleanBytes = $bytes | Where-Object { $_ -ne 13 }
    $chars = $cleanBytes.Count
    return [int](($chars + 2) / 4)
}

function Get-CharCount {
    param([string]$File)
    $bytes = [System.IO.File]::ReadAllBytes($File)
    $cleanBytes = $bytes | Where-Object { $_ -ne 13 }
    return $cleanBytes.Count
}

# Measure directives
$FULL_TOK = Measure-File $TemplateFull
$LITE_TOK = Measure-File $TemplateLite
$ROUTE_TOK = Measure-File (Join-Path $KitDir "workflows/route.md")
$GATE_TOK = Measure-File (Join-Path $KitDir "protocols/code-quality-gate.md")

# Workflows
$FIX_TOK = Measure-File (Join-Path $KitDir "workflows/fix.md")
$PLAN_TOK = Measure-File (Join-Path $KitDir "workflows/plan.md")
$SHIP_TOK = Measure-File (Join-Path $KitDir "workflows/ship.md")
$TECH_SPEC_TOK = Measure-File (Join-Path $KitDir "templates/tech-spec-template.md")
$RELEASE_CHECKLIST_TOK = Measure-File (Join-Path $KitDir "templates/release-checklist.md")

Write-Output ""
Write-Output "📊 PromptKit OS Per-Task Token Analysis (bytes/4)"
Write-Output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
try {
    $sha = git -C $KitDir rev-parse --short HEAD 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Output "Repo SHA: $sha" } else { Write-Output "Repo SHA: unknown" }
} catch {
    Write-Output "Repo SHA: unknown"
}
Write-Output "Date: $(Get-Date -Format 'yyyy-MM-dd')"
Write-Output ""

Write-Output "Static Directives:"
Write-Output "  Full (Balanced): $FULL_TOK tok ($(Get-CharCount $TemplateFull) chars)"
Write-Output "  Lite:            $LITE_TOK tok ($(Get-CharCount $TemplateLite) chars)"
Write-Output "  Route (old mandatory load): $ROUTE_TOK tok"
Write-Output "  Gate: $GATE_TOK tok"
Write-Output ""

Write-Output "Workflows:"
Write-Output "  fix.md: $FIX_TOK tok"
Write-Output "  plan.md: $PLAN_TOK tok"
Write-Output "  ship.md: $SHIP_TOK tok (after extraction, was ~8,292 tok before)"
Write-Output ""

# Calculate per-task payloads
$BASELINE_FIX = 12861
$BASELINE_PLAN = 24666
$BASELINE_SHIP = 24761

$JIT_FIX_FULL = $FULL_TOK + $FIX_TOK + $GATE_TOK
$JIT_PLAN_FULL = $FULL_TOK + $PLAN_TOK + $TECH_SPEC_TOK + $GATE_TOK
$JIT_SHIP_FULL = $FULL_TOK + $SHIP_TOK + $RELEASE_CHECKLIST_TOK + $GATE_TOK

$JIT_FIX_LITE = $LITE_TOK + $FIX_TOK + $GATE_TOK
$JIT_PLAN_LITE = $LITE_TOK + $PLAN_TOK + $TECH_SPEC_TOK + $GATE_TOK
$JIT_SHIP_LITE = $LITE_TOK + $SHIP_TOK + $RELEASE_CHECKLIST_TOK + $GATE_TOK

Write-Output "Per-Task Payloads (after Change A - no mandatory route load):"

function Format-PayloadLine {
    param([string]$Task, [int]$Bal, [int]$Lite, [int]$Base)
    $Save = $Base - $Bal
    $Pct = [int](100 - $Bal * 100 / $Base)
    printf "  %-10s Balanced: %5d tok | Lite: %5d tok | Baseline: %5d tok | Saving Balanced: %5d tok (%d%%)`n" $Task $Bal $Lite $Base $Save $Pct
}

Format-PayloadLine "pk:fix" $JIT_FIX_FULL $JIT_FIX_LITE $BASELINE_FIX
Format-PayloadLine "pk:plan" $JIT_PLAN_FULL $JIT_PLAN_LITE $BASELINE_PLAN
Format-PayloadLine "pk:ship" $JIT_SHIP_FULL $JIT_SHIP_LITE $BASELINE_SHIP

Write-Output ""
Write-Output "Key Insights:"
Write-Output "  - Change A (remove mandatory route.md load) saves ~6,915 tok per task (route 6,962 tok - directive growth 47 tok)"
Write-Output "  - Lite vs Balanced saves additional $($FULL_TOK - $LITE_TOK) tok static (-$(( ($FULL_TOK - $LITE_TOK)*100/$FULL_TOK ))%%)"
Write-Output "  - 90% claim is static-only (1,928 tok vs 18.5k monolithic), per-task saving is 28-54% Balanced, 33-63% Lite"
Write-Output ""
Write-Output "Verification:"
Write-Output "  pwsh -File scripts/measure-tokens.ps1 # static directive"
Write-Output "  pwsh -File scripts/measure-per-task-tokens.ps1 # this script"
Write-Output "  bash scripts/validate-references.sh . # no broken links"
Write-Output ""

if ($STRICT -eq 1) {
    $GATE_FAIL = 0
    function Check-Baseline {
        param([string]$Name, [int]$Payload, [int]$Limit)
        if ($Payload -le $Limit) {
            Write-Output "BASELINE|$Name|$Payload|$Limit|PASS"
        } else {
            Write-Output "BASELINE|$Name|$Payload|$Limit|FAIL (exceeds recorded baseline by $($Payload - $Limit) tokens)"
            $script:GATE_FAIL = 1
        }
    }
    Write-Output "Strict baseline gate (bytes/4):"
    Check-Baseline "pk:fix/balanced"   $JIT_FIX_FULL   $BASELINE_FIX
    Check-Baseline "pk:plan/balanced"  $JIT_PLAN_FULL  $BASELINE_PLAN
    Check-Baseline "pk:ship/balanced"  $JIT_SHIP_FULL  $BASELINE_SHIP
    Check-Baseline "pk:fix/lite"       $JIT_FIX_LITE   $BASELINE_FIX
    Check-Baseline "pk:plan/lite"      $JIT_PLAN_LITE  $BASELINE_PLAN
    Check-Baseline "pk:ship/lite"      $JIT_SHIP_LITE  $BASELINE_SHIP
    if ($GATE_FAIL -eq 1) {
        Write-Output ""
        Write-Error "❌ Per-task baseline gate FAILED: current payloads exceed the historical baselines encoded in this script (docs/BENCHMARKS.md section 3)."
        exit 1
    }
    Write-Output ""
    Write-Output "✅ Per-task baseline gate passed for all profiles."
}
exit 0
