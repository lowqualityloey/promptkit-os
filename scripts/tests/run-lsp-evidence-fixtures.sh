#!/usr/bin/env bash
# Cross-platform fixture harness for the read-only LSP evidence validator.
# Run from repository root: bash scripts/tests/run-lsp-evidence-fixtures.sh

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/lsp-evidence"
VALIDATOR="$REPO_ROOT/scripts/validate-lsp-evidence.sh"
DIFF="$FIXTURE_ROOT/baseline.diff"

TEMP_BASE="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/promptkit-lsp-evidence.XXXXXX")"
cleanup() { rm -rf "$TEMP_ROOT"; }
trap cleanup EXIT
fail() { echo "HARNESS_FAILURE|$1" >&2; exit 1; }

run_case() {
    local case_dir="$1" out_file="$2" status_file="$3"
    bash "$VALIDATOR" --root "$case_dir" --diff-file "$DIFF" > "$out_file" 2>&1
    printf '%s' "$?" > "$status_file"
}

run_case "$FIXTURE_ROOT/valid" "$TEMP_ROOT/out-valid" "$TEMP_ROOT/status-valid"
run_case "$FIXTURE_ROOT/invalid-hallucinated" "$TEMP_ROOT/out-hallucinated" "$TEMP_ROOT/status-hallucinated"
run_case "$FIXTURE_ROOT/invalid-out-of-range" "$TEMP_ROOT/out-out-of-range" "$TEMP_ROOT/status-out-of-range"
run_case "$FIXTURE_ROOT/not-measured" "$TEMP_ROOT/out-not-measured" "$TEMP_ROOT/status-not-measured"

PASS=0
TOTAL=4

check() {
    local label="$1" condition="$2"
    if [ "$condition" = "1" ]; then
        echo "  ✅ PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $label"
    fi
}

[ "$(cat "$TEMP_ROOT/status-valid")" = "0" ] && V0=1 || V0=0
grep -q "INVALID_EVIDENCE|REVIEW-lsp-fixture-hallucinated" "$TEMP_ROOT/out-hallucinated" && V1MSG=1 || V1MSG=0
[ "$(cat "$TEMP_ROOT/status-hallucinated")" = "1" ] && V1=1 || V1=0
grep -q "INVALID_EVIDENCE|REVIEW-lsp-fixture-out-of-range" "$TEMP_ROOT/out-out-of-range" && V2MSG=1 || V2MSG=0
[ "$(cat "$TEMP_ROOT/status-out-of-range")" = "1" ] && V2=1 || V2=0
[ "$(cat "$TEMP_ROOT/status-not-measured")" = "0" ] && V3=1 || V3=0
grep -q "CITED=0" "$TEMP_ROOT/out-not-measured" && V3NOTE=1 || V3NOTE=0

check "valid fixture exits 0" "$V0"
check "hallucinated citation flagged with REVIEW id" "$V1MSG"
check "hallucinated fixture exits 1" "$V1"
check "out-of-range citation flagged with REVIEW id" "$V2MSG"
check "out-of-range fixture exits 1" "$V2"
check "not measured fixture exits 0 (absence is never a failure)" "$V3"
check "not measured reports CITED=0 pass-through" "$V3NOTE"
TOTAL=7

echo "==========================================================="
echo "📊 LSP Evidence Fixture Verification Summary"
echo "Passed: $PASS | Failed: $((TOTAL - PASS))"
echo "==========================================================="
[ "$PASS" -eq "$TOTAL" ] || exit 1
echo "✅ All LSP evidence fixture tests passed successfully!"
