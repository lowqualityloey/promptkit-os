#!/usr/bin/env bash
# PromptKit OS Benchmark Run Aggregator
# Merges §5 telemetry records (as scored by scripts/measure-cpac.sh) with a
# blind-grading TSV into per-run rows and per-arm aggregates. The arm is each
# record's `condition`; CPAC semantics come from measure-cpac itself (records
# carry their final accepted flag — set by the operator at re-extraction after
# grading — and the grading TSV's accepted column is a fail-closed cross-check:
# a mismatch exits 2 rather than being silently reconciled).
#
# Usage: aggregate-benchmark-runs.sh --grading <sheet.tsv> <record.json>...
# Grading TSV (tab-separated, header optional):
#   run_id <TAB> rubric_passed <TAB> rubric_total <TAB> accepted
# Output: RUN|... per record (input order) and BENCH|SUMMARY|... per arm.
# CPAC aggregates cover accepted runs only (INF is excluded by definition).
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRADING=""
declare -a RECORDS=()

usage() {
    echo "Usage: aggregate-benchmark-runs.sh --grading <sheet.tsv> <record.json>..."
    echo "Grading TSV: run_id <TAB> rubric_passed <TAB> rubric_total <TAB> accepted"
    echo "Prints RUN|... rows and BENCH|SUMMARY|... per-arm aggregate machine lines."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --grading)
            GRADING="$2"
            shift 2
            ;;
        --grading=*)
            GRADING="${1#--grading=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            printf 'BENCH|ERROR|UNKNOWN_FLAG|%s\n' "$1" >&2
            exit 2
            ;;
        *)
            RECORDS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#RECORDS[@]} -eq 0 ]]; then
    usage
    exit 2
fi
if [[ -z "$GRADING" || ! -s "$GRADING" ]]; then
    printf 'BENCH|ERROR|UNREADABLE|%s\n' "$GRADING" >&2
    exit 2
fi

declare -A G_ACCEPTED=()
declare -A G_PASSED=()
declare -A G_TOTAL=()
gline_no=0
while IFS=$'\t' read -r gid gpassed gtotal gaccepted; do
    gline_no=$((gline_no + 1))
    [[ -z "$gid" ]] && continue
    [[ "$gid" == "run_id" ]] && continue
    if [[ ! "$gpassed" =~ ^[0-9]+$ || ! "$gtotal" =~ ^[0-9]+$ ]] || { [[ "$gaccepted" != "true" && "$gaccepted" != "false" ]]; }; then
        printf 'BENCH|ERROR|BAD_GRADING|%s\n' "$gline_no" >&2
        exit 2
    fi
    G_ACCEPTED[$gid]="$gaccepted"
    G_PASSED[$gid]="$gpassed"
    G_TOTAL[$gid]="$gtotal"
done < "$GRADING"

FLAT="$(mktemp "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/bench-flat.XXXXXX")"
trap 'rm -f "$FLAT"' EXIT

for rec in "${RECORDS[@]}"; do
    if [[ ! -s "$rec" ]]; then
        printf 'BENCH|ERROR|UNREADABLE|%s\n' "$rec" >&2
        exit 2
    fi
    line="$(bash "$SCRIPT_DIR/measure-cpac.sh" "$rec" 2>/dev/null | grep '^CPAC|MEASURED|' || true)"
    if [[ -z "$line" ]]; then
        printf 'BENCH|ERROR|BAD_RECORD|%s\n' "$rec" >&2
        exit 2
    fi
    declare -A F=()
    IFS='|' read -r -a PARTS <<< "$line"
    for part in "${PARTS[@]:2}"; do
        F["${part%%=*}"]="${part#*=}"
    done
    scenario="${F[scenario]}"
    condition="${F[condition]}"
    model="${F[model]}"
    cpac="${F[cpac_usd]}"
    wall="${F[wall_clock_seconds]}"
    loops="${F[rework_loops]}"
    tt=$(( ${F[tokens_in]} + ${F[tokens_out]} + ${F[rework_tokens_in]} + ${F[rework_tokens_out]} ))
    if [[ "$cpac" == "INF" ]]; then acc=0; else acc=1; fi
    graded=0
    rubric="-"
    if [[ -n "${G_ACCEPTED[$scenario]:-}" ]]; then
        graded=1
        rubric="${G_PASSED[$scenario]}/${G_TOTAL[$scenario]}"
        want=0
        [[ "${G_ACCEPTED[$scenario]}" == "true" ]] && want=1
        if [[ "$want" -ne "$acc" ]]; then
            printf 'BENCH|ERROR|ACCEPTED_MISMATCH|%s\n' "$scenario" >&2
            exit 2
        fi
    fi
    printf '%s|%s|%s|%d|%d|%d|%d|%d|%s|%s|%s\n' \
        "$scenario" "$condition" "$model" "$acc" "$graded" "$tt" "$wall" "$loops" "$rubric" "$cpac" "$rec" >> "$FLAT"
    printf 'RUN|%s|arm=%s|model=%s|accepted=%d|graded=%d|rubric=%s|tokens_total=%d|wall_clock_seconds=%s|rework_loops=%s|cpac_usd=%s\n' \
        "$scenario" "$condition" "$model" "$acc" "$graded" "$rubric" "$tt" "$wall" "$loops" "$cpac"
done

# Per-arm aggregates from the flat rows (single awk pass; medians via an
# insertion sort over the small per-arm arrays).
awk -F'|' '
function median(arr, n,  i, j, tmp, v, m) {
    for (i = 1; i <= n; i++) v[i] = arr[i]
    for (i = 1; i <= n; i++) {
        for (j = i + 1; j <= n; j++) {
            if (v[j] < v[i]) { tmp = v[i]; v[i] = v[j]; v[j] = tmp }
        }
    }
    if (n % 2 == 1) return v[int(n / 2) + 1]
    return (v[n / 2] + v[n / 2 + 1]) / 2
}
{
    arm = $2
    n[arm]++
    if ($4 == 1) acc[arm]++
    if ($5 == 1) gradedn[arm]++
    tok[arm "," n[arm]] = $6
    wal[arm "," n[arm]] = $7
    rew[arm "," n[arm]] = $8
    if ($4 == 1 && $10 != "INF") { cpacn[arm]++; cpac[arm "," cpacn[arm]] = $10 }
    arms[arm] = 1
}
END {
    m = 0
    for (a in arms) order[++m] = a
    for (i = 1; i <= m; i++) {
        for (j = i + 1; j <= m; j++) {
            if (order[j] < order[i]) { tmp = order[i]; order[i] = order[j]; order[j] = tmp }
        }
    }
    for (i = 1; i <= m; i++) {
        a = order[i]
        tkmean = 0; wlmean = 0; rwmean = 0
        for (k = 1; k <= n[a]; k++) {
            tkmean += tok[a "," k]; wlmean += wal[a "," k]; rwmean += rew[a "," k]
            tka[k] = tok[a "," k] + 0
            wla[k] = wal[a "," k] + 0
        }
        tkmean /= n[a]; wlmean /= n[a]; rwmean /= n[a]
        tkmed = median(tka, n[a])
        wlmed = median(wla, n[a])
        rate = (n[a] > 0) ? acc[a] / n[a] : 0
        if (cpacn[a] > 0) {
            cm = 0
            for (k = 1; k <= cpacn[a]; k++) {
                cm += cpac[a "," k]
                cpa[k] = cpac[a "," k] + 0
            }
            cm /= cpacn[a]
            cmed = median(cpa, cpacn[a])
            printf "BENCH|SUMMARY|arm=%s|n=%d|accepted=%d|accept_rate=%.2f|tokens_mean=%.1f|tokens_median=%.1f|wall_mean=%.1f|wall_median=%.1f|rework_mean=%.2f|cpac_n=%d|cpac_mean=%.4f|cpac_median=%.4f\n", a, n[a], acc[a], rate, tkmean, tkmed, wlmean, wlmed, rwmean, cpacn[a], cm, cmed
        } else {
            printf "BENCH|SUMMARY|arm=%s|n=%d|accepted=%d|accept_rate=%.2f|tokens_mean=%.1f|tokens_median=%.1f|wall_mean=%.1f|wall_median=%.1f|rework_mean=%.2f|cpac_n=0|cpac_mean=N/A|cpac_median=N/A\n", a, n[a], acc[a], rate, tkmean, tkmed, wlmean, wlmed, rwmean
        }
    }
}' "$FLAT"
