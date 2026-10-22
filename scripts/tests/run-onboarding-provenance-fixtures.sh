#!/usr/bin/env bash
# Cross-platform fixture harness for the onboarding artifact-provenance
# consistency contract (protocols/discovery-intake.md section G).
# Run from repository root: bash scripts/tests/run-onboarding-provenance-fixtures.sh
#
# Enforcement honesty: onboarding is a Markdown workflow, not an executable
# artifact generator. This harness validates the SPECIFIED classification of
# generated onboarding artifacts against the provenance contract. It does not
# execute an onboarding engine, and it cannot prove that a live model produces
# consistent artifacts.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_ROOT="$REPO_ROOT/scripts/tests/fixtures/onboarding-provenance"
TEMP_BASE="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
TEMP_ROOT="$(mktemp -d "$TEMP_BASE/promptkit-onboarding-provenance.XXXXXX")"

cleanup() { rm -rf "$TEMP_ROOT"; }
trap cleanup EXIT
fail() { echo "HARNESS_FAILURE|$1" >&2; exit 1; }

snapshot_files() {
    local output_file="$1"
    : > "$output_file"
    while IFS= read -r file; do printf '%s|' "$file" >> "$output_file"; sha256sum "$file" >> "$output_file"; done < <(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type f -print | sort)
}

snapshot_status() { git -C "$REPO_ROOT" status --porcelain=v1 --untracked-files=all > "$1" || fail "Unable to read Git status"; }

assert_unchanged() {
    local before_files="$1" before_status="$2" label="$3" after_files after_status
    after_files="$TEMP_ROOT/$label-after-files"
    after_status="$TEMP_ROOT/$label-after-status"
    snapshot_files "$after_files"
    snapshot_status "$after_status"
    cmp -s "$before_files" "$after_files" || fail "Repository file hashes changed during $label validation"
    cmp -s "$before_status" "$after_status" || fail "Git status changed during $label validation"
}

assert_diagnostics() {
    local output="$1" expected="$2" actual normalized_expected
    actual="$(grep -vE '^(VALID|FAILED)[|]' "$output" || true)"
    if [ "$expected" = '-' ]; then
        [ -z "$actual" ] || { cat "$output" >&2; fail "Unexpected diagnostics in a valid case"; }
        return
    fi
    actual="$(printf '%s\n' "$actual" | LC_ALL=C sort -f)"
    normalized_expected="$(printf '%s\n' "$expected" | sed 's/;;/\n/g' | LC_ALL=C sort -f)"
    [ "$actual" = "$normalized_expected" ] || { cat "$output" >&2; fail "Complete normalized diagnostic set did not match the shared contract"; }
}

# Resolve one verification-obligation destination against the generated artifact set.
resolve_destination() {
    local destination="$1" output_root="$2" path rest section
    path="$destination"
    rest=""
    case "$path" in
        *"§"*)
            rest="${path#*§}"
            path="${path%%§*}"
            ;;
    esac
    path="$(printf '%s' "$path" | sed 's/[[:space:]]*$//')"
    case "$path" in
        docs/STATE.md|./docs/STATE.md)
            [ -f "$output_root/docs/STATE.md" ] || return 1
            while IFS= read -r section; do
                [ -n "$section" ] || continue
                grep -qE "^##[[:space:]]+$section[.][[:space:]]" "$output_root/docs/STATE.md" || return 1
            done < <(printf '%s' "$rest" | grep -oE '[0-9]+' || true)
            return 0
            ;;
        docs/tasks/*)
            [ -f "$output_root/$path" ] || return 1
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Parse the registers of one Intake Record and print diagnostics, destination
# checks, and the register counts.
analyse_intake() {
    awk '
BEGIN {
    FS = "|"
    sec = ""
    na = 0; nd = 0; ndf = 0; no = 0; rounds = 0; qsum = 0
}
function trim(s) { gsub(/^[[:space:]]+/, "", s); gsub(/[[:space:]]+$/, "", s); return s }
function placeholder(s) {
    return (s == "" || s == "-" || s == "none" || s == "None" || s == "NONE" || s == "n/a" || s == "N/A" || s == "TBD" || s == "not tracked" || s == "?")
}
function member(list, target,    n, i, arr) {
    n = split(list, arr, /[,;[:space:]]+/)
    for (i = 1; i <= n; i++) if (arr[i] == target) return 1
    return 0
}
/^## / { sec = trim(substr($0, 4)); hdr = 0; seen[sec] = 1; next }
/^[|]/ {
    if (sec == "") next
    m = 0
    for (i = 2; i <= NF - 1; i++) cells[++m] = trim($i)
    if (m == 0) next
    if (cells[1] ~ /^:?-+:?$/) next
    if (hdr == 0) { hdr = 1; next }
    if (sec == "Decisions") {
        nd++
        dec_id[nd] = cells[1]
        dec_status[cells[1]] = tolower(cells[2])
        dec_prov[cells[1]] = cells[4]
    } else if (sec == "Accepted defaults") {
        ndf++
        def_id[ndf] = cells[1]
        def_resolves[cells[1]] = cells[5]
    } else if (sec == "Assumption records") {
        na++
        asm_id[na] = cells[1]
        asm_status[cells[1]] = tolower(cells[5])
        asm_link[cells[1]] = cells[6]
        asm_risk[cells[1]] = cells[7]
        asm_dest[cells[1]] = cells[8]
    } else if (sec == "Verification obligations") {
        no++
        obl_id[no] = cells[1]
        obl_owner[cells[1]] = cells[3]
        obl_status[cells[1]] = cells[4]
        obl_dest[cells[1]] = cells[5]
    } else if (sec == "Intake metadata") {
        meta[cells[1]] = cells[2]
    } else if (sec == "Round log") {
        rounds++
        if (cells[2] ~ /^[0-9]+$/) qsum += cells[2] + 0
    }
    next
}
END {
    nreq = split("Intake metadata;Decisions;Accepted defaults;Assumption records;Verification obligations;Round log", req, ";")
    for (i = 1; i <= nreq; i++) if (!(req[i] in seen)) print "REGISTER_MISSING|" req[i]
    for (k = 1; k <= na; k++) {
        id = asm_id[k]
        st = asm_status[id]
        lk = asm_link[id]
        if (lk ~ /^DECISION-/ && dec_status[lk] == "confirmed" && st !~ /^(accepted|superseded)/)
            print "ASSUMPTION_STILL_OPEN|" id "|" lk
        if (st ~ /^(accepted|superseded)/ && !placeholder(asm_risk[id]) && placeholder(asm_dest[id]))
            print "RESIDUAL_RISK_UNTRACKED|" id
    }
    for (k = 1; k <= nd; k++) {
        id = dec_id[k]
        if (match(dec_prov[id], /DEFAULT-[a-z0-9-]+-[0-9][0-9][0-9]/)) {
            d = substr(dec_prov[id], RSTART, RLENGTH)
            if (!member(def_resolves[d], id)) print "DEFAULT_WIDENED|" d "|" id
        }
    }
    size = tolower(meta["Size"])
    if (size == "small") qceil = 5
    else if (size == "medium") qceil = 8
    else if (size == "large") qceil = 12
    else qceil = 0
    rs = meta["Rounds used"]
    qs = meta["Questions asked"]
    if (rs ~ /^[0-9]+$/ && rs + 0 != rounds)
        print "COUNT_CONTRADICTION|rounds|stated=" rs "|recorded=" rounds
    if (qs ~ /^[0-9]+$/) {
        if (qs + 0 != qsum) print "COUNT_CONTRADICTION|questions|stated=" qs "|recorded=" qsum
        if (qceil > 0 && qs + 0 > qceil) print "QUESTION_BUDGET_EXCEEDED|size=" size "|ceiling=" qceil "|asked=" qs
    }
    for (k = 1; k <= no; k++) {
        id = obl_id[k]
        if (placeholder(obl_owner[id])) print "OBLIGATION_UNTRACKED|" id "|owner"
        if (placeholder(obl_status[id])) print "OBLIGATION_UNTRACKED|" id "|status"
        if (placeholder(obl_dest[id])) print "OBLIGATION_UNTRACKED|" id "|destination"
        else print "DESTCHECK|" id "|" obl_dest[id]
    }
    print "COUNTS|DECISIONS=" nd "|DEFAULTS=" ndf "|ASSUMPTIONS=" na "|OBLIGATIONS=" no "|ROUNDS=" rounds
}
' "$1"
}

# Validate one fixture case; print diagnostics and the summary line.
validate_case() {
    local case_root="$1"
    local output_root="$case_root/expected-output"
    local state_file="$output_root/docs/STATE.md"
    local counts="DECISIONS=0|DEFAULTS=0|ASSUMPTIONS=0|OBLIGATIONS=0|ROUNDS=0"
    local diagnostics="$TEMP_ROOT/diagnostics.txt"
    local intake="" intake_count=0 candidate

    : > "$diagnostics"
    for candidate in "$output_root"/docs/specs/*.md; do
        [ -f "$candidate" ] || continue
        intake_count=$((intake_count + 1))
        [ "$intake_count" -eq 1 ] && intake="$candidate"
    done
    if [ "$intake_count" -ne 1 ]; then
        echo "MISSING_INTAKE_RECORD|the fixture does not contain exactly one Intake Record under expected-output/docs/specs" >> "$diagnostics"
        LC_ALL=C sort -f "$diagnostics"
        echo "FAILED|ERRORS=1|$counts"
        return 1
    fi
    if [ ! -f "$state_file" ]; then
        echo "MISSING_STATE|the fixture has no generated docs/STATE.md" >> "$diagnostics"
        LC_ALL=C sort -f "$diagnostics"
        echo "FAILED|ERRORS=1|$counts"
        return 1
    fi

    local raw="$TEMP_ROOT/analysis.txt"
    analyse_intake "$intake" > "$raw" || fail "Unable to parse the Intake Record at $intake"

    local parsed_counts
    parsed_counts="$(grep -F 'COUNTS|' "$raw" | tail -n 1 | sed 's/^COUNTS|//')"
    [ -n "$parsed_counts" ] && counts="$parsed_counts"
    grep -vE '^(COUNTS|DESTCHECK)[|]' "$raw" > "$diagnostics" || true

    local line id value
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        id="$(printf '%s' "$line" | cut -d'|' -f2)"
        value="$(printf '%s' "$line" | cut -d'|' -f3-)"
        resolve_destination "$value" "$output_root" || echo "OBLIGATION_DESTINATION_MISSING|$id|$value" >> "$diagnostics"
    done < <(grep -F 'DESTCHECK|' "$raw" || true)

    local errors
    errors="$(grep -c . "$diagnostics" 2>/dev/null || true)"
    [ -n "$errors" ] || errors=0
    if [ "$errors" -gt 0 ]; then
        LC_ALL=C sort -f "$diagnostics"
        echo "FAILED|ERRORS=$errors|$counts"
        return 1
    fi
    echo "VALID|$counts"
    return 0
}

run_case() {
    local name="$1" case_root="$2" expected_exit="$3" expected_summary="$4" expected_diagnostics="$5"
    local output="$TEMP_ROOT/$name.output" actual_exit actual_errors expected_errors
    expected_errors="$(printf '%s\n' "$expected_summary" | sed -n 's/.*ERRORS=\([0-9][0-9]*\).*/\1/p')"
    if [ "$expected_diagnostics" = '-' ]; then
        [ -z "$expected_errors" ] || fail "Case $name claims a valid summary but lists diagnostics"
        [ "$expected_exit" -eq 0 ] || fail "Case $name expects diagnostics with a failing exit"
    else
        [ -n "$expected_errors" ] || fail "Case $name must state an ERRORS count in its expected summary"
        actual_errors="$(printf '%s\n' "$expected_diagnostics" | sed 's/;;/\n/g' | grep -c . || true)"
        [ -n "$actual_errors" ] || actual_errors=0
        [ "$actual_errors" -eq "$expected_errors" ] || fail "Case $name manifest disagreement: the summary claims $expected_errors diagnostic(s), the contract lists $actual_errors"
    fi
    validate_case "$case_root" > "$output" 2>&1
    actual_exit=$?
    [ "$actual_exit" -eq "$expected_exit" ] || { cat "$output" >&2; fail "$name expected exit $expected_exit but received $actual_exit"; }
    grep -Fqx "$expected_summary" "$output" || { cat "$output" >&2; fail "$name did not contain the exact expected summary $expected_summary"; }
    assert_diagnostics "$output" "$expected_diagnostics"
}

[ -d "$FIXTURE_ROOT/cases" ] || fail "Missing onboarding provenance fixture root"
[ -f "$FIXTURE_ROOT/expected/cases.tsv" ] || fail "Missing onboarding provenance case manifest"

case_count=0
while IFS=$'\t' read -r name expected_exit expected_summary expected_diagnostics; do
    [ -n "$name" ] || continue
    [[ "$name" = \#* ]] && continue
    [ -n "$expected_diagnostics" ] || fail "Missing diagnostic contract for case $name"
    case_root="$FIXTURE_ROOT/cases/$name"
    [ -d "$case_root" ] || fail "Missing case root: $case_root"
    before_files="$TEMP_ROOT/$name-before-files"
    before_status="$TEMP_ROOT/$name-before-status"
    snapshot_files "$before_files"
    snapshot_status "$before_status"
    run_case "$name" "$case_root" "$expected_exit" "$expected_summary" "$expected_diagnostics"
    assert_unchanged "$before_files" "$before_status" "$name"
    case_count=$((case_count + 1))
done < "$FIXTURE_ROOT/expected/cases.tsv"

echo "Onboarding provenance Bash matrix cases passed: $case_count isolated contracts."
echo "Onboarding provenance validation is deterministic, network-free, and read-only; it validates the specified classification of generated Intake Records and their obligation destinations."
echo "Onboarding provenance validation does not execute an onboarding engine; it cannot prove that a live model produces consistent artifacts."
