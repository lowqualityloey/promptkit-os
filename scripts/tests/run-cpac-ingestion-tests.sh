#!/usr/bin/env bash
# PromptKit OS CPAC Ingestion Fixture Harness (Bash)
# Pins the CPAC twins' telemetry-ingestion behavior and the Command Code
# extractor's §5 record emission against fixtures with hand-computed totals.
# Run: bash scripts/tests/run-cpac-ingestion-tests.sh
# The .ps1 twin must reach identical verdicts from identical fixtures.
# Fixture arithmetic (default pricing $3/1M in, $15/1M out, $0.05/loop):
#   telemetry-valid.json     → CPAC 0.2200   (rejected variant → INF)
#   session-basic.jsonl      → succ 11000/2200, rework 4000/800 (1 loop),
#                              cache 3500, 4 tool calls (1/1/2/0), wall 60s,
#                              and end-to-end CPAC 0.1400 once accepted.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/cpac-ingestion"

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok - $1"; }
notok() { FAIL=$((FAIL + 1)); echo "  FAIL - $1"; }

TMP_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/cpac-ingestion.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

measure() { bash "$REPO_ROOT/scripts/measure-cpac.sh" "$@"; }
extract() { bash "$REPO_ROOT/scripts/extract-commandcode-telemetry.sh" "$@"; }

echo "🧪 CPAC Ingestion Fixture Harness (Bash)"

# --- measure-cpac.sh modes -------------------------------------------------
out="$(measure --self-test)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"All CPAC measurement self-tests PASSED."* ]]; then
    ok "self-test passes with the §2B formula expectations"
else
    notok "self-test (rc=$rc, out=${out:0:120})"
fi

out="$(measure --demo)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"SIMULATED"* && "$out" != *"CPAC|MEASURED"* ]]; then
    ok "--demo prints the labeled simulated scorecard only"
else
    notok "--demo (rc=$rc)"
fi

out="$(measure)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"Usage: measure-cpac.sh"* ]]; then
    ok "bare invocation prints usage (no default simulation)"
else
    notok "bare invocation (rc=$rc)"
fi

# --- measured ingestion ----------------------------------------------------
out="$(measure "$FIXTURES/telemetry-valid.json")"; rc=$?
if [[ $rc -eq 0 && "$out" == *'CPAC|MEASURED|scenario=BENCH-01|condition=bare|model=test-model-v1|tokens_in=20000|tokens_out=2000|cache_read_tokens=4000|rework_loops=2|rework_tokens_in=5000|rework_tokens_out=1000|wall_clock_seconds=240|human_interventions=0|inference_usd=0.0900|rework_usd=0.1300|human_usd=0.0000|cpac_usd=0.2200'* ]]; then
    ok "valid §5 record scores cpac_usd=0.2200 with the full machine line"
else
    notok "valid record scoring (rc=$rc, out=${out:0:200})"
fi

out="$(measure "$FIXTURES/telemetry-rejected.json")"; rc=$?
if [[ $rc -eq 0 && "$out" == *"INF (REJECTED)"* && "$out" == *"cpac_usd=INF"* ]]; then
    ok "accepted=false record reports INF (REJECTED) with cpac_usd=INF"
else
    notok "rejected record (rc=$rc)"
fi

# stderr must be EMPTY on valid scoring runs — a past regression emitted nine
# type-resolution stack traces per valid run while stdout stayed correct
out="$(measure "$FIXTURES/telemetry-valid.json" 2>"$TMP_DIR/m.err")"; rc=$?
if [[ $rc -eq 0 && ! -s "$TMP_DIR/m.err" ]]; then
    ok "valid scoring run writes nothing to stderr"
else
    notok "stderr-empty valid scoring (rc=$rc, stderr=$(head -c 120 "$TMP_DIR/m.err" 2>/dev/null))"
fi

sed 's/"tokens_in": 20000/"tokens_in": -500000/' "$FIXTURES/telemetry-valid.json" > "$TMP_DIR/neg.json"
out="$(measure "$TMP_DIR/neg.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"CPAC|ERROR|BAD_VALUE|tokens_in"* ]]; then
    ok "negative metric value fails closed (exit 2)"
else
    notok "negative metric (rc=$rc, out=${out:0:160})"
fi

sed 's/"accepted": true/"accepted": true_lies/' "$FIXTURES/telemetry-valid.json" > "$TMP_DIR/lies.json"
out="$(measure "$TMP_DIR/lies.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"CPAC|ERROR"* ]]; then
    ok "unanchored boolean value fails closed (exit 2)"
else
    notok "unanchored boolean (rc=$rc, out=${out:0:160})"
fi

out="$(measure "$FIXTURES/telemetry-valid.json" "$FIXTURES/telemetry-rejected.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"CPAC|ERROR|MULTIPLE_INPUTS"* ]]; then
    ok "multiple positional inputs fail closed (exit 2)"
else
    notok "multiple positionals (rc=$rc, out=${out:0:160})"
fi

out="$(measure "$FIXTURES/telemetry-missing-key.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"CPAC|ERROR|MISSING_KEY|rework_loops"* ]]; then
    ok "missing rework_loops fails closed (exit 2)"
else
    notok "missing-key record (rc=$rc, out=${out:0:160})"
fi

out="$(measure "$FIXTURES/telemetry-bad-accepted.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"CPAC|ERROR|BAD_VALUE|accepted"* ]]; then
    ok "string-typed accepted fails closed (exit 2)"
else
    notok "bad-accepted record (rc=$rc, out=${out:0:160})"
fi

: > "$TMP_DIR/empty.json"
out="$(measure "$TMP_DIR/empty.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"CPAC|ERROR|UNREADABLE"* ]]; then
    ok "empty record fails closed (exit 2)"
else
    notok "empty record (rc=$rc, out=${out:0:160})"
fi

# --- extractor: known session, exact record fields -------------------------
out="$(extract "$FIXTURES/session-basic.jsonl" --scenario-id=BENCH-01 --condition=bare --accepted=true 2>"$TMP_DIR/extract.err")"; rc=$?
if [[ $rc -eq 0 \
        && "$out" == *'"tokens_in": 11000'* \
        && "$out" == *'"tokens_out": 2200'* \
        && "$out" == *'"tokens_total": 18000'* \
        && "$out" == *'"cache_read_tokens": 3500'* \
        && "$out" == *'"tool_calls_total": 4'* \
        && "$out" == *'"tool_calls_search": 1'* \
        && "$out" == *'"tool_calls_edit": 1'* \
        && "$out" == *'"tool_calls_verify": 2'* \
        && "$out" == *'"tool_calls_other": 0'* \
        && "$out" == *'"rework_loops": 1'* \
        && "$out" == *'"rework_tokens_in": 4000'* \
        && "$out" == *'"rework_tokens_out": 800'* \
        && "$out" == *'"wall_clock_seconds": 60'* \
        && "$out" == *'"human_interventions": 0'* \
        && "$out" == *'"accepted": true'* \
        && "$out" == *'"model": "test-model-v1"'* \
        && "$out" == *'"scenario_id": "BENCH-01"'* \
        && "$out" == *'"transcript_cost_usd": 0.00'* ]]; then
    ok "session fixture extracts the hand-computed §5 record exactly"
else
    notok "extraction record (rc=$rc, out=${out:0:200})"
fi

grep -q "^EXTRACT|OK|session=f1x0-dead-beef-42" "$TMP_DIR/extract.err" \
    && ok "stderr carries the EXTRACT|OK status line" \
    || notok "stderr status line"

# --- end-to-end: extraction feeds scoring ---------------------------------
printf '%s\n' "$out" > "$TMP_DIR/record.json"
out2="$(measure "$TMP_DIR/record.json")"; rc=$?
if [[ $rc -eq 0 && "$out2" == *'cpac_usd=0.1400'* ]]; then
    ok "extraction → scoring end-to-end yields cpac_usd=0.1400"
else
    notok "end-to-end scoring (rc=$rc, out=${out2:0:200})"
fi

# --- extractor: negative cases ---------------------------------------------
out="$(extract "$FIXTURES/session-nosession.jsonl" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"EXTRACT|ERROR|NO_SESSION_LINE"* ]]; then
    ok "transcript without a session line fails closed (exit 2)"
else
    notok "no-session transcript (rc=$rc, out=${out:0:160})"
fi

out="$(extract 2>&1)"; rc=$?
if [[ $rc -eq 2 ]]; then
    ok "missing transcript argument exits 2 with usage"
else
    notok "missing argument (rc=$rc)"
fi

# --- extractor: offset-bearing timestamps (P3 hardening) -------------------
printf '%s\n' \
  '{"type":"session","version":3,"id":"off-set-1","timestamp":"2026-10-25T12:00:00+02:00","cwd":"/tmp/x"}' \
  '{"type":"message","id":"c1","parentId":null,"timestamp":"2026-10-25T12:00:01+02:00","message":{"role":"user","content":[{"type":"text","text":"t"}],"meta":{"source":"user","createdAt":1,"messageId":"u1"}}}' \
  '{"type":"message","id":"c2","parentId":"c1","timestamp":"2026-10-25T12:00:10+02:00","message":{"role":"assistant","content":[{"type":"text","text":"done"}],"meta":{"source":"model","createdAt":2,"messageId":"a1"}},"usage":{"inputTokens":100,"outputTokens":10,"cacheReadTokens":0,"cacheWriteTokens":0,"costUsd":0},"model":"m1"}' \
  > "$TMP_DIR/offsets.jsonl"
out="$(extract "$TMP_DIR/offsets.jsonl" --accepted=true 2>/dev/null)"; rc=$?
if [[ $rc -eq 0 && "$out" == *'"wall_clock_seconds": 10'* && "$out" == *'"tokens_in": 100'* ]]; then
    ok "offset-bearing timestamps compute absolute wall clock"
else
    notok "offset timestamps (rc=$rc, out=${out:0:160})"
fi

# The locale pin is asserted at its source: a functional comma-locale run is
# non-deterministic across runner images, so the guarantee (LC_ALL=C before
# any awk call) is checked structurally.
grep -q "^export LC_ALL=C" "$REPO_ROOT/scripts/extract-commandcode-telemetry.sh" \
    && ok "extractor pins LC_ALL=C" \
    || notok "LC_ALL=C pin"

echo ""
echo "CPAC ingestion harness (Bash): $PASS passed, $FAIL failed."
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
exit 0
