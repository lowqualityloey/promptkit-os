#!/usr/bin/env bash
# Regression harness for the AI-attribution policy (issue #554).
# Covers the read-only detector (preference gating, prohibited trailers/footers,
# human co-authors, discussion, fail-closed rules/payload including invalid
# regexes and multi-megabyte payloads) and the opt-in commit-msg hook (install,
# reject, allow, coexistence, idempotency, removal, core.hooksPath, non-shell
# hook preservation, and executable-bit restoration).
# Run from repository root: bash scripts/tests/run-ai-attribution-tests.sh

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
DETECTOR="$REPO_ROOT/scripts/check-ai-attribution.sh"
HOOK_INSTALLER="$REPO_ROOT/scripts/install-attribution-hook.sh"

TMP="$(mktemp -d)"
export HOME="$TMP/home"
mkdir -p "$HOME"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0
SCENARIO_OK=1

pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
begin() { SCENARIO_OK=1; }
report() { if [[ "$SCENARIO_OK" -eq 1 ]]; then pass "$1"; else fail "$1"; fi; }
scenario_check() { if [[ "$1" -ne 1 ]]; then printf '  - %s\n' "$2"; SCENARIO_OK=0; fi; }

STATUS=0
OUT=""
run_det() {
    STATUS=0
    OUT="$(bash "$DETECTOR" "$@" 2>&1)" || STATUS=$?
}

make_repo() {
    local dir="$TMP/$1" pref="$2"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.name Fixture
    git -C "$dir" config user.email fixture@example.invalid
    if [[ -n "$pref" ]]; then printf 'profile: balanced\nai-attribution: %s\n' "$pref" > "$dir/PROMPTKIT.md"; else printf 'profile: balanced\n' > "$dir/PROMPTKIT.md"; fi
    printf 'x\n' > "$dir/f.txt"
    git -C "$dir" add -A
    git -C "$dir" commit -qm base
    printf '%s' "$dir"
}

commit_msg() {
    local dir="$1"; shift
    git -C "$dir" commit -qm "feat: change" -m "$1" >/dev/null 2>&1
}

# D1: host-default (and missing) never newly blocks.
d1() {
    local root
    root="$(make_repo d1 '')"
    printf 'feat: x\n\nCo-authored-by: Claude <n@x>\n' > "$TMP/d1.txt"
    run_det --root "$root" --message-file "$TMP/d1.txt"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "expected exit 0, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|SKIP|host-default"* ]] && printf 1 || printf 0)" "missing host-default SKIP"
    run_det --root "$root" --message-file "$TMP/d1.txt"
}

# D2: off + AI trailer is prohibited; diagnostics name the rule and remediation.
d2() {
    local root
    root="$(make_repo d2 off)"
    printf 'feat: x\n\nCo-authored-by: Claude <n@x>\n' > "$TMP/d2.txt"
    run_det --root "$root" --message-file "$TMP/d2.txt"
    scenario_check "$([[ "$STATUS" -eq 1 ]] && printf 1 || printf 0)" "expected exit 1, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE|trailer"* ]] && printf 1 || printf 0)" "missing rule diagnostic"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|REMEDIATION|"* ]] && printf 1 || printf 0)" "missing remediation"
}

# D3: off + AI promotional footer is prohibited.
d3() {
    local root
    root="$(make_repo d3 off)"
    printf '## Summary\n\nGenerated with Claude Code\n' > "$TMP/d3.md"
    run_det --root "$root" --body-file "$TMP/d3.md"
    scenario_check "$([[ "$STATUS" -eq 1 ]] && printf 1 || printf 0)" "expected exit 1, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|PROHIBITED|GENERATED_WITH_CLAUDE|footer"* ]] && printf 1 || printf 0)" "missing footer rule"
}

# D4: human co-authors, authorship, and ordinary discussion stay intact.
d4() {
    local root
    root="$(make_repo d4 off)"
    printf 'feat: x\n\nCo-authored-by: Jane Doe <jane@example.com>\n' > "$TMP/d4a.txt"
    run_det --root "$root" --message-file "$TMP/d4a.txt"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "human co-author was blocked (exit $STATUS)"
    printf 'This PR discusses how Co-authored-by: trailers and AI tools are used.\n' > "$TMP/d4b.md"
    run_det --root "$root" --body-file "$TMP/d4b.md"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "ordinary discussion was blocked (exit $STATUS)"
}

# D5: a malformed rules row and a missing payload both fail closed.
d5() {
    local root
    root="$(make_repo d5 off)"
    printf 'BADROW\n' > "$TMP/d5-bad.txt"
    printf 'feat: x\n' > "$TMP/d5.txt"
    run_det --root "$root" --rules-file "$TMP/d5-bad.txt" --message-file "$TMP/d5.txt"
    scenario_check "$([[ "$STATUS" -eq 2 ]] && printf 1 || printf 0)" "malformed rules expected exit 2, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|INCOMPLETE|RULES"* ]] && printf 1 || printf 0)" "missing RULES INCOMPLETE"
    run_det --root "$root" --message-file "$TMP/d5-missing.txt"
    scenario_check "$([[ "$STATUS" -eq 2 ]] && printf 1 || printf 0)" "missing payload expected exit 2, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|INCOMPLETE|PAYLOAD"* ]] && printf 1 || printf 0)" "missing PAYLOAD INCOMPLETE"
}

# H1: install adds the managed block and an AI trailer commit is rejected.
h1() {
    local root head_before
    root="$(make_repo h1 off)"
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    scenario_check "$([[ "$(grep -cF 'PROMPTKIT_AI_ATTRIBUTION >>>' "$root/.git/hooks/commit-msg")" -eq 1 ]] && printf 1 || printf 0)" "managed block not installed"
    head_before="$(git -C "$root" rev-parse HEAD)"
    printf 'y\n' > "$root/f.txt"
    git -C "$root" add f.txt
    commit_msg "$root" "Co-authored-by: Claude <n@x>"
    scenario_check "$([[ "$(git -C "$root" rev-parse HEAD)" == "$head_before" ]] && printf 1 || printf 0)" "AI trailer commit was not blocked"
}

# H2: a human co-author commit passes through the hook.
h2() {
    local root
    root="$(make_repo h2 off)"
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    printf 'y\n' > "$root/f.txt"
    git -C "$root" add f.txt
    commit_msg "$root" "Co-authored-by: Jane <jane@example.com>"
    scenario_check "$([[ "$(git -C "$root" log -1 --format=%s)" == "feat: change" ]] && printf 1 || printf 0)" "human co-author commit did not land"
}

# H3: a pre-existing hook body is preserved and still runs (chained).
h3() {
    local root
    root="$(make_repo h3 off)"
    mkdir -p "$root/.git/hooks"
    printf '#!/bin/sh\ntouch "$(git rev-parse --show-toplevel)/.existing-hook-ran"\nexit 0\n' > "$root/.git/hooks/commit-msg"
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    scenario_check "$([[ "$(grep -c 'existing-hook-ran' "$root/.git/hooks/commit-msg")" -eq 1 ]] && printf 1 || printf 0)" "pre-existing hook body was dropped"
    printf 'y\n' > "$root/f.txt"
    git -C "$root" add f.txt
    commit_msg "$root" "Co-authored-by: Jane <jane@example.com>"
    scenario_check "$([[ -f "$root/.existing-hook-ran" ]] && printf 1 || printf 0)" "pre-existing hook did not run"
}

# H4: re-install is idempotent and remove strips only the managed block.
h4() {
    local root
    root="$(make_repo h4 off)"
    mkdir -p "$root/.git/hooks"
    printf '#!/bin/sh\n# keep-me\nexit 0\n' > "$root/.git/hooks/commit-msg"
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    scenario_check "$([[ "$(grep -cF 'PROMPTKIT_AI_ATTRIBUTION >>>' "$root/.git/hooks/commit-msg")" -eq 1 ]] && printf 1 || printf 0)" "re-install did not stay single-block"
    bash "$HOOK_INSTALLER" --root "$root" --remove >/dev/null
    scenario_check "$([[ "$(grep -c 'keep-me' "$root/.git/hooks/commit-msg")" -eq 1 ]] && printf 1 || printf 0)" "remove dropped pre-existing content"
    scenario_check "$([[ "$(grep -cF 'PROMPTKIT_AI_ATTRIBUTION >>>' "$root/.git/hooks/commit-msg")" -eq 0 ]] && printf 1 || printf 0)" "remove left the managed block"
}

# D6: an invalid-regex rules row fails closed (exit 2, not OK/0), and a
# multi-megabyte payload whose first line is an AI trailer is still prohibited;
# the payload is scanned as a file, so early grep exits cannot SIGPIPE a writer.
d6() {
    local root
    root="$(make_repo d6 off)"
    printf 'BADREGEX|[|trailer\n' > "$TMP/d6-badrules.txt"
    printf 'feat: x\n' > "$TMP/d6-msg.txt"
    run_det --root "$root" --rules-file "$TMP/d6-badrules.txt" --message-file "$TMP/d6-msg.txt"
    scenario_check "$([[ "$STATUS" -eq 2 ]] && printf 1 || printf 0)" "invalid regex expected exit 2, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|INCOMPLETE|RULES"* ]] && printf 1 || printf 0)" "invalid regex did not fail closed as RULES"
    { printf 'Co-authored-by: Claude <n@x>\n'; head -c 3000000 /dev/zero | tr '\0' 'a'; printf '\n'; } > "$TMP/d6-big.txt"
    run_det --root "$root" --message-file "$TMP/d6-big.txt"
    scenario_check "$([[ "$STATUS" -eq 1 ]] && printf 1 || printf 0)" "multi-MB payload expected exit 1, got $STATUS"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE|trailer"* ]] && printf 1 || printf 0)" "multi-MB payload did not report the leading AI trailer"
}

# D7: a human "Claude Martin" co-author passes, while the bot "Claude <...>" and
# product "Claude Code <...>" trailers remain prohibited.
d7() {
    local root
    root="$(make_repo d7 off)"
    printf 'feat: x\n\nCo-authored-by: Claude Martin <martin@example.com>\n' > "$TMP/d7-human.txt"
    run_det --root "$root" --message-file "$TMP/d7-human.txt"
    scenario_check "$([[ "$STATUS" -eq 0 ]] && printf 1 || printf 0)" "human Claude Martin was blocked (exit $STATUS)"
    printf 'feat: x\n\nCo-authored-by: Claude <n@x>\n' > "$TMP/d7-bot.txt"
    run_det --root "$root" --message-file "$TMP/d7-bot.txt"
    scenario_check "$([[ "$STATUS" -eq 1 ]] && printf 1 || printf 0)" "bot Claude trailer was not prohibited (exit $STATUS)"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE|trailer"* ]] && printf 1 || printf 0)" "missing COAUTHORED_AI_CLAUDE rule"
    printf 'feat: x\n\nCo-authored-by: Claude Code <n@x>\n' > "$TMP/d7-code.txt"
    run_det --root "$root" --message-file "$TMP/d7-code.txt"
    scenario_check "$([[ "$STATUS" -eq 1 ]] && printf 1 || printf 0)" "Claude Code trailer was not prohibited (exit $STATUS)"
    scenario_check "$([[ "$OUT" == *"AI_ATTRIBUTION|PROHIBITED|COAUTHORED_AI_CLAUDE_CODE|trailer"* ]] && printf 1 || printf 0)" "missing COAUTHORED_AI_CLAUDE_CODE rule"
}

# H5: --remove restores the hook's executable bit; the original hook still fires
# and Git no longer reports it as an ignored (non-executable) hook.
h5() {
    local root mode_before mode_after err
    root="$(make_repo h5 off)"
    printf '#!/bin/sh\ntouch "$(git rev-parse --show-toplevel)/.restored-ran"\nexit 0\n' > "$root/.git/hooks/commit-msg"
    chmod 755 "$root/.git/hooks/commit-msg"
    mode_before="$(stat -c '%a' "$root/.git/hooks/commit-msg")"
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    bash "$HOOK_INSTALLER" --root "$root" --remove >/dev/null
    mode_after="$(stat -c '%a' "$root/.git/hooks/commit-msg")"
    scenario_check "$([[ "$mode_before" == "755" && "$mode_after" == "755" ]] && printf 1 || printf 0)" "exec bit not preserved 755: before=$mode_before after=$mode_after"
    printf 'y\n' > "$root/f.txt"
    git -C "$root" add f.txt
    err="$( { git -C "$root" commit -m 'feat: restored hook' >/dev/null; } 2>&1 )"
    scenario_check "$([[ -f "$root/.restored-ran" ]] && printf 1 || printf 0)" "restored hook did not run"
    scenario_check "$([[ "$err" != *"was ignored"* ]] && printf 1 || printf 0)" "git reported the restored hook as ignored: $err"
}

# H6: install honors core.hooksPath (hook lands at the effective git-path and
# blocks an AI-trailer commit there instead of the default .git/hooks).
h6() {
    local root head_before
    root="$(make_repo h6 off)"
    git -C "$root" config core.hooksPath .githooks
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    scenario_check "$([[ -f "$(git -C "$root" rev-parse --path-format=absolute --git-path hooks)/commit-msg" ]] && printf 1 || printf 0)" "hook not installed at the effective git-path"
    scenario_check "$([[ -f "$root/.githooks/commit-msg" ]] && printf 1 || printf 0)" "hook not placed under core.hooksPath"
    scenario_check "$([[ ! -f "$root/.git/hooks/commit-msg" ]] && printf 1 || printf 0)" "hook leaked into the default .git/hooks"
    head_before="$(git -C "$root" rev-parse HEAD)"
    printf 'y\n' > "$root/f.txt"
    git -C "$root" add f.txt
    commit_msg "$root" "Co-authored-by: Claude <n@x>"
    scenario_check "$([[ "$(git -C "$root" rev-parse HEAD)" == "$head_before" ]] && printf 1 || printf 0)" "AI trailer commit was not blocked at core.hooksPath"
}

# H7: a pre-existing non-shell python hook survives install. The original is
# preserved verbatim, a sh wrapper chains to it so ordinary commits still run
# it, and the AI check still blocks an AI-trailer commit. A tiny python3 shim on
# PATH keeps the fixture hermetic and free of any real interpreter dependency.
h7() {
    local root shim marker head_before old_path
    root="$(make_repo h7 off)"
    shim="$TMP/py-shim"
    marker="$TMP/h7-py-ran"
    mkdir -p "$shim"
    printf '#!/bin/sh\n[ -n "$PK_PY_MARKER" ] && : > "$PK_PY_MARKER"\nexit 0\n' > "$shim/python3"
    chmod 755 "$shim/python3"
    old_path="$PATH"
    PATH="$shim:$PATH"
    export PK_PY_MARKER="$marker"
    printf '#!/usr/bin/env python3\n# pre-existing python hook\n' > "$root/.git/hooks/commit-msg"
    chmod 755 "$root/.git/hooks/commit-msg"
    bash "$HOOK_INSTALLER" --root "$root" >/dev/null
    scenario_check "$([[ -f "$root/.git/hooks/commit-msg.promptkit-orig" ]] && printf 1 || printf 0)" "python original was not preserved as .promptkit-orig"
    scenario_check "$([[ "$(grep -c '#!/usr/bin/env python3' "$root/.git/hooks/commit-msg.promptkit-orig")" -eq 1 ]] && printf 1 || printf 0)" "python original lost its shebang"
    scenario_check "$([[ "$(head -n 1 "$root/.git/hooks/commit-msg")" == "#!/bin/sh" ]] && printf 1 || printf 0)" "non-shell hook was not wrapped in sh"
    printf 'y\n' > "$root/f.txt"
    git -C "$root" add f.txt
    commit_msg "$root" "Co-authored-by: Jane <jane@example.com>"
    scenario_check "$([[ -f "$marker" ]] && printf 1 || printf 0)" "preserved python hook did not run on an ordinary commit"
    head_before="$(git -C "$root" rev-parse HEAD)"
    printf 'z\n' > "$root/f.txt"
    git -C "$root" add f.txt
    commit_msg "$root" "Co-authored-by: Claude <n@x>"
    scenario_check "$([[ "$(git -C "$root" rev-parse HEAD)" == "$head_before" ]] && printf 1 || printf 0)" "AI trailer was not blocked through the wrapper"
    PATH="$old_path"
    unset PK_PY_MARKER
}

begin; d1; report 'D1 host-default/missing preference never newly blocks'
begin; d2; report 'D2 off: AI co-author trailer prohibited with diagnostics'
begin; d3; report 'D3 off: AI promotional footer prohibited'
begin; d4; report 'D4 human co-authors and ordinary discussion preserved'
begin; d5; report 'D5 malformed rules and missing payload fail closed'
begin; h1; report 'H1 install blocks an AI-trailer commit'
begin; h2; report 'H2 human co-author commit passes the hook'
begin; h3; report 'H3 pre-existing hook preserved and chained'
begin; h4; report 'H4 idempotent install; remove strips only the block'
begin; d6; report 'D6 invalid regex fails closed; multi-MB payload prohibited'
begin; d7; report 'D7 human Claude Martin passes; bot Claude trailers prohibited'
begin; h5; report 'H5 remove preserves exec bit; restored hook runs without warning'
begin; h6; report 'H6 install honors core.hooksPath'
begin; h7; report 'H7 non-shell python hook preserved, chained, and enforced'

printf 'Passed: %s | Failed: %s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
