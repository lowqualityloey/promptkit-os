#!/usr/bin/env bash
# PromptKit OS Benchmark Driver Regression Harness (mock CLI)
# Exercises benchmarks/run-ab-benchmark.sh end-to-end — the run path AND
# --finalize — against a stub command-code binary with an isolated HOME, a
# throwaway seed repo, and a throwaway task card. No spend, no real CLI, no
# real ~/.commandcode. Run: bash scripts/tests/run-benchmark-driver-tests.sh
# Bash-only by design: it tests the operator-local Bash orchestrator, which
# deliberately has no PowerShell twin (see benchmarks/README.md).
#
# The stub emulates the observable contract the driver depends on: a headless
# session writes a schema-v3 transcript under
# $HOME/.commandcode/projects/<slug>/, the agent edits a file AND COMMITS it
# (proving the seed-SHA diff anchor), and the last CLI argument is the prompt
# (captured to prove prompt extraction is byte-clean).
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DRIVER="$REPO_ROOT/benchmarks/run-ab-benchmark.sh"

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok - $1"; }
notok() { FAIL=$((FAIL + 1)); echo "  FAIL - $1"; }

TMP_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/bench-driver.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_HOME="$TMP_DIR/home"
BINDIR="$TMP_DIR/bin"
SEED="$TMP_DIR/seed"
OUT="$TMP_DIR/out"
mkdir -p "$FAKE_HOME/.commandcode/taste" "$BINDIR"
: > "$FAKE_HOME/.commandcode/taste/taste.md"   # preflight requires empty

# --- stub command-code ------------------------------------------------------
cat > "$BINDIR/command-code" <<'STUB'
#!/usr/bin/env bash
# Stub of the Command Code CLI for driver regression tests.
if [[ "${1:-}" == "--version" ]]; then echo "stub-1.0.0"; exit 0; fi
if [[ "${1:-}" == "--list-models" ]]; then echo "stub/model-a"; echo "stub/model-b"; exit 0; fi
# A run invocation: record the prompt, write a schema-v3 transcript, edit +
# COMMIT a file (proving the seed-SHA diff anchor), exit 0.
printf '%s\n' "${@: -1}" >> "$HOME/stub-prompts.log"
cwd="$(pwd)"
# Real Command Code slugifies the working directory with
# @sindresorhus/slugify: lowercase, path separators and underscores become
# hyphens. Mirror that shape so the driver's transcript lookup is exercised
# against the same path the real CLI writes.
slug="$(printf '%s' "$cwd" | sed 's#^/##; s#/#-#g' | tr '[:upper:]' '[:lower:]' | sed 's#_#-#g; s#[^a-z0-9-]#-#g; s#-\{2,\}#-#g; s#^-##; s#-$##')"
proj="$HOME/.commandcode/projects/$slug"
mkdir -p "$proj"
sid="stub-$(date +%s%N)-$RANDOM"
{
  printf '{"type":"session","version":3,"id":"%s","timestamp":"2026-10-26T12:00:00.000Z","cwd":"%s"}\n' "$sid" "$cwd"
  printf '{"type":"message","id":"u1","parentId":null,"timestamp":"2026-10-26T12:00:01.000Z","message":{"role":"user","content":[{"type":"text","text":"task"}],"meta":{"source":"user","createdAt":1,"messageId":"u1"}}}\n'
  printf '{"type":"message","id":"a1","parentId":"u1","timestamp":"2026-10-26T12:00:05.000Z","message":{"role":"assistant","content":[{"type":"text","text":"done"}],"meta":{"source":"model","createdAt":2,"messageId":"a1"}},"usage":{"inputTokens":900,"outputTokens":90,"cacheReadTokens":10,"cacheWriteTokens":0,"costUsd":0},"model":"stub/model-a"}\n'
} > "$proj/$sid.jsonl"
printf 'STUB-LINE\n' >> src/app.ts
git add -A
git -c user.name=stub -c user.email=stub@test commit -qm "agent change"
exit 0
STUB
chmod +x "$BINDIR/command-code"

# --- throwaway seed repo and task card --------------------------------------
git init -q "$SEED"
git -C "$SEED" -c user.name=seed -c user.email=seed@test add -A 2>/dev/null || true
mkdir -p "$SEED/src"
printf 'export function main() { return 1; }\n' > "$SEED/src/app.ts"
git -C "$SEED" add -A
git -C "$SEED" -c user.name=seed -c user.email=seed@test commit -qm "seed"
TASK="$TMP_DIR/task.md"
cat > "$TASK" <<'TASK'
# Task Spec: Driver smoke task

- **Task ID**: `BENCH-DRIVER-01`
- **Level**: `L1`
- **Seed Repository**: `throwaway`
- **Prompt**: `"Append the line STUB-LINE to src/app.ts. Do not change any other file."`
- **Setup**: `None`
- **Verify**: `printf 'cwd=%s\n' "$PWD"; grep -c STUB-LINE src/app.ts`

## Rubric

- [ ] `R1`: src/app.ts contains STUB-LINE.
TASK

echo "🧪 Benchmark Driver Regression Harness (mock CLI)"

# --- finalize flag-consumption regression ------------------------------------
# The documented invocation must reach real validation, not UNKNOWN_FLAG.
out="$(PATH="$BINDIR:$PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --finalize "$OUT" --grading "$OUT/grading/grading.tsv" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|UNREADABLE"* && "$out" != *"UNKNOWN_FLAG"* ]]; then
    ok "--finalize consumes its <dir> operand (documented invocation parses)"
else
    notok "--finalize parse (rc=$rc, out=${out:0:160})"
fi

# --- run the batch ------------------------------------------------------------
out="$(PATH="$BINDIR:$PATH" HOME="$FAKE_HOME" BENCH_SHUFFLE_SEED=7 bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$OUT" --max-turns 5 --timeout 60 2>&1)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"PREFLIGHT|OK"* && "$out" == *"BATCH|OK|runs=2"* ]]; then
    ok "batch runs both arms end-to-end against the stub CLI"
else
    notok "batch run (rc=$rc, out=$(printf '%s' "$out" | tail -3 | tr '\n' ' '))"
fi

# --- prompt extraction is byte-clean ------------------------------------------
bad="$(grep -c '[`"]$' "$FAKE_HOME/stub-prompts.log" || true)"
last="$(tail -1 "$FAKE_HOME/stub-prompts.log")"
if [[ "$bad" -eq 0 && "$last" == "Append the line STUB-LINE to src/app.ts. Do not change any other file." ]]; then
    ok "task prompt reaches the CLI byte-clean (no trailing backtick/quote)"
else
    notok "prompt extraction (bad-tails=$bad, last=[$last])"
fi

# --- diff anchored to the seed SHA despite the agent's commit ------------------
row_a="$(grep -m1 "BENCH-DRIVER-01-promptkit_os-r1" "$OUT/manifest.tsv" || true)"
row_b="$(grep -m1 "BENCH-DRIVER-01-bare-r1" "$OUT/manifest.tsv" || true)"
diff_a="$(printf '%s' "$row_a" | cut -f6)"
diff_b="$(printf '%s' "$row_b" | cut -f6)"
if [[ -s "$diff_a" && -s "$diff_b" && "$(cat "$diff_a")" == *"STUB-LINE"* && "$(cat "$diff_b")" == *"STUB-LINE"* ]]; then
    ok "run diffs are anchored to the seed SHA (agent commits preserved)"
else
    notok "seed-SHA diff (a=$(wc -c <"$diff_a" 2>/dev/null)B b=$(wc -c <"$diff_b" 2>/dev/null)B)"
fi

# --- blinding: artifacts stripped in the pk arm, kept in bare ------------------
strip_a="$(printf '%s' "$row_a" | cut -f7)"
strip_b="$(printf '%s' "$row_b" | cut -f7)"
if [[ "$(cat "$strip_a")" != *"AGENTS.md"* && "$(cat "$strip_a")" == *"STUB-LINE"* && "$(cat "$strip_b")" != *"AGENTS.md"* ]]; then
    ok "PromptKit artifacts stripped from the directive arm's grading packet"
else
    notok "strip in batch (a-has-agents=$(grep -c AGENTS.md "$strip_a" || true))"
fi

# --- blind packets: shuffled 1:1 mapping + verify evidence ---------------------
nblind="$(ls "$OUT/grading"/B*.diff 2>/dev/null | wc -l)"
nverify="$(ls "$OUT/grading"/B*.verify.txt 2>/dev/null | wc -l)"
nkey=$(( $(wc -l < "$OUT/grading/key.csv") - 1 ))
vexit_ok="$(grep -l "^verify_exit=0$" "$OUT/grading"/B*.verify.txt 2>/dev/null | wc -l)"
if [[ "$nblind" -eq 2 && "$nkey" -eq 2 && "$nverify" -eq 2 && "$vexit_ok" -eq 2 ]] \
        && grep -q "promptkit_os" "$OUT/grading/key.csv" && grep -q ",BENCH-DRIVER-01-bare-r1" "$OUT/grading/key.csv"; then
    ok "blind packets, key.csv (1:1), and verify packets (exit code recorded) for all runs"
else
    notok "blind packets (diffs=$nblind key=$nkey verify=$nverify vexit=$vexit_ok)"
fi

# --- finalize end-to-end: blind-keyed sheet -> aggregates ----------------------
b1="$(grep -m1 B "$OUT/grading/key.csv" | cut -d, -f1)"
b2="$(tail -1 "$OUT/grading/key.csv" | cut -d, -f1)"
printf '%s\t3\t3\ttrue\n' "$b1" "$b2" > "$OUT/grading/grading.tsv"
out="$(PATH="$BINDIR:$PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --finalize "$OUT" --grading "$OUT/grading/grading.tsv" 2>&1)"; rc=$?
# Stub transcript per run: 900 in / 90 out, no rework, accepted → CPAC = 900*3e-6
# + 90*15e-6 = 0.00405 → machine line prints 0.0040 or 0.0041 at 4dp; assert the
# stable prefix rather than the rounding tail.
if [[ $rc -eq 0 && "$out" == *"BENCH|SUMMARY|arm=bare"* && "$out" == *"BENCH|SUMMARY|arm=promptkit_os"* \
        && "$out" == *"cpac_mean=0.004"* ]] ; then
    ok "--finalize translates blind ids, re-extracts, and aggregates both arms"
else
    notok "finalize (rc=$rc, out=$(printf '%s' "$out" | tail -2 | tr '\n' ' '))"
fi

if grep -q "^${b1}	" "$OUT/grading/grading.tsv" && ! grep -q "BENCH-DRIVER" "$OUT/grading/grading.tsv"; then
    ok "operator grading sheet stays blind-keyed (no scenario/arm ids)"
else
    notok "grading sheet blinding"
fi

# --- verify packets: scrub the run directory and scenario id -----------------
# The mock Verify prints its cwd, mirroring validate-references.sh, whose
# absolute scan paths originally leaked the arm in the Phase 3 L0 packets.
leak="$(grep -lE 'promptkit_os|bare|BENCH-DRIVER|bench-driver' "$OUT/grading"/B*.verify.txt 2>/dev/null || true)"
scrubbed="$(grep -l '<rundir>' "$OUT/grading"/B*.verify.txt 2>/dev/null | wc -l)"
if [[ -z "$leak" && "$scrubbed" -eq 2 ]]; then
    ok "verify packets scrub the run directory and scenario id"
else
    notok "verify packet scrub (leak=${leak:-none} scrubbed=$scrubbed)"
fi

echo ""
echo "Benchmark driver harness (Bash): $PASS passed, $FAIL failed."
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
exit 0
