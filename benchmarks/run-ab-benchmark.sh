#!/usr/bin/env bash
# PromptKit OS A/B Benchmark Orchestrator (operator-local)
# Implements the protocol in benchmarks/README.md: paired runs of PromptKit OS
# (directive installed via the engine's init.sh) versus bare Command Code over
# a frozen task batch, with blind grading packets and CPAC aggregation through
# the scripts/ pipeline.
#
# OPERATOR-LOCAL BY DESIGN: this script drives a live, subscription-backed CLI
# (command-code) and spends the operator's plan. It is not CI-run and has no
# PowerShell twin — the twin-parity rule binds repository behavior surfaces,
# while every pure, reusable piece this script calls (extractor, stripper,
# aggregator, scorer) is a twin-tested scripts/ tool. Linux/WSL only (GNU
# timeout). Raw transcripts stay under ~/.commandcode and are never committed.
#
# Modes:
#   run batch:   run-ab-benchmark.sh --engine E --seed S --tasks a.md,b.md \
#                  --model M --out DIR [--max-turns N] [--timeout S]
#                  [--repeats N] [--profile lite|balanced]
#   dry run:     ... --preflight-only   (validates environment, spends nothing)
#   finalize:    run-ab-benchmark.sh --finalize DIR --grading DIR/grading/grading.tsv
#                (re-extracts each run with the grading sheet's accepted flag,
#                 then runs the aggregator with the sheet as cross-check)
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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --engine=*) ENGINE="${1#--engine=}" ;;
        --engine) ENGINE="$2"; shift ;;
        --seed=*) SEED="${1#--seed=}" ;;
        --seed) SEED="$2"; shift ;;
        --tasks=*) TASKS_CSV="${1#--tasks=}" ;;
        --tasks) TASKS_CSV="$2"; shift ;;
        --model=*) MODEL="${1#--model=}" ;;
        --model) MODEL="$2"; shift ;;
        --out=*) OUT="${1#--out=}" ;;
        --out) OUT="$2"; shift ;;
        --max-turns=*) MAXTURNS="${1#--max-turns=}" ;;
        --max-turns) MAXTURNS="$2"; shift ;;
        --timeout=*) TIMEOUT="${1#--timeout=}" ;;
        --timeout) TIMEOUT="$2"; shift ;;
        --repeats=*) REPEATS="${1#--repeats=}" ;;
        --repeats) REPEATS="$2"; shift ;;
        --profile=*) PROFILE="${1#--profile=}" ;;
        --profile) PROFILE="$2"; shift ;;
        --grading=*) GRADING="${1#--grading=}" ;;
        --grading) GRADING="$2"; shift ;;
        --preflight-only) PREFLIGHT_ONLY=1 ;;
        --finalize) FINALIZE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) bench_error "UNKNOWN_FLAG" "$1" ;;
    esac
    shift
done

if [[ "$FINALIZE" -eq 1 ]]; then
    # ---- finalize mode: re-extract with grading-accepted flags, aggregate ----
    [[ -n "$OUT" && -d "$OUT" ]] || bench_error "UNREADABLE" "$OUT"
    [[ -n "$GRADING" && -s "$GRADING" ]] || bench_error "UNREADABLE" "$GRADING"
    ENGINE="${ENGINE:-$OUT/engine-path.txt}"
    EXTRACT="$ENGINE/scripts/extract-commandcode-telemetry.sh"
    AGG="$ENGINE/scripts/aggregate-benchmark-runs.sh"
    [[ -f "$EXTRACT" ]] || bench_error "UNREADABLE" "$EXTRACT"
    MANIFEST="$OUT/manifest.tsv"
    [[ -s "$MANIFEST" ]] || bench_error "UNREADABLE" "$MANIFEST"
    RECORDS=()
    while IFS=$'\t' read -r scenario arm rundir transcript record diff stripped; do
        [[ -z "$scenario" || "$scenario" == "scenario" ]] && continue
        acc="false"
        if grep -q "^${scenario}$(printf '\t')" "$GRADING"; then
            row="$(grep "^${scenario}$(printf '\t')" "$GRADING" | head -1)"
            acc="$(printf '%s' "$row" | cut -f4)"
        fi
        [[ "$acc" == "true" || "$acc" == "false" ]] || bench_error "BAD_GRADING" "$scenario"
        newtranscript="$(mktemp "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/bench-rex.XXXXXX")"
        bash "$EXTRACT" "$transcript" --scenario-id="$scenario" --condition="$arm" --accepted="$acc" \
            --error-patterns="$(cat "$OUT/error-patterns.txt" 2>/dev/null || echo "")" \
            > "$record" 2>> "$OUT/runs/$scenario/extract.log" || bench_error "EXTRACT_FAILED" "$scenario"
        rm -f "$newtranscript"
        RECORDS+=("$record")
    done < "$MANIFEST"
    bash "$AGG" --grading "$GRADING" "${RECORDS[@]}"
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
    line="${line#\`}"
    line="${line%\`}"
    printf '%s' "$line"
}

: > "$OUT/manifest.tsv"
printf 'scenario\tarm\trundir\ttranscript\trecord\tdiff\tstripped\n' >> "$OUT/manifest.tsv"
: > "$OUT/grading/key.csv"
printf 'blind,scenario\n' >> "$OUT/grading/key.csv"
printf 'Error:|error:|ERROR:|No tool named|command not found|Traceback|Exception|Permission denied|FAILED|npm ERR!' > "$OUT/error-patterns.txt"
BLINDN=1
RUNS=0

IFS=',' read -r -a TASKFILES <<< "$TASKS_CSV"
for tf in "${TASKFILES[@]}"; do
    tf="$(printf '%s' "$tf" | tr -d '[:space:]')"
    [[ -f "$tf" ]] || bench_error "UNREADABLE" "$tf"
    taskid="$(parse_field "$tf" "Task ID" | tr -d '\`')" || bench_error "BAD_TASK" "$tf (Task ID)"
    level="$(parse_field "$tf" "Level" | tr -d '\`')" || bench_error "BAD_TASK" "$tf (Level)"
    promptline="$(grep -m1 -- '^- \*\*Prompt\*\*: ' "$tf" || true)"
    [[ -n "$promptline" ]] || bench_error "BAD_TASK" "$tf (Prompt)"
    prompt="${promptline#- \*\*Prompt\*\*: }"
    prompt="${prompt#\`}"; prompt="${prompt% \`}"
    prompt="${prompt#\"}"; prompt="${prompt%\"}"
    [[ -n "$prompt" ]] || bench_error "BAD_TASK" "$tf (empty prompt)"
    setup="$(parse_field "$tf" "Setup" | tr -d '\`' || true)"
    [[ -z "$setup" || "$setup" == "None" ]] && setup=""

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
            th1="$(sha256sum "$TASTE" 2>/dev/null | cut -d' ' -f1 || echo none)"
            set +e
            ( cd "$rundir" && timeout "$TIMEOUT" command-code -t --yolo --tools-all \
                --skip-onboarding --no-auto-update -m "$MODEL" --max-turns "$MAXTURNS" \
                -p "$prompt" ) > "$OUT/runs/$scenario/session.log" 2>&1
            rc=$?
            set -e
            th2="$(sha256sum "$TASTE" 2>/dev/null | cut -d' ' -f1 || echo none2)"
            [[ "$th1" == "$th2" ]] || bench_error "TASTE_CHANGED" "$scenario"
            ( cd "$rundir" && git add -A && git diff --cached --no-color > "$rundir-run.diff"; git reset -q ) \
                || bench_error "DIFF_FAILED" "$scenario"
            slug="$(printf '%s' "$rundir" | sed 's#^/##; s#/#-#g')"
            transcript="$(ls -t "${HOME}/.commandcode/projects/${slug}/"*.jsonl 2>/dev/null | grep -v checkpoints | head -1 || true)"
            [[ -n "$transcript" ]] || bench_error "TRANSCRIPT_MISSING" "$scenario"
            record="$OUT/runs/$scenario/record.json"
            bash "$EXTRACT" "$transcript" --scenario-id="$scenario" --condition="$arm" \
                --accepted=false --error-patterns="$(cat "$OUT/error-patterns.txt")" \
                > "$record" 2>> "$OUT/runs/$scenario/extract.log" || bench_error "EXTRACT_FAILED" "$scenario"
            stripped="$OUT/runs/$scenario/run.stripped.diff"
            bash "$STRIP" "$rundir-run.diff" > "$stripped" 2>> "$OUT/runs/$scenario/strip.log" \
                || bench_error "STRIP_FAILED" "$scenario"
            blind="$(printf 'B%03d' "$BLINDN")"
            BLINDN=$((BLINDN + 1))
            cp "$stripped" "$OUT/grading/$blind.diff"
            printf '%s,%s\n' "$blind" "$scenario" >> "$OUT/grading/key.csv"
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$scenario" "$arm" "$rundir" "$transcript" "$record" "$rundir-run.diff" "$stripped" >> "$OUT/manifest.tsv"
            RUNS=$((RUNS + 1))
            printf 'RUNDONE|%s|arm=%s|level=%s|cli_exit=%s|blind=%s\n' \
                "$scenario" "$arm" "$level" "$rc" "$blind"
            if [[ "$rc" -eq 8 ]]; then
                printf 'BENCH|WARN|MAX_TURNS_HIT|%s\n' "$scenario" >&2
            fi
        done
    done
done

printf 'BATCH|OK|runs=%d|out=%s\n' "$RUNS" "$OUT"
cat <<'EOF'
Next steps (operator):
1. Grade each $OUT/grading/B*.diff against the task rubric WITHOUT reading
   $OUT/grading/key.csv; write $OUT/grading/grading.tsv as
   scenario<TAB>rubric_passed<TAB>rubric_total<TAB>accepted(true|false).
2. Finalize (re-extracts records with the graded acceptance, then aggregates):
   bash benchmarks/run-ab-benchmark.sh --finalize "$OUT" --grading "$OUT/grading/grading.tsv"
EOF
