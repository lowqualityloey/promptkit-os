#!/usr/bin/env bash
# Regression harness for the read-only synthetic-base preflight.
# Run from repository root: bash scripts/tests/run-synthetic-base-tests.sh
#
# Each scenario runs in its own throwaway git repository. S11 also asserts the
# index and worktree are byte-identical before and after the scan (the
# read-only lock); every other scenario exercises a verdict or a fail-closed row.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
CHECKER="$REPO_ROOT/scripts/check-synthetic-base.sh"
CHANGELOG_GATE="$REPO_ROOT/scripts/check-changelog-entry.sh"

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
want_status() { scenario_check "$([[ "$STATUS" -eq "$1" ]] && printf 1 || printf 0)" "expected exit $1, got $STATUS"; }
want_contains() { scenario_check "$([[ "$OUT" == *"$1"* ]] && printf 1 || printf 0)" "stdout missing: $1"; }
want_not_contains() { scenario_check "$([[ "$OUT" != *"$1"* ]] && printf 1 || printf 0)" "stdout unexpectedly contains: $1"; }
want_unchanged() { scenario_check "$([[ "$1" == "$2" ]] && printf 1 || printf 0)" "worktree/index changed across the scan"; }

STATUS=0
OUT=""
run_checker() {
    local root="$1"
    shift
    STATUS=0
    OUT="$(bash "$CHECKER" --root "$root" "$@")" || STATUS=$?
}
snapshot() { git -C "$1" diff --cached --name-only 2>/dev/null; git -C "$1" status --porcelain=v1 --untracked-files=all 2>/dev/null; }

make_repo() {
    local dir="$TMP/$1"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.name Fixture
    git -C "$dir" config user.email fixture@example.invalid
    printf 'base\n' > "$dir/file.txt"
    git -C "$dir" add file.txt
    git -C "$dir" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'base commit'
    printf '%s' "$dir"
}

# A fresh detached commit the branch does not carry: the ordinary shape of both
# a synthetic workspace commit (Viewpoint 2) and a legitimate detached checkout
# (Scenario 6), which only the owned-ref signal tells apart.
make_detached() {
    local dir
    dir="$(make_repo "$1")"
    git -C "$dir" checkout -q --detach HEAD
    printf 'detached\n' > "$dir/detached.txt"
    git -C "$dir" add detached.txt
    git -C "$dir" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'detached commit'
    printf '%s' "$dir"
}

owned_ref() { git -C "$1" update-ref "$2" HEAD; }

# S1 (Scenario 1): a normal branch HEAD is silent.
s1() {
    local root
    root="$(make_repo s1)"
    run_checker "$root"
    want_status 0
    want_contains 'SYNTHETIC_BASE|OK|'
    want_not_contains 'REFUSE'
}

# S2 (Scenario 2): an owned tool ref with no carrying branch is refused, with
# recovery steps and the MAXIMS citation.
s2() {
    local root
    root="$(make_detached s2)"
    owned_ref "$root" refs/gitbutler/wt
    run_checker "$root"
    want_status 1
    want_contains 'SYNTHETIC_BASE|REFUSE|'
    want_contains 'owned-ref=refs/gitbutler/wt'
    want_contains 'SYNTHETIC_BASE|RECOVERY|'
    want_contains 'docs/MAXIMS.md'
}

# S3 (Scenario 3): a normal carrying branch with unpushed commits proceeds;
# unpushed state alone is never a fault.
s3() {
    local root
    root="$(make_repo s3)"
    printf 'more\n' > "$root/file.txt"
    git -C "$root" add file.txt
    git -C "$root" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'unpushed commit'
    run_checker "$root"
    want_status 0
    want_contains 'SYNTHETIC_BASE|OK|'
    want_not_contains 'REFUSE'
}

# S4 (Scenario 4 + 6): a detached real commit with no owned ref has no positive
# evidence, so it reports UNKNOWN and proceeds rather than refusing.
s4() {
    local root
    root="$(make_detached s4)"
    run_checker "$root"
    want_status 0
    want_contains 'SYNTHETIC_BASE|UNKNOWN|'
    want_not_contains 'REFUSE'
}

# S5: a custom signals file narrows the owned namespaces; comments and blanks
# are skipped, and only the listed namespace is refused.
s5() {
    local root
    root="$(make_detached s5)"
    printf '# comment\n\nref-namespace|refs/custom/\n' > "$TMP/s5.txt"
    owned_ref "$root" refs/gitbutler/wt
    STATUS=0
    OUT="$(bash "$CHECKER" --root "$root" --signals-file "$TMP/s5.txt")" || STATUS=$?
    want_status 0
    want_contains 'SYNTHETIC_BASE|UNKNOWN|'
    want_not_contains 'REFUSE'
    owned_ref "$root" refs/custom/thing
    run_checker "$root" --signals-file "$TMP/s5.txt"
    want_status 1
    want_contains 'owned-ref=refs/custom/thing'
}

# S6: PROMPTKIT_SYNTHETIC_REFS_EXTRA adds a project namespace.
s6() {
    local root
    root="$(make_detached s6)"
    owned_ref "$root" refs/custom/ns
    STATUS=0
    OUT="$(PROMPTKIT_SYNTHETIC_REFS_EXTRA='refs/custom/' bash "$CHECKER" --root "$root")" || STATUS=$?
    want_status 1
    want_contains 'owned-ref=refs/custom/ns'
}

# S7: a malformed row and an unreadable file both fail closed as INCOMPLETE RULES.
s7() {
    local root
    root="$(make_repo s7)"
    printf 'not-a-row\n' > "$TMP/s7-bad.txt"
    run_checker "$root" --signals-file "$TMP/s7-bad.txt"
    want_status 2
    want_contains 'SYNTHETIC_BASE|INCOMPLETE|RULES|not-a-row'
    run_checker "$root" --signals-file "$TMP/s7-missing.txt"
    want_status 2
    want_contains 'SYNTHETIC_BASE|INCOMPLETE|RULES|.'
}

# S8: no repository under root fails closed as INCOMPLETE GIT_METADATA.
s8() {
    mkdir -p "$TMP/s8"
    run_checker "$TMP/s8"
    want_status 2
    want_contains 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.'
}

# S9: an unresolvable commit fails closed as INCOMPLETE COMMIT.
s9() {
    local root
    root="$(make_repo s9)"
    run_checker "$root" --commit deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
    want_status 2
    want_contains 'SYNTHETIC_BASE|INCOMPLETE|COMMIT|'
}

# S10: an owned ref that is ALSO carried by a branch is ordinary (a tool
# checkpoint on a live branch) — positive evidence alone is not enough.
s10() {
    local root
    root="$(make_repo s10)"
    owned_ref "$root" refs/gitbutler/wt
    run_checker "$root"
    want_status 0
    want_contains 'SYNTHETIC_BASE|OK|'
    want_not_contains 'REFUSE'
}

# S11: the scan never mutates the index or worktree.
s11() {
    local root before after
    root="$(make_detached s11)"
    owned_ref "$root" refs/gitbutler/wt
    before="$(snapshot "$root")"
    run_checker "$root"
    after="$(snapshot "$root")"
    want_status 1
    want_unchanged "$before" "$after"
}

# S12: the changelog gate refuses a synthetic HEAD before deriving its range.
s12() {
    local root
    root="$(make_detached s12)"
    owned_ref "$root" refs/gitbutler/wt
    STATUS=0
    OUT="$(cd "$root" && bash "$CHANGELOG_GATE" --base HEAD --head HEAD 2>&1)" || STATUS=$?
    want_status 1
    want_contains 'CHANGELOG_GATE|SYNTHETIC-BASE|'
    want_contains 'SYNTHETIC_BASE|REFUSE|'
}

begin; s1; report 'S1 normal branch HEAD -> OK'
begin; s2; report 'S2 owned ref, no carrying branch -> REFUSE'
begin; s3; report 'S3 unpushed carrying branch -> OK'
begin; s4; report 'S4 detached real commit -> UNKNOWN'
begin; s5; report 'S5 custom signals file narrows namespaces'
begin; s6; report 'S6 PROMPTKIT_SYNTHETIC_REFS_EXTRA extends namespaces'
begin; s7; report 'S7 malformed/unreadable signals -> INCOMPLETE RULES'
begin; s8; report 'S8 no repository -> INCOMPLETE GIT_METADATA'
begin; s9; report 'S9 unresolvable commit -> INCOMPLETE COMMIT'
begin; s10; report 'S10 owned ref carried by a branch -> OK'
begin; s11; report 'S11 scan leaves index/worktree unchanged'
begin; s12; report 'S12 changelog gate refuses synthetic HEAD'

printf 'Passed: %s | Failed: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
