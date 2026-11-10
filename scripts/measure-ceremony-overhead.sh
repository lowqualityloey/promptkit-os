#!/usr/bin/env bash
# PromptKit OS Ceremony Artifact Overhead Measurement
#
# Measures the ceremony artifacts each task level requires (`workflows/route.md`,
# anchor: `Direct execution. Zero task records`) and reports their static byte
# and token load. Uses the bytes/4 convention of measure-tokens.sh:
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
# ONE TEMPLATE CARRIES TWO CEREMONY TIERS, and policy binds each level to one of
# them (`workflows/checkpoint.md`, anchor: `Requires ten canonical labels` for
# the Level 1 quick tier; anchor: `Mandatory durable execution gate requiring
# all 20 canonical checkpoint labels` for the Level 2/3 full tier). Charging the
# whole file at every level would overstate both:
#   - Level 1 optional  = the Quick Tier section alone                    267 tok
#   - Level 2/3 required = the shared header + the Full Tier section      560 tok
# The tier boundaries are read from the template's own headings
# (`templates/execution-checkpoint-template.md`, anchor: `## Quick Tier (Level 1
# Standard Work)` / anchor: `## Full Tier (Level 2 Controlled & Level 3
# Release-Critical Work)`), never from line numbers, and the three segments are
# asserted to sum to the whole file so a restructured template fails loudly
# instead of being silently mis-split.
#
# PLANNING DEPTH IS PART OF THE MODEL. `workflows/plan.md` (anchor: `Minimal
# Planning (Level 2 default)`) stops "without continuing into the full RFC", so
# a Level 2 task does NOT necessarily produce a specification file. The per-level
# baseline is therefore the Minimal Planning set (Task Record + checkpoint), and
# the specification family is published as a band that Full Planning (anchor:
# `Full Planning (Level 2 triggering work)`) adds. An earlier revision charged
# every Level 2 task for a tech spec it may never write.
#
# The Level 2 specification is a FAMILY, not a single file: `workflows/route.md`
# (anchor: `Requires a Local Task Record`) names the commands (pk:plan, pk:data,
# pk:auth, pk:api), and each maps to a different template in the checked-out
# tree. A task uses ONE member. The band is the smallest to the largest member
# added to the level's fixed set.
#
# ONE REQUIRED ARTIFACT HAS NO SHIPPED TEMPLATE. `workflows/review.md` (anchor:
# `owns one durable two-axis report`) gives pk:review "one durable two-axis
# report at docs/reviews/<review-slug>.md", and no template for it ships in this
# repository. It is listed as required and reported as not measurable from
# repository bytes -- never silently dropped, never estimated.
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
#              per-level totals, the shared setup, every required artifact on
#              its own (so offsetting drift inside one level fails), all four
#              specification variants, all five optional artifacts, and both
#              band endpoints for Level 2 and Level 3. A unit with no recorded
#              baseline fails rather than passing unrecorded.
#              Machine-parseable: CEREMONY_BASELINE|<unit>|<measured>|<limit>|PASS|FAIL
#
# Machine-parseable lines (always emitted):
#   CEREMONY_ANCHOR|<policy file>|OK
#   CEREMONY_ARTIFACT|<level or SETUP>|<path>[#<tier>]|<required|untemplated|optional|variant|setup>|<bytes>|<tokens>
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
#   REQ:*   each required artifact on its own; a multi-tier template is keyed
#           by the tier it is charged at. Per-artifact units exist so that
#           offsetting drift inside one level (one template grows, another
#           shrinks) fails instead of cancelling out in the level total.
#   SPEC:*  each specification family member
#   OPT:*   each optional artifact, keyed by the tier charged when it has tiers
#   BAND:*  specification band endpoints per level
declare -A BASELINE=(
    [L0]=0
    [L1]=0
    [L2]=5372
    [L3]=13191
    [SETUP]=3021
    [REQ:templates/execution-task-record-template.md]=4812
    [REQ:templates/execution-checkpoint-template.md#full]=560
    [REQ:templates/release-checklist.md]=3409
    [REQ:templates/release-evaluation-template.md]=3163
    [REQ:templates/contract-impact-evidence-template.md]=1247
    [SPEC:templates/tech-spec-template.md]=5480
    [SPEC:templates/data-model-spec.md]=1825
    [SPEC:templates/auth-matrix-template.md]=979
    [SPEC:templates/api-contract-spec.md]=1347
    [OPT:templates/execution-checkpoint-template.md#quick]=267
    [OPT:templates/execution-handoff-template.md]=978
    [OPT:templates/execution-scope-change-template.md]=782
    [OPT:templates/ci-triage-template.md]=1603
    [OPT:templates/code-review-checklist.md]=1534
    [BAND:L2:min]=6351
    [BAND:L2:max]=10852
    [BAND:L3:min]=14170
    [BAND:L3:max]=18671
)

# Policy the artifact model rests on. Each entry is
#   <file>|<literal fragment>|<sha256 prefix of the whole matching line>
# The fragment locates the line; the hash pins it. A rewritten sentence, or a
# requirement appended to the same line, changes the hash and fails the run.
# Every fragment is backtick-free so the same list can be quoted literally by
# both shells.
POLICY_ANCHORS=(
    'workflows/route.md|Direct execution. Zero task records|bfb62859635b83d7'
    'workflows/route.md|Natural workflow routing|164e9e3470607701'
    'workflows/route.md|Requires a Local Task Record|cef964ae7430feb8'
    'workflows/route.md|Uses full release candidate evaluation|8edb52f8602095c1'
    'workflows/route.md|as supporting references; do not create a new command|1ca0c1e74ad58f05'
    'workflows/checkpoint.md|Level 1 (Standard) work updates|88aabdd5e32c660a'
    'workflows/checkpoint.md|Requires ten canonical labels|a2be369aa6e99548'
    'workflows/checkpoint.md|Mandatory durable execution gate requiring all 20 canonical checkpoint labels|a7a8d20983332273'
    'workflows/plan.md|Minimal Planning (Level 2 default)|201483077233b647'
    'workflows/plan.md|Full Planning (Level 2 triggering work)|2eac98e5feb5025e'
    'workflows/review.md|owns one durable two-axis report|2deb075a198f7e9c'
    'workflows/ship.md|Access to|183652d35c211e10'
    'workflows/ship.md|Evidence-First CI Failure Triage and Release Linkage|cb5be9976ae2b53a'
    'templates/execution-checkpoint-template.md|## Quick Tier (Level 1 Standard Work)|8f787c21cab7d169'
    'templates/execution-checkpoint-template.md|## Full Tier (Level 2 Controlled & Level 3 Release-Critical Work)|80c04dc8ace00193'
)

# The one template that ships more than one ceremony tier in a single file.
CHECKPOINT_TEMPLATE="templates/execution-checkpoint-template.md"
CHECKPOINT_QUICK_HEADING="## Quick Tier (Level 1 Standard Work)"
CHECKPOINT_FULL_HEADING="## Full Tier (Level 2 Controlled & Level 3 Release-Critical Work)"

measure_bytes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "MEASURE_ERROR|MISSING|$file" >&2
        exit 2
    fi
    tr -d '\r' < "$file" | wc -c | tr -d ' '
}

# Bytes of one ceremony tier of the checkpoint template. Segments are delimited
# by the template's own headings, and the caller re-checks that they sum to the
# whole file:
#   header  everything above the first "## " heading (shared fill-in guide)
#   quick   the Quick Tier section
#   full    the shared header plus the Full Tier section (what Level 2/3 fill)
checkpoint_segment_bytes() {
    local tier="$1"
    local file="$KIT_DIR/$CHECKPOINT_TEMPLATE"
    if [[ ! -f "$file" ]]; then
        echo "MEASURE_ERROR|MISSING|$CHECKPOINT_TEMPLATE" >&2
        exit 2
    fi
    tr -d '\r' < "$file" | awk -v tier="$tier" -v quick="$CHECKPOINT_QUICK_HEADING" -v full="$CHECKPOINT_FULL_HEADING" '
        BEGIN { sec = 0 }
        /^## / {
            if ($0 == quick)      { sec = 1 }
            else if ($0 == full)  { sec = 2 }
            else                  { sec = 3 }
        }
        tier == "header" && sec == 0 { print; next }
        tier == "quick"  && sec == 1 { print; next }
        tier == "full"   && (sec == 0 || sec == 2) { print; next }
    ' | wc -c | tr -d ' '
}

# An artifact spec is either a repository-relative path (measured whole) or
# "<path>#<tier>" for a multi-tier template charged at one tier.
measure_artifact_bytes() {
    local spec="$1"
    case "$spec" in
        *'#'*)
            local base="${spec%%#*}"
            local tier="${spec##*#}"
            if [[ "$base" != "$CHECKPOINT_TEMPLATE" ]]; then
                echo "MEASURE_ERROR|UNKNOWN_TIERED_ARTIFACT|$spec" >&2
                exit 2
            fi
            case "$tier" in
                full|quick) checkpoint_segment_bytes "$tier" ;;
                *) echo "MEASURE_ERROR|UNKNOWN_TIER|$spec" >&2; exit 2 ;;
            esac
            ;;
        *)
            measure_bytes "$KIT_DIR/$spec"
            ;;
    esac
}

spec_note() {
    case "$1" in
        *'#'full) echo "  (shared header + Full Tier section)" ;;
        *'#'quick) echo "  (Quick Tier section)" ;;
        *) echo "" ;;
    esac
}

measure_tokens() {
    local bytes="$1"
    echo $(( (bytes + 2) / 4 ))
}

# Shared, one-time artifacts: paid once per project, updated in place after.
SHARED_SETUP="templates/state-tracker-template.md"

# Level -> per-task required artifacts that DO ship a template, grounded in
# workflows/route.md and workflows/plan.md.
#   L0 (`workflows/route.md`, anchor: `Direct execution. Zero task records`):
#       "Zero task records, no GitHub issue required, no state tracking
#       overhead." Nothing is mandatory.
#   L1 (`workflows/route.md`, anchor: `Natural workflow routing`): "Normal task
#       tracking in docs/STATE.md without requiring formal Task Record files";
#       `workflows/checkpoint.md` (anchor: `Level 1 (Standard) work updates`)
#       allows session notes instead of a file. No per-task template: the
#       tracker is shared setup.
#   L2 (`workflows/route.md`, anchor: `Requires a Local Task Record`):
#       "Requires a Local Task Record at docs/tasks/<task-id>.md" plus formal
#       specification. Minimal Planning is the default and stops before the
#       RFC, so the specification is NOT in the default set -- it is the band
#       below. The checkpoint is required by the durable-gate anchor above, and
#       policy binds L2 to its FULL tier.
#   L3 (`workflows/route.md`, anchor: `Uses full release candidate evaluation`):
#       Level 2 evidence plus "contract impact evidence (pk:ship)" and release
#       evaluation. The two evidence templates are named as supporting
#       references by the `as supporting references; do not create a new
#       command` anchor; release-checklist.md is a pk:ship precondition
#       (`workflows/ship.md`, anchor: `Evidence-First CI Failure Triage and
#       Release Linkage`). CI triage is conditional on a reported failure; the
#       QA review checklist is review evidence, not a per-task record.
declare -A LEVEL_REQUIRED=(
    [L0]=""
    [L1]=""
    [L2]="templates/execution-task-record-template.md $CHECKPOINT_TEMPLATE#full"
    [L3]="templates/execution-task-record-template.md $CHECKPOINT_TEMPLATE#full templates/release-checklist.md templates/release-evaluation-template.md templates/contract-impact-evidence-template.md"
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
    [L1]="$CHECKPOINT_TEMPLATE#quick"
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

# Every required artifact, once, for the per-artifact baselines.
REQUIRED_UNION=(
    "templates/execution-task-record-template.md"
    "$CHECKPOINT_TEMPLATE#full"
    "templates/release-checklist.md"
    "templates/release-evaluation-template.md"
    "templates/contract-impact-evidence-template.md"
)

# Optional artifacts, union across levels, each measured once at the tier it is
# charged at.
OPTIONAL_UNION=(
    "$CHECKPOINT_TEMPLATE#quick"
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

# The tier split must reconstruct the file exactly, or every tier figure below
# is meaningless. Fail closed rather than publish a plausible wrong number.
CHECKPOINT_TOTAL_BYTES=$(measure_bytes "$KIT_DIR/$CHECKPOINT_TEMPLATE")
CHECKPOINT_HEADER_BYTES=$(checkpoint_segment_bytes header)
CHECKPOINT_QUICK_BYTES=$(checkpoint_segment_bytes quick)
CHECKPOINT_FULL_RECORD_BYTES=$(checkpoint_segment_bytes full)
CHECKPOINT_FULL_SECTION_BYTES=$(( CHECKPOINT_FULL_RECORD_BYTES - CHECKPOINT_HEADER_BYTES ))
if [[ $(( CHECKPOINT_HEADER_BYTES + CHECKPOINT_QUICK_BYTES + CHECKPOINT_FULL_SECTION_BYTES )) -ne "$CHECKPOINT_TOTAL_BYTES" ]]; then
    echo "MEASURE_ERROR|TIER_SPLIT|$CHECKPOINT_TEMPLATE" >&2
    echo "ANCHOR_ERROR|POLICY_DRIFT|checkpoint tier segments ($CHECKPOINT_HEADER_BYTES + $CHECKPOINT_QUICK_BYTES + $CHECKPOINT_FULL_SECTION_BYTES) do not sum to the whole file ($CHECKPOINT_TOTAL_BYTES)" >&2
    echo "ANCHOR_ERROR|ACTION|re-read templates/execution-checkpoint-template.md, re-derive the tier split in this script, then restate the figures in docs/BENCHMARKS.md" >&2
    exit 2
fi

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
    for spec in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_artifact_bytes "$spec")
        tokens=$(measure_tokens "$bytes")
        REQ_BYTES[$level]=$(( REQ_BYTES[$level] + bytes ))
        REQ_TOKENS[$level]=$(( REQ_TOKENS[$level] + tokens ))
        REQ_COUNT[$level]=$(( REQ_COUNT[$level] + 1 ))
    done
    for path in ${LEVEL_UNTEMPLATED[$level]}; do
        UNT_COUNT[$level]=$(( UNT_COUNT[$level] + 1 ))
    done
    for spec in ${LEVEL_OPTIONAL[$level]}; do
        OPT_COUNT[$level]=$(( OPT_COUNT[$level] + 1 ))
    done
done

declare -A ART_BYTES ART_TOKENS
for spec in "${REQUIRED_UNION[@]}"; do
    ART_BYTES[$spec]=$(measure_artifact_bytes "$spec")
    ART_TOKENS[$spec]=$(measure_tokens "${ART_BYTES[$spec]}")
done

declare -A SPEC_TOKENS OPT_BYTES OPT_TOKENS
SPEC_MIN=0
SPEC_MAX=0
for path in "${SPEC_FAMILY[@]}"; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    tokens=$(measure_tokens "$bytes")
    SPEC_TOKENS[$path]=$tokens
    if [[ "$SPEC_MIN" -eq 0 || "$tokens" -lt "$SPEC_MIN" ]]; then SPEC_MIN=$tokens; fi
    if [[ "$tokens" -gt "$SPEC_MAX" ]]; then SPEC_MAX=$tokens; fi
done
for spec in "${OPTIONAL_UNION[@]}"; do
    OPT_BYTES[$spec]=$(measure_artifact_bytes "$spec")
    OPT_TOKENS[$spec]=$(measure_tokens "${OPT_BYTES[$spec]}")
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

echo "Multi-tier template split (from its own headings, not line numbers):"
printf "  %-52s %6d B  %5d tok\n" "$CHECKPOINT_TEMPLATE header" "$CHECKPOINT_HEADER_BYTES" "$(measure_tokens "$CHECKPOINT_HEADER_BYTES")"
printf "  %-52s %6d B  %5d tok  Level 1 quick tier\n" "$CHECKPOINT_TEMPLATE quick" "$CHECKPOINT_QUICK_BYTES" "$(measure_tokens "$CHECKPOINT_QUICK_BYTES")"
printf "  %-52s %6d B  %5d tok  Level 2/3 full section\n" "$CHECKPOINT_TEMPLATE full" "$CHECKPOINT_FULL_SECTION_BYTES" "$(measure_tokens "$CHECKPOINT_FULL_SECTION_BYTES")"
printf "  %-52s %6d B  %5d tok  header + full section\n" "$CHECKPOINT_TEMPLATE full record" "$CHECKPOINT_FULL_RECORD_BYTES" "$(measure_tokens "$CHECKPOINT_FULL_RECORD_BYTES")"
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
    for spec in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_artifact_bytes "$spec")
        printf "  %-2s required     %-52s %6d B  %5d tok%s\n" "$level" "$spec" "$bytes" "$(measure_tokens "$bytes")" "$(spec_note "$spec")"
    done
    for path in ${LEVEL_UNTEMPLATED[$level]}; do
        printf "  %-2s required     %-52s %6s B  %5s tok  (no shipped template)\n" "$level" "$path" "-" "-"
    done
    for spec in ${LEVEL_OPTIONAL[$level]}; do
        bytes=$(measure_artifact_bytes "$spec")
        printf "  %-2s optional     %-52s %6d B  %5d tok%s\n" "$level" "$spec" "$bytes" "$(measure_tokens "$bytes")" "$(spec_note "$spec")"
    done
done
echo ""

echo "Level 2 planning depth (workflows/plan.md, anchor: 'Minimal Planning (Level 2 default)'):"
printf "  %-34s %6d tok  (Task Record + full-tier checkpoint; no specification file)\n" "Minimal Planning (default)" "${REQ_TOKENS[L2]}"
printf "  %-34s %6d-%d tok  (adds exactly one specification family member)\n" "Full Planning (triggering)" "${BAND_MIN[L2]}" "${BAND_MAX[L2]}"
echo ""
echo "Level 3 planning depth (Level 2 planning plus release evidence):"
printf "  %-34s %6d tok  (Task Record + full-tier checkpoint + release evidence)\n" "Minimal Planning (default)" "${REQ_TOKENS[L3]}"
printf "  %-34s %6d-%d tok  (adds exactly one specification family member)\n" "Full Planning (triggering)" "${BAND_MIN[L3]}" "${BAND_MAX[L3]}"
echo ""

echo "Specification family (one member per task, selected by sub-trigger):"
for path in "${SPEC_FAMILY[@]}"; do
    printf "  %-52s %5d tok  L2 total %6d tok\n" "$path" "${SPEC_TOKENS[$path]}" "$(( REQ_TOKENS[L2] + SPEC_TOKENS[$path] ))"
done
echo ""

echo "Optional artifacts (required only in the condition named):"
for spec in "${OPTIONAL_UNION[@]}"; do
    printf "  %-52s %5d tok%s\n" "$spec" "${OPT_TOKENS[$spec]}" "$(spec_note "$spec")"
done
echo ""

echo "CEREMONY_ARTIFACT|SETUP|$SHARED_SETUP|setup|$SETUP_BYTES|$SETUP_TOKENS"
for level in L0 L1 L2 L3; do
    if [[ -z "${LEVEL_REQUIRED[$level]}" && -z "${LEVEL_UNTEMPLATED[$level]}" && -z "${LEVEL_OPTIONAL[$level]}" ]]; then
        echo "CEREMONY_ARTIFACT|$level|-|required|0|0"
        continue
    fi
    for spec in ${LEVEL_REQUIRED[$level]}; do
        bytes=$(measure_artifact_bytes "$spec")
        echo "CEREMONY_ARTIFACT|$level|$spec|required|$bytes|$(measure_tokens "$bytes")"
    done
    for path in ${LEVEL_UNTEMPLATED[$level]}; do
        echo "CEREMONY_ARTIFACT|$level|$path|untemplated|0|0"
    done
    for spec in ${LEVEL_OPTIONAL[$level]}; do
        bytes=$(measure_artifact_bytes "$spec")
        echo "CEREMONY_ARTIFACT|$level|$spec|optional|$bytes|$(measure_tokens "$bytes")"
    done
done
for path in "${SPEC_FAMILY[@]}"; do
    bytes=$(measure_bytes "$KIT_DIR/$path")
    echo "CEREMONY_ARTIFACT|SPEC|$path|variant|$bytes|${SPEC_TOKENS[$path]}"
done

echo ""

PROFILE="$(grep -m1 '^- \*\*Profile\*\*:' "$KIT_DIR/PROMPTKIT.md" 2>/dev/null | sed 's/^- \*\*Profile\*\*: *//; s/`//g; s/[^a-z].*//' || true)"
echo "CEREMONY_PROVENANCE|sha=$SHA|date=$DATESTAMP|convention=floor((bytes+2)/4)|profile=${PROFILE:-unknown}|units=per-task+shared-setup|tiers=checkpoint-quick-and-full|selection=curated-not-parsed|anchors=whole-line-sha256"
echo "CEREMONY_UNMEASURED|live-telemetry|not-measured|tool calls, elapsed time, model/host identity and interventions per level need host telemetry this repository does not capture"
echo "CEREMONY_UNMEASURED|sample-count|not-measured|static artifact measurement is deterministic; no repeated live runs were executed for this number"
echo "CEREMONY_UNMEASURED|fill-cost|not-measured|filling a template costs generation; the figures here are the size of the template text, not the cost of producing a record"
echo "CEREMONY_UNMEASURED|review-report|not-measured|workflows/review.md (anchor: 'owns one durable two-axis report') requires one durable report at docs/reviews/<review-slug>.md and no template for it ships in this repository, so its size is not derivable from repository bytes"

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
    for spec in "${REQUIRED_UNION[@]}"; do STRICT_UNITS+=("REQ:$spec"); done
    for path in "${SPEC_FAMILY[@]}"; do STRICT_UNITS+=("SPEC:$path"); done
    for spec in "${OPTIONAL_UNION[@]}"; do STRICT_UNITS+=("OPT:$spec"); done
    STRICT_UNITS+=("BAND:L2:min" "BAND:L2:max" "BAND:L3:min" "BAND:L3:max")
    for unit in "${STRICT_UNITS[@]}"; do
        case "$unit" in
            L0|L1|L2|L3) measured="${REQ_TOKENS[$unit]}" ;;
            SETUP) measured="$SETUP_TOKENS" ;;
            REQ:*) measured="${ART_TOKENS[${unit#REQ:}]}" ;;
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
