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

echo "✅ All Playbook Contract tests PASSED"
