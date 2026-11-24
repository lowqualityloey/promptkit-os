#!/usr/bin/env bash
# Local example/schema checks for release-record evidence.
# Run from repository root: bash scripts/tests/release-records.examples.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALID_ROOT="$REPO_ROOT/scripts/tests/fixtures/release-records/valid"
DEFERRED_ROOT="$REPO_ROOT/scripts/tests/fixtures/release-records/empty-range-deferred"
VALIDATOR="$REPO_ROOT/scripts/validate-release-records.sh"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/release-records"
PROPERTY_HARNESS="$REPO_ROOT/scripts/tests/run-release-record-properties.sh"

fail_example() {
    echo "EXAMPLE_FAILURE|$1" >&2
    exit 1
}

assert_file_text() {
    local file="$1" text="$2"
    grep -Fq "$text" "$file" || fail_example "Missing '$text' in $file"
}

run_invalid_validator_case() {
    local case_name="$1" expected_category="$2" output
    if output="$(bash "$VALIDATOR" --root "$REPO_ROOT/scripts/tests/fixtures/release-records/cases/$case_name" --strict 2>&1)"; then
        fail_example "$case_name unexpectedly passed"
    fi
    [[ "$output" == *"$expected_category"* ]] || fail_example "$case_name did not emit $expected_category"
}

assert_file_text "$REPO_ROOT/workflows/commit.md" "Conventional Commit"
assert_file_text "$REPO_ROOT/workflows/checkpoint.md" "checkpoint"
assert_file_text "$REPO_ROOT/workflows/ship.md" "release"

declare -a documentation_examples=(
    $'commit-contract|workflows/commit.md|Contract Impact Evidence|Proposed SemVer Candidate Impact'
    $'commit-blocked|workflows/commit.md|blocked|evidence'
    $'checkpoint-candidate|workflows/checkpoint.md|Preliminary SemVer Candidate|Requested Release Coordinator Decision'
    $'checkpoint-blocked|workflows/checkpoint.md|Unresolved Blockers|Handoff Status'
    $'ship-record|workflows/ship.md|Approved Release Record|Draft Changelog Entries'
    $'ship-blocked|workflows/ship.md|unresolved blocker|unapproved'
    $'qa-rereview|workflows/ship.md|correction/re-review|Blocker review'
    $'approval-alignment|workflows/ship.md|Approved Release Tag|Approved Release Version'
    $'note-coverage|workflows/ship.md|Public Release Notes|exactly one'
    $'no-side-effect|workflows/ship.md|External-action decisions|must not automatically run tag commands'
)
for example in "${documentation_examples[@]}"; do
    IFS='|' read -r name file requirement evidence <<< "$example"
    [[ -n "$name" && -n "$file" && -n "$requirement" && -n "$evidence" ]] || fail_example "Malformed documentation example"
    grep -Fqi "$requirement" "$REPO_ROOT/$file" || fail_example "Missing documentation requirement '$requirement'"
    grep -Fqi "$evidence" "$REPO_ROOT/$file" || fail_example "Missing documentation evidence '$evidence'"
done
echo "EXAMPLE|documentation-handoffs-and-schemas|PASS"

bash "$VALIDATOR" --root "$VALID_ROOT" --strict >/dev/null
bash "$VALIDATOR" --root "$DEFERRED_ROOT" --strict >/dev/null
echo "EXAMPLE|valid-and-empty-range-controls|PASS"

run_invalid_validator_case missing-field MISSING_FIELD
run_invalid_validator_case candidate-not-in-range RANGE_MEMBERSHIP
run_invalid_validator_case approval-missing APPROVAL_REQUIRED
run_invalid_validator_case tag-version-mismatch TAG_VERSION_MISMATCH
run_invalid_validator_case precedence-regression VERSION_PRECEDENCE
run_invalid_validator_case evaluation-id-mismatch EVALUATION_ID_MISMATCH
run_invalid_validator_case qa-note-linkage QA_NOTE_LINKAGE
run_invalid_validator_case empty-range-no-decision EMPTY_RANGE_DECISION
run_invalid_validator_case breaking-guidance-missing BREAKING_GUIDANCE_MISSING
run_invalid_validator_case outcome-section-not-terminal OUTCOME_SECTION
echo "EXAMPLE|malformed-validator-diagnostics|PASS"

property_output="$(PROMPTKIT_PROPERTY_ITERATIONS=1 bash "$PROPERTY_HARNESS" 2>&1)" || fail_example "paired property harness control failed"
for property_name in history-normalization-effective-set exact-once-unpublished-notes cross-record-read-only-consistency; do
    printf '%s\n' "$property_output" | grep -Eq "^PROPERTY\\|$property_name\\|.*\\|PASS$" || fail_example "Property control did not pass: $property_name"
done
grep -Fq 'expected.effective' "$FIXTURE_ROOT/property-08.tsv" || fail_example 'Normalized effective fixture expectation missing'
echo "EXAMPLE|mixed-history-shared-normalized-set|PASS"

grep -Fq 'CREATE_TAG' "$FIXTURE_ROOT/property-12.tsv" || fail_example 'CREATE_TAG request fixture missing'
grep -Fq 'record_action_request' "$PROPERTY_HARNESS" || fail_example 'Action request boundary missing'
grep -Fq 'CONSISTENCY_ACTION_LOG=NONE' "$PROPERTY_HARNESS" || fail_example 'Read-only action log boundary missing'
echo "EXAMPLE|external-action-request-is-data-only|PASS"

echo "Release-record Bash example checks passed: examples=5 read_only=PASS."
echo "Release-record examples are local and synthetic; they cannot authorize tags, releases, publication, remotes, deployment, or rollback actions."
