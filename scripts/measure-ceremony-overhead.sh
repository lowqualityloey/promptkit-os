#!/usr/bin/env bash
# PromptKit OS Ceremony Artifact Overhead Measurement
#
# Measures the ceremony artifacts each task level requires (workflows/route.md
# is the canonical authority for Level 0-3 ceremony) and reports their static
# byte and token load. Uses the bytes/4 convention of measure-tokens.sh:
#   tokens = floor((bytes after CR stripping + 2) / 4)
#
# The bare "CEREMONY|" prefix is reserved by the benchmark task card
# benchmarks/tasks/TASK-BENCH-L1-02.md for scripts/measure-per-task-tokens.sh;
# this script uses CEREMONY_ARTIFACT| so the two never collide.
#
# What this DOES measure: the static size of the canonical artifacts the policy
# makes mandatory at each level, read from the checked-out tree.
#
# What this does NOT measure: live run cost. Tool calls, elapsed time, model,
# host, and number of human interventions per level require host telemetry that
# this repository does not capture. Those fields are reported as
# "not measured" on purpose -- never estimated, never fabricated.
#
# Modes:
#   default  : informational report.
#   --strict : CI gate mode. After the report, asserts every level required
#              artifact total stays within its recorded baseline below.
#              Machine-parseable: CEREMONY_BASELINE|level|measured|limit|PASS|FAIL
#
# Machine-parseable lines (always emitted):
#   CEREMONY_ARTIFACT|<level>|<path or ->|required|optional|<bytes>|<tokens>
#   CEREMONY_TOTAL|<level>|<required_files>|<optional_files>|<required_bytes>|<required_tokens>
#   CEREMONY_PROVENANCE|<key>=<value>|...
#   CEREMONY_UNMEASURED|<field>|not-measured|<reason>
set -euo pipefail

STRICT=0
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=1 ;;
        -h|--help) echo "Usage: measure-ceremony-overhead.sh [--strict]"; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Recorded baselines: required artifact tokens per level, first measured at
# commit 471ebc7 (docs/BENCHMARKS.md, "Ceremony Artifact Overhead by
# Level"). They pin the mandatory surface against silent growth; they are not
# targets and must be restated when a measured artifact legitimately changes.
declare -A BASELINE=(
    [L0]=0
    [L1]=3021
    [L2]=8660
    [L3]=16479
)

measure_bytes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "MEASURE_ERROR|MISSING|$file" >&2
        exit 2
    fi
    tr -d '\r' < "$file" | wc -c | tr -d ' '
}

measure_tokens() {
    local bytes="$1"
    echo $(( (bytes + 2) / 4 ))
}

# Level -> artifact list, grounded in workflows/route.md.
#   L0 (route.md:50): "Zero task records, no GitHub issue required, no state
#       tracking overhead." Nothing is mandatory.
#   L1 (route.md:54): lightweight inline planning, "Normal task tracking in
#       docs/STATE.md without requiring formal Task Record files". A quick-tier
#       checkpoint exists (workflows/checkpoint.md:78) but is not mandatory.
#   L2 (route.md:59,61): "task record -> plan -> implement -> checkpoints";
#       "Requires a Local Task Record at docs/tasks/<task-id>.md". Handoff and
#       scope-change records cover transfer and scope expansion
#       (workflows/checkpoint.md:72,81), so they are optional here.
#   L3 (route.md:66): Level 2 evidence plus "contract impact evidence
#       (pk:ship)" and release evaluation (workflows/ship.md:18,194). CI triage
#       is conditional on a reported failure (workflows/ship.md:136).
declare -A LEVEL_REQUIRED=(
    [L0]=""
    [L1]="templates/state-tracker-template.md"
    [L2]="templates/state-tracker-template.md templates/execution-task-record-template.md templates/execution-checkpoint-template.md"
    [L3]="templates/state-tracker-template.md templates/execution-task-record-template.md templates/execution-checkpoint-template.md templates/release-checklist.md templates/release-evaluation-template.md templates/contract-impact-evidence-template.md"
)

declare -A LEVEL_OPTIONAL=(
    [L0]=""
    [L1]="templates/execution-checkpoint-template.md"
    [L2]="templates/execution-handoff-template.md templates/execution-scope-change-template.md"
    [L3]="templates/execution-handoff-template.md templates/execution-scope-change-template.md templates/ci-triage-template.md"
)

declare -A LEVEL_LABEL=(
    [L0]="Direct"
    [L1]="Standard"
    [L2]="Controlled"
    [L3]="Release-Critical"
)

declare -A REQ_BYTES REQ_TOKENS REQ_COUNT OPT_COUNT
for level in L0 L1 L2 L3; do
    REQ_BYTES[$level]=0
    REQ_TOKENS[$level]=0
    REQ_COUNT[$level]=0
    OPT_COUNT[$level]=0
done

emit_artifacts() {
    local level="$1"
    local kind="$2"
    local files="$3"
    local path bytes tokens
    if [[ -z "$files" ]]; then
        echo "CEREMONY_ARTIFACT|$level|-|$kind|0|0"
        return 0
    fi
    for path in $files; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        tokens=$(measure_tokens "$bytes")
        echo "CEREMONY_ARTIFACT|$level|$path|$kind|$bytes|$tokens"
        if [[ "$kind" == "required" ]]; then
            REQ_BYTES[$level]=$(( REQ_BYTES[$level] + bytes ))
            REQ_TOKENS[$level]=$(( REQ_TOKENS[$level] + tokens ))
            REQ_COUNT[$level]=$(( REQ_COUNT[$level] + 1 ))
        else
            OPT_COUNT[$level]=$(( OPT_COUNT[$level] + 1 ))
        fi
    done
}

SHA="$(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
DATESTAMP="$(date +%Y-%m-%d)"

echo ""
echo "📊 PromptKit OS Ceremony Artifact Overhead by Task Level"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repo SHA: $SHA"
echo "Date: $DATESTAMP"
echo "Convention: tokens = floor((bytes after CR stripping + 2) / 4)"
echo ""

echo "Required ceremony artifacts per level:"
for level in L0 L1 L2 L3; do
    printf "  %-2s %-17s %2d file(s)  %6d bytes  %6d tok\n" "$level" "${LEVEL_LABEL[$level]}" "${REQ_COUNT[$level]}" "${REQ_BYTES[$level]}" "${REQ_TOKENS[$level]}"
done
echo ""

echo "Artifact detail:"
for level in L0 L1 L2 L3; do
    if [[ -z "${LEVEL_REQUIRED[$level]}" && -z "${LEVEL_OPTIONAL[$level]}" ]]; then
        echo "  $level: none (deliberate - zero ceremony artifacts)"
        continue
    fi
    for path in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s required  %-52s %6d B  %5d tok\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
    for path in ${LEVEL_OPTIONAL[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s optional  %-52s %6d B  %5d tok\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
done

for level in L0 L1 L2 L3; do
    emit_artifacts "$level" required "${LEVEL_REQUIRED[$level]}"
    emit_artifacts "$level" optional "${LEVEL_OPTIONAL[$level]}"
done

echo ""

PROFILE="$(sed -n 's/^- \*\*Profile\*\*: *`\([a-z]*\)`.*/\1/p' "$KIT_DIR/PROMPTKIT.md" 2>/dev/null | head -1 || true)"
echo "CEREMONY_PROVENANCE|sha=$SHA|date=$DATESTAMP|convention=floor((bytes+2)/4)|profile=${PROFILE:-unknown}"
echo "CEREMONY_UNMEASURED|live-telemetry|not-measured|tool calls, elapsed time, model/host identity and interventions per level need host telemetry this repository does not capture"
echo "CEREMONY_UNMEASURED|sample-count|not-measured|static artifact measurement is deterministic; no repeated live runs were executed for this number"

for level in L0 L1 L2 L3; do
    echo "CEREMONY_TOTAL|$level|required_files=${REQ_COUNT[$level]}|optional_files=${OPT_COUNT[$level]}|required_bytes=${REQ_BYTES[$level]}|required_tokens=${REQ_TOKENS[$level]}"
done

if [[ "$STRICT" -eq 1 ]]; then
    echo ""
    echo "Strict mode: required artifact totals vs recorded baselines"
    FAILED=0
    for level in L0 L1 L2 L3; do
        measured="${REQ_TOKENS[$level]}"
        limit="${BASELINE[$level]}"
        if [[ "$limit" == "0" ]]; then
            echo "CEREMONY_BASELINE|$level|$measured|unrecorded|SKIP"
            continue
        fi
        if [[ "$measured" -le "$limit" ]]; then
            echo "CEREMONY_BASELINE|$level|$measured|$limit|PASS"
        else
            echo "CEREMONY_BASELINE|$level|$measured|$limit|FAIL"
            FAILED=1
        fi
    done
    if [[ "$FAILED" -ne 0 ]]; then
        echo "CEREMONY_GATE|FAIL|required ceremony artifacts grew past the recorded baseline" >&2
        exit 1
    fi
    echo "CEREMONY_GATE|PASS"
fi
