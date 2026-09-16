#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
INIT_SH="$ROOT_DIR/init.sh"
TEST_DIR="$ROOT_DIR/test-output-saas-sh"

echo "Running SaaS Scaffold tests (Bash)..."

# Cleanup
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

export PROMPTKIT_NO_INTERACTIVE=1

echo "1. Standard init still works (no scaffold runs)"
mkdir -p "$TEST_DIR/standard"
"$INIT_SH" --lite "$TEST_DIR/standard" > /dev/null
if [[ -f "$TEST_DIR/standard/package.json" ]]; then
    echo "FAILED: package.json should not exist in standard init"
    exit 1
fi
echo "✓ Standard init passes"

echo "2. Scaffold creates expected file tree"
mkdir -p "$TEST_DIR/scaffolded"
"$INIT_SH" --saas "$TEST_DIR/scaffolded" > /dev/null
if [[ ! -f "$TEST_DIR/scaffolded/package.json" ]]; then
    echo "FAILED: package.json should exist in scaffolded init"
    exit 1
fi
if [[ ! -f "$TEST_DIR/scaffolded/app/api/auth/[...nextauth]/route.ts" ]]; then
    echo "FAILED: route.ts should exist"
    exit 1
fi
if [[ ! -f "$TEST_DIR/scaffolded/.env.example" ]]; then
    echo "FAILED: .env.example should exist"
    exit 1
fi
echo "✓ Scaffold file tree passes"

echo "3. Non-empty directory aborts"
mkdir -p "$TEST_DIR/nonempty"
touch "$TEST_DIR/nonempty/existing.txt"
set +e
"$INIT_SH" --saas "$TEST_DIR/nonempty" > /dev/null 2>&1
EXIT_CODE=$?
set -e
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "FAILED: Should have aborted on non-empty directory"
    exit 1
fi
echo "✓ Non-empty directory check passes"

echo "All Bash Scaffold tests passed!"
