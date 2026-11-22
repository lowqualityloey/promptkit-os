#!/usr/bin/env bash
# Regression harness for the capture-transcript renderer.
# Run from repository root: bash scripts/tests/run-render-capture-transcript-tests.sh
#
# The renderer is the only mechanical path from a raw agy stream-json event
# stream to the transcript format the behavioral scorer reads. Two properties
# matter and both are asserted here against the six committed Antigravity
# bundles rather than against synthetic input:
#
#   1. Round-trip fidelity. Re-rendering a bundle's own session.jsonl reproduces
#      that bundle's committed transcript and observed-writes.log. The timestamp
#      column is excluded from the comparison on purpose: agy reports no
#      per-event clock, so the renderer reconstructs the timeline from the stream
#      file's mtime and the cumulative step durations, and float accumulation can
#      move a reconstructed millisecond. Everything the scorer grades — assistant
#      text, tool verbs, targets, statuses, and the write log — must match
#      byte-for-byte.
#   2. Twin parity. The Bash and PowerShell forwarders invoke the same module, so
#      their output must be identical. This is asserted directly rather than
#      assumed from the shared implementation.
#
# A third case re-scores a re-rendered bundle and requires the same verdict line
# as the committed scorer.txt, which is what makes the round-trip meaningful:
# identical bytes that score differently would not be a pass.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
RENDERER_SH="$REPO_ROOT/scripts/render-capture-transcript.sh"
RENDERER_PS1="$REPO_ROOT/scripts/render-capture-transcript.ps1"
MODULE="$REPO_ROOT/scripts/render-capture-transcript.mjs"
SCORER="$REPO_ROOT/scripts/run-behavioral-eval.sh"
BUNDLES="$REPO_ROOT/docs/internal/host-conformance/antigravity"
PROBES="breaker-exhaustion card-provenance greenfield-saas-intake halt-callout milestone-halt milestone-halt-resume"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0
SCENARIO_OK=1

pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
begin() { SCENARIO_OK=1; }
report() { if [[ "$SCENARIO_OK" -eq 1 ]]; then pass "$1"; else fail "$1"; fi; }
scenario_check() {
    if [[ "$1" -ne 1 ]]; then
        printf '  - %s\n' "$2"
        SCENARIO_OK=0
    fi
}
check_status() { scenario_check "$([[ "$1" -eq "$2" ]] && printf 1 || printf 0)" "expected exit $2, got $1"; }

# The timestamp column is the only part of the transcript the renderer
# reconstructs rather than copies, so it is the only part excluded here.
strip_timestamps() {
    sed -E 's/^- .[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+[+-][0-9]{2}:[0-9]{2}. /- /' "$1"
}

# Read a preamble field back out of a committed transcript so a re-render is
# invoked with exactly the arguments the original capture used. awk is used
# rather than sed because the values contain backticks and slashes.
field() {
    awk -v label="$2" 'index($0, "- " label ": `") == 1 {
        s = substr($0, length("- " label ": `") + 1)
        i = index(s, "`")
        print substr(s, 1, i - 1)
        exit
    }' "$1"
}

# The invocation is the second backtick-quoted value on the Model line.
invocation_field() {
    awk 'index($0, "- Model: `") == 1 {
        s = substr($0, length("- Model: `") + 1)
        i = index(s, "`")
        s = substr(s, i + 1)
        j = index(s, "`")
        s = substr(s, j + 1)
        k = index(s, "`")
        print substr(s, 1, k - 1)
        exit
    }' "$1"
}

# A pwsh on PATH is not proof that pwsh runs: this repository's own development
# host carries a shim that execs a Windows path which does not exist. Probe the
# candidate with a trivial command and fall through to the real install.
pwsh_bin() {
    local candidate
    for candidate in "$(command -v pwsh 2>/dev/null || true)" /opt/microsoft/powershell/7/pwsh; do
        [[ -n "$candidate" && -x "$candidate" ]] || continue
        if "$candidate" -NoProfile -Command 'exit 0' >/dev/null 2>&1; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

render() {
    local probe="$1" out="$2" log="$3" bundle="$BUNDLES/$1"
    bash "$RENDERER_SH" "$bundle/session.jsonl" "$out" "$log" \
        --probe "$probe" \
        --prompt "$(field "$bundle/transcript.md" 'Prompt submitted')" \
        --model "$(field "$bundle/transcript.md" 'Model')" \
        --invocation "$(invocation_field "$bundle/transcript.md")"
}

printf '== Renderer module and forwarders ==\n'
begin
scenario_check "$([[ -f "$MODULE" ]] && printf 1 || printf 0)" "missing module: scripts/render-capture-transcript.mjs"
scenario_check "$([[ -f "$RENDERER_SH" ]] && printf 1 || printf 0)" "missing forwarder: scripts/render-capture-transcript.sh"
scenario_check "$([[ -f "$RENDERER_PS1" ]] && printf 1 || printf 0)" "missing forwarder: scripts/render-capture-transcript.ps1"
scenario_check "$([[ -x "$RENDERER_SH" ]] && printf 1 || printf 0)" "forwarder is not executable: scripts/render-capture-transcript.sh"
report 'renderer module and both forwarders exist'

printf '== Argument validation ==\n'
begin
OUT="$(bash "$RENDERER_SH" 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"Usage:"* ]] && printf 1 || printf 0)" "no-argument output did not print usage"
OUT="$(bash "$RENDERER_SH" /nonexistent.jsonl /tmp/t.md /tmp/w.log --probe p --prompt x --model m 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"no such event stream"* ]] && printf 1 || printf 0)" "missing-stream output did not name the problem"
OUT="$(bash "$RENDERER_SH" "$BUNDLES/halt-callout/session.jsonl" /tmp/t.md /tmp/w.log --probe p --prompt x --model m --bogus y 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"unknown argument"* ]] && printf 1 || printf 0)" "unknown-flag output did not name the problem"
report 'argument validation rejects bad invocations with exit 2'

printf '== Round-trip against the committed bundles ==\n'
for probe in $PROBES; do
    bundle="$BUNDLES/$probe"
    begin
    if [[ ! -f "$bundle/session.jsonl" || ! -f "$bundle/transcript.md" ]]; then
        scenario_check 0 "bundle is missing session.jsonl or transcript.md: $probe"
        report "round-trip $probe"
        continue
    fi

    out="$TMP/$probe.md"
    log="$TMP/$probe.log"
    render "$probe" "$out" "$log" >/dev/null 2>&1
    check_status "$?" 0

    if ! diff -q <(strip_timestamps "$out") <(strip_timestamps "$bundle/transcript.md") >/dev/null 2>&1; then
        scenario_check 0 "transcript content differs from the committed transcript for $probe"
        diff <(strip_timestamps "$out") <(strip_timestamps "$bundle/transcript.md") | head -6 | sed 's/^/    /'
    fi
    if ! diff -q "$log" "$bundle/observed-writes.log" >/dev/null 2>&1; then
        scenario_check 0 "observed-writes.log differs from the committed log for $probe"
        diff "$log" "$bundle/observed-writes.log" | head -6 | sed 's/^/    /'
    fi
    report "round-trip $probe"
done

printf '== Twin parity ==\n'
if PWSH="$(pwsh_bin)"; then
    begin
    bundle="$BUNDLES/halt-callout"
    prompt="$(field "$bundle/transcript.md" 'Prompt submitted')"
    model="$(field "$bundle/transcript.md" 'Model')"
    invocation="$(invocation_field "$bundle/transcript.md")"
    bash "$RENDERER_SH" "$bundle/session.jsonl" "$TMP/twin-sh.md" "$TMP/twin-sh.log" \
        --probe halt-callout --prompt "$prompt" --model "$model" --invocation "$invocation" >/dev/null 2>&1
    check_status "$?" 0
    "$PWSH" -NoProfile -File "$RENDERER_PS1" "$bundle/session.jsonl" "$TMP/twin-ps.md" "$TMP/twin-ps.log" \
        --probe halt-callout --prompt "$prompt" --model "$model" --invocation "$invocation" >/dev/null 2>&1
    check_status "$?" 0
    scenario_check "$(diff -q "$TMP/twin-sh.md" "$TMP/twin-ps.md" >/dev/null 2>&1 && printf 1 || printf 0)" "Bash and PowerShell transcripts differ"
    scenario_check "$(diff -q "$TMP/twin-sh.log" "$TMP/twin-ps.log" >/dev/null 2>&1 && printf 1 || printf 0)" "Bash and PowerShell write logs differ"
    report 'Bash and PowerShell forwarders produce identical output'
else
    printf 'SKIP: PowerShell forwarder parity (pwsh not available)\n'
fi

printf '== Re-rendered bundle still scores the same ==\n'
begin
bundle="$BUNDLES/halt-callout"
if [[ -f "$bundle/scorer.txt" && -f "$SCORER" ]]; then
    work="$TMP/score"
    mkdir -p "$work"
    cp "$bundle/provenance.json" "$work/" 2>/dev/null || true
    render halt-callout "$work/transcript.md" "$work/observed-writes.log" >/dev/null 2>&1
    check_status "$?" 0
    rendered="$(bash "$SCORER" --score halt-callout "$work/transcript.md" 2>&1 | grep -E '^halt-callout\|' | head -1)"
    committed="$(grep -E '^halt-callout\|' "$bundle/scorer.txt" | head -1)"
    scenario_check "$([[ -n "$rendered" ]] && printf 1 || printf 0)" "scorer produced no verdict line for the re-rendered bundle"
    scenario_check "$([[ "$rendered" == "$committed" ]] && printf 1 || printf 0)" "verdict differs: rendered '$rendered' vs committed '$committed'"
else
    scenario_check 0 "missing scorer.txt or scripts/run-behavioral-eval.sh"
fi
report 're-rendered halt-callout bundle scores the committed verdict'

printf '\n'
if [[ "$FAIL" -eq 0 ]]; then
    printf 'RENDER_CAPTURE_TRANSCRIPT_TESTS|PASS|%d passed\n' "$PASS"
    exit 0
fi
printf 'RENDER_CAPTURE_TRANSCRIPT_TESTS|FAIL|%d passed, %d failed\n' "$PASS" "$FAIL"
exit 1
