#!/usr/bin/env bash
# Render a capture transcript and its write log from an Antigravity CLI
# (agy) --output-format stream-json event stream.
#
# Usage:
#   render-capture-transcript.sh <session.jsonl> <transcript.md> <observed-writes.log> \
#       --probe <name> --prompt <text> --model <text> [--host <text>] [--invocation <text>]
#
# This is a thin forwarder. The renderer itself lives in
# scripts/render-capture-transcript.mjs, which the PowerShell twin
# (scripts/render-capture-transcript.ps1) invokes as well. Keeping one
# implementation is what makes the Linux/macOS and Windows behaviour identical by
# construction rather than by review: there is no second copy to drift.
#
# The transcript format, the two load-bearing properties (the two-space body
# indent that keeps ^-anchored scorer patterns anchored, and the tool-name to
# scorer-verb mapping), and the reconstructed-timeline caveat are documented in
# the module.

set -uo pipefail

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
RENDERER="$SCRIPT_DIR/render-capture-transcript.mjs"

if ! command -v node >/dev/null 2>&1; then
    echo "render-capture-transcript: node is required but was not found on PATH" >&2
    exit 2
fi

if [ ! -f "$RENDERER" ]; then
    echo "render-capture-transcript: renderer module not found: $RENDERER" >&2
    exit 2
fi

exec node "$RENDERER" "$@"
