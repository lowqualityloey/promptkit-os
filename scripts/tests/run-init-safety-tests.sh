#!/usr/bin/env bash
# Regression tests for non-destructive init.sh directive updates.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
FAKE_BIN="$TEST_ROOT/bin"
PROJECT_ROOT="$TEST_ROOT/project"
MALFORMED_ROOT="$TEST_ROOT/malformed"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$PROJECT_ROOT" "$MALFORMED_ROOT"

cat > "$PROJECT_ROOT/AGENTS.md" <<'EOF'
# User-owned instructions

Keep this content.

<!-- PROMPTKIT_START -->
old directive
<!-- PROMPTKIT_END -->

Keep this content too.
EOF

bash "$REPO_ROOT/init.sh" "$PROJECT_ROOT" >/dev/null

grep -q '^# User-owned instructions$' "$PROJECT_ROOT/AGENTS.md"
grep -q '^Keep this content\.$' "$PROJECT_ROOT/AGENTS.md"
grep -q '^Keep this content too\.$' "$PROJECT_ROOT/AGENTS.md"
grep -q '^## PromptKit OS: Engineering Operating System$' "$PROJECT_ROOT/AGENTS.md"
[[ "$(grep -c '^<!-- PROMPTKIT_START -->$' "$PROJECT_ROOT/AGENTS.md")" -eq 1 ]]
[[ "$(grep -c '^<!-- PROMPTKIT_END -->$' "$PROJECT_ROOT/AGENTS.md")" -eq 1 ]]

# Test: Incomplete marker block fails loudly and preserves file
cat > "$MALFORMED_ROOT/AGENTS.md" <<'EOF'
# User-owned instructions

<!-- PROMPTKIT_START -->
incomplete directive
EOF
before_hash="$(sha256sum "$MALFORMED_ROOT/AGENTS.md" | cut -d' ' -f1)"
if bash "$REPO_ROOT/init.sh" "$MALFORMED_ROOT" >/dev/null 2>&1; then
    echo "Expected malformed directive update to fail." >&2
    exit 1
fi
after_hash="$(sha256sum "$MALFORMED_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]

# Test: Duplicate START markers fail loudly and preserve file
DUP_START_ROOT="$TEST_ROOT/dupstart"
mkdir -p "$DUP_START_ROOT"
cat > "$DUP_START_ROOT/AGENTS.md" <<'EOF'
Header
<!-- PROMPTKIT_START -->
Block 1
<!-- PROMPTKIT_START -->
Block 2
<!-- PROMPTKIT_END -->
EOF
before_hash="$(sha256sum "$DUP_START_ROOT/AGENTS.md" | cut -d' ' -f1)"
if bash "$REPO_ROOT/init.sh" "$DUP_START_ROOT" >/dev/null 2>&1; then
    echo "Expected duplicate START markers to fail." >&2
    exit 1
fi
after_hash="$(sha256sum "$DUP_START_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]

# Test: Duplicate END markers fail loudly and preserve file
DUP_END_ROOT="$TEST_ROOT/dupend"
mkdir -p "$DUP_END_ROOT"
cat > "$DUP_END_ROOT/AGENTS.md" <<'EOF'
Header
<!-- PROMPTKIT_START -->
Block 1
<!-- PROMPTKIT_END -->
<!-- PROMPTKIT_END -->
EOF
before_hash="$(sha256sum "$DUP_END_ROOT/AGENTS.md" | cut -d' ' -f1)"
if bash "$REPO_ROOT/init.sh" "$DUP_END_ROOT" >/dev/null 2>&1; then
    echo "Expected duplicate END markers to fail." >&2
    exit 1
fi
after_hash="$(sha256sum "$DUP_END_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]

# Test: Reversed END-before-START markers fail loudly and preserve file
REVERSED_ROOT="$TEST_ROOT/reversed"
mkdir -p "$REVERSED_ROOT"
cat > "$REVERSED_ROOT/AGENTS.md" <<'EOF'
Header
<!-- PROMPTKIT_END -->
Reversed body
<!-- PROMPTKIT_START -->
Footer
EOF
before_hash="$(sha256sum "$REVERSED_ROOT/AGENTS.md" | cut -d' ' -f1)"
if bash "$REPO_ROOT/init.sh" "$REVERSED_ROOT" >/dev/null 2>&1; then
    echo "Expected reversed markers to fail." >&2
    exit 1
fi
after_hash="$(sha256sum "$REVERSED_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]

# Test: Orphaned END marker fails loudly and preserves file
ORPHANED_END_ROOT="$TEST_ROOT/orphaned_end"
mkdir -p "$ORPHANED_END_ROOT"
cat > "$ORPHANED_END_ROOT/AGENTS.md" <<'EOF'
Header
<!-- PROMPTKIT_END -->
Footer
EOF
before_hash="$(sha256sum "$ORPHANED_END_ROOT/AGENTS.md" | cut -d' ' -f1)"
if bash "$REPO_ROOT/init.sh" "$ORPHANED_END_ROOT" >/dev/null 2>&1; then
    echo "Expected orphaned END marker to fail." >&2
    exit 1
fi
after_hash="$(sha256sum "$ORPHANED_END_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]

# Test: Directive replacement tool failure (awk failure) fails loudly and preserves file
AWK_FAIL_ROOT="$TEST_ROOT/awkfail"
mkdir -p "$AWK_FAIL_ROOT" "$FAKE_BIN"
cat > "$AWK_FAIL_ROOT/AGENTS.md" <<'EOF'
Header
<!-- PROMPTKIT_START -->
old directive
<!-- PROMPTKIT_END -->
Footer
EOF
cat > "$FAKE_BIN/awk" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$FAKE_BIN/awk"

before_hash="$(sha256sum "$AWK_FAIL_ROOT/AGENTS.md" | cut -d' ' -f1)"
if PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/init.sh" "$AWK_FAIL_ROOT" >/dev/null 2>&1; then
    echo "Expected init.sh to fail when replacement tool (awk) fails." >&2
    exit 1
fi
after_hash="$(sha256sum "$AWK_FAIL_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]

# CRLF line ending test
CRLF_ROOT="$TEST_ROOT/crlf"
mkdir -p "$CRLF_ROOT"
printf "Header with \$1 literal dollar reference\r\n\r\nKeep content before.\r\n\r\n<!-- PROMPTKIT_START -->\r\nold directive\r\n<!-- PROMPTKIT_END -->\r\n\r\nKeep content after.\r\n" > "$CRLF_ROOT/AGENTS.md"
bash "$REPO_ROOT/init.sh" "$CRLF_ROOT" >/dev/null
grep -q 'Header with $1 literal dollar reference' "$CRLF_ROOT/AGENTS.md"
grep -q 'Keep content before\.' "$CRLF_ROOT/AGENTS.md"
grep -q 'Keep content after\.' "$CRLF_ROOT/AGENTS.md"
grep -q '## PromptKit OS: Engineering Operating System' "$CRLF_ROOT/AGENTS.md"

# UTF-8 Emoji/CJK content test
UTF8_ROOT="$TEST_ROOT/utf8"
mkdir -p "$UTF8_ROOT"
printf "Header 🚀 🧪 漢字 テスト\n\n<!-- PROMPTKIT_START -->\nold directive\n<!-- PROMPTKIT_END -->\n\nFooter ✨ 祝日\n" > "$UTF8_ROOT/AGENTS.md"
bash "$REPO_ROOT/init.sh" "$UTF8_ROOT" >/dev/null
grep -q '🚀 🧪 漢字 テスト' "$UTF8_ROOT/AGENTS.md"
grep -q '✨ 祝日' "$UTF8_ROOT/AGENTS.md"

# Directory target test (.clinerules/ folder layout)
DIR_ROOT="$TEST_ROOT/dirlayout"
mkdir -p "$DIR_ROOT/.clinerules"
bash "$REPO_ROOT/init.sh" "$DIR_ROOT" >/dev/null
[[ -f "$DIR_ROOT/.clinerules/promptkit.md" ]]
grep -q '## PromptKit OS: Engineering Operating System' "$DIR_ROOT/.clinerules/promptkit.md"

# Test: File permission parity is preserved on update
PERMISSIONS_ROOT="$TEST_ROOT/permissions"
mkdir -p "$PERMISSIONS_ROOT"
cat > "$PERMISSIONS_ROOT/AGENTS.md" <<'EOF'
Header
<!-- PROMPTKIT_START -->
Block 1
<!-- PROMPTKIT_END -->
Footer
EOF
chmod 600 "$PERMISSIONS_ROOT/AGENTS.md"
bash "$REPO_ROOT/init.sh" "$PERMISSIONS_ROOT" >/dev/null
new_perms="$(stat -c "%a" "$PERMISSIONS_ROOT/AGENTS.md")"
if [[ "$new_perms" != "600" ]]; then
    echo "Expected permissions to remain 600, but got $new_perms." >&2
    exit 1
fi

# Strict byte-for-byte idempotency on repeated runs
IDEMPOTENT_ROOT="$TEST_ROOT/idempotent"
mkdir -p "$IDEMPOTENT_ROOT"
printf "# Instructions\n\nKeep me.\n" > "$IDEMPOTENT_ROOT/AGENTS.md"
bash "$REPO_ROOT/init.sh" "$IDEMPOTENT_ROOT" >/dev/null
first_hash="$(sha256sum "$IDEMPOTENT_ROOT/AGENTS.md" | cut -d' ' -f1)"
bash "$REPO_ROOT/init.sh" "$IDEMPOTENT_ROOT" >/dev/null
second_hash="$(sha256sum "$IDEMPOTENT_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$first_hash" == "$second_hash" ]]

# Host selection: --host=opencode on empty dir (hermetic: clean HOME, tool-free PATH)
HOSTSEL_ROOT="$TEST_ROOT/hostsel"
FAKE_HOME="$TEST_ROOT/fakehome"
mkdir -p "$HOSTSEL_ROOT" "$FAKE_HOME"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --host=opencode --balanced "$HOSTSEL_ROOT" >/dev/null
[[ -f "$HOSTSEL_ROOT/.opencode/rules.md" ]]
[[ -f "$HOSTSEL_ROOT/AGENTS.md" ]]
[[ ! -f "$HOSTSEL_ROOT/CLAUDE.md" ]]
grep -q '## PromptKit OS: Engineering Operating System' "$HOSTSEL_ROOT/.opencode/rules.md"

# Host probing: single unambiguous hit wins without flags (fake opencode only)
PROBE_ROOT="$TEST_ROOT/probehit"
FAKE_BIN="$TEST_ROOT/fakebin"
mkdir -p "$PROBE_ROOT" "$FAKE_BIN"
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/opencode"
chmod +x "$FAKE_BIN/opencode"
HOME="$FAKE_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" PROMPTKIT_NO_INTERACTIVE=1 bash "$REPO_ROOT/init.sh" --balanced "$PROBE_ROOT" >/dev/null
[[ -f "$PROBE_ROOT/.opencode/rules.md" ]]
[[ ! -f "$PROBE_ROOT/CLAUDE.md" ]]

# Host probing: multiple hits fall back to deterministic legacy pair
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/aider"
chmod +x "$FAKE_BIN/aider"
MULTI_ROOT="$TEST_ROOT/probemulti"
mkdir -p "$MULTI_ROOT"
HOME="$FAKE_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" PROMPTKIT_NO_INTERACTIVE=1 bash "$REPO_ROOT/init.sh" --balanced "$MULTI_ROOT" >/dev/null
[[ -f "$MULTI_ROOT/AGENTS.md" ]]
[[ -f "$MULTI_ROOT/CLAUDE.md" ]]
[[ ! -f "$MULTI_ROOT/.opencode/rules.md" ]]

# Add-host on existing install preserves content and injects exactly once
ADDHOST_ROOT="$TEST_ROOT/addhost"
mkdir -p "$ADDHOST_ROOT"
printf "# Mine\n" > "$ADDHOST_ROOT/AGENTS.md"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced "$ADDHOST_ROOT" >/dev/null
before_hash="$(sha256sum "$ADDHOST_ROOT/AGENTS.md" | cut -d' ' -f1)"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced --add-host=claude "$ADDHOST_ROOT" >/dev/null
[[ -f "$ADDHOST_ROOT/CLAUDE.md" ]]
after_hash="$(sha256sum "$ADDHOST_ROOT/AGENTS.md" | cut -d' ' -f1)"
[[ "$before_hash" == "$after_hash" ]]
[[ "$(grep -c 'PROMPTKIT_START' "$ADDHOST_ROOT/CLAUDE.md")" -eq 1 ]]

# Custom target is created, injected once across re-runs, and rejects traversal
TARGET_ROOT="$TEST_ROOT/customtarget"
mkdir -p "$TARGET_ROOT"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced --target=docs/AI.md "$TARGET_ROOT" >/dev/null
[[ -f "$TARGET_ROOT/docs/AI.md" ]]
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced --target=docs/AI.md "$TARGET_ROOT" >/dev/null
[[ "$(grep -c 'PROMPTKIT_START' "$TARGET_ROOT/docs/AI.md")" -eq 1 ]]
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --target=../evil "$TARGET_ROOT" >/dev/null 2>&1; then
    echo "Traversal --target=../evil was accepted; expected rejection." >&2
    exit 1
fi
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --host=bogus "$TARGET_ROOT" >/dev/null 2>&1; then
    echo "Unknown --host=bogus was accepted; expected rejection." >&2
    exit 1
fi

# Test: Inline marker example in preamble survives without deleting intervening user prose
INLINE_ROOT="$TEST_ROOT/inlineexample"
mkdir -p "$INLINE_ROOT"
cat > "$INLINE_ROOT/AGENTS.md" <<'EOF'
# Project Instructions

Note: do not remove <!-- PROMPTKIT_START --> manually.

Intervening critical user prose that must be preserved.

<!-- PROMPTKIT_START -->
old directive
<!-- PROMPTKIT_END -->

Trailing footer prose.
EOF
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" "$INLINE_ROOT" >/dev/null
grep -q 'Note: do not remove <!-- PROMPTKIT_START --> manually\.' "$INLINE_ROOT/AGENTS.md"
grep -q '^Intervening critical user prose that must be preserved\.$' "$INLINE_ROOT/AGENTS.md"
grep -q '^Trailing footer prose\.$' "$INLINE_ROOT/AGENTS.md"

# Test: Directive block at the very beginning of the file (line 0)
STARTZERO_ROOT="$TEST_ROOT/startzero"
mkdir -p "$STARTZERO_ROOT"
cat > "$STARTZERO_ROOT/AGENTS.md" <<'EOF'
<!-- PROMPTKIT_START -->
old directive
<!-- PROMPTKIT_END -->

User postamble content.
EOF
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" "$STARTZERO_ROOT" >/dev/null
[[ "$(head -n 1 "$STARTZERO_ROOT/AGENTS.md")" == "<!-- PROMPTKIT_START -->" ]]
grep -q '^User postamble content\.$' "$STARTZERO_ROOT/AGENTS.md"

# Test: Directive block at the very end of the file with no trailing newline
ENDNONL_ROOT="$TEST_ROOT/endnonl"
mkdir -p "$ENDNONL_ROOT"
printf 'User preamble content.\n\n<!-- PROMPTKIT_START -->\nold directive\n<!-- PROMPTKIT_END -->' > "$ENDNONL_ROOT/AGENTS.md"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" "$ENDNONL_ROOT" >/dev/null
grep -q '^User preamble content\.$' "$ENDNONL_ROOT/AGENTS.md"
[[ "$(tail -n 1 "$ENDNONL_ROOT/AGENTS.md")" == "<!-- PROMPTKIT_END -->" ]]

# Test 22: Destination escape containment (F04 - P2)
ESCAPE_ROOT="$TEST_ROOT/escape_project"
OUTSIDE_DIR="$TEST_ROOT/outside"
mkdir -p "$ESCAPE_ROOT" "$OUTSIDE_DIR"
echo "sensitive external file" > "$OUTSIDE_DIR/secret.md"
ln -s "$OUTSIDE_DIR/secret.md" "$ESCAPE_ROOT/AGENTS.md"
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" "$ESCAPE_ROOT" >/dev/null 2>&1; then
    echo "Expected external symlink destination to be rejected; was accepted." >&2
    exit 1
fi
[[ "$(cat "$OUTSIDE_DIR/secret.md")" == "sensitive external file" ]]

# Test 22b: Linked parent directory with target escaping containment (independent root)
ESCAPE_ROOT_2="$TEST_ROOT/escape_project_2"
OUTSIDE_DIR_2="$TEST_ROOT/outside_2"
mkdir -p "$ESCAPE_ROOT_2/real_docs" "$OUTSIDE_DIR_2"
ln -s "$OUTSIDE_DIR_2" "$ESCAPE_ROOT_2/linked_docs"
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --target=linked_docs/AI.md "$ESCAPE_ROOT_2" >/dev/null 2>&1; then
    echo "Expected target in linked external parent directory to be rejected; was accepted." >&2
    exit 1
fi
[[ ! -f "$OUTSIDE_DIR_2/AI.md" ]]

# Test 22c: Canonicalization fallback without realpath (R2 - P2)
NO_REALPATH_DIR="$TEST_ROOT/bin_no_realpath"
mkdir -p "$NO_REALPATH_DIR"
for cmd in awk sed grep cat cp mv rm touch mkdir chmod date sha256sum cut head tail printf; do
    cmd_path="$(command -v "$cmd" || true)"
    [[ -n "$cmd_path" ]] && ln -s "$cmd_path" "$NO_REALPATH_DIR/$cmd"
done
ESCAPE_ROOT_3="$TEST_ROOT/escape_project_3"
OUTSIDE_DIR_3="$TEST_ROOT/outside_3"
mkdir -p "$ESCAPE_ROOT_3" "$OUTSIDE_DIR_3"
echo "secret" > "$OUTSIDE_DIR_3/secret.md"
ln -s "$OUTSIDE_DIR_3/secret.md" "$ESCAPE_ROOT_3/AGENTS.md"
if HOME="$FAKE_HOME" PATH="$NO_REALPATH_DIR" bash "$REPO_ROOT/init.sh" "$ESCAPE_ROOT_3" >/dev/null 2>&1; then
    echo "Expected escape to be rejected even without realpath command; was accepted." >&2
    exit 1
fi
[[ "$(cat "$OUTSIDE_DIR_3/secret.md")" == "secret" ]]

# Test 23: Multiple custom targets with spaces, brackets, commas, and rejected overlaps (F06, R6, R7, R8, R9)
SPACES_ROOT="$TEST_ROOT/spaces_and_globs"
mkdir -p "$SPACES_ROOT/docs"
# Unmarked file with 3 trailing newlines to verify byte-preservation (R9 - P2)
printf "Header line\n\n\n" > "$SPACES_ROOT/docs/unmarked.md"

HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" \
    --target="docs/path with spaces/custom instructions.md" \
    --target="docs/[special-rules]/ai.md" \
    --target="docs/AI,Rules.md" \
    --target="docs/unmarked.md" \
    "$SPACES_ROOT" >/dev/null

[[ -f "$SPACES_ROOT/docs/path with spaces/custom instructions.md" ]]
[[ -f "$SPACES_ROOT/docs/[special-rules]/ai.md" ]]
[[ -f "$SPACES_ROOT/docs/AI,Rules.md" ]]
grep -q '^<!-- PROMPTKIT_START -->$' "$SPACES_ROOT/docs/path with spaces/custom instructions.md"
grep -q '^<!-- PROMPTKIT_START -->$' "$SPACES_ROOT/docs/[special-rules]/ai.md"
grep -q '^<!-- PROMPTKIT_START -->$' "$SPACES_ROOT/docs/AI,Rules.md"

# Verify unmarked.md preserved its original blank lines (R9 - P2)
head -n 3 "$SPACES_ROOT/docs/unmarked.md" | grep -q '^Header line$'

# Verify managed destination overlap rejection (R6 - P2)
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --target=PROMPTKIT.md "$SPACES_ROOT" >/dev/null 2>&1; then
    echo "Expected --target=PROMPTKIT.md to be rejected; was accepted." >&2
    exit 1
fi

# Verify directory target rejection (R7 - P2)
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --target=docs "$SPACES_ROOT" >/dev/null 2>&1; then
    echo "Expected --target=docs (directory) to be rejected; was accepted." >&2
    exit 1
fi

# Test 24: Cline existing file layout, update, and --add-host=cline rerun (F05 - P2)
CLINE_ROOT="$TEST_ROOT/cline_file_layout"
mkdir -p "$CLINE_ROOT"
cat > "$CLINE_ROOT/.clinerules" <<'EOF'
# Cline instructions
<!-- PROMPTKIT_START -->
old directive
<!-- PROMPTKIT_END -->
EOF
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --add-host=cline "$CLINE_ROOT" >/dev/null
[[ -f "$CLINE_ROOT/.clinerules" ]]
[[ ! -d "$CLINE_ROOT/.clinerules" ]]
grep -q '^# Cline instructions$' "$CLINE_ROOT/.clinerules"
grep -q '## PromptKit OS: Engineering Operating System' "$CLINE_ROOT/.clinerules"

# Test 25: Transactional atomicity: pre-validation failure and commit-time write failure rollback (F07 - P2, R5 - P2)
TX_ROOT="$TEST_ROOT/transactional_preservation"
mkdir -p "$TX_ROOT"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --lite "$TX_ROOT" >/dev/null
grep -q '^profile: lite$' "$TX_ROOT/PROMPTKIT.md"

# Part A: Pre-validation failure (reversed markers)
cat > "$TX_ROOT/CLAUDE.md" <<'EOF'
# Claude instructions
<!-- PROMPTKIT_END -->
reversed body
<!-- PROMPTKIT_START -->
EOF

agents_before_hash="$(sha256sum "$TX_ROOT/AGENTS.md" | cut -d' ' -f1)"
claude_before_hash="$(sha256sum "$TX_ROOT/CLAUDE.md" | cut -d' ' -f1)"
profile_before_hash="$(sha256sum "$TX_ROOT/PROMPTKIT.md" | cut -d' ' -f1)"

if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced "$TX_ROOT" >/dev/null 2>&1; then
    echo "Expected transactional update to fail on malformed second target; succeeded." >&2
    exit 1
fi

[[ "$agents_before_hash" == "$(sha256sum "$TX_ROOT/AGENTS.md" | cut -d' ' -f1)" ]]
[[ "$claude_before_hash" == "$(sha256sum "$TX_ROOT/CLAUDE.md" | cut -d' ' -f1)" ]]
[[ "$profile_before_hash" == "$(sha256sum "$TX_ROOT/PROMPTKIT.md" | cut -d' ' -f1)" ]]
grep -q '^profile: lite$' "$TX_ROOT/PROMPTKIT.md"

# Part B: Commit-time write failure rollback (R5 - P2)
# Remove the malformed CLAUDE.md and install valid CLAUDE.md
rm -f "$TX_ROOT/CLAUDE.md"
mkdir -p "$TX_ROOT/readonly_dir"
touch "$TX_ROOT/readonly_dir/locked.md"
chmod 555 "$TX_ROOT/readonly_dir" # makes locked.md unwritable / uncreatable on write

agents_pre_hash="$(sha256sum "$TX_ROOT/AGENTS.md" | cut -d' ' -f1)"
profile_pre_hash="$(sha256sum "$TX_ROOT/PROMPTKIT.md" | cut -d' ' -f1)"

# Update with a valid target and a target inside the unwritable directory
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced --target=readonly_dir/new_target.md "$TX_ROOT" >/dev/null 2>&1; then
    echo "Expected commit-time write failure on unwritable directory; succeeded." >&2
    chmod 755 "$TX_ROOT/readonly_dir"
    exit 1
fi
chmod 755 "$TX_ROOT/readonly_dir"

# Verify rollback restored PROMPTKIT.md and AGENTS.md
[[ "$agents_pre_hash" == "$(sha256sum "$TX_ROOT/AGENTS.md" | cut -d' ' -f1)" ]]
[[ "$profile_pre_hash" == "$(sha256sum "$TX_ROOT/PROMPTKIT.md" | cut -d' ' -f1)" ]]
grep -q '^profile: lite$' "$TX_ROOT/PROMPTKIT.md"

# Test 26: 0600 permissions survive update, including internal symlinks (F10 - P2, R1 - P1)
PERM_ROOT="$TEST_ROOT/perm_test"
mkdir -p "$PERM_ROOT"
cat > "$PERM_ROOT/private_target.md" <<'EOF'
# Private instructions
<!-- PROMPTKIT_START -->
old directive
<!-- PROMPTKIT_END -->
EOF
chmod 600 "$PERM_ROOT/private_target.md"
ln -s "private_target.md" "$PERM_ROOT/AGENTS.md"

HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" "$PERM_ROOT" >/dev/null
perm_after="$(stat -L -c '%a' "$PERM_ROOT/AGENTS.md" 2>/dev/null || stat -L -f '%Lp' "$PERM_ROOT/AGENTS.md" 2>/dev/null)"
target_perm_after="$(stat -c '%a' "$PERM_ROOT/private_target.md" 2>/dev/null || stat -f '%Lp' "$PERM_ROOT/private_target.md" 2>/dev/null)"

[[ "$perm_after" == "600" ]]
[[ "$target_perm_after" == "600" ]]

# --- Install-door structural assert (scripts/check-setup-assert.sh, #549) ---
# A kit copy is a complete engine tree with no .git; each door differs only in
# how that tree is presented. Every scenario asserts the exact ASSERT
# classification line(s), the installer exit code, and the success banner.

copy_kit() {
    local dest="$1"
    mkdir -p "$dest"
    tar -C "$REPO_ROOT" --exclude=.git --exclude=.codegraph -cf - . | tar -C "$dest" -xf -
}

# Test 27: courier door — complete kit tree with no .git classifies as courier
COURIER_PROJ="$TEST_ROOT/assert_courier_project"
COURIER_KIT="$TEST_ROOT/assert_courier_kit"
copy_kit "$COURIER_KIT"
mkdir -p "$COURIER_PROJ"
if courier_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$COURIER_KIT/init.sh" --balanced "$COURIER_PROJ" 2>&1)"; then
    courier_rc=0
else
    courier_rc=$?
fi
[[ "$courier_rc" -eq 0 ]]
grep -q '^ASSERT|courier|tree|OK$' <<<"$courier_out"
grep -q 'PromptKit OS successfully configured' <<<"$courier_out"

# Test 28: partial-copy door — missing manifest files FAIL loudly without rollback
PARTIAL_PROJ="$TEST_ROOT/assert_partial_project"
PARTIAL_KIT="$TEST_ROOT/assert_partial_kit"
copy_kit "$PARTIAL_KIT"
rm -f "$PARTIAL_KIT/workflows/route.md" "$PARTIAL_KIT/templates/project-profile-template.md"
mkdir -p "$PARTIAL_PROJ"
if partial_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$PARTIAL_KIT/init.sh" --balanced "$PARTIAL_PROJ" 2>&1)"; then
    partial_rc=0
else
    partial_rc=$?
fi
[[ "$partial_rc" -eq 1 ]]
grep -q '^ASSERT|partial-copy|missing:templates/project-profile-template.md|FAIL$' <<<"$partial_out"
grep -q '^ASSERT|partial-copy|missing:workflows/route.md|FAIL$' <<<"$partial_out"
grep -q '^ASSERT|partial-copy|remedy|' <<<"$partial_out"
if grep -q 'PromptKit OS successfully configured' <<<"$partial_out"; then
    echo "Expected no success banner on partial-copy failure." >&2
    exit 1
fi
[[ -f "$PARTIAL_PROJ/PROMPTKIT.md" ]]

# Test 29: direct-clone door — kit carrying its own .git resolves to itself
DIRECT_PROJ="$TEST_ROOT/assert_direct_project"
DIRECT_KIT="$TEST_ROOT/assert_direct_kit"
copy_kit "$DIRECT_KIT"
git -C "$DIRECT_KIT" init -q
mkdir -p "$DIRECT_PROJ"
if direct_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$DIRECT_KIT/init.sh" --balanced "$DIRECT_PROJ" 2>&1)"; then
    direct_rc=0
else
    direct_rc=$?
fi
[[ "$direct_rc" -eq 0 ]]
grep -q '^ASSERT|direct-clone|repository|OK$' <<<"$direct_out"
grep -q 'PromptKit OS successfully configured' <<<"$direct_out"

# Test 30: submodule door — host repo with a real .promptkit git submodule
SUB_KITREPO="$TEST_ROOT/assert_sub_kitrepo"
SUB_HOST="$TEST_ROOT/assert_sub_host"
copy_kit "$SUB_KITREPO"
git -C "$SUB_KITREPO" init -q
git -C "$SUB_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid add -A
git -C "$SUB_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m "fixture kit"
mkdir -p "$SUB_HOST"
git -C "$SUB_HOST" init -q
git -C "$SUB_HOST" -c user.name=Fixture -c user.email=fixture@example.invalid -c protocol.file.allow=always submodule add -q "$SUB_KITREPO" .promptkit
if sub_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$SUB_HOST/.promptkit/init.sh" --balanced "$SUB_HOST" 2>&1)"; then
    sub_rc=0
else
    sub_rc=$?
fi
[[ "$sub_rc" -eq 0 ]]
grep -q '^ASSERT|submodule|status|OK$' <<<"$sub_out"
grep -q 'PromptKit OS successfully configured' <<<"$sub_out"

# Test 31: standalone door — kit run in place with PROJECT_ROOT == SCRIPT_DIR
STANDALONE_KIT="$TEST_ROOT/standalone_kit"
copy_kit "$STANDALONE_KIT"
if standalone_out="$(cd "$STANDALONE_KIT" && PROMPTKIT_NO_INTERACTIVE=1 bash ./init.sh --balanced 2>&1)"; then
    standalone_rc=0
else
    standalone_rc=$?
fi
[[ "$standalone_rc" -eq 0 ]]
grep -q '^ASSERT|standalone|tree|OK$' <<<"$standalone_out"
grep -q 'PromptKit OS successfully configured' <<<"$standalone_out"

# Test 32: explicit opt-out — PROMPTKIT_NO_PREFLIGHT=1 skips the assert
OPTOUT_PROJ="$TEST_ROOT/assert_optout_project"
OPTOUT_KIT="$TEST_ROOT/assert_optout_kit"
copy_kit "$OPTOUT_KIT"
mkdir -p "$OPTOUT_PROJ"
if optout_out="$(PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 bash "$OPTOUT_KIT/init.sh" --balanced "$OPTOUT_PROJ" 2>&1)"; then
    optout_rc=0
else
    optout_rc=$?
fi
[[ "$optout_rc" -eq 0 ]]
grep -q '^ASSERT|skipped|USER_OPT_OUT|SKIP$' <<<"$optout_out"
grep -q 'PromptKit OS successfully configured' <<<"$optout_out"

# Test 33: unexpected git status — a failing git probe is INCOMPLETE, not OK
GITFAIL_FAKE="$TEST_ROOT/assert_fake_git_bin"
GITFAIL_PROJ="$TEST_ROOT/assert_gitfail_project"
GITFAIL_KIT="$TEST_ROOT/assert_gitfail_kit"
copy_kit "$GITFAIL_KIT"
git -C "$GITFAIL_KIT" init -q
mkdir -p "$GITFAIL_FAKE" "$GITFAIL_PROJ"
printf '#!/usr/bin/env bash\nexit 42\n' > "$GITFAIL_FAKE/git"
chmod +x "$GITFAIL_FAKE/git"
if gitfail_out="$(PATH="$GITFAIL_FAKE:$PATH" PROMPTKIT_NO_INTERACTIVE=1 bash "$GITFAIL_KIT/init.sh" --balanced "$GITFAIL_PROJ" 2>&1)"; then
    gitfail_rc=0
else
    gitfail_rc=$?
fi
[[ "$gitfail_rc" -eq 2 ]]
grep -q '^ASSERT|unknown|host_git|INCOMPLETE$' <<<"$gitfail_out"
if grep -q 'PromptKit OS successfully configured' <<<"$gitfail_out"; then
    echo "Expected no success banner on INCOMPLETE assert." >&2
    exit 1
fi

echo "init.sh non-destructive update, CRLF/LF compatibility, duplicate/malformed/reversed markers, literal $, awk failure, UTF-8, directory targets, file permissions, byte-idempotency, and install-door structural-assert (courier, partial-copy, direct-clone, submodule, standalone, opt-out, incomplete) tests passed."
