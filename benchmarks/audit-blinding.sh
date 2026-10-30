#!/usr/bin/env bash
# PromptKit OS Phase 3b blinding audit (dry-run).
#
# Builds a graded delivery through benchmarks/run-ab-benchmark.sh with a stub
# CLI on PATH - no model is contacted, so the run spends nothing - and scans
# exactly what a grader receives for the canonical surfaces section 4 names.
#
# Usage: bash benchmarks/audit-blinding.sh [--engine DIR] [--driver PATH] [--keep]
#   --engine DIR   tree the driver runs from (default: this repository)
#   --driver PATH  driver script to exercise
#                  (default: <engine>/benchmarks/run-ab-benchmark.sh)
#   --keep         keep the fixture directory and print its path
#
# Emits one AUDIT| line per finding, AUDIT|CONTROL|<expected>|<planted>|<missing>,
# AUDIT|SUMMARY|..., and finally BLINDING_AUDIT|OK|... (exit 0) or
# AUDIT|FAILED|<n> (exit 1). Usage errors exit 2.
#
# The control is the point: a copy of the delivery gets one instance of every
# surface planted in it, and every scanner must fire. Without it, "no hits"
# could mean the patterns match nothing.
set -u -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$(cd "$HERE/.." && pwd)"
DRIVER=""
KEEP=0

usage() {
    cat <<'USAGE'
Usage: bash benchmarks/audit-blinding.sh [--engine DIR] [--driver PATH] [--keep]

Builds a graded delivery through benchmarks/run-ab-benchmark.sh with a stub
CLI (no model call, zero spend) and scans exactly what a grader receives:
the B*.diff and B*.verify.txt copied out of <out>/grading/, with the blind key
and every driver file left outside.

Scanned surfaces: promptkit_os, bare, BENCH-L, the absolute run and fixture
roots, AGENTS.md, PROMPTKIT.md, .promptkit/, docs/(adrs|reviews|releases|tests)/,
session.log, and every scenario id in the key. Structural checks cover the
packet count, verify count, blind-id shape and uniqueness, the delivery file
set, the key's absence from both the delivery and <out>, each packet's
changed-file set, and the <rundir> scrub in each verify packet.

A positive control plants one instance of every surface in a copy of the
delivery and requires every scanner to fire, so a clean result is measured
rather than vacuous.

Exit: 0 pass, 1 findings, 2 usage error.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --engine)
            [[ $# -ge 2 ]] || { echo "AUDIT|USAGE|--engine requires a directory"; exit 2; }
            ENGINE="$2"; shift 2 ;;
        --driver)
            [[ $# -ge 2 ]] || { echo "AUDIT|USAGE|--driver requires a path"; exit 2; }
            DRIVER="$2"; shift 2 ;;
        --keep) KEEP=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "AUDIT|USAGE|unknown argument: $1"; exit 2 ;;
    esac
done

[[ -d "$ENGINE" ]] || { echo "AUDIT|USAGE|engine is not a directory: $ENGINE"; exit 2; }
[[ -n "$DRIVER" ]] || DRIVER="$ENGINE/benchmarks/run-ab-benchmark.sh"
[[ -f "$DRIVER" ]] || { echo "AUDIT|USAGE|driver not found: $DRIVER"; exit 2; }

TMP="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/phase3b-blind-audit.XXXXXX")"
# The audit keeps the key where a real batch must: outside <out>.
mkdir -p "$TMP/keys"
chmod 700 "$TMP/keys"
KEY="$TMP/keys/audit-key.csv"
cleanup() {
    if [[ "$KEEP" -eq 0 ]]; then
        rm -rf "$TMP"
    fi
}
trap cleanup EXIT

FAKE_HOME="$TMP/home"
BIN="$TMP/bin"
SEED="$TMP/seed"
OUT="$TMP/out"
DELIV="$TMP/delivery"
mkdir -p "$FAKE_HOME/.commandcode/taste" "$BIN" "$SEED/src"
: > "$FAKE_HOME/.commandcode/taste/taste.md"   # preflight requires empty taste

# --- stub command-code ------------------------------------------------------
# Answers the two probes, writes a schema-v3 transcript where the real CLI
# writes one, makes the only file change, and stages it with `git add -A` -
# the same staging step that builds a real packet, and the one the harness's
# own session.log used to ride into the graded diff.
cat > "$BIN/command-code" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then echo "stub-1.0.0"; exit 0; fi
if [[ "${1:-}" == "--list-models" ]]; then echo "stub/model-a"; exit 0; fi
cwd="$(pwd)"
slug="$(printf '%s' "$cwd" | sed 's#^/##; s#/#-#g' | tr '[:upper:]' '[:lower:]' | sed 's#_#-#g; s#[^a-z0-9-]#-#g; s#-\{2,\}#-#g; s#^-##; s#-$##')"
proj="$HOME/.commandcode/projects/$slug"
mkdir -p "$proj"
sid="stub-$(date +%s%N)-$RANDOM"
{
  printf '{"type":"session","version":3,"id":"%s","timestamp":"2026-10-26T12:00:00.000Z","cwd":"%s"}\n' "$sid" "$cwd"
  printf '{"type":"message","id":"u1","parentId":null,"timestamp":"2026-10-26T12:00:01.000Z","message":{"role":"user","content":[{"type":"text","text":"task"}],"meta":{"source":"user","createdAt":1,"messageId":"u1"}}}\n'
  printf '{"type":"message","id":"a1","parentId":"u1","timestamp":"2026-10-26T12:00:05.000Z","message":{"role":"assistant","content":[{"type":"text","text":"done"}],"meta":{"source":"model","createdAt":2,"messageId":"a1"}},"usage":{"inputTokens":900,"outputTokens":90,"cacheReadTokens":10,"cacheWriteTokens":0,"costUsd":0},"model":"stub/model-a"}\n'
} > "$proj/$sid.jsonl"
printf 'STUB-LINE\n' >> src/app.ts
git add -A
git -c user.name=stub -c user.email=stub@test commit -qm "agent change"
exit 0
STUB
chmod +x "$BIN/command-code"

# --- throwaway seed and cards -----------------------------------------------
# One card declares a Verify command and one declares None, so the delivery
# carries a path-scrubbed verify packet as well as bare diffs.
printf 'export function main() { return 1; }\n' > "$SEED/src/app.ts"
git -C "$SEED" init -q
git -C "$SEED" add -A
git -C "$SEED" -c user.name=seed -c user.email=seed@test commit -qm seed

T1="$TMP/task1.md"
T2="$TMP/task2.md"
cat > "$T1" <<'CARD'
# Task Spec: blinding-audit fixture task one

- **Task ID**: `BENCH-L0-99`
- **Level**: `L0`
- **Prompt**: `"Append the line STUB-LINE to src/app.ts. Do not change any other file."`
- **Setup**: `None`
- **Verify**: `printf 'cwd=%s\n' "$PWD"; grep -c STUB-LINE src/app.ts`
CARD
cat > "$T2" <<'CARD'
# Task Spec: blinding-audit fixture task two

- **Task ID**: `BENCH-L1-99`
- **Level**: `L1`
- **Prompt**: `"Append the line STUB-LINE to src/app.ts. Do not change any other file."`
- **Setup**: `None`
- **Verify**: `None`
CARD

PATH="$BIN:/usr/bin:/bin" HOME="$FAKE_HOME" bash "$DRIVER" \
    --engine "$ENGINE" --seed "$SEED" --tasks "$T1,$T2" --model stub/model-a \
    --out "$OUT" --max-turns 5 --timeout 60 --order-seed 7 --shuffle-seed 7 \
    --key-out "$KEY" \
    > "$TMP/run.log" 2>&1
run_rc=$?
if [[ $run_rc -ne 0 ]]; then
    echo "AUDIT|FAIL|dry run exited $run_rc"
    tail -20 "$TMP/run.log"
    echo "AUDIT|FAILED|1"
    exit 1
fi
grep -E '^(PREFLIGHT\|OK|ORDER\|PLAN|BLIND|BATCH)' "$TMP/run.log" | head -20
printf 'AUDIT|PREFLIGHT|engine=%s|seed=%s|spend=0|stub=cli\n' \
    "$(git -C "$ENGINE" rev-parse --short HEAD 2>/dev/null || echo unknown)" \
    "$(git -C "$SEED" rev-parse --short HEAD 2>/dev/null || echo unknown)"

mkdir -p "$DELIV"
cp "$OUT"/grading/B*.diff "$DELIV"/
for f in "$OUT"/grading/B*.verify.txt; do
    [[ -e "$f" ]] && cp "$f" "$DELIV"/
done

fails=0
fail() { printf 'AUDIT|FAIL|%s\n' "$1"; fails=$((fails + 1)); }

packets=$(find "$DELIV" -maxdepth 1 -type f -name 'B*.diff' | wc -l | tr -d ' ')
verifies=$(find "$DELIV" -maxdepth 1 -type f -name 'B*.verify.txt' | wc -l | tr -d ' ')
delivery_files=$(find "$DELIV" -maxdepth 1 -type f | wc -l | tr -d ' ')
rows=$(($(wc -l < "$KEY") - 1))
: > "$TMP/blinds.txt"
for f in "$DELIV"/B*.diff; do
    basename "$f" .diff >> "$TMP/blinds.txt"
done
uniq_blinds=$(sort -u "$TMP/blinds.txt" | wc -l | tr -d ' ')

# Four runs (two cards x two arms x one repeat); one card declares Verify.
[[ "$packets" -eq 4 ]] || fail "packet count $packets != 4"
[[ "$verifies" -eq 2 ]] || fail "verify count $verifies != 2"
[[ "$rows" -eq 4 ]] || fail "key rows $rows != 4"
[[ "$uniq_blinds" -eq "$packets" ]] || fail "blind ids not unique"
if grep -qvE '^B[0-9]{3}$' "$TMP/blinds.txt"; then
    fail "blind id shape"
fi

extra=$(find "$DELIV" -maxdepth 1 -type f ! -name 'B*.diff' ! -name 'B*.verify.txt' | wc -l | tr -d ' ')
[[ "$extra" -eq 0 ]] || fail "delivery holds $extra unexpected file(s)"
[[ ! -e "$DELIV/key.csv" ]] || fail "key.csv inside delivery"
for f in key.csv manifest.tsv order.tsv env.txt isolation.txt crossarm.txt; do
    [[ ! -e "$DELIV/$f" ]] || fail "$f inside delivery"
done
# Section 4 stores the key outside the grading workspace; a copy in <out> is
# the failure mode a delivery-only scan cannot see.
[[ ! -e "$OUT/grading/key.csv" ]] || fail "key.csv inside <out>/grading"
[[ "$(sed -n 's/^key_path: //p' "$OUT/key-location.txt" 2>/dev/null)" == "$KEY" ]] \
    || fail "key-location.txt does not name the external key"
[[ "$(sha256sum "$KEY" | cut -d' ' -f1)" \
        == "$(sed -n 's/^key_sha256: //p' "$OUT/key-location.txt" 2>/dev/null)" ]] \
    || fail "key-location.txt sha256 does not match the key"; 

# --- scanners ---------------------------------------------------------------
# $1 label, $2 pattern, $3 grep mode (E regex, F literal). SCAN_DIR is global so
# the same code runs over the real delivery and the control.
grep_hits() {
    local dir="$1" pattern="$2" mode="${3:-E}"
    if [[ "$mode" == "F" ]]; then
        grep -RInF -- "$pattern" "$dir" 2>/dev/null || true
    else
        grep -RInE -- "$pattern" "$dir" 2>/dev/null || true
    fi
}

HITS=""
check() {
    local label="$1" pattern="$2" mode="${3:-E}" out
    out="$(grep_hits "$SCAN_DIR" "$pattern" "$mode")"
    [[ -n "$out" ]] || return 0
    printf '%s\n' "$out" | head -3 | sed "s#^#HIT|$label|#"
    HITS="$HITS $label"
}

scan_all() {
    check promptkit_os 'promptkit_os'
    check arm_bare '\bbare\b'
    check task_id 'BENCH-L'
    check out_path "$OUT" F
    check tmp_path "$TMP" F
    check agents_md 'AGENTS\.md'
    check promptkit_md 'PROMPTKIT\.md'
    check kit_dir '\.promptkit/'
    check docs_artifacts 'docs/(adrs|reviews|releases|tests)/'
    check session_log 'session\.log'
    while IFS=, read -r blind scenario; do
        [[ "$blind" == "blind" ]] && continue
        [[ -n "${scenario:-}" ]] && check "scenario:$blind" "$scenario" F
    done < "$KEY"
}

# The delivery is exactly what a grader gets; any hit stops the batch.
SCAN_DIR="$DELIV"
scan_all
[[ -z "$HITS" ]] || fail "canonical surface inside delivery:$HITS"

# The packet must carry the agent's change and nothing else - the harness's
# own files stay out of the graded diff.
for f in "$DELIV"/B*.diff; do
    files=$(grep -E '^diff --git ' "$f" \
        | sed -E 's#^diff --git a/([^ ]+) b/.*#\1#' | sort -u | tr '\n' ' ')
    [[ "$files" == "src/app.ts " ]] \
        || fail "$(basename "$f") carries files: $files"
    grep -qE '^\+.*STUB-LINE' "$f" \
        || fail "$(basename "$f") lacks the agent change"
done
for f in "$DELIV"/B*.verify.txt; do
    [[ -e "$f" ]] || continue
    grep -qF 'cwd=<rundir>' "$f" \
        || fail "verify packet $(basename "$f") is not path-scrubbed"
done

# --- positive control -------------------------------------------------------
# Plant one instance of every surface in a copy of the delivery and require
# every scanner to fire.
CONTROL="$TMP/control"
cp -r "$DELIV" "$CONTROL"
B1="$(find "$CONTROL" -maxdepth 1 -name 'B*.diff' | sort | head -1)"
{
    echo '+CONTROL AGENTS.md PROMPTKIT.md .promptkit/workflows/x.md'
    echo '+CONTROL docs/adrs/ADR-1.md promptkit_os bare BENCH-L0-99 session.log'
    echo "+CONTROL $OUT/grading/B001.diff $TMP/seed/src/app.ts"
} >> "$B1"
EXPECT="promptkit_os arm_bare task_id out_path tmp_path agents_md promptkit_md kit_dir docs_artifacts session_log"
while IFS=, read -r blind scenario; do
    [[ "$blind" == "blind" ]] && continue
    [[ -n "${scenario:-}" ]] || continue
    echo "+CONTROL $blind $scenario" >> "$B1"
    EXPECT="$EXPECT scenario:$blind"
done < "$KEY"

HITS=""
SCAN_DIR="$CONTROL"
scan_all
missing=""
expected=0
for want in $EXPECT; do
    expected=$((expected + 1))
    case " $HITS " in
        *" $want "*) ;;
        *) missing="$missing $want" ;;
    esac
done
[[ -z "$missing" ]] || fail "control did not fire:$missing"
printf 'AUDIT|CONTROL|expected=%s|planted=%s|missing=%s\n' \
    "$expected" "$expected" "${missing:-none}"

printf 'AUDIT|SUMMARY|packets=%s|verify=%s|key_rows=%s|blind_ids=%s|delivery_files=%s\n' \
    "$packets" "$verifies" "$rows" "$uniq_blinds" "$delivery_files"
[[ "$KEEP" -eq 1 ]] && printf 'AUDIT|KEPT|%s\n' "$TMP"
if [[ "$fails" -ne 0 ]]; then
    printf 'AUDIT|FAILED|%s\n' "$fails"
    exit 1
fi
printf 'BLINDING_AUDIT|OK|packets=%s|verify=%s|blind_ids=%s|leaks=0|control=%s/%s|key=outside_delivery|key_store=outside_out\n' \
    "$packets" "$verifies" "$uniq_blinds" "$expected" "$expected"
exit 0
