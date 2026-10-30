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
# runs of the batch; verify output is scrubbed of the run directory, output
# root, and scenario id so a Verify command that prints its cwd cannot reveal
# the arm. The blind->scenario mapping lives in grading/key.csv and is
# consulted only by --finalize. The grading sheet is keyed by BLIND ID.
#
# Order and isolation: the schedule is derived from two pre-registered,
# required seeds. --order-seed orders task blocks (SHA-256 digest of the seed
# and the task id) and the arm x repeat cells inside each block; --shuffle-seed
# seeds the whole-batch blind-id shuffle. The complete plan is written to
# $OUT/order.tsv before the preflight exit and before the first session, then
# executed exactly as written. Before any spend an isolation guard fails closed
# when the seed carries an agent-instruction surface or a heyloey reference, or
# when the host HOME/PATH carries global instructions, skills, hooks, MCP
# servers, or heyloey (Phase 3b protocol 3).
#
# Treatment arm: init.sh renders the kit path as ".promptkit" whenever the
# engine sits outside the project, and copies nothing itself, so the driver
# materializes the engine's consumer surface there before installing
# (workflows, protocols, templates, scripts, and the two init doors) and keeps
# it out of the clone's index. benchmarks/, docs/, and scripts/tests/ are
# deliberately absent: they hold the frozen rubrics, the Verify probes, the
# methodology, and fixtures that name the slate, and a blind arm must read none
# of them. The staged tree is asserted as a complete courier install before the
# session starts.
#
# Modes:
#   run batch:   run-ab-benchmark.sh --engine E --seed S --tasks a.md,b.md \
#                  --model M --out DIR --order-seed N --shuffle-seed N
#                  [--max-turns N] [--repeats N] [--profile lite|balanced]
#   dry run:     ... --preflight-only   (validates environment, spends nothing)
#   finalize:    run-ab-benchmark.sh --finalize DIR --grading DIR/grading/grading.tsv
#                (translates the blind-id sheet via key.csv, re-extracts each
#                 run with its graded accepted flag, then runs the aggregator
#                 with a scenario-keyed sheet as cross-check)
set -euo pipefail
export LC_ALL=C

ENGINE="" SEED="" TASKS_CSV="" MODEL="" OUT="" MAXTURNS=40 TIMEOUT=900 REPEATS=1 PROFILE=balanced PREFLIGHT_ONLY=0 FINALIZE=0 GRADING="" ORDER_SEED="" SHUFFLE_SEED="${BENCH_SHUFFLE_SEED:-}"

usage() {
    echo "Usage: run-ab-benchmark.sh --engine <promptkit-repo> --seed <seed-repo>"
    echo "       --tasks <task.md,...> --model <model> --out <dir>"
    echo "       [--max-turns N] [--timeout S] [--repeats N] [--profile lite|balanced]"
    echo "       --order-seed N   (required: pre-registered task/arm/repeat order)"
    echo "       --shuffle-seed N (required: pre-registered blind-id shuffle)"
    echo "       [--preflight-only]"
    echo "       run-ab-benchmark.sh --finalize <dir> --grading <dir/grading/grading.tsv>"
}

bench_error() {
    printf 'BENCH|ERROR|%s|%s\n' "$1" "$2" >&2
    exit 2
}

slugify_run_path() {
    # Command Code records transcripts under @sindresorhus/slugify(cwd):
    # lowercase, path separators and underscores become hyphens, repeated
    # separators collapse. The driver owns this path alphabet, so an ASCII
    # mirror is sufficient; revisit if run paths may contain non-ASCII text.
    printf '%s' "$1" \
        | sed 's#^/##; s#/#-#g' \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's#_#-#g; s#[^a-z0-9-]#-#g; s#-\{2,\}#-#g; s#^-##; s#-$##'
}

scrub_verify_output() {
    # scrub_verify_output <rundir> <out> <scenario> <file>
    # The verify command runs inside the clone, so tools that print their cwd
    # (validate-references.sh does) would otherwise put the arm-bearing
    # scenario id into the blind packet. Replace the absolute run paths before
    # the packet is written; the exit code is prepended by the caller.
    local scrubbed
    scrubbed="$(cat "$4")"
    scrubbed="${scrubbed//"$1"/<rundir>}"
    scrubbed="${scrubbed//"$2"/<out>}"
    scrubbed="${scrubbed//"$3"/<scenario>}"
    printf '%s\n' "$scrubbed"
}

need_value() {
    # need_value <flag> : fail closed when a value-taking flag has no operand
    [[ "$#" -ge 2 && -n "$2" ]] || bench_error "MISSING_VALUE" "$1"
}

# The single session invocation both arms run. Parity bindings live here and
# nowhere else: verbatim prompt bytes from the card, the same model, `--yolo`
# (permission mode), `--tools-all` (`-p` withholds tools by default), the same
# `--max-turns` cap, `--skip-onboarding`, and the updater disabled so the CLI
# cannot replace itself mid-batch. The caller's shell applies the per-session
# `timeout`, so it is not an argv element.
#
# `arm` is accepted only so the preflight check and the session loop share one
# signature; the body must never read it. `guard_cross_arm` renders both arms
# through this function and fails closed on any byte difference, so an
# arm-conditional token added here is refused before a session starts.
session_argv() {
    # session_argv <task-index> <arm>
    local task_idx="$1"
    : "${2:-}"
    printf '%s\0' command-code \
        -t --yolo --tools-all --skip-onboarding --no-auto-update \
        -m "$MODEL" --max-turns "$MAXTURNS" \
        -p "${TASK_PROMPTS[$task_idx]}"
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
        --order-seed=*) ORDER_SEED="${1#--order-seed=}" ;;
        --order-seed) need_value "$1" "${2:-}"; ORDER_SEED="$2"; shift ;;
        --shuffle-seed=*) SHUFFLE_SEED="${1#--shuffle-seed=}" ;;
        --shuffle-seed) need_value "$1" "${2:-}"; SHUFFLE_SEED="$2"; shift ;;
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
# The order seed is the batch's pre-registration. An unseeded run silently
# falls back to the fixed promptkit_os-then-bare order that Phase 3b exists to
# remove, so the driver refuses to guess one.
if [[ ! "$ORDER_SEED" =~ ^[0-9]+$ ]]; then
    bench_error "MISSING" "order-seed (pre-register one; see benchmarks/PHASE-3B-PROTOCOL.md section 2.2)"
fi
# The blind-id shuffle is part of the pre-registration too. An unrecorded RNG
# seed makes the packet mapping unreproducible, so --shuffle-seed is required
# and recorded alongside --order-seed (BENCH_SHUFFLE_SEED remains a fallback).
if [[ ! "$SHUFFLE_SEED" =~ ^[0-9]+$ ]]; then
    bench_error "MISSING" "shuffle-seed (pre-register one; see benchmarks/PHASE-3B-PROTOCOL.md section 2.2)"
fi

EXTRACT="$ENGINE/scripts/extract-commandcode-telemetry.sh"
STRIP="$ENGINE/scripts/strip-benchmark-diff.sh"
AGG="$ENGINE/scripts/aggregate-benchmark-runs.sh"
INIT="$ENGINE/init.sh"
for f in "$EXTRACT" "$STRIP" "$AGG" "$INIT"; do
    [[ -f "$f" ]] || bench_error "UNREADABLE" "$f"
done

# ---- isolation guard (benchmarks/PHASE-3B-PROTOCOL.md section 3) ----------
# A "neutral-ish" batch is not a batch: any instruction surface, skill, hook,
# MCP server, or heyloey reference can make the arms unequal or hand PromptKit
# to the bare arm. Every check fails closed before a session starts; there is no
# override flag, so an operator neutralizes the seed or uses an isolated HOME.
guard_stop() {
    bench_error "PREFLIGHT" "$1 isolation: $2"
}

guard_seed() {
    local hit
    # core.quotepath=false keeps non-ASCII paths unquoted, so a root-level
    # surface such as a .claude/ file with a non-ASCII name cannot slip past
    # the anchors below.
    hit="$(git -c core.quotepath=false -C "$SEED" ls-files 2>/dev/null \
        | grep -E -i -m1 '(^|/)(AGENTS\.md|CLAUDE\.md|PROMPTKIT\.md|GEMINI\.md|\.cursorrules|\.windsurfrules|\.clinerules|copilot-instructions\.md)$|(^|/)(\.cursor/rules|\.claude|\.promptkit|\.github/instructions)/' \
        || true)"
    [[ -z "$hit" ]] || guard_stop "seed" "tracked instruction surface: $hit"
    hit="$(git -C "$SEED" grep -I -i -l -e heyloey -- . 2>/dev/null | head -1 || true)"
    [[ -z "$hit" ]] || guard_stop "seed" "heyloey reference: $hit"
    [[ -z "$(git -C "$SEED" status --porcelain 2>/dev/null)" ]] \
        || guard_stop "seed" "working tree is dirty, so the recorded seed SHA would not describe the batch"
}

json_key_nonempty() {
    # json_key_nonempty <file> <key>: true only when the key is present and its
    # value is neither {} nor []. Whitespace is stripped first so a pretty-printed
    # empty object passes and a one-line empty object cannot slip through.
    local slim
    slim="$(tr -d '[:space:]' < "$1")"
    [[ "$slim" == *"\"$2\":{}"* || "$slim" == *"\"$2\":[]"* ]] && return 1
    [[ "$slim" == *"\"$2\":"* ]]
}

guard_host() {
    local rel path slim hp
    path=""
    for rel in AGENTS.md CLAUDE.md .cursorrules .github/copilot-instructions.md \
               .cursor/rules .claude .commandcode/AGENTS.md .commandcode/CLAUDE.md \
               .commandcode/skills; do
        if [[ -f "$HOME/$rel" || -L "$HOME/$rel" ]]; then
            path="$HOME/$rel"
            break
        fi
        if [[ -d "$HOME/$rel" && -n "$(ls -A "$HOME/$rel" 2>/dev/null)" ]]; then
            path="$HOME/$rel/"
            break
        fi
    done
    [[ -z "$path" ]] || guard_stop "host" "global instruction surface: $path"
    if [[ -f "$HOME/.commandcode/mcp.json" ]] \
        && json_key_nonempty "$HOME/.commandcode/mcp.json" mcpServers; then
        guard_stop "host" "MCP servers configured: $HOME/.commandcode/mcp.json"
    fi
    if [[ -f "$HOME/.commandcode/trusted-hooks.json" ]]; then
        slim="$(tr -d '[:space:]' < "$HOME/.commandcode/trusted-hooks.json")"
        [[ -z "$slim" || "$slim" == "{}" || "$slim" == "[]" ]] \
            || guard_stop "host" "hooks configured: $HOME/.commandcode/trusted-hooks.json"
    fi
    if [[ -f "$HOME/.commandcode/settings.json" ]] \
        && json_key_nonempty "$HOME/.commandcode/settings.json" hooks; then
        guard_stop "host" "hooks configured: $HOME/.commandcode/settings.json"
    fi
    if [[ -f "$HOME/.commandcode/settings.json" ]] \
        && json_key_nonempty "$HOME/.commandcode/settings.json" mcpServers; then
        guard_stop "host" "MCP servers configured: $HOME/.commandcode/settings.json"
    fi
    hp="$(command -v heyloey 2>/dev/null || true)"
    [[ -z "$hp" ]] || guard_stop "host" "heyloey on PATH: $hp"
}

# Cross-arm equality (benchmarks/PHASE-3B-PROTOCOL.md Appendix D): both arms
# must see the same prompt bytes, tools, permission mode, max turns, and
# timeout. Two properties are checked, and both fail closed:
#   1. the materialized plan is balanced - every task gets exactly one cell per
#      arm per repeat, so both arms run the same slate;
#   2. the one launch builder renders byte-identical argv for both arms, with
#      the card's prompt verbatim and each parity binding present exactly once.
# The session loop executes that same rendering, and <out>/crossarm.txt records
# a prompt and argv SHA-256 per task as the evidence the checklist cites.
crossarm_stop() {
    bench_error "PREFLIGHT" "cross-arm equality: $1"
}

guard_cross_arm() {
    local i arm j seen flag tid prompt_sha argv_sha mt_ok
    local -a render_pk=() render_bare=()
    local -A cells=()
    local tmp="$OUT/crossarm.txt.tmp"

    while IFS=$'\t' read -r _pos tid a _r; do
        [[ -n "${tid:-}" ]] || continue
        cells["$tid|$a"]=$(( ${cells["$tid|$a"]:-0} + 1 ))
    done < <(printf '%s\n' "${PLAN_LINES[@]}")

    printf 'task_id\tprompt_sha256\targv_sha256\n' > "$tmp"
    for i in "${!TASK_IDS[@]}"; do
        tid="${TASK_IDS[$i]}"
        for arm in promptkit_os bare; do
            [[ "${cells["$tid|$arm"]:-0}" -eq "$REPEATS" ]] || crossarm_stop \
                "plan gives $arm ${cells["$tid|$arm"]:-0} cell(s) for $tid (expected $REPEATS)"
        done
        mapfile -d '' -t render_pk < <(session_argv "$i" promptkit_os)
        mapfile -d '' -t render_bare < <(session_argv "$i" bare)
        [[ "${#render_pk[@]}" -eq "${#render_bare[@]}" ]] || crossarm_stop \
            "invocation length differs for $tid (${#render_pk[@]} vs ${#render_bare[@]} arguments)"
        for ((j = 0; j < ${#render_pk[@]}; j++)); do
            [[ "${render_pk[$j]}" == "${render_bare[$j]}" ]] || crossarm_stop \
                "invocation argument $((j + 1)) differs for $tid"
        done
        [[ "${render_pk[${#render_pk[@]}-1]}" == "${TASK_PROMPTS[$i]}" ]] || crossarm_stop \
            "prompt bytes for $tid are not the task card's prompt"
        for flag in --yolo --tools-all --max-turns; do
            seen=0
            for ((j = 0; j < ${#render_pk[@]}; j++)); do
                if [[ "${render_pk[$j]}" == "$flag" ]]; then seen=$((seen + 1)); fi
            done
            [[ "$seen" -eq 1 ]] || crossarm_stop \
                "$flag appears $seen time(s) in the invocation (expected 1)"
        done
        mt_ok=0
        for ((j = 0; j < ${#render_pk[@]} - 1; j++)); do
            if [[ "${render_pk[$j]}" == "--max-turns" && "${render_pk[$((j + 1))]}" == "$MAXTURNS" ]]; then
                mt_ok=$((mt_ok + 1))
            fi
        done
        [[ "$mt_ok" -eq 1 ]] || crossarm_stop \
            "--max-turns is not set to $MAXTURNS exactly once"
        prompt_sha="$(printf '%s' "${TASK_PROMPTS[$i]}" | sha256sum | cut -d' ' -f1)"
        argv_sha="$(printf '%s\0' "${render_pk[@]}" | sha256sum | cut -d' ' -f1)"
        printf '%s\t%s\t%s\n' "$tid" "$prompt_sha" "$argv_sha" >> "$tmp"
    done

    {
        printf 'flags: -t --yolo --tools-all --skip-onboarding --no-auto-update\n'
        printf 'permission_mode: yolo\n'
        printf 'tools: all\n'
        printf 'model: %s\n' "$MODEL"
        printf 'max_turns: %s\n' "$MAXTURNS"
        printf 'timeout: %s\n' "$TIMEOUT"
        printf 'arms: promptkit_os,bare\n'
        printf 'repeats: %s\n' "$REPEATS"
        printf 'cells: %s\n' "$PLAN_COUNT"
        printf 'promptkit_os_cells: %s\n' "$((PLAN_COUNT / 2))"
        printf 'bare_cells: %s\n' "$((PLAN_COUNT / 2))"
        printf 'verdict: identical\n'
    } >> "$tmp"
    mv "$tmp" "$OUT/crossarm.txt"
    printf 'CROSSARM|OK|tasks=%s|arms=2|cells=%s|max_turns=%s|timeout=%s\n' \
        "${#TASK_IDS[@]}" "$PLAN_COUNT" "$MAXTURNS" "$TIMEOUT"
}

# Preflight checks (--preflight-only exits after the task slate is parsed and the
# complete schedule is written, so a dry run exercises those too)
command -v command-code >/dev/null 2>&1 || bench_error "PREFLIGHT" "command-code not on PATH"
CC_VERSION="$(command-code --version 2>/dev/null | tail -1 || echo unknown)"
# Capture the list before matching: `grep -q` exits at the first hit, and under
# `set -o pipefail` the CLI then dies of SIGPIPE (141), which reads as a failed
# lookup and aborts a valid preflight at random.
CC_MODELS="$(command-code --list-models 2>/dev/null || true)"
if [[ "$CC_MODELS" != *"$MODEL"* ]]; then
    bench_error "PREFLIGHT" "model not in --list-models: $MODEL"
fi
TASTE="${HOME}/.commandcode/taste/taste.md"
if [[ -s "$TASTE" ]]; then
    bench_error "PREFLIGHT" "taste file is not empty ($TASTE) — clear or snapshot it first; taste learning during a batch makes arms unequal"
fi
guard_seed
guard_host

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

IFS=',' read -r -a TASKFILES <<< "$TASKS_CSV"
TASK_IDS=()
TASK_LEVELS=()
TASK_PROMPTS=()
TASK_SETUPS=()
TASK_VERIFIES=()
declare -A SEEN_TASK_ID=()
for tf in "${TASKFILES[@]}"; do
    tf="$(printf '%s' "$tf" | tr -d '[:space:]')"
    [[ -f "$tf" ]] || bench_error "UNREADABLE" "$tf"
    taskid="$(parse_field "$tf" "Task ID")" || bench_error "BAD_TASK" "$tf (Task ID)"
    [[ -z "${SEEN_TASK_ID[$taskid]:-}" ]] \
        || bench_error "DUPLICATE_TASK" "$taskid ($tf)"
    SEEN_TASK_ID[$taskid]=1
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
    TASK_IDS+=("$taskid")
    TASK_LEVELS+=("$level")
    TASK_PROMPTS+=("$prompt")
    TASK_SETUPS+=("$setup")
    TASK_VERIFIES+=("$verify_cmd")
done

# Seeded schedule. SHA-256 is the PRF: sorting digests of the pre-registered
# order seed plus the block/cell identity is the shuffle, so the plan is
# reproducible from the seed alone. Task blocks are shuffled first (carryover,
# cache, and time-of-day effects must not line up with task position); then the
# arm x repeat cells inside each block are shuffled, so neither arm is always
# first. The whole plan is materialized and written before the preflight exit,
# then executed as written, so a mid-batch stop cannot truncate the
# pre-registration to an attempted prefix.
order_hash_key() {
    printf '%s' "$1" | sha256sum | cut -c1-16
}

declare -a TASK_ORDER=()
while IFS=$'\t' read -r _order_key order_idx; do
    TASK_ORDER+=("$order_idx")
done < <(
    for i in "${!TASK_IDS[@]}"; do
        printf '%s\t%s\n' "$(order_hash_key "$ORDER_SEED|task|${TASK_IDS[$i]}")" "$i"
    done | sort -k1,1
)

declare -a PLAN_LINES=() PLAN_TASK_IDX=()
POSITION=0
for order_idx in "${TASK_ORDER[@]}"; do
    taskid="${TASK_IDS[$order_idx]}"
    CELLS=()
    while IFS=$'\t' read -r _order_key arm r; do
        CELLS+=("$arm:$r")
    done < <(
        for arm in promptkit_os bare; do
            for r in $(seq 1 "$REPEATS"); do
                printf '%s\t%s\t%s\n' \
                    "$(order_hash_key "$ORDER_SEED|cell|$taskid|$arm|$r")" "$arm" "$r"
            done
        done | sort -k1,1
    )
    for cell in "${CELLS[@]}"; do
        arm="${cell%%:*}"
        r="${cell##*:}"
        POSITION=$((POSITION + 1))
        PLAN_LINES+=("$POSITION"$'\t'"$taskid"$'\t'"$arm"$'\t'"$r")
        PLAN_TASK_IDX+=("$order_idx")
    done
done
PLAN_COUNT=${#PLAN_LINES[@]}

mkdir -p "$OUT/grading" "$OUT/runs"
{
    printf 'position\ttask_id\tarm\trepeat\n'
    printf '%s\n' "${PLAN_LINES[@]}"
} > "$OUT/order.tsv"
PLAN_SHA="$(sha256sum "$OUT/order.tsv" | cut -d' ' -f1)"

# Cross-arm equality is checked against the materialized plan, before the
# preflight exit, so a full run and a dry run assert the same invocation.
guard_cross_arm

printf '%s\n' "$ENGINE" > "$OUT/engine-path.txt"
{
    echo "command-code: $CC_VERSION"
    echo "engine: $(git -C "$ENGINE" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "seed: $(git -C "$SEED" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "model: $MODEL"
    echo "max_turns: $MAXTURNS"
    echo "timeout: $TIMEOUT"
    echo "profile: $PROFILE"
    echo "order_seed: $ORDER_SEED"
    echo "shuffle_seed: $SHUFFLE_SEED"
    echo "order_plan_sha256: $PLAN_SHA"
    echo "order_plan_rows: $PLAN_COUNT"
    echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$OUT/env.txt"
{
    echo "seed_commit: $(git -C "$SEED" rev-parse HEAD)"
    echo "seed_working_tree: clean"
    echo "seed_instruction_surfaces: none"
    echo "seed_heyloey_references: none"
    echo "host_home: $HOME"
    echo "host_instruction_surfaces: none"
    echo "host_mcp_servers: none"
    echo "host_hooks: none"
    echo "taste: empty"
    echo "cross_arm: identical (prompt/tools/permission_mode/max_turns/timeout)"
    echo "order_seed: $ORDER_SEED"
    echo "shuffle_seed: $SHUFFLE_SEED"
    echo "order_plan_sha256: $PLAN_SHA"
    echo "order_plan_rows: $PLAN_COUNT"
    echo "checked_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$OUT/isolation.txt"
cp "$TASTE" "$OUT/taste.md.snapshot" 2>/dev/null || true
printf 'ISOLATION|OK|seed=%s|home=%s\n' \
    "$(git -C "$SEED" rev-parse --short HEAD 2>/dev/null || echo '?')" "$HOME"
printf 'PREFLIGHT|OK|engine=%s|seed=%s|model=%s|cli=%s\n' \
    "$(git -C "$ENGINE" rev-parse --short HEAD 2>/dev/null || echo '?')" \
    "$(git -C "$SEED" rev-parse --short HEAD 2>/dev/null || echo '?')" \
    "$MODEL" "$CC_VERSION"
printf 'ORDER|PLAN|seed=%s|shuffle_seed=%s|rows=%s|sha256=%s|file=%s\n' \
    "$ORDER_SEED" "$SHUFFLE_SEED" "$PLAN_COUNT" "$PLAN_SHA" "$OUT/order.tsv"
if [[ "$PREFLIGHT_ONLY" -eq 1 ]]; then
    exit 0
fi

: > "$OUT/manifest.tsv"
MANIFEST="$OUT/manifest.tsv"
printf 'scenario\tarm\trundir\ttranscript\trecord\tdiff\tstripped\tverify\n' >> "$MANIFEST"
printf 'Error:|error:|ERROR:|No tool named|command not found|Traceback|Exception|Permission denied|FAILED|npm ERR!' > "$OUT/error-patterns.txt"
declare -a RUN_SCENARIOS=()
RUNS=0

# Stage the consumer runtime surface of the engine at <project>/.promptkit.
#
# init.sh derives KIT_DIR_REL from the relationship between the kit directory
# and the project root: with the engine outside the project (how this driver
# invokes it) the directive names ".promptkit", the courier layout. init.sh
# copies nothing, so the tree has to be materialized here or the directive
# under test points at a directory that does not exist.
#
# The copy is filtered on purpose. benchmarks/ holds the frozen rubrics and the
# Verify probes, docs/ holds the methodology, and scripts/tests/ holds fixtures
# that name the task slate: a blind arm able to read any of them is not blind.
# scripts/ itself stays, because the kit's quality gates and its install-door
# assert live there. No .git is copied, so the tree stays a courier install
# (scripts/check-setup-assert.sh classifies a non-git tree as such) and the
# parent repository never sees a nested repository.
stage_engine_kit() {
    local dest="$1" rel
    rm -rf "$dest" || return 1
    mkdir -p "$dest" || return 1
    for rel in init.sh init.ps1 LICENSE VERSION; do
        if [[ -f "$ENGINE/$rel" ]]; then
            cp -p "$ENGINE/$rel" "$dest/$rel" || return 1
        fi
    done
    for rel in workflows protocols templates scripts; do
        if [[ -d "$ENGINE/$rel" ]]; then
            cp -Rp "$ENGINE/$rel" "$dest/$rel" || return 1
        fi
    done
    rm -rf "$dest/scripts/tests"
    return 0
}

# Keep harness-owned files out of the clone's index without touching a tracked
# file: .git/info/exclude is per-clone, so the agent's own `git add -A` cannot
# pick them up and the graded diff stays code-only. The staged kit is a harness
# surface; session.log is the harness's capture of the CLI stream, and letting
# it into the packet would both pollute the artifact and risk unblinding it
# with arm-specific output.
exclude_run_artifacts() {
    local rundir="$1" exclude="$1/.git/info/exclude"
    [[ -d "$rundir/.git/info" ]] || return 1
    [[ -f "$exclude" ]] || : > "$exclude" || return 1
    grep -qxF '/.promptkit/' "$exclude" 2>/dev/null || echo '/.promptkit/' >> "$exclude"
    grep -qxF '/session.log' "$exclude" 2>/dev/null || echo '/session.log' >> "$exclude"
}

for ((pi = 0; pi < PLAN_COUNT; pi++)); do
    IFS=$'\t' read -r POSITION taskid arm r <<< "${PLAN_LINES[$pi]}"
    order_idx="${PLAN_TASK_IDX[$pi]}"
    level="${TASK_LEVELS[$order_idx]}"
    setup="${TASK_SETUPS[$order_idx]}"
    verify_cmd="${TASK_VERIFIES[$order_idx]}"
    printf 'ORDER|RUN|%s|task=%s|arm=%s|repeat=%s\n' "$POSITION" "$taskid" "$arm" "$r"
    scenario="${taskid}-${arm}-r${r}"
    rundir="$OUT/runs/$scenario"
    rm -rf "$rundir"
    git clone --quiet "$SEED" "$rundir" || bench_error "CLONE_FAILED" "$scenario"
    if [[ -n "$setup" ]]; then
        ( cd "$rundir" && bash -c "$setup" ) || bench_error "SETUP_FAILED" "$scenario"
    fi
    # Both arms get the exclude entries before the session writes its log.
    exclude_run_artifacts "$rundir" || bench_error "EXCLUDE_FAILED" "$scenario"
    if [[ "$arm" == "promptkit_os" ]]; then
        # The directive init.sh writes names the kit at ./.promptkit, so the
        # surface has to exist before the install renders it.
        stage_engine_kit "$rundir/.promptkit" \
            || bench_error "KIT_STAGE_FAILED" "$scenario"
        PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 \
            bash "$INIT" "--$PROFILE" --host=agents "$rundir" \
            > "$OUT/runs/$scenario-init.log" 2>&1 || bench_error "INIT_FAILED" "$scenario"
        # The preflight opt-out above also silences init.sh's own door assert,
        # so run it explicitly against the staged tree. It classifies the
        # install as the courier door and fails closed on a partial copy or a
        # stray .git, before any session spends.
        if ! env -u PROMPTKIT_NO_PREFLIGHT \
                bash "$rundir/.promptkit/scripts/check-setup-assert.sh" \
                    "$rundir" "$rundir/.promptkit" ".promptkit" \
                >> "$OUT/runs/$scenario-init.log" 2>&1; then
            bench_error "ASSERT_FAILED" "$scenario"
        fi
    fi
    # Anchor the grading diff to the SEED commit: under --yolo the agent
    # may commit, and `git diff --cached` against a moved HEAD would
    # return an empty diff, silently losing every committed change.
    seed_sha="$(git -C "$rundir" rev-parse HEAD)"
    th1="$(sha256sum "$TASTE" 2>/dev/null | cut -d' ' -f1 || echo none)"
    # Materialize argv through the builder guard_cross_arm checked; no
    # arm-conditional token can enter the invocation here.
    mapfile -d '' -t SESSION_ARGV < <(session_argv "$order_idx" "$arm")
    set +e
    ( cd "$rundir" && timeout "$TIMEOUT" "${SESSION_ARGV[@]}" ) \
        > "$OUT/runs/$scenario/session.log" 2>&1
    rc=$?
    set -e
    th2="$(sha256sum "$TASTE" 2>/dev/null | cut -d' ' -f1 || echo none2)"
    [[ "$th1" == "$th2" ]] || bench_error "TASTE_CHANGED" "$scenario"
    ( cd "$rundir" && git add -A && git diff --cached --no-color "$seed_sha" > "$rundir-run.diff"; git reset -q ) \
        || bench_error "DIFF_FAILED" "$scenario"
    # Optional path-scrubbed verification evidence, produced by the
    # HARNESS (not the agent) so the grader never needs the
    # arm-revealing session log for evidence-gated rubric items. The
    # packet always carries the command's exit code first
    # (verify_exit=), so a successful-but-silent command still yields
    # gradeable evidence.
    verify_out=""
    if [[ -n "$verify_cmd" ]]; then
        verify_out="$OUT/runs/$scenario/verify.txt"
        vrc=0
        ( cd "$rundir" && bash -c "$verify_cmd" ) > "$verify_out.raw" 2>&1 || vrc=$?
        {
            printf 'verify_exit=%s\n' "$vrc"
            scrub_verify_output "$rundir" "$OUT" "$scenario" "$verify_out.raw"
        } > "$verify_out"
        rm -f "$verify_out.raw"
    fi
    slug="$(slugify_run_path "$rundir")"
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

# Blind-id assignment happens AFTER all runs, by shuffle across the whole
# batch, so id order carries no arm information (a sequential per-run id would
# leak the arm by parity). The required --shuffle-seed makes the shuffle
# reproducible and is recorded in env.txt/isolation.txt.
RANDOM="$SHUFFLE_SEED"
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
