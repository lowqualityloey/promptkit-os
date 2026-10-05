#!/usr/bin/env bash
# PromptKit OS Behavioral Evaluation Harness (Bash)
#
# Scores model transcripts against scenario rubrics in two independent layers:
#
#   * PRESENTATION (field 3, RESULT) — the transcript's observable output
#     properties: a Level was declared, code was withheld, a halt used the
#     mandated callout. All presentation checks must hold; prose equality is
#     never asserted.
#   * BEHAVIOR (field 5, behavioral=) — properties of the capture bundle that
#     holds the transcript: an artifact exists, a prohibited write never
#     happened, recovery reads happened in the mandated order, a recorded field
#     holds a real value instead of a placeholder. Keywords cannot satisfy
#     these; only recorded evidence can, so prose that merely *mentions* halting
#     or checkpointing never earns behavioral credit.
#
# This complements the grep-based documentation-contract suite: that suite
# proves the docs say the right thing; this harness measures whether a model
# given the directive does it.
#
# Honesty contract: sampled compliance for named models at a named commit,
# not a guarantee. See docs/BEHAVIORAL-EVAL.md.
#
# Usage (from repository root):
#   bash scripts/run-behavioral-eval.sh --self-test
#       Offline CI mode. Scores the PASS/FAIL fixtures embedded in every
#       scenario file through the same check engine as live scoring.
#       PASS fixtures must satisfy all checks; FAIL fixtures must violate
#       at least one. No network, no API keys. Exit 0 on success.
#   bash scripts/run-behavioral-eval.sh --score <scenario> <transcript-file>
#       Live mode. Scores one transcript (produced by any model under any
#       directive variant) and prints the scored line plus failure detail.
#       The evidence bundle is dirname(<transcript-file>); there is no flag for
#       it, matching the bundle layout scripts/check-milestone-halt-evidence.sh
#       already invokes this harness with.
#
# Output: machine-parseable lines.
#   SCENARIO|MODE|RESULT|EVIDENCE|provenance=STATE
#       The scenario declares no evidence checks: RESULT is the presentation
#       verdict.
#   SCENARIO|MODE|RESULT|EVIDENCE|behavioral=VERDICT|provenance=STATE
#       The scenario declares at least one evidence check: a behavioral verdict,
#       graded from bundle evidence alone. VERDICT is PASS, PARTIAL, UNTESTED, or
#       FAIL. UNTESTED means the evidence needed to judge was absent — an invalid
#       observation, never a pass (docs/internal/host-conformance-pack/README.md).
# Fields 1-4 keep their exact meaning for every scenario, so callers that
# anchor on SCENARIO|live|PARTIAL| stay correct.
#
# MODE is a scoring mode, not an origin. A hand-written transcript scores in `live`
# mode too, so provenance is reported as its own trailing field and is always
# present: `provenance=verified` when the bundle carries all ten provenance keys
# with real values plus a recorded write log (provenance_verified), and
# `provenance=unverified` otherwise. It never moves RESULT and never moves an exit
# code — a synthetic fixture is labelled, not scored differently.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCEN_DIR="$REPO_ROOT/scripts/tests/eval-scenarios"

PASS_COUNT=0
FAIL_COUNT=0
CHECKS_MET=0
CHECKS_TOTAL=0

section() {
    # section <file> <heading> : print lines under "## <heading>" until next "## " or EOF
    awk -v h="## $2" '$0==h{f=1;next} /^## /{f=0} f' "$1"
}

trim() {
    # trim <text> : strip leading and trailing whitespace
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

evidence_write_log() {
    # evidence_write_log <bundle-dir> : the bundle's recorded tool-activity write
    # log, or empty when the bundle records none. [ -s ], not [ -f ]: an empty log
    # records no tool activity, so grepping it finds no prohibited write and would
    # report "holds" — grading a capture that observed nothing as behavioral=PASS.
    local bundle="$1"
    if [ -s "$bundle/observed-writes.log" ]; then printf '%s' "$bundle/observed-writes.log"
    elif [ -s "$bundle/observed-m2-writes.txt" ]; then printf '%s' "$bundle/observed-m2-writes.txt"
    fi
}

evidence_record() {
    # evidence_record <bundle-dir> [record-path] : the canonical Task/Checkpoint
    # Record inside the bundle. Without an explicit path, state-check.json may
    # name it via recordPath or taskRecord; the default is docs/STATE.md.
    # Resolved against the bundle's repository clone first, then the bundle root,
    # then the bare filename, and finally the recorded end-of-capture copy of the
    # default. Fails when the bundle holds no record at all.
    local bundle="$1" path file
    path="${2:-}"
    if [ -z "$path" ]; then
        path="$(sed -nE 's/.*"(recordPath|taskRecord)"[[:space:]]*:[[:space:]]*"([^"]*)".*/\2/p' "$bundle/state-check.json" 2>/dev/null | head -n 1)"
        [ -n "$path" ] || path='docs/STATE.md'
    fi
    path="${path#./}"
    for file in "$bundle/repository/$path" "$bundle/$path" "$bundle/${path##*/}"; do
        [ -s "$file" ] && { printf '%s' "$file"; return 0; }
    done
    if [ "$path" = 'docs/STATE.md' ] && [ -s "$bundle/state-at-end.md" ]; then
        printf '%s' "$bundle/state-at-end.md"
        return 0
    fi
    return 1
}

evidence_field_value() {
    # evidence_field_value <record> <Label> : value of the canonical record field,
    # mirroring validate-execution-control.sh field_value — the needle is anchored
    # at column 1, so indented lines and table rows never match; only the first
    # match counts; a fully backtick-wrapped value loses its outer backticks.
    awk -v needle="- **${2}**:" '{ sub(/\r$/, "") } index($0, needle) == 1 { value=substr($0, length(needle)+1); sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); if (value ~ /^`.*`$/) value=substr(value, 2, length(value)-2); sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); print value; exit }' "$1"
}

evidence_is_placeholder() {
    # evidence_is_placeholder <value> : 0 when the value is a placeholder,
    # mirroring validate-execution-control.sh is_placeholder
    local value
    value="$(trim "$1")"
    [ -z "$value" ] && return 0
    case "$value" in
        "N/A"|"n/a"|"None"|"none"|"Not applicable"|"not applicable"|"[N/A]"|"[None]"|"[Pending]"|"Pending") return 0 ;;
    esac
    [[ "$value" == \[*\] ]] && return 0
    return 1
}

evidence_path_written() {
    # evidence_path_written <write-log> <path-prefix> : 0 when the log records a
    # write at or under the prefix. The log captures writes observed in tool
    # activity, so a match is a boundary violation even when the repository is
    # clean again because the write was reverted.
    local log="$1" prefix line token
    prefix="${2#./}"
    prefix="${prefix%/}"
    [ -n "$prefix" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        for token in ${line//[(),;[]/ }; do
            token="${token#./}"
            token="${token%/}"
            if [ "$token" = "$prefix" ] || [[ "$token" == "$prefix/"* ]]; then return 0; fi
        done
    done < "$log"
    return 1
}

# The provenance record a genuine capture must carry, mirroring the required key
# list at scripts/check-milestone-halt-evidence.sh:19.
PROVENANCE_KEYS=(captureDate promptkitCommit profile seedCommit resetCommands openCodeVersion omoVersion agentModel observationStart observationEnd)

evidence_json_value() {
    # evidence_json_value <file> <key> : the value of a JSON string key, or empty
    # when the key is absent or its value is not a string literal — a non-string
    # (null, true, a nested object) is as absent as a missing key. A textual scan,
    # not a JSON parse: this harness stays dependency-free (no jq, python, or node)
    # and the PowerShell twin has to reach the identical verdict from the identical
    # file, which it can only do with the same text rules. Tolerates either quote
    # spacing and CRLF endings; the first line carrying the key wins.
    awk -v needle="\"$2\"" '{ sub(/\r$/, "") } index($0, needle) { rest = substr($0, index($0, needle) + length(needle)); if (rest ~ /^[ \t]*:[ \t]*"/) { sub(/^[ \t]*:[ \t]*"/, "", rest); end = index(rest, "\""); if (end > 0) { print substr(rest, 1, end - 1); exit } } }' "$1"
}

provenance_verified() {
    # provenance_verified <bundle-dir> : 0 when the bundle substantiates a genuine
    # capture. `live` in field 2 names the scoring MODE (--score, not --self-test),
    # never the origin of the transcript, so provenance is derived here instead of
    # asserted: all ten provenance keys must hold real, non-placeholder string
    # values — the set scripts/check-milestone-halt-evidence.sh:19 requires — AND a
    # recorded write log must accompany the transcript. The write log is required
    # because a capture with no tool activity cannot substantiate a halt or
    # checkpoint claim, however complete its metadata is.
    local bundle="$1" file key
    [ -n "$(evidence_write_log "$bundle")" ] || return 1
    file="$bundle/provenance.json"
    [ -s "$file" ] || return 1
    for key in "${PROVENANCE_KEYS[@]}"; do
        evidence_is_placeholder "$(evidence_json_value "$file" "$key")" && return 1
    done
    return 0
}

eval_evidence() {
    # eval_evidence <type> <pattern> <transcript> : prints its own detail line.
    # Returns 0 when the evidence holds, 1 when the evidence needed to judge is
    # absent (UNTESTED), 2 when the evidence shows a violation.
    local type="$1" pat="$2" bundle log record value target prev=0 step at
    local -a steps
    bundle="$(dirname "$3")"
    case "$type" in
        evidence-present)
            if [ -s "$bundle/$pat" ]; then return 0; fi
            echo "    ✗ evidence-present '$pat' missing or empty in bundle"; return 1 ;;
        evidence-absent)
            if [ ! -e "$bundle/$pat" ] || [ ! -s "$bundle/$pat" ]; then return 0; fi
            echo "    ✗ evidence-absent '$pat' present in bundle"; return 2 ;;
        prohibited-action)
            log="$(evidence_write_log "$bundle")"
            if [ -z "$log" ]; then
                echo "    ✗ prohibited-action '$pat' unjudgeable (bundle records no write log)"; return 1
            fi
            if grep -Eq "$pat" "$log"; then
                echo "    ✗ prohibited action '$pat' observed in $(basename "$log")"; return 2
            fi
            return 0 ;;
        evidence-order)
            # Ordered steps, space- or pipe-separated. Proves the mandate read
            # order (task record, then checkpoint, then STATE/workflow/root
            # directives) rather than asserting it with keywords.
            log="$(evidence_write_log "$bundle")"
            IFS=$' \t|' read -r -a steps <<< "$pat"
            if [ -z "$log" ] || [ "${#steps[@]}" -lt 2 ]; then
                echo "    ✗ evidence-order '$pat' unjudgeable (needs >=2 ordered paths and a recorded write log)"; return 1
            fi
            for step in "${steps[@]}"; do
                at="$(grep -nE -- "$step" "$log" | head -n 1 | cut -d: -f1)"
                if [ -z "$at" ]; then
                    echo "    ✗ evidence-order step '$step' never observed in $(basename "$log")"; return 1
                fi
                if [ "$at" -le "$prev" ]; then
                    if [ "$at" -eq "$prev" ]; then
                        echo "    ✗ evidence-order steps '$step' and its predecessor are not separable in $(basename "$log") (both at line $at)"; return 1
                    fi
                    echo "    ✗ evidence-order step '$step' at line $at came after its predecessor at line $prev"
                    return 2
                fi
                prev="$at"
            done
            return 0 ;;
        repo-unwritten)
            log="$(evidence_write_log "$bundle")"
            if [ -z "$log" ]; then
                echo "    ✗ repo-unwritten '$pat' unjudgeable (bundle records no write log)"; return 1
            fi
            if evidence_path_written "$log" "$pat"; then
                echo "    ✗ repo-unwritten '$pat' written in tool activity, even if later reverted"; return 2
            fi
            return 0 ;;
        record-field)
            # "<record-path>|<Label>" names the record explicitly; a bare "<Label>"
            # resolves it through the bundle ladder.
            target=''
            case "$pat" in *'|'*) target="${pat%%|*}"; pat="${pat#*|}" ;; esac
            record="$(evidence_record "$bundle" "$target")"
            if [ -z "$record" ]; then
                echo "    ✗ record-field '$pat' unjudgeable (bundle holds no canonical record)"; return 1
            fi
            value="$(evidence_field_value "$record" "$pat")"
            if [ -z "$value" ]; then
                echo "    ✗ record-field '$pat' absent from $(basename "$record")"; return 2
            fi
            if evidence_is_placeholder "$value"; then
                echo "    ✗ record-field '$pat' is a placeholder in $(basename "$record")"; return 2
            fi
            return 0 ;;
    esac
}

eval_checks() {
    # eval_checks <transcript-file> <checks-text>
    # The four presentation check types decide RESULT by the all-must-hold rule.
    # The six evidence check types read the capture bundle and decide the
    # behavioral verdict reported beside RESULT; they never move RESULT.
    # Prints one detail line per failure, then the side-channel line
    #   CHECKS|<presentation-met>|<presentation-total>|<behavioral>|<evidence-seen>
    # and returns 0 only when every presentation check holds.
    local transcript="$1" checks="$2"
    local first ok=0 total=0 ev_violation=0 ev_untested=0 ev_seen=0
    local line type pat status verdict='-'
    first="$(head -n 1 "$transcript")"
    while IFS= read -r line; do
        line="${line#- }"
        [ -z "$line" ] && continue
        type="${line%%:*}" pat="${line#*: }"
        case "$type" in
            evidence-present|evidence-absent|prohibited-action|evidence-order|repo-unwritten|record-field)
                ev_seen=1
                eval_evidence "$type" "$pat" "$transcript"
                status=$?
                case "$status" in
                    0) ;;
                    1) ev_untested=$((ev_untested + 1)) ;;
                    *) ev_violation=$((ev_violation + 1)) ;;
                esac
                continue ;;
        esac
        total=$((total + 1))
        case "$type" in
            first-line-matches)
                if printf '%s' "$first" | grep -Eq "$pat"; then ok=$((ok + 1));
                else echo "    ✗ first-line-matches '$pat' (got: $first)"; fi ;;
            contains)
                if grep -Eq "$pat" "$transcript"; then ok=$((ok + 1));
                else echo "    ✗ missing '$pat'"; fi ;;
            not-contains)
                if grep -Eq "$pat" "$transcript"; then echo "    ✗ forbidden '$pat' present";
                else ok=$((ok + 1)); fi ;;
            contains-any)
                local hit=0 alt
                IFS='|' read -ra ALTS <<< "$pat"
                for alt in "${ALTS[@]}"; do
                    if grep -Eq "$alt" "$transcript"; then hit=1; break; fi
                done
                if [ "$hit" -eq 1 ]; then ok=$((ok + 1));
                else echo "    ✗ none of '$pat' present"; fi ;;
            *) echo "    ✗ unknown check type '$type'"; ;;
        esac
    done <<< "$checks"
    if [ "$ev_seen" -eq 1 ]; then
        # A prohibited action or any observed violation outranks everything; absent
        # evidence is an invalid observation, never a pass; only then does the
        # presentation verdict leak into the behavioral one.
        if [ "$ev_violation" -gt 0 ]; then verdict='FAIL'
        elif [ "$ev_untested" -gt 0 ]; then verdict='UNTESTED'
        elif [ "$ok" -ne "$total" ]; then verdict='PARTIAL'
        else verdict='PASS'
        fi
    fi
    printf 'CHECKS|%s|%s|%s|%s\n' "$ok" "$total" "$verdict" "$ev_seen"
    [ "$ok" -eq "$total" ] && [ "$total" -gt 0 ]
}

run_self_test() {
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp:-}"' EXIT
    echo ""
    echo "🧪 Behavioral Eval Offline Self-Test (fixtures through the live scoring path)"
    echo "==========================================================================="
    local f name
    for f in "$SCEN_DIR"/*.md; do
        name="$(basename "$f" .md)"
        section "$f" "Transcript-PASS" > "$tmp/pass.md"
        section "$f" "Transcript-FAIL" > "$tmp/fail.md"
        local checks
        checks="$(section "$f" "Checks")"
        local detail
        if detail="$(eval_checks "$tmp/pass.md" "$checks" 2>&1)"; then
            if detail="$(eval_checks "$tmp/fail.md" "$checks" 2>&1)"; then
                echo "  ❌ FAIL: $name — FAIL fixture unexpectedly satisfies all checks"
                echo "$name|self-test|FAIL|fail-fixture-satisfies-all-checks"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            else
                echo "  ✅ PASS: $name (pass-fixture holds, fail-fixture violates)"
                echo "$name|self-test|PASS|pass-holds-fail-violates"
                PASS_COUNT=$((PASS_COUNT + 1))
            fi
        else
            echo "  ❌ FAIL: $name — PASS fixture violates checks:"
            echo "$detail" | sed 's/^/    /'
            echo "$name|self-test|FAIL|pass-fixture-violates-checks"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    done
    echo "==========================================================================="
    echo "Passed: $PASS_COUNT | Failed: $FAIL_COUNT"
    [ "$FAIL_COUNT" -eq 0 ]
}

run_score() {
    local name="$1" transcript="$2"
    local f="$SCEN_DIR/$name.md"
    [ -f "$f" ] || { echo "Unknown scenario '$name' (see $SCEN_DIR)" >&2; exit 2; }
    [ -f "$transcript" ] || { echo "Transcript file '$transcript' not found" >&2; exit 2; }
    local checks detail summary status result suffix behavioral evidence provenance
    checks="$(section "$f" "Checks")"
    detail="$(eval_checks "$transcript" "$checks" 2>&1)"
    status=$?
    summary="$(printf '%s\n' "$detail" | tail -n 1)"
    IFS='|' read -r _side_channel CHECKS_MET CHECKS_TOTAL behavioral evidence <<< "$summary"
    detail="$(printf '%s\n' "$detail" | sed '$d')"
    if [ "$evidence" = '1' ]; then suffix="|behavioral=$behavioral"; else suffix=''; fi
    if [ "$status" -eq 0 ]; then result='PASS'
    elif [ "$CHECKS_MET" -gt 0 ]; then result='PARTIAL'
    else result='FAIL'
    fi
    if provenance_verified "$(dirname "$transcript")"; then provenance='verified'; else provenance='unverified'; fi
    # Provenance is reported on an axis of its own: it records where the transcript
    # came from, never whether the model behaved, and it moves no exit code.
    echo "$name|live|$result|checks=$CHECKS_MET/$CHECKS_TOTAL$suffix|provenance=$provenance"
    if [ "$status" -ne 0 ] || { [ "$evidence" = '1' ] && [ "$behavioral" != 'PASS' ]; }; then echo "$detail"; fi
    # Exit 0 only when the presentation verdict passes AND no observed boundary
    # violation was recorded. An observed prohibited action or an inverted
    # recovery-read order is behavioral=FAIL and must be non-zero on its own:
    # scripts/check-milestone-halt-evidence.sh:94 consumes this exit status as
    # success, so a FAIL that exited 0 would be indistinguishable from a pass.
    # behavioral=UNTESTED never fails here on its own — absent evidence is an
    # invalid observation, not observed misbehavior.
    [ "$result" = 'PASS' ] && [ "$behavioral" != 'FAIL' ] || exit 1
}

case "${1:-}" in
    --self-test) run_self_test ;;
    --score) run_score "${2:-}" "${3:-}" ;;
    *) echo "Usage: $0 --self-test | --score <scenario> <transcript-file>" >&2; exit 2 ;;
esac
