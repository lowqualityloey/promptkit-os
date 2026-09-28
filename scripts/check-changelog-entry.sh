#!/usr/bin/env bash
# CHANGELOG entry gate: behavior-surface changes must carry a CHANGELOG.md entry.
# Usage: scripts/check-changelog-entry.sh [--base REF] [--head REF]
# Compares the committed range BASE...HEAD (default origin/main...HEAD).
# Skips cleanly when the base ref is unavailable (shallow or offline checkout).

set -u

BASE="origin/main"
HEAD="HEAD"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --base)
            [ "$#" -lt 2 ] && { echo "CHANGELOG_GATE|USAGE|--base requires a ref"; exit 2; }
            BASE="$2"; shift 2 ;;
        --head)
            [ "$#" -lt 2 ] && { echo "CHANGELOG_GATE|USAGE|--head requires a ref"; exit 2; }
            HEAD="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: scripts/check-changelog-entry.sh [--base REF] [--head REF]"; exit 0 ;;
        *)
            echo "CHANGELOG_GATE|USAGE|Unknown argument: $1"; exit 2 ;;
    esac
done

if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
    echo "CHANGELOG_GATE|SKIP|base ref '$BASE' unavailable (shallow or offline checkout)|Fetch it or pass --base"
    exit 0
fi

files="$(git diff --name-only "$BASE...$HEAD" 2>/dev/null || true)"
if [ -z "$files" ]; then
    echo "CHANGELOG_GATE|PASS|empty range $BASE...$HEAD, nothing to gate"
    exit 0
fi

behavior="$(printf '%s\n' "$files" | grep -E '^(workflows/|templates/|protocols/|package/|init\.sh$|init\.ps1$|scripts/[^/]+$)' || true)"
if [ -z "$behavior" ]; then
    echo "CHANGELOG_GATE|PASS|no behavior-surface paths in range, entry not required"
    exit 0
fi

if printf '%s\n' "$files" | grep -qx 'CHANGELOG.md'; then
    echo "CHANGELOG_GATE|PASS|behavior-surface changes carry a CHANGELOG.md entry"
    exit 0
fi

echo "CHANGELOG_GATE|MISSING|behavior-surface changes without a CHANGELOG.md entry:"
printf '%s\n' "$behavior" | sed 's/^/  - /'
echo "CHANGELOG_GATE|REMEDIATION|Add an [Unreleased] entry to CHANGELOG.md (Keep a Changelog)"
exit 1
