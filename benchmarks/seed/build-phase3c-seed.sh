#!/usr/bin/env bash
# Build the purpose-built neutral seed repository for the Phase 3c A/B benchmark.
#
#   build-phase3c-seed.sh <dest-dir>
#
# Phase 3c (benchmarks/PHASE-3C-DESIGN.md) needs a seed with depth: the Phase 3b
# seed is four modules with a 28-test suite whose backlog *was* the slate, and
# both arms solved all six of its tasks, so the batch measured nothing about
# quality. This seed is nine modules with a coupled store, metrics, registry,
# scheduler and CLI, a docs surface that states three invariants, and behavioral
# specs the code does not yet satisfy.
#
# The tree carries no agent-instruction surface and no `heyloey` reference, so
# neutralize.sh accepts it with `removed=0` and the seed SHA is this script's own
# commit SHA. It is synthetic — it has a backlog, but not a real one — so a batch
# run against it must be labeled accordingly.
#
# Deliberate defects, one per card. None of them is pinned by a test in this
# tree: a test that asserted the buggy behavior would have to be rewritten by the
# agent, and a test that asserted the correct behavior would hand over the fix.
# They are observable only through the cards' Verify probes and the spec files.
#
#   P3C-01  dispatcher increments the `jobs` counter once per attempt, not per job
#   P3C-02  only the legacy --DRY_RUN spelling exists; --dry-run is unknown
#   P3C-03  status() counts a finished job as pending as well as terminal
#   P3C-04  the runner ignores the store on the way in, so a restart re-dispatches
#   P3C-05  a batch enqueues one store record per item, so a failed write tears it
#   P3C-06  dispatch() returns {processed, failed, total} with an uncovered caller
#   P3C-07  store records carry no format version, and v1 is the only shape read
#   P3C-08  backoff draws from Math.random and ignores the delay cap
#   P3C-09  specs/backpressure.spec.js fails: BackpressureError does not exist
#   P3C-10  drain() calls shift() per item, so it degrades with queue size
#
# Zero runtime dependencies: the suite uses Node's built-in runner (`node --test`),
# so a fresh clone tests itself with no install step and no network access.
#
# Deterministic: fixed author/committer identity and date, `--template=` on init
# and `--no-verify` on the commit, so identical content produces an identical SHA
# on any host and the design doc can pin it.
#
# Operator-local Bash with no PowerShell twin, like the Phase 3b builder and
# neutralize.sh: it writes files and drives git, not a CLI.
#
# Output (stdout, one machine line):
#   SEED|OK|sha=<sha>|files=<n>|path=<dest>
# Errors go to stderr as SEED|ERROR|<reason> and exit 2, failing closed.

set -euo pipefail
export LC_ALL=C

die() {
    printf 'SEED|ERROR|%s\n' "$1" >&2
    exit 2
}

[[ $# -eq 1 ]] || die "usage: build-phase3c-seed.sh <dest-dir>"
dest=${1%/}
[[ -n "$dest" ]] || die "empty dest path"

command -v git >/dev/null 2>&1 || die "git is not on PATH"

if [[ -e "$dest" || -L "$dest" ]]; then
    die "dest exists, so it was left untouched: $dest"
fi

mkdir -p -- "$dest/src" "$dest/test" "$dest/docs/adr" "$dest/specs" \
    || die "cannot create seed directories: $dest"

cat > "$dest/package.json" <<'PKGJSON'
{
  "name": "phase3c-seed",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "description": "Synthetic job-service seed for the Phase 3c benchmark. Zero runtime dependencies.",
  "scripts": {
    "test": "node --test"
  }
}
PKGJSON

cat > "$dest/.gitignore" <<'GITIGNORE'
node_modules/
data/
*.log
GITIGNORE

cat > "$dest/README.md" <<'README'
# jobsvc

A small job service: a bounded FIFO queue drained through a handler, an
append-only store for job history, counters, a plugin registry, and a scheduler.

Zero runtime dependencies. Tests run on Node's built-in runner:

```sh
node --test
```

Module responsibilities and the invariants that hold across them are in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Format and counting decisions are
recorded in [`docs/adr/`](docs/adr/).

```sh
node src/bin.js run --JOBS=a,b,c
node src/bin.js status
```

Behavioral specs live in [`specs/`](specs/). They describe required behavior and
are run explicitly rather than by `node --test`:

```sh
node --test specs/backpressure.spec.js
```
README

cat > "$dest/BACKLOG.md" <<'BACKLOG'
# Backlog

Open work, roughly in the order it would be picked up. Nothing here is committed
to a milestone, and nothing here names a file: locating the code that owns a
behavior is part of picking the work up.

- Counters must describe jobs, not the machinery that processes them.
- Operator tooling needs a truthful view of what is pending, done, and failed.
- A restart must not re-dispatch work the store already recorded as finished,
  and must not drop work that was recorded but never finished.
- Batch intake should be all-or-nothing, including when the store rejects a write.
- The store format will need a version so a reader can tell generations apart.
- Retry backoff should be reproducible from a seeded source in tests.
- Draining a large queue should not get slower per item than enqueueing it.
BACKLOG

# ---------------------------------------------------------------- src/config.js
cat > "$dest/src/config.js" <<'CONFIGJS'
const LEVELS = ['debug', 'info', 'warn', 'error'];

export class ConfigError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ConfigError';
  }
}

function positiveInt(raw, fallback, name) {
  if (raw === undefined || raw === '') return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 1) {
    throw new ConfigError(`${name} must be a positive integer, got: ${raw}`);
  }
  return value;
}

export function loadConfig(env = {}) {
  const port = positiveInt(env.PORT, 8080, 'PORT');
  if (port > 65535) {
    throw new ConfigError(`PORT must be at most 65535, got: ${port}`);
  }

  const rawLevel =
    env.LOG_LEVEL === undefined || env.LOG_LEVEL === ''
      ? 'info'
      : String(env.LOG_LEVEL).toLowerCase();
  if (!LEVELS.includes(rawLevel)) {
    throw new ConfigError(`LOG_LEVEL must be one of ${LEVELS.join(', ')}, got: ${env.LOG_LEVEL}`);
  }

  const capacity = positiveInt(env.QUEUE_CAPACITY, 100, 'QUEUE_CAPACITY');
  const jitterCapMs = positiveInt(env.JITTER_CAP_MS, 200, 'JITTER_CAP_MS');
  const storePath =
    env.STORE_PATH === undefined || env.STORE_PATH === ''
      ? 'data/jobs.jsonl'
      : String(env.STORE_PATH);

  return Object.freeze({ port, level: rawLevel, capacity, jitterCapMs, storePath });
}

export const LOG_LEVELS = Object.freeze([...LEVELS]);
CONFIGJS

# ----------------------------------------------------------------- src/store.js
cat > "$dest/src/store.js" <<'STOREJS'
import { appendFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs';
import { dirname } from 'node:path';

export class StoreError extends Error {
  constructor(message) {
    super(message);
    this.name = 'StoreError';
  }
}

const defaultIo = { appendFileSync, existsSync, mkdirSync, readFileSync };

// An append-only JSONL store. Records are written one per line and are never
// rewritten in place: a later reader replays them to work out the state of a
// job. `io` is injectable so a test can drive a store without touching disk, and
// so a failure can be injected at exactly the write that matters.
export function createStore({ path, io = defaultIo } = {}) {
  if (typeof path !== 'string' || path === '') {
    throw new StoreError('store path must be a non-empty string');
  }

  function append(record) {
    if (record === null || typeof record !== 'object') {
      throw new StoreError('record must be an object');
    }
    try {
      const dir = dirname(path);
      if (!io.existsSync(dir)) {
        io.mkdirSync(dir, { recursive: true });
      }
      io.appendFileSync(path, `${JSON.stringify(record)}\n`, 'utf8');
    } catch (error) {
      throw new StoreError(`append failed: ${error.message}`);
    }
    return record;
  }

  function readAll() {
    if (!io.existsSync(path)) return [];
    let text;
    try {
      text = io.readFileSync(path, 'utf8');
    } catch (error) {
      throw new StoreError(`read failed: ${error.message}`);
    }
    const records = [];
    for (const line of text.split('\n')) {
      if (line.trim() === '') continue;
      let parsed;
      try {
        parsed = JSON.parse(line);
      } catch {
        throw new StoreError('store contains a line that is not JSON');
      }
      if (parsed === null || typeof parsed !== 'object' || typeof parsed.type !== 'string') {
        throw new StoreError('store record is missing its type');
      }
      records.push(parsed);
    }
    return records;
  }

  return { path, append, readAll };
}
STOREJS

# ----------------------------------------------------------------- src/queue.js
cat > "$dest/src/queue.js" <<'QUEUEJS'
export class QueueFullError extends Error {
  constructor(capacity) {
    super(`queue is full at capacity ${capacity}`);
    this.name = 'QueueFullError';
    this.capacity = capacity;
  }
}

export function createQueue({ capacity = 100 } = {}) {
  if (capacity !== Number.POSITIVE_INFINITY && (!Number.isInteger(capacity) || capacity < 1)) {
    throw new RangeError(`capacity must be a positive integer, got: ${capacity}`);
  }

  const items = [];

  return {
    get capacity() {
      return capacity;
    },
    get size() {
      return items.length;
    },
    get isFull() {
      return items.length >= capacity;
    },
    enqueue(item) {
      if (items.length >= capacity) throw new QueueFullError(capacity);
      items.push(item);
      return items.length;
    },
    enqueueMany(batch) {
      if (items.length + batch.length > capacity) throw new QueueFullError(capacity);
      for (const item of batch) items.push(item);
      return items.length;
    },
    peek() {
      return items.length === 0 ? undefined : items[0];
    },
    dequeue() {
      return items.length === 0 ? undefined : items.shift();
    },
    drain() {
      const drained = [];
      while (items.length > 0) drained.push(items.shift());
      return drained;
    },
  };
}
QUEUEJS

# --------------------------------------------------------------- src/metrics.js
cat > "$dest/src/metrics.js" <<'METRICSJS'
const COUNTERS = ['jobs', 'processed', 'failed'];

export function createMetrics() {
  const counters = { jobs: 0, processed: 0, failed: 0 };

  return {
    inc(name, by = 1) {
      if (!Object.hasOwn(counters, name)) {
        throw new RangeError(`unexpected counter: ${name}`);
      }
      if (!Number.isInteger(by)) {
        throw new RangeError(`counter increment must be an integer, got: ${by}`);
      }
      counters[name] += by;
      return counters[name];
    },
    recordJob(outcome) {
      if (outcome !== 'processed' && outcome !== 'failed') {
        throw new RangeError(`unexpected outcome: ${outcome}`);
      }
      counters[outcome] += 1;
      return counters[outcome];
    },
    snapshot() {
      return Object.freeze({ ...counters });
    },
    reset() {
      for (const name of COUNTERS) counters[name] = 0;
    },
  };
}

export const METRIC_NAMES = Object.freeze([...COUNTERS]);
METRICSJS

# ------------------------------------------------------------ src/dispatcher.js
cat > "$dest/src/dispatcher.js" <<'DISPATCHERJS'
export const RETRY_DEFAULTS = Object.freeze({
  maxAttempts: 3,
  baseDelayMs: 25,
  jitterCapMs: 200,
});

const realSleep = (delayMs) => new Promise((resolve) => setTimeout(resolve, delayMs));

// Drains a queue through a handler, retrying a failed job up to `maxAttempts`
// times. `sleep` and `jitter` are injectable so a test never waits for a timer.
export async function dispatch(
  queue,
  handler,
  {
    log = () => {},
    sleep = realSleep,
    jitter = Math.random,
    metrics = null,
    maxAttempts = RETRY_DEFAULTS.maxAttempts,
    baseDelayMs = RETRY_DEFAULTS.baseDelayMs,
    jitterCapMs = RETRY_DEFAULTS.jitterCapMs,
  } = {},
) {
  const processed = [];
  const failed = [];

  while (queue.size > 0) {
    const job = queue.dequeue();
    const id = job && job.id !== undefined ? job.id : 'job';
    let attempts = 0;
    let lastError;
    let result;
    let ok = false;

    while (attempts < maxAttempts) {
      attempts += 1;
      if (metrics) metrics.inc('jobs');
      try {
        result = await handler(job);
        ok = true;
        break;
      } catch (error) {
        lastError = error;
        if (attempts < maxAttempts) {
          const base = baseDelayMs * 2 ** (attempts - 1);
          await sleep(Math.floor(jitter() * base));
        }
      }
    }

    if (ok) {
      processed.push({ job, result, attempts });
      if (metrics) metrics.recordJob('processed');
      log(`ok ${id}`);
    } else {
      failed.push({ job, error: lastError, attempts });
      if (metrics) metrics.recordJob('failed');
      log(`fail ${id}: ${lastError.message}`);
    }
  }

  return { processed, failed, total: processed.length + failed.length };
}
DISPATCHERJS

# ------------------------------------------------------------- src/registry.js
cat > "$dest/src/registry.js" <<'REGISTRYJS'
import { readdirSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

export class RegistryError extends Error {
  constructor(message) {
    super(message);
    this.name = 'RegistryError';
  }
}

// Loads every `*.js` file in a directory as a plugin. A plugin is a module whose
// default export (or module namespace) carries a `name` string and a `run`
// function; anything else fails closed rather than being skipped silently.
export function createRegistry({
  dir,
  listFiles = (directory) => readdirSync(directory),
  loadModule = async (file) => import(pathToFileURL(file).href),
} = {}) {
  if (typeof dir !== 'string' || dir === '') {
    throw new RegistryError('registry dir must be a non-empty string');
  }

  async function load() {
    let names;
    try {
      names = listFiles(dir);
    } catch (error) {
      throw new RegistryError(`cannot list plugins: ${error.message}`);
    }

    const plugins = new Map();
    for (const name of names.filter((file) => file.endsWith('.js')).sort()) {
      const module = await loadModule(join(dir, name));
      const plugin = module && module.default ? module.default : module;
      if (!plugin || typeof plugin.name !== 'string' || typeof plugin.run !== 'function') {
        throw new RegistryError(`plugin ${name} must export a name and a run function`);
      }
      if (plugins.has(plugin.name)) {
        throw new RegistryError(`duplicate plugin name: ${plugin.name}`);
      }
      plugins.set(plugin.name, plugin);
    }
    return plugins;
  }

  return { dir, load };
}
REGISTRYJS

# ------------------------------------------------------------ src/scheduler.js
cat > "$dest/src/scheduler.js" <<'SCHEDULERJS'
export function createScheduler({ now = () => Date.now() } = {}) {
  const entries = [];

  return {
    get size() {
      return entries.length;
    },
    add(job, runAt) {
      if (!Number.isFinite(runAt)) {
        throw new RangeError(`runAt must be a finite number, got: ${runAt}`);
      }
      entries.push({ job, runAt });
      entries.sort((a, b) => a.runAt - b.runAt);
      return entries.length;
    },
    due() {
      const at = now();
      return entries.filter((entry) => entry.runAt <= at).map((entry) => entry.job);
    },
    async tick(handler) {
      const at = now();
      const ready = entries.filter((entry) => entry.runAt <= at);
      for (const entry of ready) {
        await handler(entry.job);
        const index = entries.indexOf(entry);
        if (index !== -1) entries.splice(index, 1);
      }
      return ready.length;
    },
  };
}
SCHEDULERJS

# ---------------------------------------------------------------- src/cli.js
cat > "$dest/src/cli.js" <<'CLIJS'
export class CliError extends Error {
  constructor(message) {
    super(message);
    this.name = 'CliError';
  }
}

const COMMANDS = new Set(['run', 'status']);
const FLAGS = new Set([
  'PORT',
  'LOG_LEVEL',
  'QUEUE_CAPACITY',
  'STORE_PATH',
  'JOBS',
  'DRY_RUN',
]);

export function parseArgs(argv = []) {
  const flags = {};
  const positional = [];
  let command = 'run';

  for (const arg of argv) {
    if (typeof arg !== 'string' || arg === '') {
      throw new CliError(`arguments must be non-empty strings, got: ${String(arg)}`);
    }
    if (arg.startsWith('--')) {
      const body = arg.slice(2);
      const eq = body.indexOf('=');
      const name = eq === -1 ? body : body.slice(0, eq);
      const value = eq === -1 ? true : body.slice(eq + 1);
      if (name === '') throw new CliError('empty flag name');
      if (!FLAGS.has(name)) throw new CliError(`unknown flag: --${name}`);
      flags[name] = value;
    } else if (COMMANDS.has(arg) && positional.length === 0) {
      command = arg;
    } else {
      positional.push(arg);
    }
  }

  if (positional.length > 0) {
    throw new CliError(`unexpected argument: ${positional[0]}`);
  }
  return { command, flags };
}

export const CLI_FLAGS = Object.freeze([...FLAGS]);
export const CLI_COMMANDS = Object.freeze([...COMMANDS]);
CLIJS

# ---------------------------------------------------------------- src/app.js
cat > "$dest/src/app.js" <<'APPJS'
import { CliError, parseArgs } from './cli.js';
import { ConfigError, loadConfig } from './config.js';
import { dispatch } from './dispatcher.js';
import { createMetrics } from './metrics.js';
import { createQueue } from './queue.js';
import { createStore } from './store.js';

// Wires a store, a queue and the counters together. `run` drains the queue,
// records each job's outcome, and returns the dispatcher's result.
export function createRunner({ store, queue, metrics = createMetrics(), now = () => Date.now(), log = () => {} } = {}) {
  async function enqueue(ids) {
    for (const id of ids) {
      store.append({ type: 'enqueue', id, at: now() });
      queue.enqueue({ id });
    }
    return queue.size;
  }

  async function run(handler) {
    const result = await dispatch(queue, handler, { metrics, log });
    for (const entry of result.processed) {
      store.append({ type: 'done', id: entry.job.id, at: now() });
    }
    for (const entry of result.failed) {
      store.append({ type: 'failed', id: entry.job.id, at: now() });
    }
    return result;
  }

  function status() {
    const records = store.readAll();
    return {
      pending: records.filter((record) => record.type === 'enqueue').length,
      done: records.filter((record) => record.type === 'done').length,
      failed: records.filter((record) => record.type === 'failed').length,
    };
  }

  return { enqueue, run, status };
}

export async function main(argv = [], env = {}, io = { out: () => {}, err: () => {} }) {
  try {
    const { command, flags } = parseArgs(argv);
    const overrides = {};
    for (const [name, value] of Object.entries(flags)) {
      if (name === 'DRY_RUN' || name === 'JOBS') continue;
      overrides[name] = value;
    }
    const config = loadConfig({ ...env, ...overrides });

    if (flags.DRY_RUN === true || flags.DRY_RUN === '1' || flags.DRY_RUN === 'true') {
      io.out(`dry-run port=${config.port} level=${config.level} capacity=${config.capacity}`);
      return { exitCode: 0, config };
    }

    const store = createStore({ path: config.storePath });
    const queue = createQueue({ capacity: config.capacity });
    const runner = createRunner({ store, queue });

    if (command === 'status') {
      const counts = runner.status();
      io.out(`pending=${counts.pending} done=${counts.done} failed=${counts.failed}`);
      return { exitCode: 0, config, status: counts };
    }

    const ids = String(flags.JOBS === undefined ? '' : flags.JOBS).split(',').filter(Boolean);
    await runner.enqueue(ids);
    const result = await runner.run(async (job) => job.id);
    io.out(`processed=${result.processed.length} failed=${result.failed.length} total=${result.total}`);
    return { exitCode: 0, config, result };
  } catch (error) {
    if (error instanceof ConfigError || error instanceof CliError) {
      io.err(`error: ${error.message}`);
      return { exitCode: 2, error };
    }
    throw error;
  }
}
APPJS

# -------------------------------------------------------------------- src/bin
cat > "$dest/src/bin.js" <<'BINJS'
import { main } from './app.js';

const result = await main(process.argv.slice(2), process.env, {
  out: (line) => process.stdout.write(`${line}\n`),
  err: (line) => process.stderr.write(`${line}\n`),
});

process.exitCode = result.exitCode;
BINJS

# ------------------------------------------------------------ docs and specs
cat > "$dest/docs/ARCHITECTURE.md" <<'ARCH'
# Architecture

`jobsvc` is a job service with a queue in front of a handler and an append-only
store behind it.

| Module | Owns |
|---|---|
| `src/config.js` | Environment and flag validation; the shape of a resolved configuration |
| `src/cli.js` | Argument parsing: commands, flags, and what is rejected |
| `src/app.js` | Wiring, batch intake, the run loop, and the operator's status view |
| `src/queue.js` | The bounded FIFO: capacity, order, and what overflow means |
| `src/dispatcher.js` | Draining the queue through a handler, retries, and backoff |
| `src/store.js` | The append-only record log and how records are read back |
| `src/metrics.js` | Counters |
| `src/registry.js` | Loading plugins from a directory |
| `src/scheduler.js` | Which jobs are due, and running them |

## Invariants

These hold across modules. A change that breaks one is a defect even when its own
tests pass.

**I1 — the store is append-only.** A record is written once and never rewritten
or reordered. Anything that needs to reinterpret an old record does it on read,
in `createStore`, so an older file stays readable by a newer build.

**I2 — a job is pending, or done, or failed, and never two of those at once.**
Every `enqueue` record opens a job and exactly one `done` or `failed` record
closes it. A closed job is not pending, and the operator's status view has to
agree with that: a job whose `done` record exists is done, not pending.

**I3 — counters describe jobs, not attempts.** `jobs` counts jobs the dispatcher
handled. Retrying a job inside the dispatcher is one job, so a retry must not
move that counter again. `processed` and `failed` count jobs by outcome.

## Reading the store

`createStore` is the only reader. It replays the log; nothing else may assume
that a record's position in the file means anything, and nothing may rewrite a
line to fix it up.
ARCH

cat > "$dest/docs/adr/0001-store-format.md" <<'ADR1'
# ADR 0001 — An append-only record log

- Status: accepted
- Date: 2026-11-01

## Context

Job state has to survive a restart without a database, and the service ships with
zero dependencies. A record log is the smallest thing that does that: one JSON
object per line, appended in the order things happened.

## Decision

The store is append-only. A record carries a `type` and the fields that type
needs; `enqueue` opens a job, `done` and `failed` close it. Readers replay the log
rather than trusting position, and a record is never rewritten in place.

The first format carries **no version field**. A reader therefore cannot tell one
generation of records from another, which is a gap rather than a decision: when a
record's shape has to change, the change lands as a new generation that a reader
must still be able to mix with files written before it.

## Consequences

- Recovery is a replay, so a partially written batch is visible as records.
- Mixing generations is expected, not exceptional; a reader must handle both.
- A record that cannot be parsed is an error, never skipped silently: skipping a
  line would turn a corrupt store into a quietly wrong status view.
ADR1

cat > "$dest/docs/adr/0002-metrics-idempotency.md" <<'ADR2'
# ADR 0002 — Counters count jobs, not attempts

- Status: accepted
- Date: 2026-11-01

## Context

The dispatcher retries a failed job. Whatever the counters mean, a reader of the
status view has to be able to read `jobs` as "work the service handled" without
knowing how many attempts anything took.

## Decision

`jobs` counts jobs, once each, however many attempts the dispatcher needed.
`processed` and `failed` count jobs by final outcome. Attempt detail belongs to
the job's result entry, not to the counters, so a retry never moves a counter
twice and the counter set stays three fixed names.

Consequence: the fix for a counter that moves per attempt belongs at the site
that increments it, not in a filter over the counter. A deduplicating counter
would make the number right while making the meaning wrong, and every future
caller would have to know about the filter.
ADR2

cat > "$dest/specs/backpressure.spec.js" <<'SPECBP'
// Behavioral spec for store backpressure during batch intake.
//
// This spec is a contract, not a test of the current implementation: `jobsvc`
// does not satisfy it yet. It is not picked up by a bare `node --test` because
// it lives outside `test/`; run it explicitly:
//
//   node --test specs/backpressure.spec.js
//
// Editing this file is out of scope for any change: it describes the required
// behavior, so a change that makes it pass by rewriting it has changed nothing.
import test from 'node:test';
import assert from 'node:assert';

import { BackpressureError, createRunner } from '../src/app.js';
import { createQueue } from '../src/queue.js';

function storeThatRejectsAfter(accepted) {
  const written = [];
  let calls = 0;
  return {
    written,
    append(record) {
      calls += 1;
      if (calls > accepted) throw new Error('store is unavailable');
      written.push(record);
      return record;
    },
    readAll() {
      return written;
    },
  };
}

test('a batch the store rejects leaves the queue unchanged and fails loudly', async () => {
  const store = storeThatRejectsAfter(1);
  const queue = createQueue({ capacity: 10 });
  const runner = createRunner({ store, queue });

  await assert.rejects(
    () => runner.enqueue(['a', 'b', 'c']),
    (error) => error instanceof BackpressureError && error.attempted === 3,
  );

  assert.equal(queue.size, 0);
  assert.equal(store.written.length, 1);
});

test('a batch the store accepts adds every job downstream', async () => {
  const store = storeThatRejectsAfter(3);
  const queue = createQueue({ capacity: 10 });
  const runner = createRunner({ store, queue });

  assert.equal(await runner.enqueue(['a', 'b', 'c']), 3);
  assert.equal(queue.size, 3);
  assert.deepEqual(store.written.map((record) => record.id), ['a', 'b', 'c']);
});

test('an empty batch is a no-op that returns the current size', async () => {
  const store = storeThatRejectsAfter(0);
  const queue = createQueue({ capacity: 5 });
  const runner = createRunner({ store, queue });

  assert.equal(await runner.enqueue([]), 0);
  assert.equal(store.written.length, 0);
});
SPECBP

# --------------------------------------------------------------------- tests
cat > "$dest/test/config.test.js" <<'CONFIGTEST'
import test from 'node:test';
import assert from 'node:assert';

import { ConfigError, LOG_LEVELS, loadConfig } from '../src/config.js';

test('defaults when the environment is empty', () => {
  const config = loadConfig({});
  assert.equal(config.port, 8080);
  assert.equal(config.level, 'info');
  assert.equal(config.capacity, 100);
  assert.equal(config.jitterCapMs, 200);
  assert.equal(config.storePath, 'data/jobs.jsonl');
});

test('reads PORT, LOG_LEVEL, QUEUE_CAPACITY, JITTER_CAP_MS and STORE_PATH', () => {
  const config = loadConfig({
    PORT: '9090',
    LOG_LEVEL: 'warn',
    QUEUE_CAPACITY: '7',
    JITTER_CAP_MS: '50',
    STORE_PATH: '/tmp/jobs.jsonl',
  });
  assert.equal(config.port, 9090);
  assert.equal(config.level, 'warn');
  assert.equal(config.capacity, 7);
  assert.equal(config.jitterCapMs, 50);
  assert.equal(config.storePath, '/tmp/jobs.jsonl');
});

test('accepts LOG_LEVEL case-insensitively', () => {
  assert.equal(loadConfig({ LOG_LEVEL: 'WARN' }).level, 'warn');
  assert.equal(loadConfig({ LOG_LEVEL: 'Debug' }).level, 'debug');
});

test('exposes the accepted levels', () => {
  assert.deepEqual([...LOG_LEVELS], ['debug', 'info', 'warn', 'error']);
});

test('rejects a PORT that is not a positive integer, and one above the range', () => {
  for (const raw of ['0', '-1', '6.5', 'abc']) {
    assert.throws(() => loadConfig({ PORT: raw }), ConfigError, `PORT=${raw}`);
  }
  assert.throws(() => loadConfig({ PORT: '70000' }), ConfigError);
});

test('rejects an unknown log level and names the accepted set', () => {
  assert.throws(() => loadConfig({ LOG_LEVEL: 'verbose' }), /LOG_LEVEL must be one of/);
});

test('rejects a non-positive capacity and a non-positive jitter cap', () => {
  assert.throws(() => loadConfig({ QUEUE_CAPACITY: '0' }), ConfigError);
  assert.throws(() => loadConfig({ JITTER_CAP_MS: '-5' }), ConfigError);
});

test('returns a frozen configuration object', () => {
  assert.ok(Object.isFrozen(loadConfig({})));
});
CONFIGTEST

cat > "$dest/test/store.test.js" <<'STORETEST'
import test from 'node:test';
import assert from 'node:assert';

import { StoreError, createStore } from '../src/store.js';

function memoryIo(initial = '') {
  const files = new Map();
  if (initial !== '') files.set('/s/jobs.jsonl', initial);
  const dirs = new Set();
  return {
    files,
    dirs,
    appends: [],
    existsSync: (path) => files.has(path) || dirs.has(path),
    mkdirSync: (path) => dirs.add(path),
    appendFileSync: (path, text) => {
      files.set(path, (files.get(path) || '') + text);
    },
    readFileSync: (path) => {
      if (!files.has(path)) throw new Error('ENOENT');
      return files.get(path);
    },
  };
}

test('appends one JSON line per record', () => {
  const io = memoryIo();
  const store = createStore({ path: '/s/jobs.jsonl', io });
  store.append({ type: 'enqueue', id: 'a' });
  store.append({ type: 'done', id: 'a' });

  // Shape, not bytes: the format is allowed to grow (an added field must not
  // make this assertion fail), but one record per line is the contract.
  const lines = io.files.get('/s/jobs.jsonl').split('\n').filter(Boolean);
  assert.equal(lines.length, 2);
  assert.deepEqual(lines.map((line) => JSON.parse(line).type), ['enqueue', 'done']);
  assert.deepEqual(lines.map((line) => JSON.parse(line).id), ['a', 'a']);
});

test('creates the parent directory when it is missing', () => {
  const io = memoryIo();
  const store = createStore({ path: '/s/jobs.jsonl', io });
  store.append({ type: 'enqueue', id: 'a' });
  assert.ok(io.dirs.has('/s'));
});

test('reads an absent store as empty', () => {
  const store = createStore({ path: '/s/jobs.jsonl', io: memoryIo() });
  assert.deepEqual(store.readAll(), []);
});

test('reads records back in order', () => {
  const io = memoryIo();
  const store = createStore({ path: '/s/jobs.jsonl', io });
  assert.deepEqual(store.readAll(), []);
  store.append({ type: 'enqueue', id: 'a' });
  store.append({ type: 'done', id: 'a' });
  assert.deepEqual(store.readAll().map((record) => record.type), ['enqueue', 'done']);
  assert.deepEqual(store.readAll().map((record) => record.id), ['a', 'a']);
});

test('fails closed on a line that is not JSON', () => {
  const store = createStore({ path: '/s/jobs.jsonl', io: memoryIo('{"type":"enqueue"}\nnot json\n') });
  assert.throws(() => store.readAll(), StoreError);
});

test('fails closed on a record without a type', () => {
  const store = createStore({ path: '/s/jobs.jsonl', io: memoryIo('{"id":"a"}\n') });
  assert.throws(() => store.readAll(), /missing its type/);
});

test('wraps a failing write in a StoreError', () => {
  const io = memoryIo();
  io.appendFileSync = () => {
    throw new Error('disk on fire');
  };
  const store = createStore({ path: '/s/jobs.jsonl', io });
  assert.throws(() => store.append({ type: 'enqueue', id: 'a' }), /append failed: disk on fire/);
});

test('refuses a non-object record and an empty path', () => {
  const store = createStore({ path: '/s/jobs.jsonl', io: memoryIo() });
  assert.throws(() => store.append(null), StoreError);
  assert.throws(() => createStore({ path: '' }), StoreError);
});
STORETEST

cat > "$dest/test/queue.test.js" <<'QUEUETEST'
import test from 'node:test';
import assert from 'node:assert';

import { QueueFullError, createQueue } from '../src/queue.js';

test('dequeues in FIFO order and reports size', () => {
  const queue = createQueue({ capacity: 3 });
  queue.enqueue('a');
  queue.enqueue('b');
  assert.equal(queue.size, 2);
  assert.equal(queue.dequeue(), 'a');
  assert.equal(queue.dequeue(), 'b');
  assert.equal(queue.size, 0);
});

test('returns undefined when empty', () => {
  assert.equal(createQueue().dequeue(), undefined);
});

test('refuses to exceed capacity and names the capacity', () => {
  const queue = createQueue({ capacity: 1 });
  queue.enqueue('a');
  assert.equal(queue.isFull, true);
  assert.throws(
    () => queue.enqueue('b'),
    (error) => error instanceof QueueFullError && error.capacity === 1,
  );
});

test('reports isFull at the capacity boundary', () => {
  const queue = createQueue({ capacity: 2 });
  assert.equal(queue.isFull, false);
  queue.enqueue('a');
  assert.equal(queue.isFull, false);
  queue.enqueue('b');
  assert.equal(queue.isFull, true);
});

test('rejects a capacity below one and a fractional capacity', () => {
  assert.throws(() => createQueue({ capacity: 0 }), RangeError);
  assert.throws(() => createQueue({ capacity: 2.5 }), RangeError);
});

test('accepts an unbounded capacity and never reports full', () => {
  const queue = createQueue({ capacity: Number.POSITIVE_INFINITY });
  for (let i = 0; i < 500; i += 1) queue.enqueue(i);
  assert.equal(queue.size, 500);
  assert.equal(queue.isFull, false);
});

test('enqueueMany appends in order and returns the new size', () => {
  const queue = createQueue({ capacity: 5 });
  queue.enqueue('a');
  assert.equal(queue.enqueueMany(['b', 'c']), 3);
  assert.deepEqual(queue.drain(), ['a', 'b', 'c']);
});

test('enqueueMany is atomic when the batch does not fit', () => {
  const queue = createQueue({ capacity: 3 });
  queue.enqueue('a');
  assert.throws(() => queue.enqueueMany(['b', 'c', 'd']), QueueFullError);
  assert.equal(queue.size, 1);
  assert.equal(queue.dequeue(), 'a');
});

test('enqueueMany with an empty batch is a no-op', () => {
  const queue = createQueue({ capacity: 2 });
  queue.enqueue('a');
  assert.equal(queue.enqueueMany([]), 1);
  assert.equal(queue.size, 1);
});

test('peek returns the head without consuming it', () => {
  const queue = createQueue({ capacity: 3 });
  assert.equal(queue.peek(), undefined);
  queue.enqueue('a');
  queue.enqueue('b');
  assert.equal(queue.peek(), 'a');
  assert.equal(queue.peek(), 'a');
  assert.equal(queue.size, 2);
});

test('drain empties the queue and returns the items in order', () => {
  const queue = createQueue({ capacity: 4 });
  queue.enqueue('a');
  queue.enqueue('b');
  assert.deepEqual(queue.drain(), ['a', 'b']);
  assert.equal(queue.size, 0);
  assert.equal(queue.isFull, false);
});
QUEUETEST

cat > "$dest/test/metrics.test.js" <<'METRICSTEST'
import test from 'node:test';
import assert from 'node:assert';

import { METRIC_NAMES, createMetrics } from '../src/metrics.js';

test('starts at zero', () => {
  assert.deepEqual(createMetrics().snapshot(), { jobs: 0, processed: 0, failed: 0 });
});

test('increments a counter and reports its new value', () => {
  const metrics = createMetrics();
  assert.equal(metrics.inc('jobs'), 1);
  assert.equal(metrics.inc('jobs', 2), 3);
  assert.equal(metrics.snapshot().jobs, 3);
});

test('refuses an unknown counter and a non-integer increment', () => {
  const metrics = createMetrics();
  assert.throws(() => metrics.inc('attempts'), RangeError);
  assert.throws(() => metrics.inc('jobs', 1.5), RangeError);
});

test('records a job outcome and refuses anything else', () => {
  const metrics = createMetrics();
  assert.equal(metrics.recordJob('processed'), 1);
  assert.equal(metrics.recordJob('failed'), 1);
  assert.deepEqual(metrics.snapshot(), { jobs: 0, processed: 1, failed: 1 });
  assert.throws(() => metrics.recordJob('retried'), RangeError);
});

test('exposes the counter names', () => {
  assert.deepEqual([...METRIC_NAMES], ['jobs', 'processed', 'failed']);
});

test('a snapshot is frozen and a copy, and reset clears the counters', () => {
  const metrics = createMetrics();
  metrics.inc('jobs');
  const snapshot = metrics.snapshot();
  assert.ok(Object.isFrozen(snapshot));
  metrics.inc('jobs');
  assert.equal(snapshot.jobs, 1);
  metrics.reset();
  assert.deepEqual(metrics.snapshot(), { jobs: 0, processed: 0, failed: 0 });
});
METRICSTEST

cat > "$dest/test/dispatcher.test.js" <<'DISPATCHERTEST'
import test from 'node:test';
import assert from 'node:assert';

import { dispatch } from '../src/dispatcher.js';
import { createMetrics } from '../src/metrics.js';
import { createQueue } from '../src/queue.js';

function queueWith(...ids) {
  const queue = createQueue({ capacity: ids.length + 1 });
  for (const id of ids) queue.enqueue({ id });
  return queue;
}

test('processes every job in order and records one attempt each', async () => {
  const queue = queueWith('a', 'b');
  const result = await dispatch(queue, async (job) => job.id.toUpperCase());

  assert.equal(result.total, 2);
  assert.deepEqual(result.processed.map((entry) => entry.result), ['A', 'B']);
  assert.deepEqual(result.processed.map((entry) => entry.attempts), [1, 1]);
  assert.deepEqual(result.failed, []);
});

test('records a failure with its last error and attempt count', async () => {
  const queue = queueWith('bad');
  const result = await dispatch(
    queue,
    async () => {
      throw new Error('boom');
    },
    { maxAttempts: 2, sleep: async () => {} },
  );

  assert.equal(result.processed.length, 0);
  assert.equal(result.failed.length, 1);
  assert.equal(result.failed[0].attempts, 2);
  assert.equal(result.failed[0].error.message, 'boom');
});

test('retries a failing job and records it once when it succeeds', async () => {
  const queue = queueWith('flaky');
  const lines = [];
  let calls = 0;

  const result = await dispatch(
    queue,
    async () => {
      calls += 1;
      if (calls < 2) throw new Error('transient');
      return 'ok';
    },
    { sleep: async () => {}, log: (line) => lines.push(line) },
  );

  assert.equal(calls, 2);
  assert.equal(result.processed.length, 1);
  assert.equal(result.processed[0].attempts, 2);
  assert.equal(result.failed.length, 0);
  assert.deepEqual(lines, ['ok flaky']);
});

test('waits between attempts and not before the first or after the last', async () => {
  const queue = queueWith('doomed');
  const delays = [];

  await dispatch(
    queue,
    async () => {
      throw new Error('nope');
    },
    {
      maxAttempts: 3,
      baseDelayMs: 100,
      jitterCapMs: 1000,
      jitter: () => 0.5,
      sleep: async (delayMs) => {
        delays.push(delayMs);
      },
    },
  );

  assert.deepEqual(delays, [50, 100]);
});

test('maxAttempts of 1 makes a single attempt without sleeping', async () => {
  const queue = queueWith('once');
  let slept = false;
  let calls = 0;

  const result = await dispatch(
    queue,
    async () => {
      calls += 1;
      throw new Error('once');
    },
    {
      maxAttempts: 1,
      sleep: async () => {
        slept = true;
      },
    },
  );

  assert.equal(calls, 1);
  assert.equal(slept, false);
  assert.equal(result.failed[0].attempts, 1);
});

test('writes exactly one log line per job, at its final outcome', async () => {
  const queue = queueWith('a', 'bad');
  const lines = [];

  await dispatch(
    queue,
    async (job) => {
      if (job.id === 'bad') throw new Error('nope');
      return 'ok';
    },
    { maxAttempts: 1, log: (line) => lines.push(line) },
  );

  assert.deepEqual(lines, ['ok a', 'fail bad: nope']);
});

test('counts one job per job when nothing is retried', async () => {
  const queue = queueWith('a', 'b');
  const metrics = createMetrics();

  await dispatch(queue, async () => 'ok', { metrics, sleep: async () => {} });

  assert.deepEqual(metrics.snapshot(), { jobs: 2, processed: 2, failed: 0 });
});

test('returns an empty result for an empty queue', async () => {
  const result = await dispatch(createQueue(), async () => 'ok');
  assert.deepEqual(result.processed, []);
  assert.deepEqual(result.failed, []);
  assert.equal(result.total, 0);
});

test('falls back to a placeholder id when a job carries none', async () => {
  const queue = createQueue({ capacity: 2 });
  queue.enqueue({});
  const lines = [];
  await dispatch(queue, async () => 'ok', { maxAttempts: 1, log: (line) => lines.push(line) });
  assert.deepEqual(lines, ['ok job']);
});
DISPATCHERTEST

cat > "$dest/test/registry.test.js" <<'REGISTRYTEST'
import test from 'node:test';
import assert from 'node:assert';

import { RegistryError, createRegistry } from '../src/registry.js';

function loaderFor(modules) {
  return async (file) => {
    const name = file.split('/').pop();
    if (!Object.hasOwn(modules, name)) throw new Error(`no such plugin: ${name}`);
    return { default: modules[name] };
  };
}

test('loads every js file and keys plugins by name', async () => {
  const registry = createRegistry({
    dir: '/plugins',
    listFiles: () => ['b.js', 'a.js'],
    loadModule: loaderFor({ 'a.js': { name: 'alpha', run: async () => 1 }, 'b.js': { name: 'beta', run: async () => 2 } }),
  });

  const plugins = await registry.load();
  assert.deepEqual([...plugins.keys()], ['alpha', 'beta']);
  assert.equal(await plugins.get('beta').run(), 2);
});

test('fails closed on a plugin without a name or a run function', async () => {
  const registry = createRegistry({
    dir: '/plugins',
    listFiles: () => ['bad.js'],
    loadModule: loaderFor({ 'bad.js': { name: 'bad' } }),
  });
  await assert.rejects(() => registry.load(), /must export a name and a run function/);
});

test('refuses a duplicate plugin name', async () => {
  const registry = createRegistry({
    dir: '/plugins',
    listFiles: () => ['a.js', 'b.js'],
    loadModule: loaderFor({ 'a.js': { name: 'same', run: async () => 1 }, 'b.js': { name: 'same', run: async () => 2 } }),
  });
  await assert.rejects(() => registry.load(), /duplicate plugin name: same/);
});

test('ignores files that are not js and wraps a listing failure', async () => {
  const registry = createRegistry({
    dir: '/plugins',
    listFiles: () => ['README.md', 'a.js'],
    loadModule: loaderFor({ 'a.js': { name: 'alpha', run: async () => 1 } }),
  });
  assert.deepEqual([...(await registry.load()).keys()], ['alpha']);

  const broken = createRegistry({
    dir: '/missing',
    listFiles: () => {
      throw new Error('ENOENT');
    },
  });
  await assert.rejects(() => broken.load(), /cannot list plugins: ENOENT/);
});

test('requires a directory', () => {
  assert.throws(() => createRegistry({ dir: '' }), RegistryError);
  assert.throws(() => createRegistry(), RegistryError);
});
REGISTRYTEST

cat > "$dest/test/scheduler.test.js" <<'SCHEDULERTEST'
import test from 'node:test';
import assert from 'node:assert';

import { createScheduler } from '../src/scheduler.js';

test('reports what is due at the current time', () => {
  let at = 1000;
  const scheduler = createScheduler({ now: () => at });
  scheduler.add({ id: 'a' }, 1000);
  scheduler.add({ id: 'b' }, 2000);

  assert.deepEqual(scheduler.due(), [{ id: 'a' }]);
  at = 2500;
  assert.deepEqual(scheduler.due(), [{ id: 'a' }, { id: 'b' }]);
});

test('orders entries by due time regardless of insertion order', () => {
  const scheduler = createScheduler({ now: () => 3000 });
  scheduler.add({ id: 'late' }, 2000);
  scheduler.add({ id: 'early' }, 1000);
  assert.deepEqual(scheduler.due(), [{ id: 'early' }, { id: 'late' }]);
});

test('tick runs the due jobs in order, removes them, and reports how many ran', async () => {
  const scheduler = createScheduler({ now: () => 5000 });
  scheduler.add({ id: 'a' }, 1000);
  scheduler.add({ id: 'b' }, 4000);
  scheduler.add({ id: 'c' }, 9000);
  const seen = [];

  const ran = await scheduler.tick(async (job) => {
    seen.push(job.id);
  });

  assert.equal(ran, 2);
  assert.deepEqual(seen, ['a', 'b']);
  assert.equal(scheduler.size, 1);
});

test('size tracks what is scheduled', () => {
  const scheduler = createScheduler({ now: () => 0 });
  assert.equal(scheduler.size, 0);
  assert.equal(scheduler.add({ id: 'a' }, 10), 1);
  assert.equal(scheduler.size, 1);
});

test('refuses a runAt that is not a finite number', () => {
  const scheduler = createScheduler({ now: () => 0 });
  assert.throws(() => scheduler.add({ id: 'a' }, Number.NaN), RangeError);
  assert.throws(() => scheduler.add({ id: 'a' }, '1000'), RangeError);
});
SCHEDULERTEST

cat > "$dest/test/cli.test.js" <<'CLITEST'
import test from 'node:test';
import assert from 'node:assert';

import { CLI_COMMANDS, CLI_FLAGS, CliError, parseArgs } from '../src/cli.js';

test('defaults to the run command with no flags', () => {
  assert.deepEqual(parseArgs([]), { command: 'run', flags: {} });
  assert.deepEqual(parseArgs(['status']), { command: 'status', flags: {} });
});

test('parses values, bare flags and a job list', () => {
  const parsed = parseArgs(['run', '--PORT=9090', '--JOBS=a,b', '--QUEUE_CAPACITY=5']);
  assert.equal(parsed.command, 'run');
  assert.deepEqual(parsed.flags, { PORT: '9090', JOBS: 'a,b', QUEUE_CAPACITY: '5' });
  assert.equal(parseArgs(['--DRY_RUN']).flags.DRY_RUN, true);
  assert.equal(parseArgs(['--DRY_RUN=1']).flags.DRY_RUN, '1');
});

test('rejects an unknown flag by name', () => {
  assert.throws(() => parseArgs(['--BOGUS=1']), /unknown flag: --BOGUS/);
});

test('rejects an empty flag name and a non-string argument', () => {
  assert.throws(() => parseArgs(['--=1']), CliError);
  assert.throws(() => parseArgs([42]), CliError);
});

test('rejects a positional argument that is not a command', () => {
  assert.throws(() => parseArgs(['serve']), /unexpected argument: serve/);
  assert.throws(() => parseArgs(['run', 'extra']), CliError);
});

test('exposes the command and flag names', () => {
  assert.deepEqual([...CLI_COMMANDS], ['run', 'status']);
  assert.ok(CLI_FLAGS.includes('JOBS'));
  assert.ok(CLI_FLAGS.includes('DRY_RUN'));
});
CLITEST

cat > "$dest/test/integration.test.js" <<'INTTEST'
import test from 'node:test';
import assert from 'node:assert';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { createRunner, main } from '../src/app.js';
import { createQueue } from '../src/queue.js';
import { createStore } from '../src/store.js';

function fakeIo(initial = '') {
  const files = new Map();
  if (initial !== '') files.set('jobs.jsonl', initial);
  return {
    files,
    existsSync: (path) => files.has(path),
    mkdirSync: () => {},
    appendFileSync: (path, text) => {
      files.set(path, (files.get(path) || '') + text);
    },
    readFileSync: (path) => {
      if (!files.has(path)) throw new Error('ENOENT');
      return files.get(path);
    },
  };
}

function runnerOn(records) {
  const io = fakeIo(records.map((record) => JSON.stringify(record)).join('\n') + (records.length ? '\n' : ''));
  const store = createStore({ path: 'jobs.jsonl', io });
  const queue = createQueue({ capacity: 10 });
  return { io, store, queue, runner: createRunner({ store, queue, now: () => 7 }) };
}

test('a run records a done record for every job that succeeded', async () => {
  const { io, runner } = runnerOn([]);
  await runner.enqueue(['a', 'b']);
  const result = await runner.run(async (job) => job.id);

  assert.equal(result.total, 2);
  const written = io.readFileSync('jobs.jsonl');
  assert.match(written, /"type":"done","id":"a"/);
  assert.match(written, /"type":"done","id":"b"/);
});

test('a run records a failed record with the job id', async () => {
  const { io, runner } = runnerOn([]);
  await runner.enqueue(['bad']);
  await runner.run(async () => {
    throw new Error('nope');
  });
  assert.match(io.readFileSync('jobs.jsonl'), /"type":"failed","id":"bad"/);
});

test('status reports the number of finished jobs', async () => {
  const { runner } = runnerOn([]);
  await runner.enqueue(['a']);
  await runner.run(async (job) => job.id);
  assert.equal(runner.status().done, 1);
  assert.equal(runner.status().failed, 0);
});

test('a runner with a non-empty store still runs the jobs it was given', async () => {
  const { runner } = runnerOn([{ type: 'enqueue', id: 'old', at: 1 }, { type: 'done', id: 'old', at: 2 }]);
  const ran = [];
  await runner.enqueue(['fresh']);
  await runner.run(async (job) => {
    ran.push(job.id);
    return job.id;
  });
  assert.deepEqual(ran, ['fresh']);
});

test('main prints a dry-run line and returns without touching the store', async () => {
  const out = [];
  const result = await main(['--DRY_RUN=1', '--PORT=9090'], {}, { out: (line) => out.push(line), err: () => {} });

  // Only the dry-run line is asserted here: the flag's spelling and any advice
  // about it are the CLI's business, not this test's.
  assert.equal(result.exitCode, 0);
  assert.deepEqual(out, ['dry-run port=9090 level=info capacity=100']);
});

test('main runs a job list and reports the totals', async () => {
  const dir = join(tmpdir(), `phase3c-seed-${process.pid}-${Date.now()}.jsonl`);
  const out = [];
  const err = [];
  const result = await main(['run', '--JOBS=a,b', `--STORE_PATH=${dir}`], {}, { out: (line) => out.push(line), err: (line) => err.push(line) });

  assert.equal(result.exitCode, 0);
  assert.deepEqual(out, ['processed=2 failed=0 total=2']);
  assert.deepEqual(err, []);
});

test('main exits 2 and reports the reason for a bad flag or config', async () => {
  const out = [];
  const err = [];
  const bad = await main(['--BOGUS=1'], {}, { out: (line) => out.push(line), err: (line) => err.push(line) });
  assert.equal(bad.exitCode, 2);
  assert.match(err[0], /unknown flag: --BOGUS/);

  const badConfig = await main(['--LOG_LEVEL=verbose'], {}, { out: () => {}, err: (line) => err.push(line) });
  assert.equal(badConfig.exitCode, 2);
  assert.match(err.at(-1), /LOG_LEVEL must be one of/);
});
INTTEST

# ------------------------------------------------------------------- commit
# --template= and --no-verify keep host git configuration out of this commit, and
# core.autocrlf=false belongs on the add as well as the commit: setting it only
# on commit is too late, because the index is already written.
git -C "$dest" -c init.defaultBranch=main init -q --template= || die "git init failed"
git -C "$dest" -c core.autocrlf=false -c core.filemode=false add -A || die "git add failed"

GIT_AUTHOR_DATE='2000-01-01T00:00:00+0000' \
GIT_COMMITTER_DATE='2000-01-01T00:00:00+0000' \
git -C "$dest" -c user.name='promptkit-bench' -c user.email='bench@invalid' \
    -c commit.gpgsign=false -c core.autocrlf=false \
    commit -q --no-verify -m 'feat: add the neutral Phase 3c benchmark seed' \
    || die "seed commit failed"

sha=$(git -C "$dest" rev-parse HEAD) || die "cannot read seed SHA"
files=$(git -C "$dest" ls-files | wc -l | tr -d ' ')

printf 'SEED|OK|sha=%s|files=%s|path=%s\n' "$sha" "$files" "$dest"
