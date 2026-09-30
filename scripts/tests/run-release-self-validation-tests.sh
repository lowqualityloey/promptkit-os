#!/usr/bin/env bash
# Regression tests for release-record self-validation output contract parser and grandfather exemption.
# Exercises clean VALID, allowed legacy FAILED, new records with legacy IDs, mixed diagnostics, crashes,
# empty output, contradictory summaries, and invalid lines.
#
# Run from repository root: bash scripts/tests/run-release-self-validation-tests.sh

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECKER="$REPO_ROOT/scripts/check-release-validation-output.sh"

PASS=0
FAIL=0

check() {
  local label="$1" expected_exit="$2" actual_exit="$3" out="$4"
  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "  ✅ PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL: $label (expected exit $expected_exit, got $actual_exit)"
    echo "     Output: $out"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Release Self-Validation Contract Parser Tests ==="

# Case 1: Clean VALID on exit 0
out=$(echo "VALID|RECORDS=47|ROOT=." | bash "$CHECKER" --exit-code 0 2>&1)
check "Clean VALID on exit 0 passes" 0 $? "$out"

# Case 2: Allowed legacy FAILED on exit 1
out=$(printf "%s\n%s\n%s\n" \
  "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field" \
  "INVALID_ID|UNKNOWN|docs/releases/2026-09-08-v1.0.0-release-notes-draft.md|Missing field: Evaluation ID|Add field" \
  "FAILED|ERRORS=2|RECORDS=47" | bash "$CHECKER" --exit-code 1 2>&1)
check "Allowed legacy diagnostics on exit 1 pass with grandfather exemption" 0 $? "$out"

# Case 3: New record with historical legacy prefix in its Evaluation ID must FAIL (R1 fix)
out=$(printf "%s\n%s\n" \
  "MISSING_FIELD|EVAL-2026-09-08-v1.0.0-new|docs/releases/new-feature-evaluation.md|Missing field: Created|Add field" \
  "FAILED|ERRORS=1|RECORDS=48" | bash "$CHECKER" --exit-code 1 2>&1)
check "New record with legacy Eval ID prefix in field 2 is rejected" 1 $? "$out"

# Case 4: Mixed legacy and new record diagnostics must FAIL
out=$(printf "%s\n%s\n%s\n" \
  "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field" \
  "MISSING_FIELD|REL-2026-09-10-V110-001|docs/releases/2026-09-10-v1.1.0-evaluation.md|Missing field: Created|Add field" \
  "FAILED|ERRORS=2|RECORDS=48" | bash "$CHECKER" --exit-code 1 2>&1)
check "Mixed legacy and new diagnostics on exit 1 is rejected" 1 $? "$out"

# Case 5: Exit 0 with diagnostics must FAIL (R2 contract violation)
out=$(printf "%s\n%s\n" \
  "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field" \
  "VALID|RECORDS=47|ROOT=." | bash "$CHECKER" --exit-code 0 2>&1)
check "Exit 0 with diagnostics is rejected" 1 $? "$out"

# Case 6: Exit 1 with 0 diagnostics must FAIL (R2 contract violation)
out=$(echo "FAILED|ERRORS=0|RECORDS=47" | bash "$CHECKER" --exit-code 1 2>&1)
check "Exit 1 with zero diagnostics is rejected" 1 $? "$out"

# Case 7: Exit 1 with mismatched diagnostic count must FAIL (R2 contract violation)
out=$(printf "%s\n%s\n" \
  "MISSING_FIELD|REL-2026-09-08-FIRST-001|docs/releases/2026-09-08-v1.0.0-first-release-evaluation.md|Missing field: Created|Add field" \
  "FAILED|ERRORS=3|RECORDS=47" | bash "$CHECKER" --exit-code 1 2>&1)
check "Exit 1 with mismatched error count in summary is rejected" 1 $? "$out"

# Case 8: Exit 0 with FAILED summary must FAIL (inconsistent status/summary)
out=$(echo "FAILED|ERRORS=1|RECORDS=47" | bash "$CHECKER" --exit-code 0 2>&1)
check "Exit 0 with FAILED summary is rejected" 1 $? "$out"

# Case 9: Exit 1 with VALID summary must FAIL (inconsistent status/summary)
out=$(echo "VALID|RECORDS=47|ROOT=." | bash "$CHECKER" --exit-code 1 2>&1)
check "Exit 1 with VALID summary is rejected" 1 $? "$out"

# Case 10: Crash exit code (e.g. 2 or 127) must propagate crash status
out=$(echo "syntax error near unexpected token" | bash "$CHECKER" --exit-code 2 2>&1)
check "Validator crash (exit 2) is rejected" 2 $? "$out"

# Case 11: Empty output must FAIL
out=$(echo "" | bash "$CHECKER" --exit-code 0 2>&1)
check "Empty output on exit 0 is rejected" 1 $? "$out"

# Case 12: Foreign/unrecognized line alongside summary must FAIL
out=$(printf "%s\n%s\n" \
  "find: /nonexistent: No such file or directory" \
  "VALID|RECORDS=47|ROOT=." | bash "$CHECKER" --exit-code 0 2>&1)
check "Unrecognized line alongside summary is rejected" 1 $? "$out"

# Case 13: Contradictory summaries must FAIL
out=$(printf "%s\n%s\n" \
  "VALID|RECORDS=47|ROOT=." \
  "FAILED|ERRORS=0|RECORDS=47" | bash "$CHECKER" --exit-code 0 2>&1)
check "Contradictory multiple summaries is rejected" 1 $? "$out"

echo ""
echo "Summary: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
