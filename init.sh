#!/usr/bin/env bash
# PromptKit OS 1-Click Setup Script for Linux/macOS
# Supports profiles: --lite, --balanced (default), --turbo --experimental
# Includes interactive TTY picker when no flag provided (visual decision)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_NAME="$(basename "$SCRIPT_DIR")"

# Default profile
PROFILE="balanced"
PROFILE_SET=0
EXPERIMENTAL=0
PROJECT_ROOT=""

# Parse args: flags + optional positional project root
for arg in "$@"; do
    case "$arg" in
        --lite)
            PROFILE="lite"
            PROFILE_SET=1
            ;;
        --balanced)
            PROFILE="balanced"
            PROFILE_SET=1
            ;;
        --turbo)
            PROFILE="turbo"
            PROFILE_SET=1
            ;;
        --experimental)
            EXPERIMENTAL=1
            ;;
        --help|-h)
            echo -e "\nPromptKit OS init.sh — 1-Click Setup\n"
            echo -e "Usage: ./init.sh [options] [project-root]\n"
            echo -e "Options:"
            echo -e "  --lite              Lite profile: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value"
            echo -e "  --balanced          Balanced profile: the full workflow set, Level 0-3 adaptive ceremony (default)"
            echo -e "  --turbo             Turbo profile: Balanced + parallel subagent waves, up to ~2x measured token cost"
            echo -e "  --experimental      Required for --turbo, acknowledges experimental cost and warnings"
            echo -e "  -h, --help          Show this help\n"
            echo -e "Profiles stored in PROMPTKIT.md as 'profile: lite|balanced|turbo'"
            echo -e "Interactive: When no flag provided and running in TTY, shows visual picker (1) Lite (Recommended) 2) Balanced 3) Turbo Experimental"
            echo -e "Env escape hatch: PROMPTKIT_NO_INTERACTIVE=1 skips the picker even in a TTY (use flags or Balanced default)"
            echo -e "Examples:"
            echo -e "  ./init.sh --lite"
            echo -e "  ./init.sh --balanced /path/to/project"
            echo -e "  ./init.sh --turbo --experimental\n"
            exit 0
            ;;
        --*)
            echo -e "\033[0;31m[!] Unknown flag: $arg\033[0m" >&2
            echo "Use --help for usage." >&2
            exit 1
            ;;
        *)
            if [[ -z "$PROJECT_ROOT" ]]; then
                if [[ -d "$arg" ]]; then
                    PROJECT_ROOT="$(cd "$arg" && pwd)"
                else
                    echo -e "\033[0;31m[!] Project root not found: $arg\033[0m" >&2
                    exit 1
                fi
            else
                echo -e "\033[0;31m[!] Multiple project roots provided: $PROJECT_ROOT and $arg\033[0m" >&2
                exit 1
            fi
            ;;
    esac
done

# Resolve PROJECT_ROOT if not provided via positional arg
if [[ -z "$PROJECT_ROOT" ]]; then
    if [[ "$DIR_NAME" == ".promptkit" || "$DIR_NAME" == "promptkit" ]]; then
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    else
        PROJECT_ROOT="$(pwd)"
    fi
fi

# Interactive TTY picker when no profile flag provided (visual decision for onboarding)
# This is the shell-level equivalent of native interactive selection tools (ask_question)
# Agent-level picker is in workflows/onboard.md which uses ask_question for same choice
# Non-interactive safety (#144): require BOTH stdin and stdout to be TTYs (so piped or
# log-redirected invocations can never block on a blind prompt), and honor the documented
# PROMPTKIT_NO_INTERACTIVE escape hatch to force the flag/default (non-interactive) path.
if [[ "$PROFILE_SET" -eq 0 && "$EXPERIMENTAL" -eq 0 && -t 0 && -t 1 && -z "${PROMPTKIT_NO_INTERACTIVE:-}" ]]; then
    echo -e "\n\033[0;36m💡 PromptKit OS Profile Selection (visual decision)\033[0m"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "  \033[1;33m1) Lite (Recommended for new users)\033[0m — 6 utility workflows (route, debug, commit, checkpoint, sync, profile) 961 tok, 80% value, fastest onboarding"
    echo -e "  2) Balanced (Recommended for teams) — 23 workflows, 2,319 tok, Level 0-3 adaptive ceremony, full power [default]"
    echo -e "  3) Turbo (Experimental) — Balanced + parallel subagent waves, up to ~2x measured token cost, still requires human L3 approval"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "Profiles stored in PROMPTKIT.md as 'profile: lite|balanced|turbo'"
    echo -e "For CI/non-interactive, use flags: --lite, --balanced, --turbo --experimental"
    echo ""
    read -p "Choose profile [1-3, default 2]: " choice
    case "$choice" in
        1)
            PROFILE="lite"
            PROFILE_SET=1
            ;;
        3)
            echo -e "\n\033[0;33m⚠️  Turbo requires --experimental flag\033[0m"
            echo -e "   Turbo uses parallel subagent waves (up to ~2x measured token cost) and is experimental."
            echo -e "   Run: ./init.sh --turbo --experimental"
            read -p "Acknowledge experimental cost and proceed with Turbo? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                PROFILE="turbo"
                EXPERIMENTAL=1
                PROFILE_SET=1
            else
                echo "Defaulting to Balanced"
                PROFILE="balanced"
                PROFILE_SET=1
            fi
            ;;
        *)
            PROFILE="balanced"
            PROFILE_SET=1
            ;;
    esac
    echo ""
fi

# Validate turbo requires experimental
if [[ "$PROFILE" == "turbo" && "$EXPERIMENTAL" -eq 0 ]]; then
    echo -e "\n\033[0;31m[!] --turbo requires --experimental flag\033[0m" >&2
    echo -e "   Turbo uses parallel subagent waves (up to ~2x measured token cost) and is experimental." >&2
    echo -e "   It still requires human approval for Level 3 (releases/tags/deploys)." >&2
    echo -e "   Run: ./init.sh --turbo --experimental [project-root]\n" >&2
    exit 1
fi

echo -e "\n\033[0;36m🚀 Initializing PromptKit OS ($PROFILE profile)...\033[0m"
echo -e "   Host Project: $PROJECT_ROOT"
echo -e "   Engine Path:  $SCRIPT_DIR"
echo -e "   Profile:      $PROFILE"
if [[ "$PROFILE" == "turbo" ]]; then
    echo -e "   \033[0;33m⚠️  Turbo: up to ~2x measured token cost, experimental, parallel waves. Human approval still required for L3.\033[0m"
fi
if [[ "$PROFILE" == "lite" ]]; then
    echo -e "   \033[0;32m✨ Lite: 6 utility workflows, <1,500 tok, 80% value — perfect for onboarding\033[0m"
fi
echo ""

# 1. Ensure Core Documentation Directories Exist in Host Project
DOC_DIRS=(
    "docs/tasks"
    "docs/specs"
    "docs/adrs"
    "docs/tests"
)
for dir in "${DOC_DIRS[@]}"; do
    if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
        mkdir -p "$PROJECT_ROOT/$dir"
        echo -e "  \033[0;32m[+]\\033[0m Created directory: $dir"
    fi
done

# 2. Scaffold PROMPTKIT.md if missing + inject profile
PROJECT_PROFILE="$PROJECT_ROOT/PROMPTKIT.md"
TEMPLATE_PROFILE="$SCRIPT_DIR/templates/project-profile-template.md"

if [[ ! -f "$PROJECT_PROFILE" ]]; then
    if [[ -f "$TEMPLATE_PROFILE" ]]; then
        cp "$TEMPLATE_PROFILE" "$PROJECT_PROFILE"
        echo -e "  \033[0;32m[+]\\033[0m Created: PROMPTKIT.md (project profile & guardrails)"
    fi
else
    echo -e "  \033[0;90m[✓] PROMPTKIT.md already present\\033[0m"
fi

# Inject or update profile field in PROMPTKIT.md (2+1 modes)
if [[ -f "$PROJECT_PROFILE" ]]; then
    if grep -q "^profile:" "$PROJECT_PROFILE" 2>/dev/null; then
        if sed --version >/dev/null 2>&1; then
            sed -i "s/^profile:.*/profile: $PROFILE/" "$PROJECT_PROFILE"
            if grep -q '^- \*\*Profile\*\*:' "$PROJECT_PROFILE" 2>/dev/null; then
                sed -i "s/^- \*\*Profile\*\*:.*/- **Profile**: $PROFILE/" "$PROJECT_PROFILE"
            fi
        else
            sed -i.bak "s/^profile:.*/profile: $PROFILE/" "$PROJECT_PROFILE" && rm -f "$PROJECT_PROFILE.bak"
            if grep -q '^- \*\*Profile\*\*:' "$PROJECT_PROFILE" 2>/dev/null; then
                sed -i.bak "s/^- \*\*Profile\*\*:.*/- **Profile**: $PROFILE/" "$PROJECT_PROFILE" && rm -f "$PROJECT_PROFILE.bak"
            fi
        fi
        echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md profile: $PROFILE"
    else
        TMP_FILE=$(mktemp)
        {
            head -n 1 "$PROJECT_PROFILE"
            echo ""
            echo "## 0. PromptKit OS Profile"
            echo "- **Profile**: $PROFILE"
            echo "- **Installed**: $(date +%Y-%m-%d)"
            echo "- **Engine**: .promptkit"
            echo "- **Upgrade**: Run \`.promptkit/init.sh --balanced\` for the full Balanced profile, or \`--turbo --experimental\` for parallel waves"
            echo ""
            tail -n +2 "$PROJECT_PROFILE"
            echo ""
            echo "profile: $PROFILE"
        } > "$TMP_FILE"
        mv "$TMP_FILE" "$PROJECT_PROFILE"
        echo -e "  \033[0;32m[+]\\033[0m Set PROMPTKIT.md profile: $PROFILE"
    fi
fi

DESIGN_PROFILE="$PROJECT_ROOT/DESIGN.md"
if [[ -f "$DESIGN_PROFILE" ]]; then
    echo -e "  \033[0;90m[✓] DESIGN.md detected (brand identity & anti-slop rules)\\033[0m"
fi

# Scaffold docs/STATE.md if missing
STATE_TRACKER="$PROJECT_ROOT/docs/STATE.md"
TEMPLATE_STATE="$SCRIPT_DIR/templates/state-tracker-template.md"

if [[ ! -f "$STATE_TRACKER" ]]; then
    if [[ -f "$TEMPLATE_STATE" ]]; then
        cp "$TEMPLATE_STATE" "$STATE_TRACKER"
        echo -e "  \033[0;32m[+]\\033[0m Created: docs/STATE.md (living project & state tracker)"
    fi
else
    echo -e "  \033[0;90m[✓] docs/STATE.md already present\\033[0m"
fi

# Scaffold .github/pull_request_template.md if missing
GITHUB_DIR="$PROJECT_ROOT/.github"
PR_TEMPLATE_TARGET="$GITHUB_DIR/pull_request_template.md"
TEMPLATE_PR="$SCRIPT_DIR/templates/pull-request-template.md"

if [[ ! -f "$PR_TEMPLATE_TARGET" ]]; then
    if [[ -f "$TEMPLATE_PR" ]]; then
        mkdir -p "$GITHUB_DIR"
        cp "$TEMPLATE_PR" "$PR_TEMPLATE_TARGET"
        echo -e "  \033[0;32m[+]\\033[0m Created: .github/pull_request_template.md (staff-level PR specification)"
    fi
else
    echo -e "  \033[0;90m[✓] .github/pull_request_template.md already present\\033[0m"
fi

# Scaffold .github/ISSUE_TEMPLATE/task.md if missing
ISSUE_TEMPLATE_DIR="$GITHUB_DIR/ISSUE_TEMPLATE"
TASK_TEMPLATE_TARGET="$ISSUE_TEMPLATE_DIR/task.md"
TEMPLATE_TASK="$SCRIPT_DIR/templates/github-issue-template.md"

if [[ ! -f "$TASK_TEMPLATE_TARGET" ]]; then
    if [[ -f "$TEMPLATE_TASK" ]]; then
        mkdir -p "$ISSUE_TEMPLATE_DIR"
        cp "$TEMPLATE_TASK" "$TASK_TEMPLATE_TARGET"
        echo -e "  \\033[0;32m[+]\\033[0m Created: .github/ISSUE_TEMPLATE/task.md (standard task specification)"
    fi
else
    echo -e "  \033[0;90m[✓] .github/ISSUE_TEMPLATE/task.md already present\\033[0m"
fi



# 3. Detect Agent Files or Default to AGENTS.md
AGENT_FILES=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    ".cursorrules"
    ".cursor/rules/promptkit.mdc"
    ".windsurfrules"
    ".github/copilot-instructions.md"
    ".clinerules"
    ".clinerules/promptkit.md"
    ".traerules"
    ".opencode/rules.md"
    "CONVENTIONS.md"   # Aider conventions file
)

TARGETS_FOUND=()
for file in "${AGENT_FILES[@]}"; do
    target_path="$PROJECT_ROOT/$file"
    if [[ -d "$target_path" ]]; then
        if [[ "$file" == ".clinerules" ]]; then
            dir_target="$target_path/promptkit.md"
            if [[ ! -f "$dir_target" ]]; then
                touch "$dir_target"
            fi
            TARGETS_FOUND+=("$dir_target")
        fi
    elif [[ -f "$target_path" ]]; then
        TARGETS_FOUND+=("$target_path")
    fi
done

if [[ ${#TARGETS_FOUND[@]} -eq 0 ]]; then
    DEFAULT_AGENT="$PROJECT_ROOT/AGENTS.md"
    DEFAULT_CLAUDE="$PROJECT_ROOT/CLAUDE.md"
    touch "$DEFAULT_AGENT"
    touch "$DEFAULT_CLAUDE"
    TARGETS_FOUND+=("$DEFAULT_AGENT")
    TARGETS_FOUND+=("$DEFAULT_CLAUDE")
    echo -e "  \033[0;32m[+]\\033[0m Created default agent configurations: AGENTS.md & CLAUDE.md"
fi

# 4. Directive Block (Loaded from Canonical Template based on profile)
KIT_DIR_REL=".promptkit"
if [[ "$SCRIPT_DIR" == "$PROJECT_ROOT"* ]]; then
    KIT_DIR_REL="${SCRIPT_DIR#$PROJECT_ROOT/}"
fi

if [[ "$PROFILE" == "lite" ]]; then
    TEMPLATE_DIRECTIVE="$SCRIPT_DIR/templates/agent-directive-lite-template.md"
    if [[ ! -f "$TEMPLATE_DIRECTIVE" ]]; then
        echo "Warning: Lite template not found, falling back to full template" >&2
        TEMPLATE_DIRECTIVE="$SCRIPT_DIR/templates/agent-directive-template.md"
    fi
else
    TEMPLATE_DIRECTIVE="$SCRIPT_DIR/templates/agent-directive-template.md"
fi

if [[ -f "$TEMPLATE_DIRECTIVE" ]]; then
    DIRECTIVE="$(sed "s|\\\$KIT_DIR_REL|$KIT_DIR_REL|g" "$TEMPLATE_DIRECTIVE")"
else
    echo "Error: Canonical directive template not found at $TEMPLATE_DIRECTIVE" >&2
    exit 1
fi

# 5. Inject or Replace Directives (Idempotent)
for target in "${TARGETS_FOUND[@]}"; do
    REL_TARGET="${target#$PROJECT_ROOT/}"
    CR=$'\r'
    has_start=0
    has_end=0
    if grep -qE "^<!-- PROMPTKIT_START -->${CR}?$" "$target" 2>/dev/null; then has_start=1; fi
    if grep -qE "^<!-- PROMPTKIT_END -->${CR}?$" "$target" 2>/dev/null; then has_end=1; fi

    if [[ "$has_start" -eq 1 || "$has_end" -eq 1 ]]; then
        start_count="$(grep -E -c "^<!-- PROMPTKIT_START -->${CR}?$" "$target" 2>/dev/null || true)"
        end_count="$(grep -E -c "^<!-- PROMPTKIT_END -->${CR}?$" "$target" 2>/dev/null || true)"
        if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
            echo "Error: Cannot safely update $REL_TARGET: expected exactly one complete PromptKit directive block." >&2
            exit 1
        fi

        directive_file="$(mktemp "${target}.directive.XXXXXX")"
        updated_file="$(mktemp "${target}.updated.XXXXXX")"
        cleanup_update_files() {
            rm -f "$directive_file" "$updated_file" "${updated_file}.content"
        }
        trap cleanup_update_files EXIT
        printf '%s\n' "$DIRECTIVE" > "$directive_file"

        cp -p "$target" "$updated_file"
        if ! awk -v directive_file="$directive_file" '
            BEGIN {
                first = 1
                while ((getline line < directive_file) > 0) {
                    if (first) {
                        directive = line
                        first = 0
                    } else {
                        directive = directive ORS line
                    }
                }
                close(directive_file)
            }
            /^<!-- PROMPTKIT_START -->\r?$/ {
                print directive
                inside = 1
                next
            }
            /^<!-- PROMPTKIT_END -->\r?$/ && inside {
                inside = 0
                next
            }
            !inside { print }
            END {
                if (inside) exit 1
            }
        ' "$target" > "${updated_file}.content"; then
            rm -f "${updated_file}.content"
            echo "Error: Unable to safely update $REL_TARGET; the original file was preserved. Update it manually." >&2
            exit 1
        fi
        chmod --reference="$target" "${updated_file}.content" 2>/dev/null || true
        mv "${updated_file}.content" "$updated_file"
        mv "$updated_file" "$target"
        trap - EXIT
        rm -f "$directive_file"
        echo -e "  \033[0;33m[✓]\\033[0m Updated PromptKit OS directives in: $REL_TARGET (profile: $PROFILE)"
    else
        printf "\n\n%s\n" "$DIRECTIVE" >> "$target"
        echo -e "  \033[0;32m[+]\\033[0m Injected PromptKit OS directives into: $REL_TARGET (profile: $PROFILE)"
    fi
done

echo -e "\n\033[0;36m✨ PromptKit OS successfully configured for $PROJECT_ROOT! ($PROFILE profile)\033[0m"
if [[ "$PROFILE" == "lite" ]]; then
    echo -e "   \033[0;32mLite: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) — 80% value, <1,500 tok\033[0m"
    echo -e "   Upgrade anytime: .promptkit/init.sh --balanced for the full Balanced profile"
elif [[ "$PROFILE" == "balanced" ]]; then
    echo -e "   Balanced: 23 workflows, Level 0-3 adaptive ceremony — full power"
    echo -e "   For onboarding: .promptkit/init.sh --lite for minimal setup"
else
    echo -e "   \033[0;33mTurbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost\033[0m"
    echo -e "   Human approval still required for Level 3 (releases/tags/deploys)"
fi
echo -e "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'\n"
