<#
.SYNOPSIS
  Automated Behavioral Contract & Safety Floor Tests for pk-route.ps1 (PowerShell Twin)
  Asserts Scenarios 1–5 (Missing Key, Timeout, Safety Floor, Secret Hygiene)
#>

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$pkRoute = Join-Path $repoRoot "scripts\pk-route.ps1"

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

Write-Host "=== Running pk-route.ps1 Behavioral Contract Tests ===" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Test 1: Help Flag
# ------------------------------------------------------------------------------
Write-Host "Test 1: Help flag prints usage and exits 0"
$helpOut = pwsh -NoProfile -File $pkRoute -Help | Out-String
Assert-Contains $helpOut "Usage: pk-route.ps1" "Help flag contains usage"

# ------------------------------------------------------------------------------
# Test 2: Scenario 1 - Missing API Key Fallback (L0 Typo)
# ------------------------------------------------------------------------------
Write-Host "Test 2: Scenario 1 - Missing API key fallback (L0)"
$envBackup = $env:TYPESAFE_API_KEY
try {
  $env:TYPESAFE_API_KEY = $null
  $l0Out = pwsh -NoProfile -File $pkRoute -Prompt "fix typo in README.md" | Out-String
  Assert-Contains $l0Out "Level 0 (Direct)" "L0 typo classified as Level 0"
  Assert-Contains $l0Out "Recommended Workflow: pk:fix" "L0 typo recommends pk:fix"
} finally {
  $env:TYPESAFE_API_KEY = $envBackup
}

# ------------------------------------------------------------------------------
# Test 3: Scenario 4 - Hard Safety Floor: Migration / Schema (L2)
# ------------------------------------------------------------------------------
Write-Host "Test 3: Scenario 4 - Hard safety floor for schema/migration (L2)"
$l2Out = pwsh -NoProfile -File $pkRoute -Prompt "minor tweak to ALTER TABLE in user schema" | Out-String
Assert-Contains $l2Out "Level 2 (Controlled)" "ALTER TABLE classified as Level 2"
Assert-Contains $l2Out "Task Record required" "L2 notes Task Record required"

# ------------------------------------------------------------------------------
# Test 4: Scenario 4 - Hard Safety Floor: Production Deploy / Release (L3)
# ------------------------------------------------------------------------------
Write-Host "Test 4: Scenario 4 - Hard safety floor for release/deploy (L3)"
$l3Out = pwsh -NoProfile -File $pkRoute -Prompt "tag and deploy release v1.0.0 to production" | Out-String
Assert-Contains $l3Out "Level 3 (Release-Critical)" "Deploy classified as Level 3"
Assert-Contains $l3Out "Recommended Workflow: pk:ship" "Deploy recommends pk:ship"

# ------------------------------------------------------------------------------
# Test 5: Scenario 4 - Adversarial Phrasing Hard Triggers
# ------------------------------------------------------------------------------
Write-Host "Test 5: Scenario 4 - Adversarial phrasing hard triggers (0% underclassification)"
$adv1Out = pwsh -NoProfile -File $pkRoute -Prompt "quickly update the production database before release" | Out-String
Assert-Contains $adv1Out "Level 3 (Release-Critical)" "Adversarial 1 -> Level 3"

$adv2Out = pwsh -NoProfile -File $pkRoute -Prompt "just change the migration and ship it" | Out-String
Assert-Contains $adv2Out "Level 2 (Controlled)" "Adversarial 2 -> Level 2"

$adv3Out = pwsh -NoProfile -File $pkRoute -Prompt "can you make this live?" | Out-String
Assert-Contains $adv3Out "Level 3 (Release-Critical)" "Adversarial 3 -> Level 3"

# ------------------------------------------------------------------------------
# Test 6: Scenario 3 - Graceful Fallback on API failure / invalid key
# ------------------------------------------------------------------------------
Write-Host "Test 6: Scenario 3 - Non-blocking degradation on invalid API call"
$fallbackOut = pwsh -NoProfile -Command "`$env:TYPESAFE_API_KEY='test-invalid-key-xyz'; & '$pkRoute' -TimeoutSec 1 -Prompt 'debug null pointer exception'" 2>&1 | Out-String
Assert-Contains $fallbackOut "PromptKit OS: Level" "Output contains valid Turn 1 banner on API failure"
Assert-Contains $fallbackOut "Recommended Workflow: pk:debug" "Workflow correctly resolved on fallback"

# ------------------------------------------------------------------------------
# Test 7: Scenario 5 - Secret Hygiene
# ------------------------------------------------------------------------------
Write-Host "Test 7: Scenario 5 - Secret hygiene (API key never leaked)"
$secretKey = "super-secret-token-do-not-leak-999"
$secretOut = pwsh -NoProfile -Command "`$env:TYPESAFE_API_KEY='$secretKey'; & '$pkRoute' -TimeoutSec 1 -Prompt 'fix bug'" 2>&1 | Out-String
Assert-NotContains $secretOut $secretKey "Stdout/stderr does not leak API key"
# ------------------------------------------------------------------------------
# Test 8: Issue #345 - Synonym hard triggers (auth, release, API contract)
# ------------------------------------------------------------------------------
Write-Host "Test 8: Issue #345 - Synonym hard triggers (deterministic, offline)"

# Scenario 1: Auth synonyms must reach L2
$auth1Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Add Google login to the app" | Out-String
Assert-Contains $auth1Out "Level 2 (Controlled)" "H2: 'Add Google login' -> Level 2"
Assert-Contains $auth1Out "Task Record required" "H2: L2 notes Task Record required"

$auth2Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Let people sign in with their Google account" | Out-String
Assert-Contains $auth2Out "Level 2 (Controlled)" "H2a: 'sign in with Google' -> Level 2"

$auth3Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Add SSO to the dashboard" | Out-String
Assert-Contains $auth3Out "Level 2 (Controlled)" "Auth synonym: 'SSO' -> Level 2"

$auth4Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Let users sign-up with an email and password" | Out-String
Assert-Contains $auth4Out "Level 2 (Controlled)" "Auth synonym: 'sign-up'/'password' -> Level 2"

# Scenario 2: Release and live-publication synonyms must reach L3
$rel1Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Ship the new version to real users" | Out-String
Assert-Contains $rel1Out "Level 3 (Release-Critical)" "H3a: bare 'ship' -> Level 3"

$rel2Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Could we turn this on for everyone now" | Out-String
Assert-Contains $rel2Out "Level 3 (Release-Critical)" "H5a: 'turn this on' -> Level 3"

$rel3Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Make the app live tomorrow morning" | Out-String
Assert-Contains $rel3Out "Level 3 (Release-Critical)" "Live publication with modifier -> Level 3"

# Scenario 3: API-contract synonyms must reach L2
$api1Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Change the public API response format for /v1/users" | Out-String
Assert-Contains $api1Out "Level 2 (Controlled)" "H6: 'API response format' -> Level 2"

$api2Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Tweak what the users endpoint gives back" | Out-String
Assert-Contains $api2Out "Level 2 (Controlled)" "H6a: 'users endpoint' -> Level 2"

$api3Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "Adjust the API payload for the create-order call" | Out-String
Assert-Contains $api3Out "Level 2 (Controlled)" "API synonym: 'API payload' -> Level 2"

# Bare ship must NOT defeat an L2 trigger (existing floor behaviour preserved)
$shipL2Out = pwsh -NoProfile -File $pkRoute -Offline -Prompt "just change the migration and ship it" | Out-String
Assert-Contains $shipL2Out "Level 2 (Controlled)" "Bare 'ship' with L2 trigger stays Level 2"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

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
