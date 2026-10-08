#!/usr/bin/env bash
# Read-only PromptKit OS CI triage state, action, and release-handoff validator.
# Usage: ./scripts/validate-ci-triage.sh [--root PATH] [--strict]

set -u
set -o pipefail

ROOT="."
STRICT=0
ERROR_COUNT=0
RECORD_COUNT=0
DIAGNOSTICS=()
SEEN_IDS=()
CURRENT_RELATIVE=""
CURRENT_ID="UNKNOWN"
ANCHOR_ID=""
ANCHOR_COUNT=0
declare -A FIELDS=()
declare -A DUPLICATES=()
ACTION_ORDER=()
declare -A ACTION_FIELDS=()
declare -A ACTION_DUPLICATES=()
declare -A ACTION_SEEN_IDS=()
declare -A RELEASE_FIELDS=()
declare -A RELEASE_DUPLICATES=()
HISTORY=()

add_diagnostic() {
    local category="$1" record_id="$2" path="$3" message="$4" remediation="$5"
    message="${message//$'\r'/ }"; message="${message//$'\n'/ }"; message="${message//|/ }"
    remediation="${remediation//$'\r'/ }"; remediation="${remediation//$'\n'/ }"; remediation="${remediation//|/ }"
    DIAGNOSTICS+=("$category|$record_id|$path|$message|$remediation")
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

usage() {
    cat <<'EOF'
Usage: validate-ci-triage.sh [--root PATH] [--strict]

Validate local CI Triage Records, action confirmation blocks, state histories,
and release handoff links without modifying records or external systems.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --root) [ "$#" -ge 2 ] || { echo "USAGE|ROOT|--root requires a path"; exit 2; }; ROOT="$2"; shift 2 ;;
        --root=*) ROOT="${1#*=}"; shift ;;
        --strict) STRICT=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "USAGE|ROOT|Unknown argument: $1"; usage; exit 2 ;;
    esac
done

[ -d "$ROOT" ] || { echo "INPUT_ERROR|REPOSITORY|.|Repository root does not exist|Provide a valid --root path"; exit 1; }
ROOT="$(cd "$ROOT" && pwd)"
CI_DIR="$ROOT/docs/releases/ci-triage"

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

unwrap() {
    local value
    value="$(trim "$1")"
    if [ "${#value}" -ge 2 ] && [ "${value:0:1}" = $'\x60' ] && [ "${value: -1}" = $'\x60' ]; then value="${value:1:${#value}-2}"; fi
    trim "$value"
}

normalize_label() {
    local label="$1"
    if [[ "$label" =~ ^(.*)[[:space:]]\[[^]]+\]$ ]]; then label="${BASH_REMATCH[1]}"; fi
    trim "$label"
}

relative_path() {
    local file="$1"
    printf '%s' "${file#"$ROOT"/}" | tr "\\\\" "/"
}

field_exists() { [ -n "${FIELDS[$1]+present}" ]; }
field_value() { unwrap "${FIELDS[$1]-}"; }
action_key() { printf '%s|%s' "$1" "$2"; }
action_exists() { [ -n "${ACTION_FIELDS[$(action_key "$1" "$2")]+present}" ]; }
action_value() { unwrap "${ACTION_FIELDS[$(action_key "$1" "$2")]-}"; }

is_placeholder() {
    local value
    value="$(unwrap "$1")"
    [ -z "$value" ] && return 0
    local lower="${value,,}"
    # The typographic dash is matched through an alternation rather than a bracket
    # expression on purpose: in a non-UTF-8 locale a multi-byte character inside
    # [ ... ] degrades to a set of raw bytes, which silently stops matching.
    [[ "$lower" =~ ^n/a([[:space:]]*(-|—)[[:space:]].*)?$ ]] && return 0
    [[ "$lower" = none || "$lower" = not\ applicable ]] && return 0
    [[ "$lower" =~ ^pending([[:space:]]*(-|—)[[:space:]].*)?$ ]] && return 0
    [[ "$lower" = not\ approved ]] && return 0
    [[ "$value" == \[*\] ]] && return 0
    return 1
}

is_usable() { ! is_placeholder "$1"; }

is_pending_confirmation_marker() {
    local value
    value="$(unwrap "$1")"
    [[ "${value,,}" =~ ^n/a[[:space:]]*(-|—)[[:space:]]*awaiting[[:space:]]+confirmation$ ]]
}

require_field() {
    local label="$1"
    if ! field_exists "$label"; then
        add_diagnostic "MISSING_FIELD" "$CURRENT_ID" "$CURRENT_RELATIVE" "Missing field: $label" "Add the labeled field to the CI Triage Record"
        return 1
    fi
    return 0
}

require_usable() {
    local label="$1"
    require_field "$label" || return 1
    if ! is_usable "$(field_value "$label")"; then
        add_diagnostic "MISSING_FIELD" "$CURRENT_ID" "$CURRENT_RELATIVE" "Missing usable value: $label" "Provide a non-placeholder value for the required field"
        return 1
    fi
    return 0
}

parse_record() {
    local file="$1" line label value action="" key
    FIELDS=(); DUPLICATES=(); ACTION_ORDER=(); ACTION_FIELDS=(); ACTION_DUPLICATES=(); ACTION_SEEN_IDS=(); ANCHOR_ID=""; ANCHOR_COUNT=0
    local anchor_pattern='^<a[[:space:]]id="([^"]+)"></a>'
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ $anchor_pattern ]]; then ANCHOR_ID="${BASH_REMATCH[1]}"; ANCHOR_COUNT=$((ANCHOR_COUNT + 1)); continue; fi
        if [[ "$line" =~ ^###[[:space:]]+(ACTION-[^[:space:]]+)[[:space:]]*$ ]]; then action="${BASH_REMATCH[1]}"; ACTION_ORDER+=("$action"); continue; fi
        if [[ "$line" =~ ^##[[:space:]]+ ]]; then action=""; continue; fi
        if [[ "$line" =~ ^-[[:space:]]\*\*([^*]+)\*\*:[[:space:]]*(.*)$ ]]; then
            label="$(normalize_label "${BASH_REMATCH[1]}")"; value="$(trim "${BASH_REMATCH[2]}")"
            if [ -n "$action" ]; then
                key="$(action_key "$action" "$label")"
                if [ -n "${ACTION_FIELDS[$key]+present}" ]; then ACTION_DUPLICATES[$key]=1; else ACTION_FIELDS[$key]="$value"; fi
            else
                if [ -n "${FIELDS[$label]+present}" ]; then DUPLICATES[$label]=1; else FIELDS[$label]="$value"; fi
            fi
        fi
    done < "$file"
}

valid_state() {
    case "$1" in evidence_requested|evidence_sufficient|classified|remediation_planned|awaiting_confirmation|local_reproduction_or_fix|verification_pending|verified|linked_to_pk_ship|blocked) return 0;; esac
    return 1
}

state_rank() {
    case "$1" in evidence_requested) echo 0;; evidence_sufficient) echo 1;; classified) echo 2;; remediation_planned) echo 3;; awaiting_confirmation) echo 4;; local_reproduction_or_fix) echo 5;; verification_pending) echo 6;; verified) echo 7;; linked_to_pk_ship) echo 8;; blocked) echo -1;; *) echo -2;; esac
}

history_contains() {
    local wanted="$1" item
    for item in "${HISTORY[@]}"; do [ "$item" = "$wanted" ] && return 0; done
    return 1
}

history_has_edge() {
    local from="$1" to="$2" i
    for ((i=0; i<${#HISTORY[@]}-1; i++)); do [ "${HISTORY[$i]}" = "$from" ] && [ "${HISTORY[$((i+1))]}" = "$to" ] && return 0; done
    return 1
}

valid_nonblocked_transition() {
    local from="$1" to="$2" active_action_count="$3" has_confirmed="$4" has_pending="$5" has_declined="$6" any_declined="$7"
    [ "$from" != blocked ] || return 1
    [ "$to" != blocked ] || return 0
    case "$from|$to" in
        evidence_requested\|evidence_sufficient|evidence_sufficient\|classified|classified\|remediation_planned|local_reproduction_or_fix\|verification_pending|verification_pending\|verified) return 0 ;;
        remediation_planned\|awaiting_confirmation) [ "$active_action_count" -gt 0 ] && return 0 ;;
        remediation_planned\|local_reproduction_or_fix) [ "$active_action_count" -eq 0 ] && return 0 ;;
        awaiting_confirmation\|local_reproduction_or_fix) [ "$active_action_count" -gt 0 ] && [ "$has_pending" -eq 0 ] && [ "$has_declined" -eq 0 ] && [ "$has_confirmed" -eq "$active_action_count" ] && return 0 ;;
        awaiting_confirmation\|remediation_planned) [ "$any_declined" -gt 0 ] && [ "$has_pending" -eq 0 ] && return 0 ;;
        verified\|linked_to_pk_ship) return 0 ;;
    esac
    return 1
}

valid_blocked_resume() {
    local previous="$1" target="$2" active_action_count="$3" has_confirmed="$4" has_pending="$5" has_declined="$6" any_declined="$7"
    [ -n "$previous" ] || return 1
    [ "$target" != blocked ] && [ "$target" != verified ] && [ "$target" != linked_to_pk_ship ] || return 1
    if [ "$target" = "$previous" ] && [ "$previous" != verified ] && [ "$previous" != linked_to_pk_ship ]; then return 0; fi
    case "$previous|$target" in
        evidence_sufficient\|evidence_requested) return 0 ;;
        classified\|evidence_sufficient) return 0 ;;
        remediation_planned\|classified) return 0 ;;
        awaiting_confirmation\|remediation_planned) [ "$any_declined" -gt 0 ] && [ "$has_pending" -eq 0 ] && return 0 ;;
        local_reproduction_or_fix\|remediation_planned) return 0 ;;
        local_reproduction_or_fix\|awaiting_confirmation) return 0 ;;
        verification_pending\|local_reproduction_or_fix) return 0 ;;
        verified\|verification_pending) return 0 ;;
        linked_to_pk_ship\|verification_pending) return 0 ;;
    esac
    valid_nonblocked_transition "$previous" "$target" "$active_action_count" "$has_confirmed" "$has_pending" "$has_declined" "$any_declined"
}

parse_release_fields() {
    local file="$1" line label value
    RELEASE_FIELDS=(); RELEASE_DUPLICATES=()
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^-[[:space:]]\*\*([^*]+)\*\*:[[:space:]]*(.*)$ ]]; then
            label="$(normalize_label "${BASH_REMATCH[1]}")"; value="$(trim "${BASH_REMATCH[2]}")"
            if [ -n "${RELEASE_FIELDS[$label]+present}" ]; then RELEASE_DUPLICATES[$label]=1; else RELEASE_FIELDS[$label]="$value"; fi
        fi
    done < "$file"
}

get_file_field() { unwrap "${RELEASE_FIELDS[$1]-}"; }

has_file_anchor() {
    local file="$1" wanted="$2" line anchor_id total=0 structural=0 i
    local anchor_pattern='^<a[[:space:]]+id="([^"]+)"></a>[[:space:]]*$'
    local heading_pattern='^#{1,6}[[:space:]]+'
    local lines=()
    mapfile -t lines < "$file" || return 1
    for ((i=0; i<${#lines[@]}; i++)); do
        line="${lines[$i]}"; line="${line%$'\r'}"
        if [[ "$line" =~ $anchor_pattern ]]; then
            anchor_id="${BASH_REMATCH[1]}"; total=$((total + 1))
            if [ "$anchor_id" = "$wanted" ] && [ "$i" -lt $(( ${#lines[@]} - 1 )) ]; then
                line="${lines[$((i + 1))]}"; line="${line%$'\r'}"
                [[ "$line" =~ $heading_pattern ]] && structural=$((structural + 1))
            fi
        fi
    done
    [ "$total" -eq 1 ] && [ "$structural" -eq 1 ]
}

validate_release_link() {
    local link="$1" release_id release_path relpath anchor release_state ci_link verification result resume release_slug ci_label ci_relpath ci_anchor verification_label verification_path verification_anchor
    local link_pattern='^\[([^]]+)\]\(([^#]+)#([^)]*)\)$'
    if ! [[ "$link" =~ $link_pattern ]]; then
        add_diagnostic "INVALID_LINK" "$CURRENT_ID" "$CURRENT_RELATIVE" "pk:ship Release Link is not a stable relative Markdown link" "Use [RELEASE-<release-slug>](../<release>.md#RELEASE-<release-slug>)"
        return
    fi
    release_id="${BASH_REMATCH[1]}"; relpath="${BASH_REMATCH[2]}"; anchor="${BASH_REMATCH[3]}"
    [ "$release_id" = "$anchor" ] || add_diagnostic "INVALID_LINK" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release link label and anchor differ" "Use the same immutable RELEASE ID in both positions"
    [[ "$release_id" =~ ^RELEASE-[a-z0-9][a-z0-9-]*$ ]] || add_diagnostic "INVALID_ID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Invalid release ID in pk:ship Release Link: $release_id" "Use RELEASE-<release-slug>"
    if ! [[ "$relpath" =~ ^\.\.\/([a-z0-9][a-z0-9-]*)\.md$ ]]; then
        add_diagnostic "INVALID_LINK" "$CURRENT_ID" "$CURRENT_RELATIVE" "pk:ship Release Link must target docs/releases/<release>.md" "Use a direct ../<release-slug>.md link from docs/releases/ci-triage"
        return
    fi
    release_slug="${BASH_REMATCH[1]}"
    [ "$release_id" = "RELEASE-$release_slug" ] || add_diagnostic "INVALID_LINK" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release link ID does not match its canonical release path" "Use RELEASE-$release_slug for ../$release_slug.md"
    release_path="$ROOT/docs/releases/$release_slug.md"
    if [ ! -f "$release_path" ]; then
        add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Linked release record does not exist: $relpath" "Create the existing docs/releases/<release>.md record before linking release resumption"
        return
    fi
    parse_release_fields "$release_path"
    for field in "${!RELEASE_DUPLICATES[@]}"; do add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Duplicate release field: $field" "Keep one canonical field label per release record"; done
    [ "$(get_file_field 'Release ID')" = "$release_id" ] || add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release record ID does not match pk:ship Release Link" "Preserve the immutable RELEASE ID across the link and target"
    has_file_anchor "$release_path" "$release_id" || add_diagnostic "INVALID_LINK" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release record is missing its explicit RELEASE anchor" "Add <a id=\"$release_id\"></a> immediately before the record heading"
    release_state="$(get_file_field 'Release Linkage State')"
    [ "$release_state" = linked_to_pk_ship ] || add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release Linkage State must be linked_to_pk_ship before resumption" "Link only after successful CI verification"

    ci_link="$(get_file_field 'CI Triage Link')"
    local ci_link_pattern='^\[([^]]+)\]\(ci-triage/([^)#]+\.md)#([^)]*)\)$'
    if ! [[ "$ci_link" =~ $ci_link_pattern ]]; then
        add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release CI Triage Link is not the canonical stable CI link" "Use [CI-<provider>-<run-id>](ci-triage/<ci-id>.md#<ci-id>)"
    else
        ci_label="${BASH_REMATCH[1]}"; ci_relpath="ci-triage/${BASH_REMATCH[2]}"; ci_anchor="${BASH_REMATCH[3]}"
        if [ "$ci_label" != "$CURRENT_ID" ] || [ "$ci_relpath" != "ci-triage/$CURRENT_ID.md" ] || [ "$ci_anchor" != "$CURRENT_ID" ]; then
            add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release CI Triage Link does not identify this CI record" "Use the exact CI ID, canonical ci-triage path, and matching anchor"
        elif [ ! -f "$ROOT/docs/releases/ci-triage/$CURRENT_ID.md" ] || ! has_file_anchor "$ROOT/docs/releases/ci-triage/$CURRENT_ID.md" "$CURRENT_ID"; then
            add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release CI Triage Link target or anchor does not exist" "Link the existing canonical CI Triage Record"
        fi
    fi

    verification="$(get_file_field 'Verification Link')"
    local verification_pattern='^\[([^]]+)\]\(([^#]+)#([^)]*)\)$'
    if ! [[ "$verification" =~ $verification_pattern ]]; then
        add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release Verification Link is not a stable existing Markdown link" "Use a relative Markdown link whose target and anchor exist"
    else
        verification_label="${BASH_REMATCH[1]}"; relpath="${BASH_REMATCH[2]}"; verification_anchor="${BASH_REMATCH[3]}"
        if [ "$verification_label" != "$verification_anchor" ] || [[ "$relpath" = /* || "$relpath" == *..* || "$relpath" == *://* ]]; then
            add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release Verification Link is not a stable existing Markdown link" "Use a relative Markdown link whose target and anchor exist"
        else
            verification_path="$ROOT/docs/releases/$relpath"
            if [ ! -f "$verification_path" ] || ! has_file_anchor "$verification_path" "$verification_anchor"; then
                add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release Verification Link target or anchor does not exist" "Link the recorded verification evidence"
            fi
        fi
    fi
    result="$(get_file_field 'Verified Result')"; result="${result,,}"
    [[ "$result" =~ ^pass([[:space:]]|[-:]) ]] || add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release record Verified Result is not Pass" "Record the successful verification result"
    resume="$(get_file_field 'Resume Condition')"; is_usable "$resume" || add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release record is missing Resume Condition" "Record the precise condition for release resumption"
}

validate_record() {
    local file="$1" state history_text token i from to previous release_candidate classification rank action_count=0 active_action_count=0 has_pending=0 has_confirmed=0 has_declined=0 any_declined=0 current_epoch=0 max_action_epoch=0 max_declined_epoch=0 remote target prior_state require_rank plan_reached=0 action_prefix action_value_text action_epoch_text action_epoch action_lifecycle label action_heading_count other_action
    CURRENT_RELATIVE="$(relative_path "$file")"; parse_record "$file"
    CURRENT_ID="$(field_value 'CI ID')"; [ -n "$CURRENT_ID" ] || CURRENT_ID=UNKNOWN
    RECORD_COUNT=$((RECORD_COUNT + 1))
    for key in "${!DUPLICATES[@]}"; do add_diagnostic "INVALID_STATE" "$CURRENT_ID" "$CURRENT_RELATIVE" "Duplicate field: $key" "Keep one canonical field label per record"; done
    require_field 'CI ID'; require_field 'State'; require_usable 'Owner'; require_usable 'CI Evidence'; require_field 'State History'; require_usable 'Resume Condition'; require_field 'Release Candidate'; require_field 'Remote Action Blocks'
    [[ "$CURRENT_ID" =~ ^CI-[a-z0-9][a-z0-9-]*-[A-Za-z0-9._-]+$ ]] || add_diagnostic "INVALID_ID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Invalid CI ID: $CURRENT_ID" "Use CI-<provider>-<run-id> with a lowercase provider slug"
    [ "$(basename "$file" .md)" = "$CURRENT_ID" ] || add_diagnostic "INVALID_ID" "$CURRENT_ID" "$CURRENT_RELATIVE" "CI filename does not match CI ID" "Save the record as docs/releases/ci-triage/<ci-failure-id>.md"
    [ "$CURRENT_RELATIVE" = "docs/releases/ci-triage/$CURRENT_ID.md" ] || add_diagnostic "INVALID_ID" "$CURRENT_ID" "$CURRENT_RELATIVE" "CI record is not at the canonical docs/releases/ci-triage path" "Save the record directly as docs/releases/ci-triage/<ci-id>.md"
    [ "$ANCHOR_COUNT" -eq 1 ] && [ "$ANCHOR_ID" = "$CURRENT_ID" ] || add_diagnostic "INVALID_LINK" "$CURRENT_ID" "$CURRENT_RELATIVE" "CI record is missing its exact immutable anchor" "Add one <a id=\"$CURRENT_ID\"></a> anchor"
    state="$(field_value 'State')"; valid_state "$state" || add_diagnostic "INVALID_STATE" "$CURRENT_ID" "$CURRENT_RELATIVE" "Unsupported CI state: $state" "Use one state from the canonical CI triage state list"
    release_candidate="$(field_value 'Release Candidate')"; release_candidate="${release_candidate,,}"
    [[ "$release_candidate" = true || "$release_candidate" = false ]] || add_diagnostic "INVALID_STATE" "$CURRENT_ID" "$CURRENT_RELATIVE" "Release Candidate must be true or false" "Record whether this CI failure affects a release candidate"
    history_text="$(field_value 'State History')"; HISTORY=(); IFS='>' read -r -a _parts <<< "$history_text"
    for token in "${_parts[@]}"; do token="$(unwrap "$token")"; [ -n "$token" ] && HISTORY+=("$token"); done
    [ "${#HISTORY[@]}" -gt 0 ] || add_diagnostic "INVALID_TRANSITION" "$CURRENT_ID" "$CURRENT_RELATIVE" "State History is empty" "Record the complete state path from evidence_requested"
    [ "${HISTORY[0]-}" = evidence_requested ] || add_diagnostic "INVALID_TRANSITION" "$CURRENT_ID" "$CURRENT_RELATIVE" "State History must start at evidence_requested" "Collect evidence before any classification or remediation"
    local last_index=$(( ${#HISTORY[@]} - 1 ))
    # A negative subscript is a hard error under `set -u`, so read the final
    # element through a guarded variable rather than indexing directly.
    local last_state=""
    [ "$last_index" -ge 0 ] && last_state="${HISTORY[$last_index]}"
    [ "$last_state" = "$state" ] || add_diagnostic "INVALID_TRANSITION" "$CURRENT_ID" "$CURRENT_RELATIVE" "State History final state differs from State" "Keep State equal to the final recorded transition"
    for token in "${HISTORY[@]}"; do valid_state "$token" || add_diagnostic "INVALID_STATE" "$CURRENT_ID" "$CURRENT_RELATIVE" "State History contains unsupported state: $token" "Use only canonical CI triage states"; done

    action_count="${#ACTION_ORDER[@]}"
    if [ "$action_count" -gt 0 ]; then
        if ! field_exists 'Current Action Epoch'; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Missing field: Current Action Epoch" "Record the active confirmation epoch for retained action blocks"; fi
        action_epoch_text="$(field_value 'Current Action Epoch')"
        if [[ "$action_epoch_text" =~ ^[1-9][0-9]*$ ]]; then current_epoch="$action_epoch_text"; else add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Current Action Epoch must be a positive integer" "Use the latest positive action epoch"; fi
    fi
    action_prefix="ACTION-${CURRENT_ID}-"
    for action in "${ACTION_ORDER[@]}"; do
        if [[ "$action" != "$action_prefix"[0-9][0-9][0-9] ]]; then add_diagnostic "INVALID_ID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Invalid action ID: $action" "Use ACTION-<ci-id>-<nnn> for each independent action"; fi
        if [ -n "${ACTION_SEEN_IDS[$action]+present}" ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Duplicate action ID: $action" "Use one unique ACTION-<ci-id>-<nnn> heading per independent action"; else ACTION_SEEN_IDS[$action]=1; fi
        action_heading_count=0
        for other_action in "${ACTION_ORDER[@]}"; do [ "$other_action" = "$action" ] && action_heading_count=$((action_heading_count + 1)); done
        if [ "$action_heading_count" -eq 1 ]; then
            for key in "${!ACTION_DUPLICATES[@]}"; do [[ "$key" == "$action|"* ]] && add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Duplicate action field in $action" "Keep one value per action field"; done
        fi
        for label in 'Action ID' 'Action Epoch' 'Action Lifecycle' 'Proposed Action' 'Confirmation State' 'Approver' 'Confirmation Timestamp' 'Bounded Scope' 'Reversal or Rollback Action' 'Resume Condition'; do
            if ! action_exists "$action" "$label"; then
                add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Missing action field: $label in $action" "Complete every independent action block"
            elif [[ "$label" = 'Proposed Action' || "$label" = 'Bounded Scope' || "$label" = 'Reversal or Rollback Action' || "$label" = 'Resume Condition' ]] && ! is_usable "$(action_value "$action" "$label")"; then
                add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Missing usable action field: $label in $action" "Provide a bounded non-placeholder value for every action field"
            fi
        done
        [ "$(action_value "$action" 'Action ID')" = "$action" ] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Action ID field does not match heading: $action" "Use the exact immutable action ID"
        action_epoch_text="$(action_value "$action" 'Action Epoch')"
        if [[ "$action_epoch_text" =~ ^[1-9][0-9]*$ ]]; then
            action_epoch="$action_epoch_text"
            [ "$action_epoch" -gt "$max_action_epoch" ] && max_action_epoch="$action_epoch"
            if [ "$current_epoch" -gt 0 ] && [ "$action_epoch" -gt "$current_epoch" ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action requires an Action Epoch no greater than Current Action Epoch" "Use the current or a prior recorded action epoch"; fi
        else
            action_epoch=0
            add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action requires a positive Action Epoch" "Record the positive confirmation epoch for this action"
        fi
            if [ "$current_epoch" -gt 0 ] && [ "$action_epoch" -eq "$current_epoch" ]; then active_action_count=$((active_action_count + 1)); fi
        action_lifecycle="$(action_value "$action" 'Action Lifecycle')"; action_lifecycle="${action_lifecycle,,}"
        action_value_text="$(action_value "$action" 'Confirmation State')"; action_value_text="${action_value_text,,}"
        case "$action_value_text" in
            pending)
                [ "$action_lifecycle" = open ] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action pending state requires Action Lifecycle open" "Keep undecided actions open"
                if [ "$current_epoch" -gt 0 ] && [ "$action_epoch" -ne "$current_epoch" ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action pending state cannot remain in a closed prior epoch" "Create a new current action or record a decision"; else has_pending=$((has_pending + 1)); fi
                ;;
            confirmed)
                [ "$action_lifecycle" = closed ] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action confirmed state requires Action Lifecycle closed" "Close an action when its confirmation decision is recorded"
                if [ "$action_epoch" -eq "$current_epoch" ]; then has_confirmed=$((has_confirmed + 1)); fi
                ;;
            declined)
                [ "$action_lifecycle" = closed ] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action declined state requires Action Lifecycle closed" "Close a declined action while preserving its audit record"
                any_declined=$((any_declined + 1))
                [ "$action_epoch" -gt "$max_declined_epoch" ] && max_declined_epoch="$action_epoch"
                if [ "$action_epoch" -eq "$current_epoch" ]; then has_declined=$((has_declined + 1)); fi
                ;;
            *) add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Unsupported Confirmation State in $action: $action_value_text" "Use pending, confirmed, or declined" ;;
        esac
        if [ "$action_value_text" = pending ]; then
            is_pending_confirmation_marker "$(action_value "$action" 'Approver')" || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Pending action must keep Approver at N/A - awaiting confirmation" "Do not imply human approval while pending"
            is_pending_confirmation_marker "$(action_value "$action" 'Confirmation Timestamp')" || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Pending action must keep Confirmation Timestamp at N/A - awaiting confirmation" "Do not imply a confirmation timestamp while pending"
        else
            is_usable "$(action_value "$action" 'Approver')" || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action requires a real Approver" "Record the human approver for confirmed or declined actions"
            is_usable "$(action_value "$action" 'Confirmation Timestamp')" || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action requires a Confirmation Timestamp" "Record the UTC confirmation timestamp"
        fi
    done
    if [ "$action_count" -gt 0 ] && [ "$max_action_epoch" -ne "$current_epoch" ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Current Action Epoch does not match the highest action epoch" "Use the latest epoch represented by the action blocks"; fi
    for action in "${ACTION_ORDER[@]}"; do
        action_value_text="$(action_value "$action" 'Confirmation State')"; action_value_text="${action_value_text,,}"
        action_epoch_text="$(action_value "$action" 'Action Epoch')"
        if [[ "$action_epoch_text" =~ ^[1-9][0-9]*$ ]] && [ "$max_declined_epoch" -gt 0 ] && [ "$action_value_text" != declined ] && [ "$action_epoch_text" -le "$max_declined_epoch" ]; then
            add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "$action must use a new Action Epoch after a declined action" "Close the declined epoch and create the next bounded action independently"
        fi
    done
    remote="$(field_value 'Remote Action Blocks')"; remote="${remote,,}"
    if [ "$action_count" -eq 0 ]; then [[ "$remote" = 'n/a - no remote action proposed' ]] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Remote Action Blocks must be N/A - no remote action proposed when no action exists" "Use one independent block for every proposed remote action"; else [[ "$remote" =~ ^[0-9]+$ ]] && [ "$remote" -eq "$action_count" ] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Remote Action Blocks count does not match independent action blocks" "Record the exact number of action blocks"; fi
    plan_reached=0
    for token in "${HISTORY[@]}"; do rank="$(state_rank "$token")"; [ "$rank" -ge 3 ] && plan_reached=1; done
    if [ "$action_count" -gt 0 ] && [ "$plan_reached" -eq 0 ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Action blocks require remediation_planned or later" "Record independent actions only after a bounded remediation plan exists"; fi
    if history_contains awaiting_confirmation && [ "$active_action_count" -eq 0 ]; then add_diagnostic "INVALID_TRANSITION" "$CURRENT_ID" "$CURRENT_RELATIVE" "awaiting_confirmation requires an independent action block" "Create one action block for each proposed remote action"; fi
    if [ "$state" = awaiting_confirmation ] && [ "$active_action_count" -gt 0 ] && [ "$has_pending" -eq 0 ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "awaiting_confirmation requires at least one pending action" "Keep the parent state awaiting_confirmation until every action has a decision"; fi
    if [ "$has_confirmed" -gt 0 ] && ! history_contains awaiting_confirmation; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Confirmed action requires an awaiting_confirmation parent state" "Record the action decision only after entering awaiting_confirmation"; fi

    rank="$(state_rank "$state")"; require_rank="$rank"
    if [ "$state" = blocked ]; then
        require_rank=-1
        prior_state=""
        for ((i=${#HISTORY[@]}-2; i>=0; i--)); do if [ "${HISTORY[$i]}" != blocked ]; then prior_state="${HISTORY[$i]}"; require_rank="$(state_rank "$prior_state")"; break; fi; done
    fi
    if [ "$require_rank" -ge 1 ]; then
        for label in 'Check Identity' 'Failed Job or Command' 'Failure Output' 'Revision Identifier' 'Execution Time' 'Configuration Context'; do require_usable "$label"; done
    else
        require_usable 'Missing Evidence'; require_usable 'Evidence Request Owner'
    fi
    for label in 'Remediation Plan' 'Remediation Classification' 'Suspected Cause' 'Affected Scope' 'Minimal Change' 'Verification Command' 'Rollback or Reversal Action'; do
        if [ "$require_rank" -lt 3 ] && is_usable "$(field_value "$label")"; then
            if [ "$label" = 'Remediation Plan' ]; then add_diagnostic "REMEDIATION_REQUIRED" "$CURRENT_ID" "$CURRENT_RELATIVE" "$label precedes classified evidence" "Record a plan only after classification"; else add_diagnostic "EVIDENCE_REQUIRED" "$CURRENT_ID" "$CURRENT_RELATIVE" "$label must not be recorded before evidence is sufficient" "Keep classification and remediation empty until the evidence bundle is complete"; fi
        fi
    done
    classification="$(field_value 'Classification')"; classification="${classification,,}"
    if [ "$require_rank" -ge 2 ]; then
        require_usable 'Classification'
        case "$classification" in test|static\ analysis|build|dependency\ or\ environment|infrastructure\ or\ transient|deployment|unknown| '') :;; *) add_diagnostic "CLASSIFICATION_REQUIRED" "$CURRENT_ID" "$CURRENT_RELATIVE" "Unsupported CI classification: $classification" "Use the canonical evidence-based classification list";; esac
    elif is_usable "$(field_value 'Classification')"; then add_diagnostic "CLASSIFICATION_REQUIRED" "$CURRENT_ID" "$CURRENT_RELATIVE" "Classification precedes evidence sufficiency" "Do not classify before evidence_sufficient"; fi
    if [ "$require_rank" -ge 3 ]; then for label in 'Remediation Plan' 'Remediation Classification' 'Suspected Cause' 'Affected Scope' 'Minimal Change' 'Verification Command' 'Rollback or Reversal Action'; do require_usable "$label"; done; fi
    if [ "$require_rank" -ge 7 ]; then
        require_usable 'Verification Evidence'; verification="$(field_value 'Verification Evidence')"; verification="${verification,,}"
        [[ "$verification" =~ ^pass([[:space:]]|[-:]) ]] || add_diagnostic "VERIFICATION_REQUIRED" "$CURRENT_ID" "$CURRENT_RELATIVE" "Verified state requires successful Verification Evidence" "Record a Pass result for this CI failure"
    elif is_usable "$(field_value 'Verification Evidence')"; then
        add_diagnostic "VERIFICATION_REQUIRED" "$CURRENT_ID" "$CURRENT_RELATIVE" "Verification Evidence is premature for the current state" "Keep successful verification for verified or linked_to_pk_ship"
    fi

    for ((i=0; i<${#HISTORY[@]}-1; i++)); do
        from="${HISTORY[$i]}"; to="${HISTORY[$((i+1))]}"
        if [ "$from" = blocked ]; then
            previous=""
            for ((j=i-1; j>=0; j--)); do if [ "${HISTORY[$j]}" != blocked ]; then previous="${HISTORY[$j]}"; break; fi; done
            valid_blocked_resume "$previous" "$to" "$active_action_count" "$has_confirmed" "$has_pending" "$has_declined" "$any_declined" || add_diagnostic "INVALID_TRANSITION" "$CURRENT_ID" "$CURRENT_RELATIVE" "Invalid CI transition: $from -> $to" "Follow the evidence-first state graph and conditional action branch"
        else
            valid_nonblocked_transition "$from" "$to" "$active_action_count" "$has_confirmed" "$has_pending" "$has_declined" "$any_declined" || add_diagnostic "INVALID_TRANSITION" "$CURRENT_ID" "$CURRENT_RELATIVE" "Invalid CI transition: $from -> $to" "Follow the evidence-first state graph and conditional action branch"
        fi
    done
    if [ "$has_pending" -gt 0 ] && [ "$state" != awaiting_confirmation ] && [ "$state" != blocked ]; then add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Pending action requires awaiting_confirmation or blocked state" "Keep the parent record blocked until the action is decided"; fi
    if [ "$any_declined" -gt 0 ]; then
        require_usable 'Declined Action Outcome'
        history_has_edge awaiting_confirmation remediation_planned || history_has_edge awaiting_confirmation blocked || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Declined action requires a new remediation plan or blocked parent record" "Close only the declined action and define the next bounded path"
        [[ "$has_declined" -eq 0 || ( "$state" != verified && "$state" != linked_to_pk_ship ) ]] || add_diagnostic "ACTION_INVALID" "$CURRENT_ID" "$CURRENT_RELATIVE" "Declined action cannot produce verified or linked_to_pk_ship" "Create a new plan or remain blocked"
    fi
    if history_contains blocked; then
        require_usable 'Blocker'; require_usable 'Resume Target'; target="$(field_value 'Resume Target')"
        if ! valid_state "$target" || [ "$target" = blocked ] || [ "$target" = verified ] || [ "$target" = linked_to_pk_ship ]; then add_diagnostic "BLOCKED_RESUME" "$CURRENT_ID" "$CURRENT_RELATIVE" "Resume Target is not a safe canonical state" "Resume through the justified current checkpoint or its immediate safe predecessor"; fi
        for ((i=0; i<${#HISTORY[@]}; i++)); do
            if [ "${HISTORY[$i]}" = blocked ]; then
                if [ "$i" -lt $(( ${#HISTORY[@]} - 1 )) ]; then
                    [ "${HISTORY[$((i+1))]}" = "$target" ] || add_diagnostic "BLOCKED_RESUME" "$CURRENT_ID" "$CURRENT_RELATIVE" "Resume Target does not match the state after blocked" "Record the exact justified re-entry state"
                else
                    previous=""
                    for ((j=i-1; j>=0; j--)); do if [ "${HISTORY[$j]}" != blocked ]; then previous="${HISTORY[$j]}"; break; fi; done
                    valid_blocked_resume "$previous" "$target" "$active_action_count" "$has_confirmed" "$has_pending" "$has_declined" "$any_declined" || add_diagnostic "BLOCKED_RESUME" "$CURRENT_ID" "$CURRENT_RELATIVE" "Resume Target is not a safe canonical re-entry from the blocked state" "Resume through the justified current checkpoint or its immediate safe predecessor"
                fi
            fi
        done
    fi
    if [ "$state" = linked_to_pk_ship ]; then
        [ "$release_candidate" = true ] || add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "Only release candidates may reach linked_to_pk_ship" "Keep non-release records at verified"
        # Guarded for the same reason as the final-state check above: an empty or
        # single-element history makes this subscript negative.
        local prior_state_value=""
        [ "${#HISTORY[@]}" -ge 2 ] && prior_state_value="${HISTORY[${#HISTORY[@]}-2]}"
        [ "$prior_state_value" = verified ] || add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "linked_to_pk_ship must follow verified" "Link release evidence only after successful verification"
        require_usable 'pk:ship Release Link'; validate_release_link "$(field_value 'pk:ship Release Link')"
    elif is_usable "$(field_value 'pk:ship Release Link')"; then add_diagnostic "RELEASE_HANDOFF" "$CURRENT_ID" "$CURRENT_RELATIVE" "pk:ship Release Link is present before linked_to_pk_ship" "Keep release linkage empty until verified handoff"; fi
}

if [ ! -d "$CI_DIR" ]; then
    if [ "$STRICT" -eq 1 ]; then add_diagnostic "MISSING_FIELD" "REPOSITORY" "docs/releases/ci-triage" "CI Triage directory does not exist" "Provide docs/releases/ci-triage or use a CI fixture root"; else printf 'VALID|RECORDS=0|ROOT=.\n'; exit 0; fi
else
    mapfile -t files < <(find "$CI_DIR" -type f -name '*.md' -print | LC_ALL=C sort)
    if [ "${#files[@]}" -eq 0 ]; then add_diagnostic "MISSING_FIELD" "REPOSITORY" "docs/releases/ci-triage" "No CI Triage Records found" "Provide at least one canonical CI record"; fi
    for file in "${files[@]}"; do
        # An unreadable record yields no fields at all. Reporting it as a single
        # READ_ERROR keeps parity with validate-ci-triage.ps1 and avoids deriving
        # roughly twenty field findings from content that was never read.
        if [ ! -r "$file" ]; then
            add_diagnostic "READ_ERROR" "UNKNOWN" "$(relative_path "$file")" "Unable to read CI Triage Record" "Provide a readable local Markdown record"
            continue
        fi
        validate_record "$file"
        for previous in "${SEEN_IDS[@]}"; do [ "$previous" = "$CURRENT_ID" ] && add_diagnostic "DUPLICATE_ID" "$CURRENT_ID" "$(relative_path "$file")" "Duplicate CI ID across records" "Keep each immutable CI ID unique"; done
        SEEN_IDS+=("$CURRENT_ID")
    done
fi

if [ "$ERROR_COUNT" -gt 0 ]; then printf '%s\n' "${DIAGNOSTICS[@]}" | LC_ALL=C sort; printf 'FAILED|ERRORS=%s|RECORDS=%s\n' "$ERROR_COUNT" "$RECORD_COUNT"; exit 1; fi
printf 'VALID|RECORDS=%s|ROOT=.\n' "$RECORD_COUNT"
exit 0
