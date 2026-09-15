#!/usr/bin/env bash
# Behavioral Prompt-Contract Verification Harness (Bash)
# Run from repository root: bash scripts/tests/run-behavioral-contract-tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FAIL_COUNT=0
PASS_COUNT=0

assert_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if grep -Ei "$pattern" "$REPO_ROOT/$file" >/dev/null 2>&1; then
        echo "  ✅ PASS: $desc"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ❌ FAIL: $desc (pattern '$pattern' not found in $file)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo ""
echo "🧪 Running PromptKit OS Behavioral Prompt-Contract Tests"
echo "==========================================================="

echo ""
echo "📌 Scenario A: Trivial Change ('Fix a typo in the README') — Level 0 Direct"
assert_contains "workflows/route.md" "Level 0 — Direct" "Level 0 Direct classification defined in router"
assert_contains "workflows/route.md" "understand → change → verify" "Level 0 expected behavior flow present"
assert_contains "templates/agent-directive-template.md" "Fast-Path \(Zero Overhead\)" "Level 0 fast-path rule in agent setup protocol"

echo ""
echo "📌 Scenario B: Localized Bug / Small Feature ('Fix empty password crash') — Level 1 Standard"
assert_contains "workflows/route.md" "Level 1 — Standard" "Level 1 Standard classification defined in router"
assert_contains "workflows/route.md" "does .*not.* trigger Level 2 Controlled Work" "Level 1 file edits do not trigger mandatory Task Record creation"
assert_contains "workflows/plan.md" "Level 1 .*Do NOT create or populate" "Plan workflow specifies Level 1 does not map to Task Record file"
assert_contains "workflows/tasks.md" "Level 0 \(Direct\) and Level 1 \(Standard\) work modify source files directly" "Tasks workflow specifies Level 1 file edits do not require Task Record"

echo ""
echo "📌 Scenario C: Substantive Risk Feature ('Add OAuth login and user roles') — Level 2 Controlled"
assert_contains "workflows/route.md" "Level 2 — Controlled" "Level 2 Controlled classification defined in router"
assert_contains "workflows/route.md" "docs/tasks/<task-id>\.md" "Local Task Record required for Level 2 Controlled Work"
assert_contains "workflows/plan.md" "Level 2 .*Requires canonical Local Task Record readiness" "Plan workflow requires Task Record for Level 2 Minimal/Full Planning"
assert_contains "workflows/auth.md" "matrix" "Auth workflow defines capability matrix requirements"

echo ""
echo "📌 Scenario D: Destructive Operation ('Drop the users table and recreate the schema')"
assert_contains "workflows/data.md" "Expand-Contract" "Data workflow enforces Expand-Contract migration strategy"
assert_contains "templates/pull-request-template.md" "No Destructive Drops" "PR template includes destructive operation safety check"
assert_contains "workflows/route.md" "human authorization" "Router specifies explicit human authorization boundary"

echo ""
echo "📌 Scenario E: Release & Level-3 Downgrade Safety Rules"
assert_contains "workflows/route.md" "Level 3 Downgrade Guardrails" "Level 3 downgrade safety guardrails section present"
assert_contains "workflows/route.md" "no tag creation, release publication, production deployment" "Confirmation no release actions remain in scope"
assert_contains "workflows/route.md" "Release Coordinator approval" "Release Coordinator approval required if release evaluation started"
assert_contains "workflows/route.md" "closure record for any existing release evidence" "Existing release evidence must be preserved or closed"

echo ""
echo "📌 Scenario F: Canonical Mapping & Consistency Checks"
assert_contains "workflows/route.md" "Canonical Mapping & Legacy Compatibility" "Explicit canonical mapping section present in router"
assert_contains "workflows/route.md" "sole authority for Level" "Router Adaptation compatibility contract uses Level 0-3 model"
assert_contains "workflows/plan.md" "Level 0 Direct, Level 1 Standard, Level 2 Controlled, Level 3 Release-Critical" "Plan workflow maps Levels 0-3 explicitly"
assert_contains "README.md" "Level 0 — Direct" "README includes Level 0 ceremony definition"
assert_contains "README.md" "Task Ceremony Levels \(Level 0–3 Execution\)" "README contains Level 0-3 execution model"
assert_contains "README.md" "Level 1 .*does NOT require a Task Record" "README explicitly says Level 1 does not require a Task Record"
assert_contains "README.md" "Level 2 .*Requires a canonical Local Task Record" "README specifies Level 2 requires a Task Record"
assert_contains "README.md" "Level 3 .*Requires Level 2 evidence" "README specifies Level 3 requires Level 2 evidence and Task Record"
assert_contains "workflows/route.md" "treat release and evidence work as Level 3" "Router release-evidence routing uses Level-3 terminology"
assert_contains "README.md" "Maintainer CI \(script syntax, initialization dry-run/idempotency" "README CI description refers to current validation"
assert_contains "docs/WORKFLOW-MAP.md" "Level 1 — Standard" "WORKFLOW-MAP includes Level 1 ceremony definition"

echo ""
echo "📌 Scenario G: Progressive Loading & Canonical Authority"
assert_contains "protocols/setup.md" "Progressive Loading Policy" "protocols/setup.md defines progressive loading policy"
assert_contains "protocols/setup.md" "Level 1 \(Standard\).*Minimal loading path" "Level 1 defines minimal loading path without Task Record"
assert_contains "README.md" "Start Here: Most Work Is Level 1" "README contains early Level-1 onboarding path"
assert_contains "README.md" "For authoritative Level 0–3 classification.*workflows/route\.md" "README links to workflows/route.md as canonical guide"
assert_contains "workflows/route.md" "workflows/route\.md.*is the canonical authority" "workflows/route.md declares canonical ownership of Levels 0-3"

echo ""
echo "📌 Scenario H: Remediation Workflow ('Fix a known review finding') — pk:fix"
assert_contains "workflows/route.md" "pk:fix" "pk:fix trigger defined in lifecycle router"
assert_contains "workflows/fix.md" "Remediation & Surgical Fix Workflow" "Remediation workflow present with title"
assert_contains "workflows/fix.md" "pk:debug" "Remediation workflow distinguishes known cause from pk:debug"
assert_contains "workflows/fix.md" "SECURITY & SAFETY ORDERING" "Remediation workflow enforces security-first ordering"
assert_contains "workflows/fix.md" "Reproduction or Baseline Measurement" "Remediation workflow requires reproduction or baseline measurement"
assert_contains "workflows/fix.md" "Level 1 — Standard Fix" "Remediation workflow aligns with Level 0-3 ceremony model"

echo ""
echo "📌 Scenario I: Post-Staging Secret Scan Sequencing (Time-of-Check to Time-of-Use Safety)"
assert_contains "workflows/commit.md" "Pre-Commit Secret & Hygiene Scan" "Commit workflow enforces post-staging secret scan"
assert_contains "workflows/commit.md" "Immediately after staging" "Secret scan runs immediately after staging phase"

echo ""
echo "📌 Scenario J: Standardized Visual Callouts & Telemetry Status Cards"
assert_contains "templates/agent-directive-template.md" "Native MCP & Interactive Turn Prompts" "Directive includes native MCP and interactive turn prompts guardrail"
assert_contains "templates/agent-directive-template.md" "Dual-Compatible Telemetry Status Cards" "Directive includes dual-compatible telemetry status card guardrail"
assert_contains "templates/agent-directive-template.md" "### 💡 Next Recommended Step" "Directive specifies next recommended step callout format"
assert_contains "templates/agent-directive-template.md" "📊 Milestone:" "Directive specifies telemetry status card format"
assert_contains "workflows/commit.md" "Dual-Compatible Telemetry Status Card" "Commit workflow includes telemetry status card"
assert_contains "workflows/pr.md" "Telemetry Status Card" "PR workflow includes telemetry status card"
assert_contains "workflows/plan.md" "Dual-Compatible Telemetry Status Card" "Plan workflow includes telemetry status card"
assert_contains "workflows/tasks.md" "Dual-Compatible Telemetry Status Card" "Tasks workflow includes telemetry status card"
assert_contains "workflows/test.md" "Dual-Compatible Telemetry Status Card" "Test workflow includes telemetry status card"
assert_contains "workflows/fix.md" "Dual-Compatible Telemetry Status Card" "Fix workflow includes telemetry status card"
assert_contains "workflows/plan.md" "Interactive Decision & Trade-Off Clarification" "Plan workflow includes interactive decision prompt guidelines"

echo ""
echo "📌 Scenario K: Project Database & Harness Isolation"
assert_contains "templates/agent-directive-template.md" "Project Database & Harness Isolation" "Directive enforces project database isolation guardrail"
assert_contains "workflows/data.md" "Database Harness Isolation" "Data workflow mandates project-scoped database isolation"
assert_contains "workflows/test.md" "Project Database Isolation" "Test workflow mandates project-scoped database isolation"

echo ""
echo "📌 Scenario L: Protocol Synchronization & Hot-Reloading (pk:sync)"
assert_contains "templates/agent-directive-template.md" "pk:sync" "Directive includes pk:sync trigger"
assert_contains "templates/agent-directive-template.md" "Disk-First Protocol Loading & Hot-Reload" "Directive enforces disk-first protocol loading guardrail"
assert_contains "workflows/sync.md" "3-Phase Sync Protocol" "Sync workflow defines 3-phase sync protocol"
assert_contains "workflows/sync.md" "Fresh Disk-First Loading" "Sync workflow enforces fresh disk reads"

echo ""
echo "📌 Scenario M: Runtime Profile Switcher & Honest Workflow Counts (pk:profile)"
assert_contains "templates/agent-directive-template.md" 'pk:profile' "Balanced directive includes pk:profile trigger"
assert_contains "templates/agent-directive-lite-template.md" 'pk:profile' "Lite directive includes pk:profile trigger"
assert_contains "workflows/profile.md" "4-Phase Switch Protocol" "Profile workflow defines the 4-phase switch protocol"
assert_contains "workflows/profile.md" "Turbo guard" "Profile workflow enforces the Turbo experimental guard"
assert_contains "workflows/profile.md" "PROMPTKIT_NO_INTERACTIVE" "Profile workflow honors non-interactive default"
assert_contains "workflows/route.md" "Wrong Profile / Mode Upgrade" "Router decision matrix registers pk:profile"
WARN_COUNT=$(bash "$REPO_ROOT/scripts/validate-references.sh" "$REPO_ROOT" 2>&1 | grep -c 'WARNING' || true)
if [ "$WARN_COUNT" -eq 0 ]; then
    echo "  ✅ PASS: Reference validator reports zero trigger warnings"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Reference validator reports $WARN_COUNT warning(s) - orphaned trigger aliases shipped"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
assert_contains "templates/agent-directive-lite-template.md" "Lite - 6 workflows" "Lite directive claims the honest utility workflow count"
assert_contains "templates/agent-directive-template.md" "Session Endurance" "Directive carries the session-endurance checkpoint rule"
assert_contains "templates/agent-directive-template.md" "STATE.md Untrusted Until Read" "Directive mandates fresh-read trust for STATE.md"
assert_contains "templates/agent-directive-template.md" "Telemetry Card Provenance" "Directive mandates telemetry card provenance"
assert_contains "templates/agent-directive-lite-template.md" "~15 substantive turns" "Lite directive carries the endurance rule"
assert_contains "templates/agent-directive-lite-template.md" "not measured" "Lite directive carries the provenance rule"
assert_contains "templates/agent-directive-template.md" 'pk:spike. -> .research\.md' "Directive lists trigger-to-file rename exceptions"
assert_contains "workflows/route.md" "Tie-Break" "Router defines the mixed-level tie-break rule"
assert_contains "templates/agent-directive-template.md" "Ties take the higher level" "Directive carries the tie-break rule"
assert_contains "protocols/code-quality-gate.md" "milestone boundary.*is the turn after" "Quality gate defines the milestone boundary"

for directive_file in "templates/agent-directive-template.md" "templates/agent-directive-lite-template.md"; do
    DUPS=$(awk '/^- `pk:/ {print}' "$REPO_ROOT/$directive_file" | grep -oE '`pk:[a-z-]+`' | sort | uniq -d)
    if [ -z "$DUPS" ]; then
        echo "  ✅ PASS: Trigger tokens are unique within $directive_file"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ❌ FAIL: Duplicate trigger definitions in $directive_file: $(echo "$DUPS" | tr '\n' ' ')"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done
WF_COUNT=$(ls "$REPO_ROOT"/workflows/*.md | wc -l | tr -d ' ')
if [ "$WF_COUNT" -eq 23 ]; then
    echo "  ✅ PASS: On-disk workflow file count is 23 (matches reconciled docs claims)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: On-disk workflow count is $WF_COUNT but shipped docs claim 23 — reconcile counts or update this drift guard"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
STALE_CLAIMS=$(grep -rE 'full 22 workflow|\(22 workflow|22 workflow files|22 Inlined|All 22|22 workflows|All 21 workflow|21 workflow files|19 workflows' \
    "$REPO_ROOT/README.md" "$REPO_ROOT/QUICKSTART.md" "$REPO_ROOT/FAQ.md" "$REPO_ROOT/docs/WORKFLOW-MAP.md" "$REPO_ROOT/docs/BENCHMARKS.md" "$REPO_ROOT/templates/lite-profile.md" "$REPO_ROOT/workflows/sync.md" 2>/dev/null || true)
if [ -z "$STALE_CLAIMS" ]; then
    echo "  ✅ PASS: No stale 19/21/22 workflow-count claims in shipped docs"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  ❌ FAIL: Stale workflow-count claims found:"
    echo "$STALE_CLAIMS" | sed "s|$REPO_ROOT/|  - |" | head -6
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
echo "📌 Scenario N: Greenfield Discovery Intake & Planning Gate (pk:onboard / pk:plan)"
assert_contains "workflows/onboard.md" "Phase 0: Greenfield Discovery Intake" "Onboard workflow defines conditional greenfield Phase 0 intake"
assert_contains "workflows/onboard.md" "never in choice menus" "Intake questions are asked in the context window, not modal pickers"
assert_contains "workflows/onboard.md" "discovery-intake\\.md" "Onboard workflow links the bounded discovery intake protocol"
assert_contains "workflows/onboard.md" "intake-status: legacy-partial" "Brownfield installs get migration-safe intake signals (never re-grilled)"
assert_contains "workflows/onboard.md" "size: small\\|medium\\|large" "Onboard workflow writes machine-readable size class to PROMPTKIT.md"
assert_contains "protocols/discovery-intake.md" "close_reason" "Intake protocol records why the interview closed"
assert_contains "protocols/discovery-intake.md" "Later ledger" "Intake protocol routes AI-suggested scope to the Later ledger"
assert_contains "templates/project-profile-template.md" "intake-status:" "Project profile template carries machine-readable intake signals"
assert_contains "templates/project-profile-template.md" "intake questions, not defaults" "Profile placeholders are declared intake questions, never silent defaults"
assert_contains "workflows/plan.md" "Step 0: Intake Preflight" "Plan workflow gates architecture on intake status before Step 1"
assert_contains "workflows/plan.md" "intake-status: legacy-partial" "Plan workflow never re-interviews brownfield installs"
assert_contains "workflows/plan.md" "Later ledger" "Plan workflow routes unrequired complexity to the Later ledger"
assert_contains "workflows/plan.md" "Decisions I'm defaulting for you" "Plan workflow surfaces agent defaults as an accept-or-change list"
assert_contains "workflows/plan.md" "Picker routing rule" "Plan workflow bounds interactive pickers to closed-set, evidence-backed choices"
assert_contains "workflows/sync.md" "New-Requirement Interception" "Sync workflow intercepts mid-implementation requirement deltas"
assert_contains "workflows/checkpoint.md" "never silently absorbed" "Checkpoint contract requires new requirements to be recorded before continuing"
assert_contains "workflows/route.md" "New Project / Greenfield Inception" "Router decision matrix registers greenfield inception via pk:onboard"
assert_contains "protocols/context-sync.md" "Product & Design Inputs" "Context-sync authority table covers Figma/screenshot/doc design inputs"
assert_contains "workflows/plan.md" "never a full re-interview" "Plan workflow caps partial-intake repair to missing critical slots only (legacy protection)"
assert_contains "workflows/commit.md" "closed-set operational choices" "Blanket Recommended-pickers are bounded to closed-set operational choices"

echo ""
echo "==========================================================="
echo "📊 Behavioral Contract Verification Summary"
echo "Passed: $PASS_COUNT | Failed: $FAIL_COUNT"
echo "==========================================================="

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "❌ Behavioral prompt-contract verification failed."
    exit 1
else
    echo "✅ All behavioral prompt-contract tests passed successfully!"
    exit 0
fi
