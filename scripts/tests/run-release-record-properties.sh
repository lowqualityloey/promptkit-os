#!/usr/bin/env bash
# Deterministic, dependency-free local release-evidence property harness.
# Run from repository root: bash scripts/tests/run-release-record-properties.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/release-records"
ITERATIONS="${PROMPTKIT_PROPERTY_ITERATIONS:-100}"
SEED=20260908
RNG_STATE=$SEED
CHOICE=0

declare -A CASE_FIELD=()
declare -A CASE_IDS=()
declare -A CASE_SEEN=()

fail_harness() {
    echo "HARNESS_FAILURE|$1" >&2
    exit 1
}

fail_property() {
    echo "PROPERTY_FAILURE|$1|ITERATION=$2|$3" >&2
    exit 1
}

next_choice() {
    local modulus="$1"
    RNG_STATE=$(( (RNG_STATE * 48271) % 2147483647 ))
    CHOICE=$(( RNG_STATE % modulus ))
}

case_field() {
    local property="$1" case_id="$2" field="$3"
    printf '%s' "${CASE_FIELD["$property|$case_id|$field"]-NONE}"
}

load_fixture() {
    local property="$1" file
    file="$FIXTURE_ROOT/$property.tsv"
    local case_id entity field value key case_key
    [[ -f "$file" ]] || fail_harness "Missing fixture: $file"
    while IFS=$'\t' read -r case_id entity field value || [[ -n "$case_id" ]]; do
        [[ -z "$case_id" || "$case_id" == \#* ]] && continue
        [[ -z "$entity" || -z "$field" || -z "$value" ]] && fail_harness "Malformed fixture row in $file"
        key="$property|$case_id|$field"
        CASE_FIELD["$key"]="$value"
        case_key="$property|$case_id"
        if [[ -z "${CASE_SEEN[$case_key]+present}" ]]; then
            CASE_SEEN["$case_key"]=1
            CASE_IDS["$property"]="${CASE_IDS[$property]-} $case_id"
        fi
    done < "$file"
    [[ -n "${CASE_IDS[$property]-}" ]] || fail_harness "Fixture has no cases: $file"
}

assert_shape_generation() {
    local property="$1" iteration="$2"
    local prefix="${property^^}-$iteration"
    local commit_id="COMMIT-$prefix"
    local merge_id="MERGE-$prefix"
    local squash_id="SQUASH-$prefix"
    local duplicate_a="DUP-A-$prefix"
    local duplicate_b="DUP-B-$prefix"
    local revert_id="REVERT-$prefix"
    local reverted_id="REVERTED-$prefix"
    local partial_id="PARTIAL-REVERT-$prefix"
    local duplicate_group="DUPLICATE-GROUP-$prefix"
    local full_revert_relation="$revert_id=>$reverted_id"
    local partial_evidence="EVIDENCE-$partial_id"
    local qa_pass="QA-$prefix:pass"
    local qa_blocked="QA-$prefix:blocked"
    local -a combined_history=("$commit_id" "$merge_id" "$squash_id" "$duplicate_a" "$duplicate_b" "$reverted_id" "$revert_id" "$partial_id")
    local -a action_log=()
    [[ "$commit_id" == COMMIT-* && "${combined_history[0]}" == "$commit_id" ]] || fail_harness "Synthetic commit history is unstable"
    [[ "${combined_history[1]}" == "$merge_id" && "${combined_history[2]}" == "$squash_id" ]] || fail_harness "Synthetic merge/squash order is invalid"
    [[ "$duplicate_a" != "$duplicate_b" && "$duplicate_group" == DUPLICATE-GROUP-* ]] || fail_harness "Synthetic duplicate group is invalid"
    [[ "$full_revert_relation" == "$revert_id=>$reverted_id" && "$partial_id" == PARTIAL-REVERT-* ]] || fail_harness "Synthetic revert relations are invalid"
    [[ "$partial_evidence" == EVIDENCE-* ]] || fail_harness "Synthetic partial-revert evidence is missing"
    [[ "$qa_pass" == *:pass && "$qa_blocked" == *:blocked ]] || fail_harness "Synthetic QA outcomes are invalid"
    [[ "${#combined_history[@]}" -eq 8 && "${#action_log[@]}" -eq 0 ]] || fail_harness "Synthetic history or action stub is invalid"
}

join_csv() {
    local IFS=','
    printf '%s' "$*"
}

classify_evidence() {
    local case_id="$1" conventional_type="$2"
    local public evidence linked contract before after impact proposed guidance
    local maintenance_declared no_public_contract complete=1 expected_proposed
    public="$(case_field property-01 "$case_id" public)"
    evidence="$(case_field property-01 "$case_id" evidence)"
    linked="$(case_field property-01 "$case_id" linked)"
    contract="$(case_field property-01 "$case_id" contract)"
    before="$(case_field property-01 "$case_id" before)"
    after="$(case_field property-01 "$case_id" after)"
    impact="$(case_field property-01 "$case_id" impact)"
    proposed="$(case_field property-01 "$case_id" proposed)"
    guidance="$(case_field property-01 "$case_id" guidance)"
    maintenance_declared="$(case_field property-01 "$case_id" maintenance_declared)"
    no_public_contract="$(case_field property-01 "$case_id" no_public_contract)"
    : "${conventional_type:?}"

    if [[ "$public" == 1 ]]; then
        [[ "$evidence" != NONE || "$linked" != NONE ]] || complete=0
        for value in "$contract" "$before" "$after" "$impact"; do
            [[ "$value" != NONE ]] || complete=0
        done
        case "$impact" in
            additive) expected_proposed=minor ;;
            corrective) expected_proposed="patch" ;;
            breaking) expected_proposed=major; [[ "$guidance" != NONE ]] || complete=0 ;;
            *) complete=0; expected_proposed=none ;;
        esac
        [[ "$proposed" == "$expected_proposed" ]] || complete=0
        [[ "$complete" -eq 1 ]] && printf 'eligible' || printf 'incomplete'
        return
    fi

    if [[ "$maintenance_declared" == 1 && "$no_public_contract" == 1 && "$proposed" == none ]]; then
        printf 'maintenance'
    else
        printf 'incomplete'
    fi
}

property_one() {
    local iteration case_id expected actual
    local -a types=(feat fix perf)
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-01 "$iteration"
        for case_id in ${CASE_IDS[property-01]}; do
            next_choice "${#types[@]}"
            expected="$(case_field property-01 "$case_id" expected)"
            actual="$(classify_evidence "$case_id" "${types[$CHOICE]}")"
            [[ "$actual" == "$expected" ]] || fail_property eligible-evidence-maintenance "$iteration" "$case_id expected $expected got $actual"
        done
    done
    echo "PROPERTY|eligible-evidence-maintenance|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

augment_history() {
    local history="$1" candidate="$2" iteration="$3"
    local -a items=()
    local item
    AUGMENTED_HISTORY=()
    IFS=',' read -r -a items <<< "$history"
    for item in "${items[@]}"; do
        if [[ "$item" == "$candidate" ]]; then
            AUGMENTED_HISTORY+=("GEN-P02-$iteration-$CHOICE")
        fi
        AUGMENTED_HISTORY+=("$item")
    done
    AUGMENTED_HISTORY_CSV="$(join_csv "${AUGMENTED_HISTORY[@]}")"
}

select_release_range() {
    local history="$1" baseline="$2" candidate="$3"
    local -a items=()
    local item index=0 baseline_index=-1 candidate_index=-1 candidate_count=0 started=0
    RESULT_RANGE=()
    RESULT_VALID=1
    IFS=',' read -r -a items <<< "$history"
    [[ "$baseline" == NONE ]] && started=1
    for item in "${items[@]}"; do
        if [[ "$item" == "$baseline" && "$baseline" != NONE ]]; then
            baseline_index=$index
            started=1
            index=$((index + 1))
            continue
        fi
        if [[ "$item" == "$candidate" ]]; then
            candidate_count=$((candidate_count + 1))
            candidate_index=$index
        fi
        [[ "$started" -eq 1 ]] && RESULT_RANGE+=("$item")
        index=$((index + 1))
    done
    [[ "$baseline" == NONE || "$baseline_index" -ge 0 ]] || RESULT_VALID=0
    [[ "$candidate_count" -eq 1 && "$candidate_index" -ge 0 ]] || RESULT_VALID=0
    [[ "$candidate_index" -eq $(( ${#items[@]} - 1 )) ]] || RESULT_VALID=0
    [[ "$baseline" == NONE || "$baseline_index" -lt "$candidate_index" ]] || RESULT_VALID=0
    [[ "${#RESULT_RANGE[@]}" -gt 0 && "${RESULT_RANGE[-1]}" == "$candidate" ]] || RESULT_VALID=0
    RESULT_RANGE_CSV="$(join_csv "${RESULT_RANGE[@]}")"
}

property_two() {
    local iteration case_id history baseline candidate expected first_result second_result
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-02 "$iteration"
        for case_id in ${CASE_IDS[property-02]}; do
            next_choice 2
            history="$(case_field property-02 "$case_id" history)"
            baseline="$(case_field property-02 "$case_id" baseline)"
            candidate="$(case_field property-02 "$case_id" candidate)"
            expected="$(case_field property-02 "$case_id" expected)"
            augment_history "$history" "$candidate" "$iteration"
            select_release_range "$AUGMENTED_HISTORY_CSV" "$baseline" "$candidate"
            first_result="$RESULT_VALID|$RESULT_RANGE_CSV"
            select_release_range "$AUGMENTED_HISTORY_CSV" "$baseline" "$candidate"
            second_result="$RESULT_VALID|$RESULT_RANGE_CSV"
            [[ "$first_result" == "$second_result" ]] || fail_property candidate-inclusive-range "$iteration" "$case_id is not reproducible"
            if [[ "$expected" == PASS ]]; then
                [[ "$RESULT_VALID" -eq 1 ]] || fail_property candidate-inclusive-range "$iteration" "$case_id expected PASS"
            else
                [[ "$RESULT_VALID" -eq 0 ]] || fail_property candidate-inclusive-range "$iteration" "$case_id expected FAIL"
            fi
        done
    done
    echo "PROPERTY|candidate-inclusive-range|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

resolve_latest_approved() {
    local records="$1"
    local -a items=()
    local record status version commit evaluation sequence
    local highest=-1
    RESULT_BASELINE=NONE
    IFS=';' read -r -a items <<< "$records"
    for record in "${items[@]}"; do
        IFS=',' read -r _ status version commit evaluation sequence <<< "$record"
        if [[ "${status,,}" == approved && "$sequence" =~ ^[0-9]+$ && "$sequence" -gt "$highest" ]]; then
            highest="$sequence"
            RESULT_BASELINE="$evaluation|$version|$commit"
        fi
    done
}

property_three() {
    local iteration case_id records expected generated_result
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-03 "$iteration"
        for case_id in ${CASE_IDS[property-03]}; do
            next_choice 2
            records="$(case_field property-03 "$case_id" records)"
            expected="$(case_field property-03 "$case_id" expected)"
            records="$records;R-GEN,preliminary,9.9.9,GEN-P03-$iteration,GEN-EVAL-$iteration,$((100 + iteration))"
            resolve_latest_approved "$records"
            generated_result="${RESULT_BASELINE%%|*}"
            [[ "$generated_result" == "$expected" ]] || fail_property latest-approved-baseline "$iteration" "$case_id expected $expected got $generated_result"
        done
    done
    echo "PROPERTY|latest-approved-baseline|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

classify_impact() {
    local impact="$1" guidance="$2" proposed="$3" derived
    case "$impact" in
        additive) derived=minor ;;
        corrective) derived="patch" ;;
        breaking) [[ "$guidance" != NONE ]] && derived=major || derived=blocked ;;
        none) derived=none ;;
        *) derived=blocked ;;
    esac
    if [[ "$proposed" != NONE && "$proposed" != "$derived" && "$derived" != blocked ]]; then
        derived=blocked
    fi
    printf '%s' "$derived"
}

property_four() {
    local iteration case_id impact guidance proposed expected actual types type
    local -a type_values=()
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-04 "$iteration"
        for case_id in ${CASE_IDS[property-04]}; do
            types="$(case_field property-04 "$case_id" types)"
            IFS=',' read -r -a type_values <<< "$types"
            next_choice "${#type_values[@]}"
            type="${type_values[$CHOICE]}"
            : "${type:?}"
            impact="$(case_field property-04 "$case_id" impact)"
            guidance="$(case_field property-04 "$case_id" guidance)"
            proposed="$(case_field property-04 "$case_id" proposed)"
            expected="$(case_field property-04 "$case_id" expected)"
            actual="$(classify_impact "$impact" "$guidance" "$proposed")"
            [[ "$actual" == "$expected" ]] || fail_property evidence-driven-impact "$iteration" "$case_id expected $expected got $actual"
        done
    done
    echo "PROPERTY|evidence-driven-impact|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

parse_core_semver() {
    local version="${1#v}"
    [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || return 1
    SEMVER_MAJOR="${BASH_REMATCH[1]}"
    SEMVER_MINOR="${BASH_REMATCH[2]}"
    SEMVER_PATCH="${BASH_REMATCH[3]}"
}

derive_candidate() {
    local impacts="$1" prior="$2" first="$3" impact rank=0
    RESULT_IMPACT=none
    RESULT_VERSION=NONE
    IFS=',' read -r -a impact_values <<< "$impacts"
    for impact in "${impact_values[@]}"; do
        case "$impact" in
            blocked)
                RESULT_IMPACT=blocked
                RESULT_VERSION=NONE
                return
                ;;
            major)
                if (( rank < 3 )); then
                    rank=3
                    RESULT_IMPACT=major
                fi
                ;;
            minor)
                if (( rank < 2 )); then
                    rank=2
                    RESULT_IMPACT=minor
                fi
                ;;
            patch)
                if (( rank < 1 )); then
                    rank=1
                    RESULT_IMPACT="patch"
                fi
                ;;
            none) ;;
            *)
                RESULT_IMPACT=blocked
                RESULT_VERSION=NONE
                return
                ;;
        esac
    done
    if (( rank == 0 )); then
        return 0
    fi
    if [[ "$first" == 1 ]]; then
        RESULT_VERSION=1.0.0
        return
    fi
    parse_core_semver "$prior" || { RESULT_IMPACT=blocked; return; }
    case "$RESULT_IMPACT" in
        major) RESULT_VERSION="$((SEMVER_MAJOR + 1)).0.0" ;;
        minor) RESULT_VERSION="$SEMVER_MAJOR.$((SEMVER_MINOR + 1)).0" ;;
        patch) RESULT_VERSION="$SEMVER_MAJOR.$SEMVER_MINOR.$((SEMVER_PATCH + 1))" ;;
    esac
}

property_five() {
    local iteration case_id impacts prior first expected_impact expected_version
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-05 "$iteration"
        for case_id in ${CASE_IDS[property-05]}; do
            next_choice 2
            impacts="$(case_field property-05 "$case_id" impacts)"
            prior="$(case_field property-05 "$case_id" prior)"
            first="$(case_field property-05 "$case_id" first)"
            expected_impact="$(case_field property-05 "$case_id" expected-impact)"
            expected_version="$(case_field property-05 "$case_id" expected-version)"
            derive_candidate "$impacts" "$prior" "$first"
            [[ "$RESULT_IMPACT" == "$expected_impact" ]] || fail_property greatest-impact-first-release "$iteration" "$case_id impact expected $expected_impact got $RESULT_IMPACT"
            [[ "$RESULT_VERSION" == "$expected_version" ]] || fail_property greatest-impact-first-release "$iteration" "$case_id version expected $expected_version got $RESULT_VERSION"
        done
    done
    echo "PROPERTY|greatest-impact-first-release|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

property_six() {
    local iteration case_id core prerelease commit supporting display promoted expected generated_support
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-06 "$iteration"
        for case_id in ${CASE_IDS[property-06]}; do
            next_choice 2
            core="$(case_field property-06 "$case_id" core)"
            prerelease="$(case_field property-06 "$case_id" prerelease)"
            commit="$(case_field property-06 "$case_id" commit)-I$iteration"
            supporting="$(case_field property-06 "$case_id" supporting)"
            generated_support="$supporting,GEN-P06-$iteration"
            expected="$(case_field property-06 "$case_id" expected)"
            parse_core_semver "$core" || fail_property preliminary-provenance-promotion "$iteration" "$case_id has invalid core"
            [[ -n "$commit" && "$generated_support" != NONE ]] || fail_property preliminary-provenance-promotion "$iteration" "$case_id lost provenance"
            if [[ "$prerelease" == NONE ]]; then display="$core"; else display="$core-$prerelease"; fi
            promoted="$core"
            [[ "$display" == "$core" || "$display" == "$core-$prerelease" ]] || fail_property preliminary-provenance-promotion "$iteration" "$case_id display changed core"
            [[ "$promoted" == "$core" && "$commit" == *"-I$iteration" && "$generated_support" == *"GEN-P06-$iteration"* ]] || fail_property preliminary-provenance-promotion "$iteration" "$case_id promotion lost provenance"
            [[ "$expected" == PASS ]] || fail_property preliminary-provenance-promotion "$iteration" "$case_id fixture expected non-pass"
        done
    done
    echo "PROPERTY|preliminary-provenance-promotion|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

validate_approval() {
    local candidate="$1" approved="$2" tag="$3" decision="$4" coordinator="$5" rationale="$6"
    local normalized_approved="${approved#v}"
    RESULT_APPROVAL=PASS
    parse_core_semver "$candidate" || RESULT_APPROVAL=FAIL
    parse_core_semver "$approved" || RESULT_APPROVAL=FAIL
    [[ "${decision,,}" == approved ]] || RESULT_APPROVAL=FAIL
    [[ "$coordinator" != NONE ]] || RESULT_APPROVAL=FAIL
    [[ "$tag" == "v$normalized_approved" || "$tag" == "$normalized_approved" ]] || RESULT_APPROVAL=FAIL
    if [[ "$candidate" != "$approved" && "$rationale" == NONE ]]; then RESULT_APPROVAL=FAIL; fi
}

property_seven() {
    local iteration case_id candidate approved tag decision coordinator rationale expected
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-07 "$iteration"
        for case_id in ${CASE_IDS[property-07]}; do
            next_choice 2
            candidate="$(case_field property-07 "$case_id" candidate)"
            approved="$(case_field property-07 "$case_id" approved)"
            tag="$(case_field property-07 "$case_id" tag)"
            decision="$(case_field property-07 "$case_id" decision)"
            coordinator="$(case_field property-07 "$case_id" coordinator)"
            rationale="$(case_field property-07 "$case_id" rationale)"
            expected="$(case_field property-07 "$case_id" expected)"
            validate_approval "$candidate" "$approved" "$tag" "$decision" "$coordinator" "$rationale"
            [[ "$RESULT_APPROVAL" == "$expected" ]] || fail_property approval-justification-alignment "$iteration" "$case_id expected $expected got $RESULT_APPROVAL"
        done
    done
    echo "PROPERTY|approval-justification-alignment|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

array_contains() {
    local needle="$1" value
    shift
    for value in "$@"; do
        if [[ "$value" == "$needle" ]]; then return 0; fi
    done
    return 1
}

array_csv_or_none() {
    if [[ "$#" -eq 0 ]]; then printf 'NONE'; else join_csv "$@"; fi
}

array_plus_or_none() {
    if [[ "$#" -eq 0 ]]; then printf 'NONE'; else local IFS='+'; printf '%s' "$*"; fi
}

item_field() {
    local property="$1" case_id="$2" item_id="$3" field="$4"
    case_field "$property" "$case_id" "item.$item_id.$field"
}

encode_effective_item() {
    local property="$1" case_id="$2" item_id="$3" shape kind impact contract before after guidance evidence
    shape="$(item_field "$property" "$case_id" "$item_id" shape)"
    kind="$(item_field "$property" "$case_id" "$item_id" kind)"
    impact="$(item_field "$property" "$case_id" "$item_id" impact)"
    contract="$(item_field "$property" "$case_id" "$item_id" contract)"
    before="$(item_field "$property" "$case_id" "$item_id" before)"
    after="$(item_field "$property" "$case_id" "$item_id" after)"
    guidance="$(item_field "$property" "$case_id" "$item_id" guidance)"
    evidence="$(item_field "$property" "$case_id" "$item_id" evidence)"
    printf '%s~%s~%s~%s~%s~%s~%s~%s~%s' "$item_id" "$shape" "$kind" "$impact" "$contract" "$before" "$after" "$guidance" "$evidence"
}

normalize_history() {
    local property="$1" case_id="$2" history="$3" id shape rep target
    local -a ordered=()
    NORMALIZED_ITEMS=()
    NORMALIZED_IDS=()
    FULL_REVERT_REMOVED=()
    DUPLICATE_REPRESENTATIVES=()
    PARTIAL_REVERT_SOURCES=()
    MERGE_COUNT=0
    SQUASH_COUNT=0
    IFS=',' read -r -a ordered <<< "$history"
    for id in "${ordered[@]}"; do
        shape="$(item_field "$property" "$case_id" "$id" shape)"
        if [[ "$shape" == full-revert ]]; then
            target="$(item_field "$property" "$case_id" "$id" target)"
            [[ "$target" != NONE ]] && FULL_REVERT_REMOVED+=("$target")
            FULL_REVERT_REMOVED+=("$id")
        fi
    done
    for id in "${ordered[@]}"; do
        shape="$(item_field "$property" "$case_id" "$id" shape)"
        if [[ "$shape" == merge ]]; then
            MERGE_COUNT=$((MERGE_COUNT + 1))
            continue
        fi
        if array_contains "$id" "${FULL_REVERT_REMOVED[@]}"; then continue; fi
        if [[ "$shape" == duplicate ]]; then
            rep="$(item_field "$property" "$case_id" "$id" representative)"
            if [[ "$rep" != NONE && "$rep" != "$id" ]]; then continue; fi
            DUPLICATE_REPRESENTATIVES+=("$id")
        fi
        if [[ "$shape" == squash ]]; then SQUASH_COUNT=$((SQUASH_COUNT + 1)); fi
        if [[ "$shape" == partial-revert ]]; then PARTIAL_REVERT_SOURCES+=("$id"); fi
        if [[ "$(item_field "$property" "$case_id" "$id" kind)" == excluded ]]; then continue; fi
        NORMALIZED_ITEMS+=("$(encode_effective_item "$property" "$case_id" "$id")")
        NORMALIZED_IDS+=("$id")
    done
    NORMALIZED_SERIALIZED="$(join_csv "${NORMALIZED_ITEMS[@]}")"
    NORMALIZED_IDS_CSV="$(array_csv_or_none "${NORMALIZED_IDS[@]}")"
    FULL_REVERT_REMOVED_CSV="$(array_plus_or_none "${FULL_REVERT_REMOVED[@]}")"
    DUPLICATE_REPRESENTATIVES_CSV="$(array_csv_or_none "${DUPLICATE_REPRESENTATIVES[@]}")"
    PARTIAL_REVERT_SOURCES_CSV="$(array_csv_or_none "${PARTIAL_REVERT_SOURCES[@]}")"
}

build_notes_input() {
    local property="$1" case_id="$2" effective="$3" id
    local -a ids=()
    NOTE_BUILD_ITEMS=()
    IFS=',' read -r -a ids <<< "$effective"
    for id in "${ids[@]}"; do
        [[ "$id" == NONE ]] && continue
        NOTE_BUILD_ITEMS+=("$(encode_effective_item "$property" "$case_id" "$id")")
    done
    NOTES_INPUT_SERIALIZED="$(join_csv "${NOTE_BUILD_ITEMS[@]}")"
}

effective_impacts() {
    local property="$1" case_id="$2" effective="$3" id impact
    local -a impacts=() ids=()
    IFS=',' read -r -a ids <<< "$effective"
    for id in "${ids[@]}"; do
        [[ "$id" == NONE ]] && continue
        impact="$(case_field "$property" "$case_id" "item.$id.impact")"
        [[ "$impact" != NONE ]] || return 1
        impacts+=("$impact")
    done
    if [[ "${#impacts[@]}" -eq 0 ]]; then printf 'none'; else join_csv "${impacts[@]}"; fi
}

derive_candidate_from_effective() {
    local snapshot="$1" record id shape kind impact contract before after guidance evidence
    local -a records=()
    CANDIDATE_INPUT_SNAPSHOT="$snapshot"
    CANDIDATE_SOURCES=()
    IFS=',' read -r -a records <<< "$snapshot"
    for record in "${records[@]}"; do
        IFS='~' read -r id shape kind impact contract before after guidance evidence <<< "$record"
        case "$impact" in
            blocked) CANDIDATE_SOURCES+=("$id"); return ;;
            none) ;;
        esac
        if [[ "$impact" != none && "$kind" != excluded ]]; then CANDIDATE_SOURCES+=("$id"); fi
    done
    CANDIDATE_SOURCES_CSV="$(array_csv_or_none "${CANDIDATE_SOURCES[@]}")"
}

derive_notes_from_effective() {
    local snapshot="$1" maintenance_policy="$2" record id shape kind impact contract before after guidance evidence note_id
    local -a records=()
    NOTE_INPUT_SNAPSHOT="$snapshot"
    NOTE_PUBLIC_IDS=()
    NOTE_PUBLIC_SOURCE_IDS=()
    NOTE_MAINTENANCE_IDS=()
    NOTE_MAINTENANCE_SOURCE_IDS=()
    NOTE_CHANGELOG_IDS=()
    NOTES_RESULT=PASS
    IFS=',' read -r -a records <<< "$snapshot"
    for record in "${records[@]}"; do
        IFS='~' read -r id shape kind impact contract before after guidance evidence <<< "$record"
        if [[ "$kind" == excluded || ("$impact" == none && "$kind" != maintenance) ]]; then continue; fi
        if [[ "$impact" == major && "$guidance" == NONE ]]; then NOTES_RESULT=FAIL; continue; fi
        note_id="NOTE-$id"
        if array_contains "$note_id" "${NOTE_PUBLIC_IDS[@]}" "${NOTE_MAINTENANCE_IDS[@]}"; then NOTES_RESULT=FAIL; continue; fi
        if [[ "$kind" == maintenance ]]; then
            if [[ "$maintenance_policy" == include ]]; then NOTE_MAINTENANCE_IDS+=("$note_id"); NOTE_MAINTENANCE_SOURCE_IDS+=("$id"); fi
        else
            NOTE_PUBLIC_IDS+=("$note_id")
            NOTE_PUBLIC_SOURCE_IDS+=("$id")
        fi
        if [[ "$kind" != maintenance || "$maintenance_policy" == include ]]; then NOTE_CHANGELOG_IDS+=("DRAFT-$note_id"); fi
    done
    NOTE_PUBLIC_IDS_CSV="$(array_csv_or_none "${NOTE_PUBLIC_IDS[@]}")"
    NOTE_PUBLIC_SOURCE_IDS_CSV="$(array_csv_or_none "${NOTE_PUBLIC_SOURCE_IDS[@]}")"
    NOTE_MAINTENANCE_IDS_CSV="$(array_csv_or_none "${NOTE_MAINTENANCE_IDS[@]}")"
    NOTE_CHANGELOG_IDS_CSV="$(array_csv_or_none "${NOTE_CHANGELOG_IDS[@]}")"
    NOTE_PUBLIC_COUNT="${#NOTE_PUBLIC_IDS[@]}"
    NOTE_MAINTENANCE_COUNT="${#NOTE_MAINTENANCE_IDS[@]}"
    NOTE_CHANGELOG_COUNT="${#NOTE_CHANGELOG_IDS[@]}"
    NOTE_CHANGELOG_STATE='Draft-unpublished'
    NOTE_PUBLICATION_DECISION='Pending-human-decision'
}

property_eight() {
    local iteration case_id history snapshot expected
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-08 "$iteration"
        for case_id in ${CASE_IDS[property-08]}; do
            history="$(case_field property-08 "$case_id" history.ordered)"
            normalize_history property-08 "$case_id" "$history"
            snapshot="$NORMALIZED_SERIALIZED"
            derive_candidate_from_effective "$snapshot"
            derive_notes_from_effective "$snapshot" omit
            [[ "$CANDIDATE_INPUT_SNAPSHOT" == "$snapshot" && "$NOTE_INPUT_SNAPSHOT" == "$snapshot" ]] || fail_property history-normalization-effective-set "$iteration" "$case_id consumers rebuilt the normalized set"
            expected="$(case_field property-08 "$case_id" expected.effective)"; [[ "$NORMALIZED_IDS_CSV" == "$expected" ]] || fail_property history-normalization-effective-set "$iteration" "$case_id effective IDs expected $expected got $NORMALIZED_IDS_CSV"
            expected="$(case_field property-08 "$case_id" expected.candidateSources)"; [[ "$CANDIDATE_SOURCES_CSV" == "$expected" ]] || fail_property history-normalization-effective-set "$iteration" "$case_id candidate sources mismatch"
            expected="$(case_field property-08 "$case_id" expected.noteSources)"; [[ "$NOTE_PUBLIC_SOURCE_IDS_CSV" == "$expected" ]] || fail_property history-normalization-effective-set "$iteration" "$case_id note sources mismatch"
            [[ "$MERGE_COUNT" == "$(case_field property-08 "$case_id" expected.mergeCount)" && "$SQUASH_COUNT" == "$(case_field property-08 "$case_id" expected.squashCount)" ]] || fail_property history-normalization-effective-set "$iteration" "$case_id shape counters mismatch"
            [[ "$DUPLICATE_REPRESENTATIVES_CSV" == "$(case_field property-08 "$case_id" expected.duplicateRepresentatives)" && "$FULL_REVERT_REMOVED_CSV" == "$(case_field property-08 "$case_id" expected.fullRevertRemoved)" && "$PARTIAL_REVERT_SOURCES_CSV" == "$(case_field property-08 "$case_id" expected.partialRevertSources)" ]] || fail_property history-normalization-effective-set "$iteration" "$case_id normalization decisions mismatch"
            [[ "$(case_field property-08 "$case_id" expected.result)" == PASS ]] || fail_property history-normalization-effective-set "$iteration" "$case_id fixture expected failure"
        done
    done
    echo "PROPERTY|history-normalization-effective-set|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

evaluate_empty_range() {
    local impact_list="$1" decision="$2" rationale="$3" trigger="$4" qa="$5" consistency="$6" impact
    EMPTY_STATUS=BLOCKED
    EMPTY_CANDIDATE_IMPACT=none
    EMPTY_RESULT=FAIL
    IFS=',' read -r -a empty_impacts <<< "$impact_list"
    for impact in "${empty_impacts[@]}"; do
        if [[ "$impact" != none ]]; then EMPTY_STATUS=NOT_EMPTY; EMPTY_CANDIDATE_IMPACT="$impact"; EMPTY_RESULT=PASS; return; fi
    done
    case "${decision,,}" in
        defer)
            if [[ "$rationale" != NONE && "$trigger" != NONE ]]; then EMPTY_STATUS=DEFERRED; EMPTY_RESULT=PASS; fi
            ;;
        approve-no-contract-change)
            if [[ "$rationale" != NONE && "$qa" == PASS && "$consistency" == PASS ]]; then EMPTY_STATUS=APPROVED; EMPTY_RESULT=PASS; fi
            ;;
    esac
}

property_nine() {
    local iteration case_id effective derived_impacts declared_impacts decision rationale trigger qa consistency expected
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-09 "$iteration"
        for case_id in ${CASE_IDS[property-09]}; do
            effective="$(case_field property-09 "$case_id" effective)"
            derived_impacts="$(effective_impacts property-09 "$case_id" "$effective")" || fail_property empty-impactful-range-decision "$iteration" "$case_id effective item has no impact projection"
            declared_impacts="$(case_field property-09 "$case_id" impacts)"
            expected_projection="$(case_field property-09 "$case_id" expected.projection)"; if [[ "$expected_projection" == NONE ]]; then expected_projection=PASS; fi
            actual_projection=FAIL; [[ "$derived_impacts" == "$declared_impacts" ]] && actual_projection=PASS
            [[ "$actual_projection" == "$expected_projection" ]] || fail_property empty-impactful-range-decision "$iteration" "$case_id effective impact projection mismatch"
            if [[ "$actual_projection" == FAIL ]]; then continue; fi
            decision="$(case_field property-09 "$case_id" decision)"; rationale="$(case_field property-09 "$case_id" decisionRationale)"; trigger="$(case_field property-09 "$case_id" nextTrigger)"; qa="$(case_field property-09 "$case_id" qaResult)"; consistency="$(case_field property-09 "$case_id" consistencyResult)"
            evaluate_empty_range "$derived_impacts" "$decision" "$rationale" "$trigger" "$qa" "$consistency"
            [[ "$EMPTY_STATUS" == "$(case_field property-09 "$case_id" expected.status)" && "$EMPTY_CANDIDATE_IMPACT" == "$(case_field property-09 "$case_id" expected.candidateImpact)" && "$EMPTY_RESULT" == "$(case_field property-09 "$case_id" expected.result)" ]] || fail_property empty-impactful-range-decision "$iteration" "$case_id decision mismatch"
        done
    done
    echo "PROPERTY|empty-impactful-range-decision|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

property_ten() {
    local iteration case_id effective policy snapshot expected
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-10 "$iteration"
        for case_id in ${CASE_IDS[property-10]}; do
            effective="$(case_field property-10 "$case_id" effective)"; policy="$(case_field property-10 "$case_id" maintenancePolicy)"; build_notes_input property-10 "$case_id" "$effective"; snapshot="$NOTES_INPUT_SERIALIZED"; derive_notes_from_effective "$snapshot" "$policy"
            [[ "$NOTE_INPUT_SNAPSHOT" == "$snapshot" ]] || fail_property exact-once-unpublished-notes "$iteration" "$case_id note derivation rebuilt its input"
            expected="$(case_field property-10 "$case_id" expected.publicNoteIds)"; [[ "$NOTE_PUBLIC_IDS_CSV" == "$expected" ]] || fail_property exact-once-unpublished-notes "$iteration" "$case_id public note IDs mismatch"
            [[ "$NOTE_MAINTENANCE_IDS_CSV" == "$(case_field property-10 "$case_id" expected.maintenanceNoteIds)" && "$NOTE_CHANGELOG_IDS_CSV" == "$(case_field property-10 "$case_id" expected.changelogIds)" ]] || fail_property exact-once-unpublished-notes "$iteration" "$case_id maintenance/changelog IDs mismatch"
            [[ "$NOTE_PUBLIC_COUNT" == "$(case_field property-10 "$case_id" expected.publicCount)" && "$NOTE_MAINTENANCE_COUNT" == "$(case_field property-10 "$case_id" expected.maintenanceCount)" && "$NOTE_CHANGELOG_COUNT" == "$(case_field property-10 "$case_id" expected.changelogCount)" ]] || fail_property exact-once-unpublished-notes "$iteration" "$case_id note counts mismatch"
            [[ "$NOTE_CHANGELOG_STATE" == "$(case_field property-10 "$case_id" expected.changelogState)" && "$NOTE_PUBLICATION_DECISION" == "$(case_field property-10 "$case_id" expected.publicationDecision)" ]] || fail_property exact-once-unpublished-notes "$iteration" "$case_id publication boundary mismatch"
            [[ "$NOTES_RESULT" == "$(case_field property-10 "$case_id" expected.result)" ]] || fail_property exact-once-unpublished-notes "$iteration" "$case_id expected $(case_field property-10 "$case_id" expected.result) got $NOTES_RESULT"
        done
    done
    echo "PROPERTY|exact-once-unpublished-notes|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

evaluate_qa_gate() {
    local classification="$1" note_coverage="$2" blocker="$3" initial_decision="$4" correction="$5" rereview="$6" final_blocker="$7" final_decision="$8"
    QA_INITIAL_STATUS=PASS; QA_FINAL_STATUS=PASS; QA_APPROVAL_ALLOWED=0; QA_RESULT=PASS
    if [[ "$classification" != PASS || "$note_coverage" != PASS ]]; then
        QA_INITIAL_STATUS=BLOCKED
        if [[ "$blocker" == NONE || "${initial_decision,,}" == approved ]]; then QA_RESULT=FAIL; fi
        if [[ "$correction" == NONE || "$rereview" != PASS || ("$final_blocker" != NONE && "$final_blocker" != RESOLVED) || "${final_decision,,}" != approved ]]; then QA_FINAL_STATUS=BLOCKED; else QA_APPROVAL_ALLOWED=1; fi
    else
        if [[ "$blocker" != NONE || "${initial_decision,,}" != approved ]]; then QA_RESULT=FAIL; fi
        if [[ "$rereview" != PASS || ("$final_blocker" != NONE && "$final_blocker" != RESOLVED) || "${final_decision,,}" != approved ]]; then QA_FINAL_STATUS=BLOCKED; else QA_APPROVAL_ALLOWED=1; fi
    fi
}

property_eleven() {
    local iteration case_id classification note blocker initial correction rereview final_blocker final_decision
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-11 "$iteration"
        for case_id in ${CASE_IDS[property-11]}; do
            classification="$(case_field property-11 "$case_id" initialClassificationResult)"; note="$(case_field property-11 "$case_id" initialNoteCoverageResult)"; blocker="$(case_field property-11 "$case_id" initialBlocker)"; initial="$(case_field property-11 "$case_id" initialDecision)"; correction="$(case_field property-11 "$case_id" correction)"; rereview="$(case_field property-11 "$case_id" reReviewResult)"; final_blocker="$(case_field property-11 "$case_id" finalBlockerStatus)"; final_decision="$(case_field property-11 "$case_id" finalDecision)"
            evaluate_qa_gate "$classification" "$note" "$blocker" "$initial" "$correction" "$rereview" "$final_blocker" "$final_decision"
            [[ "$QA_INITIAL_STATUS" == "$(case_field property-11 "$case_id" expected.initialStatus)" && "$QA_FINAL_STATUS" == "$(case_field property-11 "$case_id" expected.finalStatus)" && "$QA_APPROVAL_ALLOWED" == "$(case_field property-11 "$case_id" expected.approvalAllowed)" && "$QA_RESULT" == "$(case_field property-11 "$case_id" expected.result)" ]] || fail_property qa-blocks-until-rereview "$iteration" "$case_id QA gate mismatch"
        done
    done
    echo "PROPERTY|qa-blocks-until-rereview|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

record_action_request() {
    CONSISTENCY_REQUESTED_ACTION="$1"
    # External requests are recorded as data only; this boundary never invokes an action.
    CONSISTENCY_ACTION_LOG=NONE
}

validate_consistency() {
    local property="$1" case_id="$2" eval_id candidate_eval qa_eval notes_eval approval_eval consistency_eval candidate commit range occurrences at_end version tag prior candidate_version rationale qa notes action_request item last_index
    local actual_occurrences=0 actual_at_end=0 approved_major approved_minor approved_patch prior_major prior_minor prior_patch
    local -a range_items=()
    CONSISTENCY_RESULT=PASS; CONSISTENCY_DIAGNOSTIC=NONE; CONSISTENCY_ACTION_LOG=NONE; CONSISTENCY_SHARED_EVALUATION_ID=; CONSISTENCY_NON_REGRESSING=0; CONSISTENCY_CANDIDATE_AT_RANGE_END=0
    eval_id="$(case_field "$property" "$case_id" artifact.evaluation.evaluationId)"; action_request="$(case_field "$property" "$case_id" artifact.actionRequest)"; record_action_request "$action_request"
    CONSISTENCY_SHARED_EVALUATION_ID="$eval_id"
    if [[ -z "$eval_id" || "$eval_id" == NONE ]]; then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=EVALUATION_ID_MISMATCH; return; fi
    candidate_eval="$(case_field "$property" "$case_id" artifact.candidate.evaluationId)"; qa_eval="$(case_field "$property" "$case_id" artifact.qa.evaluationId)"; notes_eval="$(case_field "$property" "$case_id" artifact.notes.evaluationId)"; approval_eval="$(case_field "$property" "$case_id" artifact.approval.evaluationId)"; consistency_eval="$(case_field "$property" "$case_id" artifact.consistency.evaluationId)"
    for item in "$candidate_eval" "$qa_eval" "$notes_eval" "$approval_eval" "$consistency_eval"; do if [[ -z "$item" || "$item" == NONE || "$item" != "$eval_id" ]]; then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=EVALUATION_ID_MISMATCH; return; fi; done
    candidate="$(case_field "$property" "$case_id" candidateCommit)"; commit="$(case_field "$property" "$case_id" approvedCandidateCommit)"; range="$(case_field "$property" "$case_id" orderedRange)"; occurrences="$(case_field "$property" "$case_id" candidateOccurrences)"; at_end="$(case_field "$property" "$case_id" candidateAtEnd)"
    IFS=',' read -r -a range_items <<< "$range"
    for item in "${range_items[@]}"; do [[ "$item" == "$candidate" ]] && actual_occurrences=$((actual_occurrences + 1)); done
    if [[ "${#range_items[@]}" -gt 0 ]]; then last_index=$(( ${#range_items[@]} - 1 )); [[ "$range" != NONE && "${range_items[$last_index]}" == "$candidate" ]] && actual_at_end=1; fi
    CONSISTENCY_CANDIDATE_AT_RANGE_END="$actual_at_end"
    if [[ "$candidate" == NONE || "$commit" != "$candidate" || "$actual_occurrences" -ne 1 || "$actual_at_end" -ne 1 || "$occurrences" != "$actual_occurrences" || "$at_end" != "$actual_at_end" ]]; then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=RANGE_MEMBERSHIP; return; fi
    version="$(case_field "$property" "$case_id" approvedVersion)"; tag="$(case_field "$property" "$case_id" approvedTag)"; prior="$(case_field "$property" "$case_id" priorVersion)"; candidate_version="$(case_field "$property" "$case_id" candidateVersion)"; rationale="$(case_field "$property" "$case_id" approvalRationale)"; qa="$(case_field "$property" "$case_id" qaResult)"; notes="$(case_field "$property" "$case_id" noteCoverage)"
    if [[ "$tag" != "v$version" && "$tag" != "$version" ]]; then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=TAG_VERSION_MISMATCH; return; fi
    parse_core_semver "$version" || { CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=INVALID_VERSION; return; }; approved_major="$SEMVER_MAJOR"; approved_minor="$SEMVER_MINOR"; approved_patch="$SEMVER_PATCH"
    parse_core_semver "$prior" || { CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=INVALID_VERSION; return; }; prior_major="$SEMVER_MAJOR"; prior_minor="$SEMVER_MINOR"; prior_patch="$SEMVER_PATCH"
    parse_core_semver "$candidate_version" || { CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=INVALID_VERSION; return; }
    if (( approved_major < prior_major || (approved_major == prior_major && approved_minor < prior_minor) || (approved_major == prior_major && approved_minor == prior_minor && approved_patch < prior_patch) )); then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=VERSION_PRECEDENCE; return; fi
    CONSISTENCY_NON_REGRESSING=1
    if [[ "$candidate_version" != "$version" && "$rationale" == NONE ]]; then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=APPROVAL_REQUIRED; return; fi
    if [[ "$qa" != PASS || "$notes" != PASS ]]; then CONSISTENCY_RESULT=FAIL; CONSISTENCY_DIAGNOSTIC=QA_NOTE_LINKAGE; return; fi
}

property_twelve() {
    local iteration case_id expected_consistency expected_diag expected_case_result
    for ((iteration = 1; iteration <= ITERATIONS; iteration++)); do
        assert_shape_generation property-12 "$iteration"
        for case_id in ${CASE_IDS[property-12]}; do
            validate_consistency property-12 "$case_id"
            expected_consistency="$(case_field property-12 "$case_id" expected.consistency)"; expected_diag="$(case_field property-12 "$case_id" expected.diagnosticCategory)"; expected_case_result="$(case_field property-12 "$case_id" expected.result)"; expected_non_regressing="$(case_field property-12 "$case_id" expected.nonRegressing)"; expected_shared_id="$(case_field property-12 "$case_id" expected.sharedEvaluationId)"; expected_at_end="$(case_field property-12 "$case_id" expected.candidateAtRangeEnd)"; expected_action_request="$(case_field property-12 "$case_id" artifact.actionRequest)"
            [[ "$CONSISTENCY_RESULT" == "$expected_consistency" && "$CONSISTENCY_DIAGNOSTIC" == "$expected_diag" && "$CONSISTENCY_ACTION_LOG" == "$(case_field property-12 "$case_id" expected.actionLog)" && "$CONSISTENCY_NON_REGRESSING" == "$expected_non_regressing" && "$CONSISTENCY_SHARED_EVALUATION_ID" == "$expected_shared_id" && "$CONSISTENCY_CANDIDATE_AT_RANGE_END" == "$expected_at_end" && "$CONSISTENCY_REQUESTED_ACTION" == "$expected_action_request" && "$expected_case_result" == PASS ]] || fail_property cross-record-read-only-consistency "$iteration" "$case_id consistency mismatch"
        done
    done
    echo "PROPERTY|cross-record-read-only-consistency|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

for fixture_property in property-01 property-02 property-03 property-04 property-05 property-06 property-07 property-08 property-09 property-10 property-11 property-12; do
    load_fixture "$fixture_property"
done

property_one
property_two
property_three
property_four
property_five
property_six
property_seven
property_eight
property_nine
property_ten
property_eleven
property_twelve

echo "Release-record Bash property harness passed: properties=12 iterations_per_property=$ITERATIONS seed=$SEED read_only=PASS."
echo "Release-record property evidence is local and synthetic; it cannot authorize tags, releases, publication, remotes, deployment, or rollback actions."
