#!/usr/bin/env bash
# PromptKit OS Command Code Telemetry Extractor
# Converts a Command Code session transcript (JSONL, schema v3, as written
# under ~/.commandcode/projects/<slug>/<session>.jsonl) into the standardized
# telemetry record defined in docs/BENCHMARK-METHODOLOGY.md §5, for scoring by
# scripts/measure-cpac.sh. Dependency-free: a single awk state machine, no
# jq/python/node. The .ps1 twin reaches identical field values from identical
# input.
#
# v1 mapping and known approximations (documented in BENCHMARK-METHODOLOGY §5):
# - tokens_in/tokens_out sum usage over SUCCESSFUL assistant turns; a turn whose
#   tool results since the previous assistant turn include a failure (per the
#   error-pattern heuristic) is a rework turn (rework_tokens_in/out).
# - Command Code schema v3 records no tool exit codes, so failed loops are a
#   documented heuristic over tool_result text (default patterns below,
#   overridable with --error-patterns="a|b").
# - cache_read_tokens is reported but excluded from C_inference (the §5
#   pricing model has no cache-read price; this is the v1 convention).
# - human_interventions counts user prompts after the first (the initial
#   request is the task, not an intervention).
# - tool_calls_search/edit/verify classify tool names and shell commands with
#   best-effort keyword rules; the remainder is tool_calls_other.
set -euo pipefail
# Locale-independent formatting: the emitted record must always carry dot
# decimals regardless of the host locale.
export LC_ALL=C

DEFAULT_ERROR_PATTERNS="No tool named|command not found|Error:|error:|ERROR:|Traceback|Exception|Permission denied|FAILED|npm ERR!"

SCENARIO_ID=""
CONDITION="unspecified"
ACCEPTED="false"
INV_CHECKED="0"
INV_PASSED="0"
ERROR_PATTERNS="$DEFAULT_ERROR_PATTERNS"
TARGET_FILE=""

usage() {
    echo "Usage: extract-commandcode-telemetry.sh <session.jsonl> [options]"
    echo "Options:"
    echo "  --scenario-id=ID         §5 scenario_id (default: the session id)"
    echo "  --condition=NAME         §5 condition label (default: unspecified)"
    echo "  --accepted=true|false    §5 accepted gate (default: false — acceptance is a human judgment)"
    echo "  --invariants-checked=N   §5 invariants_checked (default: 0)"
    echo "  --invariants-passed=N    §5 invariants_passed (default: 0)"
    echo "  --error-patterns=\"a|b\"   rework-loop detection patterns (default: $DEFAULT_ERROR_PATTERNS)"
    echo ""
    echo "Emits the §5 telemetry record on stdout and an EXTRACT|... status line"
    echo "on stderr. Exit 0 on success; exit 2 on unreadable input or a file with"
    echo "no Command Code session line."
}

for arg in "$@"; do
    case "$arg" in
        --scenario-id=*) SCENARIO_ID="${arg#--scenario-id=}" ;;
        --condition=*) CONDITION="${arg#--condition=}" ;;
        --accepted=*) ACCEPTED="${arg#--accepted=}" ;;
        --invariants-checked=*) INV_CHECKED="${arg#--invariants-checked=}" ;;
        --invariants-passed=*) INV_PASSED="${arg#--invariants-passed=}" ;;
        --error-patterns=*) ERROR_PATTERNS="${arg#--error-patterns=}" ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*|-*-*)
            printf 'EXTRACT|ERROR|UNKNOWN_FLAG|%s\n' "$arg" >&2
            exit 2
            ;;
        *)
            if [[ -n "$TARGET_FILE" ]]; then
                printf 'EXTRACT|ERROR|MULTIPLE_INPUTS|%s\n' "$arg" >&2
                exit 2
            fi
            TARGET_FILE="$arg"
            ;;
    esac
done

if [[ -z "$TARGET_FILE" ]]; then
    usage
    exit 2
fi
if [[ "$ACCEPTED" != "true" && "$ACCEPTED" != "false" ]]; then
    printf 'EXTRACT|ERROR|BAD_VALUE|accepted\n' >&2
    exit 2
fi
for inv in "$INV_CHECKED" "$INV_PASSED"; do
    if [[ ! "$inv" =~ ^[0-9]+$ ]]; then
        printf 'EXTRACT|ERROR|BAD_VALUE|invariants\n' >&2
        exit 2
    fi
done
if [[ -z "$ERROR_PATTERNS" ]]; then
    printf 'EXTRACT|ERROR|BAD_VALUE|error-patterns\n' >&2
    exit 2
fi
for strval in "$SCENARIO_ID" "$CONDITION"; do
    if [[ "$strval" == *[\"\\]* ]]; then
        printf 'EXTRACT|ERROR|BAD_VALUE|scenario-or-condition\n' >&2
        exit 2
    fi
done
if [[ ! -s "$TARGET_FILE" ]]; then
    printf 'EXTRACT|ERROR|NOT_FOUND|%s\n' "$TARGET_FILE" >&2
    exit 2
fi

extract_facts() {
    awk -v pats="$ERROR_PATTERNS" '
    function epoch(t,  y, mo, d, h, mi, s, off, sign, oh, om, yy, mm, era, yoe, doy, doe, days) {
        # ISO-8601 (YYYY-MM-DDTHH:MM:SS[.frac])(Z | ±HH:MM) → UTC epoch seconds
        # via pure integer arithmetic (the civil-days algorithm) — POSIX awk has
        # no mktime, and mktime would also interpret the fields in the local
        # timezone of the host. A timestamp with no zone suffix is read as UTC
        # (the Command Code host emits Z).
        y = substr(t, 1, 4) + 0
        mo = substr(t, 6, 2) + 0
        d = substr(t, 9, 2) + 0
        h = substr(t, 12, 2) + 0
        mi = substr(t, 15, 2) + 0
        s = substr(t, 18, 2) + 0
        # Strip the fractional part FIRST so position 20 is the zone character
        # in every shape (Z or ±HH:MM, with or without .sss).
        sub(/\.[0-9]+/, "", t)
        off = 0
        if (length(t) >= 25 && (substr(t, 20, 1) == "+" || substr(t, 20, 1) == "-")) {
            sign = (substr(t, 20, 1) == "+") ? 1 : -1
            oh = substr(t, 21, 2) + 0
            om = substr(t, 24, 2) + 0
            off = sign * (oh * 3600 + om * 60)
        }
        yy = y
        mm = mo
        if (mm <= 2) { yy = yy - 1; mm = mm + 12 }
        era = int(yy / 400)
        yoe = yy - era * 400
        doy = int((153 * (mm - 3) + 2) / 5) + d - 1
        doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
        days = era * 146097 + doe - 719468
        return days * 86400 + h * 3600 + mi * 60 + s - off
    }
    function json_num(line, key,  idx, rest) {
        idx = index(line, "\"" key "\":")
        if (idx == 0) return ""
        rest = substr(line, idx + length(key) + 3)
        if (match(rest, /^[ \t]*-?[0-9]+(\.[0-9]+)?/)) return substr(rest, RSTART, RLENGTH)
        return ""
    }
    function classify(name, tail,  cmdtext) {
        if (name ~ /^(read|grep|glob|list|fd|search|view|ls)/) return "search"
        if (name ~ /^(edit|write|apply|multiedit|create|notebook)/) return "edit"
        if (name ~ /^(shell|bash|terminal|exec|run)/) {
            if (match(tail, /"command":"[^"]*/)) {
                cmdtext = substr(tail, RSTART, RLENGTH)
                if (cmdtext ~ /test|jest|vitest|pytest|cargo|make|gradle|mvn|tsc|eslint|ruff|lint|check|audit|compile|build/) return "verify"
                if (cmdtext ~ /grep|rg |fd |find|ls |cat|head|tail|glob|list/) return "search"
                if (cmdtext ~ /sed -i|patch|tee |mkdir|touch|mv |cp |rm |chmod|truncate/) return "edit"
            }
            return "other"
        }
        return "other"
    }
    BEGIN {
        npat = split(pats, P, "|")
    }
    {
        sub(/\r$/, "")
        if (match($0, /"timestamp":"[^"]+"/)) {
            ts = substr($0, RSTART + 13, RLENGTH - 14)
            if (first_ts == "") first_ts = ts
            last_ts = ts
        }
        if ($0 ~ /"type":"session"/ && !seen) {
            seen = 1
            if (match($0, /"id":"[^"]+"/)) session_id = substr($0, RSTART + 6, RLENGTH - 7)
        }
        if ($0 ~ /"meta":\{"source":"user"/) users++
        if ($0 ~ /"type":"tool_result"/) {
            # Failure flags OR across consecutive tool_result lines between
            # assistant turns (parallel tool calls): the next assistant turn is
            # a rework turn when ANY result since the previous assistant turn
            # failed.
            is_fail = 0
            for (i = 1; i <= npat; i++) if (index($0, P[i])) { is_fail = 1; break }
            if (is_fail) { loops++; accum_fail = 1 }
        }
        if ($0 ~ /"role":"assistant"/) {
            turn_fail = accum_fail
            accum_fail = 0
            if ($0 ~ /"usage":\{/) {
                uin = json_num($0, "inputTokens")
                uout = json_num($0, "outputTokens")
                ucache = json_num($0, "cacheReadTokens")
                ucost = json_num($0, "costUsd")
                if (uin != "") {
                    if (turn_fail) {
                        rew_in += uin
                        rew_out += (uout == "" ? 0 : uout)
                    } else {
                        s_in += uin
                        s_out += (uout == "" ? 0 : uout)
                    }
                    cache += (ucache == "" ? 0 : ucache)
                    cost += (ucost == "" ? 0 : ucost)
                }
            }
            if (match($0, /"model":"[^"]+"/)) model = substr($0, RSTART + 9, RLENGTH - 10)
            # Tool calls are counted per "type":"tool_use" block, and each
            # block name/command are matched only INSIDE that block — an
            # earlier tool_use without a command can never borrow a later
            # block command (cross-tool tail bleed).
            tmp = $0
            TL = "\"type\":\"tool_use\""
            while ((tlp = index(tmp, TL)) > 0) {
                after = substr(tmp, tlp + length(TL))
                nxt = index(after, TL)
                block = (nxt > 0) ? substr(after, 1, nxt - 1) : after
                if (match(block, /"name":"[^"]+"/)) {
                    nm = substr(block, RSTART + 8, RLENGTH - 9)
                    tool_total++
                    cls = classify(tolower(nm), substr(block, RSTART + RLENGTH))
                    if (cls == "search") tool_search++
                    else if (cls == "edit") tool_edit++
                    else if (cls == "verify") tool_verify++
                    else tool_other++
                }
                tmp = after
            }
        }
    }
    END {
        if (!seen) { print "NO_SESSION"; exit 3 }
        wall = 0
        if (first_ts != "" && last_ts != "") {
            wall = epoch(last_ts) - epoch(first_ts)
            if (wall < 0) wall = 0
        }
        humans = (users > 1) ? users - 1 : 0
        printf "session_id=%s\nmodel=%s\nfirst_ts=%s\nsucc_in=%d\nsucc_out=%d\nrew_in=%d\nrew_out=%d\nloops=%d\ncache=%d\ncost=%.2f\ntool_total=%d\ntool_search=%d\ntool_edit=%d\ntool_verify=%d\ntool_other=%d\nusers=%d\nhumans=%d\nwall=%d\n", session_id, model, first_ts, s_in, s_out, rew_in, rew_out, loops, cache, cost, tool_total, tool_search, tool_edit, tool_verify, tool_other, users, humans, wall
    }' "$TARGET_FILE"
}

set +e
FACTS="$(extract_facts)"
AWK_RC=$?
set -e
if [[ "$AWK_RC" -ne 0 || "$FACTS" == "NO_SESSION" || -z "$FACTS" ]]; then
    printf 'EXTRACT|ERROR|NO_SESSION_LINE|%s\n' "$TARGET_FILE" >&2
    exit 2
fi

# Parse the key=value fact lines without eval: transcript-derived values are
# untrusted, so nothing here may re-enter the shell parser.
declare -A F=()
while IFS= read -r factline; do
    fkey="${factline%%=*}"
    fval="${factline#*=}"
    F[$fkey]="$fval"
done <<< "$FACTS"

session_id="${F[session_id]:-}"
model="${F[model]:-unknown}"
first_ts="${F[first_ts]:-}"
# The record below is emitted via an expanding heredoc, so every emitted string
# field — including the session id when it becomes the scenario_id fallback —
# must be free of shell-expansion and JSON-structure characters before it is
# interpolated.
if [[ -z "$SCENARIO_ID" ]]; then
    SCENARIO_ID="$session_id"
fi
for strval in "$SCENARIO_ID" "$CONDITION" "$model" "$first_ts"; do
    if [[ "$strval" == *[\"\\\$\`]* ]]; then
        printf 'EXTRACT|ERROR|BAD_VALUE|emitted-string-field\n' >&2
        exit 2
    fi
done
succ_in="${F[succ_in]:-0}"
succ_out="${F[succ_out]:-0}"
rew_in="${F[rew_in]:-0}"
rew_out="${F[rew_out]:-0}"
loops="${F[loops]:-0}"
cache="${F[cache]:-0}"
cost="${F[cost]:-0.00}"
tool_total="${F[tool_total]:-0}"
tool_search="${F[tool_search]:-0}"
tool_edit="${F[tool_edit]:-0}"
tool_verify="${F[tool_verify]:-0}"
tool_other="${F[tool_other]:-0}"
humans="${F[humans]:-0}"
wall="${F[wall]:-0}"

tokens_total=$((succ_in + succ_out + rew_in + rew_out))

cat <<EOF
{
  "scenario_id": "$SCENARIO_ID",
  "condition": "$CONDITION",
  "model": "$model",
  "timestamp": "$first_ts",
  "metrics": {
    "tokens_in": $succ_in,
    "tokens_out": $succ_out,
    "tokens_total": $tokens_total,
    "cache_read_tokens": $cache,
    "tool_calls_total": $tool_total,
    "tool_calls_search": $tool_search,
    "tool_calls_edit": $tool_edit,
    "tool_calls_verify": $tool_verify,
    "tool_calls_other": $tool_other,
    "rework_loops": $loops,
    "rework_tokens_in": $rew_in,
    "rework_tokens_out": $rew_out,
    "wall_clock_seconds": $wall,
    "invariants_checked": $INV_CHECKED,
    "invariants_passed": $INV_PASSED,
    "human_interventions": $humans,
    "accepted": $ACCEPTED
  },
  "costs": {
    "transcript_cost_usd": $cost
  }
}
EOF

if [[ "$ACCEPTED" == "false" ]]; then
    printf 'EXTRACT|NOTE|accepted defaulted to false — pass --accepted=true only after human acceptance\n' >&2
fi
printf 'EXTRACT|OK|session=%s|model=%s|tokens_in=%d|tokens_out=%d|rework_loops=%d|tool_calls=%d|wall_clock_seconds=%d\n' \
    "$session_id" "$model" "$succ_in" "$succ_out" "$loops" "$tool_total" "$wall" >&2
