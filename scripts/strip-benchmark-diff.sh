#!/usr/bin/env bash
# PromptKit OS Benchmark Diff Stripper
# Filters a unified diff (as produced by git diff between a benchmark run's
# seed and post-run states) so blind graders see code changes only: whole file
# sections for PromptKit framework artifacts are dropped — PROMPTKIT.md,
# AGENTS.md, docs/STATE.md, docs/tasks/, docs/specs/, .promptkit/,
# .github/pull_request_template.md, and .github/ISSUE_TEMPLATE/. Everything
# else passes through verbatim. Dependency-free; the .ps1 twin reaches
# identical verdicts from identical input.
#
# Known limitation (v1): section paths are taken from the trailing b/ operand
# of each `diff --git` line, so quoted paths containing spaces are not parsed.
set -euo pipefail
export LC_ALL=C

DROP_PATTERNS="PROMPTKIT.md|AGENTS.md|docs/STATE.md|docs/tasks/|docs/specs/|.promptkit/|.github/pull_request_template.md|.github/ISSUE_TEMPLATE/"
TARGET_FILE=""

usage() {
    echo "Usage: strip-benchmark-diff.sh <run.diff>"
    echo "Drops PromptKit-artifact file sections from a unified diff and prints"
    echo "the code-change diff on stdout; a STRIP|... status line goes to stderr."
    echo "Exit 0 on success; exit 2 on empty/non-diff input."
}

strip_error() {
    printf 'STRIP|ERROR|%s|%s\n' "$1" "$2" >&2
    exit 2
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        --*|-*-*)
            printf 'STRIP|ERROR|UNKNOWN_FLAG|%s\n' "$arg" >&2
            exit 2
            ;;
        *)
            if [[ -n "$TARGET_FILE" ]]; then
                strip_error "MULTIPLE_INPUTS" "$arg"
            fi
            TARGET_FILE="$arg"
            ;;
    esac
done

if [[ -z "$TARGET_FILE" ]]; then
    usage
    exit 2
fi
if [[ ! -s "$TARGET_FILE" ]]; then
    strip_error "UNREADABLE" "$TARGET_FILE"
fi
first_line="$(grep -m1 -v '^[[:space:]]*$' "$TARGET_FILE" || true)"
if [[ "$first_line" != "diff --git "* ]]; then
    strip_error "NOT_A_DIFF" "$TARGET_FILE"
fi

awk -v pats="$DROP_PATTERNS" '
function is_artifact(p,  i) {
    for (i = 1; i <= npat; i++) {
        if (P[i] == "") continue
        if (substr(P[i], length(P[i]), 1) == "/") {
            if (index(p, P[i]) == 1) return 1
        } else if (p == P[i]) {
            return 1
        }
    }
    return 0
}
BEGIN {
    npat = split(pats, P, "|")
    infiles = 0; outfiles = 0; dropped = 0; keep = 0; buf = ""
}
/^diff --git / {
    if (infiles > 0) {
        if (keep) { printf "%s", buf; outfiles++ } else { dropped++ }
    }
    infiles++
    path = $NF
    sub(/^b\//, "", path)
    keep = is_artifact(path) ? 0 : 1
    buf = $0 "\n"
    next
}
{ buf = buf $0 "\n" }
END {
    if (infiles > 0) {
        if (keep) { printf "%s", buf; outfiles++ } else { dropped++ }
    }
    printf "STRIP|OK|in_files=%d|out_files=%d|dropped=%d\n", infiles, outfiles, dropped > "/dev/stderr"
}' "$TARGET_FILE"
