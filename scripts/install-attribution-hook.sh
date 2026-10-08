#!/usr/bin/env bash
# install-attribution-hook.sh — opt-in, reversible commit-msg integration.
#
# Adds/removes a managed block in the repository's commit-msg hook that runs
# scripts/check-ai-attribution.sh against the pending message. The block is
# inserted immediately after the shebang so it fires even when a pre-existing
# hook body ends in an unconditional `exit 0`; the original body still runs
# afterward when the check passes (chained, content preserved verbatim).
# --remove strips only the managed block. Installing/removing is explicit and
# idempotent. It never stages, commits, amends, or rewrites history.
#
# Exit codes: 0 installed/removed; 2 incomplete (no git repository).

set -uo pipefail
export LC_ALL=C

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || exit 2
checker="$script_dir/check-ai-attribution.sh"

START='# >>> PROMPTKIT_AI_ATTRIBUTION >>>'
END='# <<< PROMPTKIT_AI_ATTRIBUTION <<<'

root="."
action="install"

usage() {
    cat >&2 <<'EOF'
Usage: scripts/install-attribution-hook.sh [--root PATH] [--remove]
EOF
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --root) [[ "$#" -ge 2 ]] || { usage; exit 2; }; root="$2"; shift 2 ;;
        --root=*) root="${1#*=}"; shift ;;
        --remove) action="remove"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 2 ;;
    esac
done

git_dir="$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null)" || {
    printf 'AI_ATTRIBUTION_HOOK|INCOMPLETE|NO_REPO|.\n'
    exit 2
}
[[ -n "$git_dir" ]] || { printf 'AI_ATTRIBUTION_HOOK|INCOMPLETE|NO_REPO|.\n'; exit 2; }

hook_dir="$git_dir/hooks"
hook_path="$hook_dir/commit-msg"

# Stream filter: drop lines between the managed markers (inclusive), wherever
# they appear. Reads stdin, writes stdout.
strip_block() {
    awk -v s="$START" -v e="$END" '
        $0==s {inblk=1; next}
        inblk && $0==e {inblk=0; next}
        !inblk {print}
    '
}

if [[ "$action" == "remove" ]]; then
    if [[ -f "$hook_path" ]] && grep -qF "$START" "$hook_path"; then
        strip_block < "$hook_path" > "$hook_path.tmp"
        if [[ "$(grep -vcE '^(#!.*)?[[:space:]]*$' "$hook_path.tmp" 2>/dev/null)" -eq 0 ]]; then
            rm -f "$hook_path" "$hook_path.tmp"
        else
            mv "$hook_path.tmp" "$hook_path"
        fi
        printf 'AI_ATTRIBUTION_HOOK|REMOVED|%s\n' "$hook_path"
    else
        printf 'AI_ATTRIBUTION_HOOK|ABSENT|%s\n' "$hook_path"
    fi
    exit 0
fi

mkdir -p "$hook_dir"

body_tmp="$hook_path.body.$$"
if [[ -f "$hook_path" ]]; then
    first_line="$(head -n 1 "$hook_path")"
    case "$first_line" in
        '#!'*) shebang="$first_line"; tail -n +2 "$hook_path" | strip_block > "$body_tmp" ;;
        *) shebang='#!/bin/sh'; strip_block < "$hook_path" > "$body_tmp" ;;
    esac
else
    shebang='#!/bin/sh'
    : > "$body_tmp"
fi

{
    printf '%s\n' "$shebang"
    printf '\n'
    printf '%s\n' "$START"
    printf '# Managed by PromptKit OS. Remove with scripts/install-attribution-hook.sh --remove.\n'
    printf '__pk_attr_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"\n'
    printf '__pk_attr_checker="%s"\n' "$checker"
    printf 'if [ -f "$__pk_attr_checker" ]; then\n'
    printf '  bash "$__pk_attr_checker" --root "$__pk_attr_root" --message-file "$1" || exit 1\n'
    printf 'fi\n'
    printf '%s\n' "$END"
    printf '\n'
    cat "$body_tmp"
} > "$hook_path.tmp"
rm -f "$body_tmp"

mv "$hook_path.tmp" "$hook_path"
chmod +x "$hook_path"
printf 'AI_ATTRIBUTION_HOOK|INSTALLED|%s\n' "$hook_path"
exit 0
