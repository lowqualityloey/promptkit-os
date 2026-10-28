#!/usr/bin/env bash
# PromptKit OS Benchmark Tools Fixture Harness (Bash)
# Pins the benchmark tooling twins against fixtures with hand-computed
# expectations. Run: bash scripts/tests/run-benchmark-tools-tests.sh
# The .ps1 twin must reach identical verdicts from identical fixtures.
# Fixture arithmetic (default pricing $3/1M in, $15/1M out, $0.05/loop):
#   strip run.diff    -> in_files=7, out_files=1 (src/app.ts kept), dropped=6
#                        (incl. docs/adrs/ and docs/reviews/ scaffold sections)
#   aggregate 4 records + grading.tsv ->
#     bare:         n=2 accepted=1 rate=0.50 tokens 19500 wall 180 rework 1.00
#                   cpac_n=1 cpac 0.2200
#     promptkit_os: n=2 accepted=2 rate=1.00 tokens 17200 wall 195 rework 0.50
#                   cpac_n=2 cpac mean/median 0.0970
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/benchmark-tools"

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok - $1"; }
notok() { FAIL=$((FAIL + 1)); echo "  FAIL - $1"; }

TMP_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/bench-tools.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

strip() { bash "$REPO_ROOT/scripts/strip-benchmark-diff.sh" "$@"; }
aggregate() { bash "$REPO_ROOT/scripts/aggregate-benchmark-runs.sh" "$@"; }

echo "🧪 Benchmark Tools Fixture Harness (Bash)"

# --- strip-benchmark-diff ---------------------------------------------------
out="$(strip "$FIXTURES/run.diff" 2>"$TMP_DIR/strip.err")"; rc=$?
kept="$(printf '%s\n' "$out" | grep -c '^diff --git ' || true)"
if [[ $rc -eq 0 && "$kept" -eq 1 && "$out" == *"diff --git a/src/app.ts b/src/app.ts"* \
        && "$(cat "$TMP_DIR/strip.err")" == "STRIP|OK|in_files=7|out_files=1|dropped=6" ]]; then
    ok "strip keeps code changes and drops all six PromptKit artifacts (incl. scaffold dirs)"
else
    notok "strip valid diff (rc=$rc, kept=$kept, err=$(cat "$TMP_DIR/strip.err" 2>/dev/null))"
fi

# CRLF parity: both twins must reach the identical verdict on a CRLF copy
sed 's/$/\r/' "$FIXTURES/run.diff" > "$TMP_DIR/run-crlf.diff"
out="$(strip "$TMP_DIR/run-crlf.diff" 2>"$TMP_DIR/strip2.err")"; rc=$?
if [[ $rc -eq 0 && "$(cat "$TMP_DIR/strip2.err")" == "STRIP|OK|in_files=7|out_files=1|dropped=6" ]] \
        && ! printf '%s\n' "$out" | grep -q "PROMPTKIT.md\|docs/STATE.md"; then
    ok "CRLF diff strips identically (no artifact leak under CRLF)"
else
    notok "strip CRLF (err=$(cat "$TMP_DIR/strip2.err" 2>/dev/null))"
fi

# A 160000 gitlink for the kit has no trailing slash, so the directory pattern
# missed it and the plugin tree would have reached a blind grader.
printf '%s\n' \
    'diff --git a/.promptkit b/.promptkit' \
    'new file mode 160000' \
    'index 0000000..1234567' \
    '--- /dev/null' \
    '+++ b/.promptkit' \
    '@@ -0,0 +1 @@' \
    '+Subproject commit 1234567890123456789012345678901234567890' \
    'diff --git a/src/app.ts b/src/app.ts' \
    '--- a/src/app.ts' \
    '+++ b/src/app.ts' \
    '@@ -1 +1,2 @@' \
    ' export function main() { return 1; }' \
    '+export const x = 1;' > "$TMP_DIR/gitlink.diff"
out="$(strip "$TMP_DIR/gitlink.diff" 2>"$TMP_DIR/strip3.err")"; rc=$?
if [[ $rc -eq 0 && "$(cat "$TMP_DIR/strip3.err")" == "STRIP|OK|in_files=2|out_files=1|dropped=1" ]] \
        && [[ "$out" != *".promptkit"* ]]; then
    ok "a bare .promptkit gitlink is dropped, not leaked to the grader"
else
    notok "strip gitlink (err=$(cat "$TMP_DIR/strip3.err" 2>/dev/null))"
fi

out="$(strip "$FIXTURES/not-a-diff.txt" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"STRIP|ERROR|NOT_A_DIFF"* ]]; then
    ok "non-diff input fails closed (exit 2)"
else
    notok "strip non-diff (rc=$rc)"
fi

: > "$TMP_DIR/empty.diff"
out="$(strip "$TMP_DIR/empty.diff" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"STRIP|ERROR|UNREADABLE"* ]]; then
    ok "empty diff fails closed (exit 2)"
else
    notok "strip empty (rc=$rc)"
fi

# --- aggregate-benchmark-runs ------------------------------------------------
out="$(aggregate --grading "$FIXTURES/grading.tsv" \
    "$FIXTURES/rec-bare-1.json" "$FIXTURES/rec-bare-2.json" \
    "$FIXTURES/rec-pk-1.json" "$FIXTURES/rec-pk-2.json" 2>"$TMP_DIR/agg.err")"; rc=$?
SUM_BARE='BENCH|SUMMARY|arm=bare|n=2|accepted=1|graded_n=2|accept_rate=0.50|tokens_mean=19500.0|tokens_median=19500.0|wall_mean=180.0|wall_median=180.0|rework_mean=1.00|cpac_n=1|cpac_mean=0.2200|cpac_median=0.2200'
SUM_PK='BENCH|SUMMARY|arm=promptkit_os|n=2|accepted=2|graded_n=2|accept_rate=1.00|tokens_mean=17200.0|tokens_median=17200.0|wall_mean=195.0|wall_median=195.0|rework_mean=0.50|cpac_n=2|cpac_mean=0.0970|cpac_median=0.0970'
if [[ $rc -eq 0 \
        && "$out" == *"$SUM_BARE"* \
        && "$out" == *"$SUM_PK"* \
        && "$out" == *"RUN|BENCH-BARE-1|arm=bare|model=test-model-v1|accepted=1|graded=1|rubric=5/5|tokens_total=28000|wall_clock_seconds=240|rework_loops=2|cpac_usd=0.2200"* \
        && "$out" == *"RUN|BENCH-BARE-2|arm=bare|model=test-model-v1|accepted=0|graded=1|rubric=1/5|tokens_total=11000|wall_clock_seconds=120|rework_loops=0|cpac_usd=INF"* ]]; then
    ok "aggregate emits hand-computed RUN rows and both arm summaries"
else
    notok "aggregate valid (rc=$rc, out=${out:0:220})"
fi

sed 's/BENCH-BARE-2\t1\t5\tfalse/BENCH-BARE-2\t1\t5\ttrue/' "$FIXTURES/grading.tsv" > "$TMP_DIR/mismatch.tsv"
out="$(aggregate --grading "$TMP_DIR/mismatch.tsv" \
    "$FIXTURES/rec-bare-1.json" "$FIXTURES/rec-bare-2.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|ACCEPTED_MISMATCH|BENCH-BARE-2"* ]]; then
    ok "grading-vs-record accepted mismatch fails closed (exit 2)"
else
    notok "accepted mismatch (rc=$rc, out=${out:0:160})"
fi

printf 'BENCH-X\tok\t5\n' > "$TMP_DIR/badg.tsv"
out="$(aggregate --grading "$TMP_DIR/badg.tsv" "$FIXTURES/rec-bare-1.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|BAD_GRADING"* ]]; then
    ok "malformed grading row fails closed (exit 2)"
else
    notok "bad grading (rc=$rc)"
fi

# exact-column discipline: an extra tab-separated column is BAD_GRADING
printf 'BENCH-BARE-1\t5\t5\ttrue\textra\n' > "$TMP_DIR/extracol.tsv"
out="$(aggregate --grading "$TMP_DIR/extracol.tsv" "$FIXTURES/rec-bare-1.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|BAD_GRADING"* ]]; then
    ok "extra grading column fails closed (exit 2)"
else
    notok "extra column (rc=$rc)"
fi

# CRLF + missing final newline parity: a CRLF sheet grades identically
sed 's/$/\r/' "$FIXTURES/grading.tsv" | head -3 > "$TMP_DIR/grading-crlf.tsv"
out="$(aggregate --grading "$TMP_DIR/grading-crlf.tsv" \
    "$FIXTURES/rec-bare-1.json" "$FIXTURES/rec-bare-2.json" 2>&1)"; rc=$?
if [[ $rc -eq 0 && "$out" == *'BENCH|SUMMARY|arm=bare|n=2|accepted=1|graded_n=2|accept_rate=0.50|tokens_mean=19500.0|tokens_median=19500.0|wall_mean=180.0|wall_median=180.0|rework_mean=1.00|cpac_n=1|cpac_mean=0.2200|cpac_median=0.2200'* ]]; then
    ok "CRLF sheet without final newline grades identically (final row included)"
else
    notok "CRLF grading (rc=$rc, out=${out:0:180})"
fi

# MISSING_GRADING: a record absent from the mandatory sheet fails closed
printf 'BENCH-BARE-1\t5\t5\ttrue\n' > "$TMP_DIR/partial.tsv"
out="$(aggregate --grading "$TMP_DIR/partial.tsv" \
    "$FIXTURES/rec-bare-1.json" "$FIXTURES/rec-bare-2.json" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"BENCH|ERROR|MISSING_GRADING|BENCH-BARE-2"* ]]; then
    ok "record missing from the grading sheet fails closed (exit 2)"
else
    notok "missing grading (rc=$rc, out=${out:0:160})"
fi

out="$(aggregate --grading "$FIXTURES/grading.tsv" 2>&1)"; rc=$?
if [[ $rc -eq 2 ]]; then
    ok "missing records exits 2 with usage"
else
    notok "no records (rc=$rc)"
fi

echo ""
echo "Benchmark tools harness (Bash): $PASS passed, $FAIL failed."
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
exit 0
