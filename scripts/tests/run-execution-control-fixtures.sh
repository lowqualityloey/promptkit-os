#!/usr/bin/env bash
# Cross-platform fixture harness for the read-only execution-control validator.
# Run from repository root: bash scripts/tests/run-execution-control-fixtures.sh

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/execution-control"
VALIDATOR="$REPO_ROOT/scripts/validate-execution-control.sh"
VALID_ROOT="$FIXTURE_ROOT/valid"
INVALID_ROOT="$FIXTURE_ROOT/invalid"
CASE_ROOT="$FIXTURE_ROOT/cases"
IMPORT_ROOT="$FIXTURE_ROOT/imports"
EXPECTED_VALID="$FIXTURE_ROOT/expected-valid.txt"
EXPECTED_INVALID="$FIXTURE_ROOT/expected-invalid.txt"
EXPECTED_INVALID_SUMMARY="$FIXTURE_ROOT/expected-invalid-summary.txt"
EXPECTED_CASES="$FIXTURE_ROOT/expected/cases.tsv"
EXPECTED_IMPORTS="$FIXTURE_ROOT/expected/imports.tsv"
TEMP_BASE="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/promptkit-execution-control.XXXXXX")"

cleanup() {
    rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

fail() {
    echo "HARNESS_FAILURE|$1" >&2
    exit 1
}

snapshot_files() {
    local output_file="$1"
    : > "$output_file"
    while IFS= read -r file; do
        printf '%s|' "${file#"$REPO_ROOT"/}" >> "$output_file"
        sha256sum "$file" >> "$output_file"
    done < <(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type f -print | sort)
}

snapshot_git_status() {
    local output_file="$1"
    git -C "$REPO_ROOT" status --porcelain=v1 --untracked-files=all > "$output_file" || fail "Unable to read Git status"
}

assert_snapshot_unchanged() {
    local before_files="$1" before_status="$2" label="$3"
    local after_files="$TEMP_ROOT/${label}-after-files.txt"
    local after_status="$TEMP_ROOT/${label}-after-status.txt"
    snapshot_files "$after_files"
    snapshot_git_status "$after_status"
    cmp -s "$before_files" "$after_files" || fail "Repository file hashes changed during $label validation"
    cmp -s "$before_status" "$after_status" || fail "Git status changed during $label validation"
}

normalize_output() {
    local input_file="$1" output_file="$2"
    tr -d '\r' < "$input_file" | sed 's#\\#/#g' > "$output_file"
}

assert_case() {
    local name="$1" root="$2" expected_exit="$3"
    local output_file="$TEMP_ROOT/${name}.output"
    local normalized_file="$TEMP_ROOT/${name}.normalized"
    local actual_exit

    set +e
    bash "$VALIDATOR" --root "$root" --strict > "$output_file" 2>&1
    actual_exit=$?
    set -e
    [ "$actual_exit" -eq "$expected_exit" ] || fail "$name expected exit $expected_exit but received $actual_exit"

    normalize_output "$output_file" "$normalized_file"
    if [ "$name" = "valid" ]; then
        local expected_summary
        expected_summary="$(tr -d '\r\n' < "$EXPECTED_VALID")"
        local actual_summary
        actual_summary="$(grep -E '^(VALID|FAILED)\|' "$normalized_file" | tail -n 1 || true)"
        [ "$actual_summary" = "$expected_summary" ] || fail "valid summary mismatch: $actual_summary"
        [ "$(grep -Ec '^(VALID|FAILED)\|' "$normalized_file" || true)" -eq 1 ] || fail "valid case emitted an unexpected summary count"
    else
        local expected_failure_summary actual_failure_summary
        expected_failure_summary="$(tr -d '\r\n' < "$EXPECTED_INVALID_SUMMARY")"
        actual_failure_summary="$(grep -E '^FAILED\|' "$normalized_file" | tail -n 1 || true)"
        [ "$actual_failure_summary" = "$expected_failure_summary" ] || fail "invalid summary mismatch: $actual_failure_summary"
        local expected_diagnostics actual_diagnostics
        expected_diagnostics="$(sort "$EXPECTED_INVALID")"
        actual_diagnostics="$(grep -E '^[A-Z_]+\|' "$normalized_file" | grep -vE '^(VALID|FAILED)\|' | sort || true)"
        [ "$actual_diagnostics" = "$expected_diagnostics" ] || {
            echo "Expected diagnostics:" >&2
            printf '%s\n' "$expected_diagnostics" >&2
            echo "Actual diagnostics:" >&2
            printf '%s\n' "$actual_diagnostics" >&2
            fail "invalid diagnostic contract mismatch"
        }
    fi
}

assert_matrix_case() {
    local name="$1" root="$2" expected_exit="$3" expected_summary_file="$4" expected_diagnostics_file="$5"
    local output_file="$TEMP_ROOT/${name}.output"
    local normalized_file="$TEMP_ROOT/${name}.normalized"
    local actual_exit

    set +e
    bash "$VALIDATOR" --root "$root" --strict > "$output_file" 2>&1
    actual_exit=$?
    set -e
    [ "$actual_exit" -eq "$expected_exit" ] || fail "$name expected exit $expected_exit but received $actual_exit"

    normalize_output "$output_file" "$normalized_file"
    local expected_summary actual_summary
    expected_summary="$(tr -d '\r\n' < "$expected_summary_file")"
    actual_summary="$(grep -E '^(VALID|FAILED)\|' "$normalized_file" | tail -n 1 || true)"
    [ "$actual_summary" = "$expected_summary" ] || fail "$name summary mismatch: $actual_summary"
    [ "$(grep -Ec '^(VALID|FAILED)\|' "$normalized_file" || true)" -eq 1 ] || fail "$name emitted an unexpected summary count"

    local expected_diagnostics="" actual_diagnostics=""
    if [ -s "$expected_diagnostics_file" ]; then
        expected_diagnostics="$(sort "$expected_diagnostics_file")"
    fi
    actual_diagnostics="$(grep -E '^[A-Z_]+\|' "$normalized_file" | grep -vE '^(VALID|FAILED)\|' | sort || true)"
    [ "$actual_diagnostics" = "$expected_diagnostics" ] || {
        echo "Expected diagnostics for $name:" >&2
        printf '%s\n' "$expected_diagnostics" >&2
        echo "Actual diagnostics for $name:" >&2
        printf '%s\n' "$actual_diagnostics" >&2
        fail "$name diagnostic contract mismatch"
    }
}

# Import-matrix case: run the foreign /handoff importer against a fixture root
# and pin its IMPORT-DRAFT verdict plus the TRACEABILITY_MISSING / unresolved
# contract. The importer must stay read-only and must never synthesize a Task ID.
assert_import_case() {
    local name="$1" root="$2" expect_trace="$3" expect_task_line="$4"
    local draft_expected_file="$5" unresolved_expected_file="$6"
    local payload_file="$IMPORT_ROOT/${name}.txt"
    local output_file="$TEMP_ROOT/import-${name}.output"
    local normalized_file="$TEMP_ROOT/import-${name}.normalized"
    local actual_exit

    [ -f "$payload_file" ] || fail "Missing import payload: $payload_file"

    set +e
    bash "$VALIDATOR" --root "$root" --import "$payload_file" > "$output_file" 2>&1
    actual_exit=$?
    set -e
    [ "$actual_exit" -eq 0 ] || fail "import $name expected exit 0 but received $actual_exit"

    normalize_output "$output_file" "$normalized_file"

    local expected_draft actual_draft
    expected_draft="$(tr -d '\r\n' < "$draft_expected_file")"
    actual_draft="$(grep -E '^IMPORT-DRAFT\|' "$normalized_file" | tail -n 1 || true)"
    [ "$actual_draft" = "IMPORT-DRAFT|$expected_draft" ] || fail "import $name draft mismatch: $actual_draft (expected IMPORT-DRAFT|$expected_draft)"

    local trace_count
    trace_count="$(grep -Ec '^TRACEABILITY_MISSING\|' "$normalized_file" || true)"
    if [ "$expect_trace" = "yes" ]; then
        [ "$trace_count" -ge 1 ] || fail "import $name expected TRACEABILITY_MISSING but none was emitted"
    else
        [ "$trace_count" -eq 0 ] || fail "import $name expected no TRACEABILITY_MISSING but received $trace_count"
    fi

    # No fabricated task identity: the draft only carries a Task ID line when the
    # payload supplied an ID that resolved in TASK_FILE_BY_ID.
    local task_line_count
    task_line_count="$(grep -Ec '^- \*\*Task ID\*\*:' "$normalized_file" || true)"
    if [ "$expect_task_line" = "yes" ]; then
        [ "$task_line_count" -eq 1 ] || fail "import $name expected one resolved Task ID draft line but found $task_line_count"
    else
        [ "$task_line_count" -eq 0 ] || fail "import $name emitted a synthesized or unresolved Task ID draft line ($task_line_count)"
    fi

    if [ "$unresolved_expected_file" != "-" ]; then
        [ -f "$unresolved_expected_file" ] || fail "Missing import unresolved expectation: $unresolved_expected_file"
        local expected_unresolved actual_unresolved
        expected_unresolved="$(tr -d '\r\n' < "$unresolved_expected_file")"
        actual_unresolved="$(grep -E '^IMPORT-UNRESOLVED\|' "$normalized_file" | tail -n 1 || true)"
        [ "$actual_unresolved" = "$expected_unresolved" ] || fail "import $name unresolved mismatch: $actual_unresolved (expected $expected_unresolved)"
    fi
}

[ -x "$VALIDATOR" ] || fail "Bash validator is not executable: $VALIDATOR"
[ -d "$VALID_ROOT" ] || fail "Missing valid fixture root: $VALID_ROOT"
[ -d "$INVALID_ROOT" ] || fail "Missing invalid fixture root: $INVALID_ROOT"
[ -d "$CASE_ROOT" ] || fail "Missing isolated case root: $CASE_ROOT"
[ -d "$IMPORT_ROOT" ] || fail "Missing import payload root: $IMPORT_ROOT"
[ -f "$EXPECTED_VALID" ] || fail "Missing expected valid result: $EXPECTED_VALID"
[ -f "$EXPECTED_INVALID" ] || fail "Missing expected invalid diagnostics: $EXPECTED_INVALID"
[ -f "$EXPECTED_INVALID_SUMMARY" ] || fail "Missing expected invalid summary: $EXPECTED_INVALID_SUMMARY"
[ -f "$EXPECTED_CASES" ] || fail "Missing isolated case manifest: $EXPECTED_CASES"
[ -f "$EXPECTED_IMPORTS" ] || fail "Missing import manifest: $EXPECTED_IMPORTS"

before_files="$TEMP_ROOT/before-files.txt"
before_status="$TEMP_ROOT/before-status.txt"
snapshot_files "$before_files"
snapshot_git_status "$before_status"
assert_case valid "$VALID_ROOT" 0
assert_snapshot_unchanged "$before_files" "$before_status" valid

before_invalid_files="$TEMP_ROOT/before-invalid-files.txt"
before_invalid_status="$TEMP_ROOT/before-invalid-status.txt"
snapshot_files "$before_invalid_files"
snapshot_git_status "$before_invalid_status"
assert_case invalid "$INVALID_ROOT" 1
assert_snapshot_unchanged "$before_invalid_files" "$before_invalid_status" invalid

while IFS=$'\t' read -r name expected_exit expected_summary expected_diagnostics; do
    [ -n "$name" ] || continue
    case_root="$CASE_ROOT/$name"
    summary_file="$FIXTURE_ROOT/expected/$expected_summary"
    diagnostics_file="$FIXTURE_ROOT/expected/$expected_diagnostics"
    [ -d "$case_root" ] || fail "Missing matrix case root: $case_root"
    [ -f "$summary_file" ] || fail "Missing matrix summary: $summary_file"
    [ -f "$diagnostics_file" ] || fail "Missing matrix diagnostics: $diagnostics_file"
    before_case_files="$TEMP_ROOT/${name}-before-files.txt"
    before_case_status="$TEMP_ROOT/${name}-before-status.txt"
    snapshot_files "$before_case_files"
    snapshot_git_status "$before_case_status"
    assert_matrix_case "$name" "$case_root" "$expected_exit" "$summary_file" "$diagnostics_file"
    assert_snapshot_unchanged "$before_case_files" "$before_case_status" "$name"
done < "$EXPECTED_CASES"

import_count=0
while IFS=$'\t' read -r name root expect_trace expect_task_line draft_expected unresolved_expected; do
    [ -n "$name" ] || continue
    case "$name" in \#*) continue ;; esac
    import_root="$FIXTURE_ROOT/$root"
    [ -d "$import_root" ] || fail "Missing import fixture root: $import_root"
    draft_expected_file="$FIXTURE_ROOT/expected/$draft_expected"
    [ -f "$draft_expected_file" ] || fail "Missing import draft expectation: $draft_expected_file"
    if [ "$unresolved_expected" = "-" ]; then
        unresolved_expected_file="-"
    else
        unresolved_expected_file="$FIXTURE_ROOT/expected/$unresolved_expected"
    fi
    before_import_files="$TEMP_ROOT/import-${name}-before-files.txt"
    before_import_status="$TEMP_ROOT/import-${name}-before-status.txt"
    snapshot_files "$before_import_files"
    snapshot_git_status "$before_import_status"
    assert_import_case "$name" "$import_root" "$expect_trace" "$expect_task_line" "$draft_expected_file" "$unresolved_expected_file"
    assert_snapshot_unchanged "$before_import_files" "$before_import_status" "import-${name}"
    import_count=$((import_count + 1))
done < "$EXPECTED_IMPORTS"

echo "Execution-control Bash matrix cases passed: $(grep -c '^[^#[:space:]]' "$EXPECTED_CASES") isolated contracts."
echo "Execution-control Bash import cases passed: $import_count /handoff import-draft contracts (tier|unresolved|verdict pinned)."
echo "CI evidence: provider=${GITHUB_ACTIONS:-local} workflow=${GITHUB_WORKFLOW:-local} job=${GITHUB_JOB:-local} run=${GITHUB_RUN_ID:-local} revision=${GITHUB_SHA:-local} timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Execution-control validation is durable evidence only; it cannot observe live chat duration or approve external actions."
echo "Execution-control Bash fixture harness passed: regression and isolated matrix contracts are stable and read-only."
