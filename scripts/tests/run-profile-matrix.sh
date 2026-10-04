#!/usr/bin/env bash
# E2E profile matrix tests for init.sh (issue #143).
# Covers: flag matrix for all 3 profiles, the --turbo/--experimental guard,
# non-interactive fallbacks (piped stdin, PROMPTKIT_NO_INTERACTIVE env), and
# lite -> balanced upgrade idempotency.
#
# TTY note (#144): PTY simulation is explicitly out of scope for this harness.
# All tests exercise the NON-TTY contract that CI relies on. The real-TTY +
# PROMPTKIT_NO_INTERACTIVE=1 case (picker must not appear) is a manual check.
# Run from repository root: bash scripts/tests/run-profile-matrix.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

PASS=0
FAIL=0
ok()    { echo "  PASS: $1"; PASS=$((PASS + 1)); }
notok() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

profile_of() {
    grep -E '^profile:' "$1/PROMPTKIT.md" 2>/dev/null | tail -1 | awk '{print $2}'
}

managed_block_matches_template() {
    local target="$1" template="$2"
    diff -u <(sed 's|\$KIT_DIR_REL|.promptkit|g' "$template") <(awk '/^<!-- PROMPTKIT_START -->$/{copy=1} copy{print} /^<!-- PROMPTKIT_END -->$/{copy=0}' "$target")
}

echo "🧪 init.sh Profile Matrix Tests (non-interactive contract)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. No flag (non-TTY stdin): defaults to balanced, exits 0.
D="$TEST_ROOT/t1"; mkdir -p "$D"
out=$(bash "$REPO_ROOT/init.sh" "$D" </dev/null 2>&1); rc=$?
if [[ $rc -eq 0 && "$(profile_of "$D")" == "balanced" ]]; then
    ok "no flag defaults to balanced (exit 0)"
else
    notok "no flag should default balanced (rc=$rc, profile=$(profile_of "$D"))"
fi

# 2. --lite: profile lite + Lite directive injected.
D="$TEST_ROOT/t2"; mkdir -p "$D"
if bash "$REPO_ROOT/init.sh" --lite "$D" </dev/null >/dev/null 2>&1 \
   && [[ "$(profile_of "$D")" == "lite" ]] \
   && grep -q 'PromptKit OS Lite' "$D/AGENTS.md" \
   && managed_block_matches_template "$D/AGENTS.md" "$REPO_ROOT/templates/agent-directive-lite-template.md"; then
    ok "--lite sets profile lite and renders the selected directive template"
else
    notok "--lite install (profile=$(profile_of "$D"))"
fi

# 3. --balanced: profile balanced + full directive header.
D="$TEST_ROOT/t3"; mkdir -p "$D"
if bash "$REPO_ROOT/init.sh" --balanced "$D" </dev/null >/dev/null 2>&1 \
   && [[ "$(profile_of "$D")" == "balanced" ]] \
   && grep -q '^## PromptKit OS: Engineering Operating System$' "$D/AGENTS.md" \
   && managed_block_matches_template "$D/AGENTS.md" "$REPO_ROOT/templates/agent-directive-template.md"; then
    ok "--balanced sets profile balanced and renders the selected directive template"
else
    notok "--balanced install (profile=$(profile_of "$D"))"
fi

# 4. --turbo without --experimental: must fail with guard message, write nothing.
D="$TEST_ROOT/t4"; mkdir -p "$D"
out=$(bash "$REPO_ROOT/init.sh" --turbo "$D" </dev/null 2>&1); rc=$?
if [[ $rc -ne 0 && "$out" == *"requires --experimental"* ]]; then
    ok "--turbo alone is rejected with --experimental guard"
else
    notok "--turbo alone should exit non-zero with guard (rc=$rc)"
fi

# 5. --turbo --experimental: profile turbo accepted.
D="$TEST_ROOT/t5"; mkdir -p "$D"
if bash "$REPO_ROOT/init.sh" --turbo --experimental "$D" </dev/null >/dev/null 2>&1 \
   && [[ "$(profile_of "$D")" == "turbo" ]]; then
    ok "--turbo --experimental sets profile turbo"
else
    notok "--turbo --experimental install (profile=$(profile_of "$D"))"
fi

# 6. Piped stdin must not hang: complete within 5s, default balanced (choice input ignored).
D="$TEST_ROOT/t6"; mkdir -p "$D"
if timeout 5 bash -c "echo 1 | bash '$REPO_ROOT/init.sh' '$D'" >/dev/null 2>&1 \
   && [[ "$(profile_of "$D")" == "balanced" ]]; then
    ok "piped stdin does not hang and defaults to balanced"
else
    notok "piped stdin test (hang or wrong profile)"
fi

# 7. PROMPTKIT_NO_INTERACTIVE=1: accepted, no picker text, defaults balanced.
D="$TEST_ROOT/t7"; mkdir -p "$D"
out=$(PROMPTKIT_NO_INTERACTIVE=1 bash "$REPO_ROOT/init.sh" "$D" </dev/null 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" != *"Profile Selection"* && "$(profile_of "$D")" == "balanced" ]]; then
    ok "PROMPTKIT_NO_INTERACTIVE=1 yields non-interactive default"
else
    notok "env-var escape test (rc=$rc, profile=$(profile_of "$D"))"
fi

# 8. Upgrade path lite -> balanced re-run: profile flips, single directive marker.
D="$TEST_ROOT/t8"; mkdir -p "$D"
bash "$REPO_ROOT/init.sh" --lite "$D" </dev/null >/dev/null 2>&1
bash "$REPO_ROOT/init.sh" --balanced "$D" </dev/null >/dev/null 2>&1
if [[ "$(profile_of "$D")" == "balanced" \
   && "$(grep -c '^<!-- PROMPTKIT_START -->$' "$D/AGENTS.md")" -eq 1 ]] \
   && grep -q '^## PromptKit OS: Engineering Operating System$' "$D/AGENTS.md" \
   && grep -q '^- \*\*Profile\*\*: balanced$' "$D/PROMPTKIT.md"; then
    ok "lite -> balanced upgrade is idempotent (profile + Section 0 body flip, one directive block)"
else
    notok "upgrade re-run (profile=$(profile_of "$D"), markers=$(grep -c '^<!-- PROMPTKIT_START -->$' "$D/AGENTS.md" 2>/dev/null), section0=$(grep -c '^- \*\*Profile\*\*: balanced$' "$D/PROMPTKIT.md" 2>/dev/null))"
fi

# 9. Aider parity: existing CONVENTIONS.md receives an idempotent directive block.
D="$TEST_ROOT/t9"; mkdir -p "$D"
printf '# My aider notes\n' > "$D/CONVENTIONS.md"
bash "$REPO_ROOT/init.sh" --balanced "$D" </dev/null >/dev/null 2>&1
if [[ "$(grep -c '^<!-- PROMPTKIT_START -->$' "$D/CONVENTIONS.md" 2>/dev/null)" -eq 1 ]] \
   && grep -q '^# My aider notes$' "$D/CONVENTIONS.md"; then
    ok "existing CONVENTIONS.md injected idempotently with user content preserved"
else
    notok "CONVENTIONS.md injection (markers=$(grep -c '^<!-- PROMPTKIT_START -->$' "$D/CONVENTIONS.md" 2>/dev/null))"
fi

D="$TEST_ROOT/t10"; mkdir -p "$D"
if PROMPTKIT_NO_PREFLIGHT=1 bash "$REPO_ROOT/init.sh" --balanced --tracking=local --host=agents "$D" </dev/null >/dev/null 2>&1; then
    out=$(PROMPTKIT_NO_PREFLIGHT=1 bash "$REPO_ROOT/init.sh" "$D" </dev/null 2>&1); rc=$?
    if [[ $rc -eq 0 && "$out" == *"Keeping installed hosts: agents"* ]] \
       && [[ -f "$D/AGENTS.md" ]] \
       && [[ ! -e "$D/CLAUDE.md" && ! -e "$D/.opencode/rules.md" && ! -e "$D/.cursorrules" \
          && ! -e "$D/GEMINI.md" && ! -e "$D/.windsurfrules" \
          && ! -e "$D/.github/copilot-instructions.md" && ! -e "$D/.clinerules" \
          && ! -e "$D/.traerules" && ! -e "$D/CONVENTIONS.md" ]]; then
        ok "AGENTS.md-only install preserves universal hosts on rerun"
    else
        notok "AGENTS.md-only rerun did not preserve universal host choice (rc=$rc)"
    fi
else
    notok "AGENTS.md-only initial install"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $PASS | Failed: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    echo "❌ init profile matrix FAILED"
    exit 1
fi
echo "✅ init profile matrix passed"
exit 0
