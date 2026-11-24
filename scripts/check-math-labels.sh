#!/usr/bin/env bash
# Math label guard: reject backslash-escaped underscores inside \text{...}.
# Usage: scripts/check-math-labels.sh [--root PATH]
# Why: `\_` is a markdown backslash escape. Renderers that resolve markdown
# escapes before handing math to KaTeX deliver a bare `_` into \text{} (text
# mode), which KaTeX rejects with "`_` allowed only in math mode". Observed on
# GitHub for docs/BENCHMARK-METHODOLOGY.md. Use hyphens in \text{} labels.
# Scope: git-tracked plus untracked-but-not-ignored *.md files when the root is
# a git work tree, so a local run and a CI run see the same set; otherwise
# every *.md under the root recursively. Historical records are exempt by class
# (dated evidence, like other sweeps).
# Limitation: detects \text{ and a later \_ on the same line only.

set -u

ROOT="."
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)
            [ "$#" -lt 2 ] && { echo "MATH_LABEL_GATE|USAGE|--root requires a path"; exit 2; }
            ROOT="$2"; shift 2 ;;
        --root=*)
            ROOT="${1#*=}"; shift ;;
        -h|--help)
            echo "Usage: scripts/check-math-labels.sh [--root PATH]"; exit 0 ;;
        *)
            echo "MATH_LABEL_GATE|USAGE|Unknown argument: $1"; exit 2 ;;
    esac
done

if [ ! -d "$ROOT" ]; then
    echo "MATH_LABEL_GATE|MISSING_ROOT|Repository root does not exist|Provide a valid --root path"
    exit 1
fi

ROOT_ABS="$(cd "$ROOT" && pwd -P)" || {
    echo "MATH_LABEL_GATE|MISSING_ROOT|Repository root is not readable|Provide a valid --root path"
    exit 1
}

list_file="$(mktemp)" || { echo "MATH_LABEL_GATE|IO_ERROR|Cannot create a temporary file"; exit 2; }
trap 'rm -f "$list_file"' EXIT

# Prefer the git index: it is the same set CI checks out. Fall back to a
# recursive scan when the root is not a work tree or git is unavailable.
scope_mode="scan"
if [ -e "$ROOT_ABS/.git" ] && command -v git >/dev/null 2>&1; then
    if GIT_OPTIONAL_LOCKS=0 git -C "$ROOT_ABS" -c core.fsmonitor=false \
        ls-files --cached --others --exclude-standard -z -- '*.md' > "$list_file.raw" 2>/dev/null; then
        scope_mode="git"
        : > "$list_file"
        while IFS= read -r -d '' rel; do
            [ -f "$ROOT_ABS/$rel" ] && printf '%s\n' "$rel"
        done < "$list_file.raw" >> "$list_file"
    fi
    rm -f "$list_file.raw"
fi

if [ "$scope_mode" = "scan" ]; then
    ( cd "$ROOT_ABS" && find . -name .git -prune -o -type f -name '*.md' -print ) \
        | sed 's|^\./||' > "$list_file"
fi

file_count="$(wc -l < "$list_file" | tr -d ' ')"
printf '%s\n' "MATH_LABEL_GATE|SCOPE|mode=$scope_mode|files=$file_count"

findings="$(awk -v root="$ROOT_ABS" -v list="$list_file" '
    BEGIN {
        while ((getline rel < list) > 0) {
            if (rel == "") continue
            exempt = (rel ~ /(^|\/)docs\/releases\//) || (rel ~ /(^|\/)docs\/archive\//) \
                  || (rel ~ /(^|\/)docs\/internal\//) || (rel ~ /(^|\/)docs\/tasks\//) \
                  || (rel ~ /(^|\/)CHANGELOG\.md$/)
            if (exempt) continue
            path = root "/" rel
            lineno = 0
            while ((getline line < path) > 0) {
                lineno++
                start = index(line, "\\text{")
                if (start == 0) continue
                rest = substr(line, start)
                if (index(rest, "\\_") == 0) continue
                printf "%s:%d:%s\n", rel, lineno, line
            }
            close(path)
        }
    }' 2>/dev/null || true)"

if [ -n "$findings" ]; then
    printf '%s\n' "MATH_LABEL_GATE|FAIL|backslash-escaped underscore inside \\text{} label:"
    printf '%s\n' "$findings" | sed 's/^/  - /'
    printf '%s\n' "MATH_LABEL_GATE|REMEDIATION|Use a hyphen or space in \\text{} labels (e.g. \\text{dev-hourly}); \\_ is a markdown escape and breaks text-mode math on some renderers"
    exit 1
fi

printf '%s\n' "MATH_LABEL_GATE|PASS|no fragile \\_ inside \\text{} labels"
exit 0
