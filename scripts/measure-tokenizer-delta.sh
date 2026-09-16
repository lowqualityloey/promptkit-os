#!/usr/bin/env bash
# PromptKit OS Tokenizer-Delta Validation Utility
# Compares the gated `bytes/4` proxy (scripts/measure-tokens.sh convention)
# against real tokenizer counts (tiktoken cl100k_base + o200k_base).
#
# Informational only: bytes/4 REMAINS the gated convention. This script never
# fails the build — it exits 0 with a clear SKIPPED line when tiktoken or its
# BPE encodings are unavailable (e.g. network-restricted runners).
#
# Run from repository root: bash scripts/measure-tokenizer-delta.sh
# Output: machine-parseable FILE|BYTES4|CL100K|O200K|RATIO lines
# (RATIO = CL100K / BYTES4, 3 decimals), consistent with the existing
# BALANCED| and BASELINE| styles.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FILES=(
    "templates/agent-directive-template.md"
    "templates/agent-directive-lite-template.md"
    "workflows/plan.md"
    "workflows/route.md"
    "workflows/fix.md"
    "workflows/ship.md"
    "protocols/discovery-intake.md"
)

skip() {
    echo "SKIPPED: $1"
    exit 0
}

command -v python3 >/dev/null 2>&1 || skip "python3 not found on PATH"
python3 -c "import tiktoken" 2>/dev/null || skip "tiktoken not installed (pip install tiktoken to run this validation)"

export REPO_ROOT
export MEASURE_FILES="${FILES[*]}"

python3 - <<'PYEOF'
import os
import sys

try:
    import tiktoken
except ImportError:
    print("SKIPPED: tiktoken not installed (pip install tiktoken to run this validation)")
    sys.exit(0)

repo = os.environ["REPO_ROOT"]
files = os.environ["MEASURE_FILES"].split(" ")

try:
    encodings = {name: tiktoken.get_encoding(name) for name in ("cl100k_base", "o200k_base")}
except Exception as e:
    print(f"SKIPPED: BPE encodings unreachable ({e})")
    sys.exit(0)

print(f"# tiktoken {tiktoken.__version__} | cl100k_base + o200k_base | FILE|BYTES4|CL100K|O200K|RATIO")
for f in files:
    raw = open(os.path.join(repo, f), "rb").read()
    b4 = (len(raw) + 2) // 4
    text = raw.decode("utf-8")
    cl = len(encodings["cl100k_base"].encode(text))
    o2 = len(encodings["o200k_base"].encode(text))
    print(f"{f}|{b4}|{cl}|{o2}|{cl / b4:.3f}")
PYEOF
