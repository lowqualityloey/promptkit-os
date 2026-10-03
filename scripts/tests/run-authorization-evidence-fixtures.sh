#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/promptkit-authz.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT
FIXTURE="$TEMP_ROOT/repo"
mkdir -p "$FIXTURE/docs/tasks"
git -C "$FIXTURE" init -q
git -C "$FIXTURE" -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty -qm baseline
cat > "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md" <<'EOF'
# Task Record
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Commit Evidence**: `old-sha old commit`
EOF
git -C "$FIXTURE" add docs/tasks/TASK-2026-01-01-example.md
git -C "$FIXTURE" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm "seed legacy evidence"
BASELINE="$(git -C "$FIXTURE" rev-parse HEAD)"

assert_result() {
    local name="$1" expected="$2" output actual
    set +e
    output="$(bash "$REPO_ROOT/scripts/validate-authorization-evidence.sh" --root "$FIXTURE" --baseline "$BASELINE" 2>&1)"
    actual=$?
    set -e
    if [ "$actual" -ne "$expected" ]; then echo "FAIL|$name|exit=$actual|$output"; exit 1; fi
    echo "PASS|$name"
}

write_checkpoint() {
    local boundary="$1" batch_ref="$2"
    cat > "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md" <<EOF
# Task Record
- **Mode**: \`Gated Mode\`
- **Batch Authorization**: \`$batch_ref\`
<a id="AUTHZ-example-001"></a>
- **Declared Boundary**: \`$boundary\`
- **Verbatim Human Instruction**: \`Run M1 through review only\`
- **Instruction Source**: \`user message 1\`
- **Frozen Task and Milestone Scope**: \`M1 files only\`
- **Batch Authorization Reference**: \`$batch_ref\`
- **Commit Evidence Entry**: \`abc123 message; Authorization Checkpoint Reference: AUTHZ-example-001; Authorization Source: user message 1\`
EOF
}

assert_result "untouched legacy evidence passes" 0
write_checkpoint review N/A
assert_result "valid run checkpoint reference passes" 0
sed -i 's/Authorization Source: user message 1/Authorization Source:/' "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
assert_result "new entry missing authorization source fails" 1
write_checkpoint review N/A
sed -i '0,/AUTHZ-example-001/s//AUTHZ-missing-001/' "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
assert_result "missing checkpoint fails" 1
write_checkpoint review docs/tasks/batch-example.md
sed -i 's/Declared Boundary/Boundary Removed/' "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
cat > "$FIXTURE/docs/tasks/batch-example.md" <<'EOF'
# Batch Authorization
- **Declared Boundary**: `review`
- **Permitted Actions**: `local commits`
- **Milestone Scope**: `M1`
EOF
sed -i 's/`Gated Mode`/`Approved Batch Mode`/' "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
assert_result "missing checkpoint fields fail" 1
write_checkpoint review docs/tasks/batch-example.md
sed -i 's/`Gated Mode`/`Approved Batch Mode`/' "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
rm -f "$FIXTURE/docs/tasks/batch-example.md"
assert_result "missing batch record fails" 1
cat > "$FIXTURE/docs/tasks/batch-example.md" <<'EOF'
# Batch Authorization
- **Declared Boundary**: `pr`
- **Permitted Actions**: `local commits`
- **Milestone Scope**: `M1`
EOF
assert_result "conflicting run and batch boundary fails" 1
sed -i 's/`pr`/`review`/' "$FIXTURE/docs/tasks/batch-example.md"
assert_result "valid batch authorization link passes" 0
sed -i 's/`review`/review/' "$FIXTURE/docs/tasks/batch-example.md"
assert_result "batch boundary without required markup fails" 1
sed -i 's/Declared Boundary\*\*: review/Declared Boundary**: `final`/' "$FIXTURE/docs/tasks/batch-example.md"
assert_result "unsupported batch boundary fails" 1
sed -i 's/`final`/`review`/' "$FIXTURE/docs/tasks/batch-example.md"
assert_result "restored valid batch boundary passes" 0

echo "AUTHORIZATION_FIXTURES|PASS|11 cases"
