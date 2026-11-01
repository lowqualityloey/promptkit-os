#!/usr/bin/env bash
# Cross-platform fixture harness for the read-only CI triage validator.
# Run from repository root: bash scripts/tests/run-ci-triage-fixtures.sh

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/ci-triage"
VALIDATOR="$REPO_ROOT/scripts/validate-ci-triage.sh"
TEMP_BASE="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/promptkit-ci-triage.XXXXXX")"

cleanup() { rm -rf "$TEMP_ROOT"; }
trap cleanup EXIT
fail() { echo "HARNESS_FAILURE|$1" >&2; exit 1; }

# One sha256sum invocation per path list instead of one per file. The previous
# per-file loop forked a process 2,145 times per snapshot on this repository and
# ran twice per fixture case; batching keeps identical coverage at a fraction of
# the wall clock.
snapshot_files() {
    local output_file="$1"
    ( cd "$REPO_ROOT" && find . -path ./.git -prune -o -type f -print0 \
        | xargs -0 sha256sum | LC_ALL=C sort ) > "$output_file"
}

snapshot_status() { git -C "$REPO_ROOT" status --porcelain=v1 --untracked-files=all > "$1" || fail "Unable to read Git status"; }
assert_unchanged() {
    local before_files="$1" before_status="$2" label="$3" after_files after_status
    after_files="$TEMP_ROOT/$label-after-files"; after_status="$TEMP_ROOT/$label-after-status"
    snapshot_files "$after_files"; snapshot_status "$after_status"
    cmp -s "$before_files" "$after_files" || fail "Repository file hashes changed during $label validation"
    cmp -s "$before_status" "$after_status" || fail "Git status changed during $label validation"
}

assert_diagnostics() {
    local output="$1" expected="$2" actual normalized_expected
    actual="$(grep -vE '^(VALID|FAILED)\|' "$output" || true)"
    if [ "$expected" = '-' ]; then
        [ -z "$actual" ] || { cat "$output" >&2; fail "Unexpected diagnostics in valid case"; }
        return
    fi
    actual="$(printf '%s\n' "$actual" | LC_ALL=C sort -f)"
    normalized_expected="$(printf '%s\n' "$expected" | sed 's/;;/\n/g' | LC_ALL=C sort -f)"
    [ "$actual" = "$normalized_expected" ] || { cat "$output" >&2; fail "Complete normalized diagnostic set did not match the shared contract"; }
}

run_case() {
    local name="$1" root="$2" expected_exit="$3" expected_summary="$4" expected_diagnostics="$5"
    local output="$TEMP_ROOT/$name.output" actual_exit
    set +e
    bash "$VALIDATOR" --root "$root" --strict > "$output" 2>&1
    actual_exit=$?
    set -e
    [ "$actual_exit" -eq "$expected_exit" ] || { cat "$output" >&2; fail "$name expected exit $expected_exit but received $actual_exit"; }
    grep -Fqx "$expected_summary" "$output" || { cat "$output" >&2; fail "$name did not contain the exact expected summary $expected_summary"; }
    assert_diagnostics "$output" "$expected_diagnostics"
}

[ -f "$VALIDATOR" ] || fail "Missing CI triage Bash validator"
[ -d "$FIXTURE_ROOT/valid" ] || fail "Missing valid CI triage fixture root"
[ -d "$FIXTURE_ROOT/invalid" ] || fail "Missing invalid CI triage fixture root"
[ -f "$FIXTURE_ROOT/expected/cases.tsv" ] || fail "Missing CI triage case manifest"

all_before_status="$TEMP_ROOT/all-before-status"; snapshot_status "$all_before_status"
before_files="$TEMP_ROOT/valid-before-files"; before_status="$TEMP_ROOT/valid-before-status"; snapshot_files "$before_files"; snapshot_status "$before_status"; run_case valid "$FIXTURE_ROOT/valid" 0 'VALID|RECORDS=1|ROOT=.' '-'; assert_unchanged "$before_files" "$before_status" valid
before_files="$TEMP_ROOT/invalid-before-files"; before_status="$TEMP_ROOT/invalid-before-status"; snapshot_files "$before_files"; snapshot_status "$before_status"; run_case invalid "$FIXTURE_ROOT/invalid" 1 'FAILED|ERRORS=7|RECORDS=1' 'INVALID_TRANSITION|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Invalid CI transition: evidence_requested -> classified|Follow the evidence-first state graph and conditional action branch;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Check Identity|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Configuration Context|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Execution Time|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Failed Job or Command|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Failure Output|Provide a non-placeholder value for the required field;;MISSING_FIELD|CI-github-200|docs/releases/ci-triage/CI-github-200.md|Missing usable value: Revision Identifier|Provide a non-placeholder value for the required field'; assert_unchanged "$before_files" "$before_status" invalid

case_count=0
while IFS=$'\t' read -r name expected_exit expected_summary expected_diagnostics; do
    [ -n "$name" ] || continue
    [[ "$name" = \#* ]] && continue
    [ -n "$expected_diagnostics" ] || fail "Missing diagnostic contract for case $name"
    case_root="$FIXTURE_ROOT/cases/$name"
    [ -d "$case_root" ] || fail "Missing case root: $case_root"
    before_files="$TEMP_ROOT/$name-before-files"; before_status="$TEMP_ROOT/$name-before-status"; snapshot_files "$before_files"; snapshot_status "$before_status"; run_case "$name" "$case_root" "$expected_exit" "$expected_summary" "$expected_diagnostics"; assert_unchanged "$before_files" "$before_status" "$name"
    case_count=$((case_count + 1))
done < "$FIXTURE_ROOT/expected/cases.tsv"

after_all_status="$TEMP_ROOT/all-after-status"; snapshot_status "$after_all_status"; cmp -s "$all_before_status" "$after_all_status" || fail 'Git status changed during CI triage fixture validation'

# Locale invariance regression guard.
#
# Placeholder detection recognises typographic dashes such as "N/A — reason".
# A multi-byte character inside an ERE bracket expression degrades to a set of
# raw bytes under a non-UTF-8 locale, which silently changes the diagnostic
# set. Assert the contract under the C locale, and compare against a UTF-8
# locale when the host offers one.
locale_guard_case="unicode-placeholder"
locale_guard_root="$FIXTURE_ROOT/cases/$locale_guard_case"
[ -d "$locale_guard_root" ] || fail "Missing locale regression case: $locale_guard_root"
locale_guard_expected="$(awk -F'\t' -v c="$locale_guard_case" '$1 == c { print $3 }' "$FIXTURE_ROOT/expected/cases.tsv")"
[ -n "$locale_guard_expected" ] || fail "Missing expected summary for locale regression case $locale_guard_case"

set +e
LC_ALL=C bash "$VALIDATOR" --root "$locale_guard_root" --strict > "$TEMP_ROOT/locale-c.output" 2>&1
set -e
grep -Fqx "$locale_guard_expected" "$TEMP_ROOT/locale-c.output" || { cat "$TEMP_ROOT/locale-c.output" >&2; fail "Locale regression: LC_ALL=C did not reproduce the expected summary $locale_guard_expected"; }

locale_guard_utf8=""
for locale_guard_candidate in C.UTF-8 C.utf8 en_US.UTF-8; do
    if [ -z "$(LC_ALL="$locale_guard_candidate" bash -c : 2>&1)" ]; then locale_guard_utf8="$locale_guard_candidate"; break; fi
done

if [ -n "$locale_guard_utf8" ]; then
    set +e
    LC_ALL="$locale_guard_utf8" bash "$VALIDATOR" --root "$locale_guard_root" --strict > "$TEMP_ROOT/locale-utf8.output" 2>&1
    set -e
    cmp -s "$TEMP_ROOT/locale-c.output" "$TEMP_ROOT/locale-utf8.output" || { diff -u "$TEMP_ROOT/locale-c.output" "$TEMP_ROOT/locale-utf8.output" >&2 || true; fail "Locale regression: validator output differs between LC_ALL=C and LC_ALL=$locale_guard_utf8"; }
    echo "Locale invariance verified for $locale_guard_case across LC_ALL=C and LC_ALL=$locale_guard_utf8."
else
    echo "Locale invariance verified for $locale_guard_case under LC_ALL=C; no UTF-8 locale is available on this host to compare against."
fi

echo "CI triage Bash matrix cases passed: $case_count isolated contracts."
echo "CI triage validation is deterministic, network-free, and read-only; it cannot execute remote actions or approve release resumption."
echo "CI triage Bash fixture harness passed: complete normalized diagnostic contracts cover state, action, blocked/resume, and release-handoff behavior."
