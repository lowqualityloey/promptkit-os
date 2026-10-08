<#
.SYNOPSIS
  PromptKit OS Fast Route & Ceremony Classifier (PowerShell 7 Twin)

.DESCRIPTION
  Fully offline and deterministic: the ceremony level (L0-L3) and workflow are
  computed locally from the prompt. There is no network transport, no external
  service, and no credential read.

  Non-negotiable safety floor:
  1. Obvious/hard-risk triggers deterministically override lower recommendations.
  2. Unsafe Underclassification Rate must be 0% across the tested fixture set
     (see scripts/tests/run-pk-route-tests.ps1) — a safety objective measured on
     those fixtures, not a proven property over unrestricted input.
  3. Classification never blocks or fails: routing is always available and
     deterministic, regardless of environment.
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

This router is fully offline and deterministic. It classifies the prompt with
local pattern rules only: no network transport, no external service, and no
credentials. The same prompt always yields the same level and workflow.

Parameters:
  -Prompt <string>     Task or user prompt to classify
  -Offline             Force offline deterministic classification
  -TimeoutSec <int>    Deprecated compatibility no-op; accepted and ignored
  -DryRun              Deprecated compatibility no-op; accepted and ignored
  -Help                Show this help message

Zero-Lock-In Contract:
  Never halts or blocks. Classification is a pure local function of the prompt.
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

function Test-ActionMarkerApplies ([string]$text) {
  # #594 follow-up: a request can be ABOUT an action without BEING one. "Explain how
  # to change the public API" and "What is a high-impact contract change?" are
  # questions, and in both the token "change" is a NOUN, so a bare work-verb scan
  # escalated them to Level 3. An informational frame therefore vetoes the topical
  # markers even when a work verb is present. A coordination marker followed by its
  # own action verb is a genuine second clause and does still escalate
  # ("explain ... then implement it"), so mixed-intent requests keep reaching the
  # hard-risk floor. Release/deploy/publish language is ungated and unaffected.
  #
  # Pattern note: no \b is used anywhere below, so this twin and the Bash original are
  # both plain unanchored substring matches. Bash ERE supports neither \b nor \s, so
  # the Bash twin spells spaces as "\ "; the alternations are otherwise identical.
  if ($text -match '(?i)(what is|what does|how to|how does|explain|describe|tell me about|syntax|lookup|typo|spelling|readme|docs|documentation|changelog|formatting)' `
      -and $text -notmatch '(?i)(then|after that|finally|also|plus|and) (apply|applied|backport|deploy|deploying|ship|shipped|shipping|release|releasing|publish|published|push|upgrade|upgraded|perform|conduct|mitigate|remediate|implement|add|added|create|created|introduce|modify|change|changed|extend|expose|remove|delete|revert|roll out|roll back|update|fix|patch|migrate|write|document|rename|refactor)') {
    return $false
  }

  # Explicit work verbs. fix/patch/update are deliberately ABSENT here because
  # they are verb-ambiguous; they are handled by the rule below.
  if ($text -match '(?i)(apply|applied|applying|backport|deploy|deploying|ship|shipped|shipping|release|releasing|publish|published|push|upgrade|upgraded|perform|conduct|mitigate|remediate|implement|add|added|create|created|introduce|modify|change|changed|extend|expose|return|remove|delete|rename|write|revert|roll out|roll back|need to|required|must|should)') {
    return $true
  }

  # fix/patch/update are accepted only when the security phrase is the DIRECT
  # OBJECT ("fix the security patch"), not when they modify something else
  # ("fix a typo in the security patch README").
  if ($text -match '(?i)(fix|patch|update)s? (a|an|the|this|that|our)? (critical )?security (patch|fix|update|advisory|hotfix)') {
    return $true
  }

  return $false
}

function Test-HardL3 ([string]$text) {
  # Release, deploy, publish, tag candidate, production push (#345: live
  # publication now tolerates ordinary modifiers, e.g. "make the app live",
  # "turn this on for everyone").
  #
  # #594 (F-3) restructures L3 into three tiers:
  #   1. l3_core — the pre-#594 alternations only (release/deploy/publish verbs
  #      and live-publication phrases). Kept UNGATED so the established safety
  #      floor and offline behaviour are untouched.
  #   2. named-CVE — an unconditional CVE identifier check: naming a CVE is work
  #      by definition (workflows/route.md:64 lists critical security updates as
  #      Level 3).
  #   3. action-marker gate — the security-update / high-impact phrases added by
  #      #594 are ACTION markers, not topic keywords, so they escalate only when
  #      Test-ActionMarkerApplies reads the request as work on that subject.
  $corePattern = '(?i)\b(deploy|release|publish|tag\s+candidate|make\s+(this|it|that|everything)(\s+[a-z]+)?\s+(live|public)|make\s+the\s+[a-z]+\s+(live|public)|turn\s+(this|it|that|everything)\s+on|production\s+deploy|hotfix\s+prod|ship\s+release|v\d+\.\d+)'
  if ($text -match $corePattern) {
    return $true
  }

  # Named CVE is unconditionally release-critical.
  if ($text -match '(?i)cve-\d{4}-\d+') {
    return $true
  }

  # Gated #594 additions: security-update and high-impact action markers.
  if (($text -match '(?i)\b(security\s+(patch|fix|update|advisory|hotfix|release)|critical\s+security|high[-\s]impact)\b') -and (Test-ActionMarkerApplies $text)) {
    return $true
  }

  # Bare "ship" (#345): a release verb on its own is release-critical, but when
  # a controlled-change (L2) trigger coexists, the L2 trigger claims the input.
  # This keeps "change the migration and ship it" at Level 2 while
  # "ship the new version to real users" reaches Level 3.
  if ($text -match '(?i)\bship\b') {
    if (Test-HardL2 $text) {
      return $false
    }
    return $true
  }
  return $false
}

function Test-HardL2 ([string]$text) {
  # Schema, migration, alter table, drop, auth, session, jwt, credentials,
  # production database (#345: extended auth vocabulary and API-contract
  # synonyms: login, sign in/sign-in, signup, SSO, password; API response
  # format, API payload, API endpoint, bare endpoint).
  # #594: added public-contract/response synonyms, and qualified the former bare
  # `breaking` term with action context so a definitional mention such as
  # "what is a breaking change?" no longer matches. Canonical L2/L3 mapping:
  # workflows/route.md:89.
  # #594 (F-3): the `public (api|contract|interface|rest|response)` term is now
  # GATED by Test-ActionMarkerApplies: a bare topical mention such as "explain
  # the public response format" must not escalate, so it fires only when the
  # request reads as work on the public contract.
  if (($text -match '(?i)\bpublic\s+(api|contract|interface|rest|response)\b') -and (Test-ActionMarkerApplies $text)) {
    return $true
  }

  $pattern = '(?i)\b(alter\s+table|migration|migrate|drop\s+table|create\s+table|schema|database|production\s+database|auth|login|sign[-\s]?in|signup|sso|password|token|session|jwt|oauth|credentials|secret|api\s+(contract|response\s+format|payload|endpoint)|endpoint|(introduce|introduces|introducing|make|makes|making|create|creates|creating|cause|causes|causing|avoid|avoids|avoiding|ship|ships|shipping|publish|publishes|publishing|release|releases|releasing|update|updates|updating|convert|converts|converting)\s+([a-z]+\s+){0,3}breaking)'
  return ($text -match $pattern)
}

function Test-ObviousL0 ([string]$text) {
  # #594 follow-up: "what does ..." is a conceptual question too (route.md:46), and
  # without it a definitional prompt that also trips an action frame falls to L1.
  $pattern = '(?i)\b(what\s+is|what\s+does|how\s+does|explain|syntax|lookup|typo|fix\s+typo|formatting|format\s+this|where\s+is|where\s+do\s+we)'
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
# 2. Deterministic Offline Router
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
# 3. Routing
# ------------------------------------------------------------------------------

# -Offline forces deterministic routing; the default path routes identically
# because classification is already fully local and deterministic.
if ($Offline) {
  Emit-DeterministicRoute $inputPrompt "Forced offline deterministic routing"
  exit 0
}

Emit-DeterministicRoute $inputPrompt
exit 0
