#!/usr/bin/env bash
# Benchmark task-card lint: a card's Verify command must run its behavioral
# probe BEFORE the test suite, and must not chain the two halves with && / ||.
# Usage: scripts/check-benchmark-task-cards.sh [--root PATH]
#
# Why: `<suite> && <probe>` makes the probe conditional on the suite. A red
# suite then short-circuits it, B<nnn>.verify.txt carries only test output, and
# every rubric item that depends on behavior becomes ungradeable while
# verify_exit reports the suite's opinion alone. The reverse shape is just as
# bad: a green suite hides a red probe, and the probe's failure arrives as a
# bare exit status with no explanation. The ordering is stated in
# benchmarks/tasks/TEMPLATE-task.md and benchmarks/README.md section 5.
#
# Scope: every benchmarks/tasks/TASK-*.md card. TEMPLATE-task.md is not a card.
# A card with no Verify field, or `Verify: None`, is skipped; a card whose
# Verify is a bare suite has nothing to order and passes. Probe and suite are
# recognized from the documented marker lists below — a probe spelled some
# other way is reviewed by hand rather than guessed, so this gate cannot claim
# more than it checks.
#
# Output: one `TASKCARD|OK|`, `TASKCARD|SKIP|`, or `TASKCARD|FAIL|` line per
# card, then `TASKCARD|SUMMARY|cards=N|failed=M`. Exit 0 when no card fails,
# 1 on a finding or an unusable root, 2 on a usage error.

set -u

ROOT="."
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)
            [ "$#" -lt 2 ] && { echo "TASKCARD|USAGE|--root requires a path"; exit 2; }
            ROOT="$2"; shift 2 ;;
        --root=*)
            ROOT="${1#*=}"; shift ;;
        -h|--help)
            echo "Usage: scripts/check-benchmark-task-cards.sh [--root PATH]"
            exit 0 ;;
        *)
            echo "TASKCARD|USAGE|Unknown argument: $1"
            exit 2 ;;
    esac
done

TASKS_DIR="$ROOT/benchmarks/tasks"
if [ ! -d "$TASKS_DIR" ]; then
    echo "TASKCARD|MISSING_ROOT|no benchmarks/tasks directory under '$ROOT'|Pass --root at the repository root"
    exit 1
fi

# The test suite: an invocation that runs the task's own tests.
SUITE_MARKERS=(
    'node --test'
    'npm test'
    'npm run test'
    'pnpm test'
    'yarn test'
    'bun test'
    'pytest'
    'go test'
    'cargo test'
    'dotnet test'
    'mvn test'
    'gradle test'
    'rspec'
    'mix test'
    'swift test'
    'phpunit'
    'make test'
    'ctest'
)
# The behavioral probe: an inline check run against the artifact.
PROBE_MARKERS=(
    'node --input-type=module'
    'node -e'
    'node --eval'
    'python -c'
    'python3 -c'
)

field() {
    # field <file> <label>: the single-line field value, backticks stripped.
    # Same semantics as the driver's parse_field, so a card odd enough to parse
    # here still parses there.
    local file="$1" label="$2" line
    line="$(grep -m1 -- "^- \*\*$label\*\*: " "$file" || true)"
    [ -n "$line" ] || return 0
    line="${line#- \*\*$label\*\*: }"
    line="${line%$'\r'}"
    line="${line#\`}"
    line="${line%\`}"
    printf '%s' "$line"
}

first_marker() {
    # first_marker <haystack> <marker>...: "<index>TAB<marker>" for the
    # earliest marker, or "-1<TAB>" when nothing matched. It prints rather than
    # setting a variable because it runs in a command substitution.
    local hay="$1" marker prefix best=-1 best_marker=""
    shift
    for marker in "$@"; do
        case "$hay" in
            *"$marker"*) ;;
            *) continue ;;
        esac
        prefix="${hay%%"$marker"*}"
        if [ "$best" -lt 0 ] || [ "${#prefix}" -lt "$best" ]; then
            best="${#prefix}"
            best_marker="$marker"
        fi
    done
    printf '%s\t%s' "$best" "$best_marker"
}

cards=0
failed=0
shopt -s nullglob
for card in "$TASKS_DIR"/TASK-*.md; do
    cards=$((cards + 1))
    id="$(field "$card" 'Task ID')"
    [ -n "$id" ] || id="$(basename "$card" .md)"
    verify="$(field "$card" 'Verify')"
    if [ -z "$verify" ] || [ "$verify" = "None" ]; then
        printf 'TASKCARD|SKIP|%s|no Verify command\n' "$id"
        continue
    fi

    reasons=()
    IFS=$'\t' read -r suite_idx suite_marker <<<"$(first_marker "$verify" "${SUITE_MARKERS[@]}")"
    IFS=$'\t' read -r probe_idx probe_marker <<<"$(first_marker "$verify" "${PROBE_MARKERS[@]}")"

    if [ "$suite_idx" -ge 0 ] && [ "$probe_idx" -ge 0 ] && [ "$suite_idx" -lt "$probe_idx" ]; then
        reasons+=("the test suite ($suite_marker) runs before the behavioral probe ($probe_marker)")
    fi

    if [ "$suite_idx" -ge 0 ]; then
        before="${verify%%"$suite_marker"*}"
        after="${verify#*"$suite_marker"}"
        # Probe earlier in the command: the suite must not be short-circuited
        # onto it, or a red probe skips the suite and a red probe's status is
        # never reached independently.
        if [ "$probe_idx" -ge 0 ] && [ "$probe_idx" -lt "$suite_idx" ]; then
            before="${before%"${before##*[![:space:]]}"}"
            case "$before" in
                *'&&'|*'||') reasons+=("the test suite is chained to the probe with a short-circuit connector") ;;
            esac
        fi
        # Suite earlier in the command: a connector here is what makes the
        # probe conditional, i.e. the defect this gate exists for.
        if [ "$probe_idx" -ge 0 ] && [ "$suite_idx" -lt "$probe_idx" ]; then
            after="${after#"${after%%[![:space:]]*}"}"
            case "$after" in
                '&&'*|'||'*) reasons+=("the test suite is chained to the probe with a short-circuit connector") ;;
            esac
        fi
    fi

    if [ "${#reasons[@]}" -eq 0 ]; then
        printf 'TASKCARD|OK|%s\n' "$id"
        continue
    fi
    failed=$((failed + 1))
    joined="$(printf '%s; ' "${reasons[@]}")"
    printf 'TASKCARD|FAIL|%s|%s\n' "$id" "${joined%; }"
done

if [ "$cards" -eq 0 ]; then
    echo "TASKCARD|MISSING_CARDS|no benchmarks/tasks/TASK-*.md cards under '$ROOT'|Pass --root at the repository root"
    exit 1
fi

printf 'TASKCARD|SUMMARY|cards=%s|failed=%s\n' "$cards" "$failed"
if [ "$failed" -gt 0 ]; then
    echo "TASKCARD|REMEDIATION|Run the behavioral probe first, run the test suite second with ';' between them, print VERIFY|probe=<n>|tests=<n>, and exit non-zero if either failed (benchmarks/tasks/TEMPLATE-task.md)"
    exit 1
fi
exit 0
