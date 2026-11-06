#!/usr/bin/env bash
# Regression harness for the CHANGELOG behavior-surface gate.
# Run from repository root: bash scripts/tests/run-changelog-gate-tests.sh
#
# Every case builds a throwaway repository with a base commit and one head
# commit, then runs the real gate against that committed range. A repository
# fixture keeps the gate on its real code path: git range, synthetic-base
# preflight, and path classification are all exercised, not mocked.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
GATE="$REPO_ROOT/scripts/check-changelog-entry.sh"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0
SCENARIO_OK=1
STATUS=0
OUT=""

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
want_status() { scenario_check "$([[ "$STATUS" -eq "$1" ]] && printf 1 || printf 0)" "expected exit $1, got $STATUS"; }
want_contains() { scenario_check "$([[ "$OUT" == *"$1"* ]] && printf 1 || printf 0)" "stdout missing: $1"; }
want_not_contains() { scenario_check "$([[ "$OUT" != *"$1"* ]] && printf 1 || printf 0)" "stdout unexpectedly contains: $1"; }

make_repo() {
    local dir="$TMP/$1"
    mkdir -p "$dir" || return 1
    git -C "$dir" init -q || return 1
    git -C "$dir" config user.name Fixture || return 1
    git -C "$dir" config user.email fixture@example.invalid || return 1
    printf 'base\n' > "$dir/file.txt"
    git -C "$dir" add -A || return 1
    git -C "$dir" commit -qm 'base' || return 1
    printf '%s' "$dir"
}

commit_paths() {
    local dir="$1" path
    shift
    for path in "$@"; do
        mkdir -p "$dir/$(dirname -- "$path")" || return 1
        printf 'change\n' > "$dir/$path" || return 1
    done
    git -C "$dir" add -A || return 1
    git -C "$dir" commit -qm 'change' || return 1
}

run_gate() {
    local root="$1"
    STATUS=0
    OUT="$(cd "$root" && bash "$GATE" --base HEAD~1 --head HEAD 2>&1)" || STATUS=$?
}

# C1: a benchmark driver change without an entry is a behavior-surface miss.
begin
C1_ROOT="$(make_repo c1)" && commit_paths "$C1_ROOT" benchmarks/run-ab-benchmark.sh && run_gate "$C1_ROOT"
want_status 1
want_contains 'CHANGELOG_GATE|MISSING|'
want_contains 'benchmarks/run-ab-benchmark.sh'
want_not_contains 'CHANGELOG_GATE|PASS|'
report 'C1 benchmark driver without CHANGELOG -> MISSING'

# C2: the same driver change with an [Unreleased] entry passes.
begin
C2_ROOT="$(make_repo c2)" && commit_paths "$C2_ROOT" benchmarks/run-ab-benchmark.sh CHANGELOG.md && run_gate "$C2_ROOT"
want_status 0
want_contains 'CHANGELOG_GATE|PASS|behavior-surface changes carry a CHANGELOG.md entry'
report 'C2 benchmark driver with CHANGELOG -> PASS'

# C3: documentation under benchmarks/ is not a behavior surface.
begin
C3_ROOT="$(make_repo c3)" && commit_paths "$C3_ROOT" benchmarks/README.md && run_gate "$C3_ROOT"
want_status 0
want_contains 'CHANGELOG_GATE|PASS|no behavior-surface paths in range'
report 'C3 benchmark documentation without CHANGELOG -> PASS (not gated)'

printf '\nCHANGELOG_GATE_TESTS|%d passed|%d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
