#!/usr/bin/env bash
# Regression harness for scripts/install-benchmark-task-card-hook.sh.
# Run from repository root: bash scripts/tests/run-benchmark-task-card-hook-tests.sh
#
# Every case builds a throwaway git repository, installs the hook there, and
# commits through it. The gate under test is the repository's real
# check-benchmark-task-cards.sh, so a passing case proves the installed hook
# blocks a badly ordered card and lets a compliant one through.
#
# Cases are 1:1 with the PowerShell twin except the executable-bit assertions,
# which Windows has no mode bit to satisfy, and one Bash-only case pinning
# tilde-pattern expansion for a repository under $HOME (PowerShell has no
# equivalent case-pattern expansion to guard).

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
INSTALLER="$REPO_ROOT/scripts/install-benchmark-task-card-hook.sh"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0

pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

STATUS=0
OUT=""
REPO=""

install_hook() {
    STATUS=0
    OUT="$(bash "$INSTALLER" --root "$REPO" "$@" 2>&1)" || STATUS=$?
}

run_hook() {
    STATUS=0
    OUT="$(cd "$REPO" && sh .git/hooks/pre-commit 2>&1)" || STATUS=$?
}

commit() {
    STATUS=0
    OUT="$(git -C "$REPO" commit -qm "$1" 2>&1)" || STATUS=$?
}

make_repo() {
    REPO="$TMP/$1"
    mkdir -p "$REPO/benchmarks/tasks"
    git init -q "$REPO"
    git -C "$REPO" config user.name test
    git -C "$REPO" config user.email test@example.com
    git -C "$REPO" config commit.gpgsign false
    printf '# seed\n' > "$REPO/README.md"
    git -C "$REPO" add README.md
    git -C "$REPO" commit -qm seed
}

BAD_VERIFY='node --test && node --input-type=module -e "1"'
GOOD_VERIFY='node --input-type=module -e "1"; probe=$?; node --test; tests=$?; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]'

# write_card <file-name> <task-id> <verify-command>
write_card() {
    {
        printf '# Task Spec: fixture\n\n'
        printf -- '- **Task ID**: `%s`\n' "$2"
        printf -- '- **Verify**: `%s`\n' "$3"
    } > "$REPO/benchmarks/tasks/$1"
}

write_bad_card() { write_card TASK-BENCH-T-01.md BENCH-T-01 "$BAD_VERIFY"; }
write_good_card() { write_card TASK-BENCH-T-02.md BENCH-T-02 "$GOOD_VERIFY"; }

want_status() {
    if [ "$STATUS" -eq "$1" ]; then return 0; fi
    printf '  - expected exit %s, got %s\n  - output: %s\n' "$1" "$STATUS" "$OUT"
    return 1
}

want_nonzero() {
    if [ "$STATUS" -ne 0 ]; then return 0; fi
    printf '  - expected a non-zero exit, got 0\n  - output: %s\n' "$OUT"
    return 1
}

want_contains() {
    case "$OUT" in
        *"$1"*) return 0 ;;
    esac
    printf '  - output missing: %s\n  - output: %s\n' "$1" "$OUT"
    return 1
}

want_file() {
    if [ -f "$1" ]; then return 0; fi
    printf '  - expected file: %s\n' "$1"
    return 1
}

want_no_file() {
    if [ ! -f "$1" ]; then return 0; fi
    printf '  - expected no file: %s\n' "$1"
    return 1
}

want_same_bytes() {
    # one argument: "<file-a>|<file-b>"
    local a="${1%%|*}" b="${1#*|}"
    if cmp -s "$a" "$b"; then return 0; fi
    printf '  - files differ: %s vs %s\n' "$a" "$b"
    diff -u "$a" "$b" | head -20
    return 1
}

scenario() {
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

head_of() { git -C "$REPO" rev-parse HEAD; }

# --- 1. install creates an executable hook with the managed block ----------
make_repo install
install_hook
HEAD_BEFORE="$(head_of)"
scenario "install writes an executable pre-commit hook" \
    "want_status 0" "want_contains TASK_CARD_HOOK|INSTALLED" \
    "want_file $REPO/.git/hooks/pre-commit"
if [ -x "$REPO/.git/hooks/pre-commit" ] && grep -qF 'PROMPTKIT_TASK_CARD_GATE' "$REPO/.git/hooks/pre-commit"; then
    pass "hook is executable and carries the managed markers"
else
    fail "hook is executable and carries the managed markers"
fi

# --- 2. install is idempotent ---------------------------------------------
cp "$REPO/.git/hooks/pre-commit" "$TMP/hook-once"
install_hook
scenario "second install is byte-identical" \
    "want_status 0" "want_same_bytes $TMP/hook-once|$REPO/.git/hooks/pre-commit"

# --- 3. a badly ordered card cannot be committed --------------------------
make_repo blocks
install_hook
write_bad_card
git -C "$REPO" add benchmarks/tasks/TASK-BENCH-T-01.md
HEAD_BEFORE="$(head_of)"
commit "bad card"
scenario "badly ordered card is blocked before commit" \
    "want_nonzero x" "want_contains Commit blocked" \
    "want_contains runs before the behavioral probe"
if [ "$(head_of)" = "$HEAD_BEFORE" ]; then
    pass "blocked commit leaves HEAD untouched"
else
    fail "blocked commit leaves HEAD untouched"
fi

# --- 4. a compliant card commits ------------------------------------------
make_repo passes
install_hook
write_good_card
git -C "$REPO" add benchmarks/tasks/TASK-BENCH-T-02.md
HEAD_BEFORE="$(head_of)"
commit "good card"
scenario "compliant card commits through the hook" "want_status 0"
if [ "$(head_of)" != "$HEAD_BEFORE" ]; then
    pass "compliant commit advanced HEAD"
else
    fail "compliant commit advanced HEAD"
fi

# --- 5. unrelated commits are not gated -----------------------------------
make_repo scoped
install_hook
write_bad_card                          # a broken card exists in the tree ...
printf '# changed\n' >> "$REPO/README.md"
git -C "$REPO" add README.md             # ... but is not staged
commit "unrelated"
scenario "unrelated commit runs the hook as a no-op" "want_status 0"

# --- 6. an existing shell hook body is preserved and still runs -----------
make_repo chained
mkdir -p "$REPO/.git/hooks"
cat > "$REPO/.git/hooks/pre-commit" <<'HOOK'
#!/bin/sh
echo ran >> "$(git rev-parse --show-toplevel)/hooked.txt"
HOOK
chmod +x "$REPO/.git/hooks/pre-commit"
install_hook
write_good_card
git -C "$REPO" add benchmarks/tasks/TASK-BENCH-T-02.md
commit "good card"
scenario "existing hook body still runs after the gate" \
    "want_status 0" "want_file $REPO/hooked.txt"

# --- 7. remove restores the original body and mode ------------------------
make_repo restore
mkdir -p "$REPO/.git/hooks"
printf '#!/bin/sh\necho original\n' > "$REPO/.git/hooks/pre-commit"
chmod 755 "$REPO/.git/hooks/pre-commit"
cp "$REPO/.git/hooks/pre-commit" "$TMP/original-hook"
install_hook
install_hook --remove
scenario "remove restores the original hook byte-for-byte" \
    "want_status 0" "want_contains TASK_CARD_HOOK|REMOVED" \
    "want_same_bytes $TMP/original-hook|$REPO/.git/hooks/pre-commit"
if [ -x "$REPO/.git/hooks/pre-commit" ]; then
    pass "removed hook keeps its executable mode"
else
    fail "removed hook keeps its executable mode"
fi

# --- 8. remove deletes a hook it created entirely -------------------------
make_repo created
install_hook
install_hook --remove
scenario "remove deletes a hook it created" \
    "want_status 0" "want_contains TASK_CARD_HOOK|REMOVED" \
    "want_no_file $REPO/.git/hooks/pre-commit"

# --- 9. a non-shell hook is wrapped, not corrupted ------------------------
make_repo nonshell
mkdir -p "$REPO/.git/hooks"
printf '#!/usr/bin/env python3\nprint("original")\n' > "$REPO/.git/hooks/pre-commit"
chmod +x "$REPO/.git/hooks/pre-commit"
cp "$REPO/.git/hooks/pre-commit" "$TMP/original-python-hook"
install_hook
scenario "non-shell hook is preserved as promptkit-orig" \
    "want_status 0" "want_file $REPO/.git/hooks/pre-commit.promptkit-orig" \
    "want_same_bytes $TMP/original-python-hook|$REPO/.git/hooks/pre-commit.promptkit-orig"
install_hook --remove
scenario "remove restores a wrapped non-shell hook" \
    "want_status 0" "want_same_bytes $TMP/original-python-hook|$REPO/.git/hooks/pre-commit" \
    "want_no_file $REPO/.git/hooks/pre-commit.promptkit-orig"

# --- 10. a repository under $HOME keeps a single-prefix hook path ---------
# An unquoted `~/*` case pattern is tilde-expanded to "$HOME/*", which matches
# an absolute hook path under HOME and used to produce "$HOME/<abs path>".
FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME"
REPO="$FAKE_HOME/repo"
mkdir -p "$REPO/benchmarks/tasks"
git init -q "$REPO"
git -C "$REPO" config user.name test
git -C "$REPO" config user.email test@example.com
STATUS=0
OUT="$(HOME="$FAKE_HOME" bash "$INSTALLER" --root "$REPO" 2>&1)" || STATUS=$?
scenario "repository under HOME installs at the single expected path" \
    "want_status 0" "want_contains TASK_CARD_HOOK|INSTALLED|$REPO/.git/hooks/pre-commit" \
    "want_file $REPO/.git/hooks/pre-commit"

# --- 11. no repository --------------------------------------------------
REPO="$TMP/not-a-repo"
mkdir -p "$REPO"
install_hook
scenario "missing repository fails closed" \
    "want_status 2" "want_contains TASK_CARD_HOOK|INCOMPLETE|NO_REPO"

# --- 12. a card is judged as staged, not as it sits on disk ----------------
# The bypass this pins: stage a badly ordered card, then fix the working-tree
# copy without re-staging. The commit would carry the bad card, so the gate must
# block it even though benchmarks/tasks/ on disk looks compliant.
make_repo staged-not-worktree
install_hook
write_bad_card
git -C "$REPO" add benchmarks/tasks/TASK-BENCH-T-01.md
write_card TASK-BENCH-T-01.md BENCH-T-01 "$GOOD_VERIFY"
HEAD_BEFORE="$(head_of)"
commit "bad card staged, fixed only on disk"
scenario "a bad card staged and fixed only on disk is blocked" \
    "want_nonzero x" "want_contains Commit blocked" \
    "want_contains runs before the behavioral probe"
if [ "$(head_of)" = "$HEAD_BEFORE" ]; then
    pass "partial-staging block leaves HEAD untouched"
else
    fail "partial-staging block leaves HEAD untouched"
fi

# --- 13. a compliant staged card survives a broken working-tree copy ------
# The mirror: stage the compliant bytes, then break the file on disk. The commit
# carries the compliant card, so the gate must let it through and the committed
# blob must be the staged one.
make_repo worktree-not-staged
install_hook
write_good_card
git -C "$REPO" add benchmarks/tasks/TASK-BENCH-T-02.md
write_card TASK-BENCH-T-02.md BENCH-T-02 "$BAD_VERIFY"
commit "good card staged, broken only on disk"
scenario "a compliant staged card commits despite a broken working-tree copy" "want_status 0"
if git -C "$REPO" show "HEAD:benchmarks/tasks/TASK-BENCH-T-02.md" 2>/dev/null | grep -qF 'probe=$?'; then
    pass "the committed blob is the staged compliant card"
else
    fail "the committed blob is the staged compliant card"
fi

# --- 14. an unstaged card cannot block a staged one ----------------------
# A broken card left in the tree is not part of this commit; validating it would
# block unrelated work, which is what tree-wide scanning used to do.
make_repo staged-only
install_hook
write_bad_card                                        # broken card in the tree ...
write_good_card
git -C "$REPO" add benchmarks/tasks/TASK-BENCH-T-02.md   # ... another card staged
commit "staged good card beside an unstaged bad card"
scenario "an unstaged card elsewhere in the tree does not block" "want_status 0"

printf 'RESULTS|passed=%s|failed=%s\n' "$PASS" "$FAIL"
