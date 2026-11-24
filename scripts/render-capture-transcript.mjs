#!/usr/bin/env node
// Render a capture transcript and its write log from an Antigravity CLI
// (agy) --output-format stream-json event stream.
//
// Usage:
//   node render-capture-transcript.mjs <session.jsonl> <transcript.md> <observed-writes.log> \
//       --probe <name> --prompt <text> --model <text> [--host <text>] [--invocation <text>]
//
// This module is the single implementation. scripts/render-capture-transcript.sh
// and scripts/render-capture-transcript.ps1 are thin forwarders, so the two
// twins cannot drift: there is no second copy of the logic to keep in step.
//
// The transcript format is the one the nine committed bundles under
// docs/internal/host-conformance/opencode-omo/ already use, so the scorer reads
// it unchanged: an H1 naming the host and probe, a preamble recording the raw
// stream's sha256, a "## Events" section, and one entry per event as
// "- \`<timestamp>\` **text**" (body indented two spaces, byte-for-byte) or
// "- \`<timestamp>\` **tool**" followed by "<verb> <target> (<status>)".
//
// Two properties are load-bearing and must not be "simplified":
//
//   1. The two-space indent on event bodies is preserved. The scorer's
//      assistant_text() keeps it deliberately, so a ^-anchored pattern such as
//      \`not-contains: ^tool write\` keeps anchoring at the start of a plain-prose
//      line instead of firing on a sentence that merely mentions a write.
//   2. Tool names are mapped to the scorer's verb vocabulary (read, write, grep,
//      find, ls, shell). The scorer's inspection and write attribution is
//      verb-driven, so emitting agy's own tool names (read_file, run_command)
//      would make every tool line unclassifiable.
//
// agy's event stream carries no per-event timestamp. Timestamps are therefore
// derived from the capture start plus the cumulative step durations agy does
// report, and the transcript says so rather than implying an observed clock.

import fs from 'node:fs';
import crypto from 'node:crypto';

const USAGE = 'Usage: render-capture-transcript <session.jsonl> <transcript.md> <observed-writes.log> --probe <name> --prompt <text> --model <text> [--host <text>] [--invocation <text>] [--stream <name>] [--start <iso>] [--offset <±HH:MM>]';

function usage() {
  process.stderr.write(USAGE + '\n');
  process.exit(2);
}

function fail(message) {
  process.stderr.write('render-capture-transcript: ' + message + '\n');
  process.exit(2);
}

const argv = process.argv.slice(2);
if (argv.length < 3) usage();

const jsonl = argv[0];
const transcript = argv[1];
const writes = argv[2];

let probe = '';
let prompt = '';
let model = '';
let host = 'Antigravity CLI';
let invocation = 'agy --input-format stream-json --output-format stream-json';
// The file name the preamble names as the rendered source. A capture that
// rewrites absolute tool targets to repository-relative ones renders from a
// derived stream, and the preamble must say which file the hash describes
// rather than implying it is the raw one.
let streamName = 'session.jsonl';
// The instant the capture began, when the bundle recorded one. Without it the
// timeline is anchored on the stream file's mtime, which git does not preserve:
// a committed bundle re-rendered on another machine would silently shift every
// timestamp while still passing a timestamp-stripped round-trip test.
let startAnchor = '';
// The UTC offset the timestamp column is rendered in. It is a property of the
// bundle, never of the machine doing the rendering - see the iso() comment.
let offsetFlag = '';

for (let i = 3; i < argv.length; i += 1) {
  const flag = argv[i];
  const value = argv[i + 1];
  switch (flag) {
    case '--probe':
      if (value === undefined) usage();
      probe = value; i += 1; break;
    case '--prompt':
      if (value === undefined) usage();
      prompt = value; i += 1; break;
    case '--model':
      if (value === undefined) usage();
      model = value; i += 1; break;
    case '--host':
      if (value === undefined) usage();
      host = value; i += 1; break;
    case '--invocation':
      if (value === undefined) usage();
      invocation = value; i += 1; break;
    case '--stream':
      if (value === undefined) usage();
      streamName = value; i += 1; break;
    case '--start':
      if (value === undefined) usage();
      startAnchor = value; i += 1; break;
    case '--offset':
      if (value === undefined) usage();
      offsetFlag = value; i += 1; break;
    default:
      fail('unknown argument: ' + flag);
  }
}

if (!fs.existsSync(jsonl) || !fs.statSync(jsonl).isFile()) fail('no such event stream: ' + jsonl);
if (!probe) fail('--probe is required');
if (!prompt) fail('--prompt is required');
if (!model) fail('--model is required');

// The stream is hashed in canonical form (LF line endings) rather than as the
// checkout happens to store it. A Windows checkout with core.autocrlf rewrites
// the file to CRLF, which would otherwise change the preamble hash and make the
// same capture render differently on different machines. The hash identifies the
// stream's content, not the checkout's line-ending policy.
const raw = fs.readFileSync(jsonl, 'utf8').replace(/\r\n/g, '\n');
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
  // agy 1.5.15 emits edit_file at runtime even though it is absent from the
  // tool list in the init event. Leaving it unmapped would render it verbatim,
  // and the scorer's write-verb table does not know it either, so a real write
  // would be invisible to repo-unwritten and silently degrade to a non-detection.
  edit_file: 'write',
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
// began at a known instant, and each step is placed by the durations agy does
// report. The transcript states this rather than implying observation.
//
// The anchor is the recorded capture start when the bundle carries one. Falling
// back to the stream file's mtime is only correct on the machine that produced
// the capture: git does not preserve mtime, so a committed bundle re-rendered
// elsewhere would shift every timestamp by the checkout's clock while the
// timestamp-stripped round-trip test still passed.
// The anchor is rounded to whole milliseconds. A file mtime carries sub-ms
// precision that no reader can interpret and that would make the same capture
// render one millisecond differently depending on which filesystem wrote the
// file. Rounding once, here, is what lets a recorded anchor reproduce a
// committed transcript byte for byte on any machine.
let startMs;
if (startAnchor) {
  startMs = Date.parse(startAnchor);
  if (!Number.isFinite(startMs)) fail('--start is not a parseable instant: ' + startAnchor);
  startMs = Math.round(startMs);
} else {
  startMs = Math.round(fs.statSync(jsonl).mtimeMs - totalSeconds * 1000);
}
// The timestamp column is rendered in a FIXED offset, never the host's local
// zone. Formatting with getFullYear()/getHours()/getTimezoneOffset() made the
// rendering a property of the machine rather than of the capture: the same
// recorded anchor produced `+13:00` on the capture host and `+00:00` on a UTC
// CI runner, so a committed transcript could never be reproduced off the
// machine that wrote it. The anchor fixed the instant; this fixes its spelling.
//
// The offset comes from the bundle, in this order:
//   1. --offset <±HH:MM>, when the caller passes one.
//   2. The offset carried by --start, when it carries one (a Z-suffixed anchor
//      carries none, which is why the flag exists).
//   3. +00:00, the only offset that is not a guess about someone's machine.
// A bundle that wants its capture host's zone recorded must say so; the
// renderer will not infer it from the environment.
const OFFSET_RE = /([+-])(\d{2}):?(\d{2})$/;
function parseOffset(text) {
  if (!text) return null;
  const m = OFFSET_RE.exec(text);
  if (!m) return null;
  const minutes = (m[1] === '-' ? -1 : 1) * (Number(m[2]) * 60 + Number(m[3]));
  if (!Number.isFinite(minutes) || Math.abs(minutes) > 14 * 60) return null;
  return minutes;
}

let offsetMinutes = parseOffset(offsetFlag);
if (offsetMinutes === null && offsetFlag) fail('--offset is not a ±HH:MM offset: ' + offsetFlag);
if (offsetMinutes === null) offsetMinutes = parseOffset(startAnchor);
if (offsetMinutes === null) offsetMinutes = 0;

const offsetLabel = (() => {
  const sign = offsetMinutes < 0 ? '-' : '+';
  const abs = Math.abs(offsetMinutes);
  const pad = (n) => String(n).padStart(2, '0');
  return sign + pad(Math.floor(abs / 60)) + ':' + pad(abs % 60);
})();

let cursor = startMs;
function iso(ms) {
  // Shift into the target offset, then read every field through the UTC
  // accessors: the shift is the only place the offset is applied, so the
  // rendering cannot pick up the host zone by accident.
  const d = new Date(ms + offsetMinutes * 60000);
  const pad = (n, w = 2) => String(n).padStart(w, '0');
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}T${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}:${pad(d.getUTCSeconds())}.${pad(d.getUTCMilliseconds(), 3)}000${offsetLabel}`;
}

const ordered = [...steps.values()].sort((a, b) => a.index - b.index);
const out = [];
const log = [];

out.push(`# Live capture transcript — ${host}, ${probe} probe (${model})`);
out.push('');
out.push('Rendered mechanically from the session event stream preserved in this bundle as');
out.push(`\`${streamName}\` (sha256 \`${sha}\`). Assistant text is byte-for-byte as emitted;`);
out.push('tool lines record the tool name, its target, and its completion status.');
out.push('');
out.push(`- Session: \`${conversation || 'unknown'}\``);
out.push(`- Prompt submitted: \`${prompt}\``);
out.push(`- Model: \`${model}\` via \`${invocation}\``);
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

fs.writeFileSync(transcript, out.join('\n') + '\n');
fs.writeFileSync(writes, log.join('\n') + (log.length ? '\n' : ''));
process.stdout.write(`rendered ${transcript} (${ordered.length} steps, ${log.length} tool calls, session ${conversation || 'unknown'})\n`);
