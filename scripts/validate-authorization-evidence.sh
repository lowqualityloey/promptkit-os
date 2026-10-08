#!/usr/bin/env bash
set -uo pipefail

ROOT="."
BASELINE=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then echo "Usage: validate-authorization-evidence.sh --baseline <git-ref> [--root PATH]" >&2; exit 2; fi
            ROOT="$2"; shift 2 ;;
        --baseline)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then echo "Usage: validate-authorization-evidence.sh --baseline <git-ref> [--root PATH]" >&2; exit 2; fi
            BASELINE="$2"; shift 2 ;;
        *) echo "Usage: validate-authorization-evidence.sh --baseline <git-ref> [--root PATH]" >&2; exit 2 ;;
    esac
done
if [ -z "$BASELINE" ] || ! git -C "$ROOT" rev-parse --verify "$BASELINE^{commit}" >/dev/null 2>&1; then
    echo "INVALID|AUTHORIZATION_BASELINE|A resolvable --baseline git ref is required"
    exit 2
fi
ROOT="$(cd "$ROOT" && pwd)"
resolve_batch_authorization() {
    local reference="$1" resolved task_root current component
    local -a components
    [[ "$reference" == docs/tasks/* ]] || return 1
    [[ "$reference" != *\\* && ! "$reference" =~ (^|/)\.\.?(/|$) ]] || return 1
    current="$ROOT"
    IFS='/' read -r -a components <<< "$reference"
    for component in "${components[@]}"; do
        current+="/$component"
        [[ ! -L "$current" ]] || return 1
    done
    resolved="$(realpath -e -- "$ROOT/$reference" 2>/dev/null)" || return 1
    task_root="$(realpath -e -- "$ROOT/docs/tasks" 2>/dev/null)" || return 1
    [[ -f "$resolved" && "$resolved" == "$task_root/"* ]] || return 1
    printf '%s\n' "$resolved"
}
meaningful_batch_field() {
    local file="$1" field="$2" line value normalized
    line="$(grep -E "^[-*]?[[:space:]]*\*\*$field\*\*:" "$file" | head -n1 || true)"
    value="${line#*:}"
    value="$(printf '%s' "$value" | tr -d '`' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
    [ -n "$normalized" ] && [[ ! "$normalized" =~ ^(n/?a|none|null|tbd|todo|not[[:space:]]+applicable|\[\])$ ]]
}
if ! diff_output="$(git -C "$ROOT" diff --unified=0 "$BASELINE" -- docs/tasks 2>&1)"; then
    echo "INVALID|AUTHORIZATION_DIFF|Unable to compare docs/tasks with the declared baseline"
    exit 2
fi
while IFS= read -r untracked; do
    [ -z "$untracked" ] && continue
    diff_output+=$'\n+++ b/'"$untracked"
    while IFS= read -r added_line || [ -n "$added_line" ]; do diff_output+=$'\n+'"$added_line"; done < "$ROOT/$untracked"
done < <(git -C "$ROOT" ls-files --others --exclude-standard -- docs/tasks)
errors=0
record=""
while IFS= read -r line; do
    if [[ "$line" == '+++ b/docs/tasks/'* ]]; then record="${line#+++ b/}"; continue; fi
    [[ "$line" != +* ]] && continue
    [[ "$line" == +++* ]] && continue
    [[ "$line" == *'Commit Evidence Entry'* ]] || continue
    id="$(printf '%s' "$line" | grep -oE 'AUTHZ-[A-Za-z0-9._-]+' | head -n1 || true)"
    source="$(printf '%s' "$line" | sed -n 's/.*Authorization Source:[[:space:]]*//p' | sed 's/[;}`].*$//' | tr -d '[:space:]')"
    if [ -z "$id" ] || [ -z "$source" ] || [[ "$source" == \[* ]]; then
        echo "MISSING_AUTHORIZATION|${record:-docs/tasks}|New Commit Evidence Entry must cite an AUTHZ checkpoint and Authorization Source"
        errors=$((errors + 1))
        continue
    fi
    checkpoint="$ROOT/${record:-}"
    if [ -z "$record" ] || [ ! -f "$checkpoint" ] || ! grep -Fq "<a id=\"$id\"></a>" "$checkpoint"; then
        echo "UNRESOLVED_AUTHORIZATION|${record:-docs/tasks}|Checkpoint $id does not resolve in the cited Task Record"
        errors=$((errors + 1))
        continue
    fi
    section="$(awk -v anchor="<a id=\"$id\"></a>" 'index($0,anchor){on=1;next} on && /<a id=/{exit} on{print}' "$checkpoint")"
    for field in 'Declared Boundary' 'Verbatim Human Instruction' 'Instruction Source' 'Frozen Task and Milestone Scope'; do
        value="$(printf '%s\n' "$section" | sed -n "s/.*\\*\\*$field\\*\\*:[[:space:]]*//p" | head -n1 | tr -d '`' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if [ -z "$value" ] || [[ "$value" == \[* ]] || [ "$value" = "N/A" ] || [ "$value" = "None" ]; then
            echo "MISSING_AUTHORIZATION|$record|Checkpoint $id lacks $field"
            errors=$((errors + 1))
        fi
    done
    boundary="$(printf '%s\n' "$section" | sed -n "s/.*\\*\\*Declared Boundary\\*\\*:[[:space:]]*\`\\([^\`]*\\)\`.*/\\1/p" | head -n1)"
    if [[ ! "$boundary" =~ ^(review|pr|full)$ ]]; then echo "INVALID_AUTHORIZATION_BOUNDARY|$record|Checkpoint $id must declare review, pr, or full"; errors=$((errors + 1)); fi
    mode="$(grep -E '^-[[:space:]]+\*\*Mode\*\*:' "$ROOT/$record" | tail -n1 | grep -oE 'Approved Batch Mode' || true)"
    if [ -n "$mode" ]; then
        batch="$(grep -E '^-[[:space:]]+\*\*Batch Authorization\*\*:' "$ROOT/$record" | tail -n1 | grep -oE "\`[^\`]+\`" | tr -d '`' || true)"
        batch_file="$(resolve_batch_authorization "$batch" || true)"
        if [ -z "$batch_file" ]; then
            echo "MISSING_BATCH_AUTHORIZATION|$record|Approved Batch Mode link does not resolve"
            errors=$((errors + 1))
        else
            for field in 'Declared Boundary' 'Permitted Actions' 'Milestone Scope'; do
                if ! meaningful_batch_field "$batch_file" "$field"; then
                    echo "MISSING_BATCH_AUTHORIZATION|$record|Batch Authorization lacks a meaningful $field"
                    errors=$((errors + 1))
                fi
            done
            checkpoint_boundary="$boundary"
            batch_boundary="$(grep -E '^[-*]?[[:space:]]*\*\*Declared Boundary\*\*:' "$batch_file" | sed -nE "s/.*\`(review|pr|full)\`[[:space:]]*\$/\\1/p" | head -n1)"
            if [ -z "$batch_boundary" ]; then
                echo "INVALID_AUTHORIZATION_BOUNDARY|$record|Batch Authorization must declare review, pr, or full in backticks"
                errors=$((errors + 1))
            elif [ -n "$checkpoint_boundary" ] && [ "$checkpoint_boundary" != "$batch_boundary" ]; then
                echo "CONFLICTING_AUTHORIZATION|$record|Run boundary '$checkpoint_boundary' conflicts with batch boundary '$batch_boundary'"
                errors=$((errors + 1))
            fi
        fi
    fi
done <<< "$diff_output"
validate_changed_batch_record() {
    local candidate="$1" source="$2" candidate_diff batch batch_file batch_boundary checkpoint_boundary field
    [ -f "$ROOT/$candidate" ] || return 0
    candidate_diff="$(git -C "$ROOT" diff --unified=0 "$BASELINE" -- "$candidate")"
    if [ "$source" = untracked ]; then
        candidate_diff="$(sed 's/^/+/g' "$ROOT/$candidate")"
    fi
    if [ -n "$(grep -E '^-[[:space:]]+\*\*Mode\*\*:' "$ROOT/$candidate" | grep -F 'Approved Batch Mode' || true)" ] && [ -n "$(grep -E '^\+[^+][[:space:]]+\*\*(Mode|Batch Authorization)\*\*:' <<< "$candidate_diff" | head -n1)" ]; then
            batch="$(grep -E '^-[[:space:]]+\*\*Batch Authorization\*\*:' "$ROOT/$candidate" | tail -n1 | grep -oE "\`[^\`]+\`" | tr -d '`' || true)"
            batch_file="$(resolve_batch_authorization "$batch" || true)"
            if [ -z "$batch_file" ]; then
                echo "MISSING_BATCH_AUTHORIZATION|$candidate|Approved Batch Mode link does not resolve"
                errors=$((errors + 1))
            else
                for field in 'Declared Boundary' 'Permitted Actions' 'Milestone Scope'; do
                    if ! meaningful_batch_field "$batch_file" "$field"; then
                        echo "MISSING_BATCH_AUTHORIZATION|$candidate|Batch Authorization lacks a meaningful $field"
                        errors=$((errors + 1))
                    fi
                done
                batch_boundary="$(grep -E '^[-*]?[[:space:]]*\*\*Declared Boundary\*\*:' "$batch_file" | sed -nE "s/.*\`(review|pr|full)\`[[:space:]]*\$/\\1/p" | head -n1)"
                checkpoint_boundary="$(grep -E '^-[[:space:]]+\*\*Declared Boundary\*\*:' "$ROOT/$candidate" | sed -nE "s/.*\`(review|pr|full)\`[[:space:]]*\$/\\1/p" | head -n1)"
                if [ -z "$batch_boundary" ]; then
                    echo "INVALID_AUTHORIZATION_BOUNDARY|$candidate|Batch Authorization must declare review, pr, or full in backticks"
                    errors=$((errors + 1))
                elif [ -z "$checkpoint_boundary" ]; then
                    echo "INVALID_AUTHORIZATION_BOUNDARY|$candidate|Task Record must declare review, pr, or full in backticks"
                    errors=$((errors + 1))
                elif [ "$checkpoint_boundary" != "$batch_boundary" ]; then
                    echo "CONFLICTING_AUTHORIZATION|$candidate|Run boundary '$checkpoint_boundary' conflicts with batch boundary '$batch_boundary'"
                    errors=$((errors + 1))
                fi
            fi
    fi
}
while IFS= read -r -d '' candidate; do validate_changed_batch_record "$candidate" tracked; done < <(git -C "$ROOT" diff --name-only -z "$BASELINE" -- docs/tasks)
while IFS= read -r -d '' candidate; do validate_changed_batch_record "$candidate" untracked; done < <(git -C "$ROOT" ls-files --others --exclude-standard -z -- docs/tasks)
if [ "$errors" -eq 0 ]; then echo "VALID|AUTHORIZATION_EVIDENCE=COMPLETE"; exit 0; fi
echo "FAILED|AUTHORIZATION_ERRORS=$errors"
exit 1
