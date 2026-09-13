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
