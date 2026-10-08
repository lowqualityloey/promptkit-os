#!/usr/bin/env bash
# install-attribution-hook.sh — opt-in, reversible commit-msg integration.
#
# Adds/removes a managed block in the repository's commit-msg hook that runs
# scripts/check-ai-attribution.sh against the pending message. The destination
# is Git's effective hooks directory (honors core.hooksPath and linked
# worktrees). For sh hooks the block is inserted immediately after the shebang
# so it fires even when a pre-existing hook body ends in an unconditional
# `exit 0`; the original body still runs afterward when the check passes
# (chained, content preserved verbatim). For non-sh hooks (python, node, ...)
# the original is preserved verbatim as commit-msg.promptkit-orig and a sh
# wrapper runs the check then execs it, so the interpreter is never corrupted.
# --remove restores the original byte-for-byte and mode-for-mode. Installing and
# removing are explicit and idempotent. It never stages, commits, amends, or
# rewrites history.
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

git_dir="$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null)" || git_dir=""
[[ -n "$git_dir" ]] || { printf 'AI_ATTRIBUTION_HOOK|INCOMPLETE|NO_REPO|.\n'; exit 2; }

# Git's effective hooks directory. `rev-parse --git-path` applies core.hooksPath
# and resolves linked worktrees to the shared common dir; the explicit
# core.hooksPath/git-dir fallbacks cover Git without --path-format.
resolve_hook_dir() {
    local top p
    p="$(git -C "$root" rev-parse --path-format=absolute --git-path hooks 2>/dev/null || true)"
    if [[ -z "$p" ]]; then
        p="$(git -C "$root" config --get core.hooksPath 2>/dev/null || true)"
    fi
    case "$p" in
        '') p="$git_dir/hooks" ;;
        ~/*) p="$HOME/${p#\~/}" ;;
    esac
    case "$p" in
        /*) : ;;
        *)
            top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)"
            [[ -n "$top" ]] || top="$root"
            p="${top%/}/$p"
            ;;
    esac
    printf '%s\n' "${p%/}"
}

hook_dir="$(resolve_hook_dir)"
hook_path="$hook_dir/commit-msg"
orig_path="$hook_path.promptkit-orig"

# Print the interpreter basename of a shebang line (empty when not a shebang).
shebang_interpreter() {
    local line="$1" word base rest
    [[ "$line" == '#!'* ]] || return 0
    line="${line#\#!}"
    line="${line#"${line%%[![:space:]]*}"}"
    word="${line%%[[:space:]]*}"
    base="${word##*/}"
    if [[ "$base" == "env" ]]; then
        rest="${line#"$word"}"
        rest="${rest#"${rest%%[![:space:]]*}"}"
        while [[ -n "$rest" ]]; do
            word="${rest%%[[:space:]]*}"
            case "$word" in
                -*) rest="${rest#"$word"}"; rest="${rest#"${rest%%[![:space:]]*}"}" ;;
                *=*) rest="${rest#"$word"}"; rest="${rest#"${rest%%[![:space:]]*}"}" ;;
                *) break ;;
            esac
        done
        base="${word##*/}"
    fi
    printf '%s' "$base"
}

is_shell_interpreter() {
    case "$1" in
        sh|bash|dash|ash|ksh|mksh|zsh|posh|busybox) return 0 ;;
        *) return 1 ;;
    esac
}

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
        if [[ -f "$orig_path" ]]; then
            mv "$orig_path" "$hook_path"
        else
            strip_block < "$hook_path" > "$hook_path.tmp"
            if [[ "$(grep -vcE '^(#!.*)?[[:space:]]*$' "$hook_path.tmp" 2>/dev/null)" -eq 0 ]]; then
                rm -f "$hook_path" "$hook_path.tmp"
            else
                cat "$hook_path.tmp" > "$hook_path"
                rm -f "$hook_path.tmp"
            fi
        fi
        printf 'AI_ATTRIBUTION_HOOK|REMOVED|%s\n' "$hook_path"
    else
        printf 'AI_ATTRIBUTION_HOOK|ABSENT|%s\n' "$hook_path"
    fi
    exit 0
fi

mkdir -p "$hook_dir"

# A pre-existing non-shell hook cannot host the POSIX block under its shebang;
# keep the original verbatim and let a sh wrapper chain to it instead.
if [[ -f "$hook_path" ]] && ! grep -qF "$START" "$hook_path" 2>/dev/null; then
    existing_interp="$(shebang_interpreter "$(head -n 1 "$hook_path")")"
    if [[ -n "$existing_interp" ]] && ! is_shell_interpreter "$existing_interp"; then
        cp -p "$hook_path" "$orig_path"
    fi
fi

if [[ -f "$orig_path" ]]; then
    wrapper_tmp="$hook_path.tmp.$$"
    {
        printf '#!/bin/sh\n'
        printf '\n'
        printf '%s\n' "$START"
        printf '# Managed by PromptKit OS. Remove with scripts/install-attribution-hook.sh --remove.\n'
        printf '__pk_attr_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"\n'
        printf '__pk_attr_checker="%s"\n' "$checker"
        printf '__pk_attr_orig="%s"\n' "$orig_path"
        printf 'if [ -f "$__pk_attr_checker" ]; then\n'
        printf '  bash "$__pk_attr_checker" --root "$__pk_attr_root" --message-file "$1" || exit 1\n'
        printf 'fi\n'
        printf '%s\n' "$END"
        printf '\n'
        printf 'if [ -x "$__pk_attr_orig" ]; then\n'
        printf '  exec "$__pk_attr_orig" "$@"\n'
        printf 'fi\n'
        printf '__pk_attr_shebang="$(head -n 1 "$__pk_attr_orig" 2>/dev/null || true)"\n'
        printf 'case "$__pk_attr_shebang" in\n'
        printf "  '#!'*) exec \${__pk_attr_shebang#\\#!} \"\$__pk_attr_orig\" \"\$@\" ;;\n"
        printf '  *) exec /bin/sh "$__pk_attr_orig" "$@" ;;\n'
        printf 'esac\n'
    } > "$wrapper_tmp"
    cat "$wrapper_tmp" > "$hook_path"
    rm -f "$wrapper_tmp"
    chmod +x "$hook_path"
    printf 'AI_ATTRIBUTION_HOOK|INSTALLED|%s\n' "$hook_path"
    exit 0
fi

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
    printf '%s\n' "$START"
    printf '# Managed by PromptKit OS. Remove with scripts/install-attribution-hook.sh --remove.\n'
    printf '__pk_attr_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"\n'
    printf '__pk_attr_checker="%s"\n' "$checker"
    printf 'if [ -f "$__pk_attr_checker" ]; then\n'
    printf '  bash "$__pk_attr_checker" --root "$__pk_attr_root" --message-file "$1" || exit 1\n'
    printf 'fi\n'
    printf '%s\n' "$END"
    cat "$body_tmp"
} > "$hook_path.tmp"
rm -f "$body_tmp"

if [[ -f "$hook_path" ]]; then
    cat "$hook_path.tmp" > "$hook_path"
    rm -f "$hook_path.tmp"
else
    mv "$hook_path.tmp" "$hook_path"
fi
chmod +x "$hook_path"
printf 'AI_ATTRIBUTION_HOOK|INSTALLED|%s\n' "$hook_path"
exit 0
