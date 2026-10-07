#!/usr/bin/env bash
# Read-only synthetic-base preflight.
# Usage: scripts/check-synthetic-base.sh [--root PATH] [--commit REF] [--signals-file PATH]
#
# Refuses to let a caller derive a comparison base from a commit that is
# positively tool-owned -- a synthetic workspace commit carried by a
# tool-namespace ref (e.g. refs/gitbutler/*, refs/orca/*) and by no branch.
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
# must be exactly `ref-namespace|<prefix>` with a non-empty, pipe-free prefix;
# a malformed row aborts the whole preflight so a typo cannot silently widen or
# narrow the owned namespaces.
namespaces=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" == '#'* ]] && continue
    if [[ ! "$line" =~ ^ref-namespace\|[^|]+$ ]]; then
        printf 'SYNTHETIC_BASE|INCOMPLETE|RULES|%s\n' "$(sanitize "$line")"
        exit 2
    fi
    namespaces+=("${line#*|}")
done < "$signals_file"

# Project-supplied extra owned namespaces (whitespace-separated prefixes).
if [[ -n "${PROMPTKIT_SYNTHETIC_REFS_EXTRA:-}" ]]; then
    for extra in ${PROMPTKIT_SYNTHETIC_REFS_EXTRA}; do
        [[ -n "$extra" ]] && namespaces+=("$extra")
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

# A carrying branch (local or remote-tracking) makes the commit an ordinary
# branch tip. This is the silent, healthy path.
carrying="$(local_git for-each-ref --contains "$sha" --format='%(refname)' refs/heads refs/remotes)" || {
    printf 'SYNTHETIC_BASE|INCOMPLETE|REFS|.\n'
    exit 2
}
if [[ -n "$carrying" ]]; then
    printf 'SYNTHETIC_BASE|OK|%s|carried-by=%s\n' "$sha" "$(sanitize "${carrying%%$'\n'*}")"
    exit 0
fi

# Positive evidence only: the commit is owned by a tool namespace. Absence of a
# carrying branch is corroborating, never sufficient on its own -- a detached
# real commit is exactly "no carrying branch" and must fall through to UNKNOWN.
for ns in "${namespaces[@]}"; do
    owned="$(local_git for-each-ref --contains "$sha" --format='%(refname)' "$ns")" || {
        printf 'SYNTHETIC_BASE|INCOMPLETE|REFS|.\n'
        exit 2
    }
    if [[ -n "$owned" ]]; then
        printf 'SYNTHETIC_BASE|REFUSE|%s|owned-ref=%s\n' "$sha" "$(sanitize "${owned%%$'\n'*}")"
        printf 'SYNTHETIC_BASE|RECOVERY|Return to the carrying branch or rebase onto a real branch tip before deriving a base; never derive a base from a synthetic workspace commit (docs/MAXIMS.md)\n'
        exit 1
    fi
done

printf 'SYNTHETIC_BASE|UNKNOWN|%s|no-carrying-branch-no-owned-ref\n' "$sha"
exit 0
