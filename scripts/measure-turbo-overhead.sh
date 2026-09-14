#!/usr/bin/env bash
# PromptKit OS Turbo Overhead Estimator (issue #145)
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
# Usage: bash scripts/measure-turbo-overhead.sh [--strict]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$SCRIPT_DIR/.."

STRICT=0
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=1 ;;
        -h|--help) echo "Usage: measure-turbo-overhead.sh [--strict]"; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# --- live inputs (bytes/4 convention, same as measure-tokens.sh) ---
tok_of() { local c; c=$(tr -d '\r' < "$1" | wc -c | tr -d ' '); echo $(( (c + 2) / 4 )); }
DIR_TOK=$(tok_of "$KIT_DIR/templates/agent-directive-template.md")
GATE_TOK=$(tok_of "$KIT_DIR/protocols/code-quality-gate.md")
FIX_TOK=$(tok_of "$KIT_DIR/workflows/fix.md")
PLAN_TOK=$(tok_of "$KIT_DIR/workflows/plan.md")
SHIP_TOK=$(tok_of "$KIT_DIR/workflows/ship.md")
TECH_TOK=$(tok_of "$KIT_DIR/templates/tech-spec-template.md")
RELIST_TOK=$(tok_of "$KIT_DIR/templates/release-checklist.md")
SYNTH_TOK=250

BAL_FIX=$(( DIR_TOK + FIX_TOK + GATE_TOK ))
BAL_PLAN=$(( DIR_TOK + PLAN_TOK + TECH_TOK + GATE_TOK ))
BAL_SHIP=$(( DIR_TOK + SHIP_TOK + RELIST_TOK + GATE_TOK ))

# touchpoints: count, k per touchpoint (see header anchors)
# fix: 1 tp k=1 ; plan: 1 tp k=2 ; ship: 2 tps k=2 + k=1
L_BRANCH=$(( DIR_TOK + SYNTH_TOK ))
calc_turbo() { # $1=bal $2=pathkey -> sets TUR_LO TUR_HI TIME_BOUND
    local bal="$1" key="$2" extra_lo=0 extra_hi=0
    case "$key" in
        fix)   extra_lo=0;                        extra_hi=0;                        TIME_BOUND="0% (single-thread path)" ;;
        plan)  extra_lo=$(( 1 * L_BRANCH ));      extra_hi=$(( 1 * (bal + SYNTH_TOK) )); TIME_BOUND="<=50% of spike segment" ;;
        ship)  extra_lo=$(( 1 * L_BRANCH + 0 ));  extra_hi=$(( 1 * (bal + SYNTH_TOK) )); TIME_BOUND="<=50% of QA-review segment" ;;
    esac
    TUR_LO=$(( bal + extra_lo ))
    TUR_HI=$(( bal + extra_hi ))
}

fmt_mult() { # $1 bal $2 lo $3 hi -> "lox-hix"
    awk -v b="$1" -v l="$2" -v h="$3" 'BEGIN { printf "%.2fx-%.2fx", l/b, h/b }'
}

echo ""
echo "📊 PromptKit OS Turbo Protocol Overhead (static bounds, bytes/4)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Directive: ${DIR_TOK} tok · per-task balanced payloads measured live · synthesis return cap: ${SYNTH_TOK} tok"
echo ""
printf "%-8s | %-12s | %-22s | %-16s | %-28s | %s\n" "Task" "Balanced tok" "Turbo tok (lower-upper)" "Multiplier" "Time saved est (bound)" "Notes"
printf -- "---------|--------------|-------------------------|------------------|------------------------------|------------------------\n"

for key in fix plan ship; do
    case "$key" in
        fix)  bal=$BAL_FIX;  note="Tier-3 offload only; Turbo adds no wave" ;;
        plan) bal=$BAL_PLAN; note="Pattern A spike, k=2 branches" ;;
        ship) bal=$BAL_SHIP; note="Pattern B QA axes k=2 + Pattern C verifier" ;;
    esac
    calc_turbo "$bal" "$key"
    printf "%-8s | %-12s | %-22s | %-16s | %-28s | %s\n" "pk:$key" "$bal" "${TUR_LO}-${TUR_HI}" "$(fmt_mult "$bal" "$TUR_LO" "$TUR_HI")" "$TIME_BOUND" "$note"
done

# --- AC-3 safety invariant (grep-asserted) ---
INV_COUNT=$(grep -rlEi 'human (approval|L3|decision).*turbo|turbo.*human (approval|L3|decision)' "$KIT_DIR/templates/lite-profile.md" "$KIT_DIR/workflows/onboard.md" "$KIT_DIR/workflows/profile.md" "$KIT_DIR/init.sh" 2>/dev/null | wc -l | tr -d ' ')
echo ""
if [ "$INV_COUNT" -ge 3 ]; then
    echo "AC-3 invariant: OK (human L3 approval required under Turbo, asserted in ${INV_COUNT} shipped sources)"
else
    echo "AC-3 invariant: VIOLATED (found in only ${INV_COUNT}/4 Turbo sources)" >&2
    exit 1
fi

if [ "$STRICT" -eq 1 ]; then
    # Claim window recorded in docs/BENCHMARKS.md section 8. If the measured
    # UPPER-bound multiplier exceeds DOC_MAX (or the path model collapses below
    # DOC_MIN where waves exist), the docs claim is stale -> CI fails.
    DOC_MIN="1.00"
    DOC_MAX="2.60"
    calc_turbo "$BAL_PLAN" plan; M_HI_PLAN=$(awk -v b="$BAL_PLAN" -v h="$TUR_HI" 'BEGIN { printf "%.2f", h/b }')
    calc_turbo "$BAL_SHIP" ship; M_HI_SHIP=$(awk -v b="$BAL_SHIP" -v h="$TUR_HI" 'BEGIN { printf "%.2f", h/b }')
    for pair in "plan:$M_HI_PLAN" "ship:$M_HI_SHIP"; do
        m="${pair#*:}"
        viol=$(awk -v m="$m" -v lo="$DOC_MIN" -v hi="$DOC_MAX" 'BEGIN { print (m >= lo && m <= hi) ? "ok" : "FAIL" }')
        if [ "$viol" != "ok" ]; then
            echo "STRICT|${pair%%:*}|${m}|claim-window ${DOC_MIN}-${DOC_MAX}|FAIL" >&2
            echo "❌ Turbo overhead gate FAILED: measured upper multiplier ${m} outside docs claim (BENCHMARKS §8)." >&2
            exit 1
        fi
        echo "STRICT|${pair%%:*}|${m}|claim-window ${DOC_MIN}-${DOC_MAX}|PASS"
    done
    echo "✅ Turbo overhead claim within documented window."
fi
exit 0
