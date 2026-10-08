#!/usr/bin/env bash
# ==============================================================================
# scripts/tests/run-pk-route-tests.sh
#
# Behavioral Contract & Safety Floor Tests for pk-route.sh (POST-change contract).
#
# This suite encodes the contract AFTER the two parallel changes land:
#   - #592: the optional external AI integration is retired in full. There is no
#           credential gate and no network transport; the router always classifies
#           deterministically. Legacy AI_GATEWAY_API_KEY / TYPESAFE_API_KEY values
#           must be ignored entirely (never read, never leaked, never contacted).
#   - #594: the L0-L3 classifier is corrected on a bounded fixture set. This file
#           records the expected-vs-observed levels for those fixtures in an
#           explicit FP/FN table and fails while either named defect remains:
#             * FP: `What is a breaking change?`  was over-classified as L2 (want L0)
#             * FN: `Add an optional field to the public REST response` was
#                   under-classified as L1 (want L2)
#
# Verification model: this suite is expected to run RED against the CURRENT,
# unmodified router until the router change lands, and GREEN afterwards.
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

assert_exit_zero() {
  local code="$1"
  local test_name="$2"

  if [[ "$code" -eq 0 ]]; then
    echo "  [PASS] $test_name"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $test_name"
    echo "         Expected exit code 0, got: '$code'"
    FAILED=$((FAILED + 1))
  fi
}

assert_file_exists() {
  local path="$1"
  local test_name="$2"

  if [[ -f "$path" ]]; then
    echo "  [PASS] $test_name"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $test_name"
    echo "         Expected file to exist: '$path'"
    FAILED=$((FAILED + 1))
  fi
}

# Asserts a forbidden construct is absent from the router SOURCE (static guard).
assert_source_absent() {
  local needle="$1"
  local test_name="$2"

  if grep -qiF -- "$needle" "$PK_ROUTE"; then
    echo "  [FAIL] $test_name"
    echo "         Forbidden construct still present in router source: '$needle'"
    FAILED=$((FAILED + 1))
  else
    echo "  [PASS] $test_name"
    PASSED=$((PASSED + 1))
  fi
}

# Deterministic, credential-free invocation: strip the retired AI credentials so
# the suite exercises the post-#592 routing contract (no credential gate, no
# network). The router must produce an identical classification regardless.
route_prompt() {
  env -u AI_GATEWAY_API_KEY -u TYPESAFE_API_KEY bash "$PK_ROUTE" "$1"
}

# Extracts the ceremony level (0-3) from a router banner, or "?" if absent.
extract_level() {
  if [[ "$1" =~ Level\ ([0-3]) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    printf '?'
  fi
}

echo "=== Running pk-route.sh Behavioral Contract Tests ==="

# ------------------------------------------------------------------------------
# Test 1: Help Flag (Group 1)
# ------------------------------------------------------------------------------
echo "Test 1: Help flag prints usage and exits 0"
HELP_OUT=$(bash "$PK_ROUTE" --help)
assert_contains "$HELP_OUT" "Usage: pk-route.sh" "Help flag contains usage"
# #592: help text must not surface the retired integration vocabulary.
assert_not_contains "$HELP_OUT" "Jev" "Help text does not mention Jev"
assert_not_contains "$HELP_OUT" "TypeSafe" "Help text does not mention TypeSafe"
assert_not_contains "$HELP_OUT" "AI_GATEWAY_API_KEY" "Help text does not mention AI_GATEWAY_API_KEY"
assert_not_contains "$HELP_OUT" "TYPESAFE_API_KEY" "Help text does not mention TYPESAFE_API_KEY"
assert_not_contains "$HELP_OUT" "curl" "Help text does not mention curl"
# F-4: deprecated compatibility flags must be labelled as such.
assert_contains "$HELP_OUT" "Deprecated" "Help text contains Deprecated (F-4)"

# ------------------------------------------------------------------------------
# Test 2: No credential gate (Group 2, rewritten from "missing key")
# ------------------------------------------------------------------------------
# #592 deletes the credential gate, so there is no longer a "no API key"
# scenario: with both credentials unset and no --offline the router must still
# classify deterministically and recommend the fix workflow.
echo "Test 2: Credential-free routing still yields Level 0 + pk:fix"
L0_OUT=$(route_prompt "fix typo in README.md")
assert_contains "$L0_OUT" "Level 0 (Direct)" "L0 typo classified as Level 0"
assert_contains "$L0_OUT" "Recommended Workflow: pk:fix" "L0 typo recommends pk:fix"

# ------------------------------------------------------------------------------
# Test 3: Hard Safety Floor: Migration / Schema (L2) — KEEP AS-IS
# ------------------------------------------------------------------------------
echo "Test 3: Scenario 4 - Hard safety floor for schema/migration (L2)"
L2_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "minor tweak to ALTER TABLE in user schema")
assert_contains "$L2_OUT" "Level 2 (Controlled)" "ALTER TABLE classified as Level 2"
assert_contains "$L2_OUT" "Task Record required" "L2 notes Task Record required"

# ------------------------------------------------------------------------------
# Test 4: Hard Safety Floor: Production Deploy / Release (L3) — KEEP AS-IS
# ------------------------------------------------------------------------------
echo "Test 4: Scenario 4 - Hard safety floor for release/deploy (L3)"
L3_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "tag and deploy release v1.0.0 to production")
assert_contains "$L3_OUT" "Level 3 (Release-Critical)" "Deploy classified as Level 3"
assert_contains "$L3_OUT" "Recommended Workflow: pk:ship" "Deploy recommends pk:ship"

# ------------------------------------------------------------------------------
# Test 5: Adversarial Phrasing Hard Triggers — KEEP AS-IS
# ------------------------------------------------------------------------------
echo "Test 5: Scenario 4 - Adversarial phrasing hard triggers (0% underclassification)"
ADV1_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "quickly update the production database before release")
assert_contains "$ADV1_OUT" "Level 3 (Release-Critical)" "Adversarial 1 -> Level 3"

ADV2_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "just change the migration and ship it")
assert_contains "$ADV2_OUT" "Level 2 (Controlled)" "Adversarial 2 -> Level 2"

ADV3_OUT=$(env -u TYPESAFE_API_KEY bash "$PK_ROUTE" "can you make this live?")
assert_contains "$ADV3_OUT" "Level 3 (Release-Critical)" "Adversarial 3 -> Level 3"

# ------------------------------------------------------------------------------
# Test 6: Legacy credentials are ignored (Group 6, rewritten from "API failure")
# ------------------------------------------------------------------------------
# #592 retires the network transport, so there is no API to fail. Presence of
# legacy credential env vars must change nothing: deterministic classification,
# no sentinel leak, and no "Falling back" diagnostic.
echo "Test 6: Legacy credentials are ignored"
SENTINEL_GW="svc-sentinel-1"
SENTINEL_TS="svc-sentinel-2"
GRP6_ERR=$(mktemp)
GRP6_EXIT=0
GRP6_OUT=$(AI_GATEWAY_API_KEY="$SENTINEL_GW" TYPESAFE_API_KEY="$SENTINEL_TS" \
  bash "$PK_ROUTE" "debug null pointer exception" 2>"$GRP6_ERR") || GRP6_EXIT=$?
GRP6_ERR_CONTENT=$(cat "$GRP6_ERR")
rm -f "$GRP6_ERR"

assert_exit_zero "$GRP6_EXIT" "Router exits 0 with legacy credentials present"
assert_contains "$GRP6_OUT" "PromptKit OS: Level" "Output contains valid level banner"
assert_contains "$GRP6_OUT" "Recommended Workflow: pk:debug" "Workflow resolved to pk:debug"
assert_not_contains "$GRP6_OUT" "$SENTINEL_GW" "Gateway sentinel never appears on stdout"
assert_not_contains "$GRP6_OUT" "$SENTINEL_TS" "TypeSafe sentinel never appears on stdout"
assert_not_contains "$GRP6_ERR_CONTENT" "$SENTINEL_GW" "Gateway sentinel never appears on stderr"
assert_not_contains "$GRP6_ERR_CONTENT" "$SENTINEL_TS" "TypeSafe sentinel never appears on stderr"
assert_not_contains "$GRP6_ERR_CONTENT" "Falling back" "No network fallback diagnostic on stderr"

# ------------------------------------------------------------------------------
# Test 7: Static retirement guard (Group 7, rewritten from "secret hygiene")
# ------------------------------------------------------------------------------
# #592 is a full retirement: no surviving external-network construct may remain
# anywhere in the router source. This is a STATIC source scan, not a runtime
# probe. Any hit fails the guard.
echo "Test 7: Static retirement guard (no external-network constructs in source)"
assert_file_exists "$PK_ROUTE" "Router source is present for static scan"
assert_source_absent "curl" "Router source contains no 'curl'"
assert_source_absent "wget" "Router source contains no 'wget'"
assert_source_absent "Invoke-RestMethod" "Router source contains no 'Invoke-RestMethod'"
assert_source_absent "Invoke-WebRequest" "Router source contains no 'Invoke-WebRequest'"
assert_source_absent "AI_GATEWAY_API_KEY" "Router source contains no 'AI_GATEWAY_API_KEY'"
assert_source_absent "TYPESAFE_API_KEY" "Router source contains no 'TYPESAFE_API_KEY'"
assert_source_absent "ai-gateway" "Router source contains no 'ai-gateway'"
assert_source_absent "typesafe.ai" "Router source contains no 'typesafe.ai'"
assert_source_absent "jev" "Router source contains no 'jev' (case-insensitive)"

# ------------------------------------------------------------------------------
# Test 8: Issue #345 - Synonym hard triggers — KEEP AS-IS
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
# Test 9: Issue #594 - L3 positives (Group 9)
# ------------------------------------------------------------------------------
echo "Test 9: Issue #594 - L3 positives"
RELEASE_RC_OUT=$(route_prompt "Ship the v2.0 release candidate")
assert_contains "$RELEASE_RC_OUT" "Level 3" "'Ship the v2.0 release candidate' -> Level 3"

CVE_OUT=$(route_prompt "Apply the critical security patch for CVE-2026-1234")
assert_contains "$CVE_OUT" "Level 3" "'Apply the critical security patch for CVE-2026-1234' -> Level 3"

PUBLIC_CONTRACT_OUT=$(route_prompt "Roll out the high-impact public API contract change to billing")
assert_contains "$PUBLIC_CONTRACT_OUT" "Level 3" "'Roll out the high-impact public API contract change to billing' -> Level 3"

# ------------------------------------------------------------------------------
# Test 10: Issue #594 - L2 positives (Group 10)
# ------------------------------------------------------------------------------
echo "Test 10: Issue #594 - L2 positives"
OPTIONAL_FIELD_OUT=$(route_prompt "Add an optional field to the public REST response")
assert_contains "$OPTIONAL_FIELD_OUT" "Level 2" "'Add an optional field to the public REST response' -> Level 2"
assert_not_contains "$OPTIONAL_FIELD_OUT" "Level 3" "Optional REST field is not promoted to Level 3"

MIGRATE_INDEX_OUT=$(route_prompt "Migrate the users table with a new index")
assert_contains "$MIGRATE_INDEX_OUT" "Level 2" "'Migrate the users table with a new index' -> Level 2"
assert_not_contains "$MIGRATE_INDEX_OUT" "Level 3" "Table migration is not promoted to Level 3"

OAUTH_LOGIN_OUT=$(route_prompt "Implement OAuth login")
assert_contains "$OAUTH_LOGIN_OUT" "Level 2" "'Implement OAuth login' -> Level 2"
assert_not_contains "$OAUTH_LOGIN_OUT" "Level 3" "OAuth login is not promoted to Level 3"

# ------------------------------------------------------------------------------
# Test 11: Issue #594 - negatives + vague-word guard (Group 11)
# ------------------------------------------------------------------------------
echo "Test 11: Issue #594 - negatives + vague-word guard"
# #594 forbids promoting a task on vague words alone (important/urgent/major).
# Such wording may set NO floor above Level 1 and must never reach Level 3.
API_VERSIONING_Q_OUT=$(route_prompt "Explain how our API versioning works")
assert_contains "$API_VERSIONING_Q_OUT" "Level 0" "'Explain how our API versioning works' -> Level 0"

BREAKING_CHANGE_Q_OUT=$(route_prompt "What is a breaking change?")
assert_contains "$BREAKING_CHANGE_Q_OUT" "Level 0" "'What is a breaking change?' -> Level 0"

TYPO_API_DOCS_OUT=$(route_prompt "Fix a typo in the API docs")
assert_contains "$TYPO_API_DOCS_OUT" "Level 0" "'Fix a typo in the API docs' -> Level 0"

VAGUE_URGENT_OUT=$(route_prompt "This is urgent")
assert_contains "$VAGUE_URGENT_OUT" "Level 1" "'This is urgent' -> Level 1"
assert_not_contains "$VAGUE_URGENT_OUT" "Level 3" "'urgent' alone never promotes to Level 3"

VAGUE_IMPORTANT_OUT=$(route_prompt "This is important")
assert_contains "$VAGUE_IMPORTANT_OUT" "Level 1" "'This is important' -> Level 1"
assert_not_contains "$VAGUE_IMPORTANT_OUT" "Level 3" "'important' alone never promotes to Level 3"

VAGUE_MAJOR_OUT=$(route_prompt "Major refactor of the parser")
assert_contains "$VAGUE_MAJOR_OUT" "Level 1" "'Major refactor of the parser' -> Level 1"
assert_not_contains "$VAGUE_MAJOR_OUT" "Level 3" "'major' alone never promotes to Level 3"

# ------------------------------------------------------------------------------
# Test 12: Issue #595 - alias coverage + workflow ambiguity (Group 12)
# ------------------------------------------------------------------------------
echo "Test 12: Issue #595 - workflow alias coverage + ambiguity resolution"
assert_file_exists "$REPO_ROOT/workflows/design-system.md" "Alias target exists: workflows/design-system.md"
assert_file_exists "$REPO_ROOT/workflows/research.md" "Alias target exists: workflows/research.md"
assert_file_exists "$REPO_ROOT/workflows/reflect.md" "Alias target exists: workflows/reflect.md"
assert_file_exists "$REPO_ROOT/workflows/tutor.md" "Alias target exists: workflows/tutor.md"

TWEAK_SETTINGS_OUT=$(route_prompt "tweak the settings")
assert_contains "$TWEAK_SETTINGS_OUT" "Recommended Workflow: pk:route" "'tweak the settings' falls back to pk:route"

CHECKOUT_500_OUT=$(route_prompt "the checkout endpoint returns 500")
assert_contains "$CHECKOUT_500_OUT" "Recommended Workflow: pk:route" "'the checkout endpoint returns 500' falls back to pk:route"

FAILING_TEST_OUT=$(route_prompt "review the failing test")
assert_contains "$FAILING_TEST_OUT" "Recommended Workflow: pk:debug" "'review the failing test' resolves to pk:debug (debug beats review)"

DEPLOY_AFTER_TESTS_OUT=$(route_prompt "deploy after the tests pass")
assert_contains "$DEPLOY_AFTER_TESTS_OUT" "Recommended Workflow: pk:ship" "'deploy after the tests pass' resolves to pk:ship"

# ------------------------------------------------------------------------------
# Test 13: Issue #594 F-3 regression - action markers vs bare mentions (Group 13)
# ------------------------------------------------------------------------------
echo "Test 13: #594 F-3 regression: action markers vs bare mentions"

# NEGATIVE: a bare topical mention must NOT escalate (was over-classified).
NEG_TYPO_SECURITY_README_OUT=$(route_prompt "Fix a typo in the security patch README.")
assert_contains "$NEG_TYPO_SECURITY_README_OUT" "Level 0" "'Fix a typo in the security patch README.' -> Level 0"
assert_not_contains "$NEG_TYPO_SECURITY_README_OUT" "Level 3" "typo in security-patch README is not Level 3"
assert_not_contains "$NEG_TYPO_SECURITY_README_OUT" "Level 2" "typo in security-patch README is not Level 2"

NEG_TELL_CRITICAL_OUT=$(route_prompt "Tell me about critical security patches in general.")
assert_contains "$NEG_TELL_CRITICAL_OUT" "Level 1" "'Tell me about critical security patches in general.' -> Level 1"
assert_not_contains "$NEG_TELL_CRITICAL_OUT" "Level 3" "general talk about critical security patches is not Level 3"

NEG_EXPLAIN_CRITICAL_OUT=$(route_prompt "Explain what a critical security patch is.")
assert_contains "$NEG_EXPLAIN_CRITICAL_OUT" "Level 0" "'Explain what a critical security patch is.' -> Level 0"
assert_not_contains "$NEG_EXPLAIN_CRITICAL_OUT" "Level 3" "definition of a critical security patch is not Level 3"
assert_not_contains "$NEG_EXPLAIN_CRITICAL_OUT" "Level 2" "definition of a critical security patch is not Level 2"

NEG_PUBLIC_RESPONSE_OUT=$(route_prompt "Explain the public response format.")
assert_contains "$NEG_PUBLIC_RESPONSE_OUT" "Level 0" "'Explain the public response format.' -> Level 0"
assert_not_contains "$NEG_PUBLIC_RESPONSE_OUT" "Level 3" "explaining the public response format is not Level 3"
assert_not_contains "$NEG_PUBLIC_RESPONSE_OUT" "Level 2" "explaining the public response format is not Level 2"

# POSITIVE: genuine work on the subject must still escalate (safety floor).
POS_FIX_SECURITY_PATCH_OUT=$(route_prompt "Fix the security patch for the login module.")
assert_contains "$POS_FIX_SECURITY_PATCH_OUT" "Level 3" "'Fix the security patch for the login module.' -> Level 3"

POS_BACKPORT_OUT=$(route_prompt "Backport the critical security fix for the parser.")
assert_contains "$POS_BACKPORT_OUT" "Level 3" "'Backport the critical security fix for the parser.' -> Level 3"

POS_APPLY_CVE_OUT=$(route_prompt "Apply a critical security patch for CVE-2026-1234.")
assert_contains "$POS_APPLY_CVE_OUT" "Level 3" "'Apply a critical security patch for CVE-2026-1234.' -> Level 3"

POS_HIGH_IMPACT_OUT=$(route_prompt "Roll out the high-impact public API contract change to billing")
assert_contains "$POS_HIGH_IMPACT_OUT" "Level 3" "'Roll out the high-impact public API contract change to billing' -> Level 3"

POS_PUBLIC_REST_OUT=$(route_prompt "Add an optional field to the public REST response")
assert_contains "$POS_PUBLIC_REST_OUT" "Level 2" "'Add an optional field to the public REST response' -> Level 2"

# MIXED-INTENT: the new predicate must not under-classify.
MIXED_MIGRATE_OUT=$(route_prompt "Explain and then migrate the production database.")
assert_contains "$MIXED_MIGRATE_OUT" "Level 2" "'Explain and then migrate the production database.' -> Level 2"

MIXED_RELEASE_DEPLOY_OUT=$(route_prompt "Explain the release process, then deploy.")
assert_contains "$MIXED_RELEASE_DEPLOY_OUT" "Level 3" "'Explain the release process, then deploy.' -> Level 3"

# ------------------------------------------------------------------------------
# Test 14: Issue #594 follow-up - action intent vs question ABOUT an action
# ------------------------------------------------------------------------------
echo "Test 14: #594 follow-up: question about an action must not escalate"

# NEGATIVE: an informational frame suppresses the topical markers even when the
# sentence also contains an action verb (here "change"/"revert" used as a NOUN).
Q_HIGHIMPACT_CONTRACT_OUT=$(route_prompt "Explain the high-impact contract change.")
assert_contains "$Q_HIGHIMPACT_CONTRACT_OUT" "Level 0" "'Explain the high-impact contract change.' -> Level 0"
assert_not_contains "$Q_HIGHIMPACT_CONTRACT_OUT" "Level 3" "question about a high-impact contract change is not Level 3"

Q_HIGHIMPACT_WHAT_OUT=$(route_prompt "What is a high-impact contract change?")
assert_contains "$Q_HIGHIMPACT_WHAT_OUT" "Level 0" "'What is a high-impact contract change?' -> Level 0"
assert_not_contains "$Q_HIGHIMPACT_WHAT_OUT" "Level 3" "'What is a high-impact contract change?' is not Level 3"

Q_HIGHIMPACT_PUBLIC_OUT=$(route_prompt "Explain the high-impact public API change.")
assert_contains "$Q_HIGHIMPACT_PUBLIC_OUT" "Level 0" "'Explain the high-impact public API change.' -> Level 0"
assert_not_contains "$Q_HIGHIMPACT_PUBLIC_OUT" "Level 3" "'Explain the high-impact public API change.' is not Level 3"

Q_HOWTO_CHANGE_OUT=$(route_prompt "Explain how to change the high-impact public API.")
assert_contains "$Q_HOWTO_CHANGE_OUT" "Level 0" "'Explain how to change the high-impact public API.' -> Level 0"
assert_not_contains "$Q_HOWTO_CHANGE_OUT" "Level 3" "'Explain how to change ...' is not Level 3"

Q_MEANING_OUT=$(route_prompt "What does it mean to change a high-impact API?")
assert_contains "$Q_MEANING_OUT" "Level 0" "'What does it mean to change a high-impact API?' -> Level 0"
assert_not_contains "$Q_MEANING_OUT" "Level 3" "'What does it mean to change ...' is not Level 3"

Q_HOWTO_REVERT_OUT=$(route_prompt "Explain how to revert the high-impact API change.")
assert_contains "$Q_HOWTO_REVERT_OUT" "Level 0" "'Explain how to revert the high-impact API change.' -> Level 0"
assert_not_contains "$Q_HOWTO_REVERT_OUT" "Level 3" "'Explain how to revert ...' is not Level 3"

Q_TYPO_README_OUT=$(route_prompt "Fix a typo in the high-impact API change README.")
assert_contains "$Q_TYPO_README_OUT" "Level 0" "'Fix a typo in the high-impact API change README.' -> Level 0"
assert_not_contains "$Q_TYPO_README_OUT" "Level 3" "a README typo fix is not Level 3"

# POSITIVE: a real high-impact contract change still escalates, including when the
# action verb is merely implied by a polite question or leads the sentence.
A_IMPLEMENT_OUT=$(route_prompt "Implement the high-impact public API change.")
assert_contains "$A_IMPLEMENT_OUT" "Level 3" "'Implement the high-impact public API change.' -> Level 3"

A_CHANGE_LEAD_OUT=$(route_prompt "Change the high-impact public API.")
assert_contains "$A_CHANGE_LEAD_OUT" "Level 3" "'Change the high-impact public API.' -> Level 3"

A_COULD_YOU_OUT=$(route_prompt "Could you change the high-impact public API?")
assert_contains "$A_COULD_YOU_OUT" "Level 3" "'Could you change the high-impact public API?' -> Level 3"

A_REVERT_OUT=$(route_prompt "Revert the high-impact public API change.")
assert_contains "$A_REVERT_OUT" "Level 3" "'Revert the high-impact public API change.' -> Level 3"

A_MIXED_THEN_OUT=$(route_prompt "Explain the high-impact API change, then implement it.")
assert_contains "$A_MIXED_THEN_OUT" "Level 3" "'Explain ... then implement it.' -> Level 3 (mixed intent preserved)"

A_CVE_OUT=$(route_prompt "Apply a critical security patch for CVE-2026-1234.")
assert_contains "$A_CVE_OUT" "Level 3" "'Apply a critical security patch for CVE-2026-1234.' -> Level 3"

# ------------------------------------------------------------------------------
# Test 15: Issue #594 follow-up - the veto must not swallow a real action
# ------------------------------------------------------------------------------
echo "Test 15: #594 follow-up: incidental informational words must not suppress action"

# REGRESSION: "and implement" is a second action clause; only "then" was recognised,
# so the veto suppressed a genuine high-impact contract change.
B_AND_IMPLEMENT_OUT=$(route_prompt "Explain the high-impact public API change, and implement it.")
assert_contains "$B_AND_IMPLEMENT_OUT" "Level 3" "'Explain ... and implement it.' -> Level 3"

# REGRESSION: "Docker" contains the substring "doc", so the old frame marker treated a
# containerised contract change as a documentation edit.
B_DOCKER_OUT=$(route_prompt "Implement the high-impact public API in Docker.")
assert_contains "$B_DOCKER_OUT" "Level 3" "'Implement the high-impact public API in Docker.' -> Level 3"

# REGRESSION: "rename" was listed as an informational frame marker, so a real rename
# of a high-impact contract was demoted to Level 1.
B_RENAME_OUT=$(route_prompt "Rename the high-impact public API.")
assert_contains "$B_RENAME_OUT" "Level 3" "'Rename the high-impact public API.' -> Level 3"

# OPPOSITE DIRECTION: documentation and question frames must still suppress, so the
# fixes above cannot be "solved" by simply deleting the veto.
B_DOC_QUESTION_OUT=$(route_prompt "What does the documentation say about the high-impact API change?")
assert_contains "$B_DOC_QUESTION_OUT" "Level 0" "'What does the documentation say ...' -> Level 0"
assert_not_contains "$B_DOC_QUESTION_OUT" "Level 3" "a documentation question is not Level 3"

B_DOCS_EXPLAIN_OUT=$(route_prompt "Explain the docs for the high-impact public API change.")
assert_contains "$B_DOCS_EXPLAIN_OUT" "Level 0" "'Explain the docs for ...' -> Level 0"
assert_not_contains "$B_DOCS_EXPLAIN_OUT" "Level 3" "'Explain the docs for ...' is not Level 3"

# A documentation clause attached to a real action must still escalate.
B_ACTION_WITH_DOCS_OUT=$(route_prompt "Add the high-impact public API contract and update the documentation.")
assert_contains "$B_ACTION_WITH_DOCS_OUT" "Level 3" "'Add ... and update the documentation.' -> Level 3"

# ------------------------------------------------------------------------------
# #594 FP/FN Report
# ------------------------------------------------------------------------------
# Bounded, table-driven classification report over the #594 fixture set only.
# This is NOT a claim of universal correctness over unrestricted input.
#
# Expected defects this batch fixes (must be gone once the router lands):
#   * FP: `What is a breaking change?` was over-classified L2 (want L0)
#   * FN: `Add an optional field to the public REST response` was
#         under-classified L1 (want L2)
#
# Verdict rule (ordinal): observed < expected -> FN, observed > expected -> FP,
# observed == expected -> TP. Any remaining FP or FN fails the suite.
echo ""
echo "=== #594 Classification FP/FN Report ==="

FPFN_FIXTURES=(
  "3|Ship the v2.0 release candidate"
  "3|Apply the critical security patch for CVE-2026-1234"
  "3|Roll out the high-impact public API contract change to billing"
  "2|Add an optional field to the public REST response"
  "2|Migrate the users table with a new index"
  "2|Implement OAuth login"
  "0|Explain how our API versioning works"
  "0|What is a breaking change?"
  "0|Fix a typo in the API docs"
  "1|This is urgent"
  "1|This is important"
  "1|Major refactor of the parser"
)

FP_TOTAL=0
FN_TOTAL=0
for fpfn_row in "${FPFN_FIXTURES[@]}"; do
  expected_level="${fpfn_row%%|*}"
  fpfn_prompt="${fpfn_row#*|}"
  fpfn_out=$(route_prompt "$fpfn_prompt" 2>/dev/null || true)
  observed_level=$(extract_level "$fpfn_out")

  if [[ "$observed_level" == "?" ]]; then
    verdict="FN"
  elif [[ "$observed_level" -eq "$expected_level" ]]; then
    verdict="TP"
  elif [[ "$observed_level" -lt "$expected_level" ]]; then
    verdict="FN"
  else
    verdict="FP"
  fi

  case "$verdict" in
    TP) printf '  [TP] observed L%s == expected L%s : %s\n' "$observed_level" "$expected_level" "$fpfn_prompt" ;;
    FP) FP_TOTAL=$((FP_TOTAL + 1)); printf '  [FP] observed L%s >  expected L%s : %s\n' "$observed_level" "$expected_level" "$fpfn_prompt" ;;
    FN) FN_TOTAL=$((FN_TOTAL + 1)); printf '  [FN] observed L%s <  expected L%s : %s\n' "$observed_level" "$expected_level" "$fpfn_prompt" ;;
  esac
done

echo "  #594 FP total: $FP_TOTAL, FN total: $FN_TOTAL"
if [[ $((FP_TOTAL + FN_TOTAL)) -gt 0 ]]; then
  echo "  [FAIL] #594 FP/FN report: $FP_TOTAL false positive(s), $FN_TOTAL false negative(s) remain"
  FAILED=$((FAILED + FP_TOTAL + FN_TOTAL))
else
  echo "  [PASS] #594 FP/FN report: zero false positives, zero false negatives"
  PASSED=$((PASSED + 1))
fi

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
