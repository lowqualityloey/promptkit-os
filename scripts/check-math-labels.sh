#!/usr/bin/env bash
# Math label guard: reject backslash-escaped underscores inside \text{...}.
# Usage: scripts/check-math-labels.sh [--root PATH]
# Why: `\_` is a markdown backslash escape. Renderers that resolve markdown
# escapes before handing math to KaTeX deliver a bare `_` into \text{} (text
# mode), which KaTeX rejects with "`_` allowed only in math mode". Observed on
# GitHub for docs/BENCHMARK-METHODOLOGY.md. Use hyphens in \text{} labels.
# Scans every *.md under the root recursively; historical records are exempt
# by class (dated evidence, like other sweeps).
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

findings="$(find "$ROOT" -type f -name '*.md' -not -path '*/.git/*' -exec awk '
    FNR == 1 {
        path = FILENAME
        exempt = (path ~ /(^|\/)docs\/releases\//) || (path ~ /(^|\/)docs\/archive\//) \
              || (path ~ /(^|\/)docs\/internal\//) || (path ~ /(^|\/)docs\/tasks\//) \
              || (path ~ /(^|\/)CHANGELOG\.md$/)
    }
    exempt { next }
    {
        start = index($0, "\\text{")
        if (start == 0) next
        rest = substr($0, start)
        if (index(rest, "\\_") == 0) next
        printf "%s:%d:%s\n", path, FNR, $0
    }
  ' {} + 2>/dev/null || true)"

if [ -n "$findings" ]; then
    printf '%s\n' "MATH_LABEL_GATE|FAIL|backslash-escaped underscore inside \\text{} label:"
    printf '%s\n' "$findings" | sed "s|$ROOT/||; s/^/  - /"
    printf '%s\n' "MATH_LABEL_GATE|REMEDIATION|Use a hyphen or space in \\text{} labels (e.g. \\text{dev-hourly}); \\_ is a markdown escape and breaks text-mode math on some renderers"
    exit 1
fi

printf '%s\n' "MATH_LABEL_GATE|PASS|no fragile \\_ inside \\text{} labels"
exit 0
