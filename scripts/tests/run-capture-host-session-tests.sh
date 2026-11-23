#!/usr/bin/env bash
# Regression harness for the live-capture harness.
# Run from repository root: bash scripts/tests/run-capture-host-session-tests.sh
#
# scripts/capture-host-session.mjs is the harness promised by
# docs/internal/host-conformance/antigravity-capture-plan.md section 3.1: it
# seeds a fixture, stages and installs the kit with --host=gemini, applies the
# bwrap isolation, drives agy over --input-format stream-json, and preserves the
# raw NDJSON stream. Three properties matter and are asserted here:
#
#   1. Plan resolution. --print-plan must resolve the scenario's prompt, profile,
#      fixture and bundle without touching the filesystem or invoking a model.
#      This is the only part of the harness that runs in CI, which has neither
#      agy nor bwrap, so it is also the part that catches a scenario/fixture
#      mismatch before a maintainer spends a model turn on it.
#   2. Grading material stays out of the fixture. The staged kit must omit the
#      scenario rubric, the scorer, this evaluation record, the published
#      bundles and the task records, while keeping the discovery route
#      (protocols/context-economy.md, protocols/setup.md, docs/WORKFLOW-MAP.md,
#      workflows/route.md) intact. A regression here silently invalidates every
#      capture, because the model under test could read its own rubric.
#   3. The isolation canary can fail. A canary that reports zero paths because
#      it cannot see the fixture is worse than no canary: it manufactures a
#      false pass. The committed canary.txt must therefore carry a control arm
#      that found copies, a sweep arm that found none, and a direct-read arm
#      that was blocked.
#
# The live capture itself is NOT run here: it spends a model turn and needs agy
# plus bwrap. That case is skipped, not failed, when either is absent.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(builtin cd -- "$SCRIPT_DIR/../.." && pwd -P)"
HARNESS_SH="$REPO_ROOT/scripts/capture-host-session.sh"
HARNESS_PS1="$REPO_ROOT/scripts/capture-host-session.ps1"
MODULE="$REPO_ROOT/scripts/capture-host-session.mjs"
SCORER="$REPO_ROOT/scripts/run-behavioral-eval.sh"
SCEN_DIR="$REPO_ROOT/scripts/tests/eval-scenarios"
BUNDLES="$REPO_ROOT/docs/internal/host-conformance/antigravity"
SCENARIOS="ce-sufficiency-balanced ce-sufficiency-lite ce-escalation-balanced ce-escalation-lite ce-antistarvation-balanced ce-antistarvation-lite"

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

# Read one CAPTURE_PLAN field back out of the plan line.
plan_field() {
    awk -v key="$2" 'index($0, "CAPTURE_PLAN|") == 1 {
        n = split($0, parts, "|")
        for (i = 2; i <= n; i++) {
            eq = index(parts[i], "=")
            if (eq > 0 && substr(parts[i], 1, eq - 1) == key) {
                print substr(parts[i], eq + 1)
                exit
            }
        }
    }' "$1"
}

printf '== Harness module and forwarders ==\n'
begin
scenario_check "$([[ -f "$MODULE" ]] && printf 1 || printf 0)" "missing module: scripts/capture-host-session.mjs"
scenario_check "$([[ -f "$HARNESS_SH" ]] && printf 1 || printf 0)" "missing forwarder: scripts/capture-host-session.sh"
scenario_check "$([[ -f "$HARNESS_PS1" ]] && printf 1 || printf 0)" "missing forwarder: scripts/capture-host-session.ps1"
# The forwarder is invoked as 'bash <path>' everywhere (CI, CONTRIBUTING, this
# harness), so its executable bit is not part of the contract and is not asserted:
# the repository stores scripts as mode 644 and a checkout reproduces that.
scenario_check "$([[ -r "$HARNESS_SH" ]] && printf 1 || printf 0)" "forwarder is not readable: scripts/capture-host-session.sh"
report 'harness module and both forwarders exist'

printf '== Argument validation ==\n'
begin
OUT="$(bash "$HARNESS_SH" 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"Usage:"* ]] && printf 1 || printf 0)" "no-argument output did not print usage"
OUT="$(bash "$HARNESS_SH" ce-sufficiency-balanced 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"Usage:"* ]] && printf 1 || printf 0)" "one-positional output did not print usage"
OUT="$(bash "$HARNESS_SH" ce-sufficiency-balanced "$TMP/b" --bogus y 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"unknown argument"* ]] && printf 1 || printf 0)" "unknown-flag output did not name the problem"
OUT="$(bash "$HARNESS_SH" no-such-scenario "$TMP/b" --print-plan 2>&1)"; STATUS=$?
check_status "$STATUS" 2
scenario_check "$([[ "$OUT" == *"no such scenario"* ]] && printf 1 || printf 0)" "missing-scenario output did not name the problem"
report 'argument validation rejects bad invocations with exit 2'

printf '== Plan resolution for every ce-* scenario ==\n'
for scenario in $SCENARIOS; do
    begin
    if [[ ! -f "$SCEN_DIR/$scenario.md" ]]; then
        scenario_check 0 "missing scenario file: scripts/tests/eval-scenarios/$scenario.md"
        report "plan $scenario"
        continue
    fi
    plan="$TMP/$scenario.plan"
    bash "$HARNESS_SH" "$scenario" "$TMP/$scenario-bundle" --print-plan >"$plan" 2>&1
    check_status "$?" 0

    # The profile comes from the scenario's own ## Directive body, and the
    # scenario name must agree with it: a mismatch means the file and its name
    # disagree and the capture would install the wrong directive.
    expected_profile="${scenario##*-}"
    scenario_check "$([[ "$(plan_field "$plan" profile)" == "$expected_profile" ]] && printf 1 || printf 0)" \
        "profile resolved to '$(plan_field "$plan" profile)', expected '$expected_profile'"

    # The fixture is shared by the Balanced and Lite cells of a probe, so it is
    # named without the profile suffix.
    expected_fixture="${scenario%-$expected_profile}"
    scenario_check "$([[ "$(plan_field "$plan" fixture)" == */"$expected_fixture" ]] && printf 1 || printf 0)" \
        "fixture resolved to '$(plan_field "$plan" fixture)', expected .../$expected_fixture"

    # The probe label is the full scenario name: it is the cell identity that
    # reaches the transcript, the README and state-check.json.
    scenario_check "$([[ "$(plan_field "$plan" probe)" == "$scenario" ]] && printf 1 || printf 0)" \
        "probe resolved to '$(plan_field "$plan" probe)', expected '$scenario'"

    # The prompt must come from the scenario file, not be duplicated in the
    # harness: a drift between the two would capture the wrong task.
    scenario_prompt="$(awk '/^## Prompt$/{f=1;next} /^## /{f=0} f' "$SCEN_DIR/$scenario.md" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | head -1)"
    plan_prompt="$(sed -n 's/^CAPTURE_PROMPT|//p' "$plan" | head -1)"
    scenario_check "$([[ -n "$scenario_prompt" && "$plan_prompt" == "$scenario_prompt" ]] && printf 1 || printf 0)" \
        "prompt resolved to '$plan_prompt', expected '$scenario_prompt'"

    # --print-plan must not touch the filesystem: the bundle directory is a
    # destination, not a side effect.
    scenario_check "$([[ ! -e "$TMP/$scenario-bundle" ]] && printf 1 || printf 0)" \
        "--print-plan created the bundle directory"
    report "plan $scenario"
done

printf '== Twin parity ==\n'
if PWSH="$(pwsh_bin)"; then
    begin
    # Both forwarders are given the same bundle path: the plan echoes it, so a
    # difference in the path would mask a real difference in the plan.
    bash "$HARNESS_SH" ce-escalation-balanced "$TMP/twin-bundle" --print-plan >"$TMP/twin-sh.txt" 2>&1
    check_status "$?" 0
    "$PWSH" -NoProfile -File "$HARNESS_PS1" ce-escalation-balanced "$TMP/twin-bundle" --print-plan >"$TMP/twin-ps.txt" 2>&1
    check_status "$?" 0
    scenario_check "$(diff -q "$TMP/twin-sh.txt" "$TMP/twin-ps.txt" >/dev/null 2>&1 && printf 1 || printf 0)" "Bash and PowerShell plans differ"
    if ! diff -q "$TMP/twin-sh.txt" "$TMP/twin-ps.txt" >/dev/null 2>&1; then
        diff "$TMP/twin-sh.txt" "$TMP/twin-ps.txt" | head -6 | sed 's/^/    /'
    fi
    report 'Bash and PowerShell forwarders produce identical plans'
else
    printf 'SKIP: PowerShell forwarder parity (pwsh not available)\n'
fi

printf '== Committed bundles keep grading material out of the fixture ==\n'
for scenario in $SCENARIOS; do
    bundle="$BUNDLES/$scenario"
    begin
    if [[ ! -f "$bundle/kit-exclusions.txt" ]]; then
        scenario_check 0 "bundle has no kit-exclusions.txt: $scenario"
        report "exclusions $scenario"
        continue
    fi
    # Every exclusion must be recorded as absent. A 'LEAK' line means the model
    # under test could have read its own rubric, which invalidates the capture.
    scenario_check "$(grep -qE '^LEAK ' "$bundle/kit-exclusions.txt" && printf 0 || printf 1)" \
        "kit-exclusions.txt records a leak"
    for rel in scripts/tests/eval-scenarios scripts/run-behavioral-eval.sh docs/BEHAVIORAL-EVAL.md docs/internal/host-conformance docs/tasks; do
        scenario_check "$(grep -qE "^absent  $rel( |\$)" "$bundle/kit-exclusions.txt" && printf 1 || printf 0)" \
            "kit-exclusions.txt does not record $rel as absent"
    done
    # The discovery route must survive the pruning, or the capture measures nothing.
    for rel in protocols/context-economy.md protocols/setup.md docs/WORKFLOW-MAP.md workflows/route.md; do
        scenario_check "$(grep -qE "^present  $rel( |\$)" "$bundle/kit-exclusions.txt" && printf 1 || printf 0)" \
            "kit-exclusions.txt does not record $rel as present"
    done
    report "exclusions $scenario"
done

printf '== Committed canaries can fail ==\n'
for scenario in $SCENARIOS; do
    bundle="$BUNDLES/$scenario"
    begin
    if [[ ! -f "$bundle/canary.txt" ]]; then
        scenario_check 0 "bundle has no canary.txt: $scenario"
        report "canary $scenario"
        continue
    fi
    line="$(grep -E '^CANARY\|' "$bundle/canary.txt" | head -1)"
    scenario_check "$([[ -n "$line" ]] && printf 1 || printf 0)" "canary.txt has no CANARY| verdict line"
    scenario_check "$([[ "$line" == CANARY\|PASS* ]] && printf 1 || printf 0)" "canary did not pass: $line"
    # The control arm is what makes the canary meaningful: if it found nothing,
    # the isolated arm's empty result proves nothing at all.
    unisolated="$(sed -nE 's/.*\|unisolated=([0-9]+).*/\1/p' <<<"$line")"
    isolated="$(sed -nE 's/.*\|isolated=([0-9]+).*/\1/p' <<<"$line")"
    scenario_check "$([[ -n "$unisolated" && "$unisolated" -gt 0 ]] && printf 1 || printf 0)" \
        "control arm found no copy, so the canary proves nothing: $line"
    scenario_check "$([[ "$isolated" == 0 ]] && printf 1 || printf 0)" "isolated arm still found copies: $line"
    # The direct-read arm is the one that catches a blind sweep: a bounded find
    # can miss a readable file, but cat either opens it or it does not.
    scenario_check "$([[ "$line" == *'direct-read=blocked'* ]] && printf 1 || printf 0)" \
        "direct-read arm did not report a blocked read: $line"
    report "canary $scenario"
done

printf '== Committed bundles record a reproducible timeline ==\n'
for scenario in $SCENARIOS; do
    bundle="$BUNDLES/$scenario"
    begin
    if [[ ! -f "$bundle/provenance.json" || ! -f "$bundle/transcript.md" ]]; then
        scenario_check 0 "bundle is missing provenance.json or transcript.md: $scenario"
        report "timeline $scenario"
        continue
    fi
    # The renderer reconstructs the timeline from a recorded anchor rather than
    # from the stream file's mtime, because git does not preserve mtime and a
    # committed bundle re-rendered elsewhere would shift every timestamp. The
    # anchor must therefore be in the bundle, and it must be the instant the
    # harness observed before spawning agy - not an approximation derived from
    # the reported duration, which drifts by the harness's own overhead.
    anchor="$(sed -nE 's/.*"timelineStart"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$bundle/provenance.json" | head -1)"
    observed="$(sed -nE 's/.*"observationStart"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$bundle/provenance.json" | head -1)"
    window_end="$(sed -nE 's/.*"observationEnd"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$bundle/provenance.json" | head -1)"
    scenario_check "$([[ -n "$anchor" ]] && printf 1 || printf 0)" "provenance.json records no timelineStart: $scenario"
    if [[ -n "$anchor" && -n "$observed" ]]; then
        anchor_epoch="$(date -d "$anchor" +%s 2>/dev/null || true)"
        observed_epoch="$(date -d "$observed" +%s 2>/dev/null || true)"
        scenario_check "$([[ -n "$anchor_epoch" && "$anchor_epoch" == "$observed_epoch" ]] && printf 1 || printf 0)" \
            "timelineStart ($anchor) is not the observed capture start ($observed): $scenario"
    fi
    # Every rendered entry must land inside the window the same bundle records.
    # A timeline that contradicts its own provenance is not evidence.
    first_ts="$(sed -nE 's/^- .([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+[+-][0-9]{2}:[0-9]{2}). .*/\1/p' "$bundle/transcript.md" | head -1)"
    last_ts="$(sed -nE 's/^- .([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+[+-][0-9]{2}:[0-9]{2}). .*/\1/p' "$bundle/transcript.md" | tail -1)"
    if [[ -n "$first_ts" && -n "$last_ts" && -n "$observed" && -n "$window_end" ]]; then
        first_epoch="$(date -d "$first_ts" +%s 2>/dev/null || true)"
        last_epoch="$(date -d "$last_ts" +%s 2>/dev/null || true)"
        start_epoch="$(date -d "$observed" +%s 2>/dev/null || true)"
        end_epoch="$(date -d "$window_end" +%s 2>/dev/null || true)"
        scenario_check "$([[ -n "$first_epoch" && "$first_epoch" -ge "$start_epoch" && "$last_epoch" -le "$end_epoch" ]] && printf 1 || printf 0)" \
            "transcript timeline ($first_ts .. $last_ts) falls outside the recorded window ($observed .. $window_end): $scenario"
    fi
    report "timeline $scenario"
done

printf '== Committed bundles still score their recorded verdict ==\n'
for scenario in $SCENARIOS; do
    bundle="$BUNDLES/$scenario"
    begin
    if [[ ! -f "$bundle/scorer.txt" || ! -f "$bundle/transcript.md" ]]; then
        scenario_check 0 "bundle is missing scorer.txt or transcript.md: $scenario"
        report "score $scenario"
        continue
    fi
    rendered="$(bash "$SCORER" --score "$scenario" "$bundle/transcript.md" 2>&1 | grep -E "^$scenario\|" | head -1)"
    committed="$(grep -E "^$scenario\|" "$bundle/scorer.txt" | head -1)"
    scenario_check "$([[ -n "$rendered" ]] && printf 1 || printf 0)" "scorer produced no verdict line for $scenario"
    scenario_check "$([[ "$rendered" == "$committed" ]] && printf 1 || printf 0)" \
        "verdict differs: rendered '$rendered' vs committed '$committed'"
    report "score $scenario"
done

printf '== Fresh clone: every bundle write log is tracked and a stub is rejected ==\n'
# The defect this case exists for: the repository root ignores *.log, and a
# negation only takes effect in a .gitignore at or below the ignored path. The
# bundles had no .gitignore of their own, so every observed-writes.log was
# silently untracked - the bundle's primary evidence never reached a clone, and
# a fresh checkout graded each bundle from whatever else it happened to carry.
# A working tree cannot show this: the file is right there on disk. Only a
# clone can, which is why the case clones.
#
# The second half is the same defect one layer down. A comment-only stub is a
# note that the log does not apply, not a log, and a scorer that accepts one
# searches it, finds no prohibited action, and reports compliance. Both halves
# are asserted here because either one alone still publishes a bundle that
# cannot be re-graded.
begin
CLONE="$TMP/fresh-clone"
if ! git clone --quiet --no-hardlinks --shared "$REPO_ROOT" "$CLONE" 2>"$TMP/clone.err"; then
    scenario_check 0 "git clone failed: $(head -1 "$TMP/clone.err")"
    report 'fresh clone reproduces every bundle write log'
else
    # The clone starts from HEAD, and the fix is uncommitted by instruction, so
    # the bundle files are copied in from the working tree before the assertion.
    # That is not a shortcut around the check: what is under test is whether git
    # will TRACK the log given the .gitignore that sits beside it, and the copy
    # only puts the two files where git can answer that. A clone of HEAD alone
    # would test the defect instead of the fix.
    for scenario in $SCENARIOS; do
        bundle="$BUNDLES/$scenario"
        dest="$CLONE/docs/internal/host-conformance/antigravity/$scenario"
        # The log must exist in the working tree at all: a bundle with no write
        # log cannot substantiate anything, and the tracked check below would
        # otherwise pass vacuously on a missing file.
        scenario_check "$([[ -s "$bundle/observed-writes.log" ]] && printf 1 || printf 0)" \
            "bundle has no non-empty observed-writes.log: $scenario"
        scenario_check "$([[ -f "$bundle/.gitignore" ]] && printf 1 || printf 0)" \
            "bundle has no .gitignore, so its write log cannot be un-ignored: $scenario"
        mkdir -p "$dest"
        [[ -f "$bundle/.gitignore" ]] && cp "$bundle/.gitignore" "$dest/.gitignore"
        [[ -f "$bundle/observed-writes.log" ]] && cp "$bundle/observed-writes.log" "$dest/observed-writes.log"
        rel="docs/internal/host-conformance/antigravity/$scenario/observed-writes.log"
        # git check-ignore exits 0 when the path IS ignored and 1 when it is not.
        # Asserting the exit status rather than the output is deliberate: with -v
        # git prints the matching negation line and still exits 0, so an output
        # match would read a negation as an ignore.
        git -C "$CLONE" check-ignore -q "$rel"
        scenario_check "$([[ $? -eq 1 ]] && printf 1 || printf 0)" \
            "observed-writes.log is still ignored in a fresh clone: $scenario"
        # Ignored is not the same as tracked, and staging is the operation that
        # separates them: git refuses an ignored path outright. This is the check
        # that would have caught the defect, because the old tree staged every
        # bundle file except the log and nothing said so.
        scenario_check "$(git -C "$CLONE" add -- "$rel" >/dev/null 2>&1 && printf 1 || printf 0)" \
            "git add refused the write log in a fresh clone: $scenario"
        scenario_check "$(git -C "$CLONE" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && printf 1 || printf 0)" \
            "observed-writes.log is not tracked in a fresh clone: $scenario"
    done
    report 'fresh clone reproduces every bundle write log'
fi

# The stub half. A bundle whose only write log is a comment must not grade as if
# it had recorded activity: the scorer has to report the evidence as absent
# rather than search a note and find no violation in it.
begin
STUB="$TMP/stub-bundle"
cp -r "$BUNDLES/ce-antistarvation-balanced" "$STUB"
printf '# Not applicable - this probe records no M2 writes.\n' > "$STUB/observed-writes.log"
printf '# Not applicable - this probe records no M2 writes.\n' > "$STUB/observed-m2-writes.txt"
stub_line="$(bash "$SCORER" --score ce-antistarvation-balanced "$STUB/transcript.md" 2>&1 | grep -E '^ce-antistarvation-balanced\|' | head -1)"
scenario_check "$([[ -n "$stub_line" ]] && printf 1 || printf 0)" "scorer produced no verdict line for the stub bundle"
# behavioral=UNTESTED is the assertion, not merely "not PASS": the scorer must
# say the evidence is absent. A comment-only log that graded PARTIAL would mean
# the stub was searched and its emptiness read as compliance.
scenario_check "$([[ "$stub_line" == *'behavioral=UNTESTED'* ]] && printf 1 || printf 0)" \
    "a comment-only write log was not rejected as absent evidence: $stub_line"
scenario_check "$([[ "$stub_line" == *'provenance=unverified'* ]] && printf 1 || printf 0)" \
    "a comment-only write log still verified provenance: $stub_line"
# The control: the same bundle with its real log must still grade as recorded,
# or the case would pass by rejecting every bundle rather than the stub.
real_line="$(bash "$SCORER" --score ce-antistarvation-balanced "$BUNDLES/ce-antistarvation-balanced/transcript.md" 2>&1 | grep -E '^ce-antistarvation-balanced\|' | head -1)"
scenario_check "$([[ "$real_line" == *'behavioral=PASS'* ]] && printf 1 || printf 0)" \
    "the real bundle no longer grades as recorded: $real_line"
report 'a comment-only write log is rejected as absent evidence'

printf '== Live capture (skipped without agy and bwrap) ==\n'
AGY="$(command -v agy 2>/dev/null || true)"
BWRAP="$(command -v bwrap 2>/dev/null || true)"
if [[ -n "$AGY" && -n "$BWRAP" ]]; then
    begin
    # A live capture spends a model turn, so it is not run here. What is asserted
    # is that the harness reaches the point of invoking the model: the plan
    # resolves and both binaries are found.
    plan="$TMP/live.plan"
    bash "$HARNESS_SH" ce-sufficiency-balanced "$TMP/live-bundle" --print-plan >"$plan" 2>&1
    check_status "$?" 0
    scenario_check "$([[ "$(sed -n 's/^CAPTURE_AGY|//p' "$plan" | head -1)" != '(not found)' ]] && printf 1 || printf 0)" "harness did not resolve agy"
    scenario_check "$([[ "$(sed -n 's/^CAPTURE_BWRAP|//p' "$plan" | head -1)" != '(not found)' ]] && printf 1 || printf 0)" "harness did not resolve bwrap"
    report 'harness resolves agy and bwrap for a live capture'
else
    printf 'SKIP: live capture prerequisites (agy and/or bwrap not available)\n'
fi

printf '\n'
if [[ "$FAIL" -eq 0 ]]; then
    printf 'CAPTURE_HOST_SESSION_TESTS|PASS|%d passed\n' "$PASS"
    exit 0
fi
printf 'CAPTURE_HOST_SESSION_TESTS|FAIL|%d passed, %d failed\n' "$PASS" "$FAIL"
exit 1
