#!/usr/bin/env bash
# Tests for scripts/isolate-worktree.sh:
# Verifies worktree creation, error handling on collisions, merge failure detection,
# and safe removal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# Setup test git repo
TEST_REPO="$TEST_ROOT/repo"
mkdir -p "$TEST_REPO"
cd "$TEST_REPO"
git init -b main >/dev/null
git config user.name "PromptKit Test"
git config user.email "test@promptkit.dev"

echo "# Initial" > README.md
git add README.md
git commit -m "initial commit" >/dev/null

ISOLATE_SCRIPT="$REPO_ROOT/scripts/isolate-worktree.sh"

echo "🧪 Running Worktree Isolation Bash Tests..."

# Test 1: Successful create
echo "  [Test 1] Create worktree task-1"
out=$(bash "$ISOLATE_SCRIPT" create task-1)
if [[ ! "$out" =~ "Worktree created successfully" ]]; then
    echo "❌ Test 1 failed: Expected success message, got: $out" >&2
    exit 1
fi
if [[ ! -d ".worktrees/task-1" ]]; then
    echo "❌ Test 1 failed: Directory .worktrees/task-1 does not exist" >&2
    exit 1
fi
echo "  ✅ Test 1 passed"

# Test 2: Failed create on existing branch collision
echo "  [Test 2] Failed create when branch already exists elsewhere"
# create conflicting branch
git branch "worktree/task-conflict"
# now try to isolate-worktree create task-conflict
set +e
err_out=$(bash "$ISOLATE_SCRIPT" create task-conflict 2>&1)
exit_code=$?
set -e
if [[ $exit_code -eq 0 ]]; then
    echo "❌ Test 2 failed: Expected nonzero exit code on branch collision, got 0" >&2
    exit 1
fi
if [[ "$err_out" =~ "Worktree created successfully" ]]; then
    echo "❌ Test 2 failed: Found false success output in error case: $err_out" >&2
    exit 1
fi
echo "  ✅ Test 2 passed: Exit code $exit_code, no false success"

# Test 3: Successful merge
echo "  [Test 3] Successful merge"
cd ".worktrees/task-1"
echo "Feature work" > feature.txt
git add feature.txt
git commit -m "add feature" >/dev/null
cd "$TEST_REPO"

merge_out=$(bash "$ISOLATE_SCRIPT" merge task-1)
if [[ ! "$merge_out" =~ "Merge completed" ]]; then
    echo "❌ Test 3 failed: Expected merge completed, got: $merge_out" >&2
    exit 1
fi
if [[ ! -f "feature.txt" ]]; then
    echo "❌ Test 3 failed: feature.txt not present after merge" >&2
    exit 1
fi
echo "  ✅ Test 3 passed"

# Test 4: Failed merge on conflict
echo "  [Test 4] Failed merge on conflict"
# Create task-conflict2
bash "$ISOLATE_SCRIPT" create task-conflict2 >/dev/null
cd ".worktrees/task-conflict2"
echo "Conflict from branch" > README.md
git commit -am "branch conflicting change" >/dev/null
cd "$TEST_REPO"
echo "Conflict on main" > README.md
git commit -am "main conflicting change" >/dev/null

set +e
merge_err_out=$(bash "$ISOLATE_SCRIPT" merge task-conflict2 2>&1)
merge_exit=$?
set -e
if [[ $merge_exit -eq 0 ]]; then
    echo "❌ Test 4 failed: Expected nonzero exit code on merge conflict, got 0" >&2
    exit 1
fi
if [[ "$merge_err_out" =~ "Merge completed" ]]; then
    echo "❌ Test 4 failed: Found false success output on merge conflict: $merge_err_out" >&2
    exit 1
fi
echo "  ✅ Test 4 passed: Merge conflict exited $merge_exit with no false success"

# Abort conflict merge to clean repo state
git merge --abort >/dev/null 2>&1 || true

# Test 5: Remove worktrees
echo "  [Test 5] Remove worktrees"
bash "$ISOLATE_SCRIPT" remove task-1 >/dev/null
if [[ -d ".worktrees/task-1" ]]; then
    echo "❌ Test 5 failed: .worktrees/task-1 still exists" >&2
    exit 1
fi
bash "$ISOLATE_SCRIPT" remove task-conflict2 --force >/dev/null
if [[ -d ".worktrees/task-conflict2" ]]; then
    echo "❌ Test 5 failed: .worktrees/task-conflict2 still exists" >&2
    exit 1
fi
echo "  ✅ Test 5 passed"

echo "✅ All Worktree Isolation Bash tests passed!"
