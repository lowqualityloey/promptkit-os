#!/usr/bin/env bash
# Projection-parity harness (issue #669): the shared 3A/Task-Record projection
# definition — the pair list AND the comparison-class assignment (#671) — must be
# identical in all four engine scripts (check-doctor.sh, check-doctor.ps1,
# validate-execution-control.sh, validate-execution-control.ps1). Each script's
# definition is extracted textually and compared to the canonical sequence; a
# script that adds, renames, reorders, or reclassifies a field alone fails here
# instead of silently forking the doctor/validator verdicts.
#
# Offline and read-only: parses four repo files, no git, no fixtures.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail() { echo "HARNESS_FAILURE|$1" >&2; exit 1; }

# check-doctor.sh: SHARED_PROJECTION_FIELDS=( ... ) block, one '3A|record|class' per line.
canon_doctor_sh() {
    awk '/^SHARED_PROJECTION_FIELDS=\(/{inside=1; next} inside && /^\)/{exit} inside{print}' \
        "$REPO_ROOT/scripts/check-doctor.sh" \
        | sed -e 's/^[[:space:]]*//' -e "s/'//g" -e 's/"//g' -e 's/`//g' -e 's/\\//g' -e 's/,$//'
}

# check-doctor.ps1: $sharedProjectionFields = @( ... ) block.
canon_doctor_ps1() {
    awk '/sharedProjectionFields = @\(/{inside=1; next} inside && /^\)/{exit} inside{print}' \
        "$REPO_ROOT/scripts/check-doctor.ps1" \
        | sed -e 's/^[[:space:]]*//' -e "s/'//g" -e 's/`//g' -e 's/\\//g' -e 's/,$//'
}

# validate-execution-control.sh: compare_pairs=( "3A|record|class" ... ) line.
canon_validator_sh() {
    grep -oE 'compare_pairs=\(.*\)' "$REPO_ROOT/scripts/validate-execution-control.sh" \
        | sed -e 's/^compare_pairs=(//' -e 's/)$//' -e 's/" "/\n/g' -e 's/"//g' -e 's/`//g' -e 's/\\//g'
}

# validate-execution-control.ps1: foreach ($pair in @( @('a','b','c'), ... )) block.
canon_validator_ps1() {
    awk '/foreach \(\$pair in @\(/{inside=1; next} inside && /^\s*\)\)\s*\{/{exit} inside{print}' \
        "$REPO_ROOT/scripts/validate-execution-control.ps1" \
        | sed -nE "s/^[[:space:]]*@\('([^']*)', '([^']*)', '([^']*)'\),?$/\1|\2|\3/p" \
        | sed -e 's/`//g' -e 's/\\//g'
}

doctor_sh="$(canon_doctor_sh)"
doctor_ps1="$(canon_doctor_ps1)"
validator_sh="$(canon_validator_sh)"
validator_ps1="$(canon_validator_ps1)"

for name in doctor_sh doctor_ps1 validator_sh validator_ps1; do
    [ -n "${!name}" ] || fail "could not extract the projection definition from $name"
    [ "$(printf '%s\n' "${!name}" | wc -l)" -eq 10 ] || fail "$name does not declare exactly 10 projection fields"
done

for pair_name in doctor_ps1 validator_sh validator_ps1; do
    if [ "$doctor_sh" != "${!pair_name}" ]; then
        echo "HARNESS_FAILURE|projection definition diverges between check-doctor.sh and $pair_name" >&2
        diff <(printf '%s\n' "$doctor_sh") <(printf '%s\n' "${!pair_name}") >&2 || true
        exit 1
    fi
done

prose="$(printf '%s\n' "$doctor_sh" | awk -F'|' '$3 == "prose" { print $1 }')"
[ "$(printf '%s\n' "$prose" | sort | tr '\n' ' ')" = "Execution Scope Next Action Specification " ] \
    || fail "prose class must be exactly: Execution Scope, Next Action, Specification"
machine_count="$(printf '%s\n' "$doctor_sh" | awk -F'|' '$3 == "machine" { n++ } END { print n+0 }')"
[ "$machine_count" -eq 6 ] || fail "machine class must cover the remaining 6 fields, got $machine_count"
level_count="$(printf '%s\n' "$doctor_sh" | awk -F'|' '$3 == "level" { n++ } END { print n+0 }')"
[ "$level_count" -eq 1 ] || fail "level class must cover exactly Ceremony Level, got $level_count"

echo "PASS|projection definition identical across check-doctor and validate-execution-control twins (10 fields; prose=Execution Scope,Next Action,Specification; level=Ceremony Level; machine=6)"
