#!/usr/bin/env bash
# PromptKit OS Directive Token Measurement Utility
# Calculates character, word, and estimated token counts for the injected directive.
set -euo pipefail

# Modes:
#   default  : Measure one directive source (host agent file, explicit target, or the
#              canonical Balanced template fallback) and assert it against the
#              profile-appropriate budget. Backward compatible.
#   --strict : CI gate mode. Ignores host-file detection and asserts BOTH canonical
#              templates: Balanced <= 2,500 tokens AND Lite <= 1,500 tokens.
#              Emits machine-parseable lines: PROFILE|MEASURED|BUDGET|PASS|FAIL
TARGET_FILE=""
STRICT=0
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=1 ;;
        -h|--help) echo "Usage: measure-tokens.sh [--strict] [target-file]"; exit 0 ;;
        *) TARGET_FILE="$arg" ;;
    esac
done

# Single source of truth for budget constants (documented in docs/BENCHMARKS.md section 2).
TOKEN_BUDGET_BALANCED=2500
TOKEN_BUDGET_LITE=1500

if [[ "$STRICT" -eq 1 ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    measure_tokens_of() {
        local file="$1"
        local chars
        chars=$(tr -d '\r' < "$file" | wc -c | tr -d ' ')
        echo $(( (chars + 2) / 4 ))
    }
    echo ""
    echo "📊 PromptKit OS Strict Token Budget Gate (bytes/4 convention)"
    GATE_FAIL=0
    while IFS='|' read -r gate_name gate_path gate_budget; do
        if [[ ! -f "$gate_path" ]]; then
            echo "${gate_name}|MISSING|${gate_budget}|FAIL"
            GATE_FAIL=1
            continue
        fi
        gate_tokens=$(measure_tokens_of "$gate_path")
        if [[ "$gate_tokens" -le "$gate_budget" ]]; then
            echo "${gate_name}|${gate_tokens}|${gate_budget}|PASS"
        else
            echo "${gate_name}|${gate_tokens}|${gate_budget}|FAIL (exceeds budget by $(( gate_tokens - gate_budget )) tokens)"
            GATE_FAIL=1
        fi
    done <<EOF
BALANCED|$SCRIPT_DIR/../templates/agent-directive-template.md|$TOKEN_BUDGET_BALANCED
LITE|$SCRIPT_DIR/../templates/agent-directive-lite-template.md|$TOKEN_BUDGET_LITE
EOF
    if [[ "$GATE_FAIL" -eq 1 ]]; then
        echo ""
        echo "❌ Strict token budget gate FAILED. Budgets: docs/BENCHMARKS.md section 2." >&2
        exit 1
    fi
    echo ""
    echo "✅ Strict token budget gate passed: Balanced <= ${TOKEN_BUDGET_BALANCED}, Lite <= ${TOKEN_BUDGET_LITE}."
    exit 0
fi

echo -e "\n\033[0;36m📊 PromptKit OS Static Directive Token Analysis\033[0m"
echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

CANDIDATES=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    ".cursorrules"
    ".cursor/rules/promptkit.mdc"
    ".windsurfrules"
    ".github/copilot-instructions.md"
    ".clinerules"
)

FOUND_FILE=""
if [[ -n "$TARGET_FILE" && -f "$TARGET_FILE" ]]; then
    FOUND_FILE="$TARGET_FILE"
else
    for cand in "${CANDIDATES[@]}"; do
        if [[ -f "$cand" ]]; then
            FOUND_FILE="$cand"
            break
        fi
    done
fi

BLOCK=""
SOURCE_DESC=""

if [[ -n "$FOUND_FILE" && -f "$FOUND_FILE" ]]; then
    if grep -q "<!-- PROMPTKIT_START -->" "$FOUND_FILE"; then
        BLOCK=$(awk '/^<!-- PROMPTKIT_START -->/{flag=1} flag; /^<!-- PROMPTKIT_END -->/{flag=0}' "$FOUND_FILE")
        SOURCE_DESC="$FOUND_FILE"
    fi
fi

if [[ -z "$BLOCK" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_MD="$SCRIPT_DIR/../templates/agent-directive-template.md"
    if [[ -f "$TEMPLATE_MD" ]]; then
        BLOCK=$(cat "$TEMPLATE_MD")
        SOURCE_DESC="Canonical template in templates/agent-directive-template.md"
    fi
fi

if [[ -z "$BLOCK" ]]; then
    echo "Error: No PromptKit OS directive block found. Run init.sh first or pass a file path." >&2
    exit 1
fi

BLOCK="${BLOCK//$'\r'/}"
LINE_COUNT=$(echo "$BLOCK" | wc -l | tr -d ' ')
CHAR_COUNT=${#BLOCK}
WORD_COUNT=$(echo "$BLOCK" | wc -w | tr -d ' ')
ESTIMATED_TOKENS=$(( (CHAR_COUNT + 2) / 4 ))
MONOLITHIC_TOKENS=18500
SAVINGS_PERCENT=$(( 100 - (ESTIMATED_TOKENS * 100 / MONOLITHIC_TOKENS) ))

echo -e "\033[0;90mTarget File: $FOUND_FILE\033[0m"
echo -e "\n\033[1;33mMeasurement Results:\033[0m"
echo "  • Lines:            $LINE_COUNT"
echo "  • Characters:       $CHAR_COUNT"
echo "  • Words:            $WORD_COUNT"
echo -e "  • Estimated Tokens: \033[0;32m~$ESTIMATED_TOKENS tokens (at ~4 chars/token)\033[0m"

echo -e "\n\033[1;33mToken Economics Comparison:\033[0m"
echo -e "  \033[0;90m┌─────────────────────────────────────────────────────────────┐\033[0m"
echo -e "  \033[0;90m│ Model Architecture                 Static Overhead          │\033[0m"
echo -e "  \033[0;90m├─────────────────────────────────────────────────────────────┤\033[0m"
echo -e "  │ Monolithic Prompt Packs            \033[0;31m~18,500 tokens\033[0m           │"
echo -e "  │ PromptKit OS JIT Router            \033[0;32m~$ESTIMATED_TOKENS tokens (measured)\033[0m      │"
echo -e "  \033[0;90m├─────────────────────────────────────────────────────────────┤\033[0m"
echo -e "  │ Static Context Reduction:          \033[0;36m~$SAVINGS_PERCENT% reduction\033[0m             │"
echo -e "  \033[0;90m└─────────────────────────────────────────────────────────────┘\033[0m"

# Profile-aware budget: the Lite template (and host installs seeded from it) are
# asserted against the Lite budget; everything else against the Balanced budget.
TOKEN_BUDGET="$TOKEN_BUDGET_BALANCED"
BUDGET_PROFILE="Balanced"
if [[ "${FOUND_FILE:-}" == *agent-directive-lite-template.md ]]; then
    TOKEN_BUDGET="$TOKEN_BUDGET_LITE"
    BUDGET_PROFILE="Lite"
fi

echo -e "\n\033[1;33mBudget Assertion Verification:\033[0m"
echo "  • Profile:                $BUDGET_PROFILE"
echo "  • Configured Token Budget:  $TOKEN_BUDGET tokens"
echo "  • Measured Estimate:        $ESTIMATED_TOKENS tokens"

if [ "$ESTIMATED_TOKENS" -le "$TOKEN_BUDGET" ]; then
    echo -e "\n\033[0;32m✅ Verification Passed: Directive ($ESTIMATED_TOKENS tokens) adheres to the <= $TOKEN_BUDGET token budget.\033[0m\n"
else
    echo -e "\n\033[0;31m❌ Verification Failed: Directive ($ESTIMATED_TOKENS tokens) exceeds the $TOKEN_BUDGET token budget by $(( ESTIMATED_TOKENS - TOKEN_BUDGET )) tokens.\033[0m\n" >&2
    exit 1
fi
