#!/usr/bin/env bash
# Forwarder for the capture harness. The implementation is capture-host-session.mjs;
# this wrapper exists so the harness can be invoked the same way as every other
# script in this repository, and so the PowerShell twin has a Bash counterpart to
# be compared against.
set -uo pipefail

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="$SCRIPT_DIR/capture-host-session.mjs"

if ! command -v node >/dev/null 2>&1; then
    echo "capture-host-session: node is required but was not found on PATH" >&2
    exit 2
fi

if [ ! -f "$HARNESS" ]; then
    echo "capture-host-session: harness module not found: $HARNESS" >&2
    exit 2
fi

exec node "$HARNESS" "$@"
