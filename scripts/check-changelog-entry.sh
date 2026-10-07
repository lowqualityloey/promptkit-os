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
    if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
        echo "CHANGELOG_GATE|MISSING-BASE|base ref '$BASE' unavailable on a pull_request event|Ensure the base ref was fetched (fetch-depth) and the range is valid"
        exit 1
    fi
    echo "::warning::CHANGELOG gate skipped (no base ref '$BASE')"
    echo "CHANGELOG_GATE|SKIP|base ref '$BASE' unavailable (shallow or offline checkout)|Fetch it or pass --base"
    exit 0
fi

# Synthetic-base preflight: a base-deriving range is meaningless when either
# endpoint is a tool-owned workspace commit. Read-only; refuses only on positive
# evidence (exit 1), fails closed when the preflight cannot measure (exit 2), and
# fails closed when the preflight file is missing rather than silently skipping.
script_dir="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)" || script_dir="."
detector="$script_dir/check-synthetic-base.sh"
if [ ! -f "$detector" ]; then
    echo "CHANGELOG_GATE|INCOMPLETE|synthetic-base preflight missing at '$detector'|Restore scripts/check-synthetic-base.sh; the preflight must not be skipped"
    exit 2
fi
for endpoint in "$BASE" "$HEAD"; do
    sb_rc=0
    sb_out="$(bash "$detector" --root . --commit "$endpoint")" || sb_rc=$?
    if [ "$sb_rc" -eq 1 ]; then
        printf '%s\n' "$sb_out"
        echo "CHANGELOG_GATE|SYNTHETIC-BASE|refusing to derive $BASE...$HEAD from a synthetic workspace commit ($endpoint)|Return to the carrying branch or rebase onto a real branch tip (docs/MAXIMS.md)"
        exit 1
    fi
    if [ "$sb_rc" -ne 0 ]; then
        printf '%s\n' "$sb_out"
        echo "CHANGELOG_GATE|INCOMPLETE|synthetic-base preflight could not measure '$endpoint' (exit $sb_rc)|Fix the preflight configuration or git state"
        exit 2
    fi
done

files="$(git diff --name-only "$BASE...$HEAD" || true)"
if [ -z "$files" ]; then
    if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
        echo "CHANGELOG_GATE|EMPTY-RANGE|empty diff $BASE...$HEAD on a pull_request event|Ensure the base ref was fetched (fetch-depth) and the range is non-empty"
        exit 1
    fi
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
