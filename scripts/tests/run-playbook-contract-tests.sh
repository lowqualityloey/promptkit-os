#!/usr/bin/env bash
# Regression tests for Playbook Contract validator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🧪 Running Playbook Contract Test Suite..."
bash "$REPO_ROOT/scripts/validate-playbooks.sh" --test-schema

# Also validate any actual playbooks in docs/stacks if the directory exists
if [[ -d "$REPO_ROOT/docs/stacks" ]]; then
    bash "$REPO_ROOT/scripts/validate-playbooks.sh" "$REPO_ROOT/docs/stacks"
fi

# Also validate any actual recipes in docs/recipes if the directory exists
if [[ -d "$REPO_ROOT/docs/recipes" ]]; then
    bash "$REPO_ROOT/scripts/validate-playbooks.sh" "$REPO_ROOT/docs/recipes"
fi

if command -v node >/dev/null 2>&1 && [[ -f "$REPO_ROOT/scripts/tests/verify-auth-session-concurrency.mjs" ]]; then
    echo "🧪 Running Recipe Concurrency Verification (Node)..."
    node "$REPO_ROOT/scripts/tests/verify-auth-session-concurrency.mjs"
fi

echo "✅ All Playbook Contract tests PASSED"

