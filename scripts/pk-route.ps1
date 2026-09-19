<#
.SYNOPSIS
  PromptKit OS Fast Route & Ceremony Classifier (PowerShell 7 Twin)

.DESCRIPTION
  Powered by TypeSafe AI's Jev (System One) as an evidentiary decision primitive.
  Architectural Axiom: "Jev Recommends, PromptKit Decides."

  Non-negotiable safety floor:
  1. Obvious/hard-risk triggers deterministically override lower recommendations.
  2. Unsafe Underclassification Rate must be 0%.
  3. Missing key, timeout (>2s), or API failure gracefully falls back to offline
     deterministic routing without blocking or failing.
#>

[CmdletBinding()]
param(
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$PromptArgs,

  [Parameter(Mandatory = $false)]
  [string]$Prompt,

  [Parameter(Mandatory = $false)]
  [int]$TimeoutSec = 2,

  [Parameter(Mandatory = $false)]
  [switch]$Offline,

  [Parameter(Mandatory = $false)]
  [switch]$DryRun,

  [Parameter(Mandatory = $false)]
  [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
  @"
Usage: pk-route.ps1 [-Prompt] "YOUR TASK PROMPT" [-TimeoutSec 2] [-Offline] [-DryRun]

Fast PromptKit ceremony level (L0-L3) classifier and workflow router.
Queries TypeSafe AI Jev (System One) with deterministic safety arbitration.

Transport fallback hierarchy (see #343):
  1. AI_GATEWAY_API_KEY -> Vercel AI Gateway evaluation route
  2. TYPESAFE_API_KEY   -> Direct TypeSafe endpoint
  3. Neither set         -> deterministic offline route
  4. Any transport failure (timeout / 4xx / 5xx / malformed)
                         -> deterministic offline route
Transport failure never changes PromptKit's safety policy.

Parameters:
  -Prompt <string>     Task or user prompt to classify
  -TimeoutSec <int>    Maximum API wait time before fallback (default: 2)
  -Offline             Force offline deterministic classification
  -DryRun              Print payload and plan without executing network request
  -Help                Show this help message

Environment:
  $env:AI_GATEWAY_API_KEY  Vercel AI Gateway key (preferred; Jev is Free/free-tier eligible)
  $env:TYPESAFE_API_KEY    TypeSafe direct API key (fallback; offline routing if neither set)
"@
  exit 0
}

# Resolve input prompt
$inputPrompt = if (-not [string]::IsNullOrWhiteSpace($Prompt)) {
  $Prompt
} elseif ($PromptArgs -and $PromptArgs.Count -gt 0) {
  $PromptArgs -join ' '
} else {
  Write-Error "Error: missing prompt input. Run 'scripts/pk-route.ps1 -Help' for usage."
  exit 1
}

# ------------------------------------------------------------------------------
# 1. Deterministic Hard-Trigger & Pattern Classifiers
# ------------------------------------------------------------------------------

function Test-HardL3 ([string]$text) {
  $pattern = '(?i)\b(deploy|release|publish|tag\s+candidate|make\s+this\s+live|production\s+deploy|hotfix\s+prod|ship\s+release|v\d+\.\d+)'
  return ($text -match $pattern)
}

function Test-HardL2 ([string]$text) {
  $pattern = '(?i)\b(alter\s+table|migration|migrate|drop\s+table|create\s+table|schema|database|production\s+database|auth|token|session|jwt|oauth|credentials|secret|api\s+contract|breaking)'
  return ($text -match $pattern)
}

function Test-ObviousL0 ([string]$text) {
  $pattern = '(?i)\b(what\s+is|how\s+does|explain|syntax|lookup|typo|fix\s+typo|formatting|format\s+this|where\s+is|where\s+do\s+we)'
  if ($text -match $pattern) {
    if (-not (Test-HardL2 $text) -and -not (Test-HardL3 $text)) {
      return $true
    }
  }
  return $false
}

function Get-DeterministicWorkflow ([string]$text) {
  if ($text -match '(?i)\b(deploy|release|publish|tag\s+candidate|ship|make\s+this\s+live)') {
    return 'pk:ship'
  } elseif ($text -match '(?i)\b(debug|error|crash|stack\s+trace|failing|regression|exception|investigate)') {
    return 'pk:debug'
  } elseif ($text -match '(?i)\b(test|coverage|assert|fixture|spec\s+test)') {
    return 'pk:test'
  } elseif ($text -match '(?i)\b(review|pr\s+|diff|audit|code\s+smell)') {
    return 'pk:review'
  } elseif ($text -match '(?i)\b(plan|rfc|architect|spec|proposal)') {
    return 'pk:plan'
  } elseif ($text -match '(?i)\b(checkpoint|sync\s+state|compact)') {
    return 'pk:checkpoint'
  } elseif ($text -match '(?i)\b(fix|patch|typo|correct|repair)') {
    return 'pk:fix'
  } else {
    return 'pk:route'
  }
}

# ------------------------------------------------------------------------------
# 2. Deterministic Offline Fallback Router
# ------------------------------------------------------------------------------

function Emit-DeterministicRoute ([string]$text, [string]$reason = "Deterministic offline policy classification") {
  $workflow = Get-DeterministicWorkflow $text

  if (Test-HardL3 $text) {
    Write-Output "[PromptKit OS: Level 3 (Release-Critical) — $reason. Full evaluation required.]"
    Write-Output "Recommended Workflow: $workflow"
  } elseif (Test-HardL2 $text) {
    Write-Output "[PromptKit OS: Level 2 (Controlled) — $reason. Task Record required.]"
    Write-Output "Recommended Workflow: $workflow"
  } elseif (Test-ObviousL0 $text) {
    Write-Output "[PromptKit OS: Level 0 (Direct) — $reason. Zero overhead.]"
    Write-Output "Recommended Workflow: $workflow"
  } else {
    Write-Output "[PromptKit OS: Level 1 (Standard) — $reason. No Task Record required.]"
    Write-Output "Recommended Workflow: $workflow"
  }
}

# ------------------------------------------------------------------------------
# 3. Dry-Run / Offline Handling
# ------------------------------------------------------------------------------

if ($Offline) {
  Emit-DeterministicRoute $inputPrompt "Forced offline deterministic routing"
  exit 0
}

$transport = "none"
$jevUrl = ""
$apiKey = $env:AI_GATEWAY_API_KEY
if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
  $transport = "gateway"
  $jevUrl = "https://ai-gateway.vercel.sh/v4/ai/evaluation-model"
} else {
  $apiKey = $env:TYPESAFE_API_KEY
  if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
    $transport = "direct"
    $jevUrl = "https://api.typesafe.ai/v1/systemone"
  } else {
    # Scenario 1: No credential for any transport
    Emit-DeterministicRoute $inputPrompt "Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY)"
    exit 0
  }
}

if ($DryRun) {
  Write-Output "[DryRun] Would query Jev via $transport at $jevUrl (Timeout: ${TimeoutSec}s)"
  Emit-DeterministicRoute $inputPrompt "Dry-run deterministic projection"
  exit 0
}

# ------------------------------------------------------------------------------
# 4. Jev System One API Call
# ------------------------------------------------------------------------------

$payloadObj = @{
  state = $inputPrompt
  questions = @{
    ceremony = @{
      type = "choice"
      instructions = "Classify this developer task into PromptKit ceremony level (Level 0 Direct, Level 1 Standard, Level 2 Controlled, Level 3 Release-Critical)"
      criteria = @{
        "Level 0 (Direct)" = "Typo, simple syntax query, explanation, formatting tweak. Zero overhead."
        "Level 1 (Standard)" = "Localized bug fix, small self-contained feature, isolated test. Normal unit testing."
        "Level 2 (Controlled)" = "Database migration, schema, auth, API contract, multi-component scope. Task Record required."
        "Level 3 (Release-Critical)" = "Production deployment, release tag, critical security fix, live publication. Full evaluation."
      }
    }
    workflow = @{
      type = "choice"
      instructions = "Select the primary matching PromptKit workflow"
      criteria = @{
        "pk:debug" = "Investigating unexpected errors, regressions, or stack traces"
        "pk:fix" = "Applying a known bug fix or code correction"
        "pk:plan" = "Architectural design, new feature specification"
        "pk:test" = "Adding or modifying test fixtures and suites"
        "pk:review" = "Two-axis code and architecture review"
        "pk:ship" = "Preparing release artifacts or deployment tags"
        "pk:checkpoint" = "Syncing docs/STATE.md or resetting context"
      }
    }
  }
}

$jsonBody = $payloadObj | ConvertTo-Json -Depth 5 -Compress

$headers = @{
  "Authorization" = "Bearer $apiKey"
  "Content-Type"  = "application/json"
}
# Gateway transport (see #343) requires the evaluation-protocol headers.
if ($transport -eq "gateway") {
  $headers["ai-gateway-protocol-version"] = "0.0.1"
  $headers["ai-gateway-auth-method"] = "api-key"
  $headers["ai-evaluation-model-specification-version"] = "4"
  $headers["ai-model-id"] = "typesafe-ai/jev"
}

$response = $null
try {
  $response = Invoke-RestMethod -Uri $jevUrl `
    -Method Post `
    -Headers $headers `
    -Body $jsonBody `
    -TimeoutSec $TimeoutSec `
    -ErrorAction Stop
} catch {
  # Scenario 3: Jev unavailable / timeout
  [Console]::Error.WriteLine("[pk-route] Warning: Jev API request failed or timed out (${TimeoutSec}s). Falling back to deterministic routing.")
  Emit-DeterministicRoute $inputPrompt "Deterministic offline fallback (API timeout/unreachable)"
  exit 0
}

# ------------------------------------------------------------------------------
# 5. Response Parsing & Validation (Scenario 5: Malformed Output Rejection)
# ------------------------------------------------------------------------------

$jevLevel = $null
$jevWorkflow = $null

try {
  if ($response -and $response.answers) {
    if ($response.answers.ceremony -and $response.answers.ceremony.choice) {
      $jevLevel = [string]$response.answers.ceremony.choice
    }
    if ($response.answers.workflow -and $response.answers.workflow.choice) {
      $jevWorkflow = [string]$response.answers.workflow.choice
    }
  }
} catch {
  $jevLevel = $null
}

if ([string]::IsNullOrWhiteSpace($jevLevel)) {
  # Scenario 5: Malformed response
  [Console]::Error.WriteLine("[pk-route] Warning: Failed to parse valid ceremony choice from Jev response. Falling back to deterministic routing.")
  Emit-DeterministicRoute $inputPrompt "Deterministic offline fallback (Malformed Jev schema)"
  exit 0
}

if ([string]::IsNullOrWhiteSpace($jevWorkflow)) {
  $jevWorkflow = Get-DeterministicWorkflow $inputPrompt
}

# ------------------------------------------------------------------------------
# 6. PromptKit Policy Arbitrator (Scenario 4: Hard Safety Floor Override)
# ------------------------------------------------------------------------------

$finalLevel = $jevLevel
$justification = "Jev System One recommendation"

# Enforce deterministic hard safety floor (0% Unsafe Underclassifications)
if (Test-HardL3 $inputPrompt) {
  if ($jevLevel -notmatch 'Level 3') {
    $finalLevel = "Level 3 (Release-Critical)"
    $justification = "Hard safety floor override: release/deployment trigger detected"
  }
} elseif (Test-HardL2 $inputPrompt) {
  if ($jevLevel -match 'Level 0' -or $jevLevel -match 'Level 1') {
    $finalLevel = "Level 2 (Controlled)"
    $justification = "Hard safety floor override: schema/auth/state trigger detected"
  }
}

# Format output banner
switch -Regex ($finalLevel) {
  'Level 0' {
    Write-Output "[PromptKit OS: Level 0 (Direct) — $justification. Zero overhead.]"
  }
  'Level 1' {
    Write-Output "[PromptKit OS: Level 1 (Standard) — $justification. No Task Record required.]"
  }
  'Level 2' {
    Write-Output "[PromptKit OS: Level 2 (Controlled) — $justification. Task Record required.]"
  }
  'Level 3' {
    Write-Output "[PromptKit OS: Level 3 (Release-Critical) — $justification. Full evaluation required.]"
  }
  default {
    Emit-DeterministicRoute $inputPrompt "Fallback: unexpected level output"
    exit 0
  }
}

Write-Output "Recommended Workflow: $jevWorkflow"
exit 0
