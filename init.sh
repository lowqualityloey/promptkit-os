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
TRACKING="local"
TRACKING_SET=0
TRACKING_PROJECTION=""
HOSTS=""
HOST_SET=0
RECONFIGURE=0
EXTRA_TARGETS=""
PROJECT_ROOT=""
# Known host -> directive file map (defined early: arg parsing validates against it).
# Probes are best-effort suggestions only; the TTY menu (or --host=) is authoritative.
host_file() {
    case "$1" in
        agents) echo "AGENTS.md" ;;
        claude) echo "CLAUDE.md" ;;
        opencode) echo ".opencode/rules.md" ;;
        cursor) echo ".cursorrules" ;;
        gemini) echo "GEMINI.md" ;;
        windsurf) echo ".windsurfrules" ;;
        copilot) echo ".github/copilot-instructions.md" ;;
        cline) echo ".clinerules" ;;
        trae) echo ".traerules" ;;
        aider) echo "CONVENTIONS.md" ;;
        *) echo "" ;;
    esac
}
KNOWN_HOSTS="claude opencode cursor gemini windsurf copilot cline trae aider"

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
        --tracking=*)
            TRACKING="${arg#--tracking=}"
            case "$TRACKING" in
                local|github|jira|linear) TRACKING_SET=1 ;;
                *) echo -e "\033[0;31m[!] Unknown tracking: $TRACKING (use local|github|jira|linear)\033[0m" >&2; exit 1 ;;
            esac
            ;;
        --host=*)
            HOSTS="${arg#--host=}"
            HOST_SET=1
            ;;
        --add-host=*)
            ADD_HOST="${arg#--add-host=}"
            if [[ -z "$(host_file "$ADD_HOST")" ]]; then
                echo -e "\033[0;31m[!] Unknown host: $ADD_HOST (use one of: agents,${KNOWN_HOSTS// /,})\033[0m" >&2; exit 1
            fi
            HOSTS="agents,$ADD_HOST"
            HOST_SET=1
            ;;
        --target=*)
            TARGET_PATH="${arg#--target=}"
            case "$TARGET_PATH" in
                /*|*../*)
                    echo -e "\033[0;31m[!] --target must be a project-relative path without '..': $TARGET_PATH\033[0m" >&2; exit 1
                    ;;
            esac
            EXTRA_TARGETS="$EXTRA_TARGETS $TARGET_PATH"
            ;;
        --reconfigure)
            RECONFIGURE=1
            ;;
        --help|-h)
            echo -e "\nPromptKit OS init.sh — 1-Click Setup\n"
            echo -e "Usage: ./init.sh [options] [project-root]\n"
            echo -e "Options:"
            echo -e "  --lite              Lite profile: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value"
            echo -e "  --balanced          Balanced profile: the full workflow set, Level 0-3 adaptive ceremony (default)"
            echo -e "  --turbo             Turbo profile: Balanced + parallel subagent waves, up to ~2x measured token cost"
            echo -e "  --experimental      Required for --turbo, acknowledges experimental cost and warnings"
            echo -e "  --tracking=local|github|jira|linear  Task tracker (default: local; jira/linear = manual import, no auto-push)"
            echo -e "  --host=a,b,c        AI hosts to configure (comma-separated from: claude,opencode,cursor,gemini,windsurf,copilot,cline,trae,aider)"
            echo -e "  --add-host=name     Add one host to an existing install (agents = universal AGENTS.md)"
            echo -e "  --reconfigure       Force interactive host re-selection on existing installations"
            echo -e "  --target=rel/path  Custom directive file (project-relative, repeatable; e.g. docs/AI.md)"
            echo -e "  -h, --help          Show this help\n"
            echo -e "Profiles stored in PROMPTKIT.md as 'profile: lite|balanced|turbo'"
            echo -e "Interactive: When no flag provided and running in TTY, shows visual picker (1) Lite (Recommended) 2) Balanced 3) Turbo Experimental"
            echo -e "Preflight opt-out: PROMPTKIT_NO_PREFLIGHT=1 skips advisory local security inspection (independent of picker)"
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

# Keep installed settings on update re-runs (flags always win over installed values)
if [[ "$PROFILE_SET" -eq 0 ]]; then
    installed_profile="$(grep -E '^profile:[[:space:]]' "$PROJECT_ROOT/PROMPTKIT.md" 2>/dev/null | tail -n 1 | awk '{print $2}' || true)"
    case "$installed_profile" in
        lite|balanced)
            PROFILE="$installed_profile"; PROFILE_SET=1
            echo -e "  Keeping installed profile: $PROFILE (pass --lite/--balanced/--turbo to change)" ;;
        turbo)
            PROFILE="turbo"; EXPERIMENTAL=1; PROFILE_SET=1
            echo -e "  Keeping installed profile: turbo (previously acknowledged --experimental)" ;;
    esac
fi
if [[ "$TRACKING_SET" -eq 0 ]]; then
    installed_tracking="$(grep -E '^tracking:[[:space:]]' "$PROJECT_ROOT/PROMPTKIT.md" 2>/dev/null | tail -n 1 | awk '{print $2}' || true)"
    case "$installed_tracking" in
        local|github|jira|linear)
            TRACKING="$installed_tracking"; TRACKING_SET=1
            if [[ "$TRACKING" == "local" ]]; then
                TRACKING_PROJECTION="$(grep -E '^projection:[[:space:]]' "$PROJECT_ROOT/PROMPTKIT.md" 2>/dev/null | tail -n 1 | awk '{print $2}' || true)"
                [[ "$TRACKING_PROJECTION" != "github" ]] && TRACKING_PROJECTION=""
            fi
            echo -e "  Keeping installed tracker: $TRACKING${TRACKING_PROJECTION:+ + $TRACKING_PROJECTION projection} (pass --tracking= to change)" ;;
    esac
fi
if [[ "$HOST_SET" -eq 0 && "$RECONFIGURE" -eq 0 && -f "$PROJECT_ROOT/PROMPTKIT.md" ]]; then
    installed_hosts=""
    for h in $KNOWN_HOSTS; do
        hf="$(host_file "$h")"
        if [[ -n "$hf" && -f "$PROJECT_ROOT/$hf" ]]; then
            installed_hosts="$installed_hosts $h"
        elif [[ "$h" == "cline" && (-f "$PROJECT_ROOT/.clinerules" || -f "$PROJECT_ROOT/.clinerules/promptkit.md") ]]; then
            installed_hosts="$installed_hosts $h"
        elif [[ "$h" == "cursor" && (-f "$PROJECT_ROOT/.cursorrules" || -f "$PROJECT_ROOT/.cursor/rules/promptkit.mdc") ]]; then
            installed_hosts="$installed_hosts $h"
        fi
    done
    installed_hosts="${installed_hosts# }"
    if [[ -n "$installed_hosts" ]]; then
        HOSTS="$(echo "$installed_hosts" | tr ' ' ',')"
        HOST_SET=1
        echo -e "  Keeping installed hosts: $HOSTS (pass --host= or --reconfigure to change)"
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
    echo -e "  2) Balanced (Recommended for teams) — 24 workflows, 2,319 tok, Level 0-3 adaptive ceremony, full power [default]"
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

# Interactive tracker picker (visual decision for onboarding, step 2)
if [[ "$TRACKING_SET" -eq 0 && -t 0 && -t 1 && -z "${PROMPTKIT_NO_INTERACTIVE:-}" ]]; then
    echo -e "\033[0;36m💡 Task Tracker Selection (visual decision)\033[0m"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "  \033[1;33m1) Local Markdown (Recommended for solo / offline)\033[0m — docs/tasks/ + STATE.md only, import later"
    echo -e "  2) GitHub Issues — via gh CLI or MCP, needs gh auth + labels script"
    echo -e "  3) Jira — manual import / copy-paste, no auto-push, needs project key"
    echo -e "  4) Linear — manual import / copy-paste, no auto-push, needs project key"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    echo -e "  Tip: combine local with GitHub projection, e.g. '1,2' or '1 and 2'."
    echo ""
    TRACKING_PROJECTION=""
    tracker_attempts=0
    while true; do
        read -p "Choose tracker [1-4, combos like 1,2 allowed, default 1]: " tchoice
        if [ -z "$tchoice" ]; then
            TRACKING="local"
            break
        fi
        norm="$(printf '%s' "$tchoice" | tr '[:upper:]' '[:lower:]' | sed -e 's/[,&+]/ /g' -e 's/[^0-9 ]//g' -e 's/  */ /g' -e 's/^ //;s/ $//')"
        has1=0; has2=0; has3=0; has4=0; bad=0
        [ -z "$norm" ] && bad=1
        for tok in $norm; do
            case "$tok" in
                1) has1=1 ;;
                2) has2=1 ;;
                3) has3=1 ;;
                4) has4=1 ;;
                *) bad=1 ;;
            esac
        done
        if [ "$bad" -eq 0 ] && { [ "$has3" -eq 0 ] || { [ "$has1" -eq 0 ] && [ "$has2" -eq 0 ] && [ "$has4" -eq 0 ]; }; } && { [ "$has4" -eq 0 ] || { [ "$has1" -eq 0 ] && [ "$has2" -eq 0 ] && [ "$has3" -eq 0 ]; }; }; then
            TRACKING_PROJECTION=""
            if [ "$has1" -eq 1 ] || { [ "$has2" -eq 0 ] && [ "$has3" -eq 0 ] && [ "$has4" -eq 0 ]; }; then
                TRACKING="local"
                [ "$has2" -eq 1 ] && TRACKING_PROJECTION="github"
            elif [ "$has2" -eq 1 ]; then
                TRACKING="github"
            elif [ "$has3" -eq 1 ]; then
                TRACKING="jira"
            else
                TRACKING="linear"
            fi
            break
        fi
        tracker_attempts=$((tracker_attempts + 1))
        if [ "$tracker_attempts" -ge 3 ]; then
            echo -e "\033[0;33m[!] Unrecognized tracker selection after 3 attempts — defaulting to Local Markdown.\033[0m"
            TRACKING="local"
            TRACKING_PROJECTION=""
            break
        fi
        echo -e "\033[0;33m[!] Could not parse '$tchoice'. Use numbers 1-4 (e.g. 1, 2, or 1,2 for local + GitHub projection).\033[0m"
    done
    TRACKING_SET=1
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
echo -e "   Tracking:     $TRACKING"
if [[ "$PROFILE" == "turbo" ]]; then
    echo -e "   \033[0;33m⚠️  Turbo: up to ~2x measured token cost, experimental, parallel waves. Human approval still required for L3.\033[0m"
fi
if [[ "$PROFILE" == "lite" ]]; then
    echo -e "   \033[0;32m✨ Lite: 6 utility workflows, <1,500 tok, 80% value — perfect for onboarding\033[0m"
fi
echo ""

if [[ "${PROMPTKIT_NO_PREFLIGHT:-}" == "1" ]]; then
    printf '%s\n' 'PREFLIGHT|SKIPPED|USER_OPT_OUT'
else
    if bash "$SCRIPT_DIR/scripts/check-harness-security.sh" "$PROJECT_ROOT"; then
        :
    else
        printf '%s\n' 'PREFLIGHT|ADVISORY|Review findings or incomplete checks; installation continues'
    fi
fi

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
    if grep -q "^tracking:" "$PROJECT_PROFILE" 2>/dev/null; then
        if sed --version >/dev/null 2>&1; then
            sed -i "s/^tracking:.*/tracking: $TRACKING/" "$PROJECT_PROFILE"
        else
            sed -i.bak "s/^tracking:.*/tracking: $TRACKING/" "$PROJECT_PROFILE" && rm -f "$PROJECT_PROFILE.bak"
        fi
    else
        echo "" >> "$PROJECT_PROFILE"
        echo "tracking: $TRACKING" >> "$PROJECT_PROFILE"
    fi
    echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md tracking: $TRACKING"
    if [ -n "$TRACKING_PROJECTION" ]; then
        if grep -q "^projection:" "$PROJECT_PROFILE" 2>/dev/null; then
            if sed --version >/dev/null 2>&1; then
                sed -i "s/^projection:.*/projection: $TRACKING_PROJECTION/" "$PROJECT_PROFILE"
            else
                sed -i.bak "s/^projection:.*/projection: $TRACKING_PROJECTION/" "$PROJECT_PROFILE" && rm -f "$PROJECT_PROFILE.bak"
            fi
        else
            echo "" >> "$PROJECT_PROFILE"
            echo "projection: $TRACKING_PROJECTION" >> "$PROJECT_PROFILE"
        fi
        echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md projection: $TRACKING_PROJECTION"
    else
        if grep -q "^projection:" "$PROJECT_PROFILE" 2>/dev/null; then
            if sed --version >/dev/null 2>&1; then
                sed -i "/^projection:/d" "$PROJECT_PROFILE"
            else
                sed -i.bak "/^projection:/d" "$PROJECT_PROFILE" && rm -f "$PROJECT_PROFILE.bak"
            fi
            echo -e "  \033[0;33m[✓]\\033[0m Removed stale PROMPTKIT.md projection line"
        fi
    fi
fi

DESIGN_PROFILE="$PROJECT_ROOT/DESIGN.md"
if [[ -f "$DESIGN_PROFILE" ]]; then
    echo -e "  \033[0;90m[✓] DESIGN.md detected (brand identity & anti-slop rules)\\033[0m"
fi

# Scaffold docs/STATE.md if missing
DOCS_DIR="$PROJECT_ROOT/docs"
STATE_TRACKER="$DOCS_DIR/STATE.md"
TEMPLATE_STATE="$SCRIPT_DIR/templates/state-tracker-template.md"

if [[ ! -f "$STATE_TRACKER" ]]; then
    if [[ -f "$TEMPLATE_STATE" ]]; then
        mkdir -p "$DOCS_DIR"
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



# 2b. Host probing + selection (which AI assistants get directive files)
# AGENTS.md is always created fresh as the universal fallback standard
# (see protocols/setup.md); host_file()/KNOWN_HOSTS live near the top
# because arg parsing validates --host=/--add-host against them.
if [[ "$HOST_SET" -eq 1 ]]; then
    for h in ${HOSTS//,/ }; do
        if [[ -z "$(host_file "$h")" ]]; then
            echo -e "\033[0;31m[!] Unknown host: $h (use comma-separated from: ${KNOWN_HOSTS// /,}) \033[0m" >&2; exit 1
        fi
    done
fi
DETECTED_HOSTS=""
probe_host() {
    local hf
    hf="$(host_file "$1")"
    if [[ -n "$hf" && -f "$PROJECT_ROOT/$hf" ]]; then
        return 0
    fi
    if [[ "$1" == "cline" && (-f "$PROJECT_ROOT/.clinerules" || -f "$PROJECT_ROOT/.clinerules/promptkit.md") ]]; then
        return 0
    fi
    if [[ "$1" == "cursor" && (-f "$PROJECT_ROOT/.cursorrules" || -f "$PROJECT_ROOT/.cursor/rules/promptkit.mdc") ]]; then
        return 0
    fi
    case "$1" in
        claude) command -v claude >/dev/null 2>&1 ;;
        opencode) command -v opencode >/dev/null 2>&1 || [[ -d "$HOME/.config/opencode" ]] ;;
        cursor) command -v cursor >/dev/null 2>&1 || [[ -d "$HOME/.cursor" ]] ;;
        gemini) command -v gemini >/dev/null 2>&1 ;;
        windsurf) command -v windsurf >/dev/null 2>&1 || [[ -d "$HOME/.windsurf" ]] ;;
        copilot) command -v copilot >/dev/null 2>&1 ;;
        cline) [[ -d "$HOME/.config/cline" ]] || [[ -d "$HOME/.cline" ]] ;;
        trae) command -v trae >/dev/null 2>&1 ;;
        aider) command -v aider >/dev/null 2>&1 ;;
    esac
}
if [[ "$HOST_SET" -eq 0 ]]; then
    for h in $KNOWN_HOSTS; do
        if probe_host "$h"; then
            DETECTED_HOSTS="$DETECTED_HOSTS $h"
        fi
    done
    DETECTED_HOSTS="${DETECTED_HOSTS# }"
fi
if [[ "$HOST_SET" -eq 0 && (! -t 0 || ! -t 1 || -n "${PROMPTKIT_NO_INTERACTIVE:-}") ]]; then
    # Non-interactive: a single unambiguous probe hit wins; zero or many
    # fall back to the deterministic legacy pair (never guess among several).
    if [[ "$(echo "$DETECTED_HOSTS" | wc -w)" -eq 1 ]]; then
        HOSTS="$DETECTED_HOSTS"
        HOST_SET=1
    fi
fi
if [[ "$HOST_SET" -eq 0 && -t 0 && -t 1 && -z "${PROMPTKIT_NO_INTERACTIVE:-}" ]]; then
    echo -e "\033[0;36m💡 AI Host Selection (visual decision)\033[0m"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    idx=0
    HOST_COUNT=0
    for h in $KNOWN_HOSTS; do HOST_COUNT=$((HOST_COUNT + 1)); done
    for h in $KNOWN_HOSTS; do
        idx=$((idx + 1))
        marker=""
        if [[ " $DETECTED_HOSTS " == *" $h "* ]]; then
            marker=" \033[0;32m[detected]\033[0;90m"
        fi
        echo -e "  $idx) $h$(echo -e "$marker") — $(host_file "$h")"
    done
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    if [[ -n "$DETECTED_HOSTS" ]]; then
        echo -e "Comma-separated numbers, Enter = detected ($(echo "$DETECTED_HOSTS" | tr ' ' ',')) + AGENTS.md"
    else
        echo -e "Comma-separated numbers, Enter = AGENTS.md + CLAUDE.md (default)"
    fi
    echo ""
    read -p "Choose hosts: " hchoice || true
    if [[ -n "$hchoice" ]]; then
        HOSTS=""
        for n in ${hchoice//,/ }; do
            if [[ "$n" =~ ^[0-9]+$ ]] && [[ "$n" -ge 1 ]] && [[ "$n" -le "$HOST_COUNT" ]]; then
                idx=0
                for h in $KNOWN_HOSTS; do
                    idx=$((idx + 1))
                    if [[ "$idx" -eq "$n" ]]; then
                        HOSTS="$HOSTS,$h"
                    fi
                done
            fi
        done
        HOSTS="${HOSTS#,}"
        if [[ -n "$HOSTS" ]]; then
            HOST_SET=1
        else
            echo -e "  No valid hosts selected; using default."
        fi
    fi
    if [[ "$HOST_SET" -eq 0 && -n "$DETECTED_HOSTS" ]]; then
        HOSTS="$(echo "$DETECTED_HOSTS" | tr ' ' ',')"
        HOST_SET=1
    fi
    echo ""
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

# Custom --target paths ride the same create/inject machinery as host files
if [[ -n "$EXTRA_TARGETS" ]]; then
    for xp in $EXTRA_TARGETS; do
        xfull="$PROJECT_ROOT/$xp"
        already=0
        for t in "${TARGETS_FOUND[@]}"; do
            [[ "$t" == "$xfull" ]] && already=1
        done
        if [[ "$already" -eq 0 ]]; then
            mkdir -p "$(dirname "$xfull")"
            [[ -f "$xfull" ]] || touch "$xfull"
            TARGETS_FOUND+=("$xfull")
            echo -e "  \033[0;32m[+]\\033[0m Added custom target: $xp"
        fi
    done
fi
# Create a directive target: parent dirs first, never overwrite, .clinerules stays a dir
create_target() {
    local rel="$1"
    local p="$PROJECT_ROOT/$rel"
    if [[ "$rel" == ".clinerules" ]]; then
        mkdir -p "$p"
        [[ -f "$p/promptkit.md" ]] || touch "$p/promptkit.md"
        TARGETS_FOUND+=("$p/promptkit.md")
        return 0
    fi
    mkdir -p "$(dirname "$p")"
    [[ -f "$p" ]] || touch "$p"
    TARGETS_FOUND+=("$p")
}
# Ensure a host file is registered (and created): newest hosts on existing
# installs, or fresh defaults. Never duplicates, never overwrites.
ensure_target() {
    local rel="$1"
    local want="$PROJECT_ROOT/$rel"
    [[ "$rel" == ".clinerules" ]] && want="$want/promptkit.md"
    local t
    local already=0
    for t in "${TARGETS_FOUND[@]}"; do
        [[ "$t" == "$want" ]] && already=1
    done
    if [[ "$already" -eq 0 ]]; then
        create_target "$rel"
        return 0
    fi
    return 1
}
FRESH=0
if [[ ${#TARGETS_FOUND[@]} -eq 0 ]]; then
    FRESH=1
fi
if [[ "$HOST_SET" -eq 1 && -n "$HOSTS" ]]; then
    for h in ${HOSTS//,/ }; do
        if ensure_target "$(host_file "$h")"; then
            echo -e "  \033[0;32m[+]\\033[0m Added host configuration: $(host_file "$h")"
        fi
    done
fi
if [[ "$FRESH" -eq 1 ]]; then
    ensure_target "AGENTS.md" >/dev/null || true
    if [[ "$HOST_SET" -eq 1 && -n "$HOSTS" ]]; then
        for h in ${HOSTS//,/ }; do
            rel="$(host_file "$h")"
            [[ "$rel" == "AGENTS.md" ]] && continue
            ensure_target "$rel" >/dev/null || true
        done
    else
        ensure_target "CLAUDE.md" >/dev/null || true
    fi
    created=""
    for t in "${TARGETS_FOUND[@]}"; do
        created="$created ${t#$PROJECT_ROOT/}"
    done
    echo -e "  \033[0;32m[+]\\033[0m Created default agent configurations:$created"
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
    echo -e "   Balanced: 24 workflows, Level 0-3 adaptive ceremony — full power"
    echo -e "   For onboarding: .promptkit/init.sh --lite for minimal setup"
else
    echo -e "   \033[0;33mTurbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost\033[0m"
    echo -e "   Human approval still required for Level 3 (releases/tags/deploys)"
fi
echo -e "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'\n"
