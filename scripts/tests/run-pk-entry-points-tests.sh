#!/usr/bin/env bash
# Regression harness for the thin `pk` entry-point shim (issue #546).
# Scenarios: 1 (route classifies and exits 0, executes nothing), 2 (unknown
# subcommand exits 2 and names the file-level contract), 5 (Bash/PowerShell
# parity, locked by one shared expected literal), plus the help/no-arg contract.
#
# Run from repository root: bash scripts/tests/run-pk-entry-points-tests.sh

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
PK="$REPO_ROOT/scripts/pk"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0
SCENARIO_OK=1

pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
begin() { SCENARIO_OK=1; }
report() { if [[ "$SCENARIO_OK" -eq 1 ]]; then pass "$1"; else fail "$1"; fi; }
scenario_check() {
    if [[ "$1" -ne 1 ]]; then
        printf '  - %s\n' "$2"
        SCENARIO_OK=0
    fi
}

STATUS=0
OUT=""
run_pk() {
    STATUS=0
    OUT="$(cd "$TMP" && env -u AI_GATEWAY_API_KEY -u TYPESAFE_API_KEY bash "$PK" "$@" 2>&1)" || STATUS=$?
}

# Scenario 5 parity lock: the PowerShell harness asserts this identical literal.
EXPECTED='[PromptKit OS: Level 2 (Controlled) — Deterministic offline policy classification. Task Record required.]
Recommended Workflow: pk:route'

# E1 (Scenario 1): `pk route "<text>"` classifies offline, exits 0, executes nothing.
e1() {
    local before after
    before="$(ls -A "$TMP")"
    run_pk route "the checkout endpoint returns 500"
    after="$(ls -A "$TMP")"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "expected exit 0, got $STATUS"
    scenario_check "$([[ "$OUT" == *"[PromptKit OS: Level "* ]] && printf 1 || printf 0)" "stdout missing the level banner"
    scenario_check "$([[ "$OUT" == *"Recommended Workflow: pk:"* ]] && printf 1 || printf 0)" "stdout missing Recommended Workflow"
    scenario_check "$([[ "$before" == "$after" ]] && printf 1 || printf 0)" "shim wrote files into the working directory"
}

# E2 (Scenario 2): a mistyped subcommand exits 2 and names workflows/<cmd>.md.
e2() {
    run_pk commti
    scenario_check "$([[ "$STATUS" -eq 2 ]] && printf 1 || printf 0)" "expected exit 2, got $STATUS"
    scenario_check "$([[ "$OUT" == *"workflows/commti.md"* ]] && printf 1 || printf 0)" "stderr missing the file-level contract path"
}

# E3 (Scenario 5): output matches the shared parity literal exactly.
e3() {
    run_pk route "the checkout endpoint returns 500"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "expected exit 0, got $STATUS"
    scenario_check "$([[ "$OUT" == "$EXPECTED" ]] && printf 1 || printf 0)" "output differs from the shared parity literal:
--- got ---
$OUT
--- expected ---
$EXPECTED"
}

# E4: --help prints usage and exits 0; no arguments exits 2.
e4() {
    run_pk --help
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "--help expected exit 0, got $STATUS"
    scenario_check "$([[ "$OUT" == *"pk route"* ]] && printf 1 || printf 0)" "--help usage missing 'pk route'"
    run_pk
    scenario_check "$([[ "$STATUS" -eq 2 ]] && printf 1 || printf 0)" "no-args expected exit 2, got $STATUS"
}

# E5: the router option --offline is forwarded, not swallowed as task text.
e5() {
    run_pk route --offline "the checkout endpoint returns 500"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "expected exit 0, got $STATUS"
    scenario_check "$([[ "$OUT" == *"Forced offline deterministic routing"* ]] && printf 1 || printf 0)" "--offline was not forwarded to the router"
}

# E6: --help is forwarded and shows the router usage instead of classifying.
e6() {
    run_pk route --help
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "expected exit 0, got $STATUS"
    scenario_check "$([[ "$OUT" == *"Usage:"* ]] && printf 1 || printf 0)" "--help was not forwarded to the router"
}

begin; e1; report 'E1 pk route classifies and exits 0 without side effects'
begin; e2; report 'E2 unknown subcommand exits 2 naming workflows/<cmd>.md'
begin; e3; report 'E3 route output matches the shared Bash/PowerShell parity literal'
begin; e4; report 'E4 --help exits 0; no arguments exits 2'
begin; e5; report 'E5 route --offline is forwarded to the router'
begin; e6; report 'E6 route --help is forwarded to the router'

printf 'Passed: %s | Failed: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
