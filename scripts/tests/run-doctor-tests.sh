#!/usr/bin/env bash
# Regression harness for the read-only pk:doctor detector (#547).
# Run from repository root: bash scripts/tests/run-doctor-tests.sh
#
# Every fixture is a real nested install: the project root ($root) holds
# PROMPTKIT.md, docs/, host files and the project git repo, while the engine
# lives at $root/.promptkit (a copy of the real checker plus the templates and
# workflows it references). Git-init the engine for version fixtures and the
# project for ignore fixtures. S10 asserts the default (no --fix) run leaves the
# tree byte-identical.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
SRC_CHECKER="$REPO_ROOT/scripts/check-doctor.sh"

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
    local checker="$root/.promptkit/scripts/check-doctor.sh"
    [[ -f "$checker" ]] || checker="$SRC_CHECKER"
    STATUS=0
    OUT="$(bash "$checker" "$root" "$@" 2>&1)" || STATUS=$?
}

snapshot_tree() { (builtin cd -- "$1" && tar --exclude=.git -cf - . 2>/dev/null | sha1sum); }

HOST_RELS="AGENTS.md CLAUDE.md .opencode/rules.md .cursorrules GEMINI.md .windsurfrules .github/copilot-instructions.md .clinerules .traerules CONVENTIONS.md"

# Lay down the engine copy at $dir/.promptkit: the real checker plus the
# templates and the route workflow its rendered block references.
install_engine() {
    local dir="$1"
    mkdir -p "$dir/.promptkit/scripts" "$dir/.promptkit/templates" "$dir/.promptkit/workflows"
    cp "$SRC_CHECKER" "$dir/.promptkit/scripts/check-doctor.sh"
    cp "$REPO_ROOT/templates/agent-directive-template.md" "$dir/.promptkit/templates/"
    cp "$REPO_ROOT/templates/agent-directive-lite-template.md" "$dir/.promptkit/templates/"
    cp "$REPO_ROOT/workflows/route.md" "$dir/.promptkit/workflows/"
}

init_engine_repo() {
    local dir="$1"
    git -C "$dir/.promptkit" init -q
    git -C "$dir/.promptkit" config user.name Fixture
    git -C "$dir/.promptkit" config user.email fixture@example.invalid
    printf '# engine\n' > "$dir/.promptkit/ENGINE.md"
    git -C "$dir/.promptkit" add -A
    git -C "$dir/.promptkit" commit -qm 'engine base'
    git -C "$dir/.promptkit" branch -M main 2>/dev/null || true
    git -C "$dir/.promptkit" update-ref refs/remotes/origin/main HEAD
}

make_kit() {
    local name="$1" profile="${2:-balanced}"
    local dir="$TMP/$name"
    mkdir -p "$dir/docs/tasks" "$dir/.opencode" "$dir/.github"
    printf 'profile: %s\n' "$profile" > "$dir/PROMPTKIT.md"
    install_engine "$dir"
    init_engine_repo "$dir"
    git -C "$dir" init -q
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
- **Owner / Current Actor**: \`Implementor\`
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
    sha="$(git -C "$dir/.promptkit" rev-parse --short HEAD)"
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
    git -C "$root/.promptkit" checkout -q -b stale
    i=1
    while [[ "$i" -le 8 ]]; do
        printf 'stale %s\n' "$i" >> "$root/.promptkit/stale.txt"
        git -C "$root/.promptkit" add stale.txt
        git -C "$root/.promptkit" commit -qm "stale $i"
        i=$((i + 1))
    done
    tip="$(git -C "$root/.promptkit" rev-parse HEAD)"
    git -C "$root/.promptkit" checkout -q main
    git -C "$root/.promptkit" update-ref refs/remotes/origin/main "$tip"
    printf 'docs/\n' > "$root/.gitignore"
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
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
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
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
    OUT="$(PATH="$fakebin:$PATH" bash "$root/.promptkit/scripts/check-doctor.sh" "$root" 2>&1)" || STATUS=$?
    want_status 1
    want_contains $'ignore:.promptkit\tINCOMPLETE'
    want_contains 'unexpected status 3'
    want_not_contains $'ignore:.promptkit\tOK'
}

# S7 (Scenario 7): a host file present but missing the block is MISSING.
s7() {
    local root sha
    root="$(make_kit s7 balanced)"
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
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
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
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

# N1: a nested engine one commit behind its OWN origin/main is STALE(+1), and a
# project ignore rule on the engine directory is reported against .promptkit.
n1() {
    local root sha tip
    root="$(make_healthy n1 balanced)"
    printf 'engine +1\n' > "$root/.promptkit/extra.txt"
    git -C "$root/.promptkit" add extra.txt
    git -C "$root/.promptkit" commit -qm 'engine +1'
    tip="$(git -C "$root/.promptkit" rev-parse HEAD)"
    git -C "$root/.promptkit" reset -q --hard HEAD~1
    git -C "$root/.promptkit" update-ref refs/remotes/origin/main "$tip"
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
    write_hosts "$root" "$sha" balanced
    write_state "$root" "$sha"
    printf '.promptkit/\n' > "$root/.gitignore"
    run_doctor "$root"
    want_status 1
    want_contains $'version\tSTALE(+1)'
    want_contains 'engine v1.2.3 is 1 commit(s) behind'
    want_contains $'ignore:.promptkit\tIGNORED('
    want_contains '.gitignore:1:.promptkit/'
    want_not_contains $'ignore:.\t'
}

# N2: --fix renders <engine_relpath>/workflows/... and that path exists.
n2() {
    local root
    root="$(make_kit n2 balanced)"
    printf '# Agent notes without the managed block\n' > "$root/AGENTS.md"
    run_doctor "$root" --fix
    want_status 0
    want_contains 're-emitted by --fix'
    scenario_check "$([[ -f "$root/.promptkit/workflows/route.md" ]] && printf 1 || printf 0)" 'engine route.md missing before --fix check'
    if ! grep -q '\.promptkit/workflows/route.md' "$root/AGENTS.md"; then
        scenario_check 0 'rendered block does not reference .promptkit/workflows/route.md'
    fi
    if grep -q 'KIT_DIR_REL' "$root/AGENTS.md"; then
        scenario_check 0 'rendered block left an unsubstituted $KIT_DIR_REL token'
    fi
}

# N3: docs-drift compares every shared 3A/Task-Record field and never bare-OKs
# without a concrete comparison.
n3() {
    local root sha
    root="$(make_kit n3 balanced)"
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
    write_hosts "$root" "$sha" balanced

    # (a) placeholder 3A vs concrete record -> DIVERGED
    cat > "$root/docs/STATE.md" <<EOF
# Project State
- **Engine Version**: v1.2.3 @ $sha

## 3A. Execution-Control Projection (Optional)
- **Task ID**: \`TASK-<task-id>\`
- **Task Record**: \`docs/tasks/TASK-2026-01-01-n3.md\`
- **Execution State**: \`[planned]\`
EOF
    cat > "$root/docs/tasks/TASK-2026-01-01-n3.md" <<'EOF'
# Task Record: n3
- **Task ID**: `TASK-2026-01-01-n3`
- **Execution State**: `in_progress`
EOF
    run_doctor "$root"
    want_status 1
    want_contains $'docs-drift\tDIVERGED(STATE 3A vs Task Record: Task ID)'

    # (b) Next Action mismatch -> DIVERGED
    cat > "$root/docs/STATE.md" <<EOF
# Project State
- **Engine Version**: v1.2.3 @ $sha

## 3A. Execution-Control Projection (Optional)
- **Task ID**: \`TASK-2026-01-01-n3\`
- **Task Record**: \`docs/tasks/TASK-2026-01-01-n3.md\`
- **Execution State**: \`in_progress\`
- **Next Action**: \`Finalize the fixture\`
EOF
    cat > "$root/docs/tasks/TASK-2026-01-01-n3.md" <<'EOF'
# Task Record: n3
- **Task ID**: `TASK-2026-01-01-n3`
- **Execution State**: `in_progress`
- **Next Action**: `Ship the different action`
EOF
    run_doctor "$root"
    want_status 1
    want_contains $'docs-drift\tDIVERGED(STATE 3A vs Task Record: Next Action)'

    # (c) no shared field concrete on both sides -> SKIP, never OK
    cat > "$root/docs/STATE.md" <<EOF
# Project State
- **Engine Version**: v1.2.3 @ $sha

## 3A. Execution-Control Projection (Optional)
- **Task ID**: \`TASK-<task-id>\`
- **Task Record**: \`docs/tasks/TASK-2026-01-01-n3-ph.md\`
- **Execution State**: \`[planned]\`
EOF
    cat > "$root/docs/tasks/TASK-2026-01-01-n3-ph.md" <<'EOF'
# Task Record: n3-ph
- **Task ID**: `TASK-<task-id>`
- **Execution State**: `[planned]`
- **Next Action**: `[action]`
EOF
    run_doctor "$root"
    want_status 0
    want_contains $'docs-drift\tSKIP(no comparable field)'
    want_not_contains $'docs-drift\tOK'
    want_not_contains 'DIVERGED'
}

# N4: a deleted universal AGENTS.md is MISSING (re-run the installer), exit 1.
n4() {
    local root
    root="$(make_healthy n4 balanced)"
    rm -f "$root/AGENTS.md"
    run_doctor "$root"
    want_status 1
    want_contains $'host:AGENTS.md\tMISSING'
    want_contains 'universal host file absent'
}

# N5: the engine lives OUTSIDE the project root (a project that does not contain
# the running kit). The kit-directory ignore row must degrade to
# SKIP(engine outside project root); the phantom basename must never report OK.
n5() {
    local root engine sha base
    root="$TMP/n5-project"
    engine="$TMP/n5-engine"
    base="$(basename -- "$engine")"
    mkdir -p "$root/docs/tasks" "$root/.opencode" "$root/.github"
    printf 'profile: balanced\n' > "$root/PROMPTKIT.md"
    mkdir -p "$engine/scripts" "$engine/templates" "$engine/workflows"
    cp "$SRC_CHECKER" "$engine/scripts/check-doctor.sh"
    cp "$REPO_ROOT/templates/agent-directive-template.md" "$engine/templates/"
    cp "$REPO_ROOT/templates/agent-directive-lite-template.md" "$engine/templates/"
    cp "$REPO_ROOT/workflows/route.md" "$engine/workflows/"
    git -C "$engine" init -q
    git -C "$engine" config user.name Fixture
    git -C "$engine" config user.email fixture@example.invalid
    printf '# engine\n' > "$engine/ENGINE.md"
    git -C "$engine" add -A
    git -C "$engine" commit -qm 'engine base'
    git -C "$engine" branch -M main 2>/dev/null || true
    git -C "$engine" update-ref refs/remotes/origin/main HEAD
    git -C "$root" init -q
    sha="$(git -C "$engine" rev-parse --short HEAD)"
    write_hosts "$root" "$sha"
    write_state "$root" "$sha"
    write_task "$root" "TASK-2026-01-01-fixture" "completed"
    STATUS=0
    OUT="$(bash "$engine/scripts/check-doctor.sh" "$root" 2>&1)" || STATUS=$?
    want_status 0
    want_contains "ignore:$base"$'\tSKIP(engine outside project root)\t-\t-'
    want_not_contains "ignore:$base"$'\tOK'
    want_not_contains "ignore:$base"$'\tINCOMPLETE'
}

# S11: a directory-form cline install (.clinerules/promptkit.md, the shape
# init.sh ensure_target writes) is OK, not INCOMPLETE host file unreadable.
s11() {
    local root sha
    root="$(make_healthy s11 balanced)"
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
    rm -f "$root/.clinerules"
    mkdir -p "$root/.clinerules"
    {
        printf '<!-- PROMPTKIT_START -->\n'
        printf '## PromptKit OS\n'
        printf 'Engine: v1.2.3 (%s) - stamped at install time\n' "$sha"
        printf '<!-- PROMPTKIT_END -->\n'
    } > "$root/.clinerules/promptkit.md"
    run_doctor "$root"
    want_status 0
    want_contains $'host:.clinerules/promptkit.md\tOK'
    want_not_contains 'host file unreadable'
}

# S12: a cursor mdc-only install (.cursor/rules/promptkit.mdc, no .cursorrules)
# is OK, not SKIP(not installed).
s12() {
    local root sha
    root="$(make_healthy s12 balanced)"
    sha="$(git -C "$root/.promptkit" rev-parse --short HEAD)"
    rm -f "$root/.cursorrules"
    mkdir -p "$root/.cursor/rules"
    {
        printf '<!-- PROMPTKIT_START -->\n'
        printf '## PromptKit OS\n'
        printf 'Engine: v1.2.3 (%s) - stamped at install time\n' "$sha"
        printf '<!-- PROMPTKIT_END -->\n'
    } > "$root/.cursor/rules/promptkit.mdc"
    run_doctor "$root"
    want_status 0
    want_contains $'host:.cursor/rules/promptkit.mdc\tOK'
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
begin; n1; report 'N1 nested engine STALE(+1) against its own origin/main + engine ignore'
begin; n2; report 'N2 --fix renders <engine_relpath>/workflows/... and path exists'
begin; n3; report 'N3 docs-drift compares shared fields, DIVERGED/SKIP, never bare OK'
begin; n4; report 'N4 deleted AGENTS.md -> MISSING, exit 1'
begin; n5; report 'N5 engine outside project root -> kit-dir ignore SKIP, no phantom OK'
begin; s11; report 'S11 cline directory-form install -> host OK'
begin; s12; report 'S12 cursor mdc-only install -> host OK'

printf 'Passed: %s | Failed: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
