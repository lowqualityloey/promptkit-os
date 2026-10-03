#!/usr/bin/env bash
# Reference-link regression harness (Bash): proves validate-references.sh
# resolves reader-facing markdown links, honors historical exemptions, skips
# placeholders and inline code examples, and fails closed on a broken link.
# Run from repository root: bash scripts/tests/run-reference-link-tests.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-references.sh"

PASS_COUNT=0
FAIL_COUNT=0
FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

echo ""
echo "🔗 Running validate-references Link-Resolution Tests (Bash)"
echo "==========================================================="

# Seed the fixture root with the real content directories so the validator's
# completeness checks pass and only link resolution is under test.
for dir in workflows protocols templates activities; do
    cp -R "$REPO_ROOT/$dir" "$FIXTURE_ROOT/$dir"
done
# Minimal stubs for the cross-tree targets the copied workflow files link to, so
# the fixture stays small (fast) and only link resolution is under test.
mkdir -p "$FIXTURE_ROOT/docs/adrs" "$FIXTURE_ROOT/docs/internal" "$FIXTURE_ROOT/docs/recipes" "$FIXTURE_ROOT/docs/stacks" \
         "$FIXTURE_ROOT/docs/archive" "$FIXTURE_ROOT/notes"
for stub in \
    docs/BENCHMARKS.md docs/TURBO-WAVES-GUIDE.md docs/WORKFLOW-MAP.md \
    docs/adrs/0002-workflow-lifecycle-policy.md docs/internal/release-evaluation.md \
    docs/recipes/auto-phrase-boundary-sheet.md docs/recipes/auto-wave-pause-resume.md \
    docs/recipes/auto-waves-preflight-checklist.md docs/recipes/websocket-realtime.md docs/recipes/state-management.md \
    docs/stacks/mobile-kmp.md docs/stacks/systems-java-spring.md docs/stacks/systems-csharp-dotnet.md \
    docs/stacks/database-postgres.md docs/stacks/database-mysql.md docs/stacks/deploy-aws.md docs/stacks/deploy-gcp.md \
    notes/learning-plan.md notes/progress-journal.md notes/skill-matrix.md; do
    printf '# Fixture stub\n' > "$FIXTURE_ROOT/$stub"
done

pass() {
    echo "  ✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "  ❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# run_case <description> <expectation: fail|pass> <search-token>
run_case() {
    local description="$1"
    local expectation="$2"
    local token="$3"
    local output status

    output="$(bash "$VALIDATOR" "$FIXTURE_ROOT" 2>&1)"
    status=$?

    if [ "$expectation" = "fail" ]; then
        if [ "$status" -ne 0 ] && printf '%s' "$output" | grep -q "$token"; then
            pass "$description"
        else
            fail "$description (exit=$status, token '$token' not reported)"
        fi
    else
        if [ "$status" -eq 0 ]; then
            pass "$description"
        else
            fail "$description (exit=$status)"
            printf '%s\n' "$output" | grep -E "BROKEN|MISSING" | head -n 5
        fi
    fi
}

# Case 1: root-relative link in docs/ (the pre-fix MAXIMS class) must fail.
cat > "$FIXTURE_ROOT/docs/link-fixture.md" <<'MD'
# Link Fixture

- Root-relative link: [route](workflows/route.md)
MD
run_case "Root-relative docs link fails closed" "fail" "BROKEN LINK"

# Case 2: same link written relative to the source file must pass.
cat > "$FIXTURE_ROOT/docs/link-fixture.md" <<'MD'
# Link Fixture

- Resolved link: [route](../workflows/route.md)
MD
run_case "Relative ../ link resolves" "pass" ""

# Case 3: broken link inside an inline code span is illustrative, not a target.
cat > "$FIXTURE_ROOT/docs/link-fixture.md" <<'MD'
# Link Fixture

For example, `[CHECK-123](../tests/checks.md#CHECK-123)` is stronger than a bare claim.
MD
run_case "Inline code example is ignored" "pass" ""

# Case 4: placeholder target is skipped.
cat > "$FIXTURE_ROOT/docs/link-fixture.md" <<'MD'
# Link Fixture

- Report path: [review](../reviews/<review-slug>.md)
MD
run_case "Placeholder link target is skipped" "pass" ""

# Case 5: historical records are exempt (same policy as the count drift guard).
cat > "$FIXTURE_ROOT/docs/archive/historic-fixture.md" <<'MD'
# Historic Fixture

- Legacy link: [gone](../tasks/TASK-1999-01-01-removed.md)
MD
rm -f "$FIXTURE_ROOT/docs/link-fixture.md"
run_case "Historical record exempt from link resolution" "pass" ""

# Case 6: removing the broken historic file restores a clean tree.
rm -f "$FIXTURE_ROOT/docs/archive/historic-fixture.md"
cat > "$FIXTURE_ROOT/docs/link-fixture.md" <<'MD'
# Link Fixture

- Absolute target: [site](https://example.com/docs/page.md)
- Anchor-only target: [top](#link-fixture)
MD
run_case "External and anchor-only targets are skipped" "pass" ""

echo ""
echo "==========================================================="
echo "Reference-Link Harness Summary"
echo "Passed: $PASS_COUNT | Failed: $FAIL_COUNT"
echo "==========================================================="

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "❌ Reference-link harness failed."
    exit 1
fi

echo "✅ All reference-link tests passed successfully!"
exit 0
