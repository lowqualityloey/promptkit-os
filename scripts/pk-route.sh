#!/usr/bin/env bash
# ==============================================================================
# scripts/pk-route.sh — PromptKit OS Fast Route & Ceremony Classifier
#
# Fully offline and deterministic: the ceremony level (L0-L3) and workflow are
# computed locally from the prompt. There is no network transport, no external
# service, and no credential read.
#
# Non-negotiable safety floor:
# 1. Obvious/hard-risk triggers deterministically override lower recommendations.
# 2. Unsafe Underclassification Rate must be 0% across the tested fixture set
#    (see scripts/tests/run-pk-route-tests.sh) — a safety objective measured on
#    those fixtures, not a proven property over unrestricted input.
# 3. Classification never blocks or fails: routing is always available and
#    deterministic, regardless of environment.
# ==============================================================================

set -euo pipefail

OFFLINE=0
PROMPT_INPUT=""

print_help() {
  cat << 'EOF'
Usage: pk-route.sh [OPTIONS] "YOUR TASK PROMPT"

Fast PromptKit ceremony level (L0-L3) classifier and workflow router.

This router is fully offline and deterministic. It classifies the prompt with
local pattern rules only: no network transport, no external service, and no
credentials. The same prompt always yields the same level and workflow.

Options:
  --prompt <text>     Task or user prompt to classify
  --offline           Force offline deterministic classification
  --timeout <sec>     Deprecated compatibility no-op; accepted and ignored
  --dry-run           Deprecated compatibility no-op; accepted and ignored
  --help, -h          Show this help message

Zero-Lock-In Contract:
  Never halts or blocks. Classification is a pure local function of the prompt.
EOF
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      print_help
      exit 0
      ;;
    --prompt)
      PROMPT_INPUT="$2"
      shift 2
      ;;
    --timeout)
      # Accepted for backward compatibility; ignored (there is no transport).
      shift 2
      ;;
    --offline)
      OFFLINE=1
      shift
      ;;
    --dry-run)
      # Accepted for backward compatibility; ignored (there is no request).
      shift
      ;;
    *)
      if [[ -z "$PROMPT_INPUT" ]]; then
        PROMPT_INPUT="$1"
      else
        PROMPT_INPUT="$PROMPT_INPUT $1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROMPT_INPUT" ]]; then
  echo "Error: missing prompt input." >&2
  echo "Run 'scripts/pk-route.sh --help' for usage." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# 1. Deterministic Hard-Trigger & Pattern Classifiers
# ------------------------------------------------------------------------------

# #594 (F-3): the security / high-impact / public-contract terms added by this
# batch are ACTION markers, not topic keywords. A bare mention must not escalate:
# "explain what a critical security patch is" is a question, and "fix a typo in
# the security patch README" is a documentation edit. They escalate only when the
# request reads as work on that subject. A named CVE stays unconditional
# (workflows/route.md:64 lists critical security updates as Level 3).
action_marker_applies() {
  local t="$1"

  # Explicit work verbs. fix/patch/update are deliberately ABSENT here because
  # they are verb-ambiguous; they are handled by the rule below.
  if [[ "$t" =~ (apply|applied|applying|backport|deploy|deploying|ship|shipped|shipping|release|releasing|publish|published|push|upgrade|upgraded|perform|conduct|mitigate|remediate|implement|add|added|create|created|introduce|modify|change|changed|extend|expose|return|remove|delete|need\ to|required|must|should|roll\ out) ]]; then
    return 0
  fi

  # fix/patch/update are accepted only when the security phrase is the DIRECT
  # OBJECT ("fix the security patch"), not when they modify something else
  # ("fix a typo in the security patch README").
  if [[ "$t" =~ (fix|patch|update)s?\ (a|an|the|this|that|our)?\ (critical\ )?security\ (patch|fix|update|advisory|hotfix) ]]; then
    return 0
  fi

  # Conceptual question or documentation edit: never escalate on a topic keyword.
  if [[ "$t" =~ (what\ is|how\ does|explain|describe|tell\ me\ about|syntax|lookup|typo|spelling|rename|readme|doc|changelog|formatting) ]]; then
    return 1
  fi

  return 1
}

detect_hard_l3() {
  local input_lower
  input_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

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
  #      action_marker_applies() reads the request as work on that subject.
  local l3_core='(deploy|release|publish|tag candidate|make (this|it|that|everything)( [a-z]+)? (live|public)|make the [a-z]+ (live|public)|turn (this|it|that|everything) on|production deploy|hotfix prod|ship release|v[0-9]+\.[0-9]+)'
  if [[ "$input_lower" =~ $l3_core ]]; then
    return 0
  fi

  # Named CVE is unconditionally release-critical.
  if [[ "$input_lower" =~ cve-[0-9]{4}-[0-9]+ ]]; then
    return 0
  fi

  # Gated #594 additions: security-update and high-impact action markers.
  if [[ "$input_lower" =~ (security\ (patch|fix|update|advisory|hotfix|release)|critical\ security|high[ -]impact) ]] \
     && action_marker_applies "$input_lower"; then
    return 0
  fi

  # Bare "ship" (#345): a release verb on its own is release-critical, but when
  # a controlled-change (L2) trigger coexists, the L2 trigger claims the input.
  # This keeps "change the migration and ship it" at Level 2 while
  # "ship the new version to real users" reaches Level 3.
  local ship_re='\bship\b'
  if [[ "$input_lower" =~ $ship_re ]]; then
    if detect_hard_l2 "$input_lower"; then
      return 1
    fi
    return 0
  fi
  return 1
}

detect_hard_l2() {
  local input_lower
  input_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

  # Schema, migration, alter table, drop, auth, session, jwt, credentials,
  # production database (#345: extended auth vocabulary and API-contract
  # synonyms: login, sign in/sign-in, signup, SSO, password; API response
  # format, API payload, API endpoint, bare endpoint).
  # #594: added public-contract/response synonyms, and qualified the former bare
  # `breaking` term with action context so a definitional mention such as
  # "what is a breaking change?" no longer matches. Canonical L2/L3 mapping:
  # workflows/route.md:89.
  # #594 (F-3): the `public (api|contract|interface|rest|response)` term is now
  # GATED by action_marker_applies(): a bare topical mention such as "explain
  # the public response format" must not escalate, so it fires only when the
  # request reads as work on the public contract.
  if [[ "$input_lower" =~ public\ (api|contract|interface|rest|response) ]] \
     && action_marker_applies "$input_lower"; then
    return 0
  fi

  if [[ "$input_lower" =~ (alter\ table|migration|migrate|drop\ table|create\ table|schema|database|production\ database|auth|login|sign[-\ ]?in|signup|sso|password|token|session|jwt|oauth|credentials|secret|api\ (contract|response\ format|payload|endpoint)|endpoint|(introduce|introduces|introducing|make|makes|making|create|creates|creating|cause|causes|causing|avoid|avoids|avoiding|ship|ships|shipping|publish|publishes|publishing|release|releases|releasing|update|updates|updating|convert|converts|converting)\ ([a-z]+\ ){0,3}breaking) ]]; then
    return 0
  fi
  return 1
}

detect_obvious_l0() {
  local input_lower
  input_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  
  # Conceptual question, syntax lookup, typo fix, formatting
  if [[ "$input_lower" =~ (what\ is|how\ does|explain|syntax|lookup|typo|fix\ typo|formatting|format\ this|where\ is|where\ do\ we) ]]; then
    if ! detect_hard_l2 "$input_lower" && ! detect_hard_l3 "$input_lower"; then
      return 0
    fi
  fi
  return 1
}

detect_workflow() {
  local input_lower
  input_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  
  if [[ "$input_lower" =~ (deploy|release|publish|tag\ candidate|ship|make\ this\ live) ]]; then
    echo "pk:ship"
  elif [[ "$input_lower" =~ (debug|error|crash|stack\ trace|failing|regression|exception|investigate) ]]; then
    echo "pk:debug"
  elif [[ "$input_lower" =~ (test|coverage|assert|fixture|spec\ test) ]]; then
    echo "pk:test"
  elif [[ "$input_lower" =~ (review|pr\ |diff|audit|code\ smell) ]]; then
    echo "pk:review"
  elif [[ "$input_lower" =~ (plan|rfc|architect|spec|proposal) ]]; then
    echo "pk:plan"
  elif [[ "$input_lower" =~ (checkpoint|sync\ state|compact) ]]; then
    echo "pk:checkpoint"
  elif [[ "$input_lower" =~ (fix|patch|typo|correct|repair) ]]; then
    echo "pk:fix"
  else
    echo "pk:route"
  fi
}

# ------------------------------------------------------------------------------
# 2. Deterministic Offline Router
# ------------------------------------------------------------------------------

emit_deterministic_route() {
  local prompt="$1"
  local reason_suffix="${2:-Deterministic offline policy classification}"
  local workflow
  workflow=$(detect_workflow "$prompt")

  if detect_hard_l3 "$prompt"; then
    echo "[PromptKit OS: Level 3 (Release-Critical) — ${reason_suffix}. Full evaluation required.]"
    echo "Recommended Workflow: ${workflow}"
  elif detect_hard_l2 "$prompt"; then
    echo "[PromptKit OS: Level 2 (Controlled) — ${reason_suffix}. Task Record required.]"
    echo "Recommended Workflow: ${workflow}"
  elif detect_obvious_l0 "$prompt"; then
    echo "[PromptKit OS: Level 0 (Direct) — ${reason_suffix}. Zero overhead.]"
    echo "Recommended Workflow: ${workflow}"
  else
    echo "[PromptKit OS: Level 1 (Standard) — ${reason_suffix}. No Task Record required.]"
    echo "Recommended Workflow: ${workflow}"
  fi
}

# ------------------------------------------------------------------------------
# 3. Routing
# ------------------------------------------------------------------------------

# --offline forces deterministic routing; the default path routes identically
# because classification is already fully local and deterministic.
if [[ "$OFFLINE" -eq 1 ]]; then
  emit_deterministic_route "$PROMPT_INPUT" "Forced offline deterministic routing"
  exit 0
fi

emit_deterministic_route "$PROMPT_INPUT"
exit 0
