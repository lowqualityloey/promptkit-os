#!/usr/bin/env bash
# PromptKit OS Blinding Audit Harness (Bash)
# Exercises benchmarks/audit-blinding.sh against the real driver and a stub CLI:
# the clean run passes with its control, the fixture never puts key.csv in the
# delivery, and the audit FAILS when the driver lets its own session.log into a
# graded packet - the defect the dry-run audit found in Phase 3b.
# Run: bash scripts/tests/run-benchmark-blinding-tests.sh
# Bash-only by design, like the driver harness it depends on.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUDIT="$REPO_ROOT/benchmarks/audit-blinding.sh"
DRIVER="$REPO_ROOT/benchmarks/run-ab-benchmark.sh"

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok - $1"; }
notok() { FAIL=$((FAIL + 1)); echo "  FAIL - $1"; }

TMP_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/bench-blinding.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "🧪 Blinding Audit Harness (mock CLI)"

# --- usage surface ----------------------------------------------------------
out="$(bash "$AUDIT" --help 2>&1)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"Usage: bash benchmarks/audit-blinding.sh"* \
        && "$out" == *"--driver PATH"* ]]; then
    ok "--help documents the invocation and exits 0"
else
    notok "--help (rc=$rc, out=${out:0:120})"
fi

out="$(bash "$AUDIT" --nonsense 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == "AUDIT|USAGE|unknown argument: --nonsense" ]]; then
    ok "an unknown argument is a usage error (exit 2)"
else
    notok "unknown argument (rc=$rc, out=${out:0:120})"
fi

out="$(bash "$AUDIT" --driver "$TMP_DIR/no-such-driver.sh" 2>&1)"; rc=$?
if [[ $rc -eq 2 && "$out" == *"AUDIT|USAGE|driver not found:"* ]]; then
    ok "a missing driver is a usage error, not a pass"
else
    notok "missing driver (rc=$rc, out=${out:0:120})"
fi

# --- the clean run ----------------------------------------------------------
out="$(bash "$AUDIT" 2>&1)"; rc=$?
if [[ $rc -eq 0 && "$out" == *"BLINDING_AUDIT|OK|"* && "$out" == *"leaks=0"* \
        && "$out" == *"key=outside_delivery"* ]]; then
    ok "a dry-run delivery scans clean and the audit exits 0"
else
    notok "clean run (rc=$rc, out=$(printf '%s' "$out" | tail -3 | tr '\n' ' '))"
fi
if [[ "$out" == *"AUDIT|SUMMARY|packets=4|verify=2|key_rows=4|blind_ids=4|delivery_files=6"* ]]; then
    ok "delivery shape is pinned: 4 packets, 2 verify packets, 6 files"
else
    notok "delivery shape (out=$(printf '%s' "$out" | grep 'AUDIT|SUMMARY' || echo none))"
fi
if [[ "$out" == *"AUDIT|CONTROL|expected=14|planted=14|missing=none"* \
        && "$out" == *"control=14/14"* ]]; then
    ok "the positive control fires all 14 scanners"
else
    notok "positive control (out=$(printf '%s' "$out" | grep 'AUDIT|CONTROL' || echo none))"
fi
if [[ "$out" == *"AUDIT|PREFLIGHT|engine="*"|spend=0|stub=cli"* ]]; then
    ok "the audit records its engine and zero spend"
else
    notok "preflight record (out=$(printf '%s' "$out" | grep 'AUDIT|PREFLIGHT' || echo none))"
fi
if [[ "$out" != *"AUDIT|KEPT|"* ]]; then
    ok "the fixture is removed when the audit finishes"
else
    notok "fixture left behind without --keep"
fi

# --- --keep leaves an inspectable fixture, key still outside the delivery ---
out="$(bash "$AUDIT" --keep 2>&1)"; rc=$?
kept="$(printf '%s\n' "$out" | sed -n 's/^AUDIT|KEPT|//p')"
if [[ $rc -eq 0 && -n "$kept" && -d "$kept" \
        && ! -e "$kept/delivery/key.csv" && -f "$kept/out/grading/key.csv" ]]; then
    ok "--keep preserves the fixture with key.csv outside the delivery"
else
    notok "--keep fixture (rc=$rc, kept=${kept:-none})"
fi
[[ -n "$kept" ]] && rm -rf "$kept"

# --- the audit catches the real regression ----------------------------------
# The Phase 3b defect: the driver redirects the session stream into the clone
# and stages it, so its own capture lands in the graded diff unless the clone
# excludes it. Drop only that exclusion and the audit must fail.
MUTATED="$TMP_DIR/driver-no-session-exclude.sh"
grep -vF "grep -qxF '/session.log'" "$DRIVER" > "$MUTATED"
chmod +x "$MUTATED"
if [[ "$(grep -cF '/session.log' "$DRIVER")" -eq 2 ]] \
        && [[ "$(grep -cF '/session.log' "$MUTATED")" -eq 1 ]] \
        && [[ -n "$(grep -F '$OUT/runs/$scenario/session.log' "$MUTATED")" ]] \
        && bash -n "$MUTATED"; then
    ok "mutation removes only the exclusion, not the session redirect"
else
    notok "driver mutation is not surgical"
fi

out="$(bash "$AUDIT" --driver "$MUTATED" 2>&1)"; rc=$?
if [[ $rc -eq 1 && "$out" == *"HIT|session_log|"* \
        && "$out" == *"AUDIT|FAIL|"*"carries files: session.log src/app.ts"* ]]; then
    ok "a driver that lets session.log into a packet fails the audit"
else
    notok "session.log detection (rc=$rc, out=$(printf '%s' "$out" | tail -3 | tr '\n' ' '))"
fi
if [[ "$out" == *"AUDIT|CONTROL|expected=14|planted=14|missing=none"* ]]; then
    ok "the control still fires on a failing run"
else
    notok "control on failing run (out=$(printf '%s' "$out" | grep 'AUDIT|CONTROL' || echo none))"
fi

echo ""
echo "Benchmark blinding harness (Bash): $PASS passed, $FAIL failed."
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
exit 0
