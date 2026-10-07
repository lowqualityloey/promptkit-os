#!/usr/bin/env bash
# Read-only install-door structural assert for the PromptKit OS kit tree.
#
# Usage: scripts/check-setup-assert.sh <project-root> <kit-dir> <kit-dir-rel>
#
# The installer calls this after a successful commit and before printing the
# success banner. It classifies which documented install door produced the kit
# tree and asserts only what is structurally true for that door, so a partial
# copy or a broken submodule registration fails loudly instead of printing
# success. It is read-only: it never stages, commits, mutates the index, or
# touches the network.
#
# Doors: standalone | courier | direct-clone | submodule | partial-copy | tracked-content.
# `partial-copy` is the incomplete-tree outcome: any install missing a required
# engine file. A partial copy is never a passing door.
#
# Records (one per line, `|`-delimited; CR, LF and `|` are replaced with spaces
# in the free-text remedy field only):
#   ASSERT|<door>|missing:<path>|FAIL
#   ASSERT|<door>|<check>|OK|FAIL|INCOMPLETE|SKIP
#   ASSERT|skipped|USER_OPT_OUT|SKIP             (PROMPTKIT_NO_PREFLIGHT=1)
#   ASSERT|<door>|remedy|<prose>                 (human remedy; field 4 is text)
#
# Exit: 0 = OK or explicit opt-out, 1 = structural FAIL, 2 = INCOMPLETE.
# FAIL is an observed structural mismatch the author can fix. INCOMPLETE means
# the condition could not be measured (git missing, an unexpected git status,
# an unreadable manifest); an unmeasured result is never reported as OK.

set -uo pipefail
export LC_ALL=C

project_root="${1:-}"
kit_dir="${2:-}"
kit_rel="${3:-}"

verdict() { printf 'ASSERT|%s|%s|%s\n' "$1" "$2" "$3"; }
sanitize() { printf '%s' "$1" | tr '\r\n|' '   '; }
remedy() { printf 'ASSERT|%s|remedy|%s\n' "$1" "$(sanitize "$2")"; }

if [[ -z "$project_root" || -z "$kit_dir" ]]; then
    verdict unknown args INCOMPLETE
    exit 2
fi

if [[ "${PROMPTKIT_NO_PREFLIGHT:-}" == "1" ]]; then
    verdict skipped USER_OPT_OUT SKIP
    exit 0
fi

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || { verdict unknown rules INCOMPLETE; exit 2; }
manifest="$script_dir/setup-assert-files.txt"
if [[ ! -f "$manifest" || ! -r "$manifest" ]]; then
    verdict unknown rules INCOMPLETE
    exit 2
fi

# Strict row validation, fail closed before measuring anything.
manifest_rows=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" == '#'* ]] && continue
    if [[ ! "$line" =~ ^[^|]+\|(file|dir)$ ]]; then
        verdict unknown rules INCOMPLETE
        exit 2
    fi
    manifest_rows+=("$line")
done < "$manifest"

kit_canon=$(builtin cd -- "$kit_dir" 2>/dev/null && pwd -P) || { verdict unknown kit_metadata INCOMPLETE; exit 2; }
project_canon=""
if [[ -n "$project_root" && -d "$project_root" ]]; then
    project_canon=$(builtin cd -- "$project_root" && pwd -P) || project_canon=""
fi

missing=()
if [[ "${#manifest_rows[@]}" -gt 0 ]]; then
    for row in "${manifest_rows[@]}"; do
        rel=${row%%|*}
        kind=${row##*|}
        case "$kind" in
            file) [[ -f "$kit_dir/$rel" ]] || missing+=("$rel") ;;
            dir)  [[ -d "$kit_dir/$rel" ]] || missing+=("$rel") ;;
        esac
    done
fi

fail_missing() {
    local door="$1" m
    if [[ "${#missing[@]}" -gt 0 ]]; then
        for m in "${missing[@]}"; do
            verdict "$door" "missing:$m" FAIL
        done
    fi
    remedy "$door" "Restore the missing file(s) above, or reinstall via a documented method: npx promptkit-os@latest, git submodule update --remote --merge $kit_rel, or a full engine-tree copy"
    exit 1
}

# Standalone vault: the kit root is the project root. Classified before any git
# probe, because a checkout carries its own .git and must not read as a clone.
if [[ -n "$project_canon" && "$kit_canon" == "$project_canon" ]]; then
    if [[ "${#missing[@]}" -eq 0 ]]; then
        verdict standalone tree OK
        exit 0
    fi
    fail_missing standalone
fi

# Tree completeness is a property of every door, not only the courier: an
# incomplete tree is the partial-copy outcome regardless of any .git present.
if [[ "${#missing[@]}" -gt 0 ]]; then
    fail_missing partial-copy
fi

# No .git in the kit: a complete non-git tree is the courier (tarball) door.
if [[ ! -e "$kit_dir/.git" ]]; then
    verdict courier tree OK
    exit 0
fi

# The kit carries its own .git. Everything below needs a working git.
if ! command -v git >/dev/null 2>&1; then
    verdict unknown git_unavailable INCOMPLETE
    exit 2
fi

# Scoped, read-only probes. `-C` is used instead of `--git-dir="$root/.git"`
# because a worktree host has a .git file, which the --git-dir form cannot read.
host_git() { GIT_OPTIONAL_LOCKS=0 git -C "$project_canon" -c core.fsmonitor=false "$@" 2>/dev/null; }
kit_git()  { GIT_OPTIONAL_LOCKS=0 git -C "$kit_canon" -c core.fsmonitor=false "$@" 2>/dev/null; }

gitmodules_lists_kit() {
    [[ -n "$project_canon" && -f "$project_canon/.gitmodules" ]] || return 1
    local out line path
    out=$(git config -f "$project_canon/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null) || return 1
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        path=${line##* }
        [[ "$path" == "$kit_rel" ]] && return 0
    done <<< "$out"
    return 1
}

host_repo=0
if [[ -n "$project_canon" ]]; then
    host_git rev-parse --git-dir >/dev/null 2>&1
    rc=$?
    case "$rc" in
        0) host_repo=1 ;;
        128) host_repo=0 ;;
        *) verdict unknown host_git INCOMPLETE; exit 2 ;;
    esac
fi

door=""
if [[ "$host_repo" -eq 1 ]]; then
    index_out=$(host_git ls-files -s -- "$kit_rel")
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        verdict unknown host_index INCOMPLETE
        exit 2
    fi
    entry_mode=""
    if [[ -n "$index_out" ]]; then
        while IFS=$'\t' read -r meta path; do
            [[ "$path" == "$kit_rel" ]] || continue
            entry_mode=${meta%% *}
            break
        done <<< "$index_out"
    fi
    if [[ -n "$entry_mode" ]]; then
        case "$entry_mode" in
            160000)
                if ! gitmodules_lists_kit; then
                    verdict submodule gitmodules FAIL
                    remedy submodule "A gitlink is staged for $kit_rel but .gitmodules does not register that path; re-run git submodule update --init --recursive $kit_rel or remove the stale index entry"
                    exit 1
                fi
                door=submodule
                ;;
            100644|100755)
                verdict tracked-content "mode:$entry_mode" FAIL
                remedy tracked-content "The host tracks $kit_rel as regular content while the kit carries its own .git; remove the nested .git or register the path as a submodule"
                exit 1
                ;;
            *)
                verdict unknown "mode:$entry_mode" INCOMPLETE
                exit 2
                ;;
        esac
    elif gitmodules_lists_kit; then
        verdict submodule staged FAIL
        remedy submodule ".gitmodules registers $kit_rel but no gitlink is staged; run git submodule update --init --recursive $kit_rel"
        exit 1
    else
        door=direct-clone
    fi
else
    door=direct-clone
fi

if [[ "$door" == "submodule" ]]; then
    sub_out=$(host_git submodule status -- "$kit_rel")
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        verdict submodule status INCOMPLETE
        exit 2
    fi
    prefix=${sub_out:0:1}
    case "$prefix" in
        ' ')
            verdict submodule status OK
            exit 0
            ;;
        '-')
            verdict submodule status FAIL
            remedy submodule "Submodule $kit_rel is not initialized; run git submodule update --remote --merge $kit_rel"
            exit 1
            ;;
        '+')
            verdict submodule status FAIL
            remedy submodule "Submodule $kit_rel is out of sync with the recorded commit; run git submodule update --remote --merge $kit_rel"
            exit 1
            ;;
        'U')
            verdict submodule status FAIL
            remedy submodule "Submodule $kit_rel has unresolved merge conflicts; resolve them or re-run git submodule update --remote --merge $kit_rel"
            exit 1
            ;;
        '?')
            verdict submodule status FAIL
            remedy submodule "Submodule $kit_rel is not registered as expected; re-run git submodule update --init --recursive $kit_rel"
            exit 1
            ;;
        *)
            verdict submodule status INCOMPLETE
            exit 2
            ;;
    esac
fi

if [[ "$door" == "direct-clone" ]]; then
    top=$(kit_git rev-parse --show-toplevel)
    rc=$?
    if [[ "$rc" -eq 128 ]]; then
        verdict direct-clone repository FAIL
        remedy direct-clone "The kit .git is present but does not resolve to a valid repository; restore the clone or reinstall"
        exit 1
    fi
    if [[ "$rc" -ne 0 ]]; then
        verdict unknown git_probe INCOMPLETE
        exit 2
    fi
    top_canon=$(builtin cd -- "$top" 2>/dev/null && pwd -P) || top_canon=""
    if [[ -n "$top_canon" && "$top_canon" == "$kit_canon" ]]; then
        verdict direct-clone repository OK
        exit 0
    fi
    verdict direct-clone repository FAIL
    remedy direct-clone "The kit resolves to a different repository root ($top); restore the direct clone"
    exit 1
fi

# Unreachable: every branch above exits.
verdict unknown classify INCOMPLETE
exit 2
