#!/usr/bin/env bash
# PromptKit OS Ceremony Artifact Overhead Measurement
#
# Measures the ceremony artifacts each task level requires (workflows/route.md
# is the canonical authority for Level 0-3 ceremony) and reports their static
# byte and token load. Uses the bytes/4 convention of measure-tokens.sh:
#   tokens = floor((bytes after CR stripping + 2) / 4)
#
# TWO UNITS, deliberately kept apart:
#
#   1. Per-task artifacts -- a template the level obliges an agent to fill for
#      each task (Task Record, checkpoint, specification, release evidence).
#      Repeated cost: paid once per task.
#   2. Shared setup -- a template filled once per project and updated in place
#      afterwards (docs/STATE.md, from templates/state-tracker-template.md).
#      Paid once, then amortised; charging it at every level would count the
#      same bytes once per task forever, so it is reported once, outside the
#      per-level totals.
#
# The Level 2 specification is a FAMILY, not a single file: workflows/route.md:61
# names the commands (pk:plan, pk:data, pk:auth, pk:api), and each maps to a
# different template in the checked-out tree. One member is pinned as the
# deterministic baseline (the generic pk:plan tech spec, the largest); the rest
# are reported as variants so the published band is honest without making the
# gate depend on which sub-trigger a given task happened to use.
#
# Membership is a CURATED SELECTION, not a parse. Policy names commands and
# duties ("contract impact evidence (pk:ship)"), never template filenames, so no
# parser can derive this list from the text. What the script can do is fail
# loudly when the policy sentences it rests on change: see POLICY_ANCHORS below.
#
# What this DOES measure: the static size of the selected template set per task
# level, read from the checked-out tree.
#
# What this does NOT measure: live run cost, and the cost of filling a record
# (generation is not reproduction of the template text). Tool calls, elapsed
# time, model, host, and human interventions per level require host telemetry
# that this repository does not capture; those fields are reported as
# "not measured" on purpose -- never estimated, never fabricated.
#
# Modes:
#   default  : informational report.
#   --strict : CI gate mode. Asserts every measured total EQUALS its recorded
#              baseline below -- growth and reduction both fail, because the
#              docs promise the figures are restated in the same commit that
#              changes a template. A legitimate template change therefore fails
#              this gate until the baseline here and the published table are
#              updated together.
#              Machine-parseable: CEREMONY_BASELINE|<unit>|<measured>|<limit>|PASS|FAIL
#
# Machine-parseable lines (always emitted):
#   CEREMONY_ANCHOR|<policy file>|OK
#   CEREMONY_ARTIFACT|<level or SETUP>|<path>|<required|optional|variant|setup>|<bytes>|<tokens>
#   CEREMONY_TOTAL|<level>|required_files=..|optional_files=..|variant_files=..|required_bytes=..|required_tokens=..
#   CEREMONY_SHARED_SETUP|files=..|bytes=..|tokens=..|amortisation=once-per-project
#   CEREMONY_SPEC_BAND|L2|<min_tokens>|<max_tokens>|pinned=<path>
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

# Recorded baselines: per-task required artifact tokens per level, plus the
# shared one-time setup total, first recorded at 471ebc7 + the ceremony rework
# (docs/BENCHMARKS.md, "Ceremony Artifact Overhead by Task Level"). --strict
# compares by EQUALITY: they are not ceilings and not targets, they are the
# published numbers, and they must be restated when a measured template
# legitimately changes.
declare -A BASELINE=(
    [L0]=0
    [L1]=0
    [L2]=11119
    [L3]=18938
)
BASELINE_SETUP=3021

# Policy sentences the artifact model rests on. If policy is rewritten, the
# selection below may silently stop matching it; these anchors turn that into a
# loud failure instead of a green gate measuring the wrong thing.
# Format: <file>|<literal fragment>
POLICY_ANCHORS=(
    "workflows/route.md|Zero task records, no GitHub issue required, no state tracking overhead"
    "workflows/route.md|without requiring formal Task Record files"
    "workflows/route.md|formal specification"
    "workflows/route.md|contract impact evidence"
    "workflows/checkpoint.md|session notes"
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

# Shared, one-time artifacts: paid once per project, updated in place after.
SHARED_SETUP="templates/state-tracker-template.md"

# Level -> per-task required artifact list, grounded in workflows/route.md.
#   L0 (route.md:50): "Zero task records, no GitHub issue required, no state
#       tracking overhead." Nothing is mandatory.
#   L1 (route.md:54): lightweight inline planning, "Normal task tracking in
#       docs/STATE.md without requiring formal Task Record files". No per-task
#       template: the tracker is shared setup, and checkpoint.md:66 allows
#       session notes instead of a file. The quick-tier checkpoint
#       (workflows/checkpoint.md:78) is optional.
#   L2 (route.md:59,61): "task record -> plan -> implement -> checkpoints";
#       "Requires a Local Task Record at docs/tasks/<task-id>.md" plus "formal
#       specification (pk:plan, pk:data, pk:auth, pk:api)". The pk:plan
#       (generic tech spec) member is pinned here; the other family members are
#       reported as variants below. Handoff and scope-change records cover
#       transfer and scope expansion (workflows/checkpoint.md:72,81), so they
#       are optional.
#   L3 (route.md:66): Level 2 evidence plus "contract impact evidence
#       (pk:ship)" and release evaluation (workflows/ship.md:18,194). CI triage
#       is conditional on a reported failure (workflows/ship.md:136); the QA
#       review checklist is review evidence, not a per-task record.
declare -A LEVEL_REQUIRED=(
    [L0]=""
    [L1]=""
    [L2]="templates/execution-task-record-template.md templates/execution-checkpoint-template.md templates/tech-spec-template.md"
    [L3]="templates/execution-task-record-template.md templates/execution-checkpoint-template.md templates/tech-spec-template.md templates/release-checklist.md templates/release-evaluation-template.md templates/contract-impact-evidence-template.md"
)

declare -A LEVEL_VARIANT=(
    [L0]=""
    [L1]=""
    [L2]="templates/data-model-spec.md templates/auth-matrix-template.md templates/api-contract-spec.md"
    [L3]="templates/data-model-spec.md templates/auth-matrix-template.md templates/api-contract-spec.md"
)

declare -A LEVEL_OPTIONAL=(
    [L0]=""
    [L1]="templates/execution-checkpoint-template.md"
    [L2]="templates/execution-handoff-template.md templates/execution-scope-change-template.md"
    [L3]="templates/execution-handoff-template.md templates/execution-scope-change-template.md templates/ci-triage-template.md templates/code-review-checklist.md"
)

declare -A LEVEL_LABEL=(
    [L0]="Direct"
    [L1]="Standard"
    [L2]="Controlled"
    [L3]="Release-Critical"
)

declare -A REQ_BYTES REQ_TOKENS REQ_COUNT OPT_COUNT VAR_COUNT
for level in L0 L1 L2 L3; do
    REQ_BYTES[$level]=0
    REQ_TOKENS[$level]=0
    REQ_COUNT[$level]=0
    OPT_COUNT[$level]=0
    VAR_COUNT[$level]=0
done

# Two passes over the same lists: tally_artifacts fills the counters the human
# summary prints, emit_artifacts prints the machine lines. They are separate so
# the summary is never printed from counters that have not been filled yet.
tally_artifacts() {
    local level="$1"
    local kind="$2"
    local files="$3"
    local path bytes tokens
    for path in $files; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        tokens=$(measure_tokens "$bytes")
        case "$kind" in
            required)
                REQ_BYTES[$level]=$(( REQ_BYTES[$level] + bytes ))
                REQ_TOKENS[$level]=$(( REQ_TOKENS[$level] + tokens ))
                REQ_COUNT[$level]=$(( REQ_COUNT[$level] + 1 ))
                ;;
            variant)
                VAR_COUNT[$level]=$(( VAR_COUNT[$level] + 1 ))
                ;;
            *)
                OPT_COUNT[$level]=$(( OPT_COUNT[$level] + 1 ))
                ;;
        esac
    done
}

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
echo "Policy anchors (the sentences this selection rests on):"
for anchor in "${POLICY_ANCHORS[@]}"; do
    file="${anchor%%|*}"
    phrase="${anchor#*|}"
    if [[ ! -f "$KIT_DIR/$file" ]] || ! grep -Fq -- "$phrase" "$KIT_DIR/$file"; then
        echo "CEREMONY_ANCHOR|$file|MISSING" >&2
        echo "ANCHOR_ERROR|POLICY_DRIFT|$file no longer contains: $phrase" >&2
        echo "ANCHOR_ERROR|ACTION|re-derive the artifact selection in this script and docs/BENCHMARKS.md before trusting any figure" >&2
        exit 2
    fi
    echo "CEREMONY_ANCHOR|$file|OK"
done

SETUP_BYTES=0
SETUP_TOKENS=0
SETUP_COUNT=0
for path in $SHARED_SETUP; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    tokens=$(measure_tokens "$bytes")
    SETUP_BYTES=$(( SETUP_BYTES + bytes ))
    SETUP_TOKENS=$(( SETUP_TOKENS + tokens ))
    SETUP_COUNT=$(( SETUP_COUNT + 1 ))
done

for level in L0 L1 L2 L3; do
    tally_artifacts "$level" required "${LEVEL_REQUIRED[$level]}"
    tally_artifacts "$level" variant "${LEVEL_VARIANT[$level]}"
    tally_artifacts "$level" optional "${LEVEL_OPTIONAL[$level]}"
done

echo ""
echo "Shared one-time setup (paid once per project, then updated in place):"
printf "  %-49s %6d B  %5d tok\\n" "$SHARED_SETUP" "$SETUP_BYTES" "$SETUP_TOKENS"
echo ""

echo "Per-task required ceremony artifacts per level:"
for level in L0 L1 L2 L3; do
    printf "  %-2s %-17s %2d file(s)  %6d bytes  %6d tok\\n" "$level" "${LEVEL_LABEL[$level]}" "${REQ_COUNT[$level]}" "${REQ_BYTES[$level]}" "${REQ_TOKENS[$level]}"
done
echo ""

echo "Artifact detail:"
for level in L0 L1 L2 L3; do
    if [[ -z "${LEVEL_REQUIRED[$level]}" && -z "${LEVEL_OPTIONAL[$level]}" && -z "${LEVEL_VARIANT[$level]}" ]]; then
        echo "  $level: none per task (deliberate - zero per-task ceremony artifacts)"
        continue
    fi
    for path in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s required  %-52s %6d B  %5d tok\\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
    for path in ${LEVEL_VARIANT[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s variant   %-52s %6d B  %5d tok\\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
    for path in ${LEVEL_OPTIONAL[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s optional  %-52s %6d B  %5d tok\\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
done

echo "CEREMONY_ARTIFACT|SETUP|$SHARED_SETUP|setup|$SETUP_BYTES|$SETUP_TOKENS"
for level in L0 L1 L2 L3; do
    emit_artifacts "$level" required "${LEVEL_REQUIRED[$level]}"
    emit_artifacts "$level" variant "${LEVEL_VARIANT[$level]}"
    emit_artifacts "$level" optional "${LEVEL_OPTIONAL[$level]}"
done

echo ""

PROFILE="$(sed -n 's/^- \*\*Profile\*\*: *`\([a-z]*\)`.*/\1/p' "$KIT_DIR/PROMPTKIT.md" 2>/dev/null | head -1 || true)"
echo "CEREMONY_PROVENANCE|sha=$SHA|date=$DATESTAMP|convention=floor((bytes+2)/4)|profile=${PROFILE:-unknown}|units=per-task+shared-setup|selection=curated-not-parsed"
echo "CEREMONY_UNMEASURED|live-telemetry|not-measured|tool calls, elapsed time, model/host identity and interventions per level need host telemetry this repository does not capture"
echo "CEREMONY_UNMEASURED|sample-count|not-measured|static artifact measurement is deterministic; no repeated live runs were executed for this number"
echo "CEREMONY_UNMEASURED|fill-cost|not-measured|filling a template costs generation; the figures here are the size of the template text, not the cost of producing a record"

echo "CEREMONY_SHARED_SETUP|files=$SETUP_COUNT|bytes=$SETUP_BYTES|tokens=$SETUP_TOKENS|amortisation=once-per-project"
for level in L0 L1 L2 L3; do
    echo "CEREMONY_TOTAL|$level|required_files=${REQ_COUNT[$level]}|optional_files=${OPT_COUNT[$level]}|variant_files=${VAR_COUNT[$level]}|required_bytes=${REQ_BYTES[$level]}|required_tokens=${REQ_TOKENS[$level]}"
done

# Specification band: the pinned member is in the per-task total; the band shows
# what the same level costs when the task's sub-trigger selects another member.
SPEC_MIN=0
SPEC_MAX=0
for path in templates/tech-spec-template.md ${LEVEL_VARIANT[L2]}; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    tokens=$(measure_tokens "$bytes")
    if [[ "$SPEC_MIN" -eq 0 || "$tokens" -lt "$SPEC_MIN" ]]; then SPEC_MIN=$tokens; fi
    if [[ "$tokens" -gt "$SPEC_MAX" ]]; then SPEC_MAX=$tokens; fi
done
L2_FIXED=$(( REQ_TOKENS[L2] - $(measure_tokens "$(measure_bytes "$KIT_DIR/templates/tech-spec-template.md")") ))
echo "CEREMONY_SPEC_BAND|L2|$(( L2_FIXED + SPEC_MIN ))|$(( L2_FIXED + SPEC_MAX ))|pinned=templates/tech-spec-template.md"

if [[ "$STRICT" -eq 1 ]]; then
    echo ""
    echo "Strict mode: measured totals vs recorded baselines (equality required)"
    FAILED=0
    for level in L0 L1 L2 L3; do
        measured="${REQ_TOKENS[$level]}"
        limit="${BASELINE[$level]}"
        if [[ "$measured" -eq "$limit" ]]; then
            echo "CEREMONY_BASELINE|$level|$measured|$limit|PASS"
        else
            echo "CEREMONY_BASELINE|$level|$measured|$limit|FAIL"
            FAILED=1
        fi
    done
    if [[ "$SETUP_TOKENS" -eq "$BASELINE_SETUP" ]]; then
        echo "CEREMONY_BASELINE|SETUP|$SETUP_TOKENS|$BASELINE_SETUP|PASS"
    else
        echo "CEREMONY_BASELINE|SETUP|$SETUP_TOKENS|$BASELINE_SETUP|FAIL"
        FAILED=1
    fi
    if [[ "$FAILED" -ne 0 ]]; then
        echo "CEREMONY_GATE|FAIL|a measured total differs from its recorded baseline; restate the baseline here and in docs/BENCHMARKS.md when a template change is legitimate" >&2
        exit 1
    fi
    echo "CEREMONY_GATE|PASS"
fi
