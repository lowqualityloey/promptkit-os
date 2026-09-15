# Behavioral Prompt-Contract Verification Harness (PowerShell)
# Run from repository root: pwsh -NoProfile -File .\scripts\tests\run-behavioral-contract-tests.ps1

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")

$script:PassCount = 0
$script:FailCount = 0

function Assert-Contains {
    param(
        [string]$File,
        [string]$Pattern,
        [string]$Description
    )

    $fullPath = Join-Path $RepoRoot $File
    if (Test-Path $fullPath) {
        $content = Get-Content -Path $fullPath -Raw
        if ($content -match $Pattern) {
            Write-Host "  ✅ PASS: $Description" -ForegroundColor Green
            $script:PassCount++
            return
        }
    }
    Write-Host "  ❌ FAIL: $Description (pattern '$Pattern' not found in $File)" -ForegroundColor Red
    $script:FailCount++
}

Write-Host "`n🧪 Running PromptKit OS Behavioral Prompt-Contract Tests" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor DarkGray

Write-Host "`n📌 Scenario A: Trivial Change ('Fix a typo in the README') — Level 0 Direct" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "Level 0 — Direct" "Level 0 Direct classification defined in router"
Assert-Contains "workflows/route.md" "understand → change → verify" "Level 0 expected behavior flow present"
Assert-Contains "templates/agent-directive-template.md" "Fast-Path \(Zero Overhead\)" "Level 0 fast-path rule in agent setup protocol"

Write-Host "`n📌 Scenario B: Localized Bug / Small Feature ('Fix empty password crash') — Level 1 Standard" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "Level 1 — Standard" "Level 1 Standard classification defined in router"
Assert-Contains "workflows/route.md" "does .*not.* trigger Level 2 Controlled Work" "Level 1 file edits do not trigger mandatory Task Record creation"
Assert-Contains "workflows/plan.md" "Level 1 .*Do NOT create or populate" "Plan workflow specifies Level 1 does not map to Task Record file"
Assert-Contains "workflows/tasks.md" "Level 0 \(Direct\) and Level 1 \(Standard\) work modify source files directly" "Tasks workflow specifies Level 1 file edits do not require Task Record"

Write-Host "`n📌 Scenario C: Substantive Risk Feature ('Add OAuth login and user roles') — Level 2 Controlled" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "Level 2 — Controlled" "Level 2 Controlled classification defined in router"
Assert-Contains "workflows/route.md" "docs/tasks/<task-id>\.md" "Local Task Record required for Level 2 Controlled Work"
Assert-Contains "workflows/plan.md" "Level 2 .*Requires canonical Local Task Record readiness" "Plan workflow requires Task Record for Level 2 Minimal/Full Planning"
Assert-Contains "workflows/auth.md" "matrix" "Auth workflow defines capability matrix requirements"

Write-Host "`n📌 Scenario D: Destructive Operation ('Drop the users table and recreate the schema')" -ForegroundColor Yellow
Assert-Contains "workflows/data.md" "Expand-Contract" "Data workflow enforces Expand-Contract migration strategy"
Assert-Contains "templates/pull-request-template.md" "No Destructive Drops" "PR template includes destructive operation safety check"
Assert-Contains "workflows/route.md" "human authorization" "Router specifies explicit human authorization boundary"

Write-Host "`n📌 Scenario E: Release & Level-3 Downgrade Safety Rules" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "Level 3 Downgrade Guardrails" "Level 3 downgrade safety guardrails section present"
Assert-Contains "workflows/route.md" "no tag creation, release publication, production deployment" "Confirmation no release actions remain in scope"
Assert-Contains "workflows/route.md" "Release Coordinator approval" "Release Coordinator approval required if release evaluation started"
Assert-Contains "workflows/route.md" "closure record for any existing release evidence" "Existing release evidence must be preserved or closed"

Write-Host "`n📌 Scenario F: Canonical Mapping & Consistency Checks" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "Canonical Mapping & Legacy Compatibility" "Explicit canonical mapping section present in router"
Assert-Contains "workflows/route.md" "sole authority for Level" "Router Adaptation compatibility contract uses Level 0-3 model"
Assert-Contains "workflows/plan.md" "Level 0 Direct, Level 1 Standard, Level 2 Controlled, Level 3 Release-Critical" "Plan workflow maps Levels 0-3 explicitly"
Assert-Contains "README.md" "Level 0 — Direct" "README includes Level 0 ceremony definition"
Assert-Contains "README.md" "Task Ceremony Levels \(Level 0–3 Execution\)" "README contains Level 0-3 execution model"
Assert-Contains "README.md" "Level 1 .*does NOT require a Task Record" "README explicitly says Level 1 does not require a Task Record"
Assert-Contains "README.md" "Level 2 .*Requires a canonical Local Task Record" "README specifies Level 2 requires a Task Record"
Assert-Contains "README.md" "Level 3 .*Requires Level 2 evidence" "README specifies Level 3 requires Level 2 evidence and Task Record"
Assert-Contains "workflows/route.md" "treat release and evidence work as Level 3" "Router release-evidence routing uses Level-3 terminology"
Assert-Contains "README.md" "Maintainer CI \(script syntax, initialization dry-run/idempotency" "README CI description refers to current validation"
Assert-Contains "docs/WORKFLOW-MAP.md" "Level 1 — Standard" "WORKFLOW-MAP includes Level 1 ceremony definition"

Write-Host "`n📌 Scenario G: Progressive Loading & Canonical Authority" -ForegroundColor Yellow
Assert-Contains "protocols/setup.md" "Progressive Loading Policy" "protocols/setup.md defines progressive loading policy"
Assert-Contains "protocols/setup.md" "Level 1 \(Standard\).*Minimal loading path" "Level 1 defines minimal loading path without Task Record"
Assert-Contains "README.md" "Start Here: Most Work Is Level 1" "README contains early Level-1 onboarding path"
Assert-Contains "README.md" "For authoritative Level 0–3 classification.*workflows/route\.md" "README links to workflows/route.md as canonical guide"
Assert-Contains "workflows/route.md" "workflows/route\.md.*is the canonical authority" "workflows/route.md declares canonical ownership of Levels 0-3"

Write-Host "`n📌 Scenario H: Remediation Workflow ('Fix a known review finding') — pk:fix" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "pk:fix" "pk:fix trigger defined in lifecycle router"
Assert-Contains "workflows/fix.md" "Remediation & Surgical Fix Workflow" "Remediation workflow present with title"
Assert-Contains "workflows/fix.md" "pk:debug" "Remediation workflow distinguishes known cause from pk:debug"
Assert-Contains "workflows/fix.md" "SECURITY & SAFETY ORDERING" "Remediation workflow enforces security-first ordering"
Assert-Contains "workflows/fix.md" "Reproduction or Baseline Measurement" "Remediation workflow requires reproduction or baseline measurement"
Assert-Contains "workflows/fix.md" "Level 1 — Standard Fix" "Remediation workflow aligns with Level 0-3 ceremony model"

Write-Host "`n📌 Scenario I: Post-Staging Secret Scan Sequencing (Time-of-Check to Time-of-Use Safety)" -ForegroundColor Yellow
Assert-Contains "workflows/commit.md" "Pre-Commit Secret & Hygiene Scan" "Commit workflow enforces post-staging secret scan"
Assert-Contains "workflows/commit.md" "Immediately after staging" "Secret scan runs immediately after staging phase"

Write-Host "`n📌 Scenario J: Standardized Visual Callouts & Telemetry Status Cards" -ForegroundColor Yellow
Assert-Contains "templates/agent-directive-template.md" "Native MCP & Interactive Turn Prompts" "Directive includes native MCP and interactive turn prompts guardrail"
Assert-Contains "templates/agent-directive-template.md" "Dual-Compatible Telemetry Status Cards" "Directive includes dual-compatible telemetry status card guardrail"
Assert-Contains "templates/agent-directive-template.md" "### 💡 Next Recommended Step" "Directive specifies next recommended step callout format"
Assert-Contains "templates/agent-directive-template.md" "📊 Milestone:" "Directive specifies telemetry status card format"
Assert-Contains "workflows/commit.md" "Dual-Compatible Telemetry Status Card" "Commit workflow includes telemetry status card"
Assert-Contains "workflows/pr.md" "Telemetry Status Card" "PR workflow includes telemetry status card"
Assert-Contains "workflows/plan.md" "Dual-Compatible Telemetry Status Card" "Plan workflow includes telemetry status card"
Assert-Contains "workflows/tasks.md" "Dual-Compatible Telemetry Status Card" "Tasks workflow includes telemetry status card"
Assert-Contains "workflows/test.md" "Dual-Compatible Telemetry Status Card" "Test workflow includes telemetry status card"
Assert-Contains "workflows/fix.md" "Dual-Compatible Telemetry Status Card" "Fix workflow includes telemetry status card"
Assert-Contains "workflows/plan.md" "Interactive Decision & Trade-Off Clarification" "Plan workflow includes interactive decision prompt guidelines"

Write-Host "`n📌 Scenario K: Project Database & Harness Isolation" -ForegroundColor Yellow
Assert-Contains "templates/agent-directive-template.md" "Project Database & Harness Isolation" "Directive enforces project database isolation guardrail"
Assert-Contains "workflows/data.md" "Database Harness Isolation" "Data workflow mandates project-scoped database isolation"
Assert-Contains "workflows/test.md" "Project Database Isolation" "Test workflow mandates project-scoped database isolation"

Write-Host "`n📌 Scenario L: Protocol Synchronization & Hot-Reloading (pk:sync)" -ForegroundColor Yellow
Assert-Contains "templates/agent-directive-template.md" "pk:sync" "Directive includes pk:sync trigger"
Assert-Contains "templates/agent-directive-template.md" "Disk-First Protocol Loading & Hot-Reload" "Directive enforces disk-first protocol loading guardrail"
Assert-Contains "workflows/sync.md" "3-Phase Sync Protocol" "Sync workflow defines 3-phase sync protocol"
Assert-Contains "workflows/sync.md" "Fresh Disk-First Loading" "Sync workflow enforces fresh disk reads"

Write-Host "`n📌 Scenario M: Runtime Profile Switcher & Honest Workflow Counts (pk:profile)" -ForegroundColor Yellow
Assert-Contains "templates/agent-directive-template.md" "pk:profile" "Balanced directive includes pk:profile trigger"
Assert-Contains "templates/agent-directive-lite-template.md" "pk:profile" "Lite directive includes pk:profile trigger"
Assert-Contains "workflows/profile.md" "4-Phase Switch Protocol" "Profile workflow defines the 4-phase switch protocol"
Assert-Contains "workflows/profile.md" "Turbo guard" "Profile workflow enforces the Turbo experimental guard"
Assert-Contains "workflows/profile.md" "PROMPTKIT_NO_INTERACTIVE" "Profile workflow honors non-interactive default"
Assert-Contains "workflows/route.md" "Wrong Profile / Mode Upgrade" "Router decision matrix registers pk:profile"
$warnOut = (& bash scripts/validate-references.sh . 2>&1) -join "`n"
$warnCount = ([regex]::Matches($warnOut, 'WARNING')).Count
if ($warnCount -eq 0) {
    Write-Host "  ✅ PASS: Reference validator reports zero trigger warnings" -ForegroundColor Green
    $script:PassCount++
} else {
    Write-Host "  ❌ FAIL: Reference validator reports $warnCount warning(s) - orphaned trigger aliases shipped" -ForegroundColor Red
    $script:FailCount++
}
Assert-Contains "templates/agent-directive-lite-template.md" "Lite - 6 workflows" "Lite directive claims the honest utility workflow count"
Assert-Contains "templates/agent-directive-template.md" "Session Endurance" "Directive carries the session-endurance checkpoint rule"
Assert-Contains "templates/agent-directive-template.md" "STATE.md Untrusted Until Read" "Directive mandates fresh-read trust for STATE.md"
Assert-Contains "templates/agent-directive-template.md" "Telemetry Card Provenance" "Directive mandates telemetry card provenance"
Assert-Contains "templates/agent-directive-lite-template.md" "~15 substantive turns" "Lite directive carries the endurance rule"
Assert-Contains "templates/agent-directive-lite-template.md" "not measured" "Lite directive carries the provenance rule"
Assert-Contains "templates/agent-directive-template.md" 'pk:spike. -> .research\.md' "Directive lists trigger-to-file rename exceptions"
Assert-Contains "workflows/route.md" "Tie-Break" "Router defines the mixed-level tie-break rule"
Assert-Contains "templates/agent-directive-template.md" "Ties take the higher level" "Directive carries the tie-break rule"
Assert-Contains "protocols/code-quality-gate.md" "milestone boundary.*is the turn after" "Quality gate defines the milestone boundary"

foreach ($directive in @("templates/agent-directive-template.md", "templates/agent-directive-lite-template.md")) {
    $tokens = Select-String -Path (Join-Path $RepoRoot $directive) -Pattern '^- `pk:' |
        ForEach-Object { [regex]::Matches($_.Line, '`pk:[a-z-]+`') } |
        ForEach-Object { $_.Value }
    $dups = $tokens | Group-Object | Where-Object { $_.Count -gt 1 }
    if (-not $dups) {
        Write-Host "  ✅ PASS: Trigger tokens are unique within $directive" -ForegroundColor Green
        $script:PassCount++
    } else {
        Write-Host "  ❌ FAIL: Duplicate trigger definitions in ${directive}: $(($dups | ForEach-Object Name) -join ' ')" -ForegroundColor Red
        $script:FailCount++
    }
}
$WfCount = @(Get-ChildItem (Join-Path $RepoRoot "workflows") -Filter "*.md").Count
if ($WfCount -eq 23) {
    Write-Host "  ✅ PASS: On-disk workflow file count is 23 (matches reconciled docs claims)" -ForegroundColor Green
    $script:PassCount++
} else {
    Write-Host "  ❌ FAIL: On-disk workflow count is $WfCount but shipped docs claim 23 — reconcile counts or update this drift guard" -ForegroundColor Red
    $script:FailCount++
}
$staleFiles = @("README.md","QUICKSTART.md","FAQ.md","docs/WORKFLOW-MAP.md","docs/BENCHMARKS.md","templates/lite-profile.md","workflows/sync.md") | ForEach-Object { Join-Path $RepoRoot $_ }
$stale = Select-String -Path $staleFiles -Pattern 'full 22 workflow|\(22 workflow|22 workflow files|22 Inlined|All 22|22 workflows|All 21 workflow|21 workflow files|19 workflows' -ErrorAction SilentlyContinue
if ($stale) {
    Write-Host "  ❌ FAIL: Stale 19/21/22 workflow-count claims found in shipped docs" -ForegroundColor Red
    $script:FailCount++
} else {
    Write-Host "  ✅ PASS: No stale 21/22 workflow-count claims in shipped docs" -ForegroundColor Green
    $script:PassCount++
}

Write-Host "`n📌 Scenario N: Greenfield Discovery Intake & Planning Gate (pk:onboard / pk:plan)" -ForegroundColor Yellow
Assert-Contains "workflows/onboard.md" "Phase 0: Greenfield Discovery Intake" "Onboard workflow defines conditional greenfield Phase 0 intake"
Assert-Contains "workflows/onboard.md" "never in choice menus" "Intake questions are asked in the context window, not modal pickers"
Assert-Contains "workflows/onboard.md" "discovery-intake\.md" "Onboard workflow links the bounded discovery intake protocol"
Assert-Contains "workflows/onboard.md" "intake-status: legacy-partial" "Brownfield installs get migration-safe intake signals (never re-grilled)"
Assert-Contains "workflows/onboard.md" "size: small\|medium\|large" "Onboard workflow writes machine-readable size class to PROMPTKIT.md"
Assert-Contains "protocols/discovery-intake.md" "close_reason" "Intake protocol records why the interview closed"
Assert-Contains "protocols/discovery-intake.md" "Later ledger" "Intake protocol routes AI-suggested scope to the Later ledger"
Assert-Contains "templates/project-profile-template.md" "intake-status:" "Project profile template carries machine-readable intake signals"
Assert-Contains "templates/project-profile-template.md" "intake questions, not defaults" "Profile placeholders are declared intake questions, never silent defaults"
Assert-Contains "workflows/plan.md" "Step 0: Intake Preflight" "Plan workflow gates architecture on intake status before Step 1"
Assert-Contains "workflows/plan.md" "intake-status: legacy-partial" "Plan workflow never re-interviews brownfield installs"
Assert-Contains "workflows/plan.md" "Later ledger" "Plan workflow routes unrequired complexity to the Later ledger"
Assert-Contains "workflows/plan.md" "Decisions I'm defaulting for you" "Plan workflow surfaces agent defaults as an accept-or-change list"
Assert-Contains "workflows/plan.md" "Picker routing rule" "Plan workflow bounds interactive pickers to closed-set, evidence-backed choices"

Write-Host "`n===========================================================" -ForegroundColor DarkGray
Write-Host "📊 Behavioral Contract Verification Summary" -ForegroundColor Cyan
Write-Host "Passed: $script:PassCount | Failed: $script:FailCount" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor DarkGray

if ($script:FailCount -gt 0) {
    Write-Host "❌ Behavioral prompt-contract verification failed.`n" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ All behavioral prompt-contract tests passed successfully!`n" -ForegroundColor Green
    exit 0
}
