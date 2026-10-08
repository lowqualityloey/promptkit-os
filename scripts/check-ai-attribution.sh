#!/usr/bin/env bash
# check-ai-attribution.sh — repository-level AI attribution policy check (read-only).
#
# Reads the optional `ai-attribution: off|host-default` preference from
# PROMPTKIT.md. `off` scans a prepared payload and fails on an unsolicited AI
# signature; a missing line or `host-default` skips without newly blocking.
#
# The payload is a commit message (--message-file), a prepared PR/issue body
# (--body-file), or stdin (--stdin). Read-only by construction: it never stages,
# commits, amends, rewrites history, or edits the payload.
#
# Exit codes: 0 clean or skipped; 1 prohibited signature found; 2 incomplete
# (unreadable/malformed rules file, bad preference value, or unreadable payload).

set -uo pipefail
export LC_ALL=C

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || exit 2

root="."
rules_file=""
preference_file=""
payload_file=""
use_stdin=0
payload_source=""
tmp_payload=""

cleanup() { [[ -n "$tmp_payload" ]] && rm -f -- "$tmp_payload"; }
trap cleanup EXIT

usage() {
    cat >&2 <<'EOF'
Usage: scripts/check-ai-attribution.sh [--root PATH] [--rules-file PATH]
       (--message-file PATH | --body-file PATH | --stdin)
EOF
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --root) [[ "$#" -ge 2 ]] || { usage; exit 2; }; root="$2"; shift 2 ;;
        --root=*) root="${1#*=}"; shift ;;
        --rules-file) [[ "$#" -ge 2 ]] || { usage; exit 2; }; rules_file="$2"; shift 2 ;;
        --rules-file=*) rules_file="${1#*=}"; shift ;;
        --preference-file) [[ "$#" -ge 2 ]] || { usage; exit 2; }; preference_file="$2"; shift 2 ;;
        --preference-file=*) preference_file="${1#*=}"; shift ;;
        --message-file) [[ "$#" -ge 2 ]] || { usage; exit 2; }; payload_file="$2"; shift 2 ;;
        --message-file=*) payload_file="${1#*=}"; shift ;;
        --body-file) [[ "$#" -ge 2 ]] || { usage; exit 2; }; payload_file="$2"; shift 2 ;;
        --body-file=*) payload_file="${1#*=}"; shift ;;
        --stdin) use_stdin=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 2 ;;
    esac
done

[[ -n "$rules_file" ]] || rules_file="$script_dir/ai-attribution-patterns.txt"
[[ -n "$preference_file" ]] || preference_file="$root/PROMPTKIT.md"

sanitize() { printf '%s' "$1" | tr '\r\n|' '   '; }

# Preference: absent, unknown, or unreadable resolves to host-default (never
# newly blocking). Only `off` enforces; an unparseable value fails closed.
preference="host-default"
if [[ -f "$preference_file" && -r "$preference_file" ]]; then
    pref_line="$(grep -E '^[[:space:]]*ai-attribution:' "$preference_file" 2>/dev/null | tail -n 1 || true)"
    if [[ -n "$pref_line" ]]; then
        pref_value="$(printf '%s' "$pref_line" | sed -E 's/^[[:space:]]*ai-attribution:[[:space:]]*//; s/[[:space:]].*$//')"
        case "$pref_value" in
            off) preference="off" ;;
            host-default|'') preference="host-default" ;;
            *) printf 'AI_ATTRIBUTION|INCOMPLETE|preference|%s\n' "$(sanitize "$pref_value")"; exit 2 ;;
        esac
    fi
fi

if [[ "$preference" != "off" ]]; then
    printf 'AI_ATTRIBUTION|SKIP|host-default|%s\n' "$(sanitize "$preference_file")"
    exit 0
fi

if [[ ! -f "$rules_file" || ! -r "$rules_file" ]]; then
    printf 'AI_ATTRIBUTION|INCOMPLETE|RULES|%s\n' "$(sanitize "$rules_file")"
    exit 2
fi

# Resolve the payload to an on-disk file and scan it in place. Multi-megabyte
# payloads must not round-trip through a shell variable piped into `grep -q`:
# when grep matches early it exits, the writer takes SIGPIPE, and `pipefail`
# reports the pipeline as a failed (non-)match. `--stdin` is spilled to a temp
# file for the same reason.
if [[ "$use_stdin" -eq 1 ]]; then
    tmp_payload="$(mktemp "${TMPDIR:-/tmp}/ai-attribution-payload.XXXXXX" 2>/dev/null)" || {
        printf 'AI_ATTRIBUTION|INCOMPLETE|PAYLOAD|%s\n' "$(sanitize "$payload_file")"
        exit 2
    }
    if ! cat > "$tmp_payload"; then
        printf 'AI_ATTRIBUTION|INCOMPLETE|PAYLOAD|%s\n' "$(sanitize "$payload_file")"
        exit 2
    fi
    payload_source="$tmp_payload"
elif [[ -n "$payload_file" ]]; then
    if [[ ! -e "$payload_file" ]]; then
        printf 'AI_ATTRIBUTION|INCOMPLETE|PAYLOAD|%s\n' "$(sanitize "$payload_file")"
        exit 2
    fi
    if [[ ! -f "$payload_file" || ! -r "$payload_file" ]]; then
        printf 'AI_ATTRIBUTION|INCOMPLETE|PAYLOAD|%s\n' "$(sanitize "$payload_file")"
        exit 2
    fi
    payload_source="$payload_file"
else
    usage
    exit 2
fi

rules_files=("$rules_file")
if [[ -n "${PROMPTKIT_AI_ATTRIBUTION_RULES_EXTRA:-}" ]]; then
    for extra in ${PROMPTKIT_AI_ATTRIBUTION_RULES_EXTRA}; do
        [[ -n "$extra" ]] && rules_files+=("$extra")
    done
fi

matched_rule=""
matched_line=""
for rf in "${rules_files[@]}"; do
    if [[ ! -f "$rf" || ! -r "$rf" ]]; then
        printf 'AI_ATTRIBUTION|INCOMPLETE|RULES|%s\n' "$(sanitize "$rf")"
        exit 2
    fi
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        raw=${raw%$'\r'}
        [[ -z "${raw//[[:space:]]/}" ]] && continue
        [[ "$raw" == '#'* ]] && continue
        if [[ "$(printf '%s' "$raw" | tr -cd '|' | wc -c | tr -d ' ')" -ne 2 ]]; then
            printf 'AI_ATTRIBUTION|INCOMPLETE|RULES|%s\n' "$(sanitize "$raw")"
            exit 2
        fi
        rule_id="${raw%%|*}"
        rest="${raw#*|}"
        rule_regex="${rest%%|*}"
        rule_tier="${rest##*|}"
        if [[ -z "$rule_id" || -z "$rule_regex" || -z "$rule_tier" ]]; then
            printf 'AI_ATTRIBUTION|INCOMPLETE|RULES|%s\n' "$(sanitize "$raw")"
            exit 2
        fi
        # grep 0 = match, 1 = no match (continue), >=2 = invalid regex or read
        # error -> fail closed instead of mistaking the error for no match.
        match_line="$(grep -Enm 1 -- "$rule_regex" "$payload_source" 2>/dev/null)"
        grep_status=$?
        if [[ "$grep_status" -eq 0 ]]; then
            matched_rule="$rule_id"
            matched_tier="$rule_tier"
            matched_line="$match_line"
            break 2
        elif [[ "$grep_status" -ge 2 ]]; then
            printf 'AI_ATTRIBUTION|INCOMPLETE|RULES|%s\n' "$(sanitize "$raw")"
            exit 2
        fi
    done < "$rf"
done

if [[ -n "$matched_rule" ]]; then
    printf 'AI_ATTRIBUTION|PROHIBITED|%s|%s|%s\n' "$matched_rule" "$matched_tier" "$(sanitize "$matched_line")"
    printf 'AI_ATTRIBUTION|REMEDIATION|Remove or rewrite the matched AI signature; keep legitimate human co-authors and required notices (scripts/ai-attribution-patterns.txt)\n'
    exit 1
fi

printf 'AI_ATTRIBUTION|OK|%s\n' "$(sanitize "$payload_file")"
exit 0
