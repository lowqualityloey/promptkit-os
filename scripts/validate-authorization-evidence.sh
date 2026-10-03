#!/usr/bin/env bash
set -uo pipefail

ROOT="."
BASELINE=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --baseline) BASELINE="${2:-}"; shift 2 ;;
        *) echo "Usage: validate-authorization-evidence.sh --baseline <git-ref> [--root PATH]" >&2; exit 2 ;;
    esac
done
if [ -z "$BASELINE" ] || ! git -C "$ROOT" rev-parse --verify "$BASELINE^{commit}" >/dev/null 2>&1; then
    echo "INVALID|AUTHORIZATION_BASELINE|A resolvable --baseline git ref is required"
    exit 2
fi
ROOT="$(cd "$ROOT" && pwd)"
diff_output="$(git -C "$ROOT" diff --unified=0 "$BASELINE" -- docs/tasks 2>&1)"
if [ "$?" -ne 0 ]; then echo "INVALID|AUTHORIZATION_DIFF|Unable to compare docs/tasks with the declared baseline"; exit 2; fi
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
    checkpoint="$(grep -RFl "<a id=\"$id\"></a>" "$ROOT/docs/tasks" --include='*.md' | head -n1 || true)"
    if [ -z "$checkpoint" ]; then
        echo "UNRESOLVED_AUTHORIZATION|${record:-docs/tasks}|Checkpoint $id does not resolve in a Task Record"
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
    boundary="$(printf '%s\n' "$section" | sed -n 's/.*\*\*Declared Boundary\*\*:[[:space:]]*`\([^`]*\)`.*/\1/p' | head -n1)"
    if [[ ! "$boundary" =~ ^(review|pr|full)$ ]]; then echo "INVALID_AUTHORIZATION_BOUNDARY|$record|Checkpoint $id must declare review, pr, or full"; errors=$((errors + 1)); fi
    mode="$(grep -E '^-[[:space:]]+\*\*Mode\*\*:' "$ROOT/$record" | tail -n1 | grep -oE 'Approved Batch Mode' || true)"
    if [ -n "$mode" ]; then
        batch="$(grep -E '^-[[:space:]]+\*\*Batch Authorization\*\*:' "$ROOT/$record" | tail -n1 | grep -oE '`[^`]+`' | tr -d '`' || true)"
        if [ -z "$batch" ] || [ ! -f "$ROOT/$batch" ]; then
            echo "MISSING_BATCH_AUTHORIZATION|$record|Approved Batch Mode link does not resolve"
            errors=$((errors + 1))
        else
            for field in 'Declared Boundary' 'Permitted Actions' 'Milestone Scope'; do
                if ! grep -Eq "^[-*]?[[:space:]]*\\*\\*$field\\*\\*:[[:space:]]*[^[]" "$ROOT/$batch"; then
                    echo "MISSING_BATCH_AUTHORIZATION|$record|Batch Authorization lacks $field"
                    errors=$((errors + 1))
                fi
            done
            checkpoint_boundary="$boundary"
            batch_boundary="$(grep -E '^[-*]?[[:space:]]*\*\*Declared Boundary\*\*:' "$ROOT/$batch" | sed -n 's/.*`\([^`]*\)`.*/\1/p' | head -n1)"
            if [ -n "$checkpoint_boundary" ] && [ -n "$batch_boundary" ] && [ "$checkpoint_boundary" != "$batch_boundary" ]; then
                echo "CONFLICTING_AUTHORIZATION|$record|Run boundary '$checkpoint_boundary' conflicts with batch boundary '$batch_boundary'"
                errors=$((errors + 1))
            fi
        fi
    fi
done <<< "$diff_output"
changed_records="$(git -C "$ROOT" diff --name-only "$BASELINE" -- docs/tasks)"
untracked_records="$(git -C "$ROOT" ls-files --others --exclude-standard -- docs/tasks)"
for candidate in $changed_records $untracked_records; do
    [ -f "$ROOT/$candidate" ] || continue
    candidate_diff="$(git -C "$ROOT" diff --unified=0 "$BASELINE" -- "$candidate")"
    if printf '%s\n' "$untracked_records" | grep -Fxq "$candidate"; then
        candidate_diff="$(sed 's/^/+/g' "$ROOT/$candidate")"
    fi
    if [ -n "$(grep -E '^-[[:space:]]+\*\*Mode\*\*:' "$ROOT/$candidate" | grep -F 'Approved Batch Mode' || true)" ] && [ -n "$(grep -E '^\+[^+][[:space:]]+\*\*(Mode|Batch Authorization)\*\*:' <<< "$candidate_diff" | head -n1)" ]; then
            batch="$(grep -E '^-[[:space:]]+\*\*Batch Authorization\*\*:' "$ROOT/$candidate" | tail -n1 | grep -oE '`[^`]+`' | tr -d '`' || true)"
            if [ -z "$batch" ] || [ ! -f "$ROOT/$batch" ]; then
                echo "MISSING_BATCH_AUTHORIZATION|$candidate|Approved Batch Mode link does not resolve"
                errors=$((errors + 1))
            else
                for field in 'Declared Boundary' 'Permitted Actions' 'Milestone Scope'; do
                    if ! grep -Eq "^[-*]?[[:space:]]*\\*\\*$field\\*\\*:[[:space:]]*[^[]" "$ROOT/$batch"; then
                        echo "MISSING_BATCH_AUTHORIZATION|$candidate|Batch Authorization lacks $field"
                        errors=$((errors + 1))
                    fi
                done
            fi
    fi
done
if [ "$errors" -eq 0 ]; then echo "VALID|AUTHORIZATION_EVIDENCE=COMPLETE"; exit 0; fi
echo "FAILED|AUTHORIZATION_ERRORS=$errors"
exit 1
