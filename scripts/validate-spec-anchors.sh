#!/usr/bin/env bash
# Validate spec anchor citations.
#
# A spec that cites `path/to/file.ext:142` rots silently: the line number drifts the
# moment an unrelated edit lands above it, and the citation keeps looking plausible
# long after it stopped being true. This gate accepts content anchors instead --
# `path/to/file.ext` (anchor: `verbatim content`) -- and fails when the cited file no
# longer contains that text.
#
# A citation is only a claim about a file. It says "this content is over there", and
# the gate checks exactly that and nothing more: it cannot tell whether the claim is
# still the right claim, only whether the words are still present.
#
# Usage: bash scripts/validate-spec-anchors.sh [--root DIR] [SPEC ...]
#        with no SPEC, validates every committed file in docs/specs/.
#
# Exit: 0 all anchors resolve, 1 one or more unresolved, 2 usage/root error.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root) ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "error: --root '$2' is not a directory" >&2; exit 2; }; shift 2 ;;
        -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
        -*) echo "error: unknown option '$1'" >&2; exit 2 ;;
        *) SPEC_DIR="$SPEC_DIR $1"; shift ;;
    esac
done
[[ -d "$ROOT" ]] || { echo "error: root '$ROOT' is not a directory" >&2; exit 2; }

# With no explicit specs, validate the committed public-specification directory.
# Local scratch specs are gitignored by design and are never gated.
if [[ -z "${SPEC_DIR// /}" ]]; then
    while IFS= read -r f; do
        SPEC_DIR="$SPEC_DIR $f"
    done < <(find "$ROOT/docs/specs" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
fi

if [[ -z "${SPEC_DIR// /}" ]]; then
    echo "No specification files found to validate."
    exit 0
fi

TOTAL=0
BAD=0
declare -a FAILED=()

# Must match the PowerShell twin's bare-citation shape exactly, or the two gates disagree
# on how many offending citations a spec contains.
BARE_RE='`[A-Za-z0-9_./-]+\.(sh|ps1|md|js|mjs|json|yml|ymlc):[0-9]+`'

declare -a BARE_REFS=()
BARE_COUNT=0

for spec in $SPEC_DIR; do
    [[ -f "$spec" ]] || { echo "error: no such spec: $spec" >&2; exit 2; }
    spec_label="${spec#"$ROOT"/}"
    line_no=0
    spec_total=0
    spec_bad=0
    # A spec that still cites `path:NNN` is citing a line number, which is the exact
    # rot this gate exists to prevent. Reject it outright rather than letting a spec
    # with no anchors pass vacuously.
    while IFS= read -r bare; do
        bl="${bare%%:*}"; btext="${bare#*:}"
        brefs=$(printf '%s' "$btext" | grep -oE "$BARE_RE" | sort -u)
        for r in $brefs; do
            BARE_COUNT=$((BARE_COUNT + 1)); spec_bad=$((spec_bad + 1))
            printf '  ❌ %s:%s  line-number citation %s -- use `path` (anchor: `content`) instead\n' "$spec_label" "$bl" "$r"
        done
    done < <(grep -nE '[A-Za-z0-9_./-]+\.(sh|ps1|md|js|mjs|json|yml|ymlc):[0-9]+' "$spec" || true)
    # Anchor citations are scanned with awk rather than a shell read loop. Two earlier
    # bash implementations disagreed with the PowerShell twin on how many citations a spec
    # contains -- a `[[ =~ ]]` loop that advanced by substring stripping, and then a
    # `grep -o` pipeline consumed by `read` -- and both silently under-counted. awk walks
    # the line with RSTART/RLENGTH exactly as the twin walks it with Match/Index, so the
    # two gates cannot drift apart on a shared-prefix line.
    # Emits: <path> TAB <anchor> TAB <line number>
    while IFS=$'\t' read -r path anchor bline; do
        [[ -n "$path" ]] || continue
        TOTAL=$((TOTAL + 1)); spec_total=$((spec_total + 1))
        target="$path"
        [[ "$target" != /* ]] && target="$ROOT/$target"
        reason=""
        if [[ ! -f "$target" ]]; then
            reason="file not found"
        elif ! grep -qF -- "$anchor" "$target"; then
            reason="anchor text absent"
        fi
        if [[ -n "$reason" ]]; then
            BAD=$((BAD + 1)); spec_bad=$((spec_bad + 1))
            FAILED+=("  $spec_label:$bline  $path  -- $reason")
            printf '  ❌ %s:%s  %s -- %s\n' "$spec_label" "$bline" "$path" "$reason"
            printf '       anchor: %s\n' "$anchor"
        fi
    done < <(awk '{
        line = $0
        while (match(line, /`[^`]+`[[:space:]]+\(anchor:[[:space:]]*`[^`]+`\)/) > 0) {
            hit = substr(line, RSTART, RLENGTH)
            split(substr(hit, 2, length(hit) - 2), parts, "`")
            printf "%s\t%s\t%d\n", parts[1], parts[3], FNR
            line = substr(line, RSTART + RLENGTH)
        }
    }' "$spec")
    if [[ "$spec_bad" -eq 0 ]]; then
        printf '  ✅ %s -- %s anchor(s) resolve\n' "$spec_label" "$spec_total"
    fi
done

echo ""
echo "Anchor citations checked: $TOTAL | unresolved anchors: $BAD | line-number citations rejected: $BARE_COUNT"
if [[ "$BAD" -gt 0 || "$BARE_COUNT" -gt 0 ]]; then
    echo "❌ spec anchor validation FAILED"
    exit 1
fi
echo "✅ every spec anchor resolves to current content and no line-number citation remains"
exit 0