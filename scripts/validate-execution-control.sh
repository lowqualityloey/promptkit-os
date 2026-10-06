#!/usr/bin/env bash
# Read-only Agent Execution Control validator.
# Usage: ./scripts/validate-execution-control.sh [--root PATH] [--strict] [--authorization-baseline REF]

set -u

ROOT="."
STRICT=0
AUTHORIZATION_BASELINE=""
ERROR_COUNT=0
RECORD_COUNT=0
HAS_QUICK_RECORD=0
QUICK_UNRESOLVED_COUNT=0
declare -a DEGRADATIONS=()

usage() {
    cat <<'EOF'
Usage: validate-execution-control.sh [--root PATH] [--strict] [--authorization-baseline REF]

Validate durable Agent Execution Control Markdown records without modifying
records, files, Git state, remotes, releases, or task state.
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
        --authorization-baseline)
            AUTHORIZATION_BASELINE="${2:-}"
            [ -n "$AUTHORIZATION_BASELINE" ] || { echo "USAGE|AUTHORIZATION_BASELINE|--authorization-baseline requires a git ref"; exit 2; }
            shift 2
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
    echo "MISSING_FIELD|REPOSITORY|.|Repository root does not exist|Provide a valid --root path"
    exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"
TASK_DIR="$ROOT/docs/tasks"

# Bash 4 associative arrays are available on supported CI and developer hosts.
declare -A TASK_FILE_BY_ID=()
declare -A TASK_STATE_BY_ID=()
declare -A TASK_REVISION_BY_ID=()
declare -a TASK_IDS=()

diagnostic() {
    local category="$1"
    local record_id="$2"
    local path="$3"
    local message="$4"
    local remediation="$5"
    message="$(trim "$(printf '%s' "$message" | tr '\r\n|' '   ')")"
    remediation="$(trim "$(printf '%s' "$remediation" | tr '\r\n|' '   ')")"
    printf '%s|%s|%s|%s|%s\n' "$category" "$record_id" "$path" "$message" "$remediation"
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

degradation() {
    local category="$1"
    local record_id="$2"
    local path="$3"
    local message="$4"
    local remediation="$5"
    message="$(trim "$(printf '%s' "$message" | tr '\r\n|' '   ')")"
    remediation="$(trim "$(printf '%s' "$remediation" | tr '\r\n|' '   ')")"
    DEGRADATIONS+=("$(printf '%s|%s|%s|%s|%s' "$category" "$record_id" "$path" "$message" "$remediation")")
}


trim() {
    local value="$1"
    value="${value%$'\r'}"
    value="${value#${value%%[![:space:]]*}}"
    value="${value%${value##*[![:space:]]}}"
    printf '%s' "$value"
}

strip_backticks() {
    local value="$1"
    if [ "${#value}" -ge 2 ] && [[ "$value" == \`*\` ]]; then
        printf '%s' "${value:1:-1}"
    else
        printf '%s' "$value"
    fi
}

field_exists() {
    local file="$1"
    local label="$2"
    awk -v needle="- **${label}**:" '{ sub(/\r$/, ""); } index($0, needle) == 1 { found=1; exit } END { exit(found ? 0 : 1) }' "$file"
}

field_value() {
    local file="$1"
    local label="$2"
    awk -v needle="- **${label}**:" '{ sub(/\r$/, ""); } index($0, needle) == 1 { value=substr($0, length(needle)+1); sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); if (value ~ /^`.*`$/) value=substr(value, 2, length(value)-2); sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); print value; exit }' "$file"
}

list_items() {
    local file="$1"
    local label="$2"
    awk -v needle="- **${label}**:" '
        index($0, needle) == 1 { inside=1; next }
        inside && index($0, "- **") == 1 { exit }
        inside && $0 ~ /^[[:space:]]+- / { print }
    ' "$file"
}

relative_path() {
    local file="$1"
    local rel="${file#"$ROOT"/}"
    printf '%s' "${rel//\\//}"
}

is_placeholder() {
    local value
    value="$(trim "$1")"
    [ -z "$value" ] && return 0
    case "$value" in
        "N/A"|"n/a"|"None"|"none"|"Not applicable"|"not applicable"|"TBD"|"tbd"|"[N/A]"|"[None]"|"[Pending]"|"Pending"|"[TBD]"|"[tbd]") return 0 ;;
    esac
    [[ "$value" == \[*\] ]] && return 0
    return 1
}

require_label() {
    local file="$1" id="$2" label="$3" category="${4:-MISSING_FIELD}"
    if ! field_exists "$file" "$label"; then
        diagnostic "$category" "$id" "$(relative_path "$file")" "Missing field: $label" "Add the labeled field to the canonical record"
        return 1
    fi
    return 0
}

require_value() {
    local file="$1" id="$2" label="$3" category="${4:-MISSING_FIELD}" remediation="${5:-Provide a non-placeholder value for the labeled field}"
    require_label "$file" "$id" "$label" "$category" || return 1
    local value
    value="$(field_value "$file" "$label")"
    if is_placeholder "$value"; then
        diagnostic "$category" "$id" "$(relative_path "$file")" "Missing usable value: $label" "$remediation"
        return 1
    fi
    return 0
}

has_uppercase() {
    printf '%s' "$1" | LC_ALL=C grep -q '[A-Z]'
}

is_valid_task_id() {
    local value="$1" profile="${2:-legacy}"
    if [ "$profile" = "sdlc-overlay-v1" ]; then
        if has_uppercase "${value#TASK-}"; then return 1; fi
        local legacy_prefix='^TASK-[0-9]{4}-[0-9]{2}-[0-9]{2}-'
        [[ "$value" =~ ^TASK-[a-z0-9]+(-[a-z0-9]+)*$ ]] && [[ ! "$value" =~ $legacy_prefix ]]
    else
        [[ "$value" =~ ^TASK-[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9][a-z0-9-]*$ ]]
    fi
}

is_valid_adaptation_link_id() {
    local kind="$1" value="$2" slug
    case "$kind" in
        PLAN) slug="${value#PLAN-}" ;;
        ASSUMPTION) slug="${value#ASSUMPTION-}" ;;
        *) return 1 ;;
    esac
    if has_uppercase "$slug"; then return 1; fi
    case "$kind" in
        PLAN) [[ "$value" =~ ^PLAN-[a-z0-9]+(-[a-z0-9]+)*$ ]] ;;
        ASSUMPTION) [[ "$value" =~ ^ASSUMPTION-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}$ ]] ;;
        *) return 1 ;;
    esac
}

validate_adaptation_link() {
    local file="$1" id="$2" link="$3" kind="$4" path="$5"
    local expected_prefix remediation link_pattern
    expected_prefix="$kind-<slug>"
    remediation="Use [$expected_prefix](relative/path#$expected_prefix) pointing to an existing explicit anchor"
    link_pattern='^\[([A-Za-z0-9._-]+)\]\(([^)#]+)#([A-Za-z0-9._-]+)\)$'
    if [[ ! "$link" =~ $link_pattern ]]; then
        diagnostic INVALID_LINK "$id" "$path" "Invalid $kind link: $link" "$remediation"
        return 1
    fi

    local linked_id="${BASH_REMATCH[1]}" target_path="${BASH_REMATCH[2]}" anchor="${BASH_REMATCH[3]}"
    if [ "$linked_id" != "$anchor" ]; then
        diagnostic INVALID_LINK "$id" "$path" "Invalid $kind link: displayed ID and anchor differ" "$remediation"
        return 1
    fi
    if ! is_valid_adaptation_link_id "$kind" "$linked_id"; then
        diagnostic INVALID_LINK "$id" "$path" "Invalid $kind link ID: $linked_id" "$remediation"
        return 1
    fi
    case "$target_path" in
        ""|/*|\\*|[A-Za-z]:/*|[A-Za-z]:\\*|*://*)
            diagnostic INVALID_LINK "$id" "$path" "Invalid $kind link target: $target_path" "$remediation"
            return 1
            ;;
    esac

    local target_dir canonical_dir target_file
    target_dir="$(dirname "$file")/$(dirname "$target_path")"
    canonical_dir="$(cd "$target_dir" 2>/dev/null && pwd)" || {
        diagnostic INVALID_LINK "$id" "$path" "Missing $kind link target: $target_path" "$remediation"
        return 1
    }
    target_file="$canonical_dir/$(basename "$target_path")"
    case "$target_file" in
        "$ROOT"/*) ;;
        *)
            diagnostic INVALID_LINK "$id" "$path" "Invalid $kind link target: $target_path" "$remediation"
            return 1
            ;;
    esac
    if [ ! -f "$target_file" ] || ! grep -Fq "<a id=\"$anchor\"></a>" "$target_file"; then
        diagnostic INVALID_LINK "$id" "$path" "Missing $kind link target or anchor: $target_path#$anchor" "$remediation"
        return 1
    fi
    return 0
}

validate_adaptation_fields() {
    local file="$1" id="$2" path="$3"
    local work_type planning_link planning_depth assumptions tdd_mode
    if require_value "$file" "$id" "Work Type" "ADAPTATION_FIELD"; then
        work_type="$(field_value "$file" "Work Type")"
        case "$work_type" in
            "Code Work"|"Documentation Work"|"Configuration Work"|"Research Work") ;;
            *) diagnostic ADAPTATION_FIELD "$id" "$path" "Invalid Work Type: $work_type" "Use Code Work, Documentation Work, Configuration Work, or Research Work" ;;
        esac
    fi

    require_value "$file" "$id" "Planning Record Link" "ADAPTATION_FIELD"
    planning_link="$(field_value "$file" "Planning Record Link")"
    if ! is_placeholder "$planning_link"; then
        validate_adaptation_link "$file" "$id" "$planning_link" "PLAN" "$path"
    fi

    if field_exists "$file" "Planning Depth Reference"; then
        planning_depth="$(field_value "$file" "Planning Depth Reference")"
        case "$planning_depth" in
            Minimal|Full|N/A) ;;
            *) diagnostic ADAPTATION_FIELD "$id" "$path" "Invalid Planning Depth Reference: $planning_depth" "Use Minimal, Full, or N/A" ;;
        esac
    fi

    if field_exists "$file" "Assumption Record Links"; then
        assumptions="$(field_value "$file" "Assumption Record Links")"
        if [ "$assumptions" != "None" ] && [ "$assumptions" != "N/A" ]; then
            local assumption_link
            while IFS= read -r assumption_link; do
                assumption_link="$(trim "$assumption_link")"
                if [ -z "$assumption_link" ]; then
                    diagnostic INVALID_LINK "$id" "$path" "Invalid ASSUMPTION link collection: $assumptions" "Use comma-separated [ASSUMPTION-<spec-slug>-<nnn>](relative/path#ASSUMPTION-<spec-slug>-<nnn>) links, None, or N/A"
                    continue
                fi
                validate_adaptation_link "$file" "$id" "$assumption_link" "ASSUMPTION" "$path"
            done < <(printf '%s\n' "$assumptions" | tr ',' '\n')
        fi
    fi

    if require_value "$file" "$id" "TDD Enforcement Mode" "ADAPTATION_FIELD"; then
        tdd_mode="$(field_value "$file" "TDD Enforcement Mode")"
        case "$tdd_mode" in
            disabled|enabled) ;;
            *) diagnostic ADAPTATION_FIELD "$id" "$path" "Invalid TDD Enforcement Mode: $tdd_mode" "Use disabled or enabled" ;;
        esac
    fi
}

is_valid_child_id() {
    [[ "$1" =~ ^(SCOPE|CHECKPOINT|HANDOFF)-[0-9]{4}-[0-9]{2}-[0-9]{2}-.+-[0-9]+$ ]]
}

expected_status() {
    case "$1" in
        planned|ready|aborted) printf 'To Do' ;;
        in_progress|checkpoint_due|blocked|paused|handoff_ready) printf 'In Progress' ;;
        awaiting_review) printf 'In Review' ;;
        completed) printf 'Done' ;;
        *) printf '' ;;
    esac
}

allowed_transition() {
    case "$1:$2" in
        N/A:planned|None:planned|planned:ready|planned:in_progress|planned:aborted|ready:in_progress|ready:blocked|ready:paused|ready:aborted|in_progress:checkpoint_due|in_progress:blocked|in_progress:paused|in_progress:handoff_ready|in_progress:awaiting_review|in_progress:completed|in_progress:aborted|checkpoint_due:in_progress|checkpoint_due:blocked|checkpoint_due:paused|checkpoint_due:handoff_ready|checkpoint_due:aborted|blocked:ready|blocked:in_progress|blocked:paused|blocked:aborted|paused:ready|paused:in_progress|paused:aborted|handoff_ready:in_progress|handoff_ready:checkpoint_due|handoff_ready:blocked|handoff_ready:aborted|awaiting_review:planned|awaiting_review:in_progress|awaiting_review:completed|awaiting_review:blocked)
            return 0 ;;
        *) return 1 ;;
    esac
}

revision_token() {
    local value="$1"
    if [[ "$value" =~ (REV-[A-Za-z0-9._-]+) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ([0-9a-fA-F]{7,40}) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    fi
}

validate_transitions() {
    local file="$1" id="$2" state="$3"
    local count=0 last_new="" in_section=0 line heading
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*#{1,6}[[:space:]]+(.*)$ ]]; then
            heading="$(trim "${BASH_REMATCH[1]}")"
            if [ "$heading" = "Transition History" ]; then
                in_section=1
            else
                in_section=0
            fi
            continue
        fi
        [ "$in_section" -eq 0 ] && continue
        [[ "$line" =~ ^[[:space:]]*\| ]] || continue
        [ -z "$(trim "$line")" ] && continue
        [[ "$line" == *"Previous State"* ]] && continue
        [[ "$line" == *"---"* ]] && continue
        IFS='|' read -r _ previous new _rest <<< "$line"
        previous="$(strip_backticks "$(trim "$previous")")"
        new="$(strip_backticks "$(trim "$new")")"
        initial_transition=0
        if { [ "$previous" = "N/A" ] || [ "$previous" = "None" ]; } && [ "$new" = "planned" ]; then
            initial_transition=1
        fi
        if (is_placeholder "$previous" || is_placeholder "$new") && [ "$initial_transition" -eq 0 ]; then
            diagnostic INVALID_TRANSITION "$id" "$(relative_path "$file")" "Transition history contains a placeholder" "Record a concrete previous and new execution state"
            continue
        fi
        count=$((count + 1))
        if ! allowed_transition "$previous" "$new"; then
            diagnostic INVALID_TRANSITION "$id" "$(relative_path "$file")" "Illegal transition: $previous -> $new" "Use the documented execution-state transition graph"
        fi
        last_new="$new"
    done < "$file"
    if [ "$count" -eq 0 ]; then
        diagnostic INVALID_TRANSITION "$id" "$(relative_path "$file")" "No concrete transition history found" "Record at least the initial transition and current state"
    elif [ "$last_new" != "$state" ]; then
        diagnostic INVALID_TRANSITION "$id" "$(relative_path "$file")" "Last transition state '$last_new' does not match current state '$state'" "Reconcile transition history with Execution State"
    fi
}

check_structured_evidence() {
    local file="$1" id="$2" path="$3"
    grep -q '```evidence:verification' "$file" || return 0
    # Validate EVERY evidence block (not just the first): awk emits one
    # \x1f-separated status/exit_code/checks_failed line per block. Values are
    # split on the FIRST colon only, with trailing `#` comments and CR stripped.
    # The while loop below uses a here-string (not a pipeline) so diagnostic()
    # increments ERROR_COUNT in the current shell.
    local parsed status exit_code failed_count
    parsed="$(awk '
        /^[ \t]*```evidence:verification[ \t]*$/ { inblock=1; status=""; code=""; failed=""; next }
        inblock && /^[ \t]*```[ \t]*$/ { printf "%s\037%s\037%s\n", status, code, failed; inblock=0; next }
        inblock {
            line=$0
            sub(/\r$/, "", line)
            pos=index(line, ":")
            if (pos > 0) {
                key=substr(line, 1, pos-1); val=substr(line, pos+1)
                gsub(/^[ \t]+|[ \t]+$/, "", key)
                if (key == "status" && status == "") { status=cleanval(val) }
                else if (key == "exit_code" && code == "") { code=cleanval(val) }
                else if (key == "checks_failed" && failed == "") { failed=cleanval(val) }
            }
            next
        }
        function cleanval(v) { sub(/[ \t]*#[ \t]*.*$/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v); return v }
        END { if (inblock) printf "%s\037%s\037%s\n", status, code, failed }
    ' "$file")"
    [ -z "$parsed" ] && return 0
    while IFS="$(printf '\037')" read -r status exit_code failed_count; do
        if [ -n "$status" ] && [ "$status" != "PASS" ]; then
            diagnostic "EVIDENCE_VERIFICATION_FAILED" "$id" "$path" "Structured verification evidence records status: $status" "Resolve verification failures before completing work"
        fi
        if [ -n "$exit_code" ] && [ "$exit_code" != "0" ]; then
            diagnostic "EVIDENCE_VERIFICATION_FAILED" "$id" "$path" "Structured verification evidence records non-zero exit_code: $exit_code" "All verification checks must exit with 0"
        fi
        if [ -n "$failed_count" ] && [ "$failed_count" != "0" ]; then
            diagnostic "EVIDENCE_VERIFICATION_FAILED" "$id" "$path" "Structured verification evidence records failed checks: $failed_count" "All verification checks must pass"
        fi
    done <<< "$parsed"
}

validate_task() {
    local file="$1" id="$(field_value "$1" "Task ID")" path profile id_profile="legacy" profile_remediation
    path="$(relative_path "$file")"
    profile="$(field_value "$file" "PromptKit Adaptation Profile")"
    [ -z "$id" ] && id="UNKNOWN"
    RECORD_COUNT=$((RECORD_COUNT + 1))

    if [ -n "$profile" ] && [ "$profile" != "none" ] && [ "$profile" != "sdlc-overlay-v1" ]; then
        diagnostic INVALID_PROFILE "$id" "$path" "Unknown PromptKit Adaptation Profile: $profile" "Use none or sdlc-overlay-v1"
    fi
    [ "$profile" = "sdlc-overlay-v1" ] && id_profile="sdlc-overlay-v1"
    if ! is_valid_task_id "$id" "$id_profile"; then
        profile_remediation="Use TASK-YYYY-MM-DD-slug"
        [ "$id_profile" = "sdlc-overlay-v1" ] && profile_remediation="Use TASK-<task-slug>"
        diagnostic INVALID_ID "$id" "$path" "Task ID is not stable: $id" "$profile_remediation"
    elif [ -n "${TASK_FILE_BY_ID[$id]+set}" ]; then
        diagnostic INVALID_ID "$id" "$path" "Duplicate Task ID: $id" "Keep one canonical Task Record per stable task identifier"
    else
        TASK_FILE_BY_ID["$id"]="$file"
        TASK_IDS+=("$id")
    fi

    if [ "$profile" = "sdlc-overlay-v1" ]; then
        validate_adaptation_fields "$file" "$id" "$path"
    fi

    local required_labels=(
        "Record Type" "Task ID" "Specification" "Owner / Actor" "Execution Scope"
        "Approval Boundary" "Created" "Objective" "Explicit Non-Goals" "Dependencies"
        "Risk" "Verification Condition" "Mode" "Batch Authorization" "Soft Checkpoint"
        "Hard Checkpoint" "Event-Driven Checkpoints" "Stop Conditions" "Host Timer Capability"
        "Execution State" "Mapped \`pk:tasks\` Status" "Active Task Pointer" "Start Time"
        "Current Actor" "Next Action" "Changed Files" "Scope Change Records"
        "Checkpoint Records" "Handoff Records" "Verification Evidence" "CI Evidence"
        "Review Evidence" "Commit Evidence" "Pull Request Evidence" "Release Evidence"
        "Blocker and Resume Condition" "Completion State" "Acceptance Results"
        "Changed-File Summary" "Completion Exception" "Completion Decision and Timestamp"
    )
    local label
    for label in "${required_labels[@]}"; do
        require_label "$file" "$id" "$label"
    done
    require_value "$file" "$id" "Record Type"
    [ "$(field_value "$file" "Record Type")" = "Task Record" ] || diagnostic INVALID_STATE "$id" "$path" "Record Type is not Task Record" "Use the canonical Task Record type"
    require_value "$file" "$id" "Specification"
    require_value "$file" "$id" "Owner / Actor"
    require_value "$file" "$id" "Execution Scope"
    require_value "$file" "$id" "Approval Boundary"
    require_value "$file" "$id" "Created"
    require_value "$file" "$id" "Objective" "READINESS_FAILURE"
    require_label "$file" "$id" "Dependencies" "READINESS_FAILURE"
    require_value "$file" "$id" "Risk"
    require_value "$file" "$id" "Verification Condition" "READINESS_FAILURE"
    require_value "$file" "$id" "Mode" "READINESS_FAILURE"
    require_value "$file" "$id" "Host Timer Capability" "POLICY_LIMITATION"

    local in_scope="$(list_items "$file" "In Scope")"
    local non_goals="$(list_items "$file" "Explicit Non-Goals")"
    if [ -z "$(trim "$in_scope")" ] || [[ "$in_scope" == *"[File"* ]]; then
        diagnostic READINESS_FAILURE "$id" "$path" "In Scope must contain at least one concrete item" "List the bounded files, behaviors, or deliverables"
    fi
    if [ -z "$(trim "$non_goals")" ] || [[ "$non_goals" == *"[File"* ]]; then
        diagnostic READINESS_FAILURE "$id" "$path" "Explicit Non-Goals must contain a concrete boundary" "Record what is deliberately excluded"
    fi
    if ! printf '%s' "$(field_value "$file" "Host Timer Capability")" | grep -Eiq 'limitation|cannot|unavailable|not[[:space:]-]*(mechanically|guaranteed|observe|terminate|enforce)|n/?a'; then
        diagnostic POLICY_LIMITATION "$id" "$path" "Host timer capability does not record an enforcement limitation" "State that live host timing or forced termination is unavailable or limited"
    fi

    local state="$(field_value "$file" "Execution State")"
    local mapped="$(field_value "$file" "Mapped \`pk:tasks\` Status")"
    local active="$(field_value "$file" "Active Task Pointer")"
    TASK_STATE_BY_ID["$id"]="$state"
    local expected="$(expected_status "$state")"
    case "$state" in
        planned|ready|in_progress|checkpoint_due|blocked|paused|handoff_ready|awaiting_review|completed|aborted) ;;
        *) diagnostic INVALID_STATE "$id" "$path" "Unknown execution state: $state" "Use one of the documented execution states" ;;
    esac
    if [ -n "$expected" ] && [ "$mapped" != "$expected" ]; then
        diagnostic INVALID_STATE "$id" "$path" "Mapped board status '$mapped' does not match execution state '$state'" "Use the established pk:tasks status mapping"
    fi
    if [ "$state" = "in_progress" ]; then
        [ "$active" = "$id" ] || diagnostic ACTIVE_TASK_CONFLICT "$id" "$path" "In-progress task does not own its active pointer" "Set Active Task Pointer to this Task ID"
        require_value "$file" "$id" "Start Time"
    elif [ -n "$active" ] && ! is_placeholder "$active"; then
        diagnostic ACTIVE_TASK_CONFLICT "$id" "$path" "Non-active task retains an active pointer" "Clear Active Task Pointer before leaving in_progress"
    fi
    require_value "$file" "$id" "Current Actor"
    require_value "$file" "$id" "Next Action"
    validate_transitions "$file" "$id" "$state"

    local ac_count
    ac_count=$(grep -Ec 'AC-[A-Za-z0-9._-]+' "$file" || true)
    if [ "$ac_count" -eq 0 ]; then
        diagnostic READINESS_FAILURE "$id" "$path" "No stable acceptance criterion ID found" "Add at least one AC-* acceptance criterion"
    fi

    local revision="$(field_value "$file" "Branch / Revision")"
    [ -z "$revision" ] && revision="$(field_value "$file" "Validated Revision")"
    TASK_REVISION_BY_ID["$id"]="$(revision_token "$revision")"

    if [[ "$state" =~ ^(blocked|paused|aborted)$ ]]; then
        local blocker="$(field_value "$file" "Blocker and Resume Condition")"
        if is_placeholder "$blocker"; then
            diagnostic BLOCKER_UNRESOLVED "$id" "$path" "Stop state lacks a blocker or resume condition" "Record the owner, evidence, and precise resume condition"
        fi
    fi
    if [ "$state" = "checkpoint_due" ]; then
        local cp="$(field_value "$file" "Checkpoint Records")"
        if is_placeholder "$cp"; then
            diagnostic CHECKPOINT_INCOMPLETE "$id" "$path" "checkpoint_due task has no checkpoint record reference" "Create and link a checkpoint record before resuming"
        fi
    fi

    local changed_items="$(list_items "$file" "Changed Files")"
    local scope_change="$(field_value "$file" "Scope Change Records")"
    if [ "$state" = "completed" ]; then
        if [ -z "$(trim "$changed_items")" ] || [[ "$changed_items" == *"[path]"* ]]; then
            diagnostic COMPLETION_EVIDENCE_MISSING "$id" "$path" "Completed task has no concrete Changed Files evidence" "List the changed files and summaries"
        fi
        local completion_labels=("Verification Evidence" "CI Evidence" "Review Evidence" "Commit Evidence" "Pull Request Evidence" "Acceptance Results" "Changed-File Summary" "Completion Decision and Timestamp")
        local completion_label completion_value
        for completion_label in "${completion_labels[@]}"; do
            completion_value="$(field_value "$file" "$completion_label")"
            if is_placeholder "$completion_value"; then
                if [ "$completion_label" = "Pull Request Evidence" ] && printf '%s' "$completion_value" | grep -Eiq 'human-confirmed'; then
                    continue
                fi
                diagnostic COMPLETION_EVIDENCE_MISSING "$id" "$path" "Completed task lacks usable $completion_label" "Record observable completion evidence or an explicit approved exception"
            fi
        done
        local completion_state="$(field_value "$file" "Completion State")"
        [ "$completion_state" = "completed" ] || diagnostic COMPLETION_EVIDENCE_MISSING "$id" "$path" "Completion State does not confirm completed" "Set the completion gate only after evidence is linked"
    fi

    if [ -n "$(trim "$changed_items")" ]; then
        while IFS= read -r item; do
            [ -z "$(trim "$item")" ] && continue
            changed_path="$(printf '%s' "$item" | grep -oE '`[^`]+`' | head -n 1 | tr -d '`' || true)"
            [ -z "$changed_path" ] && continue
            if [[ "$in_scope" != *"$changed_path"* ]]; then
                if is_placeholder "$scope_change" || ! printf '%s' "$scope_change" | grep -Eiq 'scope-'; then
                    diagnostic SCOPE_CHANGE_MISSING "$id" "$path" "Changed file '$changed_path' is outside the recorded In Scope boundary" "Link an approved Scope Change Record or keep the change within scope"
                fi
            fi
        done <<< "$changed_items"
    fi

    check_structured_evidence "$file" "$id" "$path"
}

validate_scope_change() {
    local file="$1" id="$(field_value "$1" "Scope Change ID")" path
    path="$(relative_path "$file")"; [ -z "$id" ] && id="UNKNOWN"; RECORD_COUNT=$((RECORD_COUNT + 1))
    is_valid_child_id "$id" || diagnostic INVALID_ID "$id" "$path" "Scope Change ID is not stable: $id" "Use SCOPE-YYYY-MM-DD-task-id-sequence"
    local labels=("Record Type" "Scope Change ID" "Task ID" "Specification" "Proposer / Actor" "Created" "Approval Boundary" "Reason or Discovery" "Current Task Value" "Proposed Value" "Affected Objective" "Affected Files or Artifacts" "Affected Acceptance Criteria" "Affected Dependencies" "New or Changed Non-Goals" "Risk / Estimate Impact" "Changed Verification Condition" "Disposition" "Independent Work Discovered" "Required Human Confirmation" "Required New Task Record" "Block Until Resolved" "Decision" "Approver" "Decision Timestamp" "Approval Evidence" "Related Checkpoint" "Related Handoff" "Branch / Revision" "Verification Plan or Result" "Blocker and Resume Condition" "Previous Task State" "Resulting Task State" "Task Record Updated" "New Task / Exception Links" "Changed Scope Summary" "Next Action" "Recorded By and Timestamp")
    local label
    for label in "${labels[@]}"; do require_label "$file" "$id" "$label"; done
    local value_labels=("Reason or Discovery" "Current Task Value" "Proposed Value" "Affected Objective" "Affected Files or Artifacts" "Affected Acceptance Criteria" "Risk / Estimate Impact" "Changed Verification Condition" "Disposition" "Required Human Confirmation" "Block Until Resolved" "Decision" "Decision Timestamp" "Branch / Revision" "Verification Plan or Result" "Changed Scope Summary" "Next Action" "Recorded By and Timestamp")
    for label in "${value_labels[@]}"; do require_value "$file" "$id" "$label"; done
    [ "$(field_value "$file" "Record Type")" = "Scope Change Record" ] || diagnostic INVALID_STATE "$id" "$path" "Record Type is not Scope Change Record" "Use the canonical Scope Change Record type"
    local task_id="$(field_value "$file" "Task ID")"
    if [ -z "${TASK_FILE_BY_ID[${task_id:-}]+set}" ]; then
        diagnostic TRACEABILITY_MISSING "$id" "$path" "Scope Change Record references unknown Task ID: $task_id" "Link the record to an existing canonical Task Record"
    fi
    local decision="$(field_value "$file" "Decision")"
    if [ "$decision" = "Approved" ]; then
        require_value "$file" "$id" "Approver"
        require_value "$file" "$id" "Approval Evidence"
    fi
    require_value "$file" "$id" "Next Action"
}

validate_checkpoint() {
    local file="$1" id="$(field_value "$1" "Checkpoint ID")" path
    path="$(relative_path "$file")"; [ -z "$id" ] && id="UNKNOWN"; RECORD_COUNT=$((RECORD_COUNT + 1))
    is_valid_child_id "$id" || diagnostic INVALID_ID "$id" "$path" "Checkpoint ID is not stable: $id" "Use CHECKPOINT-YYYY-MM-DD-task-id-sequence"

    local ceremony_level="$(field_value "$file" "Ceremony Level")"
    local parsed_level=""
    case "$ceremony_level" in
        0|[Ll]evel\ 0*|[Ll]0*) parsed_level="0" ;;
        1|[Ll]evel\ 1*|[Ll]1*) parsed_level="1" ;;
        2|[Ll]evel\ 2*|[Ll]2*) parsed_level="2" ;;
        3|[Ll]evel\ 3*|[Ll]3*) parsed_level="3" ;;
    esac

    if [ "$parsed_level" = "0" ]; then
        diagnostic POLICY_LIMITATION "$id" "$path" "Level 0 requests must not write execution-control records to docs/" "Remove Level 0 checkpoint record from docs/tasks"
        return 0
    fi

    local tier="full"
    if [ "$parsed_level" = "1" ]; then
        tier="quick"
    fi

    if [ "$tier" = "quick" ]; then
        HAS_QUICK_RECORD=1
        [ "$(field_value "$file" "Record Type")" = "Checkpoint Record" ] || diagnostic CHECKPOINT_INCOMPLETE "$id" "$path" "Record Type is not Checkpoint Record" "Use the canonical Checkpoint Record type"
        require_value "$file" "$id" "Execution State" "CHECKPOINT_INCOMPLETE"
        require_value "$file" "$id" "Branch / Revision" "CHECKPOINT_INCOMPLETE"
        require_value "$file" "$id" "Next Action" "CHECKPOINT_INCOMPLETE"

        local task_id="$(field_value "$file" "Task ID")"
        local unresolved_count=0

        if [ -z "$task_id" ] || is_placeholder "$task_id"; then
            unresolved_count=$((unresolved_count + 1))
            degradation POLICY_LIMITATION "$id" "$path" "Task ID is unlinked for Level 1 quick checkpoint" "Level 1 does not require a canonical Task Record"
        elif [ -z "${TASK_FILE_BY_ID[$task_id]+set}" ]; then
            unresolved_count=$((unresolved_count + 1))
            degradation POLICY_LIMITATION "$id" "$path" "Task ID '$task_id' has no canonical Task Record (Level 1 quick checkpoint)" "Level 1 does not require a canonical Task Record"
        fi

        local non_core_labels=("Specification" "Created" "Checkpoint Type" "Objective" "Completed Work" "Remaining Work" "Changed Files" "Locked Decisions and Invariants" "Verification Evidence" "CI Evidence" "Blockers" "Scope Changes" "Resume Condition" "Recorded By")
        local label
        for label in "${non_core_labels[@]}"; do
            if [ "$label" = "Changed Files" ] || [ "$label" = "Blockers" ] || [ "$label" = "Scope Changes" ]; then
                if ! field_exists "$file" "$label"; then
                    unresolved_count=$((unresolved_count + 1))
                    degradation POLICY_LIMITATION "$id" "$path" "Unresolved label for Level 1 quick checkpoint: $label" "Full tier requires presence of $label"
                fi
            else
                if ! field_exists "$file" "$label" || is_placeholder "$(field_value "$file" "$label")"; then
                    unresolved_count=$((unresolved_count + 1))
                    degradation POLICY_LIMITATION "$id" "$path" "Unresolved label for Level 1 quick checkpoint: $label" "Full tier requires non-placeholder value"
                fi
            fi
        done
        QUICK_UNRESOLVED_COUNT=$((QUICK_UNRESOLVED_COUNT + unresolved_count))
        return 0
    fi

    local labels=("Record Type" "Checkpoint ID" "Task ID" "Specification" "Created" "Checkpoint Type" "Execution State" "Objective" "Completed Work" "Remaining Work" "Changed Files" "Branch / Revision" "Locked Decisions and Invariants" "Verification Evidence" "CI Evidence" "Blockers" "Scope Changes" "Next Action" "Resume Condition" "Recorded By")
    local label
    for label in "${labels[@]}"; do
        if [ "$label" = "Changed Files" ] || [ "$label" = "Blockers" ] || [ "$label" = "Scope Changes" ]; then
            require_label "$file" "$id" "$label" "CHECKPOINT_INCOMPLETE"
        else
            require_value "$file" "$id" "$label" "CHECKPOINT_INCOMPLETE"
        fi
    done
    [ "$(field_value "$file" "Record Type")" = "Checkpoint Record" ] || diagnostic CHECKPOINT_INCOMPLETE "$id" "$path" "Record Type is not Checkpoint Record" "Use the canonical Checkpoint Record type"
    local task_id="$(field_value "$file" "Task ID")"
    [ -n "$task_id" ] && [ -n "${TASK_FILE_BY_ID[$task_id]+set}" ] || diagnostic TRACEABILITY_MISSING "$id" "$path" "Checkpoint references unknown Task ID: $task_id" "Link the checkpoint to an existing Task Record"
}

validate_handoff() {
    local file="$1" id="$(field_value "$1" "Handoff ID")" path
    path="$(relative_path "$file")"; [ -z "$id" ] && id="UNKNOWN"; RECORD_COUNT=$((RECORD_COUNT + 1))
    is_valid_child_id "$id" || diagnostic INVALID_ID "$id" "$path" "Handoff ID is not stable: $id" "Use HANDOFF-YYYY-MM-DD-task-id-sequence"
    local labels=("Record Type" "Handoff ID" "Task ID" "Specification" "Created" "Sender / Current Owner" "Intended Receiver" "Approval Boundary" "Execution State" "Execution Scope" "Objective" "Completed Milestones" "Remaining Acceptance Criteria" "Blockers and Resume Conditions" "Next Action" "Branch" "Validated Revision" "Changed Files" "Task Record" "Related Scope Changes" "Related Checkpoints" "Related Exceptions" "Verification Commands and Results" "CI Evidence" "Review / Commit / PR Evidence" "Release Evidence" "Locked Decisions" "Non-Negotiable Invariants" "Rejected Approaches" "Scope and Approval Constraints" "Host or Timer Limitations" "Receiver" "Acceptance Decision" "Acceptance Timestamp" "Receiver-Validated Revision" "Validation Evidence" "Scope Changed During Acceptance" "Acceptance Blocker and Resume Condition" "Resulting Execution State" "Task Record Updated" "Handoff Closed By" "Closed Timestamp" "Next Action")
    local label
    for label in "${labels[@]}"; do require_label "$file" "$id" "$label"; done
    local value_labels=("Record Type" "Handoff ID" "Task ID" "Specification" "Created" "Sender / Current Owner" "Intended Receiver" "Approval Boundary" "Execution State" "Execution Scope" "Objective" "Next Action" "Branch" "Validated Revision" "Task Record" "Verification Commands and Results" "Host or Timer Limitations" "Receiver" "Acceptance Decision" "Acceptance Timestamp" "Resulting Execution State" "Task Record Updated" "Handoff Closed By" "Closed Timestamp")
    for label in "${value_labels[@]}"; do require_value "$file" "$id" "$label" "HANDOFF_INCOMPLETE"; done
    [ "$(field_value "$file" "Record Type")" = "Handoff Record" ] || diagnostic HANDOFF_INCOMPLETE "$id" "$path" "Record Type is not Handoff Record" "Use the canonical Handoff Record type"
    local task_id="$(field_value "$file" "Task ID")"
    [ -n "${TASK_FILE_BY_ID[${task_id:-}]+set}" ] || diagnostic TRACEABILITY_MISSING "$id" "$path" "Handoff references unknown Task ID: $task_id" "Link the handoff to an existing Task Record"
    require_value "$file" "$id" "Next Action" "HANDOFF_INCOMPLETE"
    require_value "$file" "$id" "Host or Timer Limitations" "POLICY_LIMITATION"
    local decision="$(field_value "$file" "Acceptance Decision")"
    if [ "$decision" = "Accepted" ]; then
        require_value "$file" "$id" "Receiver-Validated Revision" "HANDOFF_INCOMPLETE"
        require_value "$file" "$id" "Validation Evidence" "HANDOFF_INCOMPLETE"
    fi
}

if [ ! -d "$TASK_DIR" ]; then
    if [ "$STRICT" -eq 1 ]; then
        diagnostic MISSING_FIELD REPOSITORY "docs/tasks" "Canonical Task Source directory is missing" "Create docs/tasks for Controlled Work or omit strict validation when no records are present"
    else
        printf 'VALID|RECORDS=0|ROOT=%s\n' "."
        exit 0
    fi
else
    mapfile -t RECORD_FILES < <(find "$TASK_DIR" -maxdepth 1 -type f -name '*.md' -print | sort)
    for file in "${RECORD_FILES[@]}"; do
        record_type="$(field_value "$file" "Record Type")"
        if [ -z "$record_type" ]; then
            if [ "$STRICT" -eq 1 ]; then
                diagnostic MISSING_FIELD UNKNOWN "$(relative_path "$file")" "Record Type is missing" "Use a recognized execution-control record type or remove the file from docs/tasks"
            fi
            continue
        fi
        [ "$record_type" = "Task Record" ] && validate_task "$file" ""
    done
    for file in "${RECORD_FILES[@]}"; do
        record_type="$(field_value "$file" "Record Type")"
        case "$record_type" in
            "Scope Change Record") validate_scope_change "$file" ;;
            "Checkpoint Record") validate_checkpoint "$file" ;;
            "Handoff Record") validate_handoff "$file" ;;
            "Task Record") ;;
            "") ;;
            *)
                [ "$STRICT" -eq 1 ] && diagnostic INVALID_STATE UNKNOWN "$(relative_path "$file")" "Unknown Record Type: $record_type" "Use Task, Scope Change, Checkpoint, or Handoff Record"
                ;;
        esac
    done

    active_count=0
    for task_id in "${TASK_IDS[@]}"; do
        [ "${TASK_STATE_BY_ID[$task_id]}" = "in_progress" ] && active_count=$((active_count + 1))
    done
    if [ "$active_count" -gt 1 ]; then
        diagnostic ACTIVE_TASK_CONFLICT REPOSITORY "docs/tasks" "More than one Task Record is in_progress" "Leave exactly one active task in the execution scope"
    fi
fi

STATE_FILE="$ROOT/docs/STATE.md"
if [ -f "$STATE_FILE" ]; then
    state_path="$(relative_path "$STATE_FILE")"

    # Validate Markdown table structural integrity and pipe hygiene in STATE.md
    in_code_block=0
    in_table=0
    header_cols=0
    delim_line_index=-1

    state_lines=()
    while IFS= read -r line || [ -n "$line" ]; do
        state_lines+=("${line%$'\r'}")
    done < "$STATE_FILE"

    count_table_cols() {
        local raw="$1"
        local clean="${raw//\\|/__PIPE__}"
        clean="${clean#"${clean%%[![:space:]]*}"}"
        clean="${clean%"${clean##*[![:space:]]}"}"
        clean="${clean#|}"
        clean="${clean%|}"
        local without="${clean//|/}"
        echo $(( ${#clean} - ${#without} + 1 ))
    }

    total_lines="${#state_lines[@]}"
    for ((i=0; i<total_lines; i++)); do
        line_num=$((i + 1))
        line="${state_lines[i]}"

        if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
            in_code_block=$((1 - in_code_block))
            in_table=0
            continue
        fi
        [ "$in_code_block" -eq 1 ] && continue

        is_table_line=0
        [[ "$line" =~ ^[[:space:]]*\|.*\|[[:space:]]*$ ]] && is_table_line=1

        if [ "$in_table" -eq 0 ]; then
            if [ "$is_table_line" -eq 1 ]; then
                next_is_delim=0
                if [ $((i + 1)) -lt "$total_lines" ]; then
                    next_line="${state_lines[i + 1]}"
                    [[ "$next_line" =~ ^[[:space:]]*\|([[:space:]]*:?-+:?[[:space:]]*\|)+[[:space:]]*$ ]] && next_is_delim=1
                fi
                if [ "$next_is_delim" -eq 1 ]; then
                    in_table=1
                    delim_line_index=$((i + 1))
                    header_cols="$(count_table_cols "$line")"
                else
                    diagnostic ORPHANED_TABLE_ROW "STATE" "$state_path" "Table row at line $line_num appears without a preceding table header or delimiter" "Keep table rows contiguous without blank lines, or ensure table has a header and delimiter"
                fi
            fi
        else
            if [ -z "$(echo "$line" | tr -d '[:space:]')" ] || [ "$is_table_line" -eq 0 ]; then
                in_table=0
            elif [ "$i" -eq "$delim_line_index" ]; then
                d_cols="$(count_table_cols "$line")"
                if [ "$d_cols" -ne "$header_cols" ]; then
                    diagnostic TABLE_COLUMN_MISMATCH "STATE" "$state_path" "Table delimiter at line $line_num has $d_cols columns (expected $header_cols)" "Ensure table delimiter matches header column count"
                fi
            else
                r_cols="$(count_table_cols "$line")"
                if [ "$r_cols" -ne "$header_cols" ]; then
                    diagnostic TABLE_COLUMN_MISMATCH "STATE" "$state_path" "Table row at line $line_num has $r_cols columns (expected $header_cols)" "Ensure all cells are on a single line and literal pipes are escaped with \|"
                fi
            fi
        fi
    done

    if grep -Eiq 'Execution-Control Projection|3A\. Execution-Control' "$STATE_FILE"; then
        state_id="$(field_value "$STATE_FILE" "Task ID")"
        [ -n "${TASK_FILE_BY_ID[$state_id]+set}" ] || diagnostic STATE_PROJECTION_MISMATCH "$state_id" "$state_path" "STATE projection references unknown Task ID: $state_id" "Synchronize docs/STATE.md from the canonical Task Record"
        if [ -n "${TASK_FILE_BY_ID[$state_id]+set}" ]; then
            task_file="${TASK_FILE_BY_ID[$state_id]}"
            compare_pairs=("Execution State|Execution State" "Mapped \`pk:tasks\` Status|Mapped \`pk:tasks\` Status" "Active Task Pointer|Active Task Pointer" "Owner / Current Actor|Current Actor")
            for pair in "${compare_pairs[@]}"; do
                IFS='|' read -r state_label task_label <<< "$pair"
                state_value="$(field_value "$STATE_FILE" "$state_label")"
                task_value="$(field_value "$task_file" "$task_label")"
                [ "$state_value" = "$task_value" ] || diagnostic STATE_PROJECTION_MISMATCH "$state_id" "$state_path" "STATE $state_label '$state_value' disagrees with Task Record '$task_value'" "Reconcile the projection without overriding the Task Record"
            done
            state_revision="$(revision_token "$(field_value "$STATE_FILE" "Current Revision")")"
            task_revision="${TASK_REVISION_BY_ID[$state_id]-}"
            if [ -n "$state_revision" ] && [ -n "$task_revision" ] && [ "$state_revision" != "$task_revision" ]; then
                diagnostic REVISION_MISMATCH "$state_id" "$state_path" "STATE revision '$state_revision' disagrees with Task Record revision '$task_revision'" "Use one exact validated revision across linked evidence"
            fi
        fi
    fi
fi

if [ -n "$AUTHORIZATION_BASELINE" ]; then
    auth_output="$(bash "$ROOT/scripts/validate-authorization-evidence.sh" --root "$ROOT" --baseline "$AUTHORIZATION_BASELINE" 2>&1)"
    auth_status=$?
    printf '%s\n' "$auth_output"
    [ "$auth_status" -eq 0 ] || ERROR_COUNT=$((ERROR_COUNT + 1))
fi

if [ "$ERROR_COUNT" -eq 0 ]; then
    for deg in "${DEGRADATIONS[@]}"; do
        printf '%s\n' "$deg"
    done
    if [ "$HAS_QUICK_RECORD" -eq 1 ]; then
        printf 'VALID|RECORDS=%s|TIER=quick|UNRESOLVED=%s|ROOT=%s\n' "$RECORD_COUNT" "$QUICK_UNRESOLVED_COUNT" "."
    else
        printf 'VALID|RECORDS=%s|ROOT=%s\n' "$RECORD_COUNT" "."
    fi
    exit 0
fi
printf 'FAILED|ERRORS=%s|RECORDS=%s\n' "$ERROR_COUNT" "$RECORD_COUNT"
exit 1
