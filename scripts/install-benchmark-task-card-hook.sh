#!/usr/bin/env bash
# install-benchmark-task-card-hook.sh — opt-in, reversible pre-commit gate.
#
# Adds/removes a managed block in the repository's pre-commit hook that runs
# scripts/check-benchmark-task-cards.sh when the staged set touches a
# benchmarks/tasks/TASK-*.md card, so a card whose Verify command orders the
# suite before the probe (or chains them with &&) fails locally instead of in
# CI. The destination is Git's effective hooks directory (honors
# core.hooksPath and linked worktrees). For sh hooks the block is inserted
# immediately after the shebang so it fires even when a pre-existing hook body
# ends in an unconditional `exit 0`; the original body still runs afterward
# when the gate passes (chained, content preserved verbatim). For non-sh hooks
# (python, node, ...) the original is preserved verbatim as
# pre-commit.promptkit-orig and a sh wrapper runs the gate then execs it, so the
# interpreter is never corrupted. --remove restores the original byte-for-byte
# and mode-for-mode. Installing and removing are explicit and idempotent. It
# never stages, commits, amends, or rewrites history.
#
# The gate is scoped to the staged card set: a commit that touches no card runs
# the hook as a no-op, so unrelated work is never blocked by a card elsewhere in
# the tree. Each staged card is read from Git's index - `git show :<path>` - into
# a throwaway tree and the checker runs there, so a partially staged card is
# judged by the bytes the commit will carry, not by the working-tree copy, and a
# broken card left unstaged elsewhere cannot block the commit.
#
# Exit codes: 0 installed/removed; 2 incomplete (no git repository).

set -uo pipefail
export LC_ALL=C

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || exit 2
checker_sh="$script_dir/check-benchmark-task-cards.sh"
checker_ps1="$script_dir/check-benchmark-task-cards.ps1"

START='# >>> PROMPTKIT_TASK_CARD_GATE >>>'
END='# <<< PROMPTKIT_TASK_CARD_GATE <<<'

root="."
action="install"

usage() {
    cat >&2 <<'EOF'
Usage: scripts/install-benchmark-task-card-hook.sh [--root PATH] [--remove]
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
[[ -n "$git_dir" ]] || { printf 'TASK_CARD_HOOK|INCOMPLETE|NO_REPO|.\n'; exit 2; }

# Git's effective hooks directory. `rev-parse --git-path` applies core.hooksPath
# and resolves linked worktrees to the shared common dir; the explicit
# core.hooksPath/git-dir fallbacks cover Git without --path-format.
resolve_hook_dir() {
    local top p
    p="$(git -C "$root" rev-parse --path-format=absolute --git-path hooks 2>/dev/null || true)"
    if [[ -z "$p" ]]; then
        p="$(git -C "$root" config --get core.hooksPath 2>/dev/null || true)"
    fi
    # A quoted RHS keeps `~` literal here: an unquoted `~/*` pattern is
    # tilde-expanded to "$HOME/*", which matches this repository's own
    # absolute hook path and doubles the prefix.
    if [[ -z "$p" ]]; then
        p="$git_dir/hooks"
    elif [[ "$p" == "~/"* ]]; then
        p="$HOME/${p#\~/}"
    fi
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
hook_path="$hook_dir/pre-commit"
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
    # A hook edited on Windows (or checked out under core.autocrlf) carries \r on
    # every line. Compare on a copy with the bare CR stripped, but print the
    # original line so the rest of the file keeps its bytes.
    awk -v s="$START" -v e="$END" '
        {
            line = $0
            sub(/\r$/, "", line)
            if (line == s) { inblk=1; next }
            if (inblk && line == e) { inblk=0; next }
            if (!inblk) print
        }
    '
}

# The managed block: run the gate only when a card is staged, prefer the Bash
# checker, fall back to the PowerShell twin where only pwsh exists. The staged
# cards are materialized from the index into a temp tree first, so the checker
# sees exactly what the commit would carry.
# $1 is the original-hook path for the wrapper case, empty otherwise.
emit_block() {
    local orig="${1:-}" body
    body="$(
        cat <<'HEAD'
# Managed by PromptKit OS. Remove with scripts/install-benchmark-task-card-hook.sh --remove.
__pk_card_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HEAD
        printf '__pk_card_sh="%s"\n' "$checker_sh"
        printf '__pk_card_ps1="%s"\n' "$checker_ps1"
        printf '__pk_card_orig="%s"\n' "$orig"
        cat <<'TAIL'
__pk_card_staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '^benchmarks/tasks/TASK-.*\.md$' || true)"
if [ -n "$__pk_card_staged" ]; then
  __pk_card_rc=0
  __pk_card_unreadable=0
  __pk_card_tmp="$(mktemp -d 2>/dev/null || true)"
  if [ -z "$__pk_card_tmp" ] || ! mkdir -p "$__pk_card_tmp/benchmarks/tasks"; then
    __pk_card_rc=1
    __pk_card_unreadable=1
  else
    # Judge the staged bytes, not the working tree. The heredoc body and its
    # delimiter stay unindented because POSIX sh requires that.
    while IFS= read -r __pk_card_path; do
      [ -n "$__pk_card_path" ] || continue
      git -C "$__pk_card_root" show ":$__pk_card_path" > "$__pk_card_tmp/$__pk_card_path" 2>/dev/null || { __pk_card_rc=1; __pk_card_unreadable=1; }
    done <<__PK_CARD_EOF
$__pk_card_staged
__PK_CARD_EOF
    if [ "$__pk_card_rc" -eq 0 ]; then
      if command -v bash >/dev/null 2>&1 && [ -f "$__pk_card_sh" ]; then
        bash "$__pk_card_sh" --root "$__pk_card_tmp" || __pk_card_rc=$?
      elif command -v pwsh >/dev/null 2>&1 && [ -f "$__pk_card_ps1" ]; then
        pwsh -NoProfile -File "$__pk_card_ps1" -Root "$__pk_card_tmp" || __pk_card_rc=$?
      fi
    fi
  fi
  [ -n "$__pk_card_tmp" ] && rm -rf -- "$__pk_card_tmp"
  if [ "$__pk_card_rc" -ne 0 ]; then
    if [ "$__pk_card_unreadable" -eq 1 ]; then
      echo "[promptkit] could not read a staged benchmark task card from the index; commit blocked." >&2
    else
      echo "[promptkit] a staged benchmark task card breaks the Verify convention: run the behavioral probe first, run the test suite second, and do not chain them with && or ||." >&2
      echo "[promptkit] see benchmarks/tasks/TEMPLATE-task.md. Commit blocked." >&2
    fi
    exit 1
  fi
fi
TAIL
    )"
    printf '%s\n' "$START"
    printf '%s\n' "$body"
    printf '%s\n' "$END"
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
        printf 'TASK_CARD_HOOK|REMOVED|%s\n' "$hook_path"
    else
        printf 'TASK_CARD_HOOK|ABSENT|%s\n' "$hook_path"
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
    {
        printf '#!/bin/sh\n'
        printf '\n'
        emit_block "$orig_path"
        printf '\n'
        cat <<'TAIL'
if [ -x "$__pk_card_orig" ]; then
  exec "$__pk_card_orig" "$@"
fi
__pk_card_shebang="$(head -n 1 "$__pk_card_orig" 2>/dev/null || true)"
case "$__pk_card_shebang" in
  '#!'*) exec ${__pk_card_shebang#\#!} "$__pk_card_orig" "$@" ;;
  *) exec /bin/sh "$__pk_card_orig" "$@" ;;
esac
TAIL
    } > "$hook_path.tmp"
    cat "$hook_path.tmp" > "$hook_path"
    rm -f "$hook_path.tmp"
    chmod +x "$hook_path"
    printf 'TASK_CARD_HOOK|INSTALLED|%s\n' "$hook_path"
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
    emit_block ""
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
printf 'TASK_CARD_HOOK|INSTALLED|%s\n' "$hook_path"
exit 0
