#!/usr/bin/env bash
# Read-only PromptKit OS release-record consistency validator.
# Usage: ./scripts/validate-release-records.sh [--root PATH] [--strict]

set -u

ROOT="."
STRICT=0
ERROR_COUNT=0
RECORD_COUNT=0

declare -a DIAGNOSTICS=()
declare -a RECORD_PATH=()
declare -a RECORD_RELATIVE=()
declare -a RECORD_ID=()
declare -a RECORD_TYPE=()
declare -a RECORD_CANONICAL=()
declare -a RECORD_LABELS=()
declare -A FIELDS=()
declare -A DUPLICATES=()

declare -a EVALUATION_INDICES=()
declare -A SEEN_DIAGNOSTICS=()

diagnostic() {
    local category="$1" record_id="$2" path="$3" message="$4" remediation="$5" entry
    message="${message//$'\r'/ }"
    message="${message//$'\n'/ }"
    message="${message//|/ }"
    remediation="${remediation//$'\r'/ }"
    remediation="${remediation//$'\n'/ }"
    remediation="${remediation//|/ }"
    entry="${category}|${record_id}|${path}|${message}|${remediation}"
    # A finding is identified by its complete tuple. require_labels and
    # require_value both assert the presence of the same label, so an absent
    # field was previously reported twice and the summary error count was
    # inflated. Distinct findings still differ in at least one tuple element.
    [ -n "${SEEN_DIAGNOSTICS[$entry]+present}" ] && return 0
    SEEN_DIAGNOSTICS["$entry"]=1
    DIAGNOSTICS+=("$entry")
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

usage() {
    cat <<'EOF'
Usage: validate-release-records.sh [--root PATH] [--strict]

Validate local Better-PromptKit release-evaluation Markdown records without
modifying records, files, repository state, or external release systems.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)
            if [ "$#" -lt 2 ]; then
                echo "USAGE|ROOT|--root requires a path"
                exit 2
            fi
            ROOT="$2"
            shift 2
            ;;
        --root=*)
            ROOT="${1#*=}"
            shift
            ;;
        --strict)
            STRICT=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "USAGE|ROOT|Unknown argument: $1"
            usage
            exit 2
            ;;
    esac
done

if [ ! -d "$ROOT" ]; then
    echo "INPUT_ERROR|REPOSITORY|.|Repository root does not exist|Provide a valid --root path"
    exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"
RELEASE_DIR="$ROOT/docs/releases"

trim() {
    local value="$1"
    value="${value#${value%%[![:space:]]*}}"
    value="${value%${value##*[![:space:]]}}"
    printf '%s' "$value"
}

unwrap() {
    local value
    value="$(trim "$1")"
    if [ "${#value}" -ge 2 ] && [ "${value:0:1}" = $'\x60' ] && [ "${value: -1}" = $'\x60' ]; then
        value="${value:1:${#value}-2}"
    fi
    trim "$value"
}

relative_path() {
    local file="$1"
    local relative="${file#"$ROOT"/}"
    printf '%s' "${relative//\\//}"
}

is_placeholder() {
    local value
    value="$(unwrap "$1")"
    [ -z "$value" ] && return 0
    case "$value" in
        N/A|n/a|None|none|Not\ applicable|not\ applicable|Pending|pending|Not\ approved|not\ approved) return 0 ;;
    esac
    [[ "$value" == \[*\] ]] && return 0
    return 1
}

is_usable() {
    if is_placeholder "$1"; then return 1; fi
    return 0
}

field_key() {
    printf '%s|%s' "$1" "$2"
}

field_exists() {
    local key
    key="$(field_key "$1" "$2")"
    [ -n "${FIELDS[$key]+present}" ]
}

field_value() {
    local key value
    key="$(field_key "$1" "$2")"
    value="${FIELDS[$key]-}"
    unwrap "$value"
}

parse_file() {
    local index="$1" file="$2" line label value key
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^-\ \*\*([^*]+)\*\*:[[:space:]]*(.*)$ ]]; then
            label="$(trim "${BASH_REMATCH[1]}")"
            value="$(trim "${BASH_REMATCH[2]}")"
            key="$(field_key "$index" "$label")"
            if [ -n "${FIELDS[$key]+present}" ]; then
                if [ -n "${DUPLICATES[$key]+present}" ]; then
                    DUPLICATES[$key]=$((DUPLICATES[$key] + 1))
                else
                    DUPLICATES[$key]=2
                fi
            else
                FIELDS[$key]="$value"
                RECORD_LABELS[$index]+="${label}"$'\t'
            fi
        fi
    done < "$file"
}

canonical_type() {
    local type
    type="${1,,}"
    case "$type" in
        "release evaluation") printf 'Release Evaluation' ;;
        "semver candidate record") printf 'SemVer Candidate Record' ;;
        "qa review record"|"qa/reviewer review record") printf 'QA Review Record' ;;
        "approved release record") printf 'Approved Release Record' ;;
        "release notes record") printf 'Release Notes Record' ;;
        *) printf '' ;;
    esac
}

add_record() {
    local index="$1" file="$2" type id canonical label
    parse_file "$index" "$file"
    type="$(field_value "$index" 'Record Type')"
    id="$(field_value "$index" 'Evaluation ID')"
    is_placeholder "$id" && id="UNKNOWN"

    if [ -z "$type" ]; then
        if [ "$STRICT" -eq 1 ]; then
            diagnostic "INVALID_STATE" "UNKNOWN" "$(relative_path "$file")" "Missing Record Type" "Use a supported canonical release-record type"
        fi
        return 0
    fi
    canonical="$(canonical_type "$type")"
    if [ -z "$canonical" ]; then
        if [ "$STRICT" -eq 1 ]; then
            diagnostic "INVALID_STATE" "$id" "$(relative_path "$file")" "Unknown Record Type: $type" "Use Release Evaluation, SemVer Candidate Record, QA Review Record, Release Notes Record, or Approved Release Record"
        fi
        return 0
    fi

    RECORD_PATH[$index]="$file"
    RECORD_RELATIVE[$index]="$(relative_path "$file")"
    RECORD_ID[$index]="$id"
    RECORD_TYPE[$index]="$type"
    RECORD_CANONICAL[$index]="$canonical"
    RECORD_COUNT=$((RECORD_COUNT + 1))
}

require_label() {
    local index="$1" label="$2" category="${3:-MISSING_FIELD}"
    if ! field_exists "$index" "$label"; then
        diagnostic "$category" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Missing field: $label" "Add the labeled field to the canonical record"
        return 1
    fi
    return 0
}

require_value() {
    local index="$1" label="$2" category="${3:-MISSING_FIELD}" remediation="${4:-Provide a non-placeholder value for the labeled field}" value
    require_label "$index" "$label" "$category" || return 1
    value="$(field_value "$index" "$label")"
    if ! is_usable "$value"; then
        diagnostic "$category" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Missing usable value: $label" "$remediation"
        return 1
    fi
    return 0
}

require_labels() {
    local index="$1" label
    shift
    for label in "$@"; do require_label "$index" "$label" >/dev/null; done
}

first_field_value() {
    local index="$1" label
    shift
    for label in "$@"; do
        if field_exists "$index" "$label"; then
            field_value "$index" "$label"
            return 0
        fi
    done
    printf ''
}

split_refs() {
    local value token
    value="$(unwrap "$1")"
    value="${value//[/ }"
    value="${value//]/ }"
    value="${value//(/ }"
    value="${value//)/ }"
    value="${value//\// }"
    value="${value//,/ }"
    read -r -a _refs <<< "$value"
    for token in "${_refs[@]}"; do
        token="$(unwrap "$token")"
        [ -n "$token" ] && printf '%s\n' "$token"
    done
}

parse_semver() {
    local value
    value="$(unwrap "$1")"
    value="${value#v}"
    if [[ "$value" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$ ]]; then
        SEMVER_TEXT="$value"
        SEMVER_MAJOR="${BASH_REMATCH[1]}"
        SEMVER_MINOR="${BASH_REMATCH[2]}"
        SEMVER_PATCH="${BASH_REMATCH[3]}"
        return 0
    fi
    return 1
}

compare_semver_core() {
    if [ "$1" -gt "$4" ]; then printf '1'; return; fi
    if [ "$1" -lt "$4" ]; then printf '%s' '-1'; return; fi
    if [ "$2" -gt "$5" ]; then printf '1'; return; fi
    if [ "$2" -lt "$5" ]; then printf '%s' '-1'; return; fi
    if [ "$3" -gt "$6" ]; then printf '1'; return; fi
    if [ "$3" -lt "$6" ]; then printf '%s' '-1'; return; fi
    printf '0'
}

test_pass() {
    local value
    value="$(unwrap "$1")"
    [ "${value,,}" = "pass" ]
}

validate_base() {
    local index="$1" key label
    IFS=$'\t' read -r -a _labels <<< "${RECORD_LABELS[$index]-}"
    for label in "${_labels[@]}"; do
        [ -z "$label" ] && continue
        key="$(field_key "$index" "$label")"
        if [ -n "${DUPLICATES[$key]+present}" ]; then
            diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Duplicate field: $label" "Keep one canonical field label per record"
        fi
    done
    require_label "$index" 'Record Type' >/dev/null
    require_value "$index" 'Evaluation ID' 'INVALID_ID' 'Provide one stable Evaluation ID shared by linked records' >/dev/null
}

validate_evaluation() {
    local index="$1" label scope status first membership empty prior_commit decision first_true guidance
    require_labels "$index" \
        'Repository Scope' 'Evaluation Owner / Role' 'QA/Reviewer' 'Release Coordinator' \
        'Created' 'Evaluation Status' 'Consumer Repository Applicability' 'Evaluation Objective' \
        'Latest Approved Release Record' 'Version Source of Truth' 'Prior Approved Release Version' \
        'Prior Approved Release Commit' 'First Release' 'Release Range Start' 'Release Range End' \
        'Release Candidate Commit' 'Candidate-Inclusive Membership Result' 'Range Selection Rationale' \
        'Ordered Range Commit References' 'Effective Change Set Summary' 'Empty Eligible Range' \
        'Empty-Range Decision' 'Normalization Blockers'

    for label in 'Repository Scope' 'Evaluation Owner / Role' 'QA/Reviewer' 'Created' 'Evaluation Status' 'Evaluation Objective' 'Release Range Start' 'Release Range End' 'Release Candidate Commit' 'Candidate-Inclusive Membership Result' 'Range Selection Rationale' 'Ordered Range Commit References' 'Effective Change Set Summary' 'Empty Eligible Range'; do
        require_value "$index" "$label" >/dev/null
    done

    scope="$(field_value "$index" 'Repository Scope')"
    if [ "$scope" != 'Better-PromptKit only' ] && [ "$scope" != 'PromptKit OS only' ]; then
        diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Repository Scope must be PromptKit OS only (or Better-PromptKit only for legacy records): $scope" "Limit release-record validation to PromptKit OS records"
    fi

    status="$(field_value "$index" 'Evaluation Status')"
    status="${status,,}"
    case "$status" in preliminary|blocked|deferred|approved) ;; *) diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported Evaluation Status: $status" "Use preliminary, blocked, deferred, or approved" ;; esac

    first="$(field_value "$index" 'First Release')"
    first="${first,,}"
    case "$first" in yes|no|true|false) ;; *) diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported First Release value: $first" "Use Yes or No" ;; esac

    membership="$(field_value "$index" 'Candidate-Inclusive Membership Result')"
    membership="${membership,,}"
    case "$membership" in pass|fail|pending) ;; *) diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported candidate membership result: $membership" "Use Pass, Fail, or Pending" ;; esac

    empty="$(field_value "$index" 'Empty Eligible Range')"
    empty="${empty,,}"
    case "$empty" in yes|no|true|false) ;; *) diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported Empty Eligible Range value: $empty" "Use Yes or No" ;; esac

    prior_commit="$(field_value "$index" 'Prior Approved Release Commit')"
    first_true=0
    [[ "$first" = yes || "$first" = true ]] && first_true=1
    if [ "$first_true" -eq 0 ] && ! is_usable "$prior_commit"; then
        diagnostic "MISSING_FIELD" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Prior Approved Release Commit is required when First Release is No' 'Record the latest approved exclusive baseline commit'
    fi

    if [[ "$empty" = yes || "$empty" = true ]]; then
        decision="$(field_value "$index" 'Empty-Range Decision')"
        decision="${decision,,}"
        if is_placeholder "$decision" || { [[ "$decision" != *defer* ]] && [[ "$decision" != *no-contract-change* ]]; }; then
            diagnostic "EMPTY_RANGE_DECISION" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Empty Eligible Range requires an explicit defer or no-contract-change decision' 'Record Defer or a documented no-contract-change release approval'
        fi
    fi

    guidance="$(first_field_value "$index" 'Migration and Upgrade Guidance' 'Migration / Upgrade Guidance')"
    for key in "${!FIELDS[@]}"; do
        if [[ "$key" == "$index|"* ]] && [[ "${FIELDS[$key]}" =~ [Bb]reaking ]] && ! is_usable "$guidance"; then
            diagnostic "BREAKING_GUIDANCE_MISSING" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Breaking impact has no Migration and Upgrade Guidance' 'Add affected consumers, required actions, and a supported transition path'
            break
        fi
    done
}

validate_candidate() {
    local index="$1" label status impact candidate_version guidance key
    require_labels "$index" \
        'Candidate Status' 'Candidate Core Version' 'Prerelease Identifier' 'Display Candidate Version' \
        'Greatest Effective Impact' 'Impact Precedence Rationale' 'Supporting Eligible Commits' \
        'Candidate Provenance' 'First Release Candidate Rule' 'Prerelease / Promotion Record' 'Candidate Blockers'
    require_value "$index" 'Candidate Status' 'CANDIDATE_PROVENANCE' >/dev/null
    require_value "$index" 'Greatest Effective Impact' 'INVALID_STATE' >/dev/null
    require_value "$index" 'Impact Precedence Rationale' >/dev/null
    require_value "$index" 'Supporting Eligible Commits' 'CANDIDATE_PROVENANCE' >/dev/null
    require_value "$index" 'Candidate Provenance' 'CANDIDATE_PROVENANCE' >/dev/null

    status="$(field_value "$index" 'Candidate Status')"
    if [ "${status,,}" != preliminary ]; then
        diagnostic "CANDIDATE_PROVENANCE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Candidate Status must be preliminary: $status" "Keep candidate status preliminary until a separate approval record exists"
    fi

    impact="$(field_value "$index" 'Greatest Effective Impact')"
    impact="${impact,,}"
    case "$impact" in major|minor|patch|none|blocked) ;; *) diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported Greatest Effective Impact: $impact" "Use major, minor, patch, none, or blocked" ;; esac

    candidate_version="$(field_value "$index" 'Candidate Core Version')"
    if [[ "$impact" != none && "$impact" != blocked ]] && ! parse_semver "$candidate_version"; then
        diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Candidate Core Version is not valid SemVer' 'Record a major.minor.patch candidate or use N/A while blocked'
    fi

    guidance="$(first_field_value "$index" 'Migration and Upgrade Guidance' 'Migration / Upgrade Guidance')"
    for key in "${!FIELDS[@]}"; do
        if [[ "$key" == "$index|"* ]] && [[ "${FIELDS[$key]}" =~ [Bb]reaking ]] && ! is_usable "$guidance"; then
            diagnostic "BREAKING_GUIDANCE_MISSING" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Breaking impact has no Migration and Upgrade Guidance' 'Add migration and upgrade guidance before approval'
            break
        fi
    done
}

validate_qa() {
    local index="$1" label value decision
    require_labels "$index" \
        'Range Boundary Result' 'Candidate Membership Result' 'Eligibility and Maintenance Classification Result' \
        'Complex-History Normalization Result' 'SemVer Precedence Result' 'Breaking-Guidance Result' \
        'Every Release Note Has Supporting Contract Impact Evidence' \
        'Every Effective User-Observable Contract Change Has Exactly One Public Release Note' \
        'QA/Reviewer Findings' 'Named Release Blockers' 'QA Review Decision' \
        'Coordinator-Handoff Gate' 'Review Date and Attestation' 'Re-Review Result'
    require_label "$index" 'Breaking-Guidance Result' >/dev/null
    guidance_result="$(field_value "$index" 'Breaking-Guidance Result')"
    case "${guidance_result,,}" in pass|n/a|pending) ;; *) diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported Breaking-Guidance Result: ${guidance_result,,}" 'Use Pass, N/A, or Pending' ;; esac
    for label in 'Range Boundary Result' 'Candidate Membership Result' 'Eligibility and Maintenance Classification Result' 'Complex-History Normalization Result' 'SemVer Precedence Result' 'Every Release Note Has Supporting Contract Impact Evidence' 'Every Effective User-Observable Contract Change Has Exactly One Public Release Note' 'QA Review Decision' 'Review Date and Attestation'; do
        require_value "$index" "$label" >/dev/null
    done
    for label in 'Range Boundary Result' 'Candidate Membership Result' 'Eligibility and Maintenance Classification Result' 'Complex-History Normalization Result' 'SemVer Precedence Result'; do
        value="$(field_value "$index" "$label")"
        if ! test_pass "$value"; then
            diagnostic "APPROVAL_REQUIRED" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "QA result is not Pass: $label=$value" 'Correct the QA finding and record a re-review before approval'
        fi
    done
    for label in 'Every Release Note Has Supporting Contract Impact Evidence' 'Every Effective User-Observable Contract Change Has Exactly One Public Release Note'; do
        if ! test_pass "$(field_value "$index" "$label")"; then
            diagnostic "QA_NOTE_LINKAGE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "QA note-coverage attestation is not Pass: $label" 'Link every note to evidence and every effective public change to exactly one note'
        fi
    done
    decision="$(field_value "$index" 'QA Review Decision')"
    decision="${decision,,}"
    if [[ "$decision" != *accepted* && "$decision" != *deferred* && "$decision" != *blocked* ]]; then
        diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Unsupported QA Review Decision: $decision" 'Record Accepted for coordinator decision, Blocked pending correction, or Deferred'
    fi
}

validate_notes() {
    local index="$1" changelog
    require_labels "$index" 'Public Release Notes' 'Maintenance Release Notes' 'Changelog State' 'Derived Entries' 'Note-to-Changelog Coverage' 'Publication Decision'
    require_value "$index" 'Changelog State' >/dev/null
    require_value "$index" 'Derived Entries' >/dev/null
    require_value "$index" 'Note-to-Changelog Coverage' >/dev/null
    require_value "$index" 'Publication Decision' >/dev/null
    changelog="$(field_value "$index" 'Changelog State')"
    changelog="${changelog,,}"
    if [[ "$changelog" != *draft* || "$changelog" != *unpublish* ]]; then
        diagnostic "QA_NOTE_LINKAGE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Changelog State is not explicitly draft and unpublished' 'Mark every derived changelog entry Draft and unpublished'
    fi
    if ! test_pass "$(field_value "$index" 'Note-to-Changelog Coverage')"; then
        diagnostic "QA_NOTE_LINKAGE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Note-to-Changelog Coverage is not Pass' 'Provide exactly one unpublished draft entry per reviewed release note'
    fi
}

validate_approved() {
    local index="$1" label decision approved_version approved_tag changelog
    require_labels "$index" \
        'Approved Release Record' 'Approved Release Version' 'Approved Release Tag' \
        'Approved Release Candidate Commit' 'Approved Release Range' 'Candidate-versus-Approved Comparison' \
        'Approval Difference Rationale' 'Approval Decision' 'Approval Date' 'Release Coordinator Decision Record' \
        'Public and Maintenance Release Notes' 'Changelog State' 'Note-to-Changelog Coverage' \
        'Shared Evaluation ID Consistency Result' 'Candidate-Inclusive Range Consistency Result' \
        'Tag/Version Alignment Result' 'Version Precedence Result' 'Approval and Rationale Result' \
        'QA/Note Linkage Result' 'Overall Consistency Result' 'Consistency Blockers and Resolution' \
        'Tag Creation Decision' 'Hosted Release Creation Decision' 'Changelog Publication Decision' \
        'Remote Operation Decision' 'Deployment Decision' 'Rollback Decision' 'External-Action Owner and Evidence'

    decision="$(field_value "$index" 'Approval Decision')"
    decision="${decision,,}"
    if [ "$decision" = approved ]; then
        for label in 'Approved Release Version' 'Approved Release Tag' 'Approved Release Candidate Commit' 'Approved Release Range' 'Approval Date' 'Release Coordinator Decision Record' 'Public and Maintenance Release Notes' 'Changelog State' 'Note-to-Changelog Coverage'; do
            require_value "$index" "$label" 'APPROVAL_REQUIRED' 'Record complete coordinator approval evidence before representing the release as approved' >/dev/null
        done
        approved_version="$(field_value "$index" 'Approved Release Version')"
        if ! parse_semver "$approved_version"; then
            diagnostic "INVALID_STATE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Approved Release Version is not valid SemVer' 'Record a major.minor.patch approved version'
        else
            approved_tag="$(field_value "$index" 'Approved Release Tag')"
            normalized_version="${approved_version#v}"
            if [ "$approved_tag" != "v$normalized_version" ] && [ "$approved_tag" != "$normalized_version" ]; then
                diagnostic "TAG_VERSION_MISMATCH" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Approved Release Tag does not encode Approved Release Version' 'Use v<approved-version> or the approved version as the tag string'
            fi
        fi
        changelog="$(field_value "$index" 'Changelog State')"
        changelog="${changelog,,}"
        if [[ "$changelog" != *draft* || "$changelog" != *unpublish* ]]; then
            diagnostic "QA_NOTE_LINKAGE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Approved record changelog state is not Draft and unpublished' 'Keep publication as a separate human decision'
        fi
        if ! test_pass "$(field_value "$index" 'Note-to-Changelog Coverage')"; then
            diagnostic "QA_NOTE_LINKAGE" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" 'Approved record note-to-changelog coverage is not Pass' 'Link reviewed notes to exactly one unpublished draft entry each'
        fi
        for label in 'Shared Evaluation ID Consistency Result' 'Candidate-Inclusive Range Consistency Result' 'Tag/Version Alignment Result' 'Version Precedence Result' 'Approval and Rationale Result' 'QA/Note Linkage Result' 'Overall Consistency Result'; do
            if ! test_pass "$(field_value "$index" "$label")"; then
                diagnostic "APPROVAL_REQUIRED" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Consistency result is not Pass: $label" 'Resolve every release-consistency finding before approval'
            fi
        done
    fi
}

validate_record() {
    local index="$1" type
    validate_base "$index"
    type="${RECORD_CANONICAL[$index]}"
    case "$type" in
        'Release Evaluation') validate_evaluation "$index" ;;
        'SemVer Candidate Record') validate_candidate "$index" ;;
        'QA Review Record') validate_qa "$index" ;;
        'Release Notes Record') validate_notes "$index" ;;
        'Approved Release Record') validate_approved "$index" ;;
    esac
}

validate_cross_records() {
    local evaluation_id evaluation_index candidate_index candidate_count qa_index qa_count approved_index approved_count notes_index notes_count
    local range_candidate range_end prior_version ordered_count occurrences last_ref membership candidate_commit provenance approved_candidate approved_range_count approved_range_last approved_version approved_tag normalized_version comparison candidate_version candidate_text prior_compare
    declare -A EVALUATION_ID_SEEN=()

    for evaluation_index in "${EVALUATION_INDICES[@]}"; do
        evaluation_id="${RECORD_ID[$evaluation_index]}"
        [ "$evaluation_id" = UNKNOWN ] && continue
        EVALUATION_ID_SEEN[$evaluation_id]=1
    done

    local index
    for index in "${!RECORD_CANONICAL[@]}"; do
        if [ "${RECORD_CANONICAL[$index]}" != 'Release Evaluation' ] && [ "${#EVALUATION_ID_SEEN[@]}" -gt 0 ] && [ -z "${EVALUATION_ID_SEEN[${RECORD_ID[$index]}]+present}" ]; then
            diagnostic "EVALUATION_ID_MISMATCH" "${RECORD_ID[$index]}" "${RECORD_RELATIVE[$index]}" "Evaluation ID does not match a Release Evaluation record: ${RECORD_ID[$index]}" 'Use one shared Evaluation ID across linked evaluation artifacts'
        fi
    done

    for evaluation_index in "${EVALUATION_INDICES[@]}"; do
        evaluation_id="${RECORD_ID[$evaluation_index]}"
        [ "$evaluation_id" = UNKNOWN ] && continue
        range_candidate="$(field_value "$evaluation_index" 'Release Candidate Commit')"
        range_end="$(field_value "$evaluation_index" 'Release Range End')"
        mapfile -t _ordered < <(split_refs "$(field_value "$evaluation_index" 'Ordered Range Commit References')")
        ordered_count="${#_ordered[@]}"
        occurrences=0
        last_ref=""
        [ "$ordered_count" -gt 0 ] && last_ref="${_ordered[$((ordered_count - 1))]}"
        for ref in "${_ordered[@]}"; do [ "$ref" = "$range_candidate" ] && occurrences=$((occurrences + 1)); done
        if [ "$occurrences" -ne 1 ] || [ "$ordered_count" -eq 0 ] || [ "$last_ref" != "$range_candidate" ] || [ "$range_end" != "$range_candidate" ]; then
            diagnostic "RANGE_MEMBERSHIP" "$evaluation_id" "${RECORD_RELATIVE[$evaluation_index]}" 'Release Candidate Commit must appear exactly once at the inclusive end of the ordered range' 'Record the candidate in Release Range End and as the final ordered reference'
        fi
        membership="$(field_value "$evaluation_index" 'Candidate-Inclusive Membership Result')"
        [ "${membership,,}" = fail ] && diagnostic "RANGE_MEMBERSHIP" "$evaluation_id" "${RECORD_RELATIVE[$evaluation_index]}" 'Candidate-Inclusive Membership Result is Fail' 'Correct the recorded candidate range before approval'

        candidate_index=-1; candidate_count=0; qa_index=-1; qa_count=0; approved_index=-1; approved_count=0; notes_index=-1; notes_count=0
        for index in "${!RECORD_CANONICAL[@]}"; do
            [ "${RECORD_ID[$index]}" != "$evaluation_id" ] && continue
            case "${RECORD_CANONICAL[$index]}" in
                'SemVer Candidate Record') candidate_index="$index"; candidate_count=$((candidate_count + 1)) ;;
                'QA Review Record') qa_index="$index"; qa_count=$((qa_count + 1)) ;;
                'Approved Release Record') approved_index="$index"; approved_count=$((approved_count + 1)) ;;
                'Release Notes Record') notes_index="$index"; notes_count=$((notes_count + 1)) ;;
            esac
        done

        if [ "$candidate_count" -gt 1 ]; then diagnostic "INVALID_ID" "$evaluation_id" "${RECORD_RELATIVE[$candidate_index]}" 'More than one SemVer Candidate Record uses this Evaluation ID' 'Keep one candidate record per evaluation'; fi
        if [ "$candidate_index" -ge 0 ]; then
            candidate_commit="$(field_value "$candidate_index" 'Release Candidate Commit')"
            if field_exists "$candidate_index" 'Release Candidate Commit' && [ "$candidate_commit" != "$range_candidate" ]; then
                diagnostic "CANDIDATE_PROVENANCE" "$evaluation_id" "${RECORD_RELATIVE[$candidate_index]}" 'Candidate record uses a different Release Candidate Commit' 'Preserve the exact evaluated candidate revision'
            fi
            provenance="$(field_value "$candidate_index" 'Candidate Provenance')"
            if [[ "$provenance" != *"$evaluation_id"* || "$provenance" != *"$range_candidate"* ]]; then
                diagnostic "CANDIDATE_PROVENANCE" "$evaluation_id" "${RECORD_RELATIVE[$candidate_index]}" 'Candidate Provenance does not identify the shared evaluation and candidate commit' 'Record Evaluation ID, range, candidate commit, and supporting evidence'
            fi
        fi

        if [ "$approved_count" -gt 1 ]; then diagnostic "INVALID_ID" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'More than one Approved Release Record uses this Evaluation ID' 'Keep one approval record per evaluation'; fi
        if [ "$approved_index" -ge 0 ]; then
            if [ "$(field_value "$approved_index" 'Approval Decision')" = 'Approved' ]; then
                [ "$qa_count" -eq 0 ] && diagnostic "APPROVAL_REQUIRED" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved Release Record has no linked QA Review Record' 'Link a completed QA review under the same Evaluation ID'
                [ "$candidate_count" -eq 0 ] && diagnostic "CANDIDATE_PROVENANCE" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved Release Record has no linked preliminary candidate' 'Link the preliminary candidate and retain its provenance'

                approved_candidate="$(field_value "$approved_index" 'Approved Release Candidate Commit')"
                [ "$approved_candidate" != "$range_candidate" ] && diagnostic "CANDIDATE_PROVENANCE" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved Release Candidate Commit differs from the evaluated candidate' 'Use the same candidate revision across evaluation and approval'

                mapfile -t _approved_range < <(split_refs "$(field_value "$approved_index" 'Approved Release Range')")
                approved_range_count="${#_approved_range[@]}"; approved_range_last=""
                [ "$approved_range_count" -gt 0 ] && approved_range_last="${_approved_range[$((approved_range_count - 1))]}"
                if [ "$approved_range_count" -gt 0 ] && [ "$approved_range_last" != "$range_candidate" ]; then
                    diagnostic "RANGE_MEMBERSHIP" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved Release Range does not end at the evaluated candidate' 'Preserve the inclusive candidate boundary in the approval record'
                fi

                approved_version="$(field_value "$approved_index" 'Approved Release Version')"
                approved_tag="$(field_value "$approved_index" 'Approved Release Tag')"
                normalized_version="${approved_version#v}"
                if [ "$approved_tag" != "v$normalized_version" ] && [ "$approved_tag" != "$normalized_version" ]; then
                    diagnostic "TAG_VERSION_MISMATCH" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved Release Tag does not encode Approved Release Version' 'Use v<approved-version> or the approved version as the tag string'
                fi

                prior_version="$(field_value "$evaluation_index" 'Prior Approved Release Version')"
                if parse_semver "$approved_version"; then
                    approved_major="$SEMVER_MAJOR"; approved_minor="$SEMVER_MINOR"; approved_patch="$SEMVER_PATCH"
                    if parse_semver "$prior_version"; then
                        prior_major="$SEMVER_MAJOR"; prior_minor="$SEMVER_MINOR"; prior_patch="$SEMVER_PATCH"
                        prior_compare="$(compare_semver_core "$approved_major" "$approved_minor" "$approved_patch" "$prior_major" "$prior_minor" "$prior_patch")"
                        [ "$prior_compare" -lt 0 ] && diagnostic "VERSION_PRECEDENCE" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved Release Version regresses below the Version Source of Truth' 'Use a non-regressing approved SemVer or record a reviewed policy decision'
                    fi
                fi

                comparison="$(field_value "$approved_index" 'Candidate-versus-Approved Comparison')"
                comparison="${comparison,,}"
                candidate_version=""
                [ "$candidate_index" -ge 0 ] && candidate_version="$(field_value "$candidate_index" 'Candidate Core Version')"
                if [ "$candidate_index" -ge 0 ] && parse_semver "$candidate_version"; then
                    candidate_text="$SEMVER_TEXT"
                    if parse_semver "$approved_version"; then approved_text="$SEMVER_TEXT"; else approved_text=""; fi
                    if [ "$comparison" = equal ] && [ "$candidate_text" != "$approved_text" ]; then
                        diagnostic "APPROVAL_REQUIRED" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Candidate-versus-Approved Comparison says Equal but versions differ' 'Use Equal only when approved and preliminary versions match'
                    fi
                    if [ "$candidate_text" != "$approved_text" ] && ! is_usable "$(field_value "$approved_index" 'Approval Difference Rationale')"; then
                        diagnostic "APPROVAL_REQUIRED" "$evaluation_id" "${RECORD_RELATIVE[$approved_index]}" 'Approved version differs from candidate without a rationale' 'Record a non-empty Approval Difference Rationale'
                    fi
                fi

                if [ "$qa_index" -ge 0 ]; then
                    for label in 'Range Boundary Result' 'Candidate Membership Result' 'Eligibility and Maintenance Classification Result' 'Complex-History Normalization Result' 'SemVer Precedence Result'; do
                        if ! test_pass "$(field_value "$qa_index" "$label")"; then
                            diagnostic "APPROVAL_REQUIRED" "$evaluation_id" "${RECORD_RELATIVE[$qa_index]}" "QA result is not Pass: $label" 'Resolve QA findings and re-review before approval'
                        fi
                    done
                    for label in 'Every Release Note Has Supporting Contract Impact Evidence' 'Every Effective User-Observable Contract Change Has Exactly One Public Release Note'; do
                        if ! test_pass "$(field_value "$qa_index" "$label")"; then
                            diagnostic "QA_NOTE_LINKAGE" "$evaluation_id" "${RECORD_RELATIVE[$qa_index]}" "QA note linkage is not Pass: $label" 'Link every release note and effective public change to evidence'
                        fi
                    done
                fi
                if [ "$notes_index" -ge 0 ] && ! test_pass "$(field_value "$notes_index" 'Note-to-Changelog Coverage')"; then
                    diagnostic "QA_NOTE_LINKAGE" "$evaluation_id" "${RECORD_RELATIVE[$notes_index]}" 'Release Notes Record has failed note-to-changelog coverage' 'Provide one unpublished draft entry per reviewed note'
                fi
            fi
        fi
    done
}

if [ ! -d "$RELEASE_DIR" ]; then
    if [ "$STRICT" -eq 1 ]; then
        diagnostic "MISSING_FIELD" "REPOSITORY" "docs/releases" 'Release-record directory does not exist' 'Provide a local docs/releases directory or use a fixture root containing one'
    else
        printf 'VALID|RECORDS=0|ROOT=.\n'
        exit 0
    fi
else
    index=0
    while IFS= read -r file; do
        # An unreadable record yields no fields at all. Reporting it as a single
        # READ_ERROR keeps parity with validate-release-records.ps1 and avoids
        # deriving field findings from content that was never read.
        if [ ! -r "$file" ]; then
            diagnostic "READ_ERROR" "UNKNOWN" "$(relative_path "$file")" 'Unable to read release record' 'Provide a readable local Markdown record'
            index=$((index + 1))
            continue
        fi
        parse_file "$index" "$file"
        type="$(field_value "$index" 'Record Type')"
        id="$(field_value "$index" 'Evaluation ID')"
        is_placeholder "$id" && id="UNKNOWN"
        if [ -z "$type" ]; then
            if [ "$STRICT" -eq 1 ]; then diagnostic "INVALID_STATE" "UNKNOWN" "$(relative_path "$file")" 'Missing Record Type' 'Use a supported canonical release-record type'; fi
            index=$((index + 1))
            continue
        fi
        canonical="$(canonical_type "$type")"
        if [ -z "$canonical" ]; then
            if [ "$STRICT" -eq 1 ]; then diagnostic "INVALID_STATE" "$id" "$(relative_path "$file")" "Unknown Record Type: $type" 'Use Release Evaluation, SemVer Candidate Record, QA Review Record, Release Notes Record, or Approved Release Record'; fi
            index=$((index + 1))
            continue
        fi
        RECORD_PATH[$index]="$file"
        RECORD_RELATIVE[$index]="$(relative_path "$file")"
        RECORD_ID[$index]="$id"
        RECORD_TYPE[$index]="$type"
        RECORD_CANONICAL[$index]="$canonical"
        RECORD_COUNT=$((RECORD_COUNT + 1))
        validate_record "$index"
        [ "$canonical" = 'Release Evaluation' ] && EVALUATION_INDICES+=("$index")
        index=$((index + 1))
    done < <(find "$RELEASE_DIR" -type f -name '*.md' ! -path "$RELEASE_DIR/ci-triage/*" -print | LC_ALL=C sort)
fi

[ "${#EVALUATION_INDICES[@]}" -gt 0 ] && validate_cross_records

if [ "$ERROR_COUNT" -gt 0 ]; then
    printf '%s\n' "${DIAGNOSTICS[@]}" | LC_ALL=C sort
    printf 'FAILED|ERRORS=%s|RECORDS=%s\n' "$ERROR_COUNT" "$RECORD_COUNT"
    exit 1
fi
printf 'VALID|RECORDS=%s|ROOT=.\n' "$RECORD_COUNT"
exit 0
