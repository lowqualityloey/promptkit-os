#!/usr/bin/env bash
# PromptKit OS Per-Task Token Measurement Utility
# Measures directive + workflow + gate payload for pk:fix, pk:plan, pk:ship
# Uses bytes/4 convention, same as measure-tokens.sh
set -euo pipefail

# Modes:
#   default  : informational report (unchanged behavior).
#   --strict : CI gate mode. After the report, asserts every measured per-task payload
#              stays <= its recorded historical baseline below. Machine-parseable lines:
#              BASELINE|task/profile|measured|limit|PASS|FAIL
STRICT=0
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=1 ;;
        -h|--help) echo "Usage: measure-per-task-tokens.sh [--strict]"; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$SCRIPT_DIR/.."

# Templates
TEMPLATE_FULL="$KIT_DIR/templates/agent-directive-template.md"
TEMPLATE_LITE="$KIT_DIR/templates/agent-directive-lite-template.md"

measure_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "0"
        return
    fi
    local chars
    chars=$(wc -c < "$file" | tr -d ' ')
    echo $(( (chars + 2) / 4 ))
}

# Measure directives
FULL_TOK=$(measure_file "$TEMPLATE_FULL")
LITE_TOK=$(measure_file "$TEMPLATE_LITE")
ROUTE_TOK=$(measure_file "$KIT_DIR/workflows/route.md")
GATE_TOK=$(measure_file "$KIT_DIR/protocols/code-quality-gate.md")

# Workflows
FIX_TOK=$(measure_file "$KIT_DIR/workflows/fix.md")
PLAN_TOK=$(measure_file "$KIT_DIR/workflows/plan.md")
SHIP_TOK=$(measure_file "$KIT_DIR/workflows/ship.md")
TECH_SPEC_TOK=$(measure_file "$KIT_DIR/templates/tech-spec-template.md")
RELEASE_CHECKLIST_TOK=$(measure_file "$KIT_DIR/templates/release-checklist.md")

echo ""
echo "📊 PromptKit OS Per-Task Token Analysis (bytes/4)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repo SHA: $(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
echo "Date: $(date +%Y-%m-%d)"
echo ""

echo "Static Directives:"
echo "  Full (Balanced): $FULL_TOK tok ($(wc -c < "$TEMPLATE_FULL" | tr -d ' ') chars)"
echo "  Lite:            $LITE_TOK tok ($(wc -c < "$TEMPLATE_LITE" | tr -d ' ') chars)"
echo "  Route (old mandatory load): $ROUTE_TOK tok"
echo "  Gate: $GATE_TOK tok"
echo ""

echo "Workflows:"
echo "  fix.md: $FIX_TOK tok"
echo "  plan.md: $PLAN_TOK tok"
echo "  ship.md: $SHIP_TOK tok (after extraction, was ~8,292 tok before)"
echo ""

# Calculate per-task payloads
# Baseline = old behavior: directive (1882) + route (6962) + workflow + gate + template
# New = directive (full or lite) + workflow + gate + template (no route)

# Use measured values for calculation, but also show baseline from token-efficiency-review.md
BASELINE_FIX=12861
BASELINE_PLAN=24666
BASELINE_SHIP=24761

JIT_FIX_FULL=$(( FULL_TOK + FIX_TOK + GATE_TOK ))
JIT_PLAN_FULL=$(( FULL_TOK + PLAN_TOK + TECH_SPEC_TOK + GATE_TOK ))
JIT_SHIP_FULL=$(( FULL_TOK + SHIP_TOK + RELEASE_CHECKLIST_TOK + GATE_TOK ))

JIT_FIX_LITE=$(( LITE_TOK + FIX_TOK + GATE_TOK ))
JIT_PLAN_LITE=$(( LITE_TOK + PLAN_TOK + TECH_SPEC_TOK + GATE_TOK ))
JIT_SHIP_LITE=$(( LITE_TOK + SHIP_TOK + RELEASE_CHECKLIST_TOK + GATE_TOK ))

echo "Per-Task Payloads (after Change A - no mandatory route load):"
printf "  %-10s Balanced: %5d tok | Lite: %5d tok | Baseline: %5d tok | Saving Balanced: %5d tok (%d%%)\n" "pk:fix" "$JIT_FIX_FULL" "$JIT_FIX_LITE" "$BASELINE_FIX" "$((BASELINE_FIX - JIT_FIX_FULL))" "$((100 - JIT_FIX_FULL*100/BASELINE_FIX))"
printf "  %-10s Balanced: %5d tok | Lite: %5d tok | Baseline: %5d tok | Saving Balanced: %5d tok (%d%%)\n" "pk:plan" "$JIT_PLAN_FULL" "$JIT_PLAN_LITE" "$BASELINE_PLAN" "$((BASELINE_PLAN - JIT_PLAN_FULL))" "$((100 - JIT_PLAN_FULL*100/BASELINE_PLAN))"
printf "  %-10s Balanced: %5d tok | Lite: %5d tok | Baseline: %5d tok | Saving Balanced: %5d tok (%d%%)\n" "pk:ship" "$JIT_SHIP_FULL" "$JIT_SHIP_LITE" "$BASELINE_SHIP" "$((BASELINE_SHIP - JIT_SHIP_FULL))" "$((100 - JIT_SHIP_FULL*100/BASELINE_SHIP))"

echo ""
echo "Key Insights:"
echo "  - Change A (remove mandatory route.md load) saves ~6,915 tok per task (route 6,962 tok - directive growth 47 tok)"
echo "  - Lite vs Balanced saves additional $((FULL_TOK - LITE_TOK)) tok static (-$(( (FULL_TOK - LITE_TOK)*100/FULL_TOK ))%)"
echo "  - 90% claim is static-only (1,928 tok vs 18.5k monolithic), per-task saving is 28-54% Balanced, 33-63% Lite"
echo ""
echo "Verification:"
echo "  bash scripts/measure-tokens.sh # static directive"
echo "  bash scripts/measure-per-task-tokens.sh # this script"
echo "  bash scripts/validate-references.sh . # no broken links"
echo ""

if [[ "$STRICT" -eq 1 ]]; then
    GATE_FAIL=0
    check_baseline() {
        local name="$1" payload="$2" limit="$3"
        if [[ "$payload" -le "$limit" ]]; then
            echo "BASELINE|${name}|${payload}|${limit}|PASS"
        else
            echo "BASELINE|${name}|${payload}|${limit}|FAIL (exceeds recorded baseline by $(( payload - limit )) tokens)"
            GATE_FAIL=1
        fi
    }
    echo "Strict baseline gate (bytes/4):"
    check_baseline "pk:fix/balanced"   "$JIT_FIX_FULL"   "$BASELINE_FIX"
    check_baseline "pk:plan/balanced"  "$JIT_PLAN_FULL"  "$BASELINE_PLAN"
    check_baseline "pk:ship/balanced"  "$JIT_SHIP_FULL"  "$BASELINE_SHIP"
    check_baseline "pk:fix/lite"       "$JIT_FIX_LITE"   "$BASELINE_FIX"
    check_baseline "pk:plan/lite"      "$JIT_PLAN_LITE"  "$BASELINE_PLAN"
    check_baseline "pk:ship/lite"      "$JIT_SHIP_LITE"  "$BASELINE_SHIP"
    if [[ "$GATE_FAIL" -eq 1 ]]; then
        echo ""
        echo "❌ Per-task baseline gate FAILED: current payloads exceed the historical baselines encoded in this script (docs/BENCHMARKS.md section 3)." >&2
        exit 1
    fi
    echo ""
    echo "✅ Per-task baseline gate passed for all profiles."
fi
