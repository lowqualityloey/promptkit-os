#!/usr/bin/env bash
# Regression harness for the read-only pk:doctor detector (#547).
# Run from repository root: bash scripts/tests/run-doctor-tests.sh
#
# Each scenario builds its own throwaway kit root under a temp dir; scenarios
# that need git behavior `git init` a disposable repository inside that root.
# S10 asserts the default (no --fix) run leaves the tree byte-identical.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
CHECKER="$REPO_ROOT/scripts/check-doctor.sh"

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
want_all_ok() {
    local bad
    bad="$(printf '%s\n' "$OUT" | awk -F'\t' 'NF >= 2 && $2 != "OK" { print }')"
    scenario_check "$([[ -z "$bad" ]] && printf 1 || printf 0)" "expected every row OK; offending rows: $bad"
}

STATUS=0
OUT=""
run_doctor() {
    local root="$1"
    shift
    STATUS=0
    OUT="$(bash "$CHECKER" "$root" "$@" 2>&1)" || STATUS=$?
}

snapshot_tree() { (builtin cd -- "$1" && tar --exclude=.git -cf - . 2>/dev/null | sha1sum); }

HOST_RELS="AGENTS.md CLAUDE.md .opencode/rules.md .cursorrules GEMINI.md .windsurfrules .github/copilot-instructions.md .clinerules .traerules CONVENTIONS.md"

make_kit() {
    local name="$1" profile="${2:-balanced}"
    local dir="$TMP/$name"
    mkdir -p "$dir/docs/tasks" "$dir/.opencode" "$dir/.github"
    printf 'profile: %s\n' "$profile" > "$dir/PROMPTKIT.md"
    git -C "$dir" init -q
    git -C "$dir" config user.name Fixture
    git -C "$dir" config user.email fixture@example.invalid
    printf '# State\n' > "$dir/docs/STATE.md"
    git -C "$dir" add -A
    git -C "$dir" commit -qm 'base'
    git -C "$dir" branch -M main 2>/dev/null || true
    git -C "$dir" update-ref refs/remotes/origin/main HEAD
    printf '%s' "$dir"
}

write_hosts() {
    local dir="$1" sha="$2" rel
    for rel in $HOST_RELS; do
        mkdir -p "$dir/$(dirname -- "$rel")"
        {
            printf '<!-- PROMPTKIT_START -->\n'
            printf '## PromptKit OS\n'
            printf 'Engine: v1.2.3 (%s) - stamped at install time\n' "$sha"
            printf 'Lite - 6 workflows\n'
            printf '<!-- PROMPTKIT_END -->\n'
        } > "$dir/$rel"
    done
}

write_state() {
    local dir="$1" sha="$2" exec_state="${3:-completed}" id="${4:-TASK-2026-01-01-fixture}"
    cat > "$dir/docs/STATE.md" <<EOF
# Project State & Living Execution Tracker

## 1. Executive Summary & Current Position
- **Engine Version**: v1.2.3 @ $sha

---

## 3A. Execution-Control Projection (Optional)

- **Task ID**: \`$id\`
- **Task Record**: \`docs/tasks/$id.md\`
- **Execution State**: \`$exec_state\`
- **Ceremony Level**: \`Level 2 (Controlled)\`

---

## 4. Locked Technical Invariants (Do Not Undo)
- none
EOF
}

write_task() {
    local dir="$1" id="$2" exec_state="${3:-completed}"
    cat > "$dir/docs/tasks/$id.md" <<EOF
# Task Record: fixture

- **Task ID**: \`$id\`
- **Owner / Actor**: \`Implementor\`

## 5. State and Active Ownership
- **Execution State**: \`$exec_state\`
EOF
}

make_healthy() {
    local name="$1" profile="${2:-balanced}"
    local dir sha
    dir="$(make_kit "$name" "$profile")"
    sha="$(git -C "$dir" rev-parse --short HEAD)"
    write_hosts "$dir" "$sha" "$profile"
    write_state "$dir" "$sha"
    write_task "$dir" "TASK-2026-01-01-fixture" "completed"
    printf '%s' "$dir"
}

# S1 (Scenario 1): a healthy Balanced install reports every row OK, exit 0.
s1() {
    local root
    root="$(make_healthy s1 balanced)"
    run_doctor "$root"
    want_status 0
    want_all_ok
}

# S2 (Scenario 2, the loey_space replay): stale engine, an ignored managed
# path, and a STATE 3A projection diverging from the canonical Task Record.
s2() {
    local root tip i sha
    root="$(make_healthy s2 balanced)"
    git -C "$root" checkout -q -b stale
    i=1
    while [[ "$i" -le 8 ]]; do
        printf 'stale %s\n' "$i" >> "$root/stale.txt"
        git -C "$root" add stale.txt
        git -C "$root" commit -qm "stale $i"
        i=$((i + 1))
    done
    tip="$(git -C "$root" rev-parse HEAD)"
    git -C "$root" checkout -q main
    git -C "$root" update-ref refs/remotes/origin/main "$tip"
    printf 'docs/\n' > "$root/.gitignore"
    sha="$(git -C "$root" rev-parse --short HEAD)"
    write_state "$root" "$sha" "in_progress"
    run_doctor "$root"
    want_status 1
    want_contains $'version\tSTALE(+8)'
    want_contains 'engine v1.2.3 is 8 commit(s) behind'
    want_contains $'ignore:docs\tIGNORED('
    want_contains '.gitignore:1:docs/'
    want_contains $'docs-drift\tDIVERGED('
    want_contains 'Execution State'
}

# S3 (Scenario 3): an intentional ignore alone does not fail health.
s3() {
    local root
    root="$(make_healthy s3 balanced)"
    printf 'docs/\n' > "$root/.gitignore"
    run_doctor "$root"
    want_status 0
    want_contains $'ignore:docs\tIGNORED(.gitignore:1:docs/)'
    want_not_contains 'STALE'
    want_not_contains $'\tMISSING'
    want_not_contains 'DIVERGED'
}

# S4 (Scenario 4): no handoff.md and no canonical Task Record degrades to SKIP.
s4() {
    local root sha
    root="$(make_kit s4 balanced)"
    sha="$(git -C "$root" rev-parse --short HEAD)"
    write_hosts "$root" "$sha" balanced
    cat > "$root/docs/STATE.md" <<EOF
# Project State
- **Engine Version**: v1.2.3 @ $sha

## 3A. Execution-Control Projection (Optional)
- **Task ID**: \`TASK-<task-id>\`
- **Task Record**: \`docs/tasks/<task-id>.md\`
- **Execution State**: \`[planned]\`
EOF
    run_doctor "$root"
    want_status 0
    want_contains $'docs-drift\tSKIP(no task record)'
    want_not_contains 'DIVERGED'
}

# S5 (Scenario 5): a Lite install expects only the 6 Lite workflows; no row is
# flagged MISSING for Balanced-only workflows.
s5() {
    local root
    root="$(make_healthy s5 lite)"
    run_doctor "$root"
    want_status 0
    want_all_ok
    want_not_contains $'\tMISSING'
}

# S6 (Scenario 6): an unexpected git exit status is fail-closed INCOMPLETE and
# exit 1, never OK and never 2.
s6() {
    local root fakebin
    root="$(make_healthy s6 balanced)"
    fakebin="$TMP/s6-bin"
    mkdir -p "$fakebin"
    printf '#!/bin/sh\nexit 3\n' > "$fakebin/git"
    chmod +x "$fakebin/git"
    STATUS=0
    OUT="$(PATH="$fakebin:$PATH" bash "$CHECKER" "$root" 2>&1)" || STATUS=$?
    want_status 1
    want_contains $'ignore:.\tINCOMPLETE'
    want_contains 'unexpected status 3'
    want_not_contains 'ignore:.	OK'
}

# S7 (Scenario 7): a host file present but missing the block is MISSING.
s7() {
    local root sha
    root="$(make_kit s7 balanced)"
    sha="$(git -C "$root" rev-parse --short HEAD)"
    write_hosts "$root" "$sha" balanced
    printf '# Agent notes without the managed block\n' > "$root/AGENTS.md"
    run_doctor "$root"
    want_status 1
    want_contains $'host:AGENTS.md\tMISSING'
}

# S8 (Scenario 8): absent PROMPTKIT.md is the exit-2 could-not-run prerequisite.
s8() {
    local root
    root="$TMP/s8"
    mkdir -p "$root"
    run_doctor "$root"
    want_status 2
    want_contains $'prereq\tINCOMPLETE'
    want_contains 'no PROMPTKIT.md at KIT_ROOT'
}

# S9 (--fix): re-emits the missing block and leaves a healthy run.
s9() {
    local root sha
    root="$(make_kit s9 balanced)"
    sha="$(git -C "$root" rev-parse --short HEAD)"
    write_hosts "$root" "$sha" balanced
    printf '# Agent notes without the managed block\n' > "$root/AGENTS.md"
    run_doctor "$root"
    want_status 1
    want_contains $'host:AGENTS.md\tMISSING'
    run_doctor "$root" --fix
    want_status 0
    want_contains 're-emitted by --fix'
    want_contains $'host:AGENTS.md\tOK'
    if ! grep -qE '^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*$' "$root/AGENTS.md"; then
        scenario_check 0 'AGENTS.md does not contain the managed block after --fix'
    fi
}

# S10: without --fix the doctor is read-only; the tree is byte-identical.
s10() {
    local root before after
    root="$(make_healthy s10 balanced)"
    before="$(snapshot_tree "$root")"
    run_doctor "$root"
    after="$(snapshot_tree "$root")"
    want_status 0
    scenario_check "$([[ "$before" == "$after" ]] && printf 1 || printf 0)" 'tree changed across a default (no --fix) run'
}

begin; s1; report 'S1 healthy Balanced install -> all OK, exit 0'
begin; s2; report 'S2 stale engine + ignored path + diverged projection -> exit 1'
begin; s3; report 'S3 intentional ignore alone -> IGNORED, exit 0'
begin; s4; report 'S4 no handoff and no Task Record -> docs-drift SKIP'
begin; s5; report 'S5 Lite install -> no MISSING for Balanced-only'
begin; s6; report 'S6 unexpected git status -> INCOMPLETE, exit 1'
begin; s7; report 'S7 host file missing the block -> MISSING'
begin; s8; report 'S8 absent PROMPTKIT.md -> exit 2'
begin; s9; report 'S9 --fix re-emits the missing block'
begin; s10; report 'S10 default run is read-only (tree unchanged)'

printf 'Passed: %s | Failed: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
