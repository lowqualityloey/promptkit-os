#!/usr/bin/env bash
# Release-archive export fixture (issue #787).
#
# Extracts `git archive HEAD` - which honours the .gitattributes export-ignore
# rules - and asserts the consumer contract of the extracted archive:
#
#   1. Every maintainer-only tree is absent and the extracted file count drops
#      by more than 80% against the tracked tree.
#   2. No relative Markdown link in a shipped file targets an excluded tree.
#   3. Installing from the extracted tree with init.sh passes
#      check-setup-assert.sh, check-doctor.sh and validate-references.sh --strict.
#
# The PowerShell twin (run-release-archive-export-tests.ps1) asserts the same
# contract through init.ps1 and the .ps1 checkers.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/promptkit-archive-export.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS|%s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL|%s\n' "$1" >&2; }

KIT="$TEMP_ROOT/kit"
PROJECT="$TEMP_ROOT/project"
mkdir -p "$KIT" "$PROJECT"

git -C "$REPO_ROOT" archive --format=tar HEAD | tar -xf - -C "$KIT"

EXCLUDED=(benchmarks docs/internal docs/releases docs/tasks docs/reviews docs/archive docs/tests scripts/tests .github)
for path in "${EXCLUDED[@]}"; do
    if [ -e "$KIT/$path" ]; then
        fail "excluded tree present in the archive: $path"
    else
        pass "excluded from the archive: $path"
    fi
done
if [ -e "$KIT/.gitattributes" ]; then
    fail 'the archive carries .gitattributes'
else
    pass 'excluded from the archive: .gitattributes'
fi

for path in init.sh init.ps1 PROMPTKIT.md README.md QUICKSTART.md FAQ.md LICENSE SECURITY.md; do
    if [ -f "$KIT/$path" ]; then
        pass "consumer path retained: $path"
    else
        fail "consumer path missing from the archive: $path"
    fi
done
for path in workflows protocols templates package docs/stacks docs/recipes docs/adrs; do
    if [ -d "$KIT/$path" ]; then
        pass "consumer directory retained: $path"
    else
        fail "consumer directory missing from the archive: $path"
    fi
done

TRACKED=$(git -C "$REPO_ROOT" ls-tree -r --name-only HEAD | wc -l | tr -d ' ')
EXTRACTED=$(find "$KIT" -type f | wc -l | tr -d ' ')
if [ "$EXTRACTED" -gt $((TRACKED / 5)) ]; then
    fail "archive reduction is below 80%: extracted=$EXTRACTED tracked=$TRACKED"
else
    pass "archive reduction above 80%: extracted=$EXTRACTED tracked=$TRACKED"
fi

if python3 - "$KIT" "${EXCLUDED[@]}" <<'PY'
import os
import posixpath
import re
import sys

kit = sys.argv[1]
excluded = tuple(path + "/" for path in sys.argv[2:])
bad = []
for root, _dirs, files in os.walk(kit):
    for name in sorted(files):
        if not name.endswith(".md"):
            continue
        full = os.path.join(root, name)
        rel = os.path.relpath(full, kit).replace(os.sep, "/")
        with open(full, encoding="utf-8", errors="replace") as handle:
            text = handle.read()
        for match in re.finditer(r"\]\(([^)\s]+)", text):
            target = match.group(1).split("#", 1)[0]
            if not target or target.startswith("/") or re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
                continue
            resolved = posixpath.normpath(posixpath.join(posixpath.dirname(rel), target))
            if resolved.startswith("../"):
                continue
            if any(resolved == path.rstrip("/") or resolved.startswith(path) for path in excluded):
                bad.append(f"{rel} -> {target}")
for entry in bad:
    print(f"FAIL|relative link targets an excluded tree: {entry}")
sys.exit(1 if bad else 0)
PY
then
    pass 'no shipped relative link targets an excluded tree'
else
    FAIL=$((FAIL + 1))
fi

cp -R "$KIT" "$PROJECT/.promptkit"
if ( cd "$PROJECT" && PROMPTKIT_NO_INTERACTIVE=1 bash .promptkit/init.sh --host=agents --balanced </dev/null >"$TEMP_ROOT/init.log" 2>&1 ); then
    pass 'init.sh installed the extracted archive'
else
    fail 'init.sh failed against the extracted archive'
    sed -n '1,40p' "$TEMP_ROOT/init.log" >&2
fi

if bash "$PROJECT/.promptkit/scripts/check-setup-assert.sh" "$PROJECT" "$PROJECT/.promptkit" .promptkit >"$TEMP_ROOT/assert.log" 2>&1; then
    pass 'check-setup-assert.sh passed inside the extracted tree'
else
    fail 'check-setup-assert.sh failed inside the extracted tree'
    sed -n '1,40p' "$TEMP_ROOT/assert.log" >&2
fi
if grep -Eq '^ASSERT\|[^|]+\|tree\|OK' "$TEMP_ROOT/assert.log"; then
    pass 'check-setup-assert.sh classified the install door and its tree as OK'
else
    fail 'check-setup-assert.sh did not report a passing install door'
fi

if bash "$PROJECT/.promptkit/scripts/check-doctor.sh" "$PROJECT" >"$TEMP_ROOT/doctor.log" 2>&1; then
    pass 'check-doctor.sh reported a healthy install'
else
    fail 'check-doctor.sh reported an unhealthy install'
    sed -n '1,40p' "$TEMP_ROOT/doctor.log" >&2
fi

if bash "$PROJECT/.promptkit/scripts/validate-references.sh" "$PROJECT/.promptkit" --strict >"$TEMP_ROOT/references.log" 2>&1; then
    pass 'validate-references.sh --strict passed inside the extracted tree'
else
    fail 'validate-references.sh --strict failed inside the extracted tree'
    sed -n '1,40p' "$TEMP_ROOT/references.log" >&2
fi

printf 'SUMMARY|passed=%d|failed=%d\n' "$PASS" "$FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi