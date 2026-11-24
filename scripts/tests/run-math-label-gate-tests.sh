#!/usr/bin/env bash
# Regression tests for the math-label gate's file scope.
# The gate must see the same *.md set locally as CI checks out: git-tracked plus
# untracked-but-not-ignored files. Before this scope existed the gate scanned every
# *.md on disk, so 4,844 gitignored files (benchmarks, scratch, tmp, .qa-evidence)
# made it green in CI and red on a developer machine.
#
# Run from repository root: bash scripts/tests/run-math-label-gate-tests.sh

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GATE="$REPO_ROOT/scripts/check-math-labels.sh"

PASS=0
FAIL=0

check() {
  local label="$1" expected_exit="$2" actual_exit="$3" out="$4"
  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (expected exit $expected_exit, got $actual_exit)"
    echo "     Output: $out"
    FAIL=$((FAIL + 1))
  fi
}

check_contains() {
  local label="$1" needle="$2" out="$3"
  case "$out" in
    *"$needle"*) echo "  PASS: $label"; PASS=$((PASS + 1)) ;;
    *) echo "  FAIL: $label (missing: $needle)"; echo "     Output: $out"; FAIL=$((FAIL + 1)) ;;
  esac
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

VIOLATION='A label like $\text{dev\_hourly}$ breaks.'

make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  ( cd "$dir" && git init -q . && git config user.email t@example.com && git config user.name t )
}

echo "=== Math Label Gate Scope Tests ==="

# Case 1: a tracked violation fails the gate.
R1="$WORK/tracked"
make_repo "$R1"
printf '%s\n' "$VIOLATION" > "$R1/docs.md"
( cd "$R1" && git add docs.md )
out=$(bash "$GATE" --root "$R1" 2>&1); code=$?
check "Tracked violation fails the gate" 1 "$code" "$out"
check_contains "Tracked violation is reported by relative path" "docs.md:1:" "$out"
check_contains "Gate announces git scope" "MATH_LABEL_GATE|SCOPE|mode=git|files=1" "$out"

# Case 2: a gitignored violation passes, because CI never sees that file.
R2="$WORK/ignored"
make_repo "$R2"
printf '%s\n' 'scratch/' > "$R2/.gitignore"
mkdir -p "$R2/scratch"
printf '%s\n' "$VIOLATION" > "$R2/scratch/notes.md"
printf '%s\n' 'Clean tracked file.' > "$R2/docs.md"
( cd "$R2" && git add .gitignore docs.md )
out=$(bash "$GATE" --root "$R2" 2>&1); code=$?
check "Gitignored violation passes" 0 "$code" "$out"
check_contains "Gitignored file is out of scope" "MATH_LABEL_GATE|SCOPE|mode=git|files=1" "$out"

# Case 3: an untracked-but-not-ignored violation fails, because CI would see it.
R3="$WORK/untracked"
make_repo "$R3"
printf '%s\n' "$VIOLATION" > "$R3/new.md"
out=$(bash "$GATE" --root "$R3" 2>&1); code=$?
check "Untracked-but-not-ignored violation fails" 1 "$code" "$out"
check_contains "Untracked file is in scope" "MATH_LABEL_GATE|SCOPE|mode=git|files=1" "$out"

# Case 4: exempt classes pass even when they carry the violation.
R4="$WORK/exempt"
make_repo "$R4"
mkdir -p "$R4/docs/releases" "$R4/docs/archive" "$R4/docs/internal" "$R4/docs/tasks"
printf '%s\n' "$VIOLATION" > "$R4/docs/releases/r.md"
printf '%s\n' "$VIOLATION" > "$R4/docs/archive/a.md"
printf '%s\n' "$VIOLATION" > "$R4/docs/internal/i.md"
printf '%s\n' "$VIOLATION" > "$R4/docs/tasks/t.md"
printf '%s\n' "$VIOLATION" > "$R4/CHANGELOG.md"
( cd "$R4" && git add -A )
out=$(bash "$GATE" --root "$R4" 2>&1); code=$?
check "Exempt classes pass" 0 "$code" "$out"
check_contains "All five exempt files are in scope but skipped" "MATH_LABEL_GATE|SCOPE|mode=git|files=5" "$out"

# Case 5: a non-git root still detects, via the recursive fallback.
R5="$WORK/plain"
mkdir -p "$R5/nested"
printf '%s\n' "$VIOLATION" > "$R5/nested/notes.md"
out=$(bash "$GATE" --root "$R5" 2>&1); code=$?
check "Non-git root still detects a violation" 1 "$code" "$out"
check_contains "Fallback announces scan scope" "MATH_LABEL_GATE|SCOPE|mode=scan|files=1" "$out"

# Case 6: a clean tree passes.
R6="$WORK/clean"
make_repo "$R6"
printf '%s\n' 'A label like $\text{dev-hourly}$ is fine.' > "$R6/docs.md"
( cd "$R6" && git add docs.md )
out=$(bash "$GATE" --root "$R6" 2>&1); code=$?
check "Clean tree passes" 0 "$code" "$out"
check_contains "Clean tree reports PASS" "MATH_LABEL_GATE|PASS" "$out"

# Case 7: the repository itself is green under git scope.
out=$(bash "$GATE" --root "$REPO_ROOT" 2>&1); code=$?
check "Repository passes under git scope" 0 "$code" "$out"
check_contains "Repository scope is git mode" "MATH_LABEL_GATE|SCOPE|mode=git|" "$out"

echo ""
echo "MATH_LABEL_GATE_TESTS|$PASS passed|$FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
