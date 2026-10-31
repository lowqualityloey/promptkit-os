#!/usr/bin/env bash
# Validate that every Phase 3c card's Verify probe discriminates.
#
#   validate-phase3c-probes.sh
#
# The Phase 3c slate (benchmarks/PHASE-3C-DESIGN.md) is built on one claim per
# card: the bare arm fails this probe and a correct fix passes it. This script
# checks that claim mechanically before any session is spent, using the same
# Verify extraction rule as benchmarks/run-ab-benchmark.sh, so a card cannot
# reach the batch with a probe that is green on the untouched seed or red on a
# correct solution.
#
# For each card it builds two trees from the pinned seed:
#
#   bare       the seed exactly as committed, which must FAIL the probe
#   reference  the seed plus the reference solution for that card's modules,
#              which must PASS the probe
#
# The reference solutions live in benchmarks/tasks/reference/p3c/. A module that
# several cards change (src/app.js serves 03, 04, 05 and 09) carries all of
# those cards' fixes, so the reference tree proves the fix is reachable and the
# bare tree proves the defect is present; it does not prove each card's fix is
# minimal.
#
# Operator-local Bash with no PowerShell twin, like the seed builders: it writes
# temporary trees and drives git and node, not a CLI.
#
# Output (stdout, one line per card, then one summary):
#   PROBE|<id>|bare=fail|reference=pass
#   VALIDATE|OK|cases=10
# Any card that does not discriminate is printed with its outcome and the script
# exits 2, failing closed. Errors go to stderr as VALIDATE|ERROR|<reason>.

set -uo pipefail
export LC_ALL=C

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
refdir=$here/tasks/reference/p3c
work=$(mktemp -d "${TMPDIR:-/tmp}/p3c-validate.XXXXXX") || {
    printf 'VALIDATE|ERROR|cannot create a work directory\n' >&2
    exit 2
}
trap 'rm -rf -- "$work"' EXIT

die() {
    printf 'VALIDATE|ERROR|%s\n' "$1" >&2
    exit 2
}

# parse_field is the driver's rule, copied verbatim: the single-line field value
# with its surrounding backticks removed. Keeping one copy would be better, but
# the driver resolves its own file by path and is not safely sourceable.
parse_field() {
    local line
    line="$(grep -m1 -- "^- \*\*${2}\*\*: " "$1" || true)"
    [[ -n "$line" ]] || return 1
    line="${line#- \*\*${2}\*\*: }"
    line="${line%$'\r'}"
    line="${line#\`}"
    line="${line%\`}"
    printf '%s' "$line"
}

# files_for <id>: the modules that card's reference solution replaces.
files_for() {
    case $1 in
        01|08) printf 'dispatcher.js\n' ;;
        02)    printf 'cli.js\napp.js\n' ;;
        03|04|05|09) printf 'app.js\n' ;;
        06)    printf 'dispatcher.js\nscheduler.js\napp.js\n' ;;
        07)    printf 'store.js\n' ;;
        10)    printf 'queue.js\n' ;;
        *)     return 1 ;;
    esac
}

command -v node >/dev/null 2>&1 || die "node is not on PATH"

seed=$work/seed
bash "$here/seed/build-phase3c-seed.sh" "$seed" >/dev/null 2>&1 \
    || die "seed build failed"

cards=("$here"/tasks/TASK-P3C-*.md)
[[ -e "${cards[0]}" ]] || die "no Phase 3c task cards found"
[[ -d "$refdir" ]] || die "reference solutions missing: $refdir"

cases=0
bad=0
for card in "${cards[@]}"; do
    base=${card##*/}
    id=${base#TASK-P3C-}
    id=${id%.md}
    verify=$(parse_field "$card" Verify) || die "no Verify field in $base"
    [[ -n "$verify" ]] || die "empty Verify field in $base"
    files=$(files_for "$id") || die "no reference mapping for P3C-$id"

    bare=$work/bare-$id
    cp -a -- "$seed" "$bare" || die "cannot stage the bare tree for P3C-$id"
    if (cd -- "$bare" && eval "$verify") >/dev/null 2>&1; then
        bare_outcome=pass
    else
        bare_outcome=fail
    fi

    ref=$work/ref-$id
    cp -a -- "$seed" "$ref" || die "cannot stage the reference tree for P3C-$id"
    while IFS= read -r module; do
        [[ -n "$module" ]] || continue
        [[ -f "$refdir/$module" ]] || die "reference module missing: $module"
        cp -- "$refdir/$module" "$ref/src/$module" \
            || die "cannot apply the reference module $module"
    done <<<"$files"
    if (cd -- "$ref" && eval "$verify") >/dev/null 2>&1; then
        ref_outcome=pass
    else
        ref_outcome=fail
    fi

    printf 'PROBE|%s|bare=%s|reference=%s\n' "$id" "$bare_outcome" "$ref_outcome"
    cases=$((cases + 1))
    [[ $bare_outcome == fail && $ref_outcome == pass ]] || bad=$((bad + 1))
done

[[ $bad -eq 0 ]] || die "$bad of $cases probes do not discriminate"
printf 'VALIDATE|OK|cases=%s\n' "$cases"
