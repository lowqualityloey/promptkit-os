#!/usr/bin/env bash
# Regression harness for scripts/check-benchmark-task-cards.sh.
# Run from repository root: bash scripts/tests/run-benchmark-task-card-tests.sh
#
# Each case writes throwaway cards under a temp root shaped like the repository
# (<root>/benchmarks/tasks/TASK-*.md) and asserts the lint's exit status and
# machine lines. The last case runs the lint against the real card set, so the
# published cards are pinned to the convention the template states.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
CHECKER="$REPO_ROOT/scripts/check-benchmark-task-cards.sh"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0

pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

STATUS=0
OUT=""

run_check() {
    local root="$1"
    shift
    STATUS=0
    OUT="$(bash "$CHECKER" --root "$root" "$@")" || STATUS=$?
}

make_root() { mkdir -p "$1/benchmarks/tasks"; }

make_card() {
    # make_card <root> <id> <verify-value> [include-verify-field]
    local root="$1" id="$2" value="$3" include="${4:-yes}"
    local file="$root/benchmarks/tasks/TASK-$id.md"
    {
        printf '# Task Spec: fixture\n\n'
        printf -- '- **Task ID**: `%s`\n' "$id"
        printf -- '- **Level**: `L1`\n'
        if [ "$include" = "yes" ]; then
            printf -- '- **Verify**: `%s`\n' "$value"
        fi
    } > "$file"
}

want_status() {
    if [ "$STATUS" -eq "$1" ]; then return 0; fi
    printf '  - expected exit %s, got %s\n' "$1" "$STATUS"
    printf '  - output: %s\n' "$OUT"
    return 1
}

want_contains() {
    case "$OUT" in
        *"$1"*) return 0 ;;
    esac
    printf '  - stdout missing: %s\n  - output: %s\n' "$1" "$OUT"
    return 1
}

want_not_contains() {
    case "$OUT" in
        *"$1"*)
            printf '  - stdout unexpectedly contains: %s\n  - output: %s\n' "$1" "$OUT"
            return 1 ;;
    esac
    return 0
}

scenario() {
    # scenario <name> <assertions...>: each assertion is `fn arg`.
    local name="$1"
    shift
    local ok=1 a fn arg
    for a in "$@"; do
        fn="${a%% *}"
        arg="${a#* }"
        if ! "$fn" "$arg"; then ok=0; fi
    done
    if [ "$ok" -eq 1 ]; then pass "$name"; else fail "$name"; fi
}

# --- 1. compliant shape: probe first, suite second, gate last ---------------
R="$TMP/pass"
make_root "$R"
make_card "$R" "BENCH-T-01" 'node --input-type=module -e "console.log(1)"; probe=$?; node --test; tests=$?; printf "VERIFY|probe=%s|tests=%s\n" "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]'
run_check "$R"
scenario "compliant probe-first card passes" \
    "want_status 0" "want_contains TASKCARD|OK|BENCH-T-01" "want_contains cards=1|failed=0"

# --- 2. the defect this gate exists for: suite && probe ---------------------
R="$TMP/suite-and"
make_root "$R"
make_card "$R" "BENCH-T-02" 'node --test && node --input-type=module -e "console.log(1)"'
run_check "$R"
scenario "suite chained before the probe fails" \
    "want_status 1" "want_contains TASKCARD|FAIL|BENCH-T-02" \
    "want_contains runs before the behavioral probe"

# --- 3. probe joined to the suite with a connector --------------------------
R="$TMP/probe-and"
make_root "$R"
make_card "$R" "BENCH-T-03" 'node --input-type=module -e "console.log(1)" && node --test'
run_check "$R"
scenario "probe chained to the suite fails" \
    "want_status 1" "want_contains TASKCARD|FAIL|BENCH-T-03" \
    "want_contains chained to the probe"

# --- 4. right halves, wrong order, separated by a semicolon ----------------
R="$TMP/suite-first"
make_root "$R"
make_card "$R" "BENCH-T-04" 'node --test; node --input-type=module -e "console.log(1)"; probe=$?; tests=$?'
run_check "$R"
scenario "suite first with a semicolon still fails on order" \
    "want_status 1" "want_contains TASKCARD|FAIL|BENCH-T-04" \
    "want_contains runs before the behavioral probe"

# --- 5. a bare suite has nothing to order ---------------------------------
R="$TMP/bare"
make_root "$R"
make_card "$R" "BENCH-T-05" 'npm test'
run_check "$R"
scenario "bare suite card passes" \
    "want_status 0" "want_contains TASKCARD|OK|BENCH-T-05"

# --- 6. setup chained to a suite is not a probe boundary -------------------
R="$TMP/setup"
make_root "$R"
make_card "$R" "BENCH-T-06" 'npm ci && npm test'
run_check "$R"
scenario "setup joined to the suite is allowed" \
    "want_status 0" "want_contains TASKCARD|OK|BENCH-T-06"

# --- 7. no Verify command --------------------------------------------------
R="$TMP/none"
make_root "$R"
make_card "$R" "BENCH-T-07" 'None'
run_check "$R"
scenario "Verify None is skipped" \
    "want_status 0" "want_contains TASKCARD|SKIP|BENCH-T-07"

# --- 8. Verify field absent entirely --------------------------------------
R="$TMP/absent"
make_root "$R"
make_card "$R" "BENCH-T-08" '' no
run_check "$R"
scenario "absent Verify field is skipped" \
    "want_status 0" "want_contains TASKCARD|SKIP|BENCH-T-08"

# --- 9. unusable root ------------------------------------------------------
run_check "$TMP/does-not-exist"
scenario "missing root fails closed" \
    "want_status 1" "want_contains TASKCARD|MISSING_ROOT"

# --- 10. no cards ----------------------------------------------------------
R="$TMP/empty"
make_root "$R"
run_check "$R"
scenario "empty card directory fails closed" \
    "want_status 1" "want_contains TASKCARD|MISSING_CARDS"

# --- 11. usage error -------------------------------------------------------
run_check "$TMP/pass" --bogus
scenario "unknown argument is a usage error" \
    "want_status 2" "want_contains TASKCARD|USAGE"

# --- 12. the real card set -------------------------------------------------
run_check "$REPO_ROOT"
scenario "repository cards satisfy the convention" \
    "want_status 0" "want_contains TASKCARD|OK|BENCH-L2-01" \
    "want_contains TASKCARD|OK|BENCH-L1-02" \
    "want_contains TASKCARD|SKIP|BENCH-L1-01" \
    "want_contains failed=0"

printf 'RESULTS|passed=%s|failed=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
