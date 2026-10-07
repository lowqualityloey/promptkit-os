#!/usr/bin/env bash
# Regression harness for the read-only gitignore preflight of pk:checkpoint.
# Run from repository root: bash scripts/tests/run-checkpoint-ignore-tests.sh
#
# Each scenario runs in its own throwaway git repository. The scanner is
# read-only: S1-S4, S9 and S10 also assert the index and worktree status are
# byte-identical before and after the scan (the removed force-add regression
# lock).

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
SCANNER="$REPO_ROOT/scripts/check-checkpoint-ignore.sh"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0
SCENARIO_OK=1

pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

begin() { SCENARIO_OK=1; }

report() {
    if [[ "$SCENARIO_OK" -eq 1 ]]; then pass "$1"; else fail "$1"; fi
}

scenario_check() {
    # $1 = 1 when the condition held, 0 otherwise; $2 = description.
    if [[ "$1" -ne 1 ]]; then
        printf '  - %s\n' "$2"
        SCENARIO_OK=0
    fi
}

want_status() { scenario_check "$([[ "$STATUS" -eq "$1" ]] && printf 1 || printf 0)" "expected exit $1, got $STATUS"; }
want_contains() { scenario_check "$([[ "$OUT" == *"$1"* ]] && printf 1 || printf 0)" "stdout missing: $1"; }
want_not_contains() { scenario_check "$([[ "$OUT" != *"$1"* ]] && printf 1 || printf 0)" "stdout unexpectedly contains: $1"; }
want_unchanged() { scenario_check "$([[ "$1" == "$2" ]] && printf 1 || printf 0)" "git index/status changed across the scan"; }

snapshot() { git -C "$1" diff --cached --name-only 2>/dev/null; git -C "$1" status --porcelain=v1 --untracked-files=all 2>/dev/null; }

run_scanner() {
    local root="$1"
    shift
    STATUS=0
    OUT="$(bash "$SCANNER" --root "$root" "$@")" || STATUS=$?
}

make_repo() {
    local name="$1"
    local dir="$TMP/$name"
    mkdir -p "$dir/docs/tasks"
    printf '# State\n' > "$dir/docs/STATE.md"
    printf '# Task 1\n' > "$dir/docs/tasks/TASK-1.md"
    git -C "$dir" init -q
    printf '%s' "$dir"
}

# S1: no ignore rule => clean, nothing reported, index untouched.
s1() {
    local root before after
    root="$(make_repo s1)"
    before="$(snapshot "$root")"
    run_scanner "$root"
    after="$(snapshot "$root")"
    want_status 0
    want_contains 'CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=5'
    want_not_contains 'POLICY_LIMITATION|'
    want_unchanged "$before" "$after"
}

# S2: docs/ ignored => all five probes reported with the verbatim rule, degraded.
s2() {
    local root before after
    root="$(make_repo s2)"
    printf 'docs/\n' > "$root/.gitignore"
    before="$(snapshot "$root")"
    run_scanner "$root"
    after="$(snapshot "$root")"
    want_status 0
    want_contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/STATE.md|'
    want_contains '.gitignore:1:docs/'
    want_contains 'CHECKPOINT_IGNORE|DEGRADED|IGNORED=5|SCANNED=5'
    want_unchanged "$before" "$after"
}

# S3: broken git (exit 3) => fail-closed INCOMPLETE, never a success summary.
s3() {
    local root stubdir
    root="$(make_repo s3)"
    stubdir="$TMP/s3-stub"
    mkdir -p "$stubdir"
    printf '#!/bin/sh\nexit 3\n' > "$stubdir/git"
    chmod +x "$stubdir/git"
    STATUS=0
    OUT="$(PATH="$stubdir:$PATH" bash "$SCANNER" --root "$root")" || STATUS=$?
    want_status 2
    want_contains 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_IGNORE|'
    want_not_contains 'NO_FINDINGS'
    want_not_contains 'DEGRADED'
}

# S4: tracked-but-matches-ignore is visible to git => not reported (no --no-index);
# the ignored directory itself and the two prospective probes still degrade.
s4() {
    local root before after
    root="$(make_repo s4)"
    printf 'docs/\n' > "$root/.gitignore"
    git -C "$root" add -f docs/STATE.md
    before="$(snapshot "$root")"
    run_scanner "$root"
    after="$(snapshot "$root")"
    want_status 0
    want_not_contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/STATE.md|'
    want_contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/TASK-1.md|'
    want_contains 'CHECKPOINT_IGNORE|DEGRADED|IGNORED=4|SCANNED=5'
    want_unchanged "$before" "$after"
}

# S5: unreadable targets file => INCOMPLETE RULES.
s5() {
    local root
    root="$(make_repo s5)"
    run_scanner "$root" --targets-file /nonexistent/checkpoint-targets.txt
    want_status 2
    want_contains 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|.'
}

# S6: no .git under root => INCOMPLETE GIT_METADATA.
s6() {
    local dir="$TMP/s6"
    mkdir -p "$dir/docs/tasks"
    printf '# State\n' > "$dir/docs/STATE.md"
    printf '# Task 1\n' > "$dir/docs/tasks/TASK-1.md"
    run_scanner "$dir"
    want_status 2
    want_contains 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.'
}

# S7: custom targets file skips comments/blanks and scans only its row.
s7() {
    local root targets
    root="$(make_repo s7)"
    targets="$TMP/s7-targets.txt"
    printf '# comment\n\ncustom/notes.md|file\n' > "$targets"
    run_scanner "$root" --targets-file "$targets"
    want_status 0
    want_contains 'CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=1'
}

# S8: malformed rows fail closed before any measurement: a pipe-less row, an
# unknown kind, an empty path, and an extra pipe each yield INCOMPLETE RULES.
s8() {
    local root targets i
    local names=(no-pipe unknown-kind empty-path extra-pipe)
    local rows=( 'docs/STATE.md' 'docs/STATE.md|bogus' '|file' 'a|b|file' )
    for i in "${!names[@]}"; do
        root="$(make_repo "s8-${names[$i]}")"
        targets="$TMP/s8-targets-${names[$i]}.txt"
        printf '%s\n' "${rows[$i]}" > "$targets"
        run_scanner "$root" --targets-file "$targets"
        want_status 2
        want_contains 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|'
        want_not_contains 'NO_FINDINGS'
        want_not_contains 'DEGRADED'
    done
    # The extra-pipe row is reported with each pipe replaced by a space.
    want_contains 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|a b file'
}

# S9: records directory itself is ignored and holds no *.md records => the dir
# probe alone degrades the result.
s9() {
    local root before after
    root="$TMP/s9"
    mkdir -p "$root/docs"
    printf '# State\n' > "$root/docs/STATE.md"
    git -C "$root" init -q
    printf 'docs/tasks/\n' > "$root/.gitignore"
    before="$(snapshot "$root")"
    run_scanner "$root"
    after="$(snapshot "$root")"
    want_status 0
    want_contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/|'
    want_contains '.gitignore:1:docs/tasks/'
    want_contains 'DEGRADED'
    want_not_contains 'NO_FINDINGS'
    want_unchanged "$before" "$after"
}

# S10: a prospective record name is ignored => the probe degrades, the sibling
# handoff probe is untouched.
s10() {
    local root before after
    root="$(make_repo s10)"
    printf '*.checkpoint-*.md\n' > "$root/.gitignore"
    before="$(snapshot "$root")"
    run_scanner "$root"
    after="$(snapshot "$root")"
    want_status 0
    want_contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/pk-probe.checkpoint-1.md|'
    want_contains '.gitignore:1:*.checkpoint-*.md'
    want_not_contains 'POLICY_LIMITATION|CHECKPOINT_IGNORE|docs/tasks/pk-probe.handoff-1.md|'
    want_contains 'DEGRADED'
    want_unchanged "$before" "$after"
}

# S11: git is not launchable (exit 127) => fail-closed INCOMPLETE GIT_IGNORE.
s11() {
    local root stubdir
    root="$(make_repo s11)"
    stubdir="$TMP/s11-stub"
    mkdir -p "$stubdir"
    printf '#!/bin/sh\nexit 127\n' > "$stubdir/git"
    chmod +x "$stubdir/git"
    STATUS=0
    OUT="$(PATH="$stubdir:$PATH" bash "$SCANNER" --root "$root")" || STATUS=$?
    want_status 2
    want_contains 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_IGNORE|docs/STATE.md'
    want_not_contains 'NO_FINDINGS'
    want_not_contains 'DEGRADED'
}

begin; s1; report 'S1 no .gitignore -> clean'
begin; s2; report 'S2 docs/ ignored -> degraded, verbatim rule'
begin; s3; report 'S3 broken git -> INCOMPLETE GIT_IGNORE'
begin; s4; report 'S4 tracked matches ignore -> not reported'
begin; s5; report 'S5 missing targets file -> INCOMPLETE RULES'
begin; s6; report 'S6 no .git -> INCOMPLETE GIT_METADATA'
begin; s7; report 'S7 custom targets file skips comments/blanks'
begin; s8; report 'S8 malformed rows -> INCOMPLETE RULES'
begin; s9; report 'S9 ignored empty records dir -> degraded'
begin; s10; report 'S10 prospective record name ignored -> degraded'
begin; s11; report 'S11 git not launchable -> INCOMPLETE GIT_IGNORE'

printf 'Passed: %s | Failed: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
