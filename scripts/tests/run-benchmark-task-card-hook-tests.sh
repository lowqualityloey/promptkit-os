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

write_bad_card() {
    {
        printf '# Task Spec: fixture\n\n'
        printf -- '- **Task ID**: `BENCH-T-01`\n'
        printf -- '- **Verify**: `node --test && node --input-type=module -e "1"`\n'
    } > "$REPO/benchmarks/tasks/TASK-BENCH-T-01.md"
}

write_good_card() {
    {
        printf '# Task Spec: fixture\n\n'
        printf -- '- **Task ID**: `BENCH-T-02`\n'
        printf -- '- **Verify**: `node --input-type=module -e "1"; probe=$?; node --test; tests=$?; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`\n'
    } > "$REPO/benchmarks/tasks/TASK-BENCH-T-02.md"
}

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

printf 'RESULTS|passed=%s|failed=%s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
