<#
.SYNOPSIS
  Behavioral Contract & Safety Floor Tests for pk-route.ps1 (PowerShell twin).

.DESCRIPTION
  PowerShell twin of scripts/tests/run-pk-route-tests.sh. Same group numbering
  (1-12), same fixture strings, same expected levels, same [PASS]/[FAIL] output,
  and the same summary + exit semantics.

  This suite encodes the contract AFTER the two parallel changes land:
    - #592: the optional external AI integration is retired in full. There is no
            credential gate and no network transport; the router always classifies
            deterministically. Legacy AI_GATEWAY_API_KEY / TYPESAFE_API_KEY values
            must be ignored entirely (never read, never leaked, never contacted).
    - #594: the L0-L3 classifier is corrected on a bounded fixture set. This file
            records the expected-vs-observed levels for those fixtures in an
            explicit FP/FN table and fails while either named defect remains:
              * FP: `What is a breaking change?`  was over-classified as L2 (want L0)
              * FN: `Add an optional field to the public REST response` was
                    under-classified as L1 (want L2)

  Verification model: this suite is expected to run RED against the CURRENT,
  unmodified router until the router change lands, and GREEN afterwards.
#>

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path (Join-Path $scriptDir "..") "..")).Path
$pkRoute = Join-Path (Join-Path $repoRoot "scripts") "pk-route.ps1"

# The PowerShell host running this suite, so the twin router is spawned with the
# same interpreter regardless of anything shadowing `pwsh` on PATH.
$pwshExe = (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($pwshExe)) { $pwshExe = "pwsh" }

$passed = 0
$failed = 0

function Assert-Contains ([string]$haystack, [string]$needle, [string]$testName) {
  if ($haystack.Contains($needle)) {
    Write-Host "  [PASS] $testName" -ForegroundColor Green
    $script:passed++
  } else {
    Write-Host "  [FAIL] $testName" -ForegroundColor Red
    Write-Host "         Expected to find: '$needle'"
    Write-Host "         Actual output:    '$haystack'"
    $script:failed++
  }
}

function Assert-NotContains ([string]$haystack, [string]$needle, [string]$testName) {
  if (-not $haystack.Contains($needle)) {
    Write-Host "  [PASS] $testName" -ForegroundColor Green
    $script:passed++
  } else {
    Write-Host "  [FAIL] $testName" -ForegroundColor Red
    Write-Host "         Found forbidden string: '$needle'"
    $script:failed++
  }
}

function Assert-ExitZero ([int]$code, [string]$testName) {
  if ($code -eq 0) {
    Write-Host "  [PASS] $testName" -ForegroundColor Green
    $script:passed++
  } else {
    Write-Host "  [FAIL] $testName" -ForegroundColor Red
    Write-Host "         Expected exit code 0, got: '$code'"
    $script:failed++
  }
}

function Assert-FileExists ([string]$path, [string]$testName) {
  if (Test-Path -Path $path -PathType Leaf) {
    Write-Host "  [PASS] $testName" -ForegroundColor Green
    $script:passed++
  } else {
    Write-Host "  [FAIL] $testName" -ForegroundColor Red
    Write-Host "         Expected file to exist: '$path'"
    $script:failed++
  }
}

# Asserts a forbidden construct is absent from the router SOURCE (static guard).
function Assert-SourceAbsent ([string]$needle, [string]$testName) {
  $hits = @()
  if (Test-Path -Path $pkRoute -PathType Leaf) {
    $hits = @(Select-String -Path $pkRoute -Pattern $needle -SimpleMatch -CaseSensitive:$false)
  }
  if ($hits.Count -gt 0) {
    Write-Host "  [FAIL] $testName" -ForegroundColor Red
    Write-Host "         Forbidden construct still present in router source: '$needle'"
    $script:failed++
  } else {
    Write-Host "  [PASS] $testName" -ForegroundColor Green
    $script:passed++
  }
}

# Deterministic, credential-free invocation: strip the retired AI credentials so
# the suite exercises the post-#592 routing contract (no credential gate, no
# network). The router must produce an identical classification regardless.
function Invoke-Route ([string]$prompt, [switch]$Offline) {
  $savedGw = $env:AI_GATEWAY_API_KEY
  $savedTs = $env:TYPESAFE_API_KEY
  try {
    $env:AI_GATEWAY_API_KEY = $null
    $env:TYPESAFE_API_KEY = $null
    $cmdArgs = @("-NoProfile", "-File", $pkRoute)
    if ($Offline) { $cmdArgs += "-Offline" }
    $cmdArgs += @("-Prompt", $prompt)
    return (& $pwshExe @cmdArgs | Out-String)
  } finally {
    $env:AI_GATEWAY_API_KEY = $savedGw
    $env:TYPESAFE_API_KEY = $savedTs
  }
}

# Extracts the ceremony level (0-3) from a router banner, or "?" if absent.
function Get-ExtractedLevel ([string]$text) {
  $match = [regex]::Match($text, 'Level ([0-3])')
  if ($match.Success) { return $match.Groups[1].Value }
  return "?"
}

Write-Host "=== Running pk-route.ps1 Behavioral Contract Tests ===" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Test 1: Help Flag (Group 1)
# ------------------------------------------------------------------------------
Write-Host "Test 1: Help flag prints usage and exits 0"
$helpOut = & $pwshExe -NoProfile -File $pkRoute -Help | Out-String
Assert-Contains $helpOut "Usage: pk-route.ps1" "Help flag contains usage"
# #592: help text must not surface the retired integration vocabulary.
Assert-NotContains $helpOut "Jev" "Help text does not mention Jev"
Assert-NotContains $helpOut "TypeSafe" "Help text does not mention TypeSafe"
Assert-NotContains $helpOut "AI_GATEWAY_API_KEY" "Help text does not mention AI_GATEWAY_API_KEY"
Assert-NotContains $helpOut "TYPESAFE_API_KEY" "Help text does not mention TYPESAFE_API_KEY"
Assert-NotContains $helpOut "curl" "Help text does not mention curl"
# F-4: deprecated compatibility flags must be labelled as such.
Assert-Contains $helpOut "Deprecated" "Help text contains Deprecated (F-4)"

# ------------------------------------------------------------------------------
# Test 2: No credential gate (Group 2, rewritten from "missing key")
# ------------------------------------------------------------------------------
# #592 deletes the credential gate, so there is no longer a "no API key"
# scenario: with both credentials unset and no -Offline the router must still
# classify deterministically and recommend the fix workflow.
Write-Host "Test 2: Credential-free routing still yields Level 0 + pk:fix"
$l0Out = Invoke-Route "fix typo in README.md"
Assert-Contains $l0Out "Level 0 (Direct)" "L0 typo classified as Level 0"
Assert-Contains $l0Out "Recommended Workflow: pk:fix" "L0 typo recommends pk:fix"

# ------------------------------------------------------------------------------
# Test 3: Hard Safety Floor: Migration / Schema (L2) — KEEP AS-IS
# ------------------------------------------------------------------------------
Write-Host "Test 3: Scenario 4 - Hard safety floor for schema/migration (L2)"
$l2Out = Invoke-Route "minor tweak to ALTER TABLE in user schema"
Assert-Contains $l2Out "Level 2 (Controlled)" "ALTER TABLE classified as Level 2"
Assert-Contains $l2Out "Task Record required" "L2 notes Task Record required"

# ------------------------------------------------------------------------------
# Test 4: Hard Safety Floor: Production Deploy / Release (L3) — KEEP AS-IS
# ------------------------------------------------------------------------------
Write-Host "Test 4: Scenario 4 - Hard safety floor for release/deploy (L3)"
$l3Out = Invoke-Route "tag and deploy release v1.0.0 to production"
Assert-Contains $l3Out "Level 3 (Release-Critical)" "Deploy classified as Level 3"
Assert-Contains $l3Out "Recommended Workflow: pk:ship" "Deploy recommends pk:ship"

# ------------------------------------------------------------------------------
# Test 5: Adversarial Phrasing Hard Triggers — KEEP AS-IS
# ------------------------------------------------------------------------------
Write-Host "Test 5: Scenario 4 - Adversarial phrasing hard triggers (0% underclassification)"
$adv1Out = Invoke-Route "quickly update the production database before release"
Assert-Contains $adv1Out "Level 3 (Release-Critical)" "Adversarial 1 -> Level 3"

$adv2Out = Invoke-Route "just change the migration and ship it"
Assert-Contains $adv2Out "Level 2 (Controlled)" "Adversarial 2 -> Level 2"

$adv3Out = Invoke-Route "can you make this live?"
Assert-Contains $adv3Out "Level 3 (Release-Critical)" "Adversarial 3 -> Level 3"

# ------------------------------------------------------------------------------
# Test 6: Legacy credentials are ignored (Group 6, rewritten from "API failure")
# ------------------------------------------------------------------------------
# #592 retires the network transport, so there is no API to fail. Presence of
# legacy credential env vars must change nothing: deterministic classification,
# no sentinel leak, and no "Falling back" diagnostic.
Write-Host "Test 6: Legacy credentials are ignored"
$SENTINEL_GW = "svc-sentinel-1"
$SENTINEL_TS = "svc-sentinel-2"
$grp6ErrFile = [System.IO.Path]::GetTempFileName()
$grp6Exit = 1
$grp6Raw = @()
$savedGw = $env:AI_GATEWAY_API_KEY
$savedTs = $env:TYPESAFE_API_KEY
try {
  $env:AI_GATEWAY_API_KEY = $SENTINEL_GW
  $env:TYPESAFE_API_KEY = $SENTINEL_TS
  $grp6Raw = & $pwshExe -NoProfile -File $pkRoute -Prompt "debug null pointer exception" 2>$grp6ErrFile
  $grp6Exit = $LASTEXITCODE
} finally {
  $env:AI_GATEWAY_API_KEY = $savedGw
  $env:TYPESAFE_API_KEY = $savedTs
}
$grp6Out = $grp6Raw | Out-String
$grp6ErrContent = if (Test-Path $grp6ErrFile) { Get-Content -Raw $grp6ErrFile } else { "" }
Remove-Item -Force $grp6ErrFile -ErrorAction SilentlyContinue

Assert-ExitZero $grp6Exit "Router exits 0 with legacy credentials present"
Assert-Contains $grp6Out "PromptKit OS: Level" "Output contains valid level banner"
Assert-Contains $grp6Out "Recommended Workflow: pk:debug" "Workflow resolved to pk:debug"
Assert-NotContains $grp6Out $SENTINEL_GW "Gateway sentinel never appears on stdout"
Assert-NotContains $grp6Out $SENTINEL_TS "TypeSafe sentinel never appears on stdout"
Assert-NotContains $grp6ErrContent $SENTINEL_GW "Gateway sentinel never appears on stderr"
Assert-NotContains $grp6ErrContent $SENTINEL_TS "TypeSafe sentinel never appears on stderr"
Assert-NotContains $grp6ErrContent "Falling back" "No network fallback diagnostic on stderr"

# ------------------------------------------------------------------------------
# Test 7: Static retirement guard (Group 7, rewritten from "secret hygiene")
# ------------------------------------------------------------------------------
# #592 is a full retirement: no surviving external-network construct may remain
# anywhere in the router source. This is a STATIC source scan, not a runtime
# probe. Any hit fails the guard.
Write-Host "Test 7: Static retirement guard (no external-network constructs in source)"
Assert-FileExists $pkRoute "Router source is present for static scan"
Assert-SourceAbsent "curl" "Router source contains no 'curl'"
Assert-SourceAbsent "wget" "Router source contains no 'wget'"
Assert-SourceAbsent "Invoke-RestMethod" "Router source contains no 'Invoke-RestMethod'"
Assert-SourceAbsent "Invoke-WebRequest" "Router source contains no 'Invoke-WebRequest'"
Assert-SourceAbsent "AI_GATEWAY_API_KEY" "Router source contains no 'AI_GATEWAY_API_KEY'"
Assert-SourceAbsent "TYPESAFE_API_KEY" "Router source contains no 'TYPESAFE_API_KEY'"
Assert-SourceAbsent "ai-gateway" "Router source contains no 'ai-gateway'"
Assert-SourceAbsent "typesafe.ai" "Router source contains no 'typesafe.ai'"
Assert-SourceAbsent "jev" "Router source contains no 'jev' (case-insensitive)"

# ------------------------------------------------------------------------------
# Test 8: Issue #345 - Synonym hard triggers — KEEP AS-IS
# ------------------------------------------------------------------------------
Write-Host "Test 8: Issue #345 - Synonym hard triggers (deterministic, offline)"

# Scenario 1: Auth synonyms must reach L2
$auth1Out = Invoke-Route "Add Google login to the app" -Offline
Assert-Contains $auth1Out "Level 2 (Controlled)" "H2: 'Add Google login' -> Level 2"
Assert-Contains $auth1Out "Task Record required" "H2: L2 notes Task Record required"

$auth2Out = Invoke-Route "Let people sign in with their Google account" -Offline
Assert-Contains $auth2Out "Level 2 (Controlled)" "H2a: 'sign in with Google' -> Level 2"

$auth3Out = Invoke-Route "Add SSO to the dashboard" -Offline
Assert-Contains $auth3Out "Level 2 (Controlled)" "Auth synonym: 'SSO' -> Level 2"

$auth4Out = Invoke-Route "Let users sign-up with an email and password" -Offline
Assert-Contains $auth4Out "Level 2 (Controlled)" "Auth synonym: 'sign-up'/'password' -> Level 2"

# Scenario 2: Release and live-publication synonyms must reach L3
$rel1Out = Invoke-Route "Ship the new version to real users" -Offline
Assert-Contains $rel1Out "Level 3 (Release-Critical)" "H3a: bare 'ship' -> Level 3"

$rel2Out = Invoke-Route "Could we turn this on for everyone now" -Offline
Assert-Contains $rel2Out "Level 3 (Release-Critical)" "H5a: 'turn this on' -> Level 3"

$rel3Out = Invoke-Route "Make the app live tomorrow morning" -Offline
Assert-Contains $rel3Out "Level 3 (Release-Critical)" "Live publication with modifier -> Level 3"

# Scenario 3: API-contract synonyms must reach L2
$api1Out = Invoke-Route "Change the public API response format for /v1/users" -Offline
Assert-Contains $api1Out "Level 2 (Controlled)" "H6: 'API response format' -> Level 2"

$api2Out = Invoke-Route "Tweak what the users endpoint gives back" -Offline
Assert-Contains $api2Out "Level 2 (Controlled)" "H6a: 'users endpoint' -> Level 2"

$api3Out = Invoke-Route "Adjust the API payload for the create-order call" -Offline
Assert-Contains $api3Out "Level 2 (Controlled)" "API synonym: 'API payload' -> Level 2"

# Bare ship must NOT defeat an L2 trigger (existing floor behaviour preserved)
$shipL2Out = Invoke-Route "just change the migration and ship it" -Offline
Assert-Contains $shipL2Out "Level 2 (Controlled)" "Bare 'ship' with L2 trigger stays Level 2"

# ------------------------------------------------------------------------------
# Test 9: Issue #594 - L3 positives (Group 9)
# ------------------------------------------------------------------------------
Write-Host "Test 9: Issue #594 - L3 positives"
$releaseRcOut = Invoke-Route "Ship the v2.0 release candidate"
Assert-Contains $releaseRcOut "Level 3" "'Ship the v2.0 release candidate' -> Level 3"

$cveOut = Invoke-Route "Apply the critical security patch for CVE-2026-1234"
Assert-Contains $cveOut "Level 3" "'Apply the critical security patch for CVE-2026-1234' -> Level 3"

$publicContractOut = Invoke-Route "Roll out the high-impact public API contract change to billing"
Assert-Contains $publicContractOut "Level 3" "'Roll out the high-impact public API contract change to billing' -> Level 3"

# ------------------------------------------------------------------------------
# Test 10: Issue #594 - L2 positives (Group 10)
# ------------------------------------------------------------------------------
Write-Host "Test 10: Issue #594 - L2 positives"
$optionalFieldOut = Invoke-Route "Add an optional field to the public REST response"
Assert-Contains $optionalFieldOut "Level 2" "'Add an optional field to the public REST response' -> Level 2"
Assert-NotContains $optionalFieldOut "Level 3" "Optional REST field is not promoted to Level 3"

$migrateIndexOut = Invoke-Route "Migrate the users table with a new index"
Assert-Contains $migrateIndexOut "Level 2" "'Migrate the users table with a new index' -> Level 2"
Assert-NotContains $migrateIndexOut "Level 3" "Table migration is not promoted to Level 3"

$oauthLoginOut = Invoke-Route "Implement OAuth login"
Assert-Contains $oauthLoginOut "Level 2" "'Implement OAuth login' -> Level 2"
Assert-NotContains $oauthLoginOut "Level 3" "OAuth login is not promoted to Level 3"

# ------------------------------------------------------------------------------
# Test 11: Issue #594 - negatives + vague-word guard (Group 11)
# ------------------------------------------------------------------------------
Write-Host "Test 11: Issue #594 - negatives + vague-word guard"
# #594 forbids promoting a task on vague words alone (important/urgent/major).
# Such wording may set NO floor above Level 1 and must never reach Level 3.
$apiVersioningQOut = Invoke-Route "Explain how our API versioning works"
Assert-Contains $apiVersioningQOut "Level 0" "'Explain how our API versioning works' -> Level 0"

$breakingChangeQOut = Invoke-Route "What is a breaking change?"
Assert-Contains $breakingChangeQOut "Level 0" "'What is a breaking change?' -> Level 0"

$typoApiDocsOut = Invoke-Route "Fix a typo in the API docs"
Assert-Contains $typoApiDocsOut "Level 0" "'Fix a typo in the API docs' -> Level 0"

$vagueUrgentOut = Invoke-Route "This is urgent"
Assert-Contains $vagueUrgentOut "Level 1" "'This is urgent' -> Level 1"
Assert-NotContains $vagueUrgentOut "Level 3" "'urgent' alone never promotes to Level 3"

$vagueImportantOut = Invoke-Route "This is important"
Assert-Contains $vagueImportantOut "Level 1" "'This is important' -> Level 1"
Assert-NotContains $vagueImportantOut "Level 3" "'important' alone never promotes to Level 3"

$vagueMajorOut = Invoke-Route "Major refactor of the parser"
Assert-Contains $vagueMajorOut "Level 1" "'Major refactor of the parser' -> Level 1"
Assert-NotContains $vagueMajorOut "Level 3" "'major' alone never promotes to Level 3"

# ------------------------------------------------------------------------------
# Test 12: Issue #595 - alias coverage + workflow ambiguity (Group 12)
# ------------------------------------------------------------------------------
Write-Host "Test 12: Issue #595 - workflow alias coverage + ambiguity resolution"
Assert-FileExists (Join-Path (Join-Path $repoRoot "workflows") "design-system.md") "Alias target exists: workflows/design-system.md"
Assert-FileExists (Join-Path (Join-Path $repoRoot "workflows") "research.md") "Alias target exists: workflows/research.md"
Assert-FileExists (Join-Path (Join-Path $repoRoot "workflows") "reflect.md") "Alias target exists: workflows/reflect.md"
Assert-FileExists (Join-Path (Join-Path $repoRoot "workflows") "tutor.md") "Alias target exists: workflows/tutor.md"

$tweakSettingsOut = Invoke-Route "tweak the settings"
Assert-Contains $tweakSettingsOut "Recommended Workflow: pk:route" "'tweak the settings' falls back to pk:route"

$checkout500Out = Invoke-Route "the checkout endpoint returns 500"
Assert-Contains $checkout500Out "Recommended Workflow: pk:route" "'the checkout endpoint returns 500' falls back to pk:route"

$failingTestOut = Invoke-Route "review the failing test"
Assert-Contains $failingTestOut "Recommended Workflow: pk:debug" "'review the failing test' resolves to pk:debug (debug beats review)"

$deployAfterTestsOut = Invoke-Route "deploy after the tests pass"
Assert-Contains $deployAfterTestsOut "Recommended Workflow: pk:ship" "'deploy after the tests pass' resolves to pk:ship"

# ------------------------------------------------------------------------------
# Test 13: Issue #594 F-3 regression - action markers vs bare mentions (Group 13)
# ------------------------------------------------------------------------------
Write-Host "Test 13: #594 F-3 regression: action markers vs bare mentions"

# NEGATIVE: a bare topical mention must NOT escalate (was over-classified).
$negTypoSecurityReadmeOut = Invoke-Route "Fix a typo in the security patch README."
Assert-Contains $negTypoSecurityReadmeOut "Level 0" "'Fix a typo in the security patch README.' -> Level 0"
Assert-NotContains $negTypoSecurityReadmeOut "Level 3" "typo in security-patch README is not Level 3"
Assert-NotContains $negTypoSecurityReadmeOut "Level 2" "typo in security-patch README is not Level 2"

$negTellCriticalOut = Invoke-Route "Tell me about critical security patches in general."
Assert-Contains $negTellCriticalOut "Level 1" "'Tell me about critical security patches in general.' -> Level 1"
Assert-NotContains $negTellCriticalOut "Level 3" "general talk about critical security patches is not Level 3"

$negExplainCriticalOut = Invoke-Route "Explain what a critical security patch is."
Assert-Contains $negExplainCriticalOut "Level 0" "'Explain what a critical security patch is.' -> Level 0"
Assert-NotContains $negExplainCriticalOut "Level 3" "definition of a critical security patch is not Level 3"
Assert-NotContains $negExplainCriticalOut "Level 2" "definition of a critical security patch is not Level 2"

$negPublicResponseOut = Invoke-Route "Explain the public response format."
Assert-Contains $negPublicResponseOut "Level 0" "'Explain the public response format.' -> Level 0"
Assert-NotContains $negPublicResponseOut "Level 3" "explaining the public response format is not Level 3"
Assert-NotContains $negPublicResponseOut "Level 2" "explaining the public response format is not Level 2"

# POSITIVE: genuine work on the subject must still escalate (safety floor).
$posFixSecurityPatchOut = Invoke-Route "Fix the security patch for the login module."
Assert-Contains $posFixSecurityPatchOut "Level 3" "'Fix the security patch for the login module.' -> Level 3"

$posBackportOut = Invoke-Route "Backport the critical security fix for the parser."
Assert-Contains $posBackportOut "Level 3" "'Backport the critical security fix for the parser.' -> Level 3"

$posApplyCveOut = Invoke-Route "Apply a critical security patch for CVE-2026-1234."
Assert-Contains $posApplyCveOut "Level 3" "'Apply a critical security patch for CVE-2026-1234.' -> Level 3"

$posHighImpactOut = Invoke-Route "Roll out the high-impact public API contract change to billing"
Assert-Contains $posHighImpactOut "Level 3" "'Roll out the high-impact public API contract change to billing' -> Level 3"

$posPublicRestOut = Invoke-Route "Add an optional field to the public REST response"
Assert-Contains $posPublicRestOut "Level 2" "'Add an optional field to the public REST response' -> Level 2"

# MIXED-INTENT: the new predicate must not under-classify.
$mixedMigrateOut = Invoke-Route "Explain and then migrate the production database."
Assert-Contains $mixedMigrateOut "Level 2" "'Explain and then migrate the production database.' -> Level 2"

$mixedReleaseDeployOut = Invoke-Route "Explain the release process, then deploy."
Assert-Contains $mixedReleaseDeployOut "Level 3" "'Explain the release process, then deploy.' -> Level 3"

# ------------------------------------------------------------------------------
# #594 FP/FN Report
# ------------------------------------------------------------------------------
# Bounded, table-driven classification report over the #594 fixture set only.
# This is NOT a claim of universal correctness over unrestricted input.
#
# Expected defects this batch fixes (must be gone once the router lands):
#   * FP: `What is a breaking change?` was over-classified L2 (want L0)
#   * FN: `Add an optional field to the public REST response` was
#         under-classified L1 (want L2)
#
# Verdict rule (ordinal): observed < expected -> FN, observed > expected -> FP,
# observed == expected -> TP. Any remaining FP or FN fails the suite.
Write-Host ""
Write-Host "=== #594 Classification FP/FN Report ===" -ForegroundColor Cyan

$fpfnFixtures = @(
  "3|Ship the v2.0 release candidate",
  "3|Apply the critical security patch for CVE-2026-1234",
  "3|Roll out the high-impact public API contract change to billing",
  "2|Add an optional field to the public REST response",
  "2|Migrate the users table with a new index",
  "2|Implement OAuth login",
  "0|Explain how our API versioning works",
  "0|What is a breaking change?",
  "0|Fix a typo in the API docs",
  "1|This is urgent",
  "1|This is important",
  "1|Major refactor of the parser"
)

$fpTotal = 0
$fnTotal = 0
foreach ($fpfnRow in $fpfnFixtures) {
  $fpfnParts = $fpfnRow -split '\|', 2
  $expectedLevel = [int]$fpfnParts[0]
  $fpfnPrompt = $fpfnParts[1]
  $fpfnOut = Invoke-Route $fpfnPrompt
  $observedLevel = Get-ExtractedLevel $fpfnOut

  if ($observedLevel -eq "?") {
    $verdict = "FN"
  } elseif ([int]$observedLevel -eq $expectedLevel) {
    $verdict = "TP"
  } elseif ([int]$observedLevel -lt $expectedLevel) {
    $verdict = "FN"
  } else {
    $verdict = "FP"
  }

  switch ($verdict) {
    "TP" { Write-Host ("  [TP] observed L{0} == expected L{1} : {2}" -f $observedLevel, $expectedLevel, $fpfnPrompt) }
    "FP" { $fpTotal++; Write-Host ("  [FP] observed L{0} >  expected L{1} : {2}" -f $observedLevel, $expectedLevel, $fpfnPrompt) }
    "FN" { $fnTotal++; Write-Host ("  [FN] observed L{0} <  expected L{1} : {2}" -f $observedLevel, $expectedLevel, $fpfnPrompt) }
  }
}

Write-Host "  #594 FP total: $fpTotal, FN total: $fnTotal"
if (($fpTotal + $fnTotal) -gt 0) {
  Write-Host "  [FAIL] #594 FP/FN report: $fpTotal false positive(s), $fnTotal false negative(s) remain" -ForegroundColor Red
  $script:failed += ($fpTotal + $fnTotal)
} else {
  Write-Host "  [PASS] #594 FP/FN report: zero false positives, zero false negatives" -ForegroundColor Green
  $script:passed++
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Test Summary: $passed passed, $failed failed ===" -ForegroundColor Cyan
if ($failed -gt 0) {
  exit 1
}

Write-Host "ALL CONTRACT TESTS PASSED WITH 0% UNSAFE UNDERCLASSIFICATIONS." -ForegroundColor Green
exit 0
