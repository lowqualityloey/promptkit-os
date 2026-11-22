#!/usr/bin/env bash
# Render a capture transcript and its write log from an Antigravity CLI
# (agy) --output-format stream-json event stream.
#
# Usage:
#   render-capture-transcript.sh <session.jsonl> <transcript.md> <observed-writes.log> \
#       --probe <name> --prompt <text> --model <text> [--host <text>] [--invocation <text>]
#
# The transcript format is the one the nine committed bundles under
# docs/internal/host-conformance/opencode-omo/ already use, so the scorer reads
# it unchanged: an H1 naming the host and probe, a preamble recording the raw
# stream's sha256, a "## Events" section, and one entry per event as
# "- \`<timestamp>\` **text**" (body indented two spaces, byte-for-byte) or
# "- \`<timestamp>\` **tool**" followed by "<verb> <target> (<status>)".
#
# Two properties are load-bearing and must not be "simplified":
#
#   1. The two-space indent on event bodies is preserved. The scorer's
#      assistant_text() keeps it deliberately, so a ^-anchored pattern such as
#      `not-contains: ^tool write` keeps anchoring at the start of a plain-prose
#      line instead of firing on a sentence that merely mentions a write.
#   2. Tool names are mapped to the scorer's verb vocabulary (read, write, grep,
#      find, ls, shell). The scorer's inspection and write attribution is
#      verb-driven, so emitting agy's own tool names (read_file, run_command)
#      would make every tool line unclassifiable.
#
# agy's event stream carries no per-event timestamp. Timestamps are therefore
# derived from the capture start plus the cumulative step durations agy does
# report, and the transcript says so rather than implying an observed clock.

set -uo pipefail

usage() {
    echo "Usage: render-capture-transcript.sh <session.jsonl> <transcript.md> <observed-writes.log> --probe <name> --prompt <text> --model <text> [--host <text>] [--invocation <text>]" >&2
    exit 2
}

[ "$#" -ge 3 ] || usage
jsonl="$1"; transcript="$2"; writes="$3"; shift 3

probe=""; prompt=""; model=""; host="Antigravity CLI"; invocation="agy --input-format stream-json --output-format stream-json"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --probe) [ "$#" -ge 2 ] || usage; probe="$2"; shift 2 ;;
        --prompt) [ "$#" -ge 2 ] || usage; prompt="$2"; shift 2 ;;
        --model) [ "$#" -ge 2 ] || usage; model="$2"; shift 2 ;;
        --host) [ "$#" -ge 2 ] || usage; host="$2"; shift 2 ;;
        --invocation) [ "$#" -ge 2 ] || usage; invocation="$2"; shift 2 ;;
        *) echo "render-capture-transcript: unknown argument: $1" >&2; usage ;;
    esac
done

[ -f "$jsonl" ] || { echo "render-capture-transcript: no such event stream: $jsonl" >&2; exit 2; }
[ -n "$probe" ] || { echo "render-capture-transcript: --probe is required" >&2; exit 2; }
[ -n "$prompt" ] || { echo "render-capture-transcript: --prompt is required" >&2; exit 2; }
[ -n "$model" ] || { echo "render-capture-transcript: --model is required" >&2; exit 2; }

JSONL="$jsonl" TRANSCRIPT="$transcript" WRITES="$writes" PROBE="$probe" PROMPT="$prompt" \
MODEL="$model" HOST="$host" INVOCATION="$invocation" node - <<'NODE'
const fs = require('node:fs');
const crypto = require('node:crypto');

const raw = fs.readFileSync(process.env.JSONL, 'utf8');
const sha = crypto.createHash('sha256').update(raw).digest('hex').slice(0, 16);

// agy tool name -> the scorer's verb vocabulary. The scorer decides inspection
// versus write from the verb, so this mapping is what makes a tool line
// classifiable at all. An unmapped tool keeps its own name, which the scorer
// then treats as neither an inspection nor a write — the safe direction.
const VERB = {
  read_file: 'read',
  view_file: 'read',
  list_dir: 'ls',
  grep_search: 'grep',
  find_by_name: 'find',
  run_command: 'shell',
  write_to_file: 'write',
  replace_file_content: 'write',
  multi_replace_file_content: 'write',
  sed_file: 'write',
  notebook_edit: 'write',
};

// The argument that names what the tool acted on, in the order the scorer's
// path attribution expects to find it.
const TARGET_KEYS = ['CommandLine', 'Path', 'AbsolutePath', 'TargetFile', 'Query', 'Pattern', 'DirectoryPath', 'Url'];

function targetOf(params) {
  if (!params || typeof params !== 'object') return '';
  for (const k of TARGET_KEYS) {
    if (typeof params[k] === 'string' && params[k]) return params[k];
  }
  const first = Object.values(params).find((v) => typeof v === 'string' && v);
  return first ?? '';
}

const events = [];
for (const line of raw.split('\n')) {
  if (!line.trim()) continue;
  let ev;
  try { ev = JSON.parse(line); } catch { continue; }
  events.push(ev);
}

// One logical step per step_index. Text deltas accumulate across the ACTIVE and
// DONE updates of the same step; a tool is emitted once, on DONE, so its status
// is the final one.
const steps = new Map();
let conversation = '';
let totalSeconds = 0;
for (const ev of events) {
  if (ev.event === 'init' && ev.conversation_id) conversation = ev.conversation_id;
  if (ev.event === 'result' && ev.result) {
    if (ev.result.conversation_id) conversation = ev.result.conversation_id;
    if (Number.isFinite(ev.result.duration_seconds)) totalSeconds = ev.result.duration_seconds;
    continue;
  }
  if (ev.event !== 'step_update' || !ev.step_update) continue;
  const su = ev.step_update;
  const idx = su.step_index;
  if (!Number.isInteger(idx)) continue;
  let step = steps.get(idx);
  if (!step) {
    step = { index: idx, type: su.step_type, text: '', tool: '', target: '', status: '', seconds: 0, done: false };
    steps.set(idx, step);
  }
  if (su.step_type) step.type = su.step_type;
  if (typeof su.text_delta === 'string') step.text += su.text_delta;
  if (su.tool_name) step.tool = su.tool_name;
  if (su.tool_info && su.tool_info.parameters) step.target = targetOf(su.tool_info.parameters);
  if (su.state === 'DONE') {
    step.done = true;
    step.status = 'completed';
    if (Number.isFinite(su.duration_seconds)) step.seconds = su.duration_seconds;
  }
}

// agy reports no per-event clock, so the timeline is reconstructed: the capture
// ended at the stream file's mtime, and each step is placed by the durations
// agy does report. The transcript states this rather than implying observation.
const endMs = fs.statSync(process.env.JSONL).mtimeMs;
const startMs = endMs - totalSeconds * 1000;
let cursor = startMs;
function iso(ms) {
  const d = new Date(ms);
  const pad = (n, w = 2) => String(n).padStart(w, '0');
  const off = -d.getTimezoneOffset();
  const sign = off >= 0 ? '+' : '-';
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.${pad(d.getMilliseconds(), 3)}000${sign}${pad(Math.floor(Math.abs(off) / 60))}:${pad(Math.abs(off) % 60)}`;
}

const ordered = [...steps.values()].sort((a, b) => a.index - b.index);
const out = [];
const log = [];

out.push(`# Live capture transcript — ${process.env.HOST}, ${process.env.PROBE} probe (${process.env.MODEL})`);
out.push('');
out.push('Rendered mechanically from the raw session event stream preserved verbatim as');
out.push(`\`session.jsonl\` in this bundle (sha256 \`${sha}\`). Assistant text is byte-for-byte as`);
out.push('emitted; tool lines record the tool name, its target, and its completion status.');
out.push('');
out.push(`- Session: \`${conversation || 'unknown'}\``);
out.push(`- Prompt submitted: \`${process.env.PROMPT}\``);
out.push(`- Model: \`${process.env.MODEL}\` via \`${process.env.INVOCATION}\``);
out.push('');
out.push('> [!NOTE]');
out.push('> The event stream carries no per-event timestamp. Each entry below is placed by the');
out.push('> capture start plus the cumulative step durations the stream does report, so the');
out.push('> times are a reconstruction of the run, not an observed clock.');
out.push('');
out.push('## Events');
out.push('');

for (const step of ordered) {
  const at = iso(cursor);
  if (step.type === 'agent_response' && step.text.trim()) {
    out.push(`- \`${at}\` **text**`);
    for (const l of step.text.replace(/\n$/, '').split('\n')) out.push(`  ${l}`);
    out.push('');
  } else if (step.type === 'tool' && step.tool) {
    const verb = VERB[step.tool] ?? step.tool;
    const line = `${verb} ${step.target} (${step.status || 'unknown'})`.trimEnd();
    out.push(`- \`${at}\` **tool**`);
    out.push(`  ${line}`);
    out.push('');
    log.push(`tool ${line}`);
  }
  cursor += step.seconds * 1000;
}

fs.writeFileSync(process.env.TRANSCRIPT, out.join('\n') + '\n');
fs.writeFileSync(process.env.WRITES, log.join('\n') + (log.length ? '\n' : ''));
process.stdout.write(`rendered ${process.env.TRANSCRIPT} (${ordered.length} steps, ${log.length} tool calls, session ${conversation || 'unknown'})\n`);
NODE
