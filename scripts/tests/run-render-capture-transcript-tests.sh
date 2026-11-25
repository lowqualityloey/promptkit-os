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
#      that bundle's committed transcript. The timestamp column is excluded from
#      the comparison on purpose: agy reports no per-event clock, so the renderer
#      reconstructs the timeline from the stream file's mtime and the cumulative
#      step durations, and float accumulation can move a reconstructed
#      millisecond. Everything the scorer grades — assistant text, tool verbs,
#      targets and statuses — must match byte-for-byte.
#
#      The write log is checked structurally rather than against a committed copy:
#      observed-writes.log is gitignored (*.log), so it exists only on the machine
#      that ran the capture. The harness therefore requires one log line per tool
#      entry in the transcript, and compares byte-for-byte only when the capture's
#      own log happens to be present.
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
# Bundles captured with a recorded timeline anchor. Their provenance.json carries
# timelineStart, so a re-render must reproduce the committed timestamps exactly -
# no timestamp stripping. This is the regression the mtime anchor could not have:
# it fails on any machine whose checkout clock differs from the capture clock.
ANCHORED_PROBES="$PROBES ce-sufficiency-balanced ce-sufficiency-lite ce-escalation-balanced ce-escalation-lite ce-antistarvation-balanced ce-antistarvation-lite"

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
# CRLF is stripped first: the renderer always writes LF, while a Windows
# checkout materialises the committed transcript as CRLF, and the comparison
# must be about content rather than the checkout's line-ending policy.
strip_timestamps() {
    sed -E 's/\r$//' "$1" | sed -E 's/^- .[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+[+-][0-9]{2}:[0-9]{2}. /- /'
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
# The forwarder is invoked as 'bash <path>' everywhere (CI, CONTRIBUTING, this
# harness), so its executable bit is not part of the contract and is not asserted:
# the repository stores scripts as mode 644 and a checkout reproduces that.
scenario_check "$([[ -r "$RENDERER_SH" ]] && printf 1 || printf 0)" "forwarder is not readable: scripts/render-capture-transcript.sh"
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
    # The write log is derived from the transcript, so it must agree with it: one
    # 'tool <verb> <target> (<status>)' line per tool entry. This is asserted
    # unconditionally because observed-writes.log is gitignored (*.log) and so
    # never exists in a CI checkout.
    # CR is stripped before counting: the '$' anchor does not match a line that
    # ends in CRLF, and a Windows checkout materialises the transcript that way.
    tool_entries="$(sed -E 's/\r$//' "$bundle/transcript.md" | grep -cE '^- .*\*\*tool\*\*$' || true)"
    log_lines="$(sed -E 's/\r$//' "$log" | grep -cE '^tool ' || true)"
    scenario_check "$([[ "$tool_entries" -eq "$log_lines" ]] && printf 1 || printf 0)" \
        "write log has $log_lines lines but the transcript has $tool_entries tool entries"

    # Where the capture's own log is present (a developer machine, not CI), the
    # rendered log must reproduce it byte-for-byte.
    if [[ -f "$bundle/observed-writes.log" ]]; then
        if ! diff -q "$log" "$bundle/observed-writes.log" >/dev/null 2>&1; then
            scenario_check 0 "observed-writes.log differs from the recorded log for $probe"
            diff "$log" "$bundle/observed-writes.log" | head -6 | sed 's/^/    /'
        fi
    fi
    report "round-trip $probe"
done


printf '== Newer stream formats ==\n'
# The renderer understands three host event shapes. agy is covered by the round-trip
# cases above; the other two are pinned against committed golden transcripts, one
# per format, rendered from a real (sanitized) stream.
FX="$REPO_ROOT/scripts/tests/fixtures/render-capture-transcript"
FX_PROMPT='Read a.txt, then create c.txt containing the word gamma, then run the shell command ls -1, then say DONE.'

# opencode carries a per-event clock, so its golden is compared with no timestamp
# stripping: the times are observed in the stream, not derived from an anchor.
begin
scenario_check "$([[ -f "$FX/opencode/session.jsonl" ]] && printf 1 || printf 0)" "missing fixture: scripts/tests/fixtures/render-capture-transcript/opencode/session.jsonl"
bash "$RENDERER_SH" "$FX/opencode/session.jsonl" "$TMP/oc.md" "$TMP/oc.log" \
    --probe halt-callout --prompt "$FX_PROMPT" \
    --model opencode/deepseek-v4.1-flash-free --host 'OpenCode' \
    --stream-format opencode --start '2026-11-25T00:00:00+09:00' --offset '+09:00' >/dev/null 2>&1
check_status "$?" 0
scenario_check "$(diff -q "$TMP/oc.md" "$FX/opencode/transcript.md" >/dev/null 2>&1 && printf 1 || printf 0)" "opencode transcript differs from its golden"
scenario_check "$(diff -q "$TMP/oc.log" "$FX/opencode/expected-writes.txt" >/dev/null 2>&1 && printf 1 || printf 0)" "opencode write log differs from its golden"
report 'opencode stream renders to its golden transcript'

# commandcode carries neither a per-event clock nor per-step durations, so its
# timeline is anchored on --start and the transcript says the sequence, not the
# timing, is the record.
begin
scenario_check "$([[ -f "$FX/commandcode/session.jsonl" ]] && printf 1 || printf 0)" "missing fixture: scripts/tests/fixtures/render-capture-transcript/commandcode/session.jsonl"
bash "$RENDERER_SH" "$FX/commandcode/session.jsonl" "$TMP/cc.md" "$TMP/cc.log" \
    --probe halt-callout --prompt "$FX_PROMPT" \
    --model deepseek/deepseek-v4.1-flash --host 'Command Code' \
    --stream-format commandcode --start '2026-11-25T00:00:00+09:00' --offset '+09:00' >/dev/null 2>&1
check_status "$?" 0
scenario_check "$(diff -q "$TMP/cc.md" "$FX/commandcode/transcript.md" >/dev/null 2>&1 && printf 1 || printf 0)" "commandcode transcript differs from its golden"
scenario_check "$(diff -q "$TMP/cc.log" "$FX/commandcode/expected-writes.txt" >/dev/null 2>&1 && printf 1 || printf 0)" "commandcode write log differs from its golden"
report 'commandcode stream renders to its golden transcript'

# A format the renderer does not know must fail loudly rather than fall back to
# rendering the stream as if it were agy.
begin
OUT="$(bash "$RENDERER_SH" "$FX/opencode/session.jsonl" "$TMP/bad.md" "$TMP/bad.log" --probe p --prompt x --model m --stream-format nope 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"not one of"* ]] && printf 1 || printf 0)" "unknown-format output did not name the problem"
report 'an unknown --stream-format is rejected'

# Each format records time differently and the transcript must say which it is,
# rather than implying an observed clock it does not have.
begin
scenario_check "$(grep -q 'reconstruction of the run' "$BUNDLES/halt-callout/transcript.md" && printf 1 || printf 0)" "the agy bundle does not carry the reconstructed-clock note"
scenario_check "$(grep -q 'Timestamps are observed' "$FX/opencode/transcript.md" && printf 1 || printf 0)" "the opencode golden does not carry the observed-clock note"
scenario_check "$(grep -q 'neither a per-event clock' "$FX/commandcode/transcript.md" && printf 1 || printf 0)" "the commandcode golden does not carry the anchored-only note"
report 'each format states which kind of clock it has'

# A tool name the verb map does not know renders verbatim, which the scorer reads
# as neither an inspection nor a write. That is the safe direction but a silent
# gap, so it must be named on stderr where a capture operator will see it.
begin
printf '%s\n' '{"type":"tool_use","timestamp":0,"sessionID":"s","part":{"tool":"mystery_tool","state":{"status":"completed","input":{"path":"x"}}}}' > "$TMP/unknown.jsonl"
OUT="$(bash "$RENDERER_SH" "$TMP/unknown.jsonl" "$TMP/u.md" "$TMP/u.log" --probe p --prompt x --model m --stream-format opencode 2>&1)"
check_status "$?" 0
scenario_check "$([[ "$OUT" == *"unmapped tool name(s)"* ]] && printf 1 || printf 0)" "an unmapped tool name was not reported on stderr"
scenario_check "$(grep -q 'mystery_tool x (completed)' "$TMP/u.md" && printf 1 || printf 0)" "an unmapped tool was not rendered verbatim"
report 'an unmapped tool name is rendered verbatim and reported'
printf '== Anchored bundles reproduce their timestamps exactly ==\n'
for probe in $ANCHORED_PROBES; do
    bundle="$BUNDLES/$probe"
    begin
    if [[ ! -f "$bundle/transcript.md" || ! -f "$bundle/provenance.json" ]]; then
        scenario_check 0 "bundle is missing transcript.md or provenance.json: $probe"
        report "anchored round-trip $probe"
        continue
    fi

    # The ce-* bundles render from the derived relative stream; the six earlier
    # bundles predate that derivation and render from the raw stream.
    if [[ -f "$bundle/session.relative.jsonl" ]]; then
        stream_name=session.relative.jsonl
    else
        stream_name=session.jsonl
    fi

    # The anchor is read back out of the bundle rather than hardcoded here, so the
    # assertion is that the bundle is self-describing: a reader holding only the
    # committed files can reproduce the transcript byte for byte.
    anchor="$(awk -F'"' '/"timelineStart"[ 	]*:[ 	]*"/ { print $4; exit }' "$bundle/provenance.json")"
    if [[ -z "$anchor" ]]; then
        scenario_check 0 "provenance.json records no timelineStart: $probe"
        report "anchored round-trip $probe"
        continue
    fi

    # The rendering offset is a property of the bundle, not of this machine. A
    # bundle that does not record one cannot be reproduced off the host that
    # captured it, which is exactly the defect this case exists to catch.
    offset="$(awk -F'"' '/"timelineOffset"[ 	]*:[ 	]*"/ { print $4; exit }' "$bundle/provenance.json")"
    if [[ -z "$offset" ]]; then
        scenario_check 0 "provenance.json records no timelineOffset: $probe"
        report "anchored round-trip $probe"
        continue
    fi

    out="$TMP/$probe-anchored.md"
    log="$TMP/$probe-anchored.log"
    bash "$RENDERER_SH" "$bundle/$stream_name" "$out" "$log" \
        --probe "$probe" \
        --prompt "$(field "$bundle/transcript.md" 'Prompt submitted')" \
        --model "$(field "$bundle/transcript.md" 'Model')" \
        --invocation "$(invocation_field "$bundle/transcript.md")" \
        --stream "$stream_name" \
        --start "$anchor" \
        --offset "$offset" >/dev/null 2>&1
    check_status "$?" 0

    # No strip_timestamps here: the whole point is that the timestamps match.
    if ! diff -q <(sed -E 's/$//' "$out") <(sed -E 's/$//' "$bundle/transcript.md") >/dev/null 2>&1; then
        scenario_check 0 "re-render with the recorded anchor differs from the committed transcript for $probe"
        diff <(sed -E 's/$//' "$out") <(sed -E 's/$//' "$bundle/transcript.md") | head -6 | sed 's/^/    /'
    fi
    report "anchored round-trip $probe"
done

printf '== Rendering is independent of the host time zone ==\n'
# The anchored case above proves a bundle reproduces on THIS machine. It cannot
# prove the rendering is a property of the bundle rather than of the machine,
# because this machine is the one that captured it. Re-render the same bundle
# under two foreign zones and require the identical bytes: a renderer that reads
# the host zone (getTimezoneOffset/getHours) passes the anchored case locally and
# fails here, which is exactly how the defect reached CI.
begin
zone_bundle="$BUNDLES/breaker-exhaustion"
zone_anchor="$(awk -F'"' '/"timelineStart"[ 	]*:[ 	]*"/ { print $4; exit }' "$zone_bundle/provenance.json")"
zone_offset="$(awk -F'"' '/"timelineOffset"[ 	]*:[ 	]*"/ { print $4; exit }' "$zone_bundle/provenance.json")"
if [[ -z "$zone_anchor" || -z "$zone_offset" ]]; then
    scenario_check 0 "breaker-exhaustion records no timelineStart/timelineOffset"
else
    zone_prompt="$(field "$zone_bundle/transcript.md" 'Prompt submitted')"
    zone_model="$(field "$zone_bundle/transcript.md" 'Model')"
    zone_invocation="$(invocation_field "$zone_bundle/transcript.md")"
    for zone in UTC America/New_York Asia/Kolkata; do
        # The zone name carries a slash, so it cannot be used as a file name.
        zone_slug="$(printf '%s' "$zone" | tr '/' '_')"
        TZ="$zone" bash "$RENDERER_SH" "$zone_bundle/session.jsonl" "$TMP/zone-$zone_slug.md" "$TMP/zone-$zone_slug.log" \
            --probe breaker-exhaustion \
            --prompt "$zone_prompt" \
            --model "$zone_model" \
            --invocation "$zone_invocation" \
            --stream session.jsonl \
            --start "$zone_anchor" \
            --offset "$zone_offset" >/dev/null 2>&1
        check_status "$?" 0
        scenario_check "$(diff -q <(sed -E 's/\r$//' "$TMP/zone-$zone_slug.md") <(sed -E 's/\r$//' "$zone_bundle/transcript.md") >/dev/null 2>&1 && printf 1 || printf 0)" \
            "re-render under TZ=$zone differs from the committed transcript"
    done
fi
report 'rendering is independent of the host time zone'

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
