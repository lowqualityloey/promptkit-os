#!/usr/bin/env bash
# Cross-platform fixture harness for the onboarding host-documentation divergence
# contract (Issue #644).
# Run from repository root: bash scripts/tests/run-onboard-divergence-fixtures.sh
#
# Enforcement honesty: onboarding is a Markdown workflow, not an executable
# artifact generator. This harness validates the SPECIFIED sample output of the
# divergence contract and its integrity properties. It does not execute an
# onboarding engine, because none exists, and it cannot prove that a live model
# detects every semantic contradiction between a confirmed decision and a
# pre-existing project document.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/onboard-divergence"
TEMP_BASE="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/promptkit-onboard-divergence.XXXXXX")"

cleanup() { rm -rf "$TEMP_ROOT"; }
trap cleanup EXIT
fail() { echo "HARNESS_FAILURE|$1" >&2; exit 1; }

PRECEDENCE_PATTERN='overrid(e|es|ing)|takes precedence|prevail(s|ed)?|supersed(e|es|ing)|precedence|wins over|takes priority over'
HOST_DOC_PATTERN='ARCHITECTURE[.]md|ROADMAP[.]md|RUNBOOK[.]md|OPERATIONS[.]md|STYLE[.]md|STYLEGUIDE[.]md|host document|host-document|host documentation|project document|root document|root documentation'
SOURCE_PATTERN='DIVERGENCE-|DECISION-|policy:|docs/specs/'
ALLOWED_PRECEDENCE='host-doc-authority|decision-authority|unresolved'
EXPECTED_COLUMNS=8

snapshot_files() {
    local output_file="$1"
    : > "$output_file"
    while IFS= read -r file; do printf '%s|' "${file#"$REPO_ROOT"/}" >> "$output_file"; sha256sum "$file" >> "$output_file"; done < <(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type f -print | sort)
}

snapshot_status() { git -C "$REPO_ROOT" status --porcelain=v1 --untracked-files=all > "$1" || fail "Unable to read Git status"; }

assert_unchanged() {
    local before_files="$1" before_status="$2" label="$3" after_files after_status
    after_files="$TEMP_ROOT/$label-after-files"; after_status="$TEMP_ROOT/$label-after-status"
    snapshot_files "$after_files"; snapshot_status "$after_status"
    cmp -s "$before_files" "$after_files" || fail "Repository file hashes changed during $label validation"
    cmp -s "$before_status" "$after_status" || fail "Git status changed during $label validation"
}

assert_diagnostics() {
    local output="$1" expected="$2" actual normalized_expected
    actual="$(grep -vE '^(VALID|FAILED)[|]' "$output" || true)"
    if [ "$expected" = '-' ]; then
        [ -z "$actual" ] || { cat "$output" >&2; fail "Unexpected diagnostics in valid case"; }
        return
    fi
    actual="$(printf '%s\n' "$actual" | LC_ALL=C sort -f)"
    normalized_expected="$(printf '%s\n' "$expected" | sed 's/;;/\n/g' | LC_ALL=C sort -f)"
    [ "$actual" = "$normalized_expected" ] || { cat "$output" >&2; fail "Complete normalized diagnostic set did not match the shared contract"; }
}

# Split one markdown table row into trimmed cells (one cell per line).
split_row() {
    printf '%s\n' "$1" | awk -F'|' '{
        for (i = 2; i <= NF - 1; i++) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i);
            print $i;
        }
    }'
}

# Print the body of a markdown section with the given heading text.
section_body() {
    awk -v heading="$2" '
        $0 ~ "^#+[[:space:]]+" heading "[[:space:]]*$" { inside = 1; next }
        inside && /^#[[:space:]]/ { exit }
        inside { print }
    ' "$1"
}

# Flag a generated artifact line that claims precedence over a pre-existing
# project document without any traceable source reference.
scan_artifact() {
    local file="$1" rel="$2" line
    while IFS= read -r line; do
        [[ "$line" =~ $PRECEDENCE_PATTERN ]] || continue
        [[ "$line" =~ $HOST_DOC_PATTERN ]] || continue
        [[ "$line" =~ $SOURCE_PATTERN ]] && continue
        echo "UNTRACEABLE_PRECEDENCE_CLAIM|$rel|$line"
    done < "$file"
}

# Print the precedence value the generated PROMPTKIT.md states, if any.
profile_precedence() {
    local profile="$1" line
    line="$(grep -F 'Dispatch Precedence' "$profile" | head -n 1 || true)"
    [ -n "$line" ] || return 0
    printf '%s\n' "$line" | tr '`' '\n' | sed -n '2p'
}

# Validate one divergence row and print its diagnostics.
validate_row() {
    local row="$1" row_index="$2" project_root="$3" intake="$4" profile="$5"
    local cells_file="$TEMP_ROOT/cells.txt"
    split_row "$row" > "$cells_file"
    local cell_count
    cell_count="$(wc -l < "$cells_file" | tr -d ' ')"
    if [ "$cell_count" -ne "$EXPECTED_COLUMNS" ]; then
        echo "ROW_COLUMN_COUNT|row $row_index has $cell_count columns, expected $EXPECTED_COLUMNS"
        return
    fi
    local divergence_id document line decision_id precedence designated_by owner next_action
    divergence_id="$(sed -n '1p' "$cells_file")"
    document="$(sed -n '2p' "$cells_file")"
    line="$(sed -n '3p' "$cells_file")"
    decision_id="$(sed -n '4p' "$cells_file")"
    precedence="$(sed -n '5p' "$cells_file")"
    designated_by="$(sed -n '6p' "$cells_file")"
    owner="$(sed -n '7p' "$cells_file")"
    next_action="$(sed -n '8p' "$cells_file")"

    local index=1 field
    while IFS= read -r field; do
        [ -n "$field" ] || continue
        if [ -z "$(sed -n "${index}p" "$cells_file")" ]; then
            echo "EMPTY_FIELD|row $row_index field $field is empty"
        fi
        index=$((index + 1))
    done <<'FIELDS'
Divergence ID
Document
Line
Decision ID
Precedence
Designated By
Owner
Next Action
FIELDS

    [[ "$divergence_id" =~ ^DIVERGENCE-[a-z0-9-]+-[0-9]{3}$ ]] || echo "INVALID_DIVERGENCE_ID|row $row_index has an invalid Divergence ID '$divergence_id'"
    [[ "$decision_id" =~ ^DECISION-[a-z0-9-]+-[0-9]{3}$ ]] || echo "INVALID_DECISION_ID|row $row_index has an invalid Decision ID '$decision_id'"

    local doc_path="$project_root/$document"
    if [ ! -f "$doc_path" ]; then
        echo "DOCUMENT_NOT_FOUND|row $row_index references '$document', which does not exist in the project"
    elif [[ ! "$line" =~ ^[0-9]+$ ]]; then
        echo "LINE_INVALID|row $row_index line '$line' is not a positive integer"
    else
        local total anchored
        total="$(wc -l < "$doc_path" | tr -d ' ')"
        if [ "$line" -lt 1 ] || [ "$line" -gt "$total" ]; then
            echo "LINE_OUT_OF_RANGE|row $row_index line $line is outside '$document' (1-$total)"
        else
            anchored="$(sed -n "${line}p" "$doc_path")"
            if [ -z "$anchored" ]; then
                echo "LINE_BLANK|row $row_index line $line of '$document' is blank"
            fi
        fi
    fi

    local confirmed=0 intake_line
    while IFS= read -r intake_line; do
        if [[ "$intake_line" == *"$decision_id"* ]] && [[ "${intake_line,,}" == *confirmed* ]]; then confirmed=1; break; fi
    done < "$intake"
    [ "$confirmed" -eq 1 ] || echo "DECISION_NOT_CONFIRMED|row $row_index Decision ID '$decision_id' has no confirmed decision in the Intake Record"

    local precedence_ok=1
    if [[ ! "$precedence" =~ ^(${ALLOWED_PRECEDENCE})$ ]]; then
        echo "PRECEDENCE_NOT_IN_ENUM|row $row_index precedence '$precedence' is outside the allowed set"
        precedence_ok=0
    fi

    if [ "$precedence" = 'unresolved' ]; then
        if [ "$designated_by" != 'not designated' ]; then
            echo "DESIGNATION_WITHOUT_PRECEDENCE|row $row_index names a designator while the precedence stays 'unresolved'"
            precedence_ok=0
        fi
    else
        if [ "$designated_by" = 'not designated' ] || [[ ! "$designated_by" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]] || [[ "$designated_by" != *docs/specs/* ]]; then
            echo "MISSING_HUMAN_DESIGNATION|row $row_index precedence $precedence has no explicit human designation (approver, date, record path)"
            precedence_ok=0
        fi
    fi

    if [ -f "$profile" ]; then
        if ! grep -Fq "$divergence_id" "$profile"; then
            echo "PROFILE_POINTER_MISSING|the generated PROMPTKIT.md does not reference the divergence row '$divergence_id'"
        fi
        local profile_precedence_value
        profile_precedence_value="$(profile_precedence "$profile")"
        if [ -n "$profile_precedence_value" ]; then
            if [ "$profile_precedence_value" != "$precedence" ]; then
                echo "PROFILE_PRECEDENCE_MISMATCH|row $row_index records precedence '$precedence' but the generated PROMPTKIT.md states '$profile_precedence_value'"
            fi
        elif [ "$precedence_ok" -eq 1 ]; then
            echo "PROFILE_PRECEDENCE_MISSING|row $row_index records precedence '$precedence' but the generated PROMPTKIT.md states no precedence"
        fi
        if [ "$precedence_ok" -eq 1 ] && [ "$precedence" != 'unresolved' ]; then
            local next_action_lower="${next_action,,}"
            if [[ "$next_action_lower" == *"record"* ]] && [[ "$next_action_lower" == *"designation"* ]]; then
                echo "NEXT_ACTION_REASKS_DESIGNATION|row $row_index asks to record a precedence designation although '$designated_by' already designated one"
            fi
        fi
    fi
}

# Validate one fixture case; print diagnostics and the summary line.
validate_case() {
    local case_root="$1" expected_rows="$2"
    local project_root="$case_root/project"
    local output_root="$case_root/expected-output"
    local errors=0 rows=0 host_unchanged=1
    local intake="" intake_count=0 candidate

    for candidate in "$output_root"/docs/specs/*.md; do
        [ -f "$candidate" ] || continue
        intake_count=$((intake_count + 1))
        [ "$intake_count" -eq 1 ] && intake="$candidate"
    done
    if [ "$intake_count" -eq 0 ]; then
        echo "MISSING_INTAKE_RECORD|the fixture has no Intake Record under expected-output/docs/specs"
        errors=$((errors + 1))
    elif [ "$intake_count" -gt 1 ]; then
        echo "MULTIPLE_INTAKE_RECORDS|the fixture has more than one Intake Record under expected-output/docs/specs"
        errors=$((errors + 1))
    fi

    local profile="$output_root/PROMPTKIT.md"
    local state="$output_root/docs/STATE.md"
    if [ ! -f "$profile" ]; then
        echo "MISSING_PROFILE|the fixture has no generated PROMPTKIT.md"
        errors=$((errors + 1))
    fi
    if [ ! -f "$state" ]; then
        echo "MISSING_STATE|the fixture has no generated docs/STATE.md"
        errors=$((errors + 1))
    elif grep -q 'DIVERGENCE-' "$state"; then
        echo "STATE_DIVERGENCE_ROW|the generated docs/STATE.md references a divergence row instead of the Intake Record"
        errors=$((errors + 1))
    fi

    if [ -n "$intake" ]; then
        local section_file="$TEMP_ROOT/section.txt"
        section_body "$intake" "Host Documentation Divergence" > "$section_file"
        if ! grep -q 'Divergence ID' "$section_file"; then
            echo "MISSING_DIVERGENCE_TABLE|the Intake Record has no Host Documentation Divergence table"
            errors=$((errors + 1))
        fi
        local rows_file="$TEMP_ROOT/rows.txt"
        grep -E '^[|]' "$section_file" | grep -vE '^[|][[:space:]]*[-:][-:|[:space:]]*$' | grep -v 'Divergence ID' > "$rows_file" || true
        rows="$(wc -l < "$rows_file" | tr -d ' ')"
        if [ "$rows" -ne "$expected_rows" ]; then
            echo "ROW_COUNT_MISMATCH|expected $expected_rows divergence row(s), found $rows"
            errors=$((errors + 1))
        fi
        local row_index=0 row
        while IFS= read -r row; do
            [ -n "$row" ] || continue
            row_index=$((row_index + 1))
            validate_row "$row" "$row_index" "$project_root" "$intake" "$profile" > "$TEMP_ROOT/row-diagnostics.txt"
            local diag
            while IFS= read -r diag; do
                [ -n "$diag" ] || continue
                echo "$diag"
                errors=$((errors + 1))
            done < "$TEMP_ROOT/row-diagnostics.txt"
        done < "$rows_file"

        local record_name
        record_name="$(basename "$intake")"
        if [ -f "$profile" ] && ! grep -Fq "$record_name" "$profile"; then
            echo "PROFILE_POINTER_MISSING|the generated PROMPTKIT.md does not reference the Intake Record '$record_name'"
            errors=$((errors + 1))
        fi
    fi

    local artifact
    while IFS= read -r artifact; do
        [ -n "$artifact" ] || continue
        scan_artifact "$artifact" "${artifact#"$output_root"/}" > "$TEMP_ROOT/scan-diagnostics.txt"
        local diag
        while IFS= read -r diag; do
            [ -n "$diag" ] || continue
            echo "$diag"
            errors=$((errors + 1))
        done < "$TEMP_ROOT/scan-diagnostics.txt"
    done < <(find "$output_root" -type f -name '*.md' | grep -v '/docs/specs/' | sort)

    local host_before="$TEMP_ROOT/host-before.txt"
    : > "$host_before"
    local host_file rel
    while IFS= read -r host_file; do
        printf '%s|%s\n' "${host_file#"$project_root"/}" "$(sha256sum "$host_file" | cut -d' ' -f1)" >> "$host_before"
    done < <(find "$project_root" -type f | sort)

    local write_file
    while IFS= read -r write_file; do
        rel="${write_file#"$output_root"/}"
        if [ -f "$project_root/$rel" ]; then
            echo "HOST_DOCUMENT_IN_WRITE_SET|the onboarding write set contains the pre-existing project document '$rel'"
            errors=$((errors + 1))
        fi
    done < <(find "$output_root" -type f | sort)

    local sim="$TEMP_ROOT/simulated-project"
    rm -rf "$sim"
    cp -R "$project_root" "$sim"
    while IFS= read -r write_file; do
        rel="${write_file#"$output_root"/}"
        mkdir -p "$sim/$(dirname "$rel")"
        cp "$write_file" "$sim/$rel"
    done < <(find "$output_root" -type f | sort)

    local before_hash after_hash
    while IFS='|' read -r rel before_hash; do
        [ -n "$rel" ] || continue
        if [ ! -f "$sim/$rel" ]; then
            echo "HOST_DOCUMENT_MUTATED|the onboarding write removed the pre-existing project document '$rel'"
            errors=$((errors + 1))
            host_unchanged=0
            continue
        fi
        after_hash="$(sha256sum "$sim/$rel" | cut -d' ' -f1)"
        if [ "$after_hash" != "$before_hash" ]; then
            echo "HOST_DOCUMENT_MUTATED|the onboarding write changed the pre-existing project document '$rel'"
            errors=$((errors + 1))
            host_unchanged=0
        fi
    done < "$host_before"

    if [ "$errors" -eq 0 ]; then
        echo "VALID|DIVERGENCES=$rows|HOST_DOC_UNCHANGED=$host_unchanged"
        return 0
    fi
    echo "FAILED|ERRORS=$errors|DIVERGENCES=$rows|HOST_DOC_UNCHANGED=$host_unchanged"
    return 1
}

run_case() {
    local name="$1" case_root="$2" expected_exit="$3" expected_summary="$4" expected_diagnostics="$5"
    local output="$TEMP_ROOT/$name.output" actual_exit expected_rows
    expected_rows="$(printf '%s\n' "$expected_summary" | sed -n 's/.*DIVERGENCES=\([0-9][0-9]*\).*/\1/p')"
    [ -n "$expected_rows" ] || fail "Missing expected divergence count for case $name"
    validate_case "$case_root" "$expected_rows" > "$output" 2>&1
    actual_exit=$?
    [ "$actual_exit" -eq "$expected_exit" ] || { cat "$output" >&2; fail "$name expected exit $expected_exit but received $actual_exit"; }
    grep -Fqx "$expected_summary" "$output" || { cat "$output" >&2; fail "$name did not contain the exact expected summary $expected_summary"; }
    assert_diagnostics "$output" "$expected_diagnostics"
}

[ -d "$FIXTURE_ROOT/cases" ] || fail "Missing onboarding divergence fixture root"
[ -f "$FIXTURE_ROOT/expected/cases.tsv" ] || fail "Missing onboarding divergence case manifest"

case_count=0
while IFS=$'\t' read -r name expected_exit expected_summary expected_diagnostics; do
    [ -n "$name" ] || continue
    [[ "$name" = \#* ]] && continue
    [ -n "$expected_diagnostics" ] || fail "Missing diagnostic contract for case $name"
    case_root="$FIXTURE_ROOT/cases/$name"
    [ -d "$case_root" ] || fail "Missing case root: $case_root"
    before_files="$TEMP_ROOT/$name-before-files"; before_status="$TEMP_ROOT/$name-before-status"; snapshot_files "$before_files"; snapshot_status "$before_status"
    run_case "$name" "$case_root" "$expected_exit" "$expected_summary" "$expected_diagnostics"
    assert_unchanged "$before_files" "$before_status" "$name"
    case_count=$((case_count + 1))
done < "$FIXTURE_ROOT/expected/cases.tsv"

echo "Onboarding divergence Bash matrix cases passed: $case_count isolated contracts."
echo "Onboarding divergence validation is deterministic, network-free, and read-only; it validates the specified sample output, the exact divergence-row count, and the host-document integrity property."
echo "Onboarding divergence validation does not execute an onboarding engine; it cannot prove that a live model detects every semantic contradiction."
