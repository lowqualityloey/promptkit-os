#!/usr/bin/env bash
# Regression tests for the strict token budget gates (issue #141).
# Covers: strict dual-profile CI gate (bash), per-task baseline gate, profile-aware
# budget resolution for the Lite template, and negative-path regression detection.
# Run from repository root: bash scripts/tests/run-token-budget-tests.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASS=0
FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
notok(){ echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

make_directive_file() {
    # $1 = target path, $2 = filler byte count
    local file="$1" size="$2"
    mkdir -p "$(dirname "$file")"
    {
        echo "<!-- PROMPTKIT_START -->"
        head -c "$size" /dev/zero | tr '\0' 'A'
        echo ""
        echo "<!-- PROMPTKIT_END -->"
    } > "$file"
}

echo "🧪 Token Budget Gate Regression Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Strict gate passes on the canonical templates (machine-parseable PASS lines).
out=$(bash "$REPO_ROOT/scripts/measure-tokens.sh" --strict 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" == *"BALANCED|"*"|PASS"* && "$out" == *"LITE|"*"|PASS"* ]]; then
    ok "measure-tokens.sh --strict passes canonical templates with PASS lines"
else
    notok "measure-tokens.sh --strict should exit 0 with BALANCED+LITE PASS (rc=$rc)"
    echo "$out"
fi

# 2. Per-task strict gate passes against recorded baselines.
out=$(bash "$REPO_ROOT/scripts/measure-per-task-tokens.sh" --strict 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" == *"Per-task baseline gate passed"* && "$out" == *"BASELINE|pk:fix/balanced|"*"|PASS"* ]]; then
    ok "measure-per-task-tokens.sh --strict passes all baseline comparisons"
else
    notok "measure-per-task-tokens.sh --strict should exit 0 (rc=$rc)"
    echo "$out" | tail -12
fi

# 3. Negative balanced regression: bloated directive must fail default mode (budget 2500).
make_directive_file "$TMP_DIR/bloated-AGENTS.md" 12000
if bash "$REPO_ROOT/scripts/measure-tokens.sh" "$TMP_DIR/bloated-AGENTS.md" >/dev/null 2>&1; then
    notok "bloated directive (12,000 chars) must exceed 2,500-token budget and exit 1"
else
    ok "bloated directive correctly fails the Balanced budget (exit 1)"
fi

# 4. Profile-aware Lite budget: a file named agent-directive-lite-template.md over the
#    Lite budget (1,500 tok = 6,000 chars) must fail even though it is under 2,500.
make_directive_file "$TMP_DIR/agent-directive-lite-template.md" 6100
if bash "$REPO_ROOT/scripts/measure-tokens.sh" "$TMP_DIR/agent-directive-lite-template.md" >/dev/null 2>&1; then
    notok "bloated Lite template (1,525 tok > 1,500 budget) must exit 1"
else
    ok "Lite template path correctly resolves to the 1,500-token budget (exit 1)"
fi

# 5. Positive Lite check: small Lite-named directive passes with Lite profile resolution.
make_directive_file "$TMP_DIR/lite-ok/templates/agent-directive-lite-template.md" 400
out=$(bash "$REPO_ROOT/scripts/measure-tokens.sh" "$TMP_DIR/lite-ok/templates/agent-directive-lite-template.md" 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" == *"Profile:                Lite"* ]]; then
    ok "small Lite template passes and reports Lite profile budget"
else
    notok "small Lite template should exit 0 reporting Lite budget (rc=$rc)"
fi

# 6. Backward compatibility: bare invocation from the repo root still measures the
#    canonical Balanced template fallback and exits 0.
out=$(cd "$REPO_ROOT" && bash scripts/measure-tokens.sh 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" == *"Verification Passed"* ]]; then
    ok "bare invocation stays backward compatible (Balanced fallback, exit 0)"
else
    notok "bare invocation should still pass (rc=$rc)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $PASS | Failed: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    echo "❌ Token budget regression tests FAILED"
    exit 1
fi
echo "✅ Token budget regression tests passed"
exit 0
