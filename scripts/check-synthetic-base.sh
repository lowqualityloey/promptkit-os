#!/usr/bin/env bash
# Read-only synthetic-base preflight.
# Usage: scripts/check-synthetic-base.sh [--root PATH] [--commit REF] [--signals-file PATH]
#
# Refuses to let a caller derive a comparison base from a commit that is
# positively tool-owned: either the tip of a tool-namespace ref (ref-namespace|
# rows, e.g. refs/gitbutler/) or carried only by a tool-owned branch namespace
# (branch-namespace| rows, e.g. GitButler's refs/heads/gitbutler/workspace or its
# fetched refs/remotes/<remote>/gitbutler/workspace). A commit carried by any
# ordinary branch is silent.
# Read-only by construction: rev-parse/for-each-ref only. It never stages,
# commits, fetches, rebases, invokes a vendor CLI, or writes any file.

set -uo pipefail
export LC_ALL=C

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || exit 2
root="."
commit="HEAD"
signals_file=""

usage() {
    cat >&2 <<'EOF'
Usage: scripts/check-synthetic-base.sh [--root PATH] [--commit REF] [--signals-file PATH]
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
        --commit)
            [[ "$#" -ge 2 ]] || { usage; exit 2; }
            commit="$2"
            shift 2
            ;;
        --commit=*)
            commit="${1#*=}"
            shift
            ;;
        --signals-file)
            [[ "$#" -ge 2 ]] || { usage; exit 2; }
            signals_file="$2"
            shift 2
            ;;
        --signals-file=*)
            signals_file="${1#*=}"
            shift
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

[[ -n "$signals_file" ]] || signals_file="$script_dir/synthetic-base-signals.txt"

sanitize() {
    printf '%s' "$1" | tr '\r\n|' '   '
}

# Fail closed on an unreadable signals file before measuring anything.
if [[ ! -f "$signals_file" || ! -r "$signals_file" ]]; then
    printf 'SYNTHETIC_BASE|INCOMPLETE|RULES|.\n'
    exit 2
fi

# Strict row validation, fail closed. After the blank/comment skip every row
# must be exactly `ref-namespace|<prefix>` or `branch-namespace|<prefix>` with a
# non-empty, pipe-free prefix; a malformed row aborts the whole preflight so a
# typo cannot silently widen or narrow the owned namespaces.
ref_namespaces=()
branch_namespaces=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" == '#'* ]] && continue
    if [[ "$line" =~ ^ref-namespace\|[^|]+$ ]]; then
        ref_namespaces+=("${line#*|}")
        continue
    fi
    if [[ "$line" =~ ^branch-namespace\|[^|]+$ ]]; then
        branch_namespaces+=("${line#*|}")
        continue
    fi
    printf 'SYNTHETIC_BASE|INCOMPLETE|RULES|%s\n' "$(sanitize "$line")"
    exit 2
done < "$signals_file"

# Project-supplied extra owned ref namespaces (whitespace-separated ref prefixes).
if [[ -n "${PROMPTKIT_SYNTHETIC_REFS_EXTRA:-}" ]]; then
    for extra in ${PROMPTKIT_SYNTHETIC_REFS_EXTRA}; do
        [[ -n "$extra" ]] && ref_namespaces+=("$extra")
    done
fi

if [[ ! -d "$root" || -L "$root" ]]; then
    printf 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
fi
root=$(builtin cd -- "$root" && pwd -P) || {
    printf 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
}

local_git() {
    GIT_OPTIONAL_LOCKS=0 git -C "$root" -c core.fsmonitor=false "$@" 2>/dev/null
}

git_dir="$(local_git rev-parse --git-dir)" || {
    printf 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
}
if [[ -z "$git_dir" ]]; then
    printf 'SYNTHETIC_BASE|INCOMPLETE|GIT_METADATA|.\n'
    exit 2
fi

sha="$(local_git rev-parse --verify --quiet "${commit}^{commit}")" || {
    printf 'SYNTHETIC_BASE|INCOMPLETE|COMMIT|%s\n' "$(sanitize "$commit")"
    exit 2
}
if [[ -z "$sha" ]]; then
    printf 'SYNTHETIC_BASE|INCOMPLETE|COMMIT|%s\n' "$(sanitize "$commit")"
    exit 2
fi

carrying="$(local_git for-each-ref --contains "$sha" --format='%(refname)' refs/heads refs/remotes)" || {
    printf 'SYNTHETIC_BASE|INCOMPLETE|REFS|.\n'
    exit 2
}

# Any ordinary branch containing the commit makes it an ordinary commit and it
# is silent (Scenario 1), even when a tool-owned branch also contains it. A ref
# is tool-owned only when its branch name (after refs/heads/ or
# refs/remotes/<remote>/) is a tool-owned branch name; the carrier classifier and
# the tip lookup below share the predicate so they cannot disagree at a boundary.
branch_name_for_ref() {
    case "$1" in
        refs/heads/*) printf '%s' "${1#refs/heads/}" ;;
        refs/remotes/*) local remote_rest="${1#refs/remotes/}"; printf '%s' "${remote_rest#*/}" ;;
        *) printf '%s' "$1" ;;
    esac
}

# Tool-owned at a path-component boundary only: the name equals a
# branch-namespace prefix exactly or begins with that prefix followed by a slash.
# GitButler's gitbutler/workspace matches; gitbutler/workspace-backup does not,
# matching how `for-each-ref` treats a ref pattern up to a slash.
is_tool_owned_branch_name() {
    local branch_name="$1" branch_ns
    # Explicit length guard: bash 3.2 errors on an empty array under `set -u`.
    if [[ "${#branch_namespaces[@]}" -gt 0 ]]; then
        for branch_ns in "${branch_namespaces[@]}"; do
            if [[ "$branch_name" == "$branch_ns" || "$branch_name" == "$branch_ns"/* ]]; then
                return 0
            fi
        done
    fi
    return 1
}

ordinary_carrying=""
while IFS= read -r carrying_ref; do
    [[ -z "$carrying_ref" ]] && continue
    branch_name="$(branch_name_for_ref "$carrying_ref")"
    if ! is_tool_owned_branch_name "$branch_name"; then
        [[ -z "$ordinary_carrying" ]] && ordinary_carrying="$carrying_ref"
    fi
done <<< "$carrying"

if [[ -n "$ordinary_carrying" ]]; then
    printf 'SYNTHETIC_BASE|OK|%s|carried-by=%s\n' "$sha" "$(sanitize "$ordinary_carrying")"
    exit 0
fi

# Positive class (b): the inspected commit is the TIP of a tool-owned workspace
# branch -- GitButler's refs/heads/gitbutler/workspace, or its fetched
# refs/remotes/<remote>/gitbutler/workspace when no local branch exists. Tip-only,
# never --contains: an ordinary commit that merely precedes a workspace snapshot is
# not itself a workspace snapshot, and ownership must be evidence about the
# inspected commit. The tip set is classified with the same predicate as the
# carrier loop above, so the two passes share one definition of tool-owned.
tool_branch_tip=""
# Explicit length guard: bash 3.2 errors on an empty array under `set -u`.
if [[ "${#branch_namespaces[@]}" -gt 0 ]]; then
    tip_refs="$(local_git for-each-ref --points-at "$sha" --format='%(refname)' refs/heads refs/remotes)" || {
        printf 'SYNTHETIC_BASE|INCOMPLETE|REFS|.\n'
        exit 2
    }
    while IFS= read -r tip_ref; do
        [[ -z "$tip_ref" ]] && continue
        if is_tool_owned_branch_name "$(branch_name_for_ref "$tip_ref")"; then
            tool_branch_tip="$tip_ref"
            break
        fi
    done <<< "$tip_refs"
fi
if [[ -n "$tool_branch_tip" ]]; then
    printf 'SYNTHETIC_BASE|REFUSE|%s|owned-branch=%s\n' "$sha" "$(sanitize "$tool_branch_tip")"
    printf 'SYNTHETIC_BASE|RECOVERY|Return to the carrying branch or rebase onto a real branch tip before deriving a base; never derive a base from a synthetic workspace commit (docs/MAXIMS.md)\n'
    exit 1
fi

# Positive class (a): the commit is the tip of a tool-namespace ref. The ref must
# point AT the commit -- an earlier commit on the same reachable chain is an
# ordinary commit, not a synthetic one, so --contains would falsely refuse it.
# Absence of a carrying branch is corroborating, never sufficient on its own -- a
# detached real commit is exactly "no carrying branch" and must fall through to
# UNKNOWN.
# Explicit length guard: bash 3.2 errors on an empty array under `set -u`.
if [[ "${#ref_namespaces[@]}" -gt 0 ]]; then
    for ns in "${ref_namespaces[@]}"; do
        owned="$(local_git for-each-ref --points-at "$sha" --format='%(refname)' "$ns")" || {
            printf 'SYNTHETIC_BASE|INCOMPLETE|REFS|.\n'
            exit 2
        }
        if [[ -n "$owned" ]]; then
            printf 'SYNTHETIC_BASE|REFUSE|%s|owned-ref=%s\n' "$sha" "$(sanitize "${owned%%$'\n'*}")"
            printf 'SYNTHETIC_BASE|RECOVERY|Return to the carrying branch or rebase onto a real branch tip before deriving a base; never derive a base from a synthetic workspace commit (docs/MAXIMS.md)\n'
            exit 1
        fi
    done
fi

printf 'SYNTHETIC_BASE|UNKNOWN|%s|no-carrying-branch-no-owned-ref\n' "$sha"
exit 0
