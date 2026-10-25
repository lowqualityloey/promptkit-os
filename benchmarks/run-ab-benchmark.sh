#!/usr/bin/env bash
# PromptKit OS A/B Benchmark Orchestrator (operator-local)
# Implements the protocol in benchmarks/README.md: paired runs of PromptKit OS
# (directive installed via the engine's init.sh) versus bare Command Code over
# a frozen task batch, with blind grading packets and CPAC aggregation through
# the scripts/ pipeline.
#
# OPERATOR-LOCAL BY DESIGN: this script drives a live, subscription-backed CLI
# (command-code) and spends the operator's plan. It is not CI-run against the
# real CLI and has no PowerShell twin — the twin-parity rule binds repository
# behavior surfaces, while every pure, reusable piece this script calls
# (extractor, stripper, aggregator, scorer) is a twin-tested scripts/ tool.
# The run and finalize paths ARE regression-tested in CI against a stub CLI
# with an isolated HOME (scripts/tests/run-benchmark-driver-tests.sh).
# Linux/WSL only (GNU timeout). Raw transcripts stay under ~/.commandcode and
# are never committed.
#
# Blinding contract: the grader receives B<nnn>.diff (+ B<nnn>.verify.txt when
# the task declares a Verify command) with ids assigned by a shuffle across ALL
# runs of the batch; the blind->scenario mapping lives in grading/key.csv and
# is consulted only by --finalize. The grading sheet is keyed by BLIND ID.
#
# Modes:
#   run batch:   run-ab-benchmark.sh --engine E --seed S --tasks a.md,b.md \
#                  --model M --out DIR [--max-turns N] [--timeout S]
#                  [--repeats N] [--profile lite|balanced]
#   dry run:     ... --preflight-only   (validates environment, spends nothing)
#   finalize:    run-ab-benchmark.sh --finalize DIR --grading DIR/grading/grading.tsv
#                (translates the blind-id sheet via key.csv, re-extracts each
#                 run with its graded accepted flag, then runs the aggregator
#                 with a scenario-keyed sheet as cross-check)
set -euo pipefail
export LC_ALL=C

ENGINE="" SEED="" TASKS_CSV="" MODEL="" OUT="" MAXTURNS=40 TIMEOUT=900 REPEATS=1 PROFILE=balanced PREFLIGHT_ONLY=0 FINALIZE=0 GRADING=""

usage() {
    echo "Usage: run-ab-benchmark.sh --engine <promptkit-repo> --seed <seed-repo>"
    echo "       --tasks <task.md,...> --model <model> --out <dir>"
    echo "       [--max-turns N] [--timeout S] [--repeats N] [--profile lite|balanced]"
    echo "       [--preflight-only]"
    echo "       run-ab-benchmark.sh --finalize <dir> --grading <dir/grading/grading.tsv>"
}

bench_error() {
    printf 'BENCH|ERROR|%s|%s\n' "$1" "$2" >&2
    exit 2
}

need_value() {
    # need_value <flag> : fail closed when a value-taking flag has no operand
    [[ "$#" -ge 2 && -n "$2" ]] || bench_error "MISSING_VALUE" "$1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --engine=*) ENGINE="${1#--engine=}" ;;
        --engine) need_value "$1" "${2:-}"; ENGINE="$2"; shift ;;
        --seed=*) SEED="${1#--seed=}" ;;
        --seed) need_value "$1" "${2:-}"; SEED="$2"; shift ;;
        --tasks=*) TASKS_CSV="${1#--tasks=}" ;;
        --tasks) need_value "$1" "${2:-}"; TASKS_CSV="$2"; shift ;;
        --model=*) MODEL="${1#--model=}" ;;
        --model) need_value "$1" "${2:-}"; MODEL="$2"; shift ;;
        --out=*) OUT="${1#--out=}" ;;
        --out) need_value "$1" "${2:-}"; OUT="$2"; shift ;;
        --max-turns=*) MAXTURNS="${1#--max-turns=}" ;;
        --max-turns) need_value "$1" "${2:-}"; MAXTURNS="$2"; shift ;;
        --timeout=*) TIMEOUT="${1#--timeout=}" ;;
        --timeout) need_value "$1" "${2:-}"; TIMEOUT="$2"; shift ;;
        --repeats=*) REPEATS="${1#--repeats=}" ;;
        --repeats) need_value "$1" "${2:-}"; REPEATS="$2"; shift ;;
        --profile=*) PROFILE="${1#--profile=}" ;;
        --profile) need_value "$1" "${2:-}"; PROFILE="$2"; shift ;;
        --grading=*) GRADING="${1#--grading=}" ;;
        --grading) need_value "$1" "${2:-}"; GRADING="$2"; shift ;;
        --preflight-only) PREFLIGHT_ONLY=1 ;;
        --finalize)
            # consumes its <dir> operand per the documented invocation
            need_value "$1" "${2:-}"
            FINALIZE=1; OUT="$2"; shift
            ;;
        -h|--help) usage; exit 0 ;;
        *) bench_error "UNKNOWN_FLAG" "$1" ;;
    esac
    shift
done

if [[ "$FINALIZE" -eq 1 ]]; then
    # ---- finalize mode -------------------------------------------------------
    [[ -n "$OUT" && -d "$OUT" ]] || bench_error "UNREADABLE" "$OUT"
    [[ -n "$GRADING" && -s "$GRADING" ]] || bench_error "UNREADABLE" "$GRADING"
    if [[ -z "$ENGINE" ]]; then
        [[ -r "$OUT/engine-path.txt" ]] || bench_error "UNREADABLE" "$OUT/engine-path.txt"
        ENGINE="$(cat "$OUT/engine-path.txt")"
    fi
    [[ -d "$ENGINE" ]] || bench_error "UNREADABLE" "engine $ENGINE"
    EXTRACT="$ENGINE/scripts/extract-commandcode-telemetry.sh"
    AGG="$ENGINE/scripts/aggregate-benchmark-runs.sh"
    [[ -f "$EXTRACT" && -f "$AGG" ]] || bench_error "UNREADABLE" "engine scripts under $ENGINE"
    KEY="$OUT/grading/key.csv"
    MANIFEST="$OUT/manifest.tsv"
    [[ -s "$KEY" && -s "$MANIFEST" ]] || bench_error "UNREADABLE" "key.csv/manifest.tsv"

    # blind -> scenario map from the withheld key (first consultation point)
    declare -A S2B=()
    while IFS=, read -r kb ks; do
        kb="${kb%$'\r'}"; ks="${ks%$'\r'}"
        [[ -z "$kb" || "$kb" == "blind" ]] && continue
        S2B[$ks]="$kb"
    done < "$KEY"

    # blind-keyed grading sheet: blind<TAB>rubric_passed<TAB>rubric_total<TAB>accepted
    declare -A G_ACC=() G_PASS=() G_TOT=()
    glineno=0
    while IFS=$'\t' read -r gb gp gt ga || [[ -n "$gb" ]]; do
        glineno=$((glineno + 1))
        gb="${gb%$'\r'}"; gp="${gp%$'\r'}"; gt="${gt%$'\r'}"; ga="${ga%$'\r'}"
        [[ -z "$gb" || "$gb" == "blind_id" || "$gb" == "run_id" ]] && continue
        [[ "$gp" =~ ^[0-9]+$ && "$gt" =~ ^[0-9]+$ ]] || bench_error "BAD_GRADING" "line $glineno"
        { [[ "$ga" == "true" || "$ga" == "false" ]]; } || bench_error "BAD_GRADING" "line $glineno (accepted)"
        G_ACC[$gb]="$ga"; G_PASS[$gb]="$gp"; G_TOT[$gb]="$gt"
    done < "$GRADING"

    # translate to a scenario-keyed sheet for the aggregator, re-extract records
    TRANSLATED="$OUT/grading/grading.scenario.tsv"
    : > "$TRANSLATED"
    RECORDS=()
    while IFS=$'\t' read -r scenario arm rundir transcript record diff stripped; do
        [[ -z "$scenario" || "$scenario" == "scenario" ]] && continue
        blind="${S2B[$scenario]:-}"
        [[ -n "$blind" ]] || bench_error "MISSING_KEY_ROW" "$scenario"
        acc="${G_ACC[$blind]:-}"
        [[ -n "$acc" ]] || bench_error "MISSING_GRADING" "$blind ($scenario)"
        bash "$EXTRACT" "$transcript" --scenario-id="$scenario" --condition="$arm" --accepted="$acc" \
            --error-patterns="$(cat "$OUT/error-patterns.txt")" \
            > "$record" 2>>"$OUT/runs/$scenario/extract.log" || bench_error "EXTRACT_FAILED" "$scenario"
        printf '%s\t%s\t%s\t%s\n' "$scenario" "${G_PASS[$blind]}" "${G_TOT[$blind]}" "$acc" >> "$TRANSLATED"
        RECORDS+=("$record")
    done < "$MANIFEST"

    bash "$AGG" --grading "$TRANSLATED" "${RECORDS[@]}"
    exit 0
fi

# ---- run mode -------------------------------------------------------------
[[ -n "$ENGINE" && -d "$ENGINE" ]] || bench_error "UNREADABLE" "engine"
[[ -n "$SEED" && -d "$SEED/.git" ]] || bench_error "UNREADABLE" "seed repo (must be a git clone)"
[[ -n "$TASKS_CSV" ]] || bench_error "MISSING" "tasks"
[[ -n "$MODEL" ]] || bench_error "MISSING" "model (spend control: the driver refuses to guess)"
[[ -n "$OUT" ]] || bench_error "MISSING" "out"
[[ "$PROFILE" == "lite" || "$PROFILE" == "balanced" ]] || bench_error "BAD_VALUE" "profile"
[[ "$MAXTURNS" =~ ^[0-9]+$ && "$MAXTURNS" -gt 0 ]] || bench_error "BAD_VALUE" "max-turns"
[[ "$TIMEOUT" =~ ^[0-9]+$ && "$TIMEOUT" -gt 0 ]] || bench_error "BAD_VALUE" "timeout"
[[ "$REPEATS" =~ ^[0-9]+$ && "$REPEATS" -gt 0 ]] || bench_error "BAD_VALUE" "repeats"

EXTRACT="$ENGINE/scripts/extract-commandcode-telemetry.sh"
STRIP="$ENGINE/scripts/strip-benchmark-diff.sh"
AGG="$ENGINE/scripts/aggregate-benchmark-runs.sh"
INIT="$ENGINE/init.sh"
for f in "$EXTRACT" "$STRIP" "$AGG" "$INIT"; do
    [[ -f "$f" ]] || bench_error "UNREADABLE" "$f"
done

# Preflight (always runs; --preflight-only stops here)
command -v command-code >/dev/null 2>&1 || bench_error "PREFLIGHT" "command-code not on PATH"
CC_VERSION="$(command-code --version 2>/dev/null | tail -1 || echo unknown)"
if ! command-code --list-models 2>/dev/null | grep -qF "$MODEL"; then
    bench_error "PREFLIGHT" "model not in --list-models: $MODEL"
fi
TASTE="${HOME}/.commandcode/taste/taste.md"
if [[ -s "$TASTE" ]]; then
    bench_error "PREFLIGHT" "taste file is not empty ($TASTE) — clear or snapshot it first; taste learning during a batch makes arms unequal"
fi
mkdir -p "$OUT/grading" "$OUT/runs"
printf '%s\n' "$ENGINE" > "$OUT/engine-path.txt"
{
    echo "command-code: $CC_VERSION"
    echo "engine: $(git -C "$ENGINE" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "seed: $(git -C "$SEED" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "model: $MODEL"
    echo "profile: $PROFILE"
    echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$OUT/env.txt"
cp "$TASTE" "$OUT/taste.md.snapshot" 2>/dev/null || true
printf 'PREFLIGHT|OK|engine=%s|seed=%s|model=%s|cli=%s\n' \
    "$(git -C "$ENGINE" rev-parse --short HEAD 2>/dev/null || echo '?')" \
    "$(git -C "$SEED" rev-parse --short HEAD 2>/dev/null || echo '?')" \
    "$MODEL" "$CC_VERSION"
if [[ "$PREFLIGHT_ONLY" -eq 1 ]]; then
    exit 0
fi

parse_field() {
    # parse_field <file> <label>: the single-line field value, backticks stripped
    local line
    line="$(grep -m1 -- "^- \*\*${2}\*\*: " "$1" || true)"
    [[ -n "$line" ]] || return 1
    line="${line#- \*\*${2}\*\*: }"
    line="${line%$'\r'}"
    line="${line#\`}"
    line="${line%\`}"
    printf '%s' "$line"
}

: > "$OUT/manifest.tsv"
MANIFEST="$OUT/manifest.tsv"
printf 'scenario\tarm\trundir\ttranscript\trecord\tdiff\tstripped\tverify\n' >> "$MANIFEST"
printf 'Error:|error:|ERROR:|No tool named|command not found|Traceback|Exception|Permission denied|FAILED|npm ERR!' > "$OUT/error-patterns.txt"
declare -a RUN_SCENARIOS=()
RUNS=0

IFS=',' read -r -a TASKFILES <<< "$TASKS_CSV"
for tf in "${TASKFILES[@]}"; do
    tf="$(printf '%s' "$tf" | tr -d '[:space:]')"
    [[ -f "$tf" ]] || bench_error "UNREADABLE" "$tf"
    taskid="$(parse_field "$tf" "Task ID")" || bench_error "BAD_TASK" "$tf (Task ID)"
    level="$(parse_field "$tf" "Level")" || bench_error "BAD_TASK" "$tf (Level)"
    promptline="$(grep -m1 -- '^- \*\*Prompt\*\*: ' "$tf" || true)"
    [[ -n "$promptline" ]] || bench_error "BAD_TASK" "$tf (Prompt)"
    promptline="${promptline%$'\r'}"
    prompt="${promptline#- \*\*Prompt\*\*: }"
    # value shape: `"..."` (backtick, quote, text, quote, backtick)
    prompt="${prompt#\`}"
    prompt="${prompt%\"\`}"   # closing quote+backtick pair
    prompt="${prompt%\"}"     # ...or a bare closing quote when unbackticked
    prompt="${prompt#\"}"
    [[ -n "$prompt" && "$prompt" != *'\`' && "$prompt" != *'"' ]] \
        || bench_error "BAD_TASK" "$tf (prompt value malformed)"
    setup="$(parse_field "$tf" "Setup" || true)"
    [[ -z "$setup" || "$setup" == "None" ]] && setup=""
    verify_cmd="$(parse_field "$tf" "Verify" || true)"
    [[ -z "$verify_cmd" || "$verify_cmd" == "None" ]] && verify_cmd=""

    for arm in promptkit_os bare; do
        for r in $(seq 1 "$REPEATS"); do
            scenario="${taskid}-${arm}-r${r}"
            rundir="$OUT/runs/$scenario"
            rm -rf "$rundir"
            git clone --quiet "$SEED" "$rundir" || bench_error "CLONE_FAILED" "$scenario"
            if [[ -n "$setup" ]]; then
                ( cd "$rundir" && bash -c "$setup" ) || bench_error "SETUP_FAILED" "$scenario"
            fi
            if [[ "$arm" == "promptkit_os" ]]; then
                PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 \
                    bash "$INIT" "--$PROFILE" --host=agents "$rundir" \
                    > "$OUT/runs/$scenario-init.log" 2>&1 || bench_error "INIT_FAILED" "$scenario"
            fi
            # Anchor the grading diff to the SEED commit: under --yolo the agent
            # may commit, and `git diff --cached` against a moved HEAD would
            # return an empty diff, silently losing every committed change.
            seed_sha="$(git -C "$rundir" rev-parse HEAD)"
            th1="$(sha256sum "$TASTE" 2>/dev/null | cut -d' ' -f1 || echo none)"
            set +e
            ( cd "$rundir" && timeout "$TIMEOUT" command-code -t --yolo --tools-all \
                --skip-onboarding --no-auto-update -m "$MODEL" --max-turns "$MAXTURNS" \
                -p "$prompt" ) > "$OUT/runs/$scenario/session.log" 2>&1
            rc=$?
            set -e
            th2="$(sha256sum "$TASTE" 2>/dev/null | cut -d' ' -f1 || echo none2)"
            [[ "$th1" == "$th2" ]] || bench_error "TASTE_CHANGED" "$scenario"
            ( cd "$rundir" && git add -A && git diff --cached --no-color "$seed_sha" > "$rundir-run.diff"; git reset -q ) \
                || bench_error "DIFF_FAILED" "$scenario"
            # Optional arm-neutral verification evidence, produced by the HARNESS
            # (not the agent) so the grader never needs the arm-revealing
            # session log for evidence-gated rubric items. The packet always
            # carries the command's exit code first (verify_exit=), so a
            # successful-but-silent command still yields gradeable evidence.
            verify_out=""
            if [[ -n "$verify_cmd" ]]; then
                verify_out="$OUT/runs/$scenario/verify.txt"
                vrc=0
                ( cd "$rundir" && bash -c "$verify_cmd" ) > "$verify_out.raw" 2>&1 || vrc=$?
                { printf 'verify_exit=%s\n' "$vrc"; cat "$verify_out.raw"; } > "$verify_out"
                rm -f "$verify_out.raw"
            fi
            slug="$(printf '%s' "$rundir" | sed 's#^/##; s#/#-#g')"
            transcript="$(ls -t "${HOME}/.commandcode/projects/${slug}/"*.jsonl 2>/dev/null | grep -v checkpoints | head -1 || true)"
            [[ -n "$transcript" ]] || bench_error "TRANSCRIPT_MISSING" "$scenario"
            record="$OUT/runs/$scenario/record.json"
            bash "$EXTRACT" "$transcript" --scenario-id="$scenario" --condition="$arm" \
                --accepted=false --error-patterns="$(cat "$OUT/error-patterns.txt")" \
                > "$record" 2>>"$OUT/runs/$scenario/extract.log" || bench_error "EXTRACT_FAILED" "$scenario"
            stripped="$OUT/runs/$scenario/run.stripped.diff"
            if [[ -s "$rundir-run.diff" ]]; then
                bash "$STRIP" "$rundir-run.diff" > "$stripped" 2>>"$OUT/runs/$scenario/strip.log" \
                    || bench_error "STRIP_FAILED" "$scenario"
            else
                # A no-op run (max-turns hit, early failure) stays gradeable as
                # accepted=false; an empty packet is the honest artifact.
                : > "$stripped"
            fi
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$scenario" "$arm" "$rundir" "$transcript" "$record" "$rundir-run.diff" "$stripped" "${verify_out:-}" >> "$OUT/manifest.tsv"
            RUN_SCENARIOS+=("$scenario")
            RUNS=$((RUNS + 1))
            printf 'RUNDONE|%s|arm=%s|level=%s|cli_exit=%s\n' "$scenario" "$arm" "$level" "$rc"
            if [[ "$rc" -eq 8 ]]; then
                printf 'BENCH|WARN|MAX_TURNS_HIT|%s\n' "$scenario" >&2
            fi
        done
    done
done

# Blind-id assignment happens AFTER all runs, by shuffle across the whole
# batch, so id order carries no arm information (a sequential per-run id would
# leak the arm by parity). BENCH_SHUFFLE_SEED makes the shuffle reproducible.
if [[ -n "${BENCH_SHUFFLE_SEED:-}" ]]; then
    RANDOM="$BENCH_SHUFFLE_SEED"
fi
n=${#RUN_SCENARIOS[@]}
for ((i = n - 1; i > 0; i--)); do
    j=$((RANDOM % (i + 1)))
    tmp="${RUN_SCENARIOS[$i]}"
    RUN_SCENARIOS[$i]="${RUN_SCENARIOS[$j]}"
    RUN_SCENARIOS[$j]="$tmp"
done
: > "$OUT/grading/key.csv"
printf 'blind,scenario\n' >> "$OUT/grading/key.csv"
idx=1
for scenario in "${RUN_SCENARIOS[@]}"; do
    blind="$(printf 'B%03d' "$idx")"
    row="$(grep -m1 -- "^${scenario}$(printf '\t')" "$MANIFEST" || true)"
    [[ -n "$row" ]] || bench_error "MANIFEST_ROW_MISSING" "$scenario"
    sdiff="$(printf '%s' "$row" | cut -f7)"
    verify_out="$(printf '%s' "$row" | cut -f8)"
    cp "$sdiff" "$OUT/grading/$blind.diff"
    if [[ -n "$verify_out" && -f "$verify_out" ]]; then
        cp "$verify_out" "$OUT/grading/$blind.verify.txt"
    fi
    printf '%s,%s\n' "$blind" "$scenario" >> "$OUT/grading/key.csv"
    # The blind->scenario mapping lives ONLY in key.csv: printing it to the
    # terminal would hand a single operator+grader the key in scrollback
    # right before grading.
    printf 'BLIND|%s\n' "$blind"
    idx=$((idx + 1))
done

printf 'BATCH|OK|runs=%d|out=%s\n' "$RUNS" "$OUT"
cat <<'EOF'
Next steps (operator):
1. Grade each $OUT/grading/B*.diff (+ B*.verify.txt when present) against the
   task rubric WITHOUT reading $OUT/grading/key.csv; write
   $OUT/grading/grading.tsv as
   blind_id<TAB>rubric_passed<TAB>rubric_total<TAB>accepted(true|false).
2. Finalize (translates blind ids via the key, re-extracts records with the
   graded acceptance, then aggregates with the sheet as cross-check):
   bash benchmarks/run-ab-benchmark.sh --finalize "$OUT" --grading "$OUT/grading/grading.tsv"
EOF
