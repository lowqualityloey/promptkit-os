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
    local name="$1" expected="$2" needle="${3:-}" output actual
    set +e
    output="$(bash "$REPO_ROOT/scripts/validate-authorization-evidence.sh" --root "$FIXTURE" --baseline "$BASELINE" 2>&1)"
    actual=$?
    set -e
    if [ "$actual" -ne "$expected" ]; then echo "FAIL|$name|exit=$actual|$output"; exit 1; fi
    if [ -n "$needle" ] && [[ "$output" != *"$needle"* ]]; then echo "FAIL|$name|expected diagnostic '$needle'|$output"; exit 1; fi
    echo "PASS|$name"
}

assert_missing_option_value() {
    local name="$1" option="$2" output actual
    set +e
    output="$(timeout 3 bash "$REPO_ROOT/scripts/validate-authorization-evidence.sh" "$option" 2>&1)"
    actual=$?
    set -e
    if [ "$actual" -ne 2 ] || [[ "$output" != *'Usage: validate-authorization-evidence.sh'* ]]; then
        echo "FAIL|$name|exit=$actual|$output"
        exit 1
    fi
    echo "PASS|$name"
}

assert_missing_option_value 'missing --baseline value exits with usage' --baseline
assert_missing_option_value 'missing --root value exits with usage' --root

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
sed -i "s/\`Gated Mode\`/\`Approved Batch Mode\`/" "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
assert_result "missing checkpoint fields fail" 1
write_checkpoint review docs/tasks/batch-example.md
sed -i "s/\`Gated Mode\`/\`Approved Batch Mode\`/" "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
rm -f "$FIXTURE/docs/tasks/batch-example.md"
assert_result "missing batch record fails" 1
cat > "$FIXTURE/docs/tasks/batch-example.md" <<'EOF'
# Batch Authorization
- **Declared Boundary**: `pr`
- **Permitted Actions**: `local commits`
- **Milestone Scope**: `M1`
EOF
assert_result "conflicting run and batch boundary fails" 1
sed -i "s/\`pr\`/\`review\`/" "$FIXTURE/docs/tasks/batch-example.md"
assert_result "valid batch authorization link passes" 0
sed -i "s/\`review\`/review/" "$FIXTURE/docs/tasks/batch-example.md"
assert_result "batch boundary without required markup fails" 1
sed -i "s/Declared Boundary\\*\\*: review/Declared Boundary**: \`final\`/" "$FIXTURE/docs/tasks/batch-example.md"
assert_result "unsupported batch boundary fails" 1
sed -i "s/\`final\`/\`review\`/" "$FIXTURE/docs/tasks/batch-example.md"
assert_result "restored valid batch boundary passes" 0
ln -s batch-example.md "$FIXTURE/docs/tasks/batch-link.md"
write_checkpoint review docs/tasks/batch-link.md
sed -i "s/\`Gated Mode\`/\`Approved Batch Mode\`/" "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
assert_result "symlinked batch authorization is rejected" 1 "MISSING_BATCH_AUTHORIZATION"
rm "$FIXTURE/docs/tasks/batch-link.md"

cat > "$FIXTURE/docs/tasks/batch-example.md" <<'EOF'
# Batch Authorization
- **Declared Boundary**: `review`
- **Permitted Actions**: `N/A`
- **Milestone Scope**: `None`
EOF
assert_result "placeholder batch actions and scope fail" 1

write_checkpoint review N/A
cat > "$FIXTURE/docs/tasks/TASK-2026-01-02-foreign.md" <<'EOF'
# Foreign Task Record
<a id="AUTHZ-foreign-001"></a>
- **Declared Boundary**: `review`
- **Verbatim Human Instruction**: `Run M1 through review only`
- **Instruction Source**: `user message 1`
- **Frozen Task and Milestone Scope**: `M1 files only`
EOF
cat > "$FIXTURE/docs/tasks/TASK-2026-01-03-borrowed.md" <<'EOF'
# Borrowed Checkpoint
- **Mode**: `Gated Mode`
- **Batch Authorization**: `N/A`
- **Commit Evidence Entry**: `abc123 message; Authorization Checkpoint Reference: AUTHZ-foreign-001; Authorization Source: user message 1`
EOF
assert_result "checkpoint cannot be borrowed from another Task Record" 1

write_checkpoint review N/A
cat > "$FIXTURE/docs/tasks/TASK-2026-01-04 whitespace.md" <<'EOF'
# Untracked Task Record
- **Mode**: `Approved Batch Mode`
- **Batch Authorization**: `N/A`
EOF
assert_result "untracked batch record with spaces is rejected" 1 "MISSING_BATCH_AUTHORIZATION"
rm "$FIXTURE/docs/tasks/TASK-2026-01-04 whitespace.md"

cat > "$TEMP_ROOT/outside-batch.md" <<'EOF'
# Batch Authorization
- **Declared Boundary**: `review`
- **Permitted Actions**: `local commits`
- **Milestone Scope**: `M1`
EOF
write_checkpoint review ../outside-batch.md
sed -i "s/\`Gated Mode\`/\`Approved Batch Mode\`/" "$FIXTURE/docs/tasks/TASK-2026-01-01-example.md"
assert_result "batch authorization cannot escape repository root" 1 "MISSING_BATCH_AUTHORIZATION"

echo "AUTHORIZATION_FIXTURES|PASS|18 cases"
