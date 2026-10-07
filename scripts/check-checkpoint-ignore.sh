#!/usr/bin/env bash
# Read-only gitignore preflight for pk:checkpoint targets.
# Usage: scripts/check-checkpoint-ignore.sh [--root PATH] [--targets-file PATH]
#
# Reports checkpoint artifacts that Git cannot see because an ignore rule
# matches them. It never stages, force-adds, commits, resets, or un-ignores
# anything: the matching rule is surfaced as evidence and the author decides.

set -uo pipefail
export LC_ALL=C

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || exit 2
root="."
targets_file=""

usage() {
    cat >&2 <<'EOF'
Usage: scripts/check-checkpoint-ignore.sh [--root PATH] [--targets-file PATH]
EOF
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --root)
            [[ "$#" -ge 2 ]] || { usage; exit 2; }
            root="$2"
            shift 2
            ;;
        --root=*)
            root="${1#*=}"
            shift
            ;;
        --targets-file)
            [[ "$#" -ge 2 ]] || { usage; exit 2; }
            targets_file="$2"
            shift 2
            ;;
        --targets-file=*)
            targets_file="${1#*=}"
            shift
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

[[ -n "$targets_file" ]] || targets_file="$script_dir/checkpoint-targets.txt"

# Fail closed on an unreadable rules file before measuring anything.
if [[ ! -f "$targets_file" || ! -r "$targets_file" ]]; then
    printf 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|.\n'
    exit 2
fi

if [[ ! -d "$root" || -L "$root" ]]; then
    printf 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
fi
root=$(builtin cd -- "$root" && pwd -P) || {
    printf 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
}

if [[ ! -e "$root/.git" ]]; then
    printf 'CHECKPOINT_IGNORE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
fi

local_git() {
    GIT_OPTIONAL_LOCKS=0 git --git-dir="$root/.git" --work-tree="$root" \
        -c core.fsmonitor=false "$@" 2>/dev/null
}

sanitize() {
    printf '%s' "$1" | tr '\r\n|' '   '
}

policy_lines=""
scanned=0
ignored=0

emit_policy() {
    policy_lines="${policy_lines}${1}"$'\n'
}

emit_incomplete() {
    # Print any evidence already gathered, then the single INCOMPLETE summary.
    # A success summary is never printed on an unmeasured result.
    [[ -z "$policy_lines" ]] || printf '%s' "$policy_lines"
    printf 'CHECKPOINT_IGNORE|INCOMPLETE|%s|%s\n' "$1" "$2"
    exit 2
}

check_target() {
    local relative="$1" rule out status
    scanned=$((scanned + 1))
    # No --no-index: a tracked file is visible to git and must not be reported
    # as ignored. Three-way branch on the exit status, fail closed otherwise.
    out=$(local_git check-ignore -v -- "$relative")
    status=$?
    case "$status" in
        0)
            rule=${out%%$'\t'*}
            emit_policy "POLICY_LIMITATION|CHECKPOINT_IGNORE|$(sanitize "$relative")|Checkpoint target is ignored by $(sanitize "$rule")|Author may add a ! negation exception or relocate the artifact; pk:checkpoint does not stage, force-add, or un-ignore"
            ignored=$((ignored + 1))
            ;;
        1)
            : ;;
        *)
            emit_incomplete GIT_IGNORE "$(sanitize "$relative")"
            ;;
    esac
}

# Strict row validation, fail closed. After the blank/comment skip every row
# must be `path|file` or `path|dir`; a malformed row aborts the whole scan
# before any target is measured, so a typo cannot silently narrow coverage.
target_rows=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" == '#'* ]] && continue
    if [[ ! "$line" =~ ^[^|]+\|(file|dir)$ ]]; then
        printf 'CHECKPOINT_IGNORE|INCOMPLETE|RULES|%s\n' "$(sanitize "$line")"
        exit 2
    fi
    target_rows+=("$line")
done < "$targets_file"

if [[ "${#target_rows[@]}" -gt 0 ]]; then
    for line in "${target_rows[@]}"; do
        relative=${line%%|*}
        kind=${line##*|}
        case "$kind" in
            file)
                check_target "$relative"
                ;;
            dir)
                # Probe the directory itself first (path with one trailing
                # slash) so an ignored, empty, or not-yet-existing records
                # directory is still measured; then each existing direct *.md
                # record, sorted by the glob.
                probe_dir=$relative
                while [[ "$probe_dir" == */ ]]; do probe_dir=${probe_dir%/}; done
                check_target "$probe_dir/"
                shopt -s nullglob
                for entry in "$root/$relative"/*.md; do
                    [[ -f "$entry" ]] || continue
                    check_target "$relative/${entry##*/}"
                done
                shopt -u nullglob
                ;;
        esac
    done
fi

if [[ "$ignored" -gt 0 ]]; then
    printf '%s' "$policy_lines"
    printf 'CHECKPOINT_IGNORE|DEGRADED|IGNORED=%s|SCANNED=%s\n' "$ignored" "$scanned"
    exit 0
fi
printf 'CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=%s\n' "$scanned"
exit 0
