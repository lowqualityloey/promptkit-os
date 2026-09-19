#!/usr/bin/env bash
# ==============================================================================
# scripts/tests/run-pk-route-tests.sh
#
# Automated Behavioral Contract & Safety Floor Tests for pk-route.sh
# Asserts Scenarios 1–5 (Missing Key, Timeout, Safety Floor, Secret Hygiene)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PK_ROUTE="$REPO_ROOT/scripts/pk-route.sh"

PASSED=0
FAILED=0

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  [PASS] $test_name"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $test_name"
    echo "         Expected to find: '$needle'"
    echo "         Actual output:    '$haystack'"
    FAILED=$((FAILED + 1))
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  [PASS] $test_name"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $test_name"
    echo "         Found forbidden string: '$needle'"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== Running pk-route.sh Behavioral Contract Tests ==="

# ------------------------------------------------------------------------------
# Test 1: Help Flag
# ------------------------------------------------------------------------------
echo "Test 1: Help flag prints usage and exits 0"
HELP_OUT=$(bash "$PK_ROUTE" --help)
assert_contains "$HELP_OUT" "Usage: pk-route.sh" "Help flag contains usage"

# ------------------------------------------------------------------------------
# Test 2: Scenario 1 - Missing API Key Fallback (L0 Typo)
# ------------------------------------------------------------------------------
echo "Test 2: Scenario 1 - Missing API key fallback (L0)"
L0_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "fix typo in README.md")
assert_contains "$L0_OUT" "Level 0 (Direct)" "L0 typo classified as Level 0"
assert_contains "$L0_OUT" "Recommended Workflow: pk:fix" "L0 typo recommends pk:fix"

# ------------------------------------------------------------------------------
# Test 3: Scenario 4 - Hard Safety Floor: Migration / Schema (L2)
# ------------------------------------------------------------------------------
echo "Test 3: Scenario 4 - Hard safety floor for schema/migration (L2)"
L2_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "minor tweak to ALTER TABLE in user schema")
assert_contains "$L2_OUT" "Level 2 (Controlled)" "ALTER TABLE classified as Level 2"
assert_contains "$L2_OUT" "Task Record required" "L2 notes Task Record required"

# ------------------------------------------------------------------------------
# Test 4: Scenario 4 - Hard Safety Floor: Production Deploy / Release (L3)
# ------------------------------------------------------------------------------
echo "Test 4: Scenario 4 - Hard safety floor for release/deploy (L3)"
L3_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "tag and deploy release v1.0.0 to production")
assert_contains "$L3_OUT" "Level 3 (Release-Critical)" "Deploy classified as Level 3"
assert_contains "$L3_OUT" "Recommended Workflow: pk:ship" "Deploy recommends pk:ship"

# ------------------------------------------------------------------------------
# Test 5: Scenario 4 - Adversarial Phrasing Hard Triggers
# ------------------------------------------------------------------------------
echo "Test 5: Scenario 4 - Adversarial phrasing hard triggers (0% underclassification)"
ADV1_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "quickly update the production database before release")
assert_contains "$ADV1_OUT" "Level 3 (Release-Critical)" "Adversarial 1 -> Level 3"

ADV2_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "just change the migration and ship it")
assert_contains "$ADV2_OUT" "Level 2 (Controlled)" "Adversarial 2 -> Level 2"

ADV3_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "can you make this live?")
assert_contains "$ADV3_OUT" "Level 3 (Release-Critical)" "Adversarial 3 -> Level 3"

# ------------------------------------------------------------------------------
# Test 6: Scenario 3 - Graceful Fallback on API failure / invalid key
# ------------------------------------------------------------------------------
echo "Test 6: Scenario 3 - Non-blocking degradation on invalid API call"
FALLBACK_ERR=$(mktemp)
FALLBACK_OUT=$(TYPESAFE_API_KEY="test-invalid-key-xyz" bash "$PK_ROUTE" --timeout 1 "debug null pointer exception" 2>"$FALLBACK_ERR" || true)
ERR_CONTENT=$(cat "$FALLBACK_ERR")
rm -f "$FALLBACK_ERR"

assert_contains "$FALLBACK_OUT" "PromptKit OS: Level" "Output contains valid Turn 1 banner on API failure"
assert_contains "$FALLBACK_OUT" "Recommended Workflow: pk:debug" "Workflow correctly resolved on fallback"
assert_contains "$ERR_CONTENT" "Falling back to deterministic routing" "Stderr contains non-blocking diagnostic"

# ------------------------------------------------------------------------------
# Test 7: Scenario 5 - Secret Hygiene
# ------------------------------------------------------------------------------
echo "Test 7: Scenario 5 - Secret hygiene (API key never leaked)"
SECRET_KEY="super-secret-token-do-not-leak-999"
SECRET_ERR=$(mktemp)
SECRET_OUT=$(TYPESAFE_API_KEY="$SECRET_KEY" bash "$PK_ROUTE" --timeout 1 "fix bug" 2>"$SECRET_ERR" || true)
SECRET_ERR_CONTENT=$(cat "$SECRET_ERR")
rm -f "$SECRET_ERR"

assert_not_contains "$SECRET_OUT" "$SECRET_KEY" "Stdout does not leak API key"
assert_not_contains "$SECRET_ERR_CONTENT" "$SECRET_KEY" "Stderr does not leak API key"

# ------------------------------------------------------------------------------
# Test 8: Issue #345 - Synonym hard triggers (auth, release, API contract)
# ------------------------------------------------------------------------------
echo "Test 8: Issue #345 - Synonym hard triggers (deterministic, offline)"

# Scenario 1: Auth synonyms must reach L2
AUTH1_OUT=$(bash "$PK_ROUTE" --offline "Add Google login to the app")
assert_contains "$AUTH1_OUT" "Level 2 (Controlled)" "H2: 'Add Google login' -> Level 2"
assert_contains "$AUTH1_OUT" "Task Record required" "H2: L2 notes Task Record required"

AUTH2_OUT=$(bash "$PK_ROUTE" --offline "Let people sign in with their Google account")
assert_contains "$AUTH2_OUT" "Level 2 (Controlled)" "H2a: 'sign in with Google' -> Level 2"

AUTH3_OUT=$(bash "$PK_ROUTE" --offline "Add SSO to the dashboard")
assert_contains "$AUTH3_OUT" "Level 2 (Controlled)" "Auth synonym: 'SSO' -> Level 2"

AUTH4_OUT=$(bash "$PK_ROUTE" --offline "Let users sign-up with an email and password")
assert_contains "$AUTH4_OUT" "Level 2 (Controlled)" "Auth synonym: 'sign-up'/'password' -> Level 2"

# Scenario 2: Release and live-publication synonyms must reach L3
REL1_OUT=$(bash "$PK_ROUTE" --offline "Ship the new version to real users")
assert_contains "$REL1_OUT" "Level 3 (Release-Critical)" "H3a: bare 'ship' -> Level 3"

REL2_OUT=$(bash "$PK_ROUTE" --offline "Could we turn this on for everyone now")
assert_contains "$REL2_OUT" "Level 3 (Release-Critical)" "H5a: 'turn this on' -> Level 3"

REL3_OUT=$(bash "$PK_ROUTE" --offline "Make the app live tomorrow morning")
assert_contains "$REL3_OUT" "Level 3 (Release-Critical)" "Live publication with modifier -> Level 3"

# Scenario 3: API-contract synonyms must reach L2
API1_OUT=$(bash "$PK_ROUTE" --offline "Change the public API response format for /v1/users")
assert_contains "$API1_OUT" "Level 2 (Controlled)" "H6: 'API response format' -> Level 2"

API2_OUT=$(bash "$PK_ROUTE" --offline "Tweak what the users endpoint gives back")
assert_contains "$API2_OUT" "Level 2 (Controlled)" "H6a: 'users endpoint' -> Level 2"

API3_OUT=$(bash "$PK_ROUTE" --offline "Adjust the API payload for the create-order call")
assert_contains "$API3_OUT" "Level 2 (Controlled)" "API synonym: 'API payload' -> Level 2"

# Bare ship must NOT defeat an L2 trigger (existing floor behaviour preserved)
SHIP_L2_OUT=$(bash "$PK_ROUTE" --offline "just change the migration and ship it")
assert_contains "$SHIP_L2_OUT" "Level 2 (Controlled)" "Bare 'ship' with L2 trigger stays Level 2"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo ""
echo "=== Test Summary: $PASSED passed, $FAILED failed ==="
if [[ $FAILED -gt 0 ]]; then
  exit 1
fi

echo "ALL CONTRACT TESTS PASSED WITH 0% UNSAFE UNDERCLASSIFICATIONS."
exit 0
