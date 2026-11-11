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
printf "Header with \$1 literal dollar reference\r\n\r\nKeep content before.\r\n\r\n<!-- PROMPTKIT_START -->\r\nold directive\r\n<!-- PROMPTKIT_END -->\r\n\r\nKeep content after." > "$CRLF_ROOT/AGENTS.md"
bash "$REPO_ROOT/init.sh" "$CRLF_ROOT" >/dev/null
grep -q "Header with \$1 literal dollar reference" "$CRLF_ROOT/AGENTS.md"
grep -q 'Keep content before\.' "$CRLF_ROOT/AGENTS.md"
grep -q 'Keep content after\.' "$CRLF_ROOT/AGENTS.md"
grep -q '## PromptKit OS: Engineering Operating System' "$CRLF_ROOT/AGENTS.md"

# CRLF EOL purity (init.ps1 parity, issue #666): every line ending in the updated
# file must remain CRLF — the POSIX door must not splice LF-only directive lines
# into a CRLF host file. count(LF) == count(CR) iff no lone LF survives.
crlf_lf_count="$(tr -cd '\n' < "$CRLF_ROOT/AGENTS.md" | wc -c | tr -d ' ')"
crlf_cr_count="$(tr -cd '\r' < "$CRLF_ROOT/AGENTS.md" | wc -c | tr -d ' ')"
if [[ "$crlf_lf_count" -ne "$crlf_cr_count" ]]; then
    echo "CRLF update left mixed line endings (LF=$crlf_lf_count, CR=$crlf_cr_count)." >&2
    exit 1
fi

# CRLF inject (issue #666): a CRLF host file WITHOUT a directive block must
# receive the directive in CRLF as well, matching init.ps1's inject semantics.
CRLF_INJECT_ROOT="$TEST_ROOT/crlf_inject"
mkdir -p "$CRLF_INJECT_ROOT"
printf 'CRLF host file without a directive block.\r\nSecond line.\r\n' > "$CRLF_INJECT_ROOT/AGENTS.md"
bash "$REPO_ROOT/init.sh" "$CRLF_INJECT_ROOT" >/dev/null
grep -q '^## PromptKit OS: Engineering Operating System' "$CRLF_INJECT_ROOT/AGENTS.md"
inject_lf_count="$(tr -cd '\n' < "$CRLF_INJECT_ROOT/AGENTS.md" | wc -c | tr -d ' ')"
inject_cr_count="$(tr -cd '\r' < "$CRLF_INJECT_ROOT/AGENTS.md" | wc -c | tr -d ' ')"
if [[ "$inject_lf_count" -ne "$inject_cr_count" ]]; then
    echo "CRLF inject left mixed line endings (LF=$inject_lf_count, CR=$inject_cr_count)." >&2
    exit 1
fi

# CRLF inject rerun (audit follow-up): the second run takes the update path on a
# file whose END marker sits at EOF — it must be byte-stable, leaving no dangling
# CR (CR == LF, same length as the inject output).
inject_len="$(wc -c < "$CRLF_INJECT_ROOT/AGENTS.md" | tr -d ' ')"
bash "$REPO_ROOT/init.sh" "$CRLF_INJECT_ROOT" >/dev/null
rerun_len="$(wc -c < "$CRLF_INJECT_ROOT/AGENTS.md" | tr -d ' ')"
rerun_cr="$(tr -cd '\r' < "$CRLF_INJECT_ROOT/AGENTS.md" | wc -c | tr -d ' ')"
rerun_lf="$(tr -cd '\n' < "$CRLF_INJECT_ROOT/AGENTS.md" | wc -c | tr -d ' ')"
if [[ "$rerun_len" -ne "$inject_len" || "$rerun_cr" -ne "$inject_cr_count" || "$rerun_lf" -ne "$inject_lf_count" ]]; then
    echo "CRLF inject rerun is not byte-stable (inject len=$inject_len CR=$inject_cr_count LF=$inject_lf_count; rerun len=$rerun_len CR=$rerun_cr LF=$rerun_lf)." >&2
    exit 1
fi
rerun_last="$(tail -c 1 "$CRLF_INJECT_ROOT/AGENTS.md" | od -An -tuC | tr -d ' \n')"
[[ "$rerun_last" != "13" ]] || {
    echo "CRLF inject rerun left a dangling CR at EOF." >&2
    exit 1
}

# Containment: a destination symlink pointing OUTSIDE the project root (sibling
# prefix, not a child) must be refused and the external file must not be touched.
SIBLING_ROOT="$TEST_ROOT/sibling"
SIBLING_EVIL="$TEST_ROOT/sibling-evil"
mkdir -p "$SIBLING_ROOT" "$SIBLING_EVIL"
printf 'PRECIOUS SIBLING FILE\n' > "$SIBLING_EVIL/victim.md"
ln -s "$SIBLING_EVIL/victim.md" "$SIBLING_ROOT/AGENTS.md"
if bash "$REPO_ROOT/init.sh" "$SIBLING_ROOT" >/dev/null 2>&1; then
    echo "Expected refusal for destination symlink escaping the project root (sibling prefix)." >&2
    exit 1
fi
grep -q 'PRECIOUS SIBLING FILE' "$SIBLING_EVIL/victim.md" || {
    echo "External sibling file was modified by refused install." >&2
    exit 1
}

# Containment: a swapped PARENT directory (docs/ -> external symlink) must be
# refused for --target writes into it.
PARENT_SWAP_ROOT="$TEST_ROOT/parent_swap"
mkdir -p "$PARENT_SWAP_ROOT" "$SIBLING_EVIL"
ln -s "$SIBLING_EVIL" "$PARENT_SWAP_ROOT/docs"
if bash "$REPO_ROOT/init.sh" --target=docs/extra.md "$PARENT_SWAP_ROOT" >/dev/null 2>&1; then
    echo "Expected refusal for parent-directory symlink escape." >&2
    exit 1
fi
[ ! -e "$SIBLING_EVIL/extra.md" ] || {
    echo "File was created outside the project root via parent-directory symlink." >&2
    exit 1
}

# Rollback through a CONTAINED symlink must still work: the containment guard
# allows in-root destinations, so a failed update restores the linked file.
INT_LINK_ROOT="$TEST_ROOT/intlink"
mkdir -p "$INT_LINK_ROOT/sub"
printf '# Instructions\n\n<!-- PROMPTKIT_START -->\nold directive\n<!-- PROMPTKIT_END -->\n' > "$INT_LINK_ROOT/sub/real.md"
ln -s sub/real.md "$INT_LINK_ROOT/AGENTS.md"
intlink_before="$(sha256sum "$INT_LINK_ROOT/sub/real.md" | cut -d' ' -f1)"
if PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/init.sh" "$INT_LINK_ROOT" >/dev/null 2>&1; then
    echo "Expected awk-failure rollback for contained-symlink target." >&2
    exit 1
fi
intlink_after="$(sha256sum "$INT_LINK_ROOT/sub/real.md" | cut -d' ' -f1)"
[[ "$intlink_before" == "$intlink_after" ]] || {
    echo "Rollback did not restore through a contained symlink." >&2
    exit 1
}

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

# Host selection: --host=cursor writes the managed block into .cursorrules (Scenario 4)
CURSOR_ROOT="$TEST_ROOT/cursorhost"
mkdir -p "$CURSOR_ROOT"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --host=cursor --balanced "$CURSOR_ROOT" >/dev/null
[[ -f "$CURSOR_ROOT/.cursorrules" ]]
[[ "$(grep -c 'PROMPTKIT_START' "$CURSOR_ROOT/.cursorrules")" -eq 1 ]]
grep -q '## PromptKit OS: Engineering Operating System' "$CURSOR_ROOT/.cursorrules"

# Host coverage: a multi-host install carries the block in every host file (Scenario 3)
MULTIHOST_ROOT="$TEST_ROOT/multihost"
mkdir -p "$MULTIHOST_ROOT"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --host=claude,cursor,opencode,gemini,windsurf,copilot,cline,trae,aider --balanced "$MULTIHOST_ROOT" >/dev/null
for rel in CLAUDE.md .cursorrules .opencode/rules.md GEMINI.md .windsurfrules .github/copilot-instructions.md .clinerules/promptkit.md .traerules CONVENTIONS.md; do
    if [[ ! -f "$MULTIHOST_ROOT/$rel" ]]; then
        echo "multi-host install missing $rel" >&2
        exit 1
    fi
    if [[ "$(grep -c 'PROMPTKIT_START' "$MULTIHOST_ROOT/$rel")" -ne 1 ]]; then
        echo "managed block missing or duplicated in $rel" >&2
        exit 1
    fi
done

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

# A file path is rejected as the project root with the friendly error (-d / -PathType Container parity)
touch "$TEST_ROOT/plainfile.txt"
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" "$TEST_ROOT/plainfile.txt" >/dev/null 2>&1; then
    echo "A file path was accepted as the project root; expected rejection." >&2
    exit 1
fi

# '..' inside a legitimate filename is accepted (segment matching, not substring)
DOTDOT_ROOT="$TEST_ROOT/dotdotname"
mkdir -p "$DOTDOT_ROOT"
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced --target=docs/v1..v2.md "$DOTDOT_ROOT" >/dev/null
[[ -f "$DOTDOT_ROOT/docs/v1..v2.md" ]]
HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --balanced --target=docs/v1..v2.md "$DOTDOT_ROOT" >/dev/null
[[ "$(grep -c 'PROMPTKIT_START' "$DOTDOT_ROOT/docs/v1..v2.md")" -eq 1 ]]

# Test: trailing '..' segment is rejected (../evil only pinned the leading segment)
TRAILING_ROOT="$TEST_ROOT/trailingdotdot"
mkdir -p "$TRAILING_ROOT"
if HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/init.sh" --target=docs/.. "$TRAILING_ROOT" >/dev/null 2>&1; then
    echo "Trailing --target=docs/.. was accepted; expected rejection." >&2
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

# Stage a COMPLETE kit at <project>/.promptkit: the installer plus every row of
# scripts/setup-assert-files.txt. That manifest is the single definition of a
# complete kit — the installer reads it to decide whether a staged copy is
# usable, and scripts/check-setup-assert.sh validates the same rows — so the
# fixtures derive the staged set from it instead of hard-coding a second list
# that could drift out of step with the installer.
stage_complete_kit() {
    local project="$1" kit="$2" rel kind
    mkdir -p "$project/.promptkit"
    cp "$kit/init.sh" "$project/.promptkit/init.sh"
    while IFS='|' read -r rel kind; do
        rel="${rel%$'\r'}"
        kind="${kind%$'\r'}"
        if [[ -z "$rel" || "$rel" == \#* ]]; then
            continue
        fi
        if [[ "$kind" == "dir" ]]; then
            mkdir -p "$project/.promptkit/$rel"
            cp -R "$kit/$rel/." "$project/.promptkit/$rel/"
        else
            mkdir -p "$project/.promptkit/$(dirname "$rel")"
            cp "$kit/$rel" "$project/.promptkit/$rel"
        fi
    done < "$kit/scripts/setup-assert-files.txt"
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
# The submodule door stages the kit at .promptkit/, so the relative upgrade
# hint must still be advertised there (dangling-kit coverage lives in test 36).
grep -qF '.promptkit/init.sh' <<<"$sub_out"

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

# Test 31a: kit root == project root renders a relative kit reference. "KIT"
# has no shorter relative form than "."; an absolute value is rendered by the
# template as ".//abs/path", which is not a path.
grep -qF '(`./.`)' "$STANDALONE_KIT/AGENTS.md"
if grep -qF './/' "$STANDALONE_KIT/AGENTS.md" || grep -qF "$STANDALONE_KIT" "$STANDALONE_KIT/AGENTS.md"; then
    echo "Standalone kit rendered an absolute kit reference." >&2
    exit 1
fi

# Test 31b: the kit reference is compared with a path boundary, not a bare
# string prefix. Kit "$X/kitref_project-kit" merely starts with project root
# "$X/kitref_project"; treating that as "kit is inside the project" leaves the
# absolute source path in KIT_DIR_REL, so the directive carries a foreign
# "./abs" path and the banner advertises an external upgrade path.
KITREF_PROJ="$TEST_ROOT/kitref_project"
KITREF_KIT="$TEST_ROOT/kitref_project-kit"
copy_kit "$KITREF_KIT"
mkdir -p "$KITREF_PROJ"
[[ "$KITREF_KIT" == "$KITREF_PROJ"* ]]
if kitref_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$KITREF_KIT/init.sh" --balanced "$KITREF_PROJ" 2>&1)"; then
    kitref_rc=0
else
    kitref_rc=$?
fi
[[ "$kitref_rc" -eq 0 ]]
grep -qF '(`./.promptkit`)' "$KITREF_PROJ/AGENTS.md"
if grep -qF './/' "$KITREF_PROJ/AGENTS.md" || grep -qF "$KITREF_KIT" "$KITREF_PROJ/AGENTS.md"; then
    echo "Sibling kit directory leaked into the directive: kit reference is not path-bounded." >&2
    exit 1
fi
# The sibling-kit scenario leaves .promptkit/ unstaged in the project, so the
# summary warns about the dangling kit reference instead of advertising an
# upgrade path that does not exist there.
grep -qF 'not staged at .promptkit/' <<<"$kitref_out"
if grep -qF "$KITREF_KIT/init.sh" <<<"$kitref_out"; then
    echo "Sibling kit directory leaked into the upgrade hint." >&2
    exit 1
fi

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

# Test 34: GitHub template gate — .github PR/issue templates are created only
# when tracking is GitHub (or GitHub projection); a local-tracking install
# skips them instead of adding .github noise to a non-GitHub project.
GATE_PROJ="$TEST_ROOT/template_gate_project"
GATE_KIT="$TEST_ROOT/template_gate_kit"
copy_kit "$GATE_KIT"
mkdir -p "$GATE_PROJ"
if gate_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$GATE_KIT/init.sh" --balanced "$GATE_PROJ" 2>&1)"; then
    gate_rc=0
else
    gate_rc=$?
fi
[[ "$gate_rc" -eq 0 ]]
[[ ! -e "$GATE_PROJ/.github" ]]
grep -qF 'Skipped: .github PR/issue templates' <<<"$gate_out"
GATE_GH_PROJ="$TEST_ROOT/template_gate_github_project"
GATE_GH_KIT="$TEST_ROOT/template_gate_github_kit"
copy_kit "$GATE_GH_KIT"
mkdir -p "$GATE_GH_PROJ"
if gate_gh_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$GATE_GH_KIT/init.sh" --balanced --tracking=github "$GATE_GH_PROJ" 2>&1)"; then
    gate_gh_rc=0
else
    gate_gh_rc=$?
fi
[[ "$gate_gh_rc" -eq 0 ]]
[[ -f "$GATE_GH_PROJ/.github/pull_request_template.md" ]]
[[ -f "$GATE_GH_PROJ/.github/ISSUE_TEMPLATE/task.md" ]]
grep -qF 'Created: .github/pull_request_template.md' <<<"$gate_gh_out"
grep -qF 'Created: .github/ISSUE_TEMPLATE/task.md' <<<"$gate_gh_out"

# Test 35: freshness-aware hint — a fresh project (no tracked files) is told
# about pk:onboard repo intake; a project with committed code is not.
FRESH_PROJ="$TEST_ROOT/fresh_hint_project"
FRESH_KIT="$TEST_ROOT/fresh_hint_kit"
copy_kit "$FRESH_KIT"
mkdir -p "$FRESH_PROJ"
git -C "$FRESH_PROJ" init -q
if fresh_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$FRESH_KIT/init.sh" --balanced "$FRESH_PROJ" 2>&1)"; then
    fresh_rc=0
else
    fresh_rc=$?
fi
[[ "$fresh_rc" -eq 0 ]]
grep -qF 'Fresh project (no code yet)?' <<<"$fresh_out"
grep -qF 'pk:onboard' <<<"$fresh_out"
BUSY_PROJ="$TEST_ROOT/busy_hint_project"
BUSY_KIT="$TEST_ROOT/busy_hint_kit"
copy_kit "$BUSY_KIT"
mkdir -p "$BUSY_PROJ"
git -C "$BUSY_PROJ" init -q
printf 'fn main() {}\n' > "$BUSY_PROJ/main.rs"
git -C "$BUSY_PROJ" -c user.name=Fixture -c user.email=fixture@example.invalid add -A
git -C "$BUSY_PROJ" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m "fixture code"
if busy_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$BUSY_KIT/init.sh" --balanced "$BUSY_PROJ" 2>&1)"; then
    busy_rc=0
else
    busy_rc=$?
fi
[[ "$busy_rc" -eq 0 ]]
if grep -qF 'Fresh project (no code yet)?' <<<"$busy_out"; then
    echo "Install hint claimed a project with committed code is fresh." >&2
    exit 1
fi

# Test 35b: courier door freshness — the courier extracts the kit into
# .promptkit/ and stages it before running the installer, so the project is
# empty of project content even though .promptkit/ is tracked. The hint must
# still fire; counting the installer-owned tree as "code" would hide it in
# the flow a fresh project actually uses.
COURIER_FRESH_PROJ="$TEST_ROOT/courier_fresh_project"
COURIER_FRESH_KIT="$TEST_ROOT/courier_fresh_kit"
copy_kit "$COURIER_FRESH_KIT"
stage_complete_kit "$COURIER_FRESH_PROJ" "$COURIER_FRESH_KIT"
git -C "$COURIER_FRESH_PROJ" init -q
git -C "$COURIER_FRESH_PROJ" -c user.name=Fixture -c user.email=fixture@example.invalid add -A
if courier_fresh_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$COURIER_FRESH_KIT/init.sh" --balanced "$COURIER_FRESH_PROJ" 2>&1)"; then
    courier_fresh_rc=0
else
    courier_fresh_rc=$?
fi
[[ "$courier_fresh_rc" -eq 0 ]]
grep -qF 'Fresh project (no code yet)?' <<<"$courier_fresh_out"
grep -qF 'pk:onboard' <<<"$courier_fresh_out"

# Test 35c: submodule door freshness — a submodule install adds a .promptkit
# gitlink and a .gitmodules entry, which are installer-owned rather than
# project content. The hint must still fire.
SUB_FRESH_PROJ="$TEST_ROOT/submodule_fresh_project"
SUB_FRESH_KIT="$TEST_ROOT/submodule_fresh_kit"
copy_kit "$SUB_FRESH_KIT"
mkdir -p "$SUB_FRESH_PROJ"
git -C "$SUB_FRESH_PROJ" init -q
git -C "$SUB_FRESH_PROJ" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m "fixture root"
sub_fresh_sha="$(git -C "$SUB_FRESH_PROJ" rev-parse HEAD)"
printf '[submodule ".promptkit"]\n\tpath = .promptkit\n\turl = https://example.invalid/kit.git\n' > "$SUB_FRESH_PROJ/.gitmodules"
git -C "$SUB_FRESH_PROJ" add .gitmodules
git -C "$SUB_FRESH_PROJ" update-index --add --cacheinfo "160000,$sub_fresh_sha,.promptkit"
if sub_fresh_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$SUB_FRESH_KIT/init.sh" --balanced "$SUB_FRESH_PROJ" 2>&1)"; then
    sub_fresh_rc=0
else
    sub_fresh_rc=$?
fi
[[ "$sub_fresh_rc" -eq 0 ]]
grep -qF 'Fresh project (no code yet)?' <<<"$sub_fresh_out"
grep -qF 'pk:onboard' <<<"$sub_fresh_out"

# Test 36: dangling-kit warning — when the engine runs from outside the
# project and nothing staged the kit at .promptkit/, the summary warns and
# suppresses the upgrade hint that points at the unstaged path. Lite profile
# is used so the suppressed "Upgrade anytime" hint is genuinely exercised
# (it is a lite-only summary line).
DANGLE_PROJ="$TEST_ROOT/dangle_hint_project"
DANGLE_KIT="$TEST_ROOT/dangle_hint_kit"
copy_kit "$DANGLE_KIT"
mkdir -p "$DANGLE_PROJ"
if dangle_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$DANGLE_KIT/init.sh" --lite "$DANGLE_PROJ" 2>&1)"; then
    dangle_rc=0
else
    dangle_rc=$?
fi
[[ "$dangle_rc" -eq 0 ]]
grep -qF 'not staged at .promptkit/' <<<"$dangle_out"
grep -qF 'Stage the kit:' <<<"$dangle_out"
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$dangle_out"; then
    echo "Upgrade hint points at an unstaged kit path." >&2
    exit 1
fi

# Test 36b: staged kit — when .promptkit/ carries a COMPLETE kit (the
# installer plus every row of scripts/setup-assert-files.txt), the relative
# upgrade hint is advertised and no dangling warning prints. Lite profile so
# the "Upgrade anytime" hint is genuinely exercised.
STAGED_PROJ="$TEST_ROOT/staged_hint_project"
STAGED_KIT="$TEST_ROOT/staged_hint_kit"
copy_kit "$STAGED_KIT"
stage_complete_kit "$STAGED_PROJ" "$STAGED_KIT"
if staged_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$STAGED_KIT/init.sh" --lite "$STAGED_PROJ" 2>&1)"; then
    staged_rc=0
else
    staged_rc=$?
fi
[[ "$staged_rc" -eq 0 ]]
grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$staged_out"
if grep -qF 'not staged at .promptkit/' <<<"$staged_out"; then
    echo "Dangling warning printed for a staged kit." >&2
    exit 1
fi
if grep -qF 'incomplete copy of the kit' <<<"$staged_out"; then
    echo "Incomplete-copy warning printed for a complete kit." >&2
    exit 1
fi

# Test 36c: partial kit — a .promptkit/ holding the installer but not the
# workflow entry point is a partial copy: the upgrade hint would point at
# pk:* commands that cannot resolve, so the warning must fire and the hint
# must be suppressed. The recovery advice must also match the state AND the
# door: this copy has no .git, so it is a courier install, which has no
# upstream to pull from and must be replaced — and the advice must warn that
# the removal deletes local edits and untracked files.
PARTIAL_PROJ="$TEST_ROOT/partial_hint_project"
PARTIAL_KIT="$TEST_ROOT/partial_hint_kit"
copy_kit "$PARTIAL_KIT"
mkdir -p "$PARTIAL_PROJ/.promptkit"
cp "$PARTIAL_KIT/init.sh" "$PARTIAL_PROJ/.promptkit/init.sh"
if partial_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$PARTIAL_KIT/init.sh" --lite "$PARTIAL_PROJ" 2>&1)"; then
    partial_rc=0
else
    partial_rc=$?
fi
[[ "$partial_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$partial_out"
grep -qF 'Replace it: rm -rf .promptkit' <<<"$partial_out"
grep -qF 'check .promptkit/ for local edits and untracked files first' <<<"$partial_out"
grep -qF -- '--force overlays the existing directory without cleaning it' <<<"$partial_out"
if grep -qF 'Restore it in place:' <<<"$partial_out"; then
    echo "Courier-door partial kit printed the submodule restore advice, which cannot work without a submodule." >&2
    exit 1
fi
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$partial_out"; then
    echo "Upgrade hint advertised from a partial kit copy." >&2
    exit 1
fi
if grep -qF 'Stage the kit:' <<<"$partial_out"; then
    echo "Partial kit printed the stage-from-scratch advice, which cannot succeed on a non-empty .promptkit/." >&2
    exit 1
fi

# Test 36d: the reviewer's tree — .promptkit/ holding exactly the installer and
# the workflow entry point. Both files exist, so a two-file check called this
# staged and advertised an upgrade path whose scripts/ directory was absent;
# the manifest-driven check must call it incomplete.
TWOFILE_PROJ="$TEST_ROOT/twofile_hint_project"
TWOFILE_KIT="$TEST_ROOT/twofile_hint_kit"
copy_kit "$TWOFILE_KIT"
mkdir -p "$TWOFILE_PROJ/.promptkit/workflows"
cp "$TWOFILE_KIT/init.sh" "$TWOFILE_PROJ/.promptkit/init.sh"
cp "$TWOFILE_KIT/workflows/route.md" "$TWOFILE_PROJ/.promptkit/workflows/route.md"
if twofile_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$TWOFILE_KIT/init.sh" --lite "$TWOFILE_PROJ" 2>&1)"; then
    twofile_rc=0
else
    twofile_rc=$?
fi
[[ "$twofile_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$twofile_out"
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$twofile_out"; then
    echo "Upgrade hint advertised from a two-file kit copy." >&2
    exit 1
fi

# Test 36e: a complete kit minus one manifest row is still incomplete. The
# scripts/ directory is the row a two-file copy misses, so removing it from an
# otherwise complete stage must flip the verdict back to incomplete.
MISSINGROW_PROJ="$TEST_ROOT/missingrow_hint_project"
MISSINGROW_KIT="$TEST_ROOT/missingrow_hint_kit"
copy_kit "$MISSINGROW_KIT"
stage_complete_kit "$MISSINGROW_PROJ" "$MISSINGROW_KIT"
rm -rf "$MISSINGROW_PROJ/.promptkit/scripts"
if missingrow_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$MISSINGROW_KIT/init.sh" --lite "$MISSINGROW_PROJ" 2>&1)"; then
    missingrow_rc=0
else
    missingrow_rc=$?
fi
[[ "$missingrow_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$missingrow_out"
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$missingrow_out"; then
    echo "Upgrade hint advertised from a kit copy missing a manifest row." >&2
    exit 1
fi

# Test 36f: submodule door — the same incomplete copy, but installed as a git
# submodule. A submodule DOES have an upstream, so the recovery is an in-place
# restore, not a replacement: "git submodule update --init --force" checks the
# recorded commit out again, which brings back deleted kit files. The plain
# "--init" form does nothing once the recorded commit is already checked out,
# which is why the advice carries --force. The scenario runs the advertised
# command and asserts it actually restores the missing file.
SUBDOOR_KITREPO="$TEST_ROOT/subdoor_kitrepo"
SUBDOOR_HOST="$TEST_ROOT/subdoor_host"
SUBDOOR_RUNNER="$TEST_ROOT/subdoor_runner"
copy_kit "$SUBDOOR_KITREPO"
git -C "$SUBDOOR_KITREPO" init -q
git -C "$SUBDOOR_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid add -A
git -C "$SUBDOOR_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m "fixture kit"
mkdir -p "$SUBDOOR_HOST"
git -C "$SUBDOOR_HOST" init -q
git -C "$SUBDOOR_HOST" -c user.name=Fixture -c user.email=fixture@example.invalid -c protocol.file.allow=always submodule add -q "$SUBDOOR_KITREPO" .promptkit
# A real submodule records .git as a file (a gitdir pointer), not a directory.
[[ -f "$SUBDOOR_HOST/.promptkit/.git" ]]
rm -f "$SUBDOOR_HOST/.promptkit/workflows/debug.md"
copy_kit "$SUBDOOR_RUNNER"
if subdoor_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$SUBDOOR_RUNNER/init.sh" --lite "$SUBDOOR_HOST" 2>&1)"; then
    subdoor_rc=0
else
    subdoor_rc=$?
fi
[[ "$subdoor_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$subdoor_out"
grep -qF 'Restore it in place: git submodule update --init --force .promptkit' <<<"$subdoor_out"
grep -qF 'untracked files such as notes are kept' <<<"$subdoor_out"
if grep -qF 'rm -rf .promptkit' <<<"$subdoor_out"; then
    echo "Submodule-door partial kit was told to delete a copy that can be restored in place." >&2
    exit 1
fi
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$subdoor_out"; then
    echo "Upgrade hint advertised from an incomplete submodule kit." >&2
    exit 1
fi
[[ ! -f "$SUBDOOR_HOST/.promptkit/workflows/debug.md" ]]
git -C "$SUBDOOR_HOST" -c protocol.file.allow=always submodule update --init --force .promptkit >/dev/null 2>&1
[[ -f "$SUBDOOR_HOST/.promptkit/workflows/debug.md" ]]

# Test 36g: an EMPTY scripts/ directory satisfies the "scripts|dir" row and
# nothing else. The installer sources scripts/terminal-picker.sh before it
# parses an argument, so such a copy cannot run — it must be called incomplete
# instead of advertising an upgrade command that dies.
EMPTYSCRIPTS_PROJ="$TEST_ROOT/emptyscripts_hint_project"
EMPTYSCRIPTS_KIT="$TEST_ROOT/emptyscripts_hint_kit"
copy_kit "$EMPTYSCRIPTS_KIT"
stage_complete_kit "$EMPTYSCRIPTS_PROJ" "$EMPTYSCRIPTS_KIT"
rm -rf "$EMPTYSCRIPTS_PROJ/.promptkit/scripts"
mkdir -p "$EMPTYSCRIPTS_PROJ/.promptkit/scripts"
[[ -d "$EMPTYSCRIPTS_PROJ/.promptkit/scripts" ]]
[[ ! -f "$EMPTYSCRIPTS_PROJ/.promptkit/scripts/terminal-picker.sh" ]]
if emptyscripts_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$EMPTYSCRIPTS_KIT/init.sh" --lite "$EMPTYSCRIPTS_PROJ" 2>&1)"; then
    emptyscripts_rc=0
else
    emptyscripts_rc=$?
fi
[[ "$emptyscripts_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$emptyscripts_out"
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$emptyscripts_out"; then
    echo "Upgrade hint advertised from a kit copy with an empty scripts/ directory." >&2
    exit 1
fi

# Test 36h: a missing Lite workflow is incomplete too. The summary tells the
# user to run pk:route, pk:debug, pk:commit, pk:checkpoint, pk:sync and
# pk:profile, so a copy without workflows/debug.md cannot deliver what it
# advertises.
MISSINGWF_PROJ="$TEST_ROOT/missingwf_hint_project"
MISSINGWF_KIT="$TEST_ROOT/missingwf_hint_kit"
copy_kit "$MISSINGWF_KIT"
stage_complete_kit "$MISSINGWF_PROJ" "$MISSINGWF_KIT"
rm -f "$MISSINGWF_PROJ/.promptkit/workflows/debug.md"
if missingwf_out="$(PROMPTKIT_NO_INTERACTIVE=1 bash "$MISSINGWF_KIT/init.sh" --lite "$MISSINGWF_PROJ" 2>&1)"; then
    missingwf_rc=0
else
    missingwf_rc=$?
fi
[[ "$missingwf_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$missingwf_out"
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$missingwf_out"; then
    echo "Upgrade hint advertised from a kit copy missing a Lite workflow." >&2
    exit 1
fi

# Test 36i: a DEINITIALIZED submodule, seen by the install-door assert. "git
# submodule deinit" empties the directory but leaves the gitlink in the parent
# index, so the kit is still REGISTERED even though .promptkit/.git is gone.
# The assert validates the ENGINE tree, so an install run from a separate engine
# still succeeds (test 36j covers that path); point the assert at the staged
# copy to reach the state a user hits when they check .promptkit/ itself. The
# tree check runs before the door classification, so the verdict is
# partial-copy rather than submodule — what matters is that the remedy it
# prints actually restores the kit. The plain "update --remote --merge" form
# does not: it refuses with "Submodule path '.promptkit' not initialized /
# Maybe you want to use 'update --init'?", so the remedy carries --init and
# this scenario runs it.
DEINIT_KITREPO="$TEST_ROOT/deinit_kitrepo"
DEINIT_HOST="$TEST_ROOT/deinit_host"
DEINIT_RUNNER="$TEST_ROOT/deinit_runner"
copy_kit "$DEINIT_KITREPO"
git -C "$DEINIT_KITREPO" init -q
git -C "$DEINIT_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid add -A
git -C "$DEINIT_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m "fixture kit"
mkdir -p "$DEINIT_HOST"
git -C "$DEINIT_HOST" init -q
git -C "$DEINIT_HOST" -c user.name=Fixture -c user.email=fixture@example.invalid -c protocol.file.allow=always submodule add -q "$DEINIT_KITREPO" .promptkit
git -C "$DEINIT_HOST" submodule deinit -f .promptkit >/dev/null 2>&1
[[ -d "$DEINIT_HOST/.promptkit" ]]
[[ ! -e "$DEINIT_HOST/.promptkit/.git" ]]
[[ ! -f "$DEINIT_HOST/.promptkit/init.sh" ]]
copy_kit "$DEINIT_RUNNER"
if deinit_assert_out="$(bash "$DEINIT_RUNNER/scripts/check-setup-assert.sh" "$DEINIT_HOST" "$DEINIT_HOST/.promptkit" ".promptkit" 2>&1)"; then
    deinit_assert_rc=0
else
    deinit_assert_rc=$?
fi
[[ "$deinit_assert_rc" -eq 1 ]]
grep -q '^ASSERT|partial-copy|missing:workflows/route.md|FAIL$' <<<"$deinit_assert_out"
grep -qF 'git submodule update --init --remote --merge .promptkit' <<<"$deinit_assert_out"
git -C "$DEINIT_HOST" -c protocol.file.allow=always submodule update --init --remote --merge .promptkit >/dev/null 2>&1
[[ -f "$DEINIT_HOST/.promptkit/init.sh" ]]

# Test 36j: the same deinitialized submodule on the install path. The assert
# would exit before the summary, so the preflight is opted out (documented at
# PROMPTKIT_NO_PREFLIGHT) and the summary must classify the state as the
# submodule door and name the in-place restore. Before the door was read from
# the parent repository this printed the courier advice and the removal warning.
git -C "$DEINIT_HOST" submodule deinit -f .promptkit >/dev/null 2>&1
[[ ! -f "$DEINIT_HOST/.promptkit/init.sh" ]]
if deinit_out="$(PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 bash "$DEINIT_RUNNER/init.sh" --lite "$DEINIT_HOST" 2>&1)"; then
    deinit_rc=0
else
    deinit_rc=$?
fi
[[ "$deinit_rc" -eq 0 ]]
grep -qF 'incomplete copy of the kit' <<<"$deinit_out"
grep -qF 'Restore it in place: git submodule update --init --force .promptkit' <<<"$deinit_out"
grep -qF 'the parent repository still records it' <<<"$deinit_out"
if grep -qF 'rm -rf .promptkit' <<<"$deinit_out"; then
    echo "A deinitialized submodule was told to delete a copy that can be restored in place." >&2
    exit 1
fi
if grep -qF 'Upgrade anytime: .promptkit/init.sh' <<<"$deinit_out"; then
    echo "Upgrade hint advertised from a deinitialized submodule." >&2
    exit 1
fi
git -C "$DEINIT_HOST" -c protocol.file.allow=always submodule update --init --force .promptkit >/dev/null 2>&1
[[ -f "$DEINIT_HOST/.promptkit/workflows/debug.md" ]]

# Test 36k: a REGISTERED submodule whose directory was DELETED. Nothing is
# staged, so the summary takes the "not staged" branch - but the parent
# repository still records the gitlink, so the advice is the in-place restore
# ("--init checks it out again"), not "git submodule add", which refuses an
# existing index entry with "fatal: '.promptkit' already exists in the index".
DELDIR_KITREPO="$TEST_ROOT/deldir_kitrepo"
DELDIR_HOST="$TEST_ROOT/deldir_host"
DELDIR_RUNNER="$TEST_ROOT/deldir_runner"
copy_kit "$DELDIR_KITREPO"
git -C "$DELDIR_KITREPO" init -q
git -C "$DELDIR_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid add -A
git -C "$DELDIR_KITREPO" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m "fixture kit"
mkdir -p "$DELDIR_HOST"
git -C "$DELDIR_HOST" init -q
git -C "$DELDIR_HOST" -c user.name=Fixture -c user.email=fixture@example.invalid -c protocol.file.allow=always submodule add -q "$DELDIR_KITREPO" .promptkit
rm -rf "$DELDIR_HOST/.promptkit"
[[ ! -d "$DELDIR_HOST/.promptkit" ]]
copy_kit "$DELDIR_RUNNER"
if deldir_out="$(PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 bash "$DELDIR_RUNNER/init.sh" --lite "$DELDIR_HOST" 2>&1)"; then
    deldir_rc=0
else
    deldir_rc=$?
fi
[[ "$deldir_rc" -eq 0 ]]
grep -qF 'the kit is not staged at .promptkit/' <<<"$deldir_out"
grep -qF 'Restore it in place: git submodule update --init --force .promptkit' <<<"$deldir_out"
grep -qF 'the parent repository still records the submodule; --init checks it out again' <<<"$deldir_out"
if grep -qF 'Stage the kit:' <<<"$deldir_out"; then
    echo "A registered submodule with a deleted directory was told to run git submodule add, which refuses the existing index entry." >&2
    exit 1
fi
if grep -qF 'rm -rf .promptkit' <<<"$deldir_out"; then
    echo "A registered submodule with a deleted directory was told to delete nothing." >&2
    exit 1
fi
git -C "$DELDIR_HOST" -c protocol.file.allow=always submodule update --init --force .promptkit >/dev/null 2>&1
[[ -f "$DELDIR_HOST/.promptkit/init.sh" ]]

# Test 37: manifest coverage guard. Every engine-relative path the installers
# resolve must be a row of scripts/setup-assert-files.txt or sit on the
# exemption list below with a written reason. The manifest is what the installer
# uses to decide whether a staged kit is complete, so a hard dependency that
# escapes it makes the installer call a kit complete and then advertise an
# upgrade command that dies at the first step needing the missing file. The
# guard makes that rule mechanical instead of resting on review.
MANIFEST_EXEMPTIONS=(
    "..|path arithmetic: the project root is derived from the engine directory, not read from it"
    ".git|engine identity probe: distinguishes a direct clone from a staged copy; a staged copy legitimately has none"
    "templates/agent-directive-lite-template.md|optional: the installer falls back to the full directive template with a warning"
    "templates/terminal-banner.txt|cosmetic: guarded by a file test and only drawn on an interactive setup"
    "templates/state-tracker-template.md|existence-guarded: docs/STATE.md is only seeded when the template is present"
    "templates/pull-request-template.md|existence-guarded: the PR template is only copied when present"
    "templates/github-issue-template.md|existence-guarded: the issue template is only copied when present"
)
MANIFEST_ROWS=()
while IFS='|' read -r manifest_rel _; do
    manifest_rel="${manifest_rel%$'\r'}"
    if [[ -z "$manifest_rel" || "$manifest_rel" == \#* ]]; then
        continue
    fi
    MANIFEST_ROWS+=("$manifest_rel")
done < "$REPO_ROOT/scripts/setup-assert-files.txt"
[[ "${#MANIFEST_ROWS[@]}" -ge 10 ]]
manifest_is_row() {
    local candidate="$1" row
    for row in "${MANIFEST_ROWS[@]}"; do
        [[ "$row" == "$candidate" ]] && return 0
    done
    return 1
}
manifest_exempt_reason() {
    local candidate="$1" entry
    for entry in "${MANIFEST_EXEMPTIONS[@]}"; do
        if [[ "${entry%%|*}" == "$candidate" ]]; then
            printf '%s' "${entry#*|}"
            return 0
        fi
    done
    return 1
}
manifest_guard() {
    local engine="$1" refs ref reason found=0
    if [[ "$engine" == *.ps1 ]]; then
        # [$] keeps the dollar literal: "\\$(" would start a command substitution.
        refs="$(grep -oE "Join-Path [$](ScriptDir|PSScriptRoot) [\"'][^\"']+[\"']" "$engine" | sed -E "s/.*[\"']([^\"']+)[\"']/\1/" | sort -u)"
    else
        refs="$(grep -oE '\$SCRIPT_DIR/[^"'"'"' )]+' "$engine" | sed 's|^\$SCRIPT_DIR/||' | sort -u)"
    fi
    [[ -n "$refs" ]]
    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        found=$((found + 1))
        manifest_is_row "$ref" && continue
        if reason="$(manifest_exempt_reason "$ref")"; then
            [[ -n "$reason" ]]
            continue
        fi
        echo "Manifest coverage guard: $(basename "$engine") resolves '$ref', which is neither a row of scripts/setup-assert-files.txt nor an exemption with a written reason." >&2
        echo "Add it to the manifest if the installer or its advertised upgrade needs it, or to MANIFEST_EXEMPTIONS in this test with the reason it is optional." >&2
        exit 1
    done <<< "$refs"
    # A regex that stops matching would make the guard vacuous, so a floor on
    # the number of extracted references is part of the assertion.
    [[ "$found" -ge 10 ]]
}
manifest_guard "$REPO_ROOT/init.sh"
echo "Manifest coverage guard: init.sh ok"
manifest_guard "$REPO_ROOT/init.ps1"
echo "Manifest coverage guard: init.ps1 ok"
# An exemption that no longer matches anything is a stale reason: removing or
# renaming a reference must also retire its exemption.
for manifest_entry in "${MANIFEST_EXEMPTIONS[@]}"; do
    manifest_path="${manifest_entry%%|*}"
    if ! grep -qF -- "$manifest_path" "$REPO_ROOT/init.sh" && ! grep -qF -- "$manifest_path" "$REPO_ROOT/init.ps1"; then
        echo "Manifest coverage guard: exemption '$manifest_path' no longer matches any installer reference; retire it with the reference it excused." >&2
        exit 1
    fi
done
echo "init.sh non-destructive update, CRLF/LF compatibility, duplicate/malformed/reversed markers, literal $, awk failure, UTF-8, directory targets, file permissions, byte-idempotency, kit-reference path-bounding (sibling prefix, root equality), GitHub-template tracking gate, freshness-aware hint (empty, busy, courier-staged, submodule-staged), dangling-kit warning (unstaged, complete, partial, two-file, missing-manifest-row, empty-scripts, missing-lite-workflow, deinitialized-submodule, deleted-submodule-directory) with install-door-matched recovery advice (courier replace with a data-loss warning, submodule in-place restore verified end to end, deinitialized and deleted-directory submodules restored in place), install-door structural-assert (courier, partial-copy, direct-clone, submodule, standalone, opt-out, incomplete), and manifest coverage guard (every engine-relative reference is a manifest row or a reasoned exemption) tests passed."
