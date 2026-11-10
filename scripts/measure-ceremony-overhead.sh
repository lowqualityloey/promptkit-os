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
# PLANNING DEPTH IS PART OF THE MODEL. workflows/plan.md:67-69 makes "Minimal
# Planning (Level 2 default)" stop "without continuing into the full RFC", so a
# Level 2 task does NOT necessarily produce a specification file. The per-level
# baseline is therefore the Minimal Planning set (Task Record + checkpoint), and
# the specification family is published as a band that Full Planning adds. The
# earlier single figure charged every Level 2 task for a tech spec it may never
# write.
#
# The Level 2 specification is a FAMILY, not a single file: workflows/route.md:61
# names the commands (pk:plan, pk:data, pk:auth, pk:api), and each maps to a
# different template in the checked-out tree. A task uses ONE member. The band
# is the smallest to the largest member added to the level's fixed set.
#
# ONE REQUIRED ARTIFACT HAS NO SHIPPED TEMPLATE. workflows/review.md:19 gives
# pk:review "one durable two-axis report at docs/reviews/<review-slug>.md", and
# no template for it ships in this repository. It is listed as required and
# reported as not measurable from repository bytes -- never silently dropped,
# never estimated.
#
# Membership is a CURATED SELECTION, not a parse. Policy names commands and
# duties ("contract impact evidence (pk:ship)"), never template filenames, so no
# parser can derive this list from the text. What the script can do is fail
# loudly when the policy it rests on changes: POLICY_ANCHORS pins the WHOLE
# ceremony line by SHA-256, so an added requirement inside a cited paragraph
# fails the run. It cannot see a requirement added elsewhere in a workflow file;
# docs/BENCHMARKS.md states that limit rather than overclaiming.
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
#   --strict : CI gate mode. Asserts every measured figure EQUALS its recorded
#              baseline below -- growth and reduction both fail, because the
#              docs promise the figures are restated in the same commit that
#              changes a template. Coverage is every published number: the four
#              per-level totals, the shared setup, all four specification
#              variants, all five optional artifacts, and both band endpoints
#              for Level 2 and Level 3. A unit with no recorded baseline fails
#              rather than passing unrecorded.
#              Machine-parseable: CEREMONY_BASELINE|<unit>|<measured>|<limit>|PASS|FAIL
#
# Machine-parseable lines (always emitted):
#   CEREMONY_ANCHOR|<policy file>|OK
#   CEREMONY_ARTIFACT|<level or SETUP>|<path>|<required|untemplated|optional|variant|setup>|<bytes>|<tokens>
#   CEREMONY_TOTAL|<level>|required_files=..|untemplated_files=..|optional_files=..|required_bytes=..|required_tokens=..
#   CEREMONY_SHARED_SETUP|files=..|bytes=..|tokens=..|amortisation=once-per-project
#   CEREMONY_SPEC_BAND|<level>|<min_tokens>|<max_tokens>|pinned=<path>
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

# Recorded baselines, keyed by unit. --strict compares by EQUALITY: these are
# not ceilings and not targets, they are the published numbers, and they must be
# restated when a measured template legitimately changes.
#   L0..L3  per-task required template tokens (Minimal Planning set)
#   SETUP   shared one-time setup tokens
#   SPEC:*  each specification family member
#   OPT:*   each optional artifact
#   BAND:*  specification band endpoints per level
declare -A BASELINE=(
    [L0]=0
    [L1]=0
    [L2]=5639
    [L3]=13458
    [SETUP]=3021
    [SPEC:templates/tech-spec-template.md]=5480
    [SPEC:templates/data-model-spec.md]=1825
    [SPEC:templates/auth-matrix-template.md]=979
    [SPEC:templates/api-contract-spec.md]=1347
    [OPT:templates/execution-checkpoint-template.md]=827
    [OPT:templates/execution-handoff-template.md]=978
    [OPT:templates/execution-scope-change-template.md]=782
    [OPT:templates/ci-triage-template.md]=1603
    [OPT:templates/code-review-checklist.md]=1534
    [BAND:L2:min]=6618
    [BAND:L2:max]=11119
    [BAND:L3:min]=14437
    [BAND:L3:max]=18938
)

# Policy the artifact model rests on. Each entry is
#   <file>|<literal fragment>|<sha256 prefix of the whole matching line>
# The fragment locates the line; the hash pins it. A rewritten sentence, or a
# requirement appended to the same line, changes the hash and fails the run.
POLICY_ANCHORS=(
    "workflows/route.md|Direct execution. Zero task records|bfb62859635b83d7"
    "workflows/route.md|Natural workflow routing|164e9e3470607701"
    "workflows/route.md|Requires a Local Task Record|cef964ae7430feb8"
    "workflows/route.md|Uses full release candidate evaluation|8edb52f8602095c1"
    "workflows/checkpoint.md|Level 1 (Standard) work updates|88aabdd5e32c660a"
    "workflows/plan.md|Minimal Planning (Level 2 default)|201483077233b647"
    "workflows/plan.md|Full Planning (Level 2 triggering work)|2eac98e5feb5025e"
    "workflows/review.md|owns one durable two-axis report|2deb075a198f7e9c"
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

# Level -> per-task required artifacts that DO ship a template, grounded in
# workflows/route.md and workflows/plan.md.
#   L0 (route.md:49): "Zero task records, no GitHub issue required, no state
#       tracking overhead." Nothing is mandatory.
#   L1 (route.md:55): "Normal task tracking in docs/STATE.md without requiring
#       formal Task Record files"; checkpoint.md:66 allows session notes
#       instead of a file. No per-task template: the tracker is shared setup.
#   L2 (route.md:61): "Requires a Local Task Record at docs/tasks/<task-id>.md"
#       plus formal specification. plan.md:67-69 makes Minimal Planning the
#       default and stops before the RFC, so the specification is NOT in the
#       default set -- it is the band below. The checkpoint is required by
#       checkpoint.md:66 ("checkpointing is a durable execution gate").
#   L3 (route.md:67): Level 2 evidence plus "contract impact evidence
#       (pk:ship)" and release evaluation (workflows/ship.md:18,194). CI triage
#       is conditional on a reported failure (workflows/ship.md:136); the QA
#       review checklist is review evidence, not a per-task record.
declare -A LEVEL_REQUIRED=(
    [L0]=""
    [L1]=""
    [L2]="templates/execution-task-record-template.md templates/execution-checkpoint-template.md"
    [L3]="templates/execution-task-record-template.md templates/execution-checkpoint-template.md templates/release-checklist.md templates/release-evaluation-template.md templates/contract-impact-evidence-template.md"
)

# Required artifacts with NO shipped template. Listed so the requirement is
# visible; reported as not measurable from repository bytes.
declare -A LEVEL_UNTEMPLATED=(
    [L0]=""
    [L1]=""
    [L2]="docs/reviews/<review-slug>.md"
    [L3]="docs/reviews/<review-slug>.md"
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

# The Level 2 specification family: one member per task, selected by the
# sub-trigger. The pinned member is the generic pk:plan tech spec.
SPEC_PINNED="templates/tech-spec-template.md"
SPEC_FAMILY=(
    "templates/tech-spec-template.md"
    "templates/data-model-spec.md"
    "templates/auth-matrix-template.md"
    "templates/api-contract-spec.md"
)

# Optional artifacts, union across levels, each measured once.
OPTIONAL_UNION=(
    "templates/execution-checkpoint-template.md"
    "templates/execution-handoff-template.md"
    "templates/execution-scope-change-template.md"
    "templates/ci-triage-template.md"
    "templates/code-review-checklist.md"
)

declare -A REQ_BYTES REQ_TOKENS REQ_COUNT UNT_COUNT OPT_COUNT
for level in L0 L1 L2 L3; do
    REQ_BYTES[$level]=0
    REQ_TOKENS[$level]=0
    REQ_COUNT[$level]=0
    UNT_COUNT[$level]=0
    OPT_COUNT[$level]=0
done

SHA="$(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
DATESTAMP="$(date +%Y-%m-%d)"

echo ""
echo "PromptKit OS Ceremony Artifact Overhead by Task Level"
echo "===================================================="
echo "Repo SHA: $SHA"
echo "Date: $DATESTAMP"
echo "Convention: tokens = floor((bytes after CR stripping + 2) / 4)"

echo ""
echo "Policy anchors (whole cited line pinned by SHA-256):"
for anchor in "${POLICY_ANCHORS[@]}"; do
    file="${anchor%%|*}"
    rest="${anchor#*|}"
    phrase="${rest%%|*}"
    want="${rest#*|}"
    if [[ ! -f "$KIT_DIR/$file" ]]; then
        echo "CEREMONY_ANCHOR|$file|MISSING" >&2
        echo "ANCHOR_ERROR|POLICY_DRIFT|$file does not exist" >&2
        echo "ANCHOR_ERROR|ACTION|re-derive the artifact selection in this script and docs/BENCHMARKS.md before trusting any figure" >&2
        exit 2
    fi
    line="$(grep -m1 -F -- "$phrase" "$KIT_DIR/$file" || true)"
    if [[ -z "$line" ]]; then
        echo "CEREMONY_ANCHOR|$file|MISSING" >&2
        echo "ANCHOR_ERROR|POLICY_DRIFT|$file no longer contains: $phrase" >&2
        echo "ANCHOR_ERROR|ACTION|re-derive the artifact selection in this script and docs/BENCHMARKS.md before trusting any figure" >&2
        exit 2
    fi
    got="$(printf '%s' "$line" | tr -d '\r' | sha256sum | cut -c1-16)"
    if [[ "$got" != "$want" ]]; then
        echo "CEREMONY_ANCHOR|$file|CHANGED" >&2
        echo "ANCHOR_ERROR|POLICY_DRIFT|$file line containing '$phrase' changed (expected $want, found $got)" >&2
        echo "ANCHOR_ERROR|ACTION|re-read the cited line, re-derive the artifact selection, then restate the hash here and the figures in docs/BENCHMARKS.md" >&2
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
    for path in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        tokens=$(measure_tokens "$bytes")
        REQ_BYTES[$level]=$(( REQ_BYTES[$level] + bytes ))
        REQ_TOKENS[$level]=$(( REQ_TOKENS[$level] + tokens ))
        REQ_COUNT[$level]=$(( REQ_COUNT[$level] + 1 ))
    done
    for path in ${LEVEL_UNTEMPLATED[$level]}; do
        UNT_COUNT[$level]=$(( UNT_COUNT[$level] + 1 ))
    done
    for path in ${LEVEL_OPTIONAL[$level]}; do
        OPT_COUNT[$level]=$(( OPT_COUNT[$level] + 1 ))
    done
done

declare -A SPEC_TOKENS OPT_TOKENS
SPEC_MIN=0
SPEC_MAX=0
for path in "${SPEC_FAMILY[@]}"; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    tokens=$(measure_tokens "$bytes")
    SPEC_TOKENS[$path]=$tokens
    if [[ "$SPEC_MIN" -eq 0 || "$tokens" -lt "$SPEC_MIN" ]]; then SPEC_MIN=$tokens; fi
    if [[ "$tokens" -gt "$SPEC_MAX" ]]; then SPEC_MAX=$tokens; fi
done
for path in "${OPTIONAL_UNION[@]}"; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    OPT_TOKENS[$path]=$(measure_tokens "$bytes")
done

declare -A BAND_MIN BAND_MAX
for level in L2 L3; do
    BAND_MIN[$level]=$(( REQ_TOKENS[$level] + SPEC_MIN ))
    BAND_MAX[$level]=$(( REQ_TOKENS[$level] + SPEC_MAX ))
done

echo ""
echo "Shared one-time setup (paid once per project, then updated in place):"
printf "  %-52s %6d B  %5d tok\n" "$SHARED_SETUP" "$SETUP_BYTES" "$SETUP_TOKENS"
echo ""

echo "Per-task required ceremony artifacts per level (Minimal Planning set):"
for level in L0 L1 L2 L3; do
    printf "  %-2s %-17s %2d file(s)  %6d bytes  %6d tok\n" "$level" "${LEVEL_LABEL[$level]}" "${REQ_COUNT[$level]}" "${REQ_BYTES[$level]}" "${REQ_TOKENS[$level]}"
done
echo ""

echo "Artifact detail:"
for level in L0 L1 L2 L3; do
    if [[ -z "${LEVEL_REQUIRED[$level]}" && -z "${LEVEL_OPTIONAL[$level]}" && -z "${LEVEL_UNTEMPLATED[$level]}" ]]; then
        echo "  $level: none per task (deliberate - zero per-task ceremony artifacts)"
        continue
    fi
    for path in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s required     %-52s %6d B  %5d tok\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
    for path in ${LEVEL_UNTEMPLATED[$level]}; do
        printf "  %-2s required     %-52s %6s B  %5s tok  (no shipped template)\n" "$level" "$path" "-" "-"
    done
    for path in ${LEVEL_OPTIONAL[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        printf "  %-2s optional     %-52s %6d B  %5d tok\n" "$level" "$path" "$bytes" "$(measure_tokens "$bytes")"
    done
done
echo ""

echo "Level 2 planning depth (workflows/plan.md:67-69):"
printf "  %-34s %6d tok  (Task Record + checkpoint; no specification file)\n" "Minimal Planning (default)" "${REQ_TOKENS[L2]}"
printf "  %-34s %6d-%d tok  (adds exactly one specification family member)\n" "Full Planning (triggering)" "${BAND_MIN[L2]}" "${BAND_MAX[L2]}"
echo ""
echo "Level 3 planning depth (Level 2 planning plus release evidence):"
printf "  %-34s %6d tok  (Task Record + checkpoint + release evidence)\n" "Minimal Planning (default)" "${REQ_TOKENS[L3]}"
printf "  %-34s %6d-%d tok  (adds exactly one specification family member)\n" "Full Planning (triggering)" "${BAND_MIN[L3]}" "${BAND_MAX[L3]}"
echo ""

echo "Specification family (one member per task, selected by sub-trigger):"
for path in "${SPEC_FAMILY[@]}"; do
    printf "  %-52s %5d tok  L2 total %6d tok\n" "$path" "${SPEC_TOKENS[$path]}" "$(( REQ_TOKENS[L2] + SPEC_TOKENS[$path] ))"
done
echo ""

echo "Optional artifacts (required only in the condition named):"
for path in "${OPTIONAL_UNION[@]}"; do
    printf "  %-52s %5d tok\n" "$path" "${OPT_TOKENS[$path]}"
done
echo ""

echo "CEREMONY_ARTIFACT|SETUP|$SHARED_SETUP|setup|$SETUP_BYTES|$SETUP_TOKENS"
for level in L0 L1 L2 L3; do
    if [[ -z "${LEVEL_REQUIRED[$level]}" && -z "${LEVEL_UNTEMPLATED[$level]}" && -z "${LEVEL_OPTIONAL[$level]}" ]]; then
        echo "CEREMONY_ARTIFACT|$level|-|required|0|0"
        continue
    fi
    for path in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        echo "CEREMONY_ARTIFACT|$level|$path|required|$bytes|$(measure_tokens "$bytes")"
    done
    for path in ${LEVEL_UNTEMPLATED[$level]}; do
        echo "CEREMONY_ARTIFACT|$level|$path|untemplated|0|0"
    done
    for path in ${LEVEL_OPTIONAL[$level]}; do
        bytes=$(measure_bytes "$KIT_DIR/$path")
        echo "CEREMONY_ARTIFACT|$level|$path|optional|$bytes|$(measure_tokens "$bytes")"
    done
done
for path in "${SPEC_FAMILY[@]}"; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    echo "CEREMONY_ARTIFACT|SPEC|$path|variant|$bytes|${SPEC_TOKENS[$path]}"
done

echo ""

PROFILE="$(grep -m1 '^- \*\*Profile\*\*:' "$KIT_DIR/PROMPTKIT.md" 2>/dev/null | sed 's/^- \*\*Profile\*\*: *//; s/`//g; s/[^a-z].*//' || true)"
echo "CEREMONY_PROVENANCE|sha=$SHA|date=$DATESTAMP|convention=floor((bytes+2)/4)|profile=${PROFILE:-unknown}|units=per-task+shared-setup|selection=curated-not-parsed|anchors=whole-line-sha256"
echo "CEREMONY_UNMEASURED|live-telemetry|not-measured|tool calls, elapsed time, model/host identity and interventions per level need host telemetry this repository does not capture"
echo "CEREMONY_UNMEASURED|sample-count|not-measured|static artifact measurement is deterministic; no repeated live runs were executed for this number"
echo "CEREMONY_UNMEASURED|fill-cost|not-measured|filling a template costs generation; the figures here are the size of the template text, not the cost of producing a record"
echo "CEREMONY_UNMEASURED|review-report|not-measured|workflows/review.md:19 requires one durable report at docs/reviews/<review-slug>.md and no template for it ships in this repository, so its size is not derivable from repository bytes"

echo "CEREMONY_SHARED_SETUP|files=$SETUP_COUNT|bytes=$SETUP_BYTES|tokens=$SETUP_TOKENS|amortisation=once-per-project"
for level in L0 L1 L2 L3; do
    echo "CEREMONY_TOTAL|$level|required_files=${REQ_COUNT[$level]}|untemplated_files=${UNT_COUNT[$level]}|optional_files=${OPT_COUNT[$level]}|required_bytes=${REQ_BYTES[$level]}|required_tokens=${REQ_TOKENS[$level]}"
done
for level in L2 L3; do
    echo "CEREMONY_SPEC_BAND|$level|${BAND_MIN[$level]}|${BAND_MAX[$level]}|pinned=$SPEC_PINNED"
done

if [[ "$STRICT" -eq 1 ]]; then
    echo ""
    echo "Strict mode: measured figures vs recorded baselines (equality required)"
    FAILED=0
    STRICT_UNITS=(L0 L1 L2 L3 SETUP)
    for path in "${SPEC_FAMILY[@]}"; do STRICT_UNITS+=("SPEC:$path"); done
    for path in "${OPTIONAL_UNION[@]}"; do STRICT_UNITS+=("OPT:$path"); done
    STRICT_UNITS+=("BAND:L2:min" "BAND:L2:max" "BAND:L3:min" "BAND:L3:max")
    for unit in "${STRICT_UNITS[@]}"; do
        case "$unit" in
            L0|L1|L2|L3) measured="${REQ_TOKENS[$unit]}" ;;
            SETUP) measured="$SETUP_TOKENS" ;;
            SPEC:*) measured="${SPEC_TOKENS[${unit#SPEC:}]}" ;;
            OPT:*) measured="${OPT_TOKENS[${unit#OPT:}]}" ;;
            BAND:L2:min) measured="${BAND_MIN[L2]}" ;;
            BAND:L2:max) measured="${BAND_MAX[L2]}" ;;
            BAND:L3:min) measured="${BAND_MIN[L3]}" ;;
            BAND:L3:max) measured="${BAND_MAX[L3]}" ;;
            *) measured="unknown" ;;
        esac
        limit="${BASELINE[$unit]:-}"
        if [[ -z "$limit" ]]; then
            echo "CEREMONY_BASELINE|$unit|$measured|unrecorded|FAIL"
            FAILED=1
            continue
        fi
        if [[ "$measured" -eq "$limit" ]]; then
            echo "CEREMONY_BASELINE|$unit|$measured|$limit|PASS"
        else
            echo "CEREMONY_BASELINE|$unit|$measured|$limit|FAIL"
            FAILED=1
        fi
    done
    if [[ "$FAILED" -ne 0 ]]; then
        echo "CEREMONY_GATE|FAIL|a measured figure differs from its recorded baseline; restate the baseline here and in docs/BENCHMARKS.md when a template change is legitimate" >&2
        exit 1
    fi
    echo "CEREMONY_GATE|PASS"
fi
