#!/usr/bin/env bash
# Read-only validator for Diagnostics Evidence tables in docs/reviews/*.md.
# Proves every cited file:line:col location falls inside the recorded fixed-point diff.
# Run from repository root: bash scripts/validate-lsp-evidence.sh --root . --diff-file baseline.diff
#
# Exit codes: 0 = all citations verified or no citations present; 1 = violations found.
# Diagnostic format: CATEGORY|REVIEW_ID|FILE|MESSAGE|REMEDIATION (stable across Bash/PowerShell).

set -u
set -o pipefail

ROOT="."
DIFF_FILE=""

usage() {
    echo "Usage: bash scripts/validate-lsp-evidence.sh [--root DIR] --diff-file GIT_DIFF"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --diff-file) DIFF_FILE="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR|UNKNOWN|cli|Unknown argument: $1|Use --root, --diff-file, or --help"; usage; exit 1 ;;
    esac
done

if [ ! -d "$ROOT" ]; then
    echo "ERROR|UNKNOWN|$ROOT|Root directory not found|Pass --root pointing at the repository root"
    exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"

REVIEWS_DIR="$ROOT/docs/reviews"

collect_citations() {
    local report="$1" section=0 line
    while IFS= read -r line; do
        if printf '%s' "$line" | grep -q '^#\{2,3\} '; then
            if printf '%s' "$line" | grep -q 'Diagnostics Evidence'; then
                section=1
            else
                section=0
            fi
            continue
        fi
        [ "$section" -eq 1 ] || continue
        printf '%s' "$line" | grep -qE '\|[[:space:]]*.`?[A-Za-z0-9_./@-]+\.[A-Za-z0-9]+:[0-9]+' || continue
        printf '%s' "$line" | grep -oE '[A-Za-z0-9_./@-]+\.[A-Za-z0-9]+:[0-9]+(:[0-9]+)?' | while IFS= read -r loc; do
            printf '%s\t%s\n' "$report" "$loc"
        done
    done < "$report"
}

if [ ! -d "$REVIEWS_DIR" ]; then
    echo "PASSED|RECORDS=0|CITED=0|note=no-reviews-directory"
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CITES="$TMP/cites.tsv"
: > "$CITES"

RECORDS=0
for report in "$REVIEWS_DIR"/*.md; do
    [ -e "$report" ] || break
    RECORDS=$((RECORDS + 1))
    collect_citations "$report" >> "$CITES"
done

CITED=$(wc -l < "$CITES" | tr -d ' ')

if [ "$CITED" -eq 0 ]; then
    echo "PASSED|RECORDS=$RECORDS|CITED=0|note=not-measured-or-no-diagnostics-section"
    exit 0
fi

if [ -z "$DIFF_FILE" ] || [ ! -f "$DIFF_FILE" ]; then
    echo "ERROR|MISSING_DIFF|-|--diff-file is required when a report cites diagnostics|Provide the fixed-point git diff file or record not measured"
    exit 1
fi

RANGES="$TMP/ranges.tsv"
awk '
    /^\+\+\+ b\// { file = substr($0, 7); next }
    /^@@ / {
        if (match($0, /\+[0-9]+(,[0-9]+)?/)) {
            spec = substr($0, RSTART + 1, RLENGTH - 1)
            split(spec, a, ",")
            start = a[1] + 0
            count = (a[2] == "") ? 1 : a[2] + 0
            if (count < 1) count = 1
            if (file != "") printf "%s\t%d\t%d\n", file, start, start + count - 1
        }
    }
' "$DIFF_FILE" > "$RANGES"

ERRORS=0
while IFS=$'\t' read -r report loc; do
    rel="${report#"$ROOT"/}"
    review_id="$(grep -oE 'id="REVIEW-[^"]+"' "$report" | head -1 | sed 's/id="\(REVIEW-[^"]*\)"/\1/')"
    [ -n "$review_id" ] || review_id="REVIEW-$(basename "$report" .md)"
    path="${loc%%:*}"; rest="${loc#*:}"
    line_no="${rest%%:*}"
    found=0
    while IFS=$'\t' read -r f s e; do
        if [ "$f" = "$path" ] && [ "$line_no" -ge "$s" ] && [ "$line_no" -le "$e" ]; then
            found=1
            break
        fi
    done < "$RANGES"
    if [ "$found" -eq 0 ]; then
        echo "INVALID_EVIDENCE|$review_id|$rel|Cited location $loc is not inside the recorded fixed-point diff|Remove or correct the citation, or record not measured"
        ERRORS=$((ERRORS + 1))
    fi
done < "$CITES"

if [ "$ERRORS" -gt 0 ]; then
    echo "FAILED|ERRORS=$ERRORS|RECORDS=$RECORDS|CITED=$CITED"
    exit 1
fi
echo "PASSED|RECORDS=$RECORDS|CITED=$CITED"
exit 0
