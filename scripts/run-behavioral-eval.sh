#!/usr/bin/env bash
# PromptKit OS Behavioral Evaluation Harness (Bash)
#
# Scores model transcripts against scenario rubrics — observable properties of
# OUTPUTS (a Level was declared, code was withheld, a halt used the mandated
# callout), never prose equality. This complements the grep-based
# documentation-contract suite: that suite proves the docs say the right
# thing; this harness measures whether a model given the directive does it.
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
#       directive variant) and prints SCENARIO|live|PASS|FAIL plus detail.
#
# Output: machine-parseable SCENARIO|MODE|RESULT|EVIDENCE lines.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCEN_DIR="$REPO_ROOT/scripts/tests/eval-scenarios"

PASS_COUNT=0
FAIL_COUNT=0

section() {
    # section <file> <heading> : print lines under "## <heading>" until next "## " or EOF
    awk -v h="## $2" '$0==h{f=1;next} /^## /{f=0} f' "$1"
}

eval_checks() {
    # eval_checks <transcript-file> <checks-text> : all checks must hold; prints failures, returns 0/1
    local transcript="$1" checks="$2" ok=0 total=0
    local first
    first="$(head -n 1 "$transcript")"
    while IFS= read -r line; do
        line="${line#- }"
        [ -z "$line" ] && continue
        local type="${line%%:*}" pat="${line#*: }"
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
    local checks detail
    checks="$(section "$f" "Checks")"
    if detail="$(eval_checks "$transcript" "$checks" 2>&1)"; then
        echo "$name|live|PASS|all-checks-hold"
    else
        echo "$name|live|FAIL|check-violations"
        echo "$detail"
        exit 1
    fi
}

case "${1:-}" in
    --self-test) run_self_test ;;
    --score) run_score "${2:-}" "${3:-}" ;;
    *) echo "Usage: $0 --self-test | --score <scenario> <transcript-file>" >&2; exit 2 ;;
esac
