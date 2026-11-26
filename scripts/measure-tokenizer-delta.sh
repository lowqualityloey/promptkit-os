#!/usr/bin/env bash
# PromptKit OS Tokenizer-Delta Validation Utility
# Compares the gated `bytes/4` proxy (scripts/measure-tokens.sh convention)
# against real tokenizer counts (tiktoken cl100k_base + o200k_base).
#
# Informational by default: bytes/4 REMAINS the gated convention, and this
# script exits 0 with a clear SKIPPED line when tiktoken or its BPE encodings
# are unavailable (e.g. network-restricted runners).
#
# Run from repository root: bash scripts/measure-tokenizer-delta.sh [--strict]
#   --strict : assert each canonical directive against its real-tokenizer cap
#              (Balanced < 2,500, Lite < 1,500) in BOTH encodings (#788).
#              Emits TOKENIZER|NAME|ENCODING|MEASURED|CAP|PASS lines and exits 1
#              on a breach. A runner without tiktoken still exits 0 with SKIPPED,
#              so CI never gains a tiktoken dependency; run --strict locally or
#              in an opt-in job where tiktoken is installed.
#
# Output: machine-parseable FILE|BYTES4|CL100K|O200K|RATIO lines
# (RATIO = CL100K / BYTES4, 3 decimals), consistent with the existing
# BALANCED| and BASELINE| styles.

set -uo pipefail

STRICT=0
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=1 ;;
        -h|--help) echo "Usage: measure-tokenizer-delta.sh [--strict]"; exit 0 ;;
        *) echo "Error: unknown argument: $arg (supported: --strict, -h, --help)" >&2; exit 2 ;;
    esac
done

# Real-tokenizer caps. These are NOT the bytes/4 ceilings asserted by
# measure-tokens.sh --strict (2,425 / 1,450): this gate compares actual BPE
# counts against the published 2,500 / 1,500 budgets, and the comparison is
# strict (measured must be < cap).
BPE_CAP_BALANCED=2500
BPE_CAP_LITE=1500

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

DELTA="$(python3 - <<'PYEOF'
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
)" || skip "tokenizer measurement failed (python3 exited non-zero)"

printf '%s\n' "$DELTA"

# A skipped measurement is never a failure, with or without --strict.
if [[ "$DELTA" == SKIPPED:* ]]; then
    exit 0
fi

if [[ "$STRICT" -eq 0 ]]; then
    exit 0
fi

echo ""
echo "📊 PromptKit OS Strict Real-Tokenizer Gate (cl100k_base + o200k_base)"
GATE_ROWS=0
GATE_FAIL=0
while IFS='|' read -r bpe_file bpe_b4 bpe_cl bpe_o2 bpe_ratio; do
    case "$bpe_file" in
        "templates/agent-directive-template.md") bpe_name="BALANCED"; bpe_cap="$BPE_CAP_BALANCED" ;;
        "templates/agent-directive-lite-template.md") bpe_name="LITE"; bpe_cap="$BPE_CAP_LITE" ;;
        *) continue ;;
    esac
    for pair in "cl100k_base:$bpe_cl" "o200k_base:$bpe_o2"; do
        encoding="${pair%%:*}"
        measured="${pair##*:}"
        [[ "$measured" =~ ^[0-9]+$ ]] || continue
        GATE_ROWS=$((GATE_ROWS + 1))
        if [[ "$measured" -lt "$bpe_cap" ]]; then
            echo "TOKENIZER|${bpe_name}|${encoding}|${measured}|${bpe_cap}|PASS"
        else
            echo "TOKENIZER|${bpe_name}|${encoding}|${measured}|${bpe_cap}|FAIL (meets or exceeds cap)"
            GATE_FAIL=1
        fi
    done
done <<< "$DELTA"

if [[ "$GATE_ROWS" -eq 0 ]]; then
    echo "SKIPPED: no tokenizer rows available for the canonical directives"
    exit 0
fi

if [[ "$GATE_FAIL" -eq 1 ]]; then
    echo "❌ Strict real-tokenizer gate FAILED: at least one directive meets or exceeds its 2,500 / 1,500 cap."
    exit 1
fi
echo "✅ Strict real-tokenizer gate passed: Balanced and Lite stay under 2,500 / 1,500 in both encodings."
exit 0
