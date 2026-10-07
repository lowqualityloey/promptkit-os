#!/usr/bin/env bash
# PromptKit OS 1-Click Setup Script for Linux/macOS
# Supports profiles: --lite, --balanced (default), --turbo --experimental
# Includes interactive TTY picker when no flag provided (visual decision)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_NAME="$(basename "$SCRIPT_DIR")"
source "$SCRIPT_DIR/scripts/terminal-picker.sh"

# Stamp the installed engine identity (#545). Must never fail the install: unresolved
# values degrade to "unknown", which pk:sync reports as its own state, not an error.
# Never add --abbrev=0 here: it discards commit distance (measured: v1.10.1 vs
# v1.10.1-12-ge78fde0), hiding exactly the drift the stamp exists to expose. --match
# excludes the repo's non-release backup/* tags, which describe would otherwise pick.
ENGINE_VERSION="unknown"
ENGINE_SHA="unknown"
resolve_engine_identity() {
    if [[ -e "$SCRIPT_DIR/.git" ]] && command -v git >/dev/null 2>&1; then
        local described short_sha
        described="$(git -C "$SCRIPT_DIR" describe --tags --match 'v[0-9]*' 2>/dev/null || true)"
        short_sha="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
        if [[ -n "$described" ]]; then ENGINE_VERSION="$described"; fi
        if [[ -n "$short_sha" ]]; then ENGINE_SHA="$short_sha"; fi
    fi
    validate_engine_identity
    return 0
}

# `git describe` output is influenced by any tag an attacker can push to the kit repo,
# and both values below are interpolated into sed replacement text. A legal git ref may
# contain '|' (the s|...| delimiter), '&' (sed's whole-match) and '\'; those either abort
# the install or silently splice text into the rendered directive. Legitimate describe and
# short-SHA output only ever uses [A-Za-z0-9._+-], so anything else is rejected at the
# source and degrades to "unknown" like any other unresolved value — the stamp stays
# display-only and an install is never aborted by a hostile tag name.
validate_engine_identity() {
    if [[ ! "$ENGINE_VERSION" =~ ^[A-Za-z0-9._+-]+$ ]]; then ENGINE_VERSION="unknown"; fi
    if [[ ! "$ENGINE_SHA" =~ ^[A-Za-z0-9._+-]+$ ]]; then ENGINE_SHA="unknown"; fi
}

# Escape an arbitrary value for use as sed REPLACEMENT text. Backslash must be doubled
# first, or it would re-escape the metacharacters handled after it.
sed_replacement_escape() {
    printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g' | tr '\n' ' '
}
resolve_engine_identity

show_setup_banner() {
    [[ "$PICKER_TTY" -eq 1 ]] || return 0
    PK_PICKER_BANNER_PATH="$SCRIPT_DIR/templates/terminal-banner.txt"
    PK_PICKER_BANNER_ACTIVE=1
}

PICKER_TTY=0
if [[ -t 0 && -t 1 && -z "${PROMPTKIT_NO_INTERACTIVE:-}" && "${TERM:-}" != "dumb" ]]; then
    PICKER_TTY=1
fi
PROFILE_INTERACTIVE=0
TRACKING_INTERACTIVE=0
HOST_INTERACTIVE=0

cancel_setup() {
    printf '\nSetup cancelled before any project files were changed.\n'
    exit 130
}

choose_profile() {
    local choice attempts=0 default_index=0
    case "$PROFILE" in lite) default_index=1 ;; turbo) default_index=2 ;; esac
    if [[ "$PICKER_TTY" -eq 1 ]]; then
        pk_picker_single "Choose your profile" "Balanced is the recommended default. Turbo needs a second confirmation." "$default_index" \
            "Balanced — Recommended default; full workflow set" \
            "Lite — Six core workflows for a lighter setup" \
            "Turbo — Experimental parallel workflows; higher token cost"
        [[ "$PK_PICKER_ACTION" == cancel ]] && cancel_setup
        case "$PK_PICKER_RESULT" in
            0) PROFILE="balanced" ;;
            1) PROFILE="lite" ;;
            2)
                printf '\nTurbo is experimental and can use up to ~2x measured token cost.\n'
                read -r -p "Acknowledge this and enable Turbo? [y/N]: " choice
                [[ "$choice" =~ ^[Yy]$ ]] || { PROFILE="balanced"; PROFILE_SET=1; PROFILE_INTERACTIVE=1; return 0; }
                PROFILE="turbo"; EXPERIMENTAL=1 ;;
        esac
    else
        while true; do
            printf '\n◉ Profile\n  1) Balanced — Recommended default; full workflow set\n  2) Lite — Six core workflows\n  3) Turbo — Experimental; higher token cost\n'
            read -r -p "Choose 1-3 (Enter for Balanced, q to cancel): " choice
            [[ "$choice" =~ ^[Qq]$ ]] && cancel_setup
            case "$choice" in
                ""|1) PROFILE="balanced"; break ;;
                2) PROFILE="lite"; break ;;
                3)
                    read -r -p "Turbo is experimental and costs more. Continue? [y/N]: " choice
                    if [[ "$choice" =~ ^[Yy]$ ]]; then PROFILE="turbo"; EXPERIMENTAL=1; else PROFILE="balanced"; fi
                    break ;;
                *) attempts=$((attempts + 1)); printf 'Please enter 1, 2, or 3.\n'; [[ "$attempts" -lt 3 ]] || cancel_setup ;;
            esac
        done
    fi
    PROFILE_SET=1
    PROFILE_INTERACTIVE=1
}

choose_tracking() {
    local choice attempts=0 default_index=0
    case "$TRACKING" in github) default_index=1 ;; jira) default_index=2 ;; linear) default_index=3 ;; esac
    if [[ "$PICKER_TTY" -eq 1 ]]; then
        pk_picker_single "Choose task tracking" "Local works offline. GitHub can mirror local task records." "$default_index" \
            "Local Markdown — Recommended; stored in docs/tasks/" \
            "GitHub Issues — Requires GitHub setup" \
            "Jira — Manual import; no automatic push" \
            "Linear — Manual import; no automatic push"
        [[ "$PK_PICKER_ACTION" == cancel ]] && cancel_setup
        case "$PK_PICKER_RESULT" in
            0) TRACKING="local" ;;
            1) TRACKING="github" ;;
            2) TRACKING="jira" ;;
            3) TRACKING="linear" ;;
        esac
        if [[ "$TRACKING" == "local" ]]; then
            local defaults=""
            [[ "$TRACKING_PROJECTION" == "github" ]] && defaults=github
            pk_picker_multi "Local task projection" "Optional checkbox. Space toggles it; Enter keeps the setting." "$defaults" \
                github "Also project local tasks to GitHub Issues"
            [[ "$PK_PICKER_ACTION" == cancel ]] && cancel_setup
            TRACKING_PROJECTION="$PK_PICKER_RESULT"
        else
            TRACKING_PROJECTION=""
        fi
    else
        while true; do
            printf '\n▣ Task tracking\n  1) Local Markdown — Recommended; docs/tasks/\n  2) GitHub Issues\n  3) Jira — manual import\n  4) Linear — manual import\n  1,2) Local Markdown + GitHub projection\n'
            read -r -p "Choose 1-4 or 1,2 (Enter for Local, q to cancel): " choice
            [[ "$choice" =~ ^[Qq]$ ]] && cancel_setup
            case "$choice" in
                ""|1) TRACKING=local; TRACKING_PROJECTION=""; break ;;
                1,2|2,1) TRACKING=local; TRACKING_PROJECTION=github; break ;;
                2) TRACKING=github; TRACKING_PROJECTION=""; break ;;
                3) TRACKING=jira; TRACKING_PROJECTION=""; break ;;
                4) TRACKING=linear; TRACKING_PROJECTION=""; break ;;
                *) attempts=$((attempts + 1)); printf 'Please enter one of the listed choices exactly.\n'; [[ "$attempts" -lt 3 ]] || cancel_setup ;;
            esac
        done
    fi
    TRACKING_SET=1
    TRACKING_INTERACTIVE=1
}

choose_hosts() {
    local choice attempts=0 token invalid
    local -a ids=(claude opencode cursor gemini windsurf copilot cline trae aider)
    local -a labels=("Claude Code" "OpenCode" "Cursor" "Gemini CLI" "Windsurf" "GitHub Copilot" "Cline" "Trae" "Aider")
    if [[ "$PICKER_TTY" -eq 1 ]]; then
        local defaults
        if [[ "$HOST_INTERACTIVE" -eq 1 ]]; then
            defaults="$HOSTS"
            [[ "$defaults" == agents ]] && defaults=""
        else
            defaults="${DETECTED_HOSTS// /,}"
            [[ -n "$defaults" ]] || defaults=claude
        fi
        local picker_args=() i
        for i in "${!ids[@]}"; do picker_args+=("${ids[$i]}" "${labels[$i]}"); done
        pk_picker_multi "Choose AI hosts" "Space toggles host-specific files. Select none for universal AGENTS.md only." "$defaults" "${picker_args[@]}"
        [[ "$PK_PICKER_ACTION" == cancel ]] && cancel_setup
        HOSTS="$PK_PICKER_RESULT"
        [[ -n "$HOSTS" ]] || HOSTS=agents
    else
        while true; do
            printf '\n◆ AI hosts (comma-separated numbers; 0 = universal AGENTS.md only)\n'
            local i=0
            for token in "${ids[@]}"; do i=$((i + 1)); printf '  %s) %s\n' "$i" "${labels[$((i - 1))]}"; done
            printf '  Enter keeps detected hosts; if none are detected, Claude Code is the default.\n'
            read -r -p "Choose hosts (q to cancel): " choice
            [[ "$choice" =~ ^[Qq]$ ]] && cancel_setup
            if [[ -z "$choice" ]]; then HOSTS="${DETECTED_HOSTS// /,}"; [[ -n "$HOSTS" ]] || HOSTS=claude; break; fi
            if [[ "$choice" == 0 ]]; then HOSTS=agents; break; fi
            invalid=0; HOSTS=""
            IFS=',' read -r -a selected_numbers <<< "$choice"
            for token in "${selected_numbers[@]}"; do
                token="${token//[[:space:]]/}"
                if [[ ! "$token" =~ ^[1-9]$ ]] || [[ "$token" -gt "${#ids[@]}" ]]; then invalid=1; break; fi
                local host="${ids[$((token - 1))]}"
                [[ ",$HOSTS," == *",$host,"* ]] || HOSTS="${HOSTS:+$HOSTS,}$host"
            done
            [[ "$invalid" -eq 0 ]] && break
            attempts=$((attempts + 1)); printf 'Invalid choice. Enter only host numbers from 1 to %s.\n' "${#ids[@]}"
            [[ "$attempts" -lt 3 ]] || cancel_setup
        done
    fi
    HOST_SET=1
    HOST_INTERACTIVE=1
}

review_setup() {
    local selection selected_profile selected_tracking selected_hosts
    local -a items=() actions=()
    [[ "$PROFILE_INTERACTIVE" -eq 1 ]] && { items+=("Edit profile"); actions+=(profile); }
    [[ "$TRACKING_INTERACTIVE" -eq 1 ]] && { items+=("Edit task tracking"); actions+=(tracking); }
    [[ "$HOST_INTERACTIVE" -eq 1 ]] && { items+=("Edit AI hosts"); actions+=(hosts); }
    items+=("Install with these settings" "Cancel setup")
    actions+=(install cancel)
    while true; do
        selected_profile="$PROFILE"
        selected_tracking="$TRACKING${TRACKING_PROJECTION:+ + GitHub projection}"
        selected_hosts="${HOSTS//,/ · }"
        [[ "$HOSTS" == agents ]] && selected_hosts="Universal AGENTS.md only"
        if [[ "$PICKER_TTY" -eq 1 ]]; then
            local subtitle
            printf -v subtitle 'Profile: %s\nTask tracking: %s\nAI hosts: %s\n\nChoose a setting to edit, install, or cancel.' \
                "$selected_profile" "$selected_tracking" "$selected_hosts"
            pk_picker_single "Review setup" "$subtitle" "$((${#items[@]} - 2))" "${items[@]}"
            [[ "$PK_PICKER_ACTION" == cancel ]] && cancel_setup
            selection="${actions[$PK_PICKER_RESULT]}"
        else
            printf '\n◇ Review setup\n  Profile: %s\n  Task tracking: %s\n  AI hosts: %s\n' "$selected_profile" "$selected_tracking" "$selected_hosts"
            for selection in "${!items[@]}"; do printf '  %s) %s\n' "$((selection + 1))" "${items[$selection]}"; done
            read -r -p "Choose an option, or q to cancel: " selection
            [[ "$selection" =~ ^[Qq]$ ]] && cancel_setup
            if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#items[@]}" ]]; then
                printf 'Please choose one of the listed options.\n'
                continue
            fi
            selection="${actions[$((selection - 1))]}"
        fi
        case "$selection" in
            profile) PROFILE_SET=0; choose_profile ;;
            tracking) TRACKING_SET=0; choose_tracking ;;
            hosts) HOST_SET=0; choose_hosts ;;
            install) return 0 ;;
            cancel) cancel_setup ;;
        esac
    done
}

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
EXTRA_TARGETS=()
PROJECT_ROOT=""

# Canonical path resolution and containment verification (F04 - P2)
resolve_canonical_path() {
    local target="$1"
    if command -v realpath >/dev/null 2>&1; then
        local rp
        rp=$(realpath -m "$target" 2>/dev/null) && [[ -n "$rp" ]] && { echo "$rp"; return 0; }
    fi
    local p="$target"
    [[ "$p" != /* ]] && p="$PWD/$p"

    local hops=0
    while [[ $hops -lt 25 ]]; do
        hops=$((hops + 1))
        if [[ -L "$p" ]]; then
            local link parent
            link=$(readlink "$p") || break
            parent=$(dirname "$p")
            case "$link" in
                /*) p="$link" ;;
                *) p="$parent/$link" ;;
            esac
        else
            local parent base phys_parent
            parent=$(dirname "$p")
            base=$(basename "$p")
            if [[ -d "$parent" ]]; then
                phys_parent=$(builtin cd "$parent" 2>/dev/null && pwd -P)
                if [[ -n "$phys_parent" ]]; then
                    p="$phys_parent/$base"
                    [[ -L "$p" ]] && continue
                fi
            fi
            break
        fi
    done

    local IFS="/"
    read -r -a raw_parts <<< "$p"
    local norm_parts=()
    for part in "${raw_parts[@]}"; do
        if [[ -z "$part" || "$part" == "." ]]; then
            continue
        elif [[ "$part" == ".." ]]; then
            if [[ ${#norm_parts[@]} -gt 0 ]]; then
                unset 'norm_parts[${#norm_parts[@]}-1]'
                norm_parts=("${norm_parts[@]}")
            fi
        else
            norm_parts+=("$part")
        fi
    done
    local result=""
    for part in "${norm_parts[@]}"; do
        result="$result/$part"
    done
    echo "${result:-/}"
}

is_path_contained() {
    local root="$1"
    local target="$2"
    local canon_root canon_target
    canon_root=$(resolve_canonical_path "$root")
    canon_target=$(resolve_canonical_path "$target")
    canon_root="${canon_root%/}"
    if [[ "$canon_target" == "$canon_root" || "$canon_target" == "$canon_root"/* ]]; then
        return 0
    fi
    return 1
}

get_file_mode() {
    stat -L -c '%a' "$1" 2>/dev/null || stat -L -f '%Lp' "$1" 2>/dev/null || true
}

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
        --engine-version=*)
            if [[ ! -e "$SCRIPT_DIR/.git" ]]; then
                ENGINE_VERSION="${arg#--engine-version=}"
                validate_engine_identity
            fi
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
                /*|*../*|*..\\*)
                    echo -e "\033[0;31m[!] --target must be a project-relative path without '..': $TARGET_PATH\033[0m" >&2; exit 1
                    ;;
            esac
            EXTRA_TARGETS+=("$TARGET_PATH")
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
            echo -e "Interactive: Arrow keys move, Enter selects, Space toggles checkboxes, q cancels; final review lets you edit choices."
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
                    PROJECT_ROOT="$(cd "$arg" && pwd -P)"
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
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
    else
        PROJECT_ROOT="$(pwd -P)"
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
    if [[ -z "$installed_hosts" && -f "$PROJECT_ROOT/AGENTS.md" ]]; then
        installed_hosts="agents"
    fi
    if [[ -n "$installed_hosts" ]]; then
        HOSTS="$(echo "$installed_hosts" | tr ' ' ',')"
        HOST_SET=1
        echo -e "  Keeping installed hosts: $HOSTS (pass --host= or --reconfigure to change)"
    fi
fi

# Interactive TTY picker when no profile flag provided (visual decision for onboarding)
if [[ "$PROFILE_SET" -eq 0 && "$EXPERIMENTAL" -eq 0 || "$TRACKING_SET" -eq 0 ]]; then
    show_setup_banner
fi
if [[ "$PROFILE_SET" -eq 0 && "$EXPERIMENTAL" -eq 0 && "$PICKER_TTY" -eq 1 ]]; then
    choose_profile
fi

# Interactive tracker picker (visual decision for onboarding, step 2)
if [[ "$TRACKING_SET" -eq 0 && "$PICKER_TTY" -eq 1 ]]; then
    choose_tracking
fi

# Validate turbo requires experimental
if [[ "$PROFILE" == "turbo" && "$EXPERIMENTAL" -eq 0 ]]; then
    echo -e "\n\033[0;31m[!] --turbo requires --experimental flag\033[0m" >&2
    echo -e "   Turbo uses parallel subagent waves (up to ~2x measured token cost) and is experimental." >&2
    echo -e "   It still requires human approval for Level 3 (releases/tags/deploys)." >&2
    echo -e "   Run: ./init.sh --turbo --experimental [project-root]\n" >&2
    exit 1
fi

DOC_DIRS=(
    "docs/tasks"
    "docs/specs"
    "docs/adrs"
    "docs/tests"
)

PROJECT_PROFILE="$PROJECT_ROOT/PROMPTKIT.md"
TEMPLATE_PROFILE="$SCRIPT_DIR/templates/project-profile-template.md"
DESIGN_PROFILE="$PROJECT_ROOT/DESIGN.md"
DOCS_DIR="$PROJECT_ROOT/docs"
STATE_TRACKER="$DOCS_DIR/STATE.md"
TEMPLATE_STATE="$SCRIPT_DIR/templates/state-tracker-template.md"
GITHUB_DIR="$PROJECT_ROOT/.github"
PR_TEMPLATE_TARGET="$GITHUB_DIR/pull_request_template.md"
TEMPLATE_PR="$SCRIPT_DIR/templates/pull-request-template.md"
ISSUE_TEMPLATE_DIR="$GITHUB_DIR/ISSUE_TEMPLATE"
TASK_TEMPLATE_TARGET="$ISSUE_TEMPLATE_DIR/task.md"
TEMPLATE_TASK="$SCRIPT_DIR/templates/github-issue-template.md"

if [[ -f "$DESIGN_PROFILE" ]]; then
    echo -e "  \033[0;90m[✓] DESIGN.md detected (brand identity & anti-slop rules)\\033[0m"
fi

# 2. Host probing + selection (which AI assistants get directive files)
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
if [[ "$HOST_SET" -eq 0 && "$PICKER_TTY" -eq 0 ]]; then
    if [[ "$(echo "$DETECTED_HOSTS" | wc -w)" -eq 1 ]]; then
        HOSTS="$DETECTED_HOSTS"
        HOST_SET=1
    fi
fi
if [[ "$HOST_SET" -eq 0 && "$PICKER_TTY" -eq 1 ]]; then
    choose_hosts
fi

if [[ "$PROFILE_INTERACTIVE" -eq 1 || "$TRACKING_INTERACTIVE" -eq 1 || "$HOST_INTERACTIVE" -eq 1 ]]; then
    review_setup
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
    "CONVENTIONS.md"
)

is_managed_destination() {
    local candidate="$1"
    local canon_cand canon_m m
    canon_cand=$(resolve_canonical_path "$candidate")
    for m in "$PROJECT_PROFILE" "$STATE_TRACKER" "$PR_TEMPLATE_TARGET" "$TASK_TEMPLATE_TARGET"; do
        canon_m=$(resolve_canonical_path "$m")
        if [[ "$canon_cand" == "$canon_m" ]]; then
            return 0
        fi
    done
    return 1
}

add_target_unique() {
    local want="$1"
    local canon_want canon_t t
    canon_want=$(resolve_canonical_path "$want")
    for t in "${TARGETS_FOUND[@]}"; do
        canon_t=$(resolve_canonical_path "$t")
        if [[ "$canon_t" == "$canon_want" ]]; then
            return 1
        fi
    done
    TARGETS_FOUND+=("$want")
    return 0
}

TARGETS_FOUND=()
for file in "${AGENT_FILES[@]}"; do
    target_path="$PROJECT_ROOT/$file"
    if [[ -d "$target_path" ]]; then
        if [[ "$file" == ".clinerules" ]]; then
            add_target_unique "$target_path/promptkit.md" || true
        fi
    elif [[ -f "$target_path" ]]; then
        add_target_unique "$target_path" || true
    fi
done

# Custom --target paths (F06 - P2)
if [[ ${#EXTRA_TARGETS[@]} -gt 0 ]]; then
    for xp in "${EXTRA_TARGETS[@]}"; do
        xfull="$PROJECT_ROOT/$xp"
        if is_managed_destination "$xfull"; then
            echo "Error: Custom target cannot be a managed PromptKit OS file: $xp" >&2
            exit 1
        fi
        if [[ -d "$xfull" ]]; then
            echo "Error: Target destination cannot be a directory: $xp" >&2
            exit 1
        fi
        if add_target_unique "$xfull"; then
            echo -e "  \033[0;32m[+]\\033[0m Added custom target: $xp"
        fi
    done
fi

ensure_target() {
    local rel="$1"
    local want="$PROJECT_ROOT/$rel"
    if [[ "$rel" == ".clinerules" ]]; then
        if [[ -f "$want" ]]; then
            :
        elif [[ -d "$want" ]]; then
            want="$want/promptkit.md"
        else
            want="$want/promptkit.md"
        fi
    fi
    add_target_unique "$want"
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

# 4. Containment Verification (F04 - P2)
ALL_DESTINATIONS=("$PROJECT_PROFILE" "$STATE_TRACKER" "$PR_TEMPLATE_TARGET" "$TASK_TEMPLATE_TARGET" "${TARGETS_FOUND[@]}")
for dest in "${ALL_DESTINATIONS[@]}"; do
    if ! is_path_contained "$PROJECT_ROOT" "$dest"; then
        rel_dest="${dest#$PROJECT_ROOT/}"
        echo "Error: Target destination escapes project root: $rel_dest" >&2
        exit 1
    fi
done

# 5. Directive Block Template Preparation
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
    KIT_DIR_REL_SED="$(sed_replacement_escape "$KIT_DIR_REL")"
    ENGINE_VERSION_SED="$(sed_replacement_escape "$ENGINE_VERSION")"
    ENGINE_SHA_SED="$(sed_replacement_escape "$ENGINE_SHA")"
    DIRECTIVE="$(sed \
        -e "s|\\\$KIT_DIR_REL|$KIT_DIR_REL_SED|g" \
        -e "s|\\\$ENGINE_VERSION|$ENGINE_VERSION_SED|g" \
        -e "s|\\\$ENGINE_SHA|$ENGINE_SHA_SED|g" \
        "$TEMPLATE_DIRECTIVE")"
else
    echo "Error: Canonical directive template not found at $TEMPLATE_DIRECTIVE" >&2
    exit 1
fi

# 6. Pre-validation and Transformation Staging (F07 - P2)
STAGING_DIR="$(mktemp -d)"
cleanup_staging_only() {
    rm -rf "$STAGING_DIR"
}
trap cleanup_staging_only EXIT

declare -a STAGED_TARGET_PATHS=()
declare -a STAGED_TARGET_MODES=()

target_idx=0
for target in "${TARGETS_FOUND[@]}"; do
    REL_TARGET="${target#$PROJECT_ROOT/}"
    CR=$'\r'
    has_start=0
    has_end=0
    if [[ -f "$target" ]]; then
        if grep -qE "^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*${CR}?$" "$target" 2>/dev/null; then has_start=1; fi
        if grep -qE "^[[:space:]]*<!-- PROMPTKIT_END -->[[:space:]]*${CR}?$" "$target" 2>/dev/null; then has_end=1; fi
    fi

    staged_target="$STAGING_DIR/target_$target_idx"
    target_idx=$((target_idx + 1))

    if [[ "$has_start" -eq 1 || "$has_end" -eq 1 ]]; then
        start_count="$(grep -E -c "^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*${CR}?$" "$target" 2>/dev/null || true)"
        end_count="$(grep -E -c "^[[:space:]]*<!-- PROMPTKIT_END -->[[:space:]]*${CR}?$" "$target" 2>/dev/null || true)"
        if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
            echo "Error: Cannot safely update $REL_TARGET: expected exactly one complete PromptKit directive block with START before END." >&2
            exit 1
        fi
        first_start="$(grep -n -E "^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*${CR}?$" "$target" | head -n 1 | cut -d: -f1)"
        first_end="$(grep -n -E "^[[:space:]]*<!-- PROMPTKIT_END -->[[:space:]]*${CR}?$" "$target" | head -n 1 | cut -d: -f1)"
        if [[ "$first_start" -ge "$first_end" ]]; then
            echo "Error: Cannot safely update $REL_TARGET: expected exactly one complete PromptKit directive block with START before END." >&2
            exit 1
        fi

        directive_file="$(mktemp "$STAGING_DIR/directive.XXXXXX")"
        printf '%s\n' "$DIRECTIVE" > "$directive_file"

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
            /^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*\r?$/ {
                print directive
                inside = 1
                next
            }
            /^[[:space:]]*<!-- PROMPTKIT_END -->[[:space:]]*\r?$/ && inside {
                inside = 0
                next
            }
            !inside { print }
            END {
                if (inside) exit 1
            }
        ' "$target" > "$staged_target"; then
            rm -f "$staged_target" "$directive_file"
            echo "Error: Unable to safely update $REL_TARGET; the original file was preserved. Update it manually." >&2
            exit 1
        fi
        rm -f "$directive_file"
        STAGED_TARGET_PATHS+=("$staged_target")
        STAGED_TARGET_MODES+=("update")
    elif [[ -f "$target" ]]; then
        cp "$target" "$staged_target"
        if [[ -s "$staged_target" ]]; then
            printf "\n\n%s\n" "$DIRECTIVE" >> "$staged_target"
        else
            printf "%s\n" "$DIRECTIVE" > "$staged_target"
        fi
        STAGED_TARGET_PATHS+=("$staged_target")
        STAGED_TARGET_MODES+=("inject")
    else
        printf "%s\n" "$DIRECTIVE" > "$staged_target"
        STAGED_TARGET_PATHS+=("$staged_target")
        STAGED_TARGET_MODES+=("create")
    fi
done

# Stage PROMPTKIT.md
STAGED_PROFILE="$STAGING_DIR/PROMPTKIT.md"
if [[ -f "$PROJECT_PROFILE" ]]; then
    cp "$PROJECT_PROFILE" "$STAGED_PROFILE"
elif [[ -f "$TEMPLATE_PROFILE" ]]; then
    cp "$TEMPLATE_PROFILE" "$STAGED_PROFILE"
else
    touch "$STAGED_PROFILE"
fi

set_staged_machine_field() {
    local target_file="$1" field_name="$2" field_value="$3" tmp_file
    tmp_file=$(mktemp "$STAGING_DIR/tmp_field.XXXXXX")
    grep -v "^${field_name}:" "$target_file" > "$tmp_file" || true
    printf '%s: %s\n' "$field_name" "$field_value" >> "$tmp_file"
    cat "$tmp_file" > "$target_file" && rm -f "$tmp_file"
}

if grep -q "^profile:" "$STAGED_PROFILE" 2>/dev/null; then
    set_staged_machine_field "$STAGED_PROFILE" "profile" "$PROFILE"
    if grep -q '^- \*\*Profile\*\*:' "$STAGED_PROFILE" 2>/dev/null; then
        if sed --version >/dev/null 2>&1; then
            sed -i "s/^- \*\*Profile\*\*:.*/- **Profile**: $PROFILE/" "$STAGED_PROFILE"
        else
            sed -i.bak "s/^- \*\*Profile\*\*:.*/- **Profile**: $PROFILE/" "$STAGED_PROFILE" && rm -f "$STAGED_PROFILE.bak"
        fi
    fi
    if grep -q '^- \*\*Installed\*\*:' "$STAGED_PROFILE" 2>/dev/null; then
        if sed --version >/dev/null 2>&1; then
            sed -i "s/^- \*\*Installed\*\*:.*/- **Installed**: $(date +%Y-%m-%d)/" "$STAGED_PROFILE"
        else
            sed -i.bak "s/^- \*\*Installed\*\*:.*/- **Installed**: $(date +%Y-%m-%d)/" "$STAGED_PROFILE" && rm -f "$STAGED_PROFILE.bak"
        fi
    fi
else
    TMP_P=$(mktemp "$STAGING_DIR/prof_sec.XXXXXX")
    {
        head -n 1 "$STAGED_PROFILE"
        echo ""
        echo "## 0. PromptKit OS Profile"
        echo "- **Profile**: $PROFILE"
        echo "- **Installed**: $(date +%Y-%m-%d)"
        echo "- **Engine**: \`$DIR_NAME\`"
        echo "- **Upgrade**: Run \`$DIR_NAME/init.sh --balanced\` for the full Balanced profile, or \`--turbo --experimental\` for parallel waves"
        echo ""
        tail -n +2 "$STAGED_PROFILE"
        echo ""
    } > "$TMP_P"
    mv "$TMP_P" "$STAGED_PROFILE"
    set_staged_machine_field "$STAGED_PROFILE" "profile" "$PROFILE"
fi
set_staged_machine_field "$STAGED_PROFILE" "tracking" "$TRACKING"
if [ -n "$TRACKING_PROJECTION" ]; then
    set_staged_machine_field "$STAGED_PROFILE" "projection" "$TRACKING_PROJECTION"
else
    if grep -q "^projection:" "$STAGED_PROFILE" 2>/dev/null; then
        PROJ_TMP=$(mktemp "$STAGING_DIR/proj.XXXXXX")
        grep -v "^projection:" "$STAGED_PROFILE" > "$PROJ_TMP" || true
        cat "$PROJ_TMP" > "$STAGED_PROFILE" && rm -f "$PROJ_TMP"
    fi
fi

# 7. Transactional Commit with Rollback (F07 - P2, F10 - P2, R5 - P2)
BACKUP_DIR="$(mktemp -d)"
declare -a CREATED_FILES=()
declare -a BACKED_UP_FILES=()
declare -a BACKUP_SOURCES=()

rollback() {
    local i
    for (( i=${#CREATED_FILES[@]}-1; i>=0; i-- )); do
        rm -f "${CREATED_FILES[i]}"
    done
    for (( i=0; i<${#BACKED_UP_FILES[@]}; i++ )); do
        local orig="${BACKED_UP_FILES[i]}"
        local bkp="${BACKUP_SOURCES[i]}"
        if [[ -f "$bkp" ]]; then
            cp -p "$bkp" "$orig"
        fi
    done
    rm -rf "$BACKUP_DIR" "$STAGING_DIR"
}

COMMIT_SUCCESS=0
trap 'if [[ "$COMMIT_SUCCESS" -eq 0 ]]; then rollback; else rm -rf "$BACKUP_DIR" "$STAGING_DIR"; fi' EXIT

# Snapshot all existing destinations ONCE before ANY disk mutation begins (R5 - P2)
if [[ -f "$PROJECT_PROFILE" ]]; then
    bkp="$BACKUP_DIR/PROMPTKIT.md"
    cp -p "$PROJECT_PROFILE" "$bkp"
    BACKED_UP_FILES+=("$PROJECT_PROFILE")
    BACKUP_SOURCES+=("$bkp")
fi

for (( i=0; i<${#TARGETS_FOUND[@]}; i++ )); do
    target="${TARGETS_FOUND[i]}"
    if [[ -f "$target" || -L "$target" ]]; then
        canon_t=$(resolve_canonical_path "$target")
        already_snapshotted=0
        for (( j=0; j<${#BACKED_UP_FILES[@]}; j++ )); do
            if [[ "$(resolve_canonical_path "${BACKED_UP_FILES[j]}")" == "$canon_t" ]]; then
                already_snapshotted=1
                break
            fi
        done
        if [[ "$already_snapshotted" -eq 0 ]]; then
            bkp="$BACKUP_DIR/target_$i"
            cp -p "$target" "$bkp"
            BACKED_UP_FILES+=("$target")
            BACKUP_SOURCES+=("$bkp")
        fi
    fi
done

# STATE.md is mutated in place rather than staged, so it belongs in the transaction even
# though it is not a staged target. Without this, a failure after the stamp pass restores
# PROMPTKIT.md and the host targets but leaves an already-stamped STATE.md behind.
if [[ -f "$STATE_TRACKER" ]]; then
    already_snapshotted=0
    state_canon="$(resolve_canonical_path "$STATE_TRACKER")"
    for (( j=0; j<${#BACKED_UP_FILES[@]}; j++ )); do
        if [[ "$(resolve_canonical_path "${BACKED_UP_FILES[j]}")" == "$state_canon" ]]; then
            already_snapshotted=1
            break
        fi
    done
    if [[ "$already_snapshotted" -eq 0 ]]; then
        bkp="$BACKUP_DIR/STATE.md"
        cp -p "$STATE_TRACKER" "$bkp"
        BACKED_UP_FILES+=("$STATE_TRACKER")
        BACKUP_SOURCES+=("$bkp")
    fi
fi

# Ensure doc directories exist
for dir in "${DOC_DIRS[@]}"; do
    if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
        mkdir -p "$PROJECT_ROOT/$dir"
        echo -e "  \033[0;32m[+]\\033[0m Created directory: $dir"
    fi
done

# Commit PROMPTKIT.md
if [[ -f "$PROJECT_PROFILE" ]]; then
    prof_mode="$(get_file_mode "$PROJECT_PROFILE")"
    cp "$STAGED_PROFILE" "$PROJECT_PROFILE"
    if [[ -n "$prof_mode" ]]; then chmod "$prof_mode" "$PROJECT_PROFILE" 2>/dev/null || true; fi
    echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md profile: $PROFILE"
    echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md tracking: $TRACKING"
    if [ -n "$TRACKING_PROJECTION" ]; then
        echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md projection: $TRACKING_PROJECTION"
    fi
else
    CREATED_FILES+=("$PROJECT_PROFILE")
    cp "$STAGED_PROFILE" "$PROJECT_PROFILE"
    echo -e "  \033[0;32m[+]\\033[0m Created: PROMPTKIT.md (project profile & guardrails)"
    echo -e "  \033[0;32m[+]\\033[0m Set PROMPTKIT.md profile: $PROFILE"
    echo -e "  \033[0;33m[✓]\\033[0m Updated PROMPTKIT.md tracking: $TRACKING"
fi

# Commit scaffolds
if [[ ! -f "$STATE_TRACKER" && -f "$TEMPLATE_STATE" ]]; then
    mkdir -p "$DOCS_DIR"
    CREATED_FILES+=("$STATE_TRACKER")
    cp "$TEMPLATE_STATE" "$STATE_TRACKER"
    echo -e "  \033[0;32m[+]\\033[0m Created: docs/STATE.md (living project & state tracker)"
fi
# STATE.md is copied verbatim, not substituted, so it needs its own stamp pass. A STATE.md
# that predates this feature has no Engine Version row at all, so insert one after the Last
# Updated row instead of skipping the file forever; a file carrying neither anchor is left
# untouched rather than guessed at.
if [[ -f "$STATE_TRACKER" ]]; then
    STAMP_ROW="- **Engine Version**: $ENGINE_VERSION @ $ENGINE_SHA"
    if grep -q '^- \*\*Engine Version\*\*:' "$STATE_TRACKER" 2>/dev/null; then
        STAMP_VALUE="$(sed_replacement_escape "$STAMP_ROW")"
        if sed --version >/dev/null 2>&1; then
            sed -i "s|^- \*\*Engine Version\*\*:.*|$STAMP_VALUE|" "$STATE_TRACKER"
        else
            sed -i.bak "s|^- \*\*Engine Version\*\*:.*|$STAMP_VALUE|" "$STATE_TRACKER" && rm -f "$STATE_TRACKER.bak"
        fi
    elif grep -q '^- \*\*Last Updated\*\*:' "$STATE_TRACKER" 2>/dev/null; then
        STATE_STAMP_TMP="$(mktemp "$STAGING_DIR/state_stamp.XXXXXX")"
        awk -v row="$STAMP_ROW" '{ print } /^- \*\*Last Updated\*\*:/ && !done { print row; done = 1 }' \
            "$STATE_TRACKER" > "$STATE_STAMP_TMP"
        cat "$STATE_STAMP_TMP" > "$STATE_TRACKER"
        rm -f "$STATE_STAMP_TMP"
    fi
fi
if [[ ! -f "$PR_TEMPLATE_TARGET" && -f "$TEMPLATE_PR" ]]; then
    mkdir -p "$GITHUB_DIR"
    CREATED_FILES+=("$PR_TEMPLATE_TARGET")
    cp "$TEMPLATE_PR" "$PR_TEMPLATE_TARGET"
    echo -e "  \033[0;32m[+]\\033[0m Created: .github/pull_request_template.md (staff-level PR specification)"
fi
if [[ ! -f "$TASK_TEMPLATE_TARGET" && -f "$TEMPLATE_TASK" ]]; then
    mkdir -p "$ISSUE_TEMPLATE_DIR"
    CREATED_FILES+=("$TASK_TEMPLATE_TARGET")
    cp "$TEMPLATE_TASK" "$TASK_TEMPLATE_TARGET"
    echo -e "  \033[0;32m[+]\\033[0m Created: .github/ISSUE_TEMPLATE/task.md (standard task specification)"
fi

# Commit targets
for (( i=0; i<${#TARGETS_FOUND[@]}; i++ )); do
    target="${TARGETS_FOUND[i]}"
    staged_file="${STAGED_TARGET_PATHS[i]}"
    mode="${STAGED_TARGET_MODES[i]}"
    REL_TARGET="${target#$PROJECT_ROOT/}"

    mkdir -p "$(dirname "$target")"
    if [[ -f "$target" || -L "$target" ]]; then
        t_mode="$(get_file_mode "$target")"
        cp "$staged_file" "$target"
        if [[ -n "$t_mode" ]]; then chmod "$t_mode" "$target" 2>/dev/null || true; fi
    else
        CREATED_FILES+=("$target")
        cp "$staged_file" "$target"
    fi

    if [[ "$mode" == "update" ]]; then
        echo -e "  \033[0;33m[✓]\\033[0m Updated PromptKit OS directives in: $REL_TARGET (profile: $PROFILE)"
    else
        echo -e "  \033[0;32m[+]\\033[0m Injected PromptKit OS directives into: $REL_TARGET (profile: $PROFILE)"
    fi
done

COMMIT_SUCCESS=1

# 8. Install-door structural assert (#549). Must stay after COMMIT_SUCCESS=1 and
# before the banner: a non-zero result fails the install without rolling back.
ASSERT_RC=0
bash "$SCRIPT_DIR/scripts/check-setup-assert.sh" "$PROJECT_ROOT" "$SCRIPT_DIR" "$KIT_DIR_REL" || ASSERT_RC=$?
if [[ "$ASSERT_RC" -eq 1 ]]; then
    exit 1
fi
if [[ "$ASSERT_RC" -ne 0 ]]; then
    if [[ "$ASSERT_RC" -ne 2 ]]; then
        printf 'ASSERT|unknown|checker|INCOMPLETE\n'
    fi
    exit 2
fi

echo -e "\n\033[0;36m✨ PromptKit OS successfully configured for $PROJECT_ROOT! ($PROFILE profile)\033[0m"
if [[ "$PROFILE" == "lite" ]]; then
    echo -e "   \033[0;32mLite: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) — 80% value, <1,500 tok\033[0m"
    echo -e "   Upgrade anytime: .promptkit/init.sh --balanced for the full Balanced profile"
elif [[ "$PROFILE" == "balanced" ]]; then
    echo -e "   Balanced: 26 workflows, Level 0-3 adaptive ceremony — full power"
    echo -e "   For onboarding: .promptkit/init.sh --lite for minimal setup"
else
    echo -e "   \033[0;33mTurbo (Experimental): Balanced + parallel waves, up to ~2x measured token cost\033[0m"
    echo -e "   Human approval still required for Level 3 (releases/tags/deploys)"
fi
echo -e "   Start by asking your AI: 'pk:route', 'pk:debug', 'pk:commit', 'pk:checkpoint'\n"
