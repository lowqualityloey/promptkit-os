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

# The engine stamp is resolved from git, so it differs per machine and per commit. It is
# canonicalized on BOTH sides, which keeps the comparison independent of the installer's
# git state. That is safe only because test 11 separately asserts the installed block
# contains no leftover $ENGINE_VERSION/$ENGINE_SHA tokens.
normalize_engine_stamp() {
    sed -e "s|^Engine: .* (.*) — stamped at install time|Engine: \$ENGINE_VERSION (\$ENGINE_SHA) — stamped at install time|"
}

# $KIT_DIR_REL is normalized on the TEMPLATE SIDE ONLY, and that asymmetry is deliberate.
# Applying it to both sides would rewrite a literal $KIT_DIR_REL in the installed block into
# .promptkit and make a broken substitution compare clean — masking the exact defect the
# comparison exists to catch. Nothing else in the suite asserts $KIT_DIR_REL does not leak,
# so test 15 pins that rejection directly.
normalize_template() {
    sed -e "s|\\\$KIT_DIR_REL|.promptkit|g" \
        -e "s|^Engine: .* (.*) — stamped at install time|Engine: \$ENGINE_VERSION (\$ENGINE_SHA) — stamped at install time|"
}

managed_block_matches_template() {
    local target="$1" template="$2"
    diff -u <(normalize_template <"$template") \
            <(awk '/^<!-- PROMPTKIT_START -->$/{copy=1} copy{print} /^<!-- PROMPTKIT_END -->$/{copy=0}' "$target" | normalize_engine_stamp)
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

# 11. Engine identity stamp: init.sh substitutes $ENGINE_VERSION / $ENGINE_SHA, so
# the literal tokens must not survive into the rendered directive. The sha must be a
# real short hash (or the no-git `unknown` fallback) rather than arbitrary text, since
# the stamp exists to make engine drift detectable.
D="$TEST_ROOT/t11"; mkdir -p "$D"
bash "$REPO_ROOT/init.sh" --balanced "$D" </dev/null >/dev/null 2>&1
if grep -Eq '^Engine: [^$]+ \((unknown|[0-9a-f]{7,})\) — stamped at install time' "$D/AGENTS.md" \
   && ! grep -Eq "\\\$ENGINE_VERSION|\\\$ENGINE_SHA" "$D/AGENTS.md"; then
    ok "engine identity stamp is substituted into the rendered directive"
else
    notok "engine identity stamp unresolved (tokens leaked or stamp line missing)"
fi

# 12. Adversarial git tag: a legal ref name may contain the sed delimiter '|' and sed's
# whole-match '&'. Both used to abort the install or splice text into the rendered
# directive, so the install must still succeed with the hostile version degraded.
FIXTURE="$TEST_ROOT/t12/kit"; mkdir -p "$FIXTURE/scripts"
cp -R "$REPO_ROOT/templates" "$FIXTURE/"
cp "$REPO_ROOT/scripts/terminal-picker.sh" "$FIXTURE/scripts/" 2>/dev/null || true
cp "$REPO_ROOT/init.sh" "$FIXTURE/"
# The install-door assert (#549) needs its checker in the kit; this synthetic partial
# kit ships it and opts out, since its subject is adversarial-tag stamp robustness.
cp "$REPO_ROOT/scripts/check-setup-assert.sh" "$FIXTURE/scripts/"
git -C "$FIXTURE" init -q .
git -C "$FIXTURE" add -A
git -C "$FIXTURE" -c user.email=fixture@example.invalid -c user.name=fixture commit -qm "fixture"
git -C "$FIXTURE" tag 'v1.0.0-x|y&z'
D="$TEST_ROOT/t12/proj"; mkdir -p "$D"
PROMPTKIT_NO_PREFLIGHT=1 bash "$FIXTURE/init.sh" --balanced --engine-version=v9.8.7 --tracking=local --host=agents "$D" </dev/null >/dev/null 2>&1
if [[ -f "$D/AGENTS.md" ]] \
   && grep -Eq '^Engine: [A-Za-z0-9._+-]+ \([0-9a-f]{7,}\) — stamped at install time' "$D/AGENTS.md" \
   && ! grep -q '^Engine: v9.8.7 ' "$D/AGENTS.md" \
   && ! grep -Eq "\\\$ENGINE_VERSION|\\\$ENGINE_SHA" "$D/AGENTS.md" \
   && ! grep -Eq '^- \*\*Engine Version\*\*:.*[|&]' "$D/docs/STATE.md"; then
    ok "adversarial git tag cannot abort or corrupt the install"
else
    notok "adversarial git tag handling ($(grep -h '^Engine: ' "$D/AGENTS.md" 2>/dev/null))"
fi

# 13. docs/STATE.md is mutated in place by the stamp pass, so it must be part of the
# rollback transaction. Sabotage a later scaffold step and assert both files are restored.
D="$TEST_ROOT/t13"; mkdir -p "$D/docs"
printf -- '- **Engine Version**: vOLD @ deadbee\n' > "$D/docs/STATE.md"
printf 'profile: lite\n' > "$D/PROMPTKIT.md"
touch "$D/.github"
bash "$REPO_ROOT/init.sh" --balanced --tracking=local --host=agents "$D" </dev/null >/dev/null 2>&1
if grep -q 'vOLD @ deadbee' "$D/docs/STATE.md" 2>/dev/null \
   && head -1 "$D/PROMPTKIT.md" 2>/dev/null | grep -q 'profile: lite'; then
    ok "rollback restores a pre-existing docs/STATE.md after a later failure"
else
    notok "rollback left docs/STATE.md mutated ($(grep -h 'Engine Version' "$D/docs/STATE.md" 2>/dev/null))"
fi

# 14. A STATE.md that predates the engine stamp has no row to replace, so one must be
# inserted without disturbing the surrounding user content.
D="$TEST_ROOT/t14"; mkdir -p "$D/docs"
printf '# Project State\n\n## 1. Executive Summary & Current Position\n- **Project Name**: Legacy\n- **Last Updated**: 2026-01-01\n\n---\n\n## 2. Milestone\n' > "$D/docs/STATE.md"
bash "$REPO_ROOT/init.sh" --balanced --tracking=local --host=agents "$D" </dev/null >/dev/null 2>&1
if [[ "$(grep -c '^- \*\*Engine Version\*\*:' "$D/docs/STATE.md" 2>/dev/null)" -eq 1 ]] \
   && grep -q '\*\*Project Name\*\*: Legacy' "$D/docs/STATE.md" \
   && grep -q 'Last Updated\*\*: 2026-01-01' "$D/docs/STATE.md" \
   && grep -q '^## 2. Milestone' "$D/docs/STATE.md"; then
    ok "legacy STATE.md gains the engine stamp row without losing user content"
else
    notok "legacy STATE.md stamp insertion (rows=$(grep -c 'Engine Version' "$D/docs/STATE.md" 2>/dev/null))"
fi

# 15. Normalization asymmetry guard: $KIT_DIR_REL is substituted on the template side
# only. Normalizing it on the installed side too would rewrite a leaked placeholder into
# .promptkit and make a broken installer compare clean, so this pins that rejection.
D="$TEST_ROOT/t15"; mkdir -p "$D"
sed -e "s|\\\$KIT_DIR_REL|\$KIT_DIR_REL|g" "$REPO_ROOT/templates/agent-directive-template.md" > "$D/AGENTS.md"
if managed_block_matches_template "$D/AGENTS.md" "$REPO_ROOT/templates/agent-directive-template.md" >/dev/null 2>&1; then
    notok "harness accepts a leaked \$KIT_DIR_REL placeholder (normalizer masking regression)"
else
    ok "harness rejects a leaked \$KIT_DIR_REL placeholder"
fi

# 16. Courier release version is retained for a tarball install, with no fabricated SHA.
KIT="$TEST_ROOT/t16/kit"; D="$TEST_ROOT/t16/project"; mkdir -p "$KIT" "$D"
tar -C "$REPO_ROOT" --exclude=.git --exclude=.codegraph -cf - . | tar -C "$KIT" -xf -
bash "$KIT/init.sh" --balanced --engine-version=v9.8.7 --tracking=local --host=agents "$D" </dev/null >/dev/null 2>&1
if grep -q '^Engine: v9.8.7 (unknown) — stamped at install time' "$D/AGENTS.md" \
   && grep -q '^- \*\*Engine Version\*\*: v9.8.7 @ unknown$' "$D/docs/STATE.md"; then
    ok "courier release version is stamped while SHA remains unknown"
else
    notok "courier identity stamp (agent=$(grep -h '^Engine: ' "$D/AGENTS.md" 2>/dev/null), state=$(grep -h 'Engine Version' "$D/docs/STATE.md" 2>/dev/null))"
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
