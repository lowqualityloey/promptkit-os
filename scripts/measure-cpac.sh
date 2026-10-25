#!/usr/bin/env bash
# PromptKit OS Cost Per Accepted Change (CPAC) Measurement Utility
# Scores a standardized telemetry record (docs/BENCHMARK-METHODOLOGY.md §5)
# with the CPAC formula, provides offline self-tests for that formula, and
# prints a SIMULATED demonstration scorecard under --demo only. Host
# transcript extraction into the §5 record is provided by
# scripts/extract-commandcode-telemetry.sh (Command Code sessions).
set -euo pipefail

# Standard Pricing Constants (USD) — overridable by flag for cross-model runs
PRICE_IN_PER_TOKEN="0.000003"    # $3.00 per 1M input tokens
PRICE_OUT_PER_TOKEN="0.000015"   # $15.00 per 1M output tokens
REWORK_TOOL_COST_USD="0.05"      # tau_tool: infrastructure execution cost per failed loop
HUMAN_INTERVENTION_USD="8.33"    # 5 minutes of engineering review @ $100/hr

SELF_TEST=0
DEMO=0
TARGET_FILE=""

usage() {
    echo "Usage: measure-cpac.sh [--self-test] [--demo] [telemetry.json]"
    echo "       measure-cpac.sh [--price-in=N] [--price-out=N] [--rework-tool-cost=N] [--human-rate=N] telemetry.json"
    echo ""
    echo "With a telemetry.json path: scores a standardized telemetry record"
    echo "(docs/BENCHMARK-METHODOLOGY.md §5) and prints a measured CPAC scorecard;"
    echo "invalid records fail closed with exit 2. --self-test runs the CPAC"
    echo "formula self-tests. --demo prints a SIMULATED demonstration scorecard"
    echo "(no telemetry is read). Extract telemetry from a Command Code session"
    echo "with scripts/extract-commandcode-telemetry.sh."
}

for arg in "$@"; do
    case "$arg" in
        --self-test) SELF_TEST=1 ;;
        --demo) DEMO=1 ;;
        --price-in=*) PRICE_IN_PER_TOKEN="${arg#--price-in=}" ;;
        --price-out=*) PRICE_OUT_PER_TOKEN="${arg#--price-out=}" ;;
        --rework-tool-cost=*) REWORK_TOOL_COST_USD="${arg#--rework-tool-cost=}" ;;
        --human-rate=*) HUMAN_INTERVENTION_USD="${arg#--human-rate=}" ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*|-*-*)
            printf 'CPAC|ERROR|UNKNOWN_FLAG|%s\n' "$arg" >&2
            exit 2
            ;;
        *) TARGET_FILE="$arg" ;;
    esac
done

for price in "$PRICE_IN_PER_TOKEN" "$PRICE_OUT_PER_TOKEN" "$REWORK_TOOL_COST_USD" "$HUMAN_INTERVENTION_USD"; do
    if [[ ! "$price" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        printf 'CPAC|ERROR|BAD_VALUE|%s\n' "$price" >&2
        printf 'Pricing flags must be non-negative numbers: --price-in=N --price-out=N --rework-tool-cost=N --human-rate=N\n' >&2
        exit 2
    fi
done

cpac_error() {
    printf 'CPAC|ERROR|%s|%s\n' "$1" "$2" >&2
    exit 2
}

# calculate_cpac implements the successful-turn/rework split of the §2
# methodology, including the §2B per-loop rework formula:
# tin:  T_successful_in  (prompt tokens from successful conversation turns)
# tout: T_successful_out (completion tokens from successful conversation turns)
# rtin: rework-loop prompt tokens (sum of T_loop(k) input)
# rtout: rework-loop completion tokens (sum of T_loop(k) output)
# rework: R (failed verification loop iterations)
# human: N_human (developer intervention units)
# accepted: boolean flag
# C_rework = (rtin * P_in + rtout * P_out) + R * tau_tool — loop tokens are
# priced at the same rates and excluded from C_inference (no double counting).
calculate_cpac() {
    local tin="$1"
    local tout="$2"
    local rtin="$3"
    local rtout="$4"
    local rework="$5"
    local human="$6"
    local accepted="$7"

    # Inference cost (successful turns only)
    local inf_cost
    inf_cost=$(awk "BEGIN { printf \"%.4f\", ($tin * $PRICE_IN_PER_TOKEN) + ($tout * $PRICE_OUT_PER_TOKEN) }")

    # Rework cost: loop-token inference at the same rates + per-loop tool cost
    local rew_cost
    rew_cost=$(awk "BEGIN { printf \"%.4f\", ($rtin * $PRICE_IN_PER_TOKEN) + ($rtout * $PRICE_OUT_PER_TOKEN) + ($rework * $REWORK_TOOL_COST_USD) }")

    # Human intervention cost
    local hum_cost
    hum_cost=$(awk "BEGIN { printf \"%.4f\", $human * $HUMAN_INTERVENTION_USD }")

    local total_cost
    total_cost=$(awk "BEGIN { printf \"%.4f\", $inf_cost + $rew_cost + $hum_cost }")

    if [[ "$accepted" == "true" || "$accepted" == "1" ]]; then
        echo "$total_cost"
    else
        echo "INF (REJECTED)"
    fi
}

run_self_test() {
    echo ""
    echo "🧪 PromptKit OS CPAC Measurement Self-Test"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test 1: Ideal Clean Run (PromptKit OS)
    # 15,000 in, 1,500 out, no rework (0 loops, 0/0 loop tokens), 0 human, accepted
    # inf: (15000 * 0.000003) + (1500 * 0.000015) = 0.0450 + 0.0225 = 0.0675
    local cpac_ideal
    cpac_ideal=$(calculate_cpac 15000 1500 0 0 0 0 "true")
    if [[ "$cpac_ideal" == "0.0675" ]]; then
        echo "✅ Test 1 Passed: Ideal run CPAC = \$$cpac_ideal"
    else
        echo "❌ Test 1 Failed: Expected 0.0675, got $cpac_ideal"
        return 1
    fi

    # Test 2: Run with Rework Loops (loop tokens priced in C_rework per §2B)
    # 45,000 in, 6,000 out successful; 12,000/2,100 loop tokens; 3 loops; 1 human; accepted
    # inf:  (45000 * 0.000003) + (6000 * 0.000015)          = 0.1350 + 0.0900 = 0.2250
    # rew:  (12000 * 0.000003) + (2100 * 0.000015) + 3*0.05 = 0.0360 + 0.0315 + 0.1500 = 0.2175
    # hum:  1 * 8.33 = 8.3300
    # total: 0.2250 + 0.2175 + 8.3300 = 8.7725
    local cpac_rework
    cpac_rework=$(calculate_cpac 45000 6000 12000 2100 3 1 "true")
    if [[ "$cpac_rework" == "8.7725" ]]; then
        echo "✅ Test 2 Passed: Rework run CPAC = \$$cpac_rework"
    else
        echo "❌ Test 2 Failed: Expected 8.7725, got $cpac_rework"
        return 1
    fi

    # Test 3: Rejected Run (Broken Invariants)
    local cpac_rejected
    cpac_rejected=$(calculate_cpac 20000 2000 0 0 2 1 "false")
    if [[ "$cpac_rejected" == "INF (REJECTED)" ]]; then
        echo "✅ Test 3 Passed: Rejected run CPAC = $cpac_rejected"
    else
        echo "❌ Test 3 Failed: Expected INF (REJECTED), got $cpac_rejected"
        return 1
    fi

    echo ""
    echo "✅ All CPAC measurement self-tests PASSED."
    return 0
}

# Textual JSON scanners — dependency-free (no jq/python/node), same text rules
# as the PowerShell twin so both reach identical verdicts from identical files.
# First line carrying the key wins; CRLF tolerated.
numeric_json_value() {
    # numeric_json_value <file> <key> : the first numeric "key": N value, or empty
    awk -v needle="\"$2\"" '{ sub(/\r$/, "") } index($0, needle) { rest = substr($0, index($0, needle) + length(needle)); if (rest ~ /^[ \t]*:[ \t]*-?[0-9]/) { sub(/^[ \t]*:[ \t]*/, "", rest); if (match(rest, /^-?[0-9]+(\.[0-9]+)?/)) { print substr(rest, RSTART, RLENGTH); exit } } }' "$1"
}

string_json_value() {
    # string_json_value <file> <key> : the first string "key": "..." value, or empty
    awk -v needle="\"$2\"" '{ sub(/\r$/, "") } index($0, needle) { rest = substr($0, index($0, needle) + length(needle)); if (rest ~ /^[ \t]*:[ \t]*"/) { sub(/^[ \t]*:[ \t]*"/, "", rest); end = index(rest, "\""); if (end > 0) { print substr(rest, 1, end - 1); exit } } }' "$1"
}

boolean_json_value() {
    # boolean_json_value <file> <key> : "true"/"false" literal, or empty when
    # absent or not a bare boolean
    awk -v needle="\"$2\"" '{ sub(/\r$/, "") } index($0, needle) { rest = substr($0, index($0, needle) + length(needle)); sub(/^[ \t]*:[ \t]*/, "", rest); if (rest ~ /^true/) { print "true"; exit } if (rest ~ /^false/) { print "false"; exit } }' "$1"
}

run_ingest() {
    local file="$TARGET_FILE"
    if [[ ! -s "$file" ]]; then
        cpac_error "UNREADABLE" "$file"
    fi

    local key
    local NUMERIC_KEYS=(tokens_in tokens_out rework_tokens_in rework_tokens_out rework_loops human_interventions wall_clock_seconds tool_calls_total cache_read_tokens)
    local STRING_KEYS=(scenario_id condition model timestamp)
    declare -A NUM=()
    declare -A STR=()

    for key in "${NUMERIC_KEYS[@]}"; do
        NUM[$key]="$(numeric_json_value "$file" "$key")"
        [[ -n "${NUM[$key]}" ]] || cpac_error "MISSING_KEY" "$key"
    done
    for key in "${STRING_KEYS[@]}"; do
        STR[$key]="$(string_json_value "$file" "$key")"
        [[ -n "${STR[$key]}" ]] || cpac_error "MISSING_KEY" "$key"
    done

    local accepted
    accepted="$(boolean_json_value "$file" "accepted")"
    if [[ -z "$accepted" ]]; then
        if grep -q '"accepted"' "$file"; then
            cpac_error "BAD_VALUE" "accepted"
        fi
        cpac_error "MISSING_KEY" "accepted"
    fi

    local inf_cost rew_cost hum_cost total
    inf_cost=$(awk "BEGIN { printf \"%.4f\", (${NUM[tokens_in]} * $PRICE_IN_PER_TOKEN) + (${NUM[tokens_out]} * $PRICE_OUT_PER_TOKEN) }")
    rew_cost=$(awk "BEGIN { printf \"%.4f\", (${NUM[rework_tokens_in]} * $PRICE_IN_PER_TOKEN) + (${NUM[rework_tokens_out]} * $PRICE_OUT_PER_TOKEN) + (${NUM[rework_loops]} * $REWORK_TOOL_COST_USD) }")
    hum_cost=$(awk "BEGIN { printf \"%.4f\", ${NUM[human_interventions]} * $HUMAN_INTERVENTION_USD }")
    total=$(awk "BEGIN { printf \"%.4f\", $inf_cost + $rew_cost + $hum_cost }")

    local cpac_value="$total"
    if [[ "$accepted" != "true" ]]; then
        cpac_value="INF"
    fi

    echo ""
    echo "📊 PromptKit OS CPAC Scorecard (Measured Telemetry)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Scenario: ${STR[scenario_id]} | Condition: ${STR[condition]} | Model: ${STR[model]}"
    echo "   Timestamp: ${STR[timestamp]} | Wall-Clock: ${NUM[wall_clock_seconds]}s"
    echo "-----------------------|------------------"
    printf "   %-24s %s\n" "Input Tokens (successful):" "${NUM[tokens_in]}"
    printf "   %-24s %s\n" "Output Tokens (successful):" "${NUM[tokens_out]}"
    printf "   %-24s %s\n" "Cache-Read Tokens (memo):" "${NUM[cache_read_tokens]}"
    printf "   %-24s %s\n" "Failed Rework Loops:" "${NUM[rework_loops]}"
    printf "   %-24s %s\n" "Loop Tokens In/Out:" "${NUM[rework_tokens_in]}/${NUM[rework_tokens_out]}"
    printf "   %-24s %s\n" "Tool Calls (total):" "${NUM[tool_calls_total]}"
    printf "   %-24s %s\n" "Human Interventions:" "${NUM[human_interventions]}"
    echo "-----------------------|------------------"
    printf "   %-24s \$%.4f\n" "Inference Cost:" "$inf_cost"
    printf "   %-24s \$%.4f (%s loops × τ_tool \$%s + loop-token inference)\n" "Rework Cost:" "$rew_cost" "${NUM[rework_loops]}" "$REWORK_TOOL_COST_USD"
    printf "   %-24s \$%.4f\n" "Human Cost:" "$hum_cost"
    if [[ "$accepted" == "true" ]]; then
        printf "   %-24s \$%s\n" "Total CPAC:" "$cpac_value"
    else
        printf "   %-24s %s\n" "Total CPAC:" "INF (REJECTED)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ "$accepted" != "true" ]]; then
        echo "   ⚠️  accepted=false in the telemetry record: the run was not accepted, so CPAC is infinite by definition."
    fi
    echo "Methodology: docs/BENCHMARK-METHODOLOGY.md | Extractor: scripts/extract-commandcode-telemetry.sh"

    printf 'CPAC|MEASURED|scenario=%s|condition=%s|model=%s|tokens_in=%s|tokens_out=%s|cache_read_tokens=%s|rework_loops=%s|rework_tokens_in=%s|rework_tokens_out=%s|wall_clock_seconds=%s|human_interventions=%s|inference_usd=%s|rework_usd=%s|human_usd=%s|cpac_usd=%s\n' \
        "${STR[scenario_id]}" "${STR[condition]}" "${STR[model]}" \
        "${NUM[tokens_in]}" "${NUM[tokens_out]}" "${NUM[cache_read_tokens]}" \
        "${NUM[rework_loops]}" "${NUM[rework_tokens_in]}" "${NUM[rework_tokens_out]}" \
        "${NUM[wall_clock_seconds]}" "${NUM[human_interventions]}" \
        "$inf_cost" "$rew_cost" "$hum_cost" "$cpac_value"
}

if [[ "$SELF_TEST" -eq 1 ]]; then
    run_self_test
    exit 0
fi

if [[ -n "$TARGET_FILE" ]]; then
    run_ingest
    exit 0
fi

if [[ "$DEMO" -eq 1 ]]; then
    echo ""
    echo "📊 PromptKit OS Benchmark Scorecard (Simulated Comparison)"
    echo "   ⚠️  SIMULATED demonstration values — no telemetry was read; pass a §5 telemetry record for a measured result."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-22s | %-16s | %-16s\n" "Dimension" "Condition A: Vanilla" "Condition B: PromptKit"
    echo "-----------------------|------------------|------------------"
    printf "%-22s | %-16s | %-16s\n" "Input Tokens" "48,200" "14,800"
    printf "%-22s | %-16s | %-16s\n" "Output Tokens" "5,400" "1,650"
    printf "%-22s | %-16s | %-16s\n" "Search / Edit Ratio" "8.4 (Exploratory)" "1.4 (Focused)"
    printf "%-22s | %-16s | %-16s\n" "Failed Rework Loops" "3 loops" "0 loops"
    printf "%-22s | %-16s | %-16s\n" "Invariant Violations" "1 (HMAC stringified)" "0 (All Invariants ✓)"
    printf "%-22s | %-16s | %-16s\n" "Human Intervention" "1 (12 mins)" "0 (Autonomous green)"
    printf "%-22s | %-16s | %-16s\n" "Wall-Clock Time" "9m 42s" "3m 15s"
    echo "-----------------------|------------------|------------------"
    printf "%-22s | %-16s | %-16s\n" "Inference Cost" "\$0.2256" "\$0.0692"
    printf "%-22s | %-16s | %-16s\n" "Rework Cost" "\$0.1500" "\$0.0000"
    printf "%-22s | %-16s | %-16s\n" "Human Cost" "\$20.0000" "\$0.0000"
    printf "%-22s | %-16s | \033[1;32m%-16s\033[0m\n" "Total CPAC" "\$20.3756" "\$0.0692 (-99.6%)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Methodology: docs/BENCHMARK-METHODOLOGY.md | Scenarios: docs/specs/SPEC-empirical-benchmark.md"
    exit 0
fi

usage
