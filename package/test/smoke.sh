#!/usr/bin/env bash
# Wrapper smoke test — network-dependent, so it runs in CI (release-npm job), NOT in the
# offline contract suites. Verifies the AC-1 equivalence claim: the npx courier produces a
# .promptkit/ tree whose generated artifacts match the canonical installer path, exercises
# the packaged courier binary directly, and verifies idempotency (directive count stays 1).
#
# Usage: PROMPTKIT_VERSION=1.9.0 bash test/smoke.sh   (a leading "v" is also accepted)
set -euo pipefail

VERSION="${PROMPTKIT_VERSION:-}"
if [ -z "$VERSION" ]; then
    echo "SKIP: PROMPTKIT_VERSION not set (network test; runs only in the release job)"
    exit 0
fi
# The release-tag URL below prepends "v". Strip a caller-supplied prefix so "v1.9.0" and
# "1.9.0" are equivalent — otherwise the documented "v1.9.0" form builds "vv1.9.0" and 404s
# in a way that reads like a missing tag rather than a malformed argument.
VERSION="${VERSION#v}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${PROMPTKIT_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/../.." && pwd))}"
WORK="$(mktemp -d)"

cleanup() {
    rm -rf "$WORK"
}
trap cleanup EXIT

echo "== 1. courier install (exercise packaged courier binary) =="
# Stage a copy of the courier package in a temporary directory before packing.
# This prevents modifying the working tree's package/package.json, preserving any
# unstaged local edits across smoke test execution (R1).
STAGE_PKG_DIR="$WORK/pkg-stage"
mkdir -p "$STAGE_PKG_DIR"
cp -R "$REPO_ROOT/package/." "$STAGE_PKG_DIR/"

# Sync version in the staged copy
(cd "$STAGE_PKG_DIR" && npm version "$VERSION" --no-git-tag-version --allow-same-version >/dev/null)

PACK_DIR="$WORK/pack"
mkdir -p "$PACK_DIR"
(cd "$STAGE_PKG_DIR" && npm pack --pack-destination "$PACK_DIR" >/dev/null)
TARBALL=$(find "$PACK_DIR" -name "promptkit-os-*.tgz" | head -1)
[ -n "$TARBALL" ] || { echo "FAIL: npm pack failed to produce tarball"; exit 1; }
tar -xzf "$TARBALL" -C "$PACK_DIR"
COURIER_BIN="$PACK_DIR/package/bin/promptkit-os.js"
chmod +x "$COURIER_BIN"

COURIER_DIR="$WORK/courier"
mkdir -p "$COURIER_DIR"
(cd "$COURIER_DIR" && PROMPTKIT_NO_INTERACTIVE=1 node "$COURIER_BIN" --balanced "$COURIER_DIR")

echo "== 1b. courier guard: refuse silent overlay of existing .promptkit without --force =="
set +e
refusal_out=$( (cd "$COURIER_DIR" && PROMPTKIT_NO_INTERACTIVE=1 node "$COURIER_BIN" --balanced "$COURIER_DIR") 2>&1 )
refusal_code=$?
set -e

if [ "$refusal_code" -eq 0 ]; then
    echo "FAIL: courier should refuse to overlay an existing non-empty .promptkit without --force"
    exit 1
fi

if ! echo "$refusal_out" | grep -q "Refusing to overlay"; then
    echo "FAIL: courier failed but not with expected overlay refusal diagnostic. Output:"
    echo "$refusal_out"
    exit 1
fi
echo "  ok: courier cleanly refuses to overlay non-empty directory"

echo "== 2. canonical submodule-path install (git materialization of the same tag) =="
CANON_DIR="$WORK/canonical"
mkdir -p "$CANON_DIR/.promptkit"
# Materialize the tag under test from git instead of copying the working tree. Copying
# $REPO_ROOT compares the release tarball against whatever happens to be checked out, so any
# version other than HEAD fails on version drift (23- vs 24-workflow PROMPTKIT.md) rather than
# on the courier-vs-canonical property this test exists to prove. git archive also keeps the
# two doors comparable: tracked files only, exec bit preserved, no VCS metadata to strip.
git -C "$REPO_ROOT" archive "v$VERSION" | tar -x -C "$CANON_DIR/.promptkit"
chmod +x "$CANON_DIR/.promptkit/init.sh"
(cd "$CANON_DIR" && PROMPTKIT_NO_INTERACTIVE=1 bash .promptkit/init.sh --balanced "$CANON_DIR")

echo "== 3. equivalence: generated artifacts must match =="
for f in PROMPTKIT.md docs/STATE.md; do
    if ! diff -q "$COURIER_DIR/$f" "$CANON_DIR/$f" >/dev/null; then
        echo "FAIL: $f differs between courier and canonical paths"
        diff "$COURIER_DIR/$f" "$CANON_DIR/$f" | head -20
        exit 1
    fi
    echo "  ok: $f identical"
done

for d in tasks specs adrs tests; do
    [ -d "$COURIER_DIR/docs/$d" ] || { echo "FAIL: missing docs/$d"; exit 1; }
    echo "  ok: docs/$d present"
done

echo "== 4. idempotency (directive count must remain 1) =="
(cd "$COURIER_DIR" && PROMPTKIT_NO_INTERACTIVE=1 node "$COURIER_BIN" --force --balanced "$COURIER_DIR")
COUNT="$(grep -c '<!-- PROMPTKIT_START -->' "$COURIER_DIR/AGENTS.md")"
[ "$COUNT" -eq 1 ] || { echo "FAIL: directive count = $COUNT (expected 1)"; exit 1; }
echo "  ok: directive count = 1"

echo "== 5. removal leaves nothing =="
rm -rf "$COURIER_DIR/.promptkit" "$COURIER_DIR/PROMPTKIT.md" "$COURIER_DIR/docs/STATE.md"
[ ! -d "$COURIER_DIR/.promptkit" ] || { echo "FAIL: .promptkit survived removal"; exit 1; }
echo "  ok: removal contract holds"

echo "SMOKE PASS (version $VERSION)"
