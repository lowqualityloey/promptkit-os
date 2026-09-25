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
Assert-Contains "docs/ARCHITECTURE.md" "Maintainer CI \(script syntax, initialization dry-run/idempotency" "ARCHITECTURE layout tree describes current CI validation"
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
Assert-Contains "protocols/telemetry-cards.md" "Dual-Compatible Telemetry Status Cards" "Telemetry-cards protocol carries the relocated status card spec"
Assert-Contains "protocols/telemetry-cards.md" "### 💡 Next Recommended Step" "Telemetry-cards protocol specifies next recommended step callout format"
Assert-Contains "protocols/telemetry-cards.md" "📊 Milestone:" "Telemetry-cards protocol specifies telemetry status card format"
Assert-Contains "templates/agent-directive-template.md" "protocols/telemetry-cards.md" "Directive points to the lazy telemetry-cards protocol"
Assert-Contains "templates/project-profile-template.md" "status-cards:" "Project profile template carries the status-cards machine line"
Assert-Contains "templates/agent-directive-template.md" "status-cards: off" "Directive conditions the card on the status-cards opt-out"
Assert-Contains "templates/agent-directive-lite-template.md" "status-cards: off" "Lite directive conditions the card on the status-cards opt-out"
Assert-Contains "protocols/telemetry-cards.md" "status-cards: off" "Telemetry-cards protocol documents the opt-out and halt guarantee"
Assert-Contains "protocols/telemetry-cards.md" "Quiet Completion" "Telemetry-cards protocol defines quiet completion when nothing is pending"
Assert-Contains "protocols/telemetry-cards.md" "Spend:" "Telemetry-cards protocol specifies the per-turn spend field"
Assert-Contains "templates/state-tracker-template.md" "COMPLETED" "State template offers the terminal COMPLETED status"
Assert-Contains "templates/state-tracker-template.md" "Session Spend Ledger" "State template carries the spend ledger block"
Assert-Contains "workflows/onboard.md" "Session Spend Ledger" "Onboard workflow mandates preserving Session Spend Ledger"
Assert-Contains "init.ps1" 'DocsDir = Join-Path .*docs' "Init script ensures docs directory creation for STATE.md"
Assert-Contains "workflows/checkpoint.md" "Project Closeout Record" "Checkpoint workflow defines the closeout DoD format"
Assert-Contains "workflows/commit.md" "Dual-Compatible Telemetry Status Card" "Commit workflow includes telemetry status card"
Assert-Contains "workflows/pr.md" "Telemetry Status Card" "PR workflow includes telemetry status card"
Assert-Contains "workflows/plan.md" "Dual-Compatible Telemetry Status Card" "Plan workflow includes telemetry status card"
Assert-Contains "workflows/tasks.md" "Dual-Compatible Telemetry Status Card" "Tasks workflow includes telemetry status card"
Assert-Contains "workflows/test.md" "Dual-Compatible Telemetry Status Card" "Test workflow includes telemetry status card"
Assert-Contains "workflows/fix.md" "Dual-Compatible Telemetry Status Card" "Fix workflow includes telemetry status card"
Assert-Contains "workflows/plan.md" "Interactive Decision & Trade-Off Clarification" "Plan workflow includes interactive decision prompt guidelines"
Assert-Contains "workflows/design-system.md" "No-DESIGN.md Visual Floor" "Design workflow defines the no-brand-file finish bar"
Assert-Contains "workflows/design-system.md" "Favicon" "Design gate requires a declared favicon"
Assert-Contains "workflows/design-system.md" "21st.dev" "Design workflow names the advisory catalog with exclusions"
Assert-Contains "workflows/design-system.md" "Curated Aesthetic Archetypes" "Design workflow defines 4 curated aesthetic archetypes"
Assert-Contains "workflows/design-system.md" "Design Study Protocol" "Design workflow defines pk:design study protocol"
Assert-Contains "workflows/design-system.md" "Refuse Uniform Bento Grids" "Design workflow defines anti-bento layout rhythm rule"
Assert-Contains "protocols/discovery-intake.md" "Slot 6 Design Vibe" "Discovery intake includes aesthetic design vibe slot"
Assert-Contains "workflows/design-system.md" "Visual Floor Enforced" "Design workflow checklist includes Visual Floor enforcement"
Assert-Contains "workflows/design-system.md" "Requirement Over Implementation" "Design workflow separates design requirements from implementation examples"
Assert-Contains "workflows/design-system.md" "Design Ceremony Tiers" "Design workflow defines D0-D3 minimum-sufficient ceremony tiers"
Assert-Contains "workflows/design-system.md" "Applicability-Based" "Design workflow scopes interaction states by applicability instead of a blanket 8-state mandate"

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
if ($WfCount -eq 24) {
    Write-Host "  ✅ PASS: On-disk workflow file count is 24 (matches reconciled docs claims)" -ForegroundColor Green
    $script:PassCount++
} else {
    Write-Host "  ❌ FAIL: On-disk workflow count is $WfCount but shipped docs claim 24 — reconcile counts or update this drift guard" -ForegroundColor Red
    $script:FailCount++
}
# Canonical-count drift guard (#347): every live workflow-count claim must state
# the mechanically enforced on-disk count ($WfCount). Claim candidates are
# matched separator-agnostically, then canonical-count claims are blanked —
# whatever remains is stale by definition, so the guard self-maintains when the
# count changes instead of denylisting past values. Historical records
# (docs/releases/, docs/tasks/, docs/archive/, docs/internal/, docs/spikes/,
# CHANGELOG.md) are exempt and are never rewritten silently.
$staleFiles = @(
    "README.md", "QUICKSTART.md", "FAQ.md", "PROMPTKIT.md",
    "docs/WORKFLOW-MAP.md", "docs/BENCHMARKS.md", "docs/ARCHITECTURE.md",
    "docs/COMPARISONS.md", "docs/INTERESTING-FACTS.md",
    "templates/lite-profile.md", "templates/project-profile-template.md", "workflows/sync.md"
) | ForEach-Object { Join-Path $RepoRoot $_ }
$claimPattern = 'full [0-9][0-9]?[- ]workflows?|[Aa]ll [0-9][0-9]? workflows?|[0-9][0-9]? workflow files|[0-9][0-9]? Inlined Workflows?|[(][0-9][0-9]? workflows?'
$stale = Select-String -Path $staleFiles -Pattern $claimPattern -ErrorAction SilentlyContinue | Where-Object {
    $line = $_.Line
    $line = $line -replace "$WfCount Inlined Workflows?", ""
    $line = $line -replace "$WfCount[-]workflow", ""
    $line = $line -replace "$WfCount workflow", ""
    $line -match $claimPattern
}
if ($stale) {
    Write-Host "  ❌ FAIL: Stale workflow-count claims found (docs contradict the on-disk count $WfCount):" -ForegroundColor Red
    $stale | Select-Object -First 6 | ForEach-Object { Write-Host "  - $($_.Path):$($_.LineNumber): $($_.Line.Trim())" }
    $script:FailCount++
} else {
    Write-Host "  ✅ PASS: All live workflow-count claims state the on-disk count ($WfCount) across the claim surface" -ForegroundColor Green
    $script:PassCount++
}
# Fail-closed canonical assertions (#347): the engine profile and the shipped
# project-profile template must positively state the current count, because the
# template seeds PROMPTKIT.md into every fresh project.
$engineProfileOk = ((Select-String -Path (Join-Path $RepoRoot "PROMPTKIT.md") -Pattern ("^  - .balanced.: the full {0}-workflow set" -f $WfCount) -ErrorAction SilentlyContinue) -ne $null) -and
    ((Select-String -Path (Join-Path $RepoRoot "PROMPTKIT.md") -Pattern ('Locked workflow count \(ADR 0002\)\*{0,2}: ' + $WfCount + ' workflows') -ErrorAction SilentlyContinue) -ne $null)
if ($engineProfileOk) {
    Write-Host "  ✅ PASS: Engine PROMPTKIT.md profile states the current count ($WfCount workflows, ADR 0002)" -ForegroundColor Green
    $script:PassCount++
} else {
    Write-Host "  ❌ FAIL: Engine PROMPTKIT.md does not state the current workflow count ($WfCount) — reconcile with ADR 0002" -ForegroundColor Red
    $script:FailCount++
}
$templateProfileOk = (Select-String -Path (Join-Path $RepoRoot "templates/project-profile-template.md") -Pattern ("full {0}-workflow set" -f $WfCount) -ErrorAction SilentlyContinue) -ne $null
if ($templateProfileOk) {
    Write-Host "  ✅ PASS: project-profile template seeds the current count ($WfCount workflows) into fresh projects" -ForegroundColor Green
    $script:PassCount++
} else {
    Write-Host "  ❌ FAIL: project-profile template does not state the current count ($WfCount) — fresh projects would inherit a stale claim" -ForegroundColor Red
    $script:FailCount++
}

Write-Host "`n📌 Scenario N: Greenfield Discovery Intake & Planning Gate (pk:onboard / pk:plan)" -ForegroundColor Yellow
Assert-Contains "workflows/onboard.md" "Phase 0: Greenfield Discovery Intake" "Onboard workflow defines conditional greenfield Phase 0 intake"
Assert-Contains "workflows/onboard.md" "never in choice menus" "Intake questions are asked in the context window, not modal pickers"
Assert-Contains "workflows/onboard.md" "discovery-intake\.md" "Onboard workflow links the bounded discovery intake protocol"
Assert-Contains "workflows/onboard.md" "intake-status: legacy-partial" "Brownfield installs get migration-safe intake signals (never re-grilled)"
Assert-Contains "workflows/onboard.md" "size: small\|medium\|large" "Onboard workflow writes machine-readable size class to PROMPTKIT.md"
Assert-Contains "workflows/onboard.md" "accept-or-change" "Onboard offers tooling proposals accept-or-change, never silent defaults"
Assert-Contains "workflows/onboard.md" "questions, not files" "Onboard answers product-shaped requests with intake questions, not a scaffold"
Assert-Contains "workflows/onboard.md" "Never propose switching" "Onboard treats brownfield toolchain as ground truth"
Assert-Contains "protocols/discovery-intake.md" "close_reason" "Intake protocol records why the interview closed"
Assert-Contains "protocols/discovery-intake.md" "Later ledger" "Intake protocol routes AI-suggested scope to the Later ledger"
Assert-Contains "protocols/discovery-intake.md" "Product-Shape Cover Questions" "Intake asks product-shape (SaaS-class) decision questions before any stack is named"
Assert-Contains "protocols/discovery-intake.md" "Never answer a product-shaped request with a stack" "Intake forbids scaffolds, templates, or a named stack for product-shaped requests"
Assert-Contains "templates/project-profile-template.md" "intake-status:" "Project profile template carries machine-readable intake signals"
Assert-Contains "templates/project-profile-template.md" "intake questions, not defaults" "Profile placeholders are declared intake questions, never silent defaults"
Assert-Contains "workflows/plan.md" "Step 0: Intake Preflight" "Plan workflow gates architecture on intake status before Step 1"
Assert-Contains "workflows/plan.md" "intake-status: legacy-partial" "Plan workflow never re-interviews brownfield installs"
Assert-Contains "workflows/plan.md" "Later ledger" "Plan workflow routes unrequired complexity to the Later ledger"
Assert-Contains "workflows/plan.md" "Decisions I'm defaulting for you" "Plan workflow surfaces agent defaults as an accept-or-change list"
Assert-Contains "workflows/plan.md" "Picker routing rule" "Plan workflow bounds interactive pickers to closed-set, evidence-backed choices"
Assert-Contains "workflows/sync.md" "New-Requirement Interception" "Sync workflow intercepts mid-implementation requirement deltas"
Assert-Contains "workflows/checkpoint.md" "never silently absorbed" "Checkpoint contract requires new requirements to be recorded before continuing"
Assert-Contains "workflows/checkpoint.md" "Fallback Estimation Heuristic" "Checkpoint workflow defines fallback spend estimation heuristic for unmetered hosts"
Assert-Contains "workflows/checkpoint.md" "lower and upper bounds independently" "Checkpoint preserves heuristic ranges instead of midpoint estimates"
Assert-Contains "workflows/checkpoint.md" "Never add measured tokens to a heuristic range" "Checkpoint keeps measured and heuristic token evidence separate"
Assert-Contains "workflows/checkpoint.md" "operational telemetry, not CPAC benchmark evidence" "Checkpoint distinguishes continuity telemetry from formal benchmarks"
Assert-Contains "templates/state-tracker-template.md" "Estimated context payload" "State template labels heuristic payload without implying provider spend"
Assert-Contains "templates/state-tracker-template.md" "repairs=<count or not tracked>" "State template records compact process evidence without inventing missing values"
Assert-Contains "workflows/route.md" "New Project / Greenfield Inception" "Router decision matrix registers greenfield inception via pk:onboard"
Assert-Contains "protocols/context-sync.md" "Product & Design Inputs" "Context-sync authority table covers Figma/screenshot/doc design inputs"
Assert-Contains "workflows/plan.md" "never a full re-interview" "Plan workflow caps partial-intake repair to missing critical slots only (legacy protection)"
Assert-Contains "workflows/commit.md" "closed-set operational choices" "Blanket Recommended-pickers are bounded to closed-set operational choices"
Assert-Contains "workflows/perf.md" "Frontend & Core Web Vitals Layer" "Perf workflow defines Core Web Vitals audit protocol"
Assert-Contains "workflows/refactor.md" "Code Simplification Pass" "Refactor workflow defines Code Simplification Pass and deflation heuristics"

Write-Host "`n📌 Scenario O: Protocol registry & FAQ count drift guards" -ForegroundColor Yellow
$protoFail = $false
$setupContent = Get-Content -Path (Join-Path $RepoRoot "protocols/setup.md") -Raw
foreach ($proto in Get-ChildItem (Join-Path $RepoRoot "protocols") -Filter "*.md") {
    if ($proto.Name -eq "setup.md") { continue }
    if ($setupContent -notmatch [regex]::Escape($proto.Name)) {
        Write-Host "  ❌ FAIL: protocols/setup.md missing registration for $($proto.Name)" -ForegroundColor Red
        $script:FailCount++
        $protoFail = $true
    }
}
if (-not $protoFail) {
    Write-Host "  ✅ PASS: Every protocols/*.md file is registered in protocols/setup.md" -ForegroundColor Green
    $script:PassCount++
}
$faqN = @(Select-String -Path (Join-Path $RepoRoot "FAQ.md") -Pattern '^## [0-9]').Count
$claimedN = @(Select-String -Path (Join-Path $RepoRoot "README.md"), (Join-Path $RepoRoot "FAQ.md") -Pattern 'for the ([0-9]+) most common questions|The ([0-9]+) questions' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Groups[2].Value } } | Sort-Object -Unique)
if (($claimedN.Count -eq 1) -and ([int]$claimedN[0] -eq $faqN)) {
    Write-Host "  ✅ PASS: FAQ entry count ($faqN) matches published claims in README.md/FAQ.md" -ForegroundColor Green
    $script:PassCount++
} else {
    Write-Host "  ❌ FAIL: FAQ entry count is $faqN but published claims are [$($claimedN -join ' ')] — reconcile counts" -ForegroundColor Red
    $script:FailCount++
}

Write-Host "`n📌 Scenario P: Published Figure Exact-Match (BENCHMARKS vs tool output)" -ForegroundColor Yellow
# Same coverage as the .sh twin. Live payloads are recomputed natively here
# (bytes/4 per file); composition MUST match measure-per-task-tokens.sh lines 81-87
# and measure-tokens.sh --strict. Dated records are exempt. Rounding: nearest
# integer percent via Floor(x + 0.5).
function Measure-Tok($RelPath) {
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $RepoRoot $RelPath))
    $cr = @($bytes | Where-Object { $_ -eq 13 }).Count
    return [int][math]::Floor((($bytes.Length - $cr) + 2) / 4)
}
function Check-Figure($Desc, $Live, $Doc) {
    if ($Live -eq $Doc) {
        Write-Host "  ✅ PASS: $Desc ($Doc tok == tool output)" -ForegroundColor Green
        $script:PassCount++
    } else {
        Write-Host "  ❌ FAIL: $Desc published $Doc tok but tool output is $Live tok" -ForegroundColor Red
        $script:FailCount++
    }
}
function Digits($S) { return [int](($S -replace '\D', '')) }
function FirstNum($S) { return [int](([regex]::Match($S, '[0-9,]+')).Value -replace ',', '') }
$benchLines = Get-Content -Path (Join-Path $RepoRoot "docs/BENCHMARKS.md")
$fullTok = Measure-Tok "templates/agent-directive-template.md"
$liteTok = Measure-Tok "templates/agent-directive-lite-template.md"
$gateTok = Measure-Tok "protocols/code-quality-gate.md"
$fixTok = Measure-Tok "workflows/fix.md"
$planTok = Measure-Tok "workflows/plan.md"
$shipTok = Measure-Tok "workflows/ship.md"
$techTok = Measure-Tok "templates/tech-spec-template.md"
$relTok = Measure-Tok "templates/release-checklist.md"
$live = @{
    'pk:fix/balanced' = $fullTok + $fixTok + $gateTok
    'pk:fix/lite'     = $liteTok + $fixTok + $gateTok
    'pk:plan/balanced' = $fullTok + $planTok + $techTok + $gateTok
    'pk:plan/lite'     = $liteTok + $planTok + $techTok + $gateTok
    'pk:ship/balanced' = $fullTok + $shipTok + $relTok + $gateTok
    'pk:ship/lite'     = $liteTok + $shipTok + $relTok + $gateTok
}
$limits = @{ 'pk:fix' = 12861; 'pk:plan' = 24666; 'pk:ship' = 24761 }
foreach ($spec in @('pk:fix', 'pk:plan', 'pk:ship')) {
    $row = @($benchLines | Where-Object { $_ -cmatch "^\| \*\*``$spec``\*\* \|" })[0]
    if ($null -eq $row) {
        Write-Host "  ❌ FAIL: BENCHMARKS.md section-3 row for $spec not found" -ForegroundColor Red
        $script:FailCount++
        continue
    }
    $cols = $row -split '\|'
    $base = Digits $cols[3]
    $balDoc = Digits $cols[4]
    $liteDoc = FirstNum $cols[5]
    $balLive = $live["$spec/balanced"]
    $liteLive = $live["$spec/lite"]
    Check-Figure "$spec Balanced payload" $balLive $balDoc
    Check-Figure "$spec Lite payload" $liteLive $liteDoc
    Check-Figure "$spec baseline constant" $limits[$spec] $base
    $balPctDoc = Digits (([regex]::Match($row, '-[0-9]+% Balanced')).Value)
    $litePctDoc = Digits (([regex]::Match($row, '-[0-9]+% Lite')).Value)
    $balPctLive = [int][math]::Floor((($base - $balLive) * 100.0) / $base + 0.5)
    $litePctLive = [int][math]::Floor((($base - $liteLive) * 100.0) / $base + 0.5)
    Check-Figure "$spec Balanced reduction label" $balPctLive $balPctDoc
    Check-Figure "$spec Lite reduction label" $litePctLive $litePctDoc
}
$balRow = @($benchLines | Where-Object { $_ -cmatch '^\| \*\*Balanced\*\* \|' })[0]
$liteRow = @($benchLines | Where-Object { $_ -cmatch '^\| \*\*Lite\*\* \|' })[0]
if ($null -eq $balRow -or $null -eq $liteRow) {
    Write-Host "  ❌ FAIL: BENCHMARKS.md section-2 profile rows not found" -ForegroundColor Red
    $script:FailCount++
} else {
    Check-Figure "Balanced static directive" $fullTok (Digits (($balRow -split '\|')[4]))
    Check-Figure "Lite static directive" $liteTok (Digits (($liteRow -split '\|')[4]))
}

Write-Host "  -- Prose-claim sweep: anchored Lite shapes must equal $liteTok (dated blocks exempt)" -ForegroundColor Gray
$shapes = @(
    'Lite[^()|]*\([^()]*[0-9,]+ tok(en)?s?\)',
    'Lite uses [0-9,]+ tok',
    'Lite stays at [0-9,]+ tok',
    '[0-9,]+ tok Lite',
    '[0-9,]+ tok(en)?s? static'
)
$benchAll = Get-Content -Path (Join-Path $RepoRoot "docs/BENCHMARKS.md")
$b9s = -1; $b9e = -1
for ($i = 0; $i -lt $benchAll.Count; $i++) {
    if ($benchAll[$i] -cmatch '^## 9\. Proxy Validation') { $b9s = $i }
    elseif ($b9s -ge 0 -and $benchAll[$i] -cmatch '^## Related References') { $b9e = $i; break }
}
$lpAll = Get-Content -Path (Join-Path $RepoRoot "templates/lite-profile.md")
$lps = -1; $lpe = -1
for ($i = 0; $i -lt $lpAll.Count; $i++) {
    if ($lpAll[$i] -cmatch '^## Token Measurements \(measured 2026-09-14') { $lps = $i }
    elseif ($lps -ge 0 -and $lpAll[$i] -cmatch '^## ') { $lpe = $i; break }
}
if ($b9s -lt 0 -or $b9e -lt 0 -or $lps -lt 0 -or $lpe -lt 0) {
    Write-Host "  ❌ FAIL: prose-sweep exempt-range markers missing" -ForegroundColor Red
    $script:FailCount++
} else {
    $proseBad = @()
    $proseFiles = @("README.md","QUICKSTART.md","FAQ.md","CONTRIBUTING.md","docs/BENCHMARKS.md","docs/COMPARISONS.md","docs/ARCHITECTURE.md","docs/WORKFLOW-MAP.md","docs/ADOPTION-GUIDE.md","docs/INTERESTING-FACTS.md","docs/DESIGN-MD-FAQ.md","docs/adaptation-friction-evaluation.md","templates/lite-profile.md")
    foreach ($pf in $proseFiles) {
        $fp = Join-Path $RepoRoot $pf
        if (-not (Test-Path $fp)) { continue }
        $lns = Get-Content -Path $fp
        for ($i = 0; $i -lt $lns.Count; $i++) {
            $ln = $lns[$i]
            if ($ln -notmatch 'Lite' -or $ln -notmatch 'tok') { continue }
            if ($pf -eq "docs/BENCHMARKS.md" -and $i -ge $b9s -and $i -lt $b9e) { continue }
            if ($pf -eq "templates/lite-profile.md" -and $i -ge $lps -and $i -lt $lpe) { continue }
            foreach ($pat in $shapes) {
                foreach ($mm in ([regex]::Matches($ln, $pat))) {
                    $m = $mm.Value
                    if ($m -like '* to *') { continue }
                    $v = [int]((([regex]::Matches($m, '[0-9,]+') | Select-Object -Last 1).Value) -replace ',', '')
                    if ($v -ne $liteTok) { $proseBad += "  - ${pf}:$($i + 1): '$m' (live is $liteTok tok)" }
                }
            }
        }
    }
    if ($proseBad.Count -eq 0) {
        Write-Host "  ✅ PASS: all live Lite prose claims match tool output ($liteTok tok)" -ForegroundColor Green
        $script:PassCount++
    } else {
        Write-Host "  ❌ FAIL: stale Lite prose figures:" -ForegroundColor Red
        $proseBad | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        $script:FailCount++
    }
}

Write-Host "`n📌 Scenario R: Search Circuit Breaker Semantics (Balanced + Lite consistency)" -ForegroundColor Yellow
Assert-Contains "templates/agent-directive-template.md" "Search Circuit Breaker \(advisory\)" "Balanced breaker states advisory semantics"
Assert-Contains "templates/agent-directive-template.md" "parallel batch" "Balanced breaker defines parallel-call counting"
Assert-Contains "templates/agent-directive-template.md" "Trivial edits" "Balanced breaker excludes trivial-edit resets"
Assert-Contains "templates/agent-directive-template.md" "Read-only" "Balanced breaker covers read-only research"
Assert-Contains "docs/BENCHMARKS.md" "advisory instruction, not deterministic tool control" "Balanced breaker distinguishes CI budgets from session/host limits"
Assert-Contains "templates/agent-directive-lite-template.md" "Circuit Breaker \(advisory\)" "Lite breaker states advisory semantics"
Assert-Contains "templates/agent-directive-lite-template.md" "Trivial edits" "Lite breaker excludes trivial-edit resets"
Assert-Contains "templates/agent-directive-lite-template.md" "Read-only" "Lite breaker covers read-only research"

Write-Host "`n📌 Scenario O: Autonomous SDLC Meta-Orchestrator (workflows/auto.md & pk:auto)" -ForegroundColor Yellow
Assert-Contains "workflows/auto.md" "Autonomous SDLC Meta-Orchestrator" "Auto workflow defines autonomous SDLC meta-orchestration"
Assert-Contains "workflows/auto.md" "Test Immobility Invariant" "Auto workflow enforces Test Immobility Invariant"
Assert-Contains "workflows/auto.md" "3-Strike Circuit Breaker" "Auto workflow enforces 3-strike circuit breaker on failures"
Assert-Contains "workflows/auto.md" "Strike 1" "Auto workflow defines explicit 3-strike failure budget (initial failure + 2 refines)"
Assert-Contains "workflows/auto.md" "One park/resume boundary per wave" "Auto workflow bounds Turbo pause/resume to one park per wave"
Assert-Contains "workflows/auto.md" "never an execution trigger" "Auto halt record is passive observable state, not a trigger"
Assert-Contains "workflows/auto.md" "Worker GREEN" "Auto workflow requires integrated-state verification before wave success"
Assert-Contains "workflows/auto.md" "never become an orchestration subsystem" "Auto waves remain a pk:auto capability, not a subsystem"
Assert-Contains "workflows/auto.md" "Path Deny-List" "Auto workflow enforces path deny-list"
Assert-Contains "workflows/auto.md" "review ready" "Auto workflow defaults to review ready stop boundary"
Assert-Contains "workflows/route.md" "workflows/auto.md" "Router decision matrix registers pk:auto"
Assert-Contains "templates/agent-directive-template.md" "pk:auto" "Directive template registers pk:auto trigger"

Write-Host "`n📌 Scenario Q: Memory vs Policy Boundary (pk:checkpoint / pk:sync / pk:onboard)" -ForegroundColor Yellow
Assert-Contains "protocols/context-sync.md" "Observation -> Candidate Learning -> Human Review -> Invariant" "Context-sync defines the memory-vs-policy promotion ladder"
Assert-Contains "protocols/context-sync.md" "Memory vs Policy Boundary" "Context-sync carries the memory-vs-policy boundary section"
Assert-Contains "protocols/context-sync.md" "not approval to promote a rule" "Context-sync rejects silence and implicit signals as promotion approval"
Assert-Contains "protocols/context-sync.md" "remains a projection" "Context-sync keeps STATE.md execution-control scoped as a projection"
Assert-Contains "templates/state-tracker-template.md" "Candidate Learnings" "State template stages unverified candidate learnings"
Assert-Contains "workflows/checkpoint.md" "Candidate Learnings" "Checkpoint preserves pending candidate status on sync"
Assert-Contains "workflows/onboard.md" "Candidate Learnings" "Onboard stages manifest-derived observations as candidates"
Assert-Contains "workflows/sync.md" "never automatically promoted" "Sync never promotes candidates on reread"
Assert-Contains "protocols/context-sync.md" 'Stage a proposed rule.*§4A.*pending' "Context-sync stages pending rules in section 4A"
Assert-Contains "workflows/checkpoint.md" 'Inferred or tentative rules go to Section 4A' "Checkpoint stages inferred rules outside locked invariants"
Assert-Contains "workflows/onboard.md" 'observations belong only in Section 4A' "Onboard never places observations directly in locked invariants"
Assert-Contains "protocols/context-sync.md" 'Rejected or deferred candidates remain non-authoritative; changed scope or wording requires fresh approval' "Rejected and changed candidates cannot inherit approval"
Assert-Contains "protocols/setup.md" 'setup and reinjection must not import session learnings as project rules' "Setup preserves the promotion boundary"
Assert-Contains "templates/state-tracker-template.md" 'approver, date, evidence reference, and destination' "Candidate promotion records decision provenance"

Write-Host "`n📌 Scenario S: Dual-Mode Telemetry & Single-Callout Invariants" -ForegroundColor Yellow
Assert-Contains "protocols/telemetry-cards.md" "The Single-Callout Invariant" "Telemetry protocol defines Single-Callout Invariant"
Assert-Contains "protocols/telemetry-cards.md" "At most ONE human callout block per turn" "Telemetry protocol mandates at most one callout per turn"
Assert-Contains "protocols/telemetry-cards.md" "Universal Square Progress Bar Contract" "Telemetry protocol defines square progress bar contract"
Assert-Contains "protocols/telemetry-cards.md" "■■■■■■■■□□" "Telemetry protocol specifies square progress bar format"
Assert-Contains "protocols/telemetry-cards.md" "Mode 2: CLI / Terminal Mode" "Telemetry protocol specifies CLI mode with ceiling and floor"
Assert-Contains "templates/agent-directive-template.md" "Max 1 callout/turn" "Balanced directive enforces max 1 callout per turn"
Assert-Contains "templates/agent-directive-template.md" "■■■■■■■■□□" "Balanced directive enforces square progress bar"
Assert-Contains "templates/agent-directive-lite-template.md" "Max 1 callout/turn" "Lite directive enforces max 1 callout per turn"
Assert-Contains "templates/agent-directive-lite-template.md" "■■■■■■■■□□" "Lite directive enforces square progress bar"

Write-Host "`n📌 Scenario T: Context Economy, Adaptive Zoom & Anti-Starvation" -ForegroundColor Yellow
Assert-Contains "protocols/context-economy.md" "Minimum Sufficient Context" "Context Economy defines Minimum Sufficient Context invariant"
Assert-Contains "protocols/context-economy.md" "Anti-Starvation" "Context Economy defines Anti-Starvation invariant"
Assert-Contains "protocols/context-economy.md" "Hard Escalation Triggers" "Context Economy specifies Hard Escalation Triggers"
Assert-Contains "protocols/context-economy.md" "Context Sufficiency Check Gate" "Context Economy specifies Context Sufficiency Check gate"
Assert-Contains "protocols/context-economy.md" "4D Context Framework" "Context Economy defines 4D Context model"
Assert-Contains "protocols/context-economy.md" "Z0–Z4 Taxonomy" "Context Economy defines Z0-Z4 zoom taxonomy"
Assert-Contains "protocols/context-economy.md" "Context Provider Capability Contract" "Context Economy defines Context Provider Capability Contract"
Assert-Contains "protocols/context-economy.md" "Retrieval Confidence is Evidence, Not Authority" "Context Economy establishes evidence vs authority invariant"
Assert-Contains "protocols/context-economy.md" "Provider Freshness & Stale-Index Fallback" "Context Economy defines provider freshness invariant"
Assert-Contains "protocols/context-economy.md" "required_capabilities" "Context Economy defines required provider capabilities"
Assert-Contains "templates/agent-directive-template.md" "Context Economy.*Anti-Starvation" "Balanced directive registers the Context Economy contract"
Assert-Contains "templates/agent-directive-lite-template.md" "Context Economy.*Anti-Starvation" "Lite directive registers the Context Economy contract"

Write-Host "`n📌 Scenario U: Table Structural Integrity & Installer Host Auto-Detection" -ForegroundColor Yellow
Assert-Contains "scripts/validate-execution-control.ps1" "ORPHANED_TABLE_ROW" "Validator PS1 defines ORPHANED_TABLE_ROW diagnostic"
Assert-Contains "scripts/validate-execution-control.ps1" "TABLE_COLUMN_MISMATCH" "Validator PS1 defines TABLE_COLUMN_MISMATCH diagnostic"
Assert-Contains "scripts/validate-execution-control.sh" "ORPHANED_TABLE_ROW" "Validator SH defines ORPHANED_TABLE_ROW diagnostic"
Assert-Contains "scripts/validate-execution-control.sh" "TABLE_COLUMN_MISMATCH" "Validator SH defines TABLE_COLUMN_MISMATCH diagnostic"
Assert-Contains "templates/state-tracker-template.md" "Table Invariant" "State tracker template includes table invariant comment"
Assert-Contains "workflows/checkpoint.md" "Table Integrity Invariant" "Checkpoint workflow defines Table Integrity Invariant"
Assert-Contains "init.ps1" "Reconfigure" "init.ps1 supports Reconfigure switch"
Assert-Contains "init.sh" "reconfigure" "init.sh supports reconfigure flag"
Assert-Contains "init.ps1" "Keeping installed hosts" "init.ps1 auto-detects and preserves installed hosts on update"
Assert-Contains "init.sh" "Keeping installed hosts" "init.sh auto-detects and preserves installed hosts on update"

Write-Host "`n📌 Scenario V: Profile Drift Audit (pk:sync vs Repository Reality — Issue #338)" -ForegroundColor Yellow
Assert-Contains "workflows/sync.md" "Profile Drift Audit" "Sync defines the PROMPTKIT.md drift audit section"
Assert-Contains "workflows/sync.md" "detection-only pass" "Sync drift audit is detection-only"
Assert-Contains "workflows/sync.md" "No dependency resolution" "Sync drift audit is bounded to manifest presence"
Assert-Contains "workflows/sync.md" "Detection is observation, not promotion" "Sync drift findings stay on the observation side of the memory-vs-policy boundary"
Assert-Contains "workflows/sync.md" "Never auto-rewrite user-authored sections" "Sync drift audit never auto-rewrites PROMPTKIT.md"
Assert-Contains "workflows/sync.md" "Clean profile is silent" "Clean profile produces no findings and no extra ceremony"

Write-Host "`n📌 Scenario W: Turbo Suitability Check (pk:profile — Issue #337)" -ForegroundColor Yellow
Assert-Contains "workflows/profile.md" "Turbo suitability check" "Profile workflow asks the Turbo suitability question"
Assert-Contains "workflows/profile.md" "zero benefit on sequential work" "Sequential workloads are warned that waves buy zero benefit"
Assert-Contains "workflows/profile.md" "Advisory, never blocking" "Suitability check is advisory and never blocks Turbo"
Assert-Contains "workflows/profile.md" "auto-waves-preflight-checklist.md" "Suitability check links the pre-flight checklist as evidence"
Assert-Contains "workflows/profile.md" "never restate its ticks" "Suitability check links the checklist instead of duplicating it"
Assert-Contains "workflows/profile.md" "still honored" "Explicit Turbo override remains honored after a no answer"
Assert-Contains "workflows/onboard.md" "advisory suitability check" "Onboarding runs the advisory suitability check before Turbo acknowledgement"

Write-Host "`n📌 Scenario X: Proactive Downgrade & Checkpoint Cadence Guidance (pk:route — Issue #339)" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "Proactive Level-Fit Check" "Router performs a proactive per-milestone level-fit check"
Assert-Contains "workflows/route.md" "Milestone Boundaries" "Level-fit check is anchored to milestone boundaries"
Assert-Contains "workflows/route.md" "Proposed, never forced" "Downgrades stay proposed, never forced"
Assert-Contains "workflows/route.md" "Verification is not downgraded" "Downgrade reduces records, never verification"
Assert-Contains "workflows/route.md" "Checkpoint Cadence by Project Size" "Router documents checkpoint cadence by project size"
Assert-Contains "workflows/route.md" "record-keeping is not progress" "Small-project cadence guidance avoids manufactured checkpoint pairs"
Assert-Contains "workflows/route.md" "workflows/checkpoint.md" "Cadence numbers defer to the canonical checkpoint workflow"

Write-Host "`n📌 Scenario Y: Skill Coexistence & Precedence Contract (workflows/route.md & protocols/setup.md — Issue #385)" -ForegroundColor Yellow
Assert-Contains "workflows/route.md" "never reclassifies work" "Router enforces that skill invocation never reclassifies work"
Assert-Contains "workflows/route.md" "yield to PromptKit Hard Gates" "Router mandates skill process instructions yield to hard gates"
Assert-Contains "workflows/route.md" "collide with PromptKit" "Router warns against host skills named with pk- prefix"
Assert-Contains "protocols/setup.md" "\.claude/skills/" "Setup Phase 1 inspects host skill directories"
Assert-Contains "protocols/setup.md" "confirm governance primacy" "Setup confirms governance primacy when skills are detected"
Assert-Contains "docs/ADOPTION-GUIDE.md" "External Skill Coexistence & Deduplication Matrix" "Adoption guide carries skill dedup table"
Assert-Contains "docs/ADOPTION-GUIDE.md" "Git Commit Skills" "Adoption guide dedup table maps commit skills"

Write-Host "`n📌 Scenario Z: Sharpened Subagent Verifier & Reviewer Briefs (Issue #390)" -ForegroundColor Yellow
Assert-Contains "protocols/subagent-delegation.md" "Claims-Audit [Dd]uty" "Subagent delegation defines Claims-Audit duty for reviewers and verifiers"
Assert-Contains "protocols/subagent-delegation.md" "re-verifying.*against the diff and recorded exit codes" "Subagent delegation requires re-verifying claims against diff and exit codes"
Assert-Contains "workflows/review.md" "Claims-Audit [Dd]uty" "Review workflow inherits Claims-Audit duty in dual-axis delegation"
Assert-Contains "workflows/review.md" "security-lens third reviewer" "Review workflow defines trigger-based security-lens third reviewer"
Assert-Contains "workflows/review.md" "create[s]? no approval.*authority" "Review report creates no approval or merge authority"
Assert-Contains "workflows/debug.md" "adversarial pass" "Debug workflow includes adversarial pass in L2+ verifier brief"
Assert-Contains "workflows/debug.md" "attempt to make the fix fail; try the failure mode the fix claims to close" "Debug workflow specifies attempting to break the fix"
Assert-Contains "workflows/debug.md" "Level 0 and Level 1.*bypass" "Debug workflow preserves L0/L1 bypass for Pattern C verification"
Assert-Contains "workflows/ship.md" "evidence audit" "Ship workflow requires Pattern C evidence audit before coordinator review"
Assert-Contains "workflows/ship.md" "tag proposals are unexecuted" "Ship evidence audit verifies tag proposals are unexecuted"
Assert-Contains "workflows/ship.md" "verification links resolve" "Ship evidence audit verifies verification links resolve"
Assert-Contains "workflows/ship.md" "rollback records exist" "Ship evidence audit verifies rollback records exist"

Write-Host "`n📌 Scenario AA: Recipe Schema & Workflow Wiring (Issue #393)" -ForegroundColor Yellow
Assert-Contains "docs/recipes/README.md" "Recipe Catalog Matrix" "Recipe README includes catalog matrix"
Assert-Contains "docs/recipes/README.md" "Architectural Intake Criteria" "Recipe README documents intake criteria and guidance tiers"
Assert-Contains "docs/recipes/README.md" "1,500 tokens" "Recipe README specifies strict 1,500 token ceiling"
Assert-Contains "workflows/auth.md" "docs/recipes/auth-session.md" "Auth workflow links auth-session recipe"
Assert-Contains "workflows/debug.md" "docs/recipes/env-validation.md" "Debug workflow links env-validation recipe"
Assert-Contains "workflows/api.md" "docs/recipes/form-mutations.md" "API workflow links form-mutations recipe"
Assert-Contains "workflows/api.md" "docs/recipes/webhook-idempotency.md" "API workflow links webhook-idempotency recipe"
Assert-Contains "workflows/test.md" "docs/recipes/test-isolation.md" "Test workflow links test-isolation recipe"
Assert-Contains "workflows/onboard.md" "docs/recipes/env-validation.md" "Onboarding workflow links env-validation recipe"

Write-Host "`n📌 Scenario AB: Stack Playbooks Catalog Index & Astro Stack (Issue #392)" -ForegroundColor Yellow
Assert-Contains "docs/stacks/README.md" "Stack Playbook Catalog" "Stacks README includes catalog matrix"
Assert-Contains "docs/stacks/README.md" "Architectural Intake Criteria" "Stacks README documents guidance tiers and intake rules"
Assert-Contains "docs/stacks/README.md" "web-astro.md" "Stacks README catalog indexes web-astro playbook"
Assert-Contains "docs/stacks/README.md" "cms-wordpress.md" "Stacks README documents CMS layer in demand-driven roadmap"
Assert-Contains "docs/stacks/web-astro.md" "name: web-astro" "Astro playbook defines valid frontmatter name"
Assert-Contains "docs/stacks/web-astro.md" "category: web" "Astro playbook uses category: web"
Assert-Contains "docs/stacks/web-astro.md" "astro.config" "Astro playbook declares astro.config manifest activation"
Assert-Contains "docs/stacks/web-astro.md" "npx astro check" "Astro playbook declares fast verification command"

Write-Host "`n📌 Scenario AC: Docker Stack Playbook & Discovery (Issue #396)" -ForegroundColor Yellow
Assert-Contains "docs/stacks/README.md" "deploy-docker.md" "Stacks README catalog indexes deploy-docker playbook"
Assert-Contains "docs/stacks/deploy-docker.md" "name: deploy-docker" "Docker playbook defines valid frontmatter name"
Assert-Contains "docs/stacks/deploy-docker.md" "category: cloud" "Docker playbook uses category: cloud"
Assert-Contains "docs/stacks/deploy-docker.md" "Dockerfile" "Docker playbook declares Dockerfile manifest activation"
Assert-Contains "docs/stacks/deploy-docker.md" "docker compose config" "Docker playbook declares fast verification command"
Assert-Contains "docs/stacks/deploy-docker.md" "Multi-Stage Build Separation" "Docker playbook defines multi-stage invariant"
Assert-Contains "docs/stacks/deploy-docker.md" "Unprivileged Non-Root Execution" "Docker playbook defines non-root invariant"
Assert-Contains "workflows/onboard.md" "Deploy — Docker" "Onboarding workflow detects Docker deployment pattern"

Write-Host "`n📌 Scenario AD: FastAPI Stack Playbook & Discovery (Issue #398)" -ForegroundColor Yellow
Assert-Contains "docs/stacks/README.md" "api-fastapi.md" "Stacks README catalog indexes api-fastapi playbook"
Assert-Contains "docs/stacks/api-fastapi.md" "name: api-fastapi" "FastAPI playbook defines valid frontmatter name"
Assert-Contains "docs/stacks/api-fastapi.md" "category: web" "FastAPI playbook uses category: web"
Assert-Contains "docs/stacks/api-fastapi.md" "alembic.ini" "FastAPI playbook declares alembic.ini manifest activation"
Assert-Contains "docs/stacks/api-fastapi.md" "ruff check" "FastAPI playbook declares fast verification command"
Assert-Contains "docs/stacks/api-fastapi.md" "Pydantic v2 Schema Boundary Separation" "FastAPI playbook defines Pydantic v2 invariant"
Assert-Contains "docs/stacks/api-fastapi.md" "Async vs Sync Handler Discipline" "FastAPI playbook defines async discipline invariant"
Assert-Contains "workflows/onboard.md" "API — FastAPI" "Onboarding workflow detects FastAPI pattern"

Write-Host "`n📌 Scenario AE: Node.js API Stack Playbook & Discovery (Issue #400)" -ForegroundColor Yellow
Assert-Contains "docs/stacks/README.md" "api-node.md" "Stacks README catalog indexes api-node playbook"
Assert-Contains "docs/stacks/api-node.md" "name: api-node" "Node API playbook defines valid frontmatter name"
Assert-Contains "docs/stacks/api-node.md" "category: web" "Node API playbook uses category: web"
Assert-Contains "docs/stacks/api-node.md" "package.json" "Node API playbook declares package.json manifest activation"
Assert-Contains "docs/stacks/api-node.md" "npm run lint" "Node API playbook declares fast verification command"
Assert-Contains "docs/stacks/api-node.md" "Runtime Schema Boundary Validation" "Node API playbook defines runtime schema invariant"
Assert-Contains "docs/stacks/api-node.md" "Event Loop Non-Blocking Discipline" "Node API playbook defines event loop invariant"
Assert-Contains "workflows/onboard.md" "API — Node.js Server" "Onboarding workflow detects Node.js Server pattern"

Write-Host "`n📌 Scenario AF: WordPress CMS Stack Playbook & Discovery (Issue #402)" -ForegroundColor Yellow
Assert-Contains "docs/stacks/README.md" "cms-wordpress.md" "Stacks README catalog indexes cms-wordpress playbook"
Assert-Contains "docs/stacks/cms-wordpress.md" "name: cms-wordpress" "WordPress playbook defines valid frontmatter name"
Assert-Contains "docs/stacks/cms-wordpress.md" "category: web" "WordPress playbook uses category: web"
Assert-Contains "docs/stacks/cms-wordpress.md" "wp-config.php" "WordPress playbook declares wp-config.php manifest activation"
Assert-Contains "docs/stacks/cms-wordpress.md" "composer validate" "WordPress playbook declares fast verification command"
Assert-Contains "docs/stacks/cms-wordpress.md" "Mandatory Prepared SQL Statements" "WordPress playbook defines prepared statements invariant"
Assert-Contains "docs/stacks/cms-wordpress.md" "State Mutation Nonce Verification" "WordPress playbook defines nonce verification invariant"
Assert-Contains "workflows/onboard.md" "CMS — WordPress" "Onboarding workflow detects WordPress pattern"

Write-Host "`n📌 Scenario AG: Human Decision & Question Comprehensibility Contract (Issue #406)" -ForegroundColor Yellow
Assert-Contains "protocols/code-quality-gate.md" "DECISION NEEDED" "Decision Card format sections defined in quality gate"
Assert-Contains "protocols/code-quality-gate.md" "Recommendation mandatory" "Recommendation mandatory on every decision card"
Assert-Contains "protocols/code-quality-gate.md" "accountability.*always human" "Type D accountability routing requires the card"
Assert-Contains "protocols/code-quality-gate.md" "you decide" "You-decide delegation default declared on the card"
Assert-Contains "workflows/plan.md" "Assumption-conversion rule" "Plan workflow defines assumption-conversion rule"
Assert-Contains "workflows/plan.md" "Random answers are worse than assumptions" "Plan workflow forbids extracting guesses"
Assert-Contains "workflows/debug.md" "render the Decision Card" "Debug halt path adopts the Decision Card"
Assert-Contains "workflows/ship.md" "renders the Decision Card" "Ship approval request adopts the Decision Card"
Assert-Contains "templates/agent-directive-lite-template.md" "Assumption Records, never guesses" "Lite directive carries the decision routing one-liner"

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
