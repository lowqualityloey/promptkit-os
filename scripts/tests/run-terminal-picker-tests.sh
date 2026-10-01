#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/terminal-picker.sh"

pk_picker_clear() { :; }
KEYS=()
KEY_INDEX=0
pk_picker_read_key() {
    PK_PICKER_KEY="${KEYS[$KEY_INDEX]}"
    KEY_INDEX=$((KEY_INDEX + 1))
}

KEYS=(down enter)
KEY_INDEX=0
pk_picker_single "Profile" "" 0 balanced lite
[[ "$PK_PICKER_RESULT" == 1 ]] || { echo "single picker did not select the arrow-highlighted item" >&2; exit 1; }

KEYS=(space down space enter)
KEY_INDEX=0
pk_picker_multi "Hosts" "" claude claude "Claude Code" cursor "Cursor"
[[ "$PK_PICKER_RESULT" == cursor ]] || { echo "multi picker did not preserve checkbox toggles" >&2; exit 1; }

KEYS=(cancel)
KEY_INDEX=0
pk_picker_single "Profile" "" 0 balanced lite
[[ "$PK_PICKER_ACTION" == cancel ]] || { echo "single picker did not report cancellation" >&2; exit 1; }

echo "Terminal picker behavior passed (single select, multi-select, cancel)."
