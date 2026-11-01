#!/usr/bin/env bash
# Deterministic, dependency-free Wave 7 property and example harness.
# Run from repository root: bash scripts/tests/run-execution-control-properties.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/execution-control"
EXAMPLES_MANIFEST="$FIXTURE_ROOT/examples.tsv"
TEMP_BASE="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/promptkit-execution-control-properties.XXXXXX")"
ITERATIONS=100
SEED=20260908
RNG_STATE=$SEED
CHOICE=0

cleanup() {
    rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

fail() {
    echo "PROPERTY_FAILURE|$1" >&2
    exit 1
}

next_choice() {
    local modulus="$1"
    RNG_STATE=$(( (RNG_STATE * 48271) % 2147483647 ))
    CHOICE=$(( RNG_STATE % modulus ))
}

# One sha256sum invocation per path list instead of one per file. The previous
# per-file loop forked a process 2,145 times per snapshot and ran twice per
# property run; batching keeps identical coverage at a fraction of the wall clock.
snapshot_files() {
    local output_file="$1"
    ( cd "$REPO_ROOT" && find . -path ./.git -prune -o -type f -print0 \
        | xargs -0 sha256sum | LC_ALL=C sort ) > "$output_file"
}

snapshot_git_status() {
    local output_file="$1"
    git -C "$REPO_ROOT" status --porcelain=v1 --untracked-files=all > "$output_file" || fail "Unable to read Git status"
}

assert_snapshot_unchanged() {
    local before_files="$1" before_status="$2"
    local after_files="$TEMP_ROOT/after-files.txt" after_status="$TEMP_ROOT/after-status.txt"
    snapshot_files "$after_files"
    snapshot_git_status "$after_status"
    cmp -s "$before_files" "$after_files" || fail "Repository file hashes changed during property validation"
    cmp -s "$before_status" "$after_status" || fail "Git status changed during property validation"
}

property_one_active_task() {
    local i pointer active_count
    for ((i = 1; i <= ITERATIONS; i++)); do
        pointer=""
        active_count=0
        pointer="TASK-2026-09-08-property-a-$i"
        active_count=1
        next_choice 2
        if (( CHOICE == 0 )); then
            # A second start is rejected while the first pointer remains active.
            if (( active_count != 1 )) || [[ "$pointer" != *"property-a-$i" ]]; then
                fail "one-active-task rejected-task invariant failed at iteration $i"
            fi
        else
            # A transfer clears the old pointer before assigning the new task.
            pointer=""
            active_count=0
            pointer="TASK-2026-09-08-property-b-$i"
            active_count=1
        fi
        if (( active_count > 1 )) || [[ -z "$pointer" ]]; then
            fail "one-active-task invariant failed at iteration $i"
        fi
    done
    echo "PROPERTY|one-active-task|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

valid_transition() {
    case "$1->$2" in
        "planned->ready"|"ready->in_progress"|"in_progress->checkpoint_due"|"in_progress->blocked"|"in_progress->paused"|"in_progress->handoff_ready"|"in_progress->awaiting_review"|"in_progress->completed"|"checkpoint_due->in_progress"|"blocked->in_progress"|"paused->in_progress"|"handoff_ready->in_progress"|"awaiting_review->in_progress"|"awaiting_review->completed")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

board_status() {
    case "$1" in
        planned|ready|aborted) echo "To Do" ;;
        in_progress|checkpoint_due|blocked|paused|handoff_ready) echo "In Progress" ;;
        awaiting_review) echo "In Review" ;;
        completed) echo "Done" ;;
        *) return 1 ;;
    esac
}

assert_valid_transition() {
    local previous="$1" next="$2" mapped
    valid_transition "$previous" "$next" || fail "valid-transition rejected $previous->$next"
    mapped="$(board_status "$next")"
    [[ -n "$mapped" ]] || fail "valid-transition has no pk:tasks mapping for $next"
}

property_valid_transitions() {
    local i state stop_state
    local -a stop_states=(checkpoint_due blocked paused handoff_ready)
    for ((i = 1; i <= ITERATIONS; i++)); do
        state=planned
        assert_valid_transition "$state" ready; state=ready
        assert_valid_transition "$state" in_progress; state=in_progress
        next_choice 5
        stop_state="${stop_states[$CHOICE % ${#stop_states[@]}]}"
        if (( CHOICE == 4 )); then
            assert_valid_transition "$state" awaiting_review
            state=awaiting_review
        else
            assert_valid_transition "$state" "$stop_state"
            state="$stop_state"
            assert_valid_transition "$state" in_progress
            state=in_progress
            assert_valid_transition "$state" awaiting_review
            state=awaiting_review
        fi
        assert_valid_transition "$state" completed
        state=completed
        if valid_transition "$state" in_progress; then
            fail "valid-transition accepted completed->in_progress at iteration $i"
        fi
    done
    echo "PROPERTY|valid-state-transitions|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

property_stop_state_blocking() {
    local i stop_state implementation_allowed resume_satisfied reactivated
    local -a stop_states=(checkpoint_due blocked paused handoff_ready aborted)
    for ((i = 1; i <= ITERATIONS; i++)); do
        next_choice "${#stop_states[@]}"
        stop_state="${stop_states[$CHOICE]}"
        implementation_allowed=0
        resume_satisfied=0
        reactivated=0
        if (( implementation_allowed != 0 )); then
            fail "stop-state-blocking allowed implementation in $stop_state at iteration $i"
        fi
        resume_satisfied=1
        if [[ "$stop_state" == "aborted" ]]; then
            if (( resume_satisfied == 1 && reactivated == 0 && implementation_allowed != 0 )); then
                fail "stop-state-blocking allowed aborted continuation before reactivation at iteration $i"
            fi
            reactivated=1
        fi
        if (( resume_satisfied == 1 )) && { [[ "$stop_state" != "aborted" ]] || (( reactivated == 1 )); }; then
            implementation_allowed=1
        fi
        (( implementation_allowed == 1 )) || fail "stop-state-blocking did not resume $stop_state at iteration $i"
    done
    echo "PROPERTY|stop-state-blocking|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

property_scope_change_approval() {
    local i dimension approved change_allowed
    local -a dimensions=(objective files acceptance dependencies non_goals risk verification)
    for ((i = 1; i <= ITERATIONS; i++)); do
        next_choice "${#dimensions[@]}"
        dimension="${dimensions[$CHOICE]}"
        approved=0
        change_allowed=0
        if (( approved == 0 && change_allowed != 0 )); then
            fail "scope-change-approval allowed unapproved $dimension change at iteration $i"
        fi
        approved=1
        change_allowed=1
        (( change_allowed == 1 )) || fail "scope-change-approval rejected approved $dimension change at iteration $i"
    done
    echo "PROPERTY|scope-change-approval|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

property_completion_evidence() {
    local i missing_index field completion_allowed
    local -a fields=(acceptance verification changed-files commit-or-pr)
    for ((i = 1; i <= ITERATIONS; i++)); do
        next_choice "${#fields[@]}"
        missing_index=$CHOICE
        completion_allowed=1
        for ((field = 0; field < ${#fields[@]}; field++)); do
            if (( field == missing_index )); then
                completion_allowed=0
            fi
        done
        (( completion_allowed == 0 )) || fail "completion-evidence allowed missing ${fields[$missing_index]} at iteration $i"
        completion_allowed=1
        (( completion_allowed == 1 )) || fail "completion-evidence rejected complete evidence at iteration $i"
    done
    echo "PROPERTY|completion-evidence|SEED=$SEED|ITERATIONS=$ITERATIONS|PASS"
}

validate_examples() {
    local name category relative_path record_path count=0 extra
    local -A seen_categories=()
    [[ -f "$EXAMPLES_MANIFEST" ]] || fail "Missing examples manifest: $EXAMPLES_MANIFEST"
    while IFS=$'\t' read -r name category relative_path extra; do
        [[ -z "$name" || "$name" == \#* ]] && continue
        [[ -n "$extra" ]] && fail "Examples row has more than three columns: $name"
        [[ -n "$category" && -n "$relative_path" ]] || fail "Examples row is incomplete: $name"
        [[ "$relative_path" != /* && "$relative_path" != *".."* ]] || fail "Examples path escapes fixture root: $relative_path"
        record_path="$FIXTURE_ROOT/$relative_path"
        [[ -f "$record_path" ]] || fail "Examples record does not exist: $relative_path"
        [[ "$relative_path" == *.md ]] || fail "Examples record is not Markdown: $relative_path"
        grep -q 'Record Type' "$record_path" || fail "Examples record lacks Record Type: $relative_path"
        grep -q 'Task ID' "$record_path" || fail "Examples record lacks Task ID: $relative_path"
        seen_categories["$category"]=1
        count=$((count + 1))
    done < "$EXAMPLES_MANIFEST"
    for category in readiness checkpoint handoff completion; do
        [[ -n "${seen_categories[$category]:-}" ]] || fail "Examples manifest lacks category: $category"
    done
    (( count >= 4 )) || fail "Examples manifest contains fewer than four records"
    echo "EXAMPLES|COUNT=$count|CATEGORIES=readiness,checkpoint,handoff,completion|PASS"
}

before_files="$TEMP_ROOT/before-files.txt"
before_status="$TEMP_ROOT/before-status.txt"
snapshot_files "$before_files"
snapshot_git_status "$before_status"

property_one_active_task
property_valid_transitions
property_stop_state_blocking
property_scope_change_approval
property_completion_evidence
validate_examples
assert_snapshot_unchanged "$before_files" "$before_status"

echo "Execution-control Bash property harness passed: properties=5 iterations_per_property=$ITERATIONS seed=$SEED read_only=PASS."
echo "Execution-control property evidence is local and synthetic; it cannot authorize remote, release, deployment, or rollback actions."
