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
CLEAN_PATH="$BINDIR:/usr/bin:/bin"
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
# Snapshot the pre-registered plan on the FIRST session only. The old driver
# appended order.tsv inside the run loop, so this file would hold one row (or
# none) instead of the complete plan.
if [[ -n "${STUB_SNAPSHOT_OUT:-}" && ! -f "$HOME/order-at-first-session.tsv" \
        && -f "$STUB_SNAPSHOT_OUT/order.tsv" ]]; then
    cp "$STUB_SNAPSHOT_OUT/order.tsv" "$HOME/order-at-first-session.tsv"
fi
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
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --finalize "$OUT" --grading "$OUT/grading/grading.tsv" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|UNREADABLE"* && "$out" != *"UNKNOWN_FLAG"* ]]; then
    ok "--finalize consumes its <dir> operand (documented invocation parses)"
else
    notok "--finalize parse (rc=$rc, out=${out:0:160})"
fi

# --- second task card (multi-block schedule) ---------------------------------
TASK2="$TMP_DIR/task2.md"
cat > "$TASK2" <<'TASK2EOF'
# Task Spec: Driver smoke task 2

- **Task ID**: `BENCH-DRIVER-02`
- **Level**: `L1`
- **Seed Repository**: `throwaway`
- **Prompt**: `"Append the line STUB-LINE to src/app.ts. Do not change any other file."`
- **Setup**: `None`
- **Verify**: `None`

## Rubric

- [ ] `R1`: src/app.ts contains STUB-LINE.
TASK2EOF

# --- run the batch ------------------------------------------------------------
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$OUT" --max-turns 5 --timeout 60 \
    --order-seed 7 --shuffle-seed 7 2>&1)"; rc=$?
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
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
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

# --- seeded schedule: no pre-registered seed, no batch ----------------------
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$TMP_DIR/out-noseed" --preflight-only 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|MISSING|order-seed"* && ! -e "$TMP_DIR/out-noseed" ]]; then
    ok "run refuses to start without a pre-registered --order-seed"
else
    notok "order-seed refusal (rc=$rc, out=${out:0:160})"
fi

# --- blind shuffle seed is pre-registered too --------------------------------
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" BENCH_SHUFFLE_SEED= bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$TMP_DIR/out-noshuffle" \
    --order-seed 7 --preflight-only 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|MISSING|shuffle-seed"* && ! -e "$TMP_DIR/out-noshuffle" ]]; then
    ok "run refuses to start without a pre-registered --shuffle-seed"
else
    notok "shuffle-seed refusal (rc=$rc, out=${out:0:160})"
fi

# --- preflight validates the task slate, not just the environment ------------
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TMP_DIR/missing-task.md" \
    --model stub/model-a --out "$TMP_DIR/out-badtask" \
    --order-seed 7 --shuffle-seed 7 --preflight-only 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|UNREADABLE|$TMP_DIR/missing-task.md"* && "$out" != *"PREFLIGHT|OK"* ]]; then
    ok "--preflight-only rejects a missing task card before printing PREFLIGHT|OK"
else
    notok "preflight task validation (rc=$rc, out=${out:0:200})"
fi

# --- duplicate Task IDs cannot collide on the same run directory -------------
DUP_TASK="$TMP_DIR/task-dup.md"
cp "$TASK" "$DUP_TASK"
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK,$DUP_TASK" \
    --model stub/model-a --out "$TMP_DIR/out-dup" \
    --order-seed 7 --shuffle-seed 7 --preflight-only 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|DUPLICATE_TASK|BENCH-DRIVER-01"* && "$out" != *"PREFLIGHT|OK"* ]]; then
    ok "duplicate Task IDs are rejected before any session"
else
    notok "duplicate task id (rc=$rc, out=${out:0:200})"
fi

# --- seeded schedule: complete plan, executed as written ---------------------
# Seed 7 puts bare first for this task, the opposite of the legacy fixed order,
# so a driver that ignored order.tsv would run promptkit_os first and fail.
OUT_SCHED="$TMP_DIR/out-sched"
rm -f "$FAKE_HOME/order-at-first-session.tsv"
out_sched="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" STUB_SNAPSHOT_OUT="$OUT_SCHED" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$OUT_SCHED" --max-turns 5 --timeout 60 \
    --order-seed 7 --shuffle-seed 7 2>&1)"; rc=$?
plan="$OUT_SCHED/order.tsv"
snap_rows=$(( $(wc -l < "$FAKE_HOME/order-at-first-session.tsv" 2>/dev/null || echo 0) - 1 ))
if [[ "$snap_rows" -eq 2 ]] && cmp -s "$FAKE_HOME/order-at-first-session.tsv" "$plan"; then
    ok "order.tsv is fully materialized before the first session starts"
else
    notok "pre-session plan (rows=$snap_rows)"
fi
plan_rows=$(( $(wc -l < "$plan") - 1 ))
planned="$(tail -n +2 "$plan" | awk -F'\t' '{print $2"-"$3"-r"$4}')"
executed="$(printf '%s\n' "$out_sched" | grep '^RUNDONE|' | cut -d'|' -f2)"
if [[ $rc -eq 0 && "$plan_rows" -eq 2 && "$executed" == "$planned" \
        && "$(printf '%s\n' "$planned" | head -1)" == "BENCH-DRIVER-01-bare-r1" ]]; then
    ok "order.tsv is complete and the batch executes exactly that plan"
else
    notok "seeded plan (rc=$rc rows=$plan_rows)"
fi

OUT_REPEAT="$TMP_DIR/out-repeat"
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$OUT_REPEAT" --max-turns 5 --timeout 60 \
    --order-seed 7 --shuffle-seed 7 2>&1)"; rc=$?
if [[ $rc -eq 0 && "$(cat "$OUT_REPEAT/order.tsv")" == "$(cat "$plan")" ]] \
        && cmp -s "$OUT_REPEAT/grading/key.csv" "$OUT/grading/key.csv"; then
    ok "the same seeds reproduce a byte-identical plan and blind key"
else
    notok "plan/key reproducibility (rc=$rc)"
fi

# --- seeded schedule: task blocks and per-block arm order -------------------
OUT_MULTI="$TMP_DIR/out-multi"
out_multi="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK,$TASK2" \
    --model stub/model-a --out "$OUT_MULTI" --max-turns 5 --timeout 60 \
    --order-seed 11 --shuffle-seed 7 2>&1)"; rc=$?
planned_multi="$(tail -n +2 "$OUT_MULTI/order.tsv" | awk -F'\t' '{print $2"-"$3"-r"$4}')"
executed_multi="$(printf '%s\n' "$out_multi" | grep '^RUNDONE|' | cut -d'|' -f2)"
first_01="$(awk -F'\t' '$2=="BENCH-DRIVER-01"{print $3; exit}' "$OUT_MULTI/order.tsv")"
first_02="$(awk -F'\t' '$2=="BENCH-DRIVER-02"{print $3; exit}' "$OUT_MULTI/order.tsv")"
per_task="$(tail -n +2 "$OUT_MULTI/order.tsv" | cut -f2 | sort | uniq -c | awk '{print $1}' | sort -u)"
if [[ $rc -eq 0 && "$out_multi" == *"BATCH|OK|runs=4"* \
        && "$executed_multi" == "$planned_multi" && "$per_task" == "2" \
        && -n "$first_01" && -n "$first_02" && "$first_01" != "$first_02" ]]; then
    ok "both task blocks run every cell, with arm order shuffled per block"
else
    notok "multi-block schedule (rc=$rc per_task=$per_task first=$first_01/$first_02)"
fi

# --- isolation guard: every refused surface fails closed --------------------
expect_preflight_fail() {
    local label="$1" want="$2" home="$3" seed="$4" path="$5"
    local got rcf
    got="$(PATH="$path" HOME="$home" bash "$DRIVER" --engine "$REPO_ROOT" \
        --seed "$seed" --tasks "$TASK" --model stub/model-a \
        --out "$TMP_DIR/out-$label" --order-seed 7 --shuffle-seed 7 --preflight-only 2>&1)"; rcf=$?
    if [[ $rcf -eq 2 && "$got" == *"$want"* ]]; then
        ok "isolation guard: $label"
    else
        notok "isolation guard: $label (rc=$rcf, out=${got:0:200})"
    fi
}

expect_preflight_ok() {
    local label="$1" home="$2"
    local got rcf
    got="$(PATH="$CLEAN_PATH" HOME="$home" bash "$DRIVER" --engine "$REPO_ROOT" \
        --seed "$SEED" --tasks "$TASK" --model stub/model-a \
        --out "$TMP_DIR/out-$label" --order-seed 7 --shuffle-seed 7 --preflight-only 2>&1)"; rcf=$?
    if [[ $rcf -eq 0 && "$got" == *"ISOLATION|OK"* && "$got" == *"PREFLIGHT|OK"* ]] \
            && grep -q '^shuffle_seed: 7$' "$TMP_DIR/out-$label/isolation.txt" \
            && [[ "$(($(wc -l < "$TMP_DIR/out-$label/order.tsv") - 1))" -eq 2 ]]; then
        ok "isolation guard: $label"
    else
        notok "isolation guard: $label (rc=$rcf, out=${got:0:200})"
    fi
}

for variant in agents leak dirty promptkit promptkitdir ghinstr; do cp -a "$SEED" "$TMP_DIR/seed-$variant"; done
printf '# Global instructions\n' > "$TMP_DIR/seed-agents/AGENTS.md"
git -C "$TMP_DIR/seed-agents" add AGENTS.md
git -C "$TMP_DIR/seed-agents" -c user.name=seed -c user.email=seed@test commit -qm "instruction surface"
printf 'Closings go through heyloey.\n' > "$TMP_DIR/seed-leak/NOTES.md"
git -C "$TMP_DIR/seed-leak" add NOTES.md
git -C "$TMP_DIR/seed-leak" -c user.name=seed -c user.email=seed@test commit -qm "reference"
printf 'dirty\n' >> "$TMP_DIR/seed-dirty/src/app.ts"
printf '# PromptKit project instructions\n' > "$TMP_DIR/seed-promptkit/PROMPTKIT.md"
git -C "$TMP_DIR/seed-promptkit" add PROMPTKIT.md
git -C "$TMP_DIR/seed-promptkit" -c user.name=seed -c user.email=seed@test commit -qm "promptkit surface"
mkdir -p "$TMP_DIR/seed-promptkitdir/.promptkit"
printf 'profile: balanced\n' > "$TMP_DIR/seed-promptkitdir/.promptkit/config.yaml"
git -C "$TMP_DIR/seed-promptkitdir" add .promptkit/config.yaml
git -C "$TMP_DIR/seed-promptkitdir" -c user.name=seed -c user.email=seed@test commit -qm "promptkit dir"
mkdir -p "$TMP_DIR/seed-ghinstr/.github/instructions"
printf '# repo instructions\n' > "$TMP_DIR/seed-ghinstr/.github/instructions/repo.md"
git -C "$TMP_DIR/seed-ghinstr" add .github/instructions/repo.md
git -C "$TMP_DIR/seed-ghinstr" -c user.name=seed -c user.email=seed@test commit -qm "github instructions"

expect_preflight_fail seed-agents \
    "PREFLIGHT|seed isolation: tracked instruction surface: AGENTS.md" \
    "$FAKE_HOME" "$TMP_DIR/seed-agents" "$CLEAN_PATH"
expect_preflight_fail seed-leak \
    "PREFLIGHT|seed isolation: heyloey reference: NOTES.md" \
    "$FAKE_HOME" "$TMP_DIR/seed-leak" "$CLEAN_PATH"
expect_preflight_fail seed-dirty \
    "PREFLIGHT|seed isolation: working tree is dirty" \
    "$FAKE_HOME" "$TMP_DIR/seed-dirty" "$CLEAN_PATH"
expect_preflight_fail seed-promptkit \
    "PREFLIGHT|seed isolation: tracked instruction surface: PROMPTKIT.md" \
    "$FAKE_HOME" "$TMP_DIR/seed-promptkit" "$CLEAN_PATH"
expect_preflight_fail seed-promptkitdir \
    "PREFLIGHT|seed isolation: tracked instruction surface: .promptkit/config.yaml" \
    "$FAKE_HOME" "$TMP_DIR/seed-promptkitdir" "$CLEAN_PATH"
expect_preflight_fail seed-ghinstr \
    "PREFLIGHT|seed isolation: tracked instruction surface: .github/instructions/repo.md" \
    "$FAKE_HOME" "$TMP_DIR/seed-ghinstr" "$CLEAN_PATH"

for variant in agents mcp mcp-empty settings-empty settings-hooks settings-mcp trusted-hooks skills; do
    mkdir -p "$TMP_DIR/home-$variant/.commandcode/taste"
    : > "$TMP_DIR/home-$variant/.commandcode/taste/taste.md"
done
printf '# global\n' > "$TMP_DIR/home-agents/.commandcode/AGENTS.md"
printf '{"mcpServers":{"demo":{"command":"demo"}}}\n' > "$TMP_DIR/home-mcp/.commandcode/mcp.json"
printf '{\n  "mcpServers": {\n  }\n}\n' > "$TMP_DIR/home-mcp-empty/.commandcode/mcp.json"
printf '{\n  "hooks": {},\n  "mcpServers": {}\n}\n' > "$TMP_DIR/home-settings-empty/.commandcode/settings.json"
printf '{"hooks":{"PreToolUse":["lint"]}}\n' > "$TMP_DIR/home-settings-hooks/.commandcode/settings.json"
printf '{"mcpServers":{"demo":{"command":"demo"}}}\n' > "$TMP_DIR/home-settings-mcp/.commandcode/settings.json"
printf '["demo-hook"]\n' > "$TMP_DIR/home-trusted-hooks/.commandcode/trusted-hooks.json"
mkdir -p "$TMP_DIR/home-skills/.commandcode/skills/demo"
printf '# demo skill\n' > "$TMP_DIR/home-skills/.commandcode/skills/demo/SKILL.md"
mkdir -p "$TMP_DIR/hostbin"
printf '#!/bin/sh\nexit 0\n' > "$TMP_DIR/hostbin/heyloey"
chmod +x "$TMP_DIR/hostbin/heyloey"

expect_preflight_fail host-agents \
    "PREFLIGHT|host isolation: global instruction surface:" \
    "$TMP_DIR/home-agents" "$SEED" "$CLEAN_PATH"
expect_preflight_fail host-mcp \
    "PREFLIGHT|host isolation: MCP servers configured:" \
    "$TMP_DIR/home-mcp" "$SEED" "$CLEAN_PATH"
expect_preflight_fail host-settings-hooks \
    "PREFLIGHT|host isolation: hooks configured:" \
    "$TMP_DIR/home-settings-hooks" "$SEED" "$CLEAN_PATH"
expect_preflight_fail host-settings-mcp \
    "PREFLIGHT|host isolation: MCP servers configured:" \
    "$TMP_DIR/home-settings-mcp" "$SEED" "$CLEAN_PATH"
expect_preflight_fail host-trusted-hooks \
    "PREFLIGHT|host isolation: hooks configured:" \
    "$TMP_DIR/home-trusted-hooks" "$SEED" "$CLEAN_PATH"
expect_preflight_fail host-skills \
    "PREFLIGHT|host isolation: global instruction surface:" \
    "$TMP_DIR/home-skills" "$SEED" "$CLEAN_PATH"
expect_preflight_fail host-path \
    "PREFLIGHT|host isolation: heyloey on PATH:" \
    "$FAKE_HOME" "$SEED" "$TMP_DIR/hostbin:$CLEAN_PATH"
expect_preflight_ok host-mcp-empty "$TMP_DIR/home-mcp-empty"
expect_preflight_ok host-settings-empty "$TMP_DIR/home-settings-empty"

# --- clean preflight: guard passes, records evidence, starts nothing -------
OUT_PREFLIGHT="$TMP_DIR/out-preflight"
out="$(PATH="$CLEAN_PATH" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$REPO_ROOT" --seed "$SEED" --tasks "$TASK" \
    --model stub/model-a --out "$OUT_PREFLIGHT" \
    --order-seed 7 --shuffle-seed 7 --preflight-only 2>&1)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"ISOLATION|OK"* && "$out" == *"PREFLIGHT|OK"* ]] \
        && grep -q '^order_seed: 7$' "$OUT_PREFLIGHT/isolation.txt" \
        && grep -q '^shuffle_seed: 7$' "$OUT_PREFLIGHT/isolation.txt" \
        && grep -q '^order_plan_rows: 2$' "$OUT_PREFLIGHT/isolation.txt" \
        && [[ "$(($(wc -l < "$OUT_PREFLIGHT/order.tsv") - 1))" -eq 2 ]] \
        && [[ ! -e "$OUT_PREFLIGHT/manifest.tsv" ]]; then
    ok "clean preflight records isolation evidence and starts no session"
else
    notok "clean preflight (rc=$rc, out=${out:0:200})"
fi

echo ""
echo "Benchmark driver harness (Bash): $PASS passed, $FAIL failed."
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
exit 0
