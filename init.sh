#!/usr/bin/env bash
# PromptKit OS 1-Click Setup Script for Linux/macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_NAME="$(basename "$SCRIPT_DIR")"

if [[ "$#" -gt 0 ]]; then
    PROJECT_ROOT="$(cd "$1" && pwd)"
elif [[ "$DIR_NAME" == ".promptkit" || "$DIR_NAME" == "promptkit" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    PROJECT_ROOT="$(pwd)"
fi

echo -e "\n\033[0;36m🚀 Initializing PromptKit OS...\033[0m"
echo -e "   Host Project: $PROJECT_ROOT"
echo -e "   Engine Path:  $SCRIPT_DIR\n"

# 1. Ensure Core Documentation Directories Exist in Host Project
# (Specialized subdirectories like docs/auth, docs/data are created on-demand by workflows)
DOC_DIRS=(
    "docs/tasks"
    "docs/specs"
    "docs/adrs"
    "docs/tests"
)
for dir in "${DOC_DIRS[@]}"; do
    if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
        mkdir -p "$PROJECT_ROOT/$dir"
        echo -e "  \033[0;32m[+]\033[0m Created directory: $dir"
    fi
done

# 2. Scaffold PROMPTKIT.md if missing
PROJECT_PROFILE="$PROJECT_ROOT/PROMPTKIT.md"
TEMPLATE_PROFILE="$SCRIPT_DIR/templates/project-profile-template.md"

if [[ ! -f "$PROJECT_PROFILE" ]]; then
    if [[ -f "$TEMPLATE_PROFILE" ]]; then
        cp "$TEMPLATE_PROFILE" "$PROJECT_PROFILE"
        echo -e "  \033[0;32m[+]\033[0m Created: PROMPTKIT.md (project profile & guardrails)"
    fi
else
    echo -e "  \033[0;90m[✓] PROMPTKIT.md already present\033[0m"
fi

DESIGN_PROFILE="$PROJECT_ROOT/DESIGN.md"
if [[ -f "$DESIGN_PROFILE" ]]; then
    echo -e "  \033[0;90m[✓] DESIGN.md detected (brand identity & anti-slop rules)\033[0m"
fi

# Scaffold docs/STATE.md if missing
STATE_TRACKER="$PROJECT_ROOT/docs/STATE.md"
TEMPLATE_STATE="$SCRIPT_DIR/templates/state-tracker-template.md"

if [[ ! -f "$STATE_TRACKER" ]]; then
    if [[ -f "$TEMPLATE_STATE" ]]; then
        cp "$TEMPLATE_STATE" "$STATE_TRACKER"
        echo -e "  \033[0;32m[+]\033[0m Created: docs/STATE.md (living project & state tracker)"
    fi
else
    echo -e "  \033[0;90m[✓] docs/STATE.md already present\033[0m"
fi

# Scaffold .github/pull_request_template.md if missing
GITHUB_DIR="$PROJECT_ROOT/.github"
PR_TEMPLATE_TARGET="$GITHUB_DIR/pull_request_template.md"
TEMPLATE_PR="$SCRIPT_DIR/templates/pull-request-template.md"

if [[ ! -f "$PR_TEMPLATE_TARGET" ]]; then
    if [[ -f "$TEMPLATE_PR" ]]; then
        mkdir -p "$GITHUB_DIR"
        cp "$TEMPLATE_PR" "$PR_TEMPLATE_TARGET"
        echo -e "  \033[0;32m[+]\033[0m Created: .github/pull_request_template.md (staff-level PR specification)"
    fi
else
    echo -e "  \033[0;90m[✓] .github/pull_request_template.md already present\033[0m"
fi

# Scaffold .github/ISSUE_TEMPLATE/task.md if missing
ISSUE_TEMPLATE_DIR="$GITHUB_DIR/ISSUE_TEMPLATE"
TASK_TEMPLATE_TARGET="$ISSUE_TEMPLATE_DIR/task.md"
TEMPLATE_TASK="$SCRIPT_DIR/templates/github-issue-template.md"

if [[ ! -f "$TASK_TEMPLATE_TARGET" ]]; then
    if [[ -f "$TEMPLATE_TASK" ]]; then
        mkdir -p "$ISSUE_TEMPLATE_DIR"
        cp "$TEMPLATE_TASK" "$TASK_TEMPLATE_TARGET"
        echo -e "  \033[0;32m[+]\033[0m Created: .github/ISSUE_TEMPLATE/task.md (standard task specification)"
    fi
else
    echo -e "  \033[0;90m[✓] .github/ISSUE_TEMPLATE/task.md already present\033[0m"
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
    echo -e "  \033[0;32m[+]\033[0m Created default agent configurations: AGENTS.md & CLAUDE.md"
fi

# 4. Directive Block (Loaded from Canonical Template)
KIT_DIR_REL=".promptkit"
if [[ "$SCRIPT_DIR" == "$PROJECT_ROOT"* ]]; then
    KIT_DIR_REL="${SCRIPT_DIR#$PROJECT_ROOT/}"
fi

TEMPLATE_DIRECTIVE="$SCRIPT_DIR/templates/agent-directive-template.md"
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
        echo -e "  \033[0;33m[✓]\033[0m Updated PromptKit OS directives in: $REL_TARGET"
    else
        printf "\n\n%s\n" "$DIRECTIVE" >> "$target"
        echo -e "  \033[0;32m[+]\033[0m Injected PromptKit OS directives into: $REL_TARGET"
    fi
done

echo -e "\n\033[0;36m✨ PromptKit OS successfully configured for $PROJECT_ROOT!\033[0m"
echo -e "   Start by asking your AI: 'pk:sync', 'pk:plan', or 'pk:tutor'\n"
