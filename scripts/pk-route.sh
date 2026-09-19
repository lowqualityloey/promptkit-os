#!/usr/bin/env bash
# ==============================================================================
# scripts/pk-route.sh — PromptKit OS Fast Route & Ceremony Classifier
#
# Powered by TypeSafe AI's Jev (System One) as an evidentiary decision primitive.
# Architectural Axiom: "Jev Recommends, PromptKit Decides."
#
# Non-negotiable safety floor:
# 1. Obvious/hard-risk triggers deterministically override lower recommendations.
# 2. Unsafe Underclassification Rate must be 0%.
# 3. Missing key, timeout (>2s), or API failure gracefully falls back to offline
#    deterministic routing without blocking or failing.
# ==============================================================================

set -euo pipefail

TIMEOUT_SEC=2
DRY_RUN=0
OFFLINE=0
PROMPT_INPUT=""

print_help() {
  cat << 'EOF'
Usage: pk-route.sh [OPTIONS] "YOUR TASK PROMPT"

Fast PromptKit ceremony level (L0-L3) classifier and workflow router.
Queries TypeSafe AI Jev (System One) with deterministic safety arbitration.

Transport fallback hierarchy (see #343):
  1. AI_GATEWAY_API_KEY -> Vercel AI Gateway evaluation route
  2. TYPESAFE_API_KEY   -> Direct TypeSafe endpoint
  3. Neither set         -> deterministic offline route
  4. Any transport failure (timeout / 4xx / 5xx / malformed)
                         -> deterministic offline route
Transport failure never changes PromptKit's safety policy.

Options:
  --prompt <text>     Task or user prompt to classify
  --timeout <sec>     Maximum API wait time before fallback (default: 2)
  --offline           Force offline deterministic classification
  --dry-run           Print payload and plan without executing network request
  --help, -h          Show this help message

Environment:
  AI_GATEWAY_API_KEY  Vercel AI Gateway key (preferred; Jev is Free/free-tier eligible)
  TYPESAFE_API_KEY    TypeSafe direct API key (fallback; offline routing if neither set)

Zero-Lock-In Contract:
  Never halts or blocks. If the API is unreachable, times out, or fails,
  PromptKit policy immediately falls back to deterministic offline routing.
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
      TIMEOUT_SEC="$2"
      shift 2
      ;;
    --offline)
      OFFLINE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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

detect_hard_l3() {
  local input_lower
  input_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  
  # Release, deploy, publish, tag candidate, make this live, production push
  if [[ "$input_lower" =~ (deploy|release|publish|tag\ candidate|make\ this\ live|production\ deploy|hotfix\ prod|ship\ release|v[0-9]+\.[0-9]+) ]]; then
    return 0
  fi
  return 1
}

detect_hard_l2() {
  local input_lower
  input_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  
  # Schema, migration, alter table, drop, auth, session, jwt, credentials, production database
  if [[ "$input_lower" =~ (alter\ table|migration|migrate|drop\ table|create\ table|schema|database|production\ database|auth|token|session|jwt|oauth|credentials|secret|api\ contract|breaking) ]]; then
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
# 2. Deterministic Offline Fallback Router
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
# 3. Dry-Run / Offline Handling
# ------------------------------------------------------------------------------

if [[ "$OFFLINE" -eq 1 ]]; then
  emit_deterministic_route "$PROMPT_INPUT" "Forced offline deterministic routing"
  exit 0
fi

if [[ -n "${AI_GATEWAY_API_KEY:-}" ]]; then
  JEV_TRANSPORT="gateway"
  JEV_URL="https://ai-gateway.vercel.sh/v4/ai/evaluation-model"
  JEV_KEY="$AI_GATEWAY_API_KEY"
elif [[ -n "${TYPESAFE_API_KEY:-}" ]]; then
  JEV_TRANSPORT="direct"
  JEV_URL="https://api.typesafe.ai/v1/systemone"
  JEV_KEY="$TYPESAFE_API_KEY"
else
  # Scenario 1: No credential for any transport
  emit_deterministic_route "$PROMPT_INPUT" "Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY)"
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[DryRun] Would query Jev via $JEV_TRANSPORT at $JEV_URL (Timeout: ${TIMEOUT_SEC}s)"
  emit_deterministic_route "$PROMPT_INPUT" "Dry-run deterministic projection"
  exit 0
fi

# ------------------------------------------------------------------------------
# 4. Jev System One API Call
# ------------------------------------------------------------------------------

# Escape JSON string safely
escape_json() {
  local string="$1"
  string="${string//\\/\\\\}"
  string="${string//\"/\\\"}"
  string="${string//$'\n'/\\n}"
  string="${string//$'\r'/\\r}"
  string="${string//$'\t'/\\t}"
  echo "$string"
}

ESCAPED_PROMPT=$(escape_json "$PROMPT_INPUT")

PAYLOAD=$(cat <<EOF
{
  "state": "$ESCAPED_PROMPT",
  "questions": {
    "ceremony": {
      "type": "choice",
      "instructions": "Classify this developer task into PromptKit ceremony level (Level 0 Direct, Level 1 Standard, Level 2 Controlled, Level 3 Release-Critical)",
      "criteria": {
        "Level 0 (Direct)": "Typo, simple syntax query, explanation, formatting tweak. Zero overhead.",
        "Level 1 (Standard)": "Localized bug fix, small self-contained feature, isolated test. Normal unit testing.",
        "Level 2 (Controlled)": "Database migration, schema, auth, API contract, multi-component scope. Task Record required.",
        "Level 3 (Release-Critical)": "Production deployment, release tag, critical security fix, live publication. Full evaluation."
      }
    },
    "workflow": {
      "type": "choice",
      "instructions": "Select the primary matching PromptKit workflow",
      "criteria": {
        "pk:debug": "Investigating unexpected errors, regressions, or stack traces",
        "pk:fix": "Applying a known bug fix or code correction",
        "pk:plan": "Architectural design, new feature specification",
        "pk:test": "Adding or modifying test fixtures and suites",
        "pk:review": "Two-axis code and architecture review",
        "pk:ship": "Preparing release artifacts or deployment tags",
        "pk:checkpoint": "Syncing docs/STATE.md or resetting context"
      }
    }
  }
}
EOF
)

# Execute API call with strict timeout.
# Gateway transport (see #343) requires the evaluation-protocol headers;
# direct transport uses plain auth. Fail-open: any failure falls through
# to deterministic routing below — transport never changes safety policy.
CURL_OUTPUT=""
HTTP_STATUS=0
CURL_EXIT=0
CURL_ARGS=(
  -sS --max-time "$TIMEOUT_SEC"
  -H "Authorization: Bearer $JEV_KEY"
  -H "Content-Type: application/json"
)
if [[ "$JEV_TRANSPORT" == "gateway" ]]; then
  CURL_ARGS+=(
    -H "ai-gateway-protocol-version: 0.0.1"
    -H "ai-gateway-auth-method: api-key"
    -H "ai-evaluation-model-specification-version: 4"
    -H "ai-model-id: typesafe-ai/jev"
  )
fi

if ! CURL_OUTPUT=$(curl "${CURL_ARGS[@]}" \
  -w "\n%{http_code}" \
  -d "$PAYLOAD" \
  "$JEV_URL" 2>&1); then
  CURL_EXIT=$?
fi

if [[ $CURL_EXIT -ne 0 ]]; then
  # Scenario 3: Jev unavailable / timeout
  echo "[pk-route] Warning: Jev API request failed or timed out (${TIMEOUT_SEC}s). Falling back to deterministic routing." >&2
  emit_deterministic_route "$PROMPT_INPUT" "Deterministic offline fallback (API timeout/unreachable)"
  exit 0
fi

# Extract HTTP status code from last line
HTTP_STATUS=$(echo "$CURL_OUTPUT" | tail -n 1)
RESPONSE_BODY=$(echo "$CURL_OUTPUT" | sed '$d')

if [[ "$HTTP_STATUS" -ne 200 ]]; then
  # Scenario 3: HTTP Error (4xx/5xx)
  echo "[pk-route] Warning: Jev API returned HTTP $HTTP_STATUS. Falling back to deterministic routing." >&2
  emit_deterministic_route "$PROMPT_INPUT" "Deterministic offline fallback (API HTTP $HTTP_STATUS)"
  exit 0
fi

# ------------------------------------------------------------------------------
# 5. Response Parsing & Validation (Scenario 5: Malformed Output Rejection)
# ------------------------------------------------------------------------------

JEV_LEVEL=""
JEV_WORKFLOW=""

# Attempt extraction using python or awk/grep
if command -v python3 >/dev/null 2>&1; then
  JEV_LEVEL=$(python3 -c "
import sys, json
try:
  data = json.loads(sys.stdin.read())
  print(data['answers']['ceremony']['choice'])
except Exception:
  pass
" <<< "$RESPONSE_BODY" 2>/dev/null || true)

  JEV_WORKFLOW=$(python3 -c "
import sys, json
try:
  data = json.loads(sys.stdin.read())
  print(data['answers']['workflow']['choice'])
except Exception:
  pass
" <<< "$RESPONSE_BODY" 2>/dev/null || true)
elif command -v jq >/dev/null 2>&1; then
  JEV_LEVEL=$(echo "$RESPONSE_BODY" | jq -r '.answers.ceremony.choice // empty' 2>/dev/null || true)
  JEV_WORKFLOW=$(echo "$RESPONSE_BODY" | jq -r '.answers.workflow.choice // empty' 2>/dev/null || true)
else
  # Minimal fallback regex extraction
  JEV_LEVEL=$(echo "$RESPONSE_BODY" | grep -o '"choice":[ ]*"Level [0-3] [^"]*"' | head -n 1 | cut -d'"' -f4 || true)
  JEV_WORKFLOW=$(echo "$RESPONSE_BODY" | grep -o '"choice":[ ]*"pk:[^"]*"' | head -n 1 | cut -d'"' -f4 || true)
fi

if [[ -z "$JEV_LEVEL" ]]; then
  # Scenario 5: Malformed response
  echo "[pk-route] Warning: Failed to parse valid ceremony choice from Jev response. Falling back to deterministic routing." >&2
  emit_deterministic_route "$PROMPT_INPUT" "Deterministic offline fallback (Malformed Jev schema)"
  exit 0
fi

if [[ -z "$JEV_WORKFLOW" ]]; then
  JEV_WORKFLOW=$(detect_workflow "$PROMPT_INPUT")
fi

# ------------------------------------------------------------------------------
# 6. PromptKit Policy Arbitrator (Scenario 4: Hard Safety Floor Override)
# ------------------------------------------------------------------------------

FINAL_LEVEL="$JEV_LEVEL"
JUSTIFICATION="Jev System One recommendation"

# Enforce deterministic hard safety floor (0% Unsafe Underclassifications)
if detect_hard_l3 "$PROMPT_INPUT"; then
  if [[ "$JEV_LEVEL" != *"Level 3"* ]]; then
    FINAL_LEVEL="Level 3 (Release-Critical)"
    JUSTIFICATION="Hard safety floor override: release/deployment trigger detected"
  fi
elif detect_hard_l2 "$PROMPT_INPUT"; then
  if [[ "$JEV_LEVEL" == *"Level 0"* || "$JEV_LEVEL" == *"Level 1"* ]]; then
    FINAL_LEVEL="Level 2 (Controlled)"
    JUSTIFICATION="Hard safety floor override: schema/auth/state trigger detected"
  fi
fi

# Format output banner
case "$FINAL_LEVEL" in
  *"Level 0"*)
    echo "[PromptKit OS: Level 0 (Direct) — ${JUSTIFICATION}. Zero overhead.]"
    ;;
  *"Level 1"*)
    echo "[PromptKit OS: Level 1 (Standard) — ${JUSTIFICATION}. No Task Record required.]"
    ;;
  *"Level 2"*)
    echo "[PromptKit OS: Level 2 (Controlled) — ${JUSTIFICATION}. Task Record required.]"
    ;;
  *"Level 3"*)
    echo "[PromptKit OS: Level 3 (Release-Critical) — ${JUSTIFICATION}. Full evaluation required.]"
    ;;
  *)
    # Unknown level string fallback
    emit_deterministic_route "$PROMPT_INPUT" "Fallback: unexpected level output"
    exit 0
    ;;
esac

echo "Recommended Workflow: ${JEV_WORKFLOW}"
exit 0
