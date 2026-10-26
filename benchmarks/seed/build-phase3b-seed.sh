#!/usr/bin/env bash
# Build the purpose-built neutral seed repository for the Phase 3b A/B benchmark.
#
#   build-phase3b-seed.sh <dest-dir>
#
# Phase 3b (benchmarks/PHASE-3B-PROTOCOL.md section 3.1) requires both arms to
# start from the same neutral clone. The preferred seed is a real consumer
# repository; the sanctioned fallback is a neutralized copy of this repository.
# That fallback is refused by benchmarks/seed/neutralize.sh on this repository
# today, because 26 tracked files carry a `heyloey` reference and 18 of them are
# dated release, review, and transcript records that must not be rewritten to
# manufacture a clean seed. This script is the third shape: a seed that was
# never contaminated in the first place.
#
# The tree it writes carries no agent-instruction surface and no `heyloey`
# reference, so neutralize.sh accepts it with `removed=0` and the seed SHA is
# the builder's own commit SHA. It is synthetic - it has a backlog, but not a
# real one - so a batch run against it must be labeled accordingly.
#
# Zero runtime dependencies: the test suite uses Node's built-in runner
# (`node --test`), so a fresh clone runs its tests with no install step and no
# network access. Section 3.1 requires the neutral seed's tests to pass, and
# Appendix D requires every task Verify command to run against it.
#
# Deterministic: fixed author/committer identity and date, so identical content
# produces an identical SHA on any host and Appendix B can pin it.
#
# Like benchmarks/seed/neutralize.sh this is operator-local Bash with no
# PowerShell twin: it writes files and drives git, not a CLI, so CI covers it
# with a syntax check plus the end-to-end preflight recorded below.
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

[[ $# -eq 1 ]] || die "usage: build-phase3b-seed.sh <dest-dir>"
dest=${1%/}
[[ -n "$dest" ]] || die "empty dest path"

command -v git >/dev/null 2>&1 || die "git is not on PATH"

# Refuse anything that already exists, rather than overwriting a directory this
# script did not create. neutralize.sh applies the same rule to its own dest.
if [[ -e "$dest" || -L "$dest" ]]; then
    die "dest exists, so it was left untouched: $dest"
fi

mkdir -p -- "$dest/src" "$dest/test" || die "cannot create seed directories: $dest"

cat > "$dest/package.json" <<'PKGJSON'
{
  "name": "phase3b-seed",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "description": "Small job-queue service used as the neutral Phase 3b benchmark seed.",
  "scripts": {
    "test": "node --test"
  },
  "engines": {
    "node": ">=20"
  }
}
PKGJSON

cat > "$dest/.gitignore" <<'GITIGNORE'
node_modules/
coverage/
*.log
GITIGNORE

cat > "$dest/README.md" <<'README'
# phase3b-seed

A small job-queue service. It reads its configuration from the environment and
from command-line flags, builds a bounded FIFO queue, and drains it through a
handler.

## Running the tests

```sh
node --test
```

There is no install step: the service has no runtime dependencies and the
suite uses Node's built-in test runner. Node 20 or newer.

## Layout

| Path | Purpose |
|---|---|
| `src/app.js` | CLI entry point, flag parsing, configuration wiring |
| `src/config.js` | Environment and flag validation |
| `src/queue.js` | Bounded FIFO queue |
| `src/dispatcher.js` | Drains a queue through a handler, collecting failures |
| `test/` | Unit tests for each module |
| `BACKLOG.md` | Known gaps and proposed work |
README

cat > "$dest/BACKLOG.md" <<'BACKLOG'
# Backlog

Open work, roughly in the order it would be picked up. Nothing here is
committed to a milestone.

- `queue`: expose `peek()` so a caller can read the head without consuming it.
- `dispatcher`: retry transient handler failures with exponential backoff and a
  per-job attempt cap, and record the attempt count on each processed entry.
- `dispatcher`: return a summary count of processed and failed jobs so callers
  do not have to measure the arrays.
- `config`: allow `QUEUE_CAPACITY=unbounded` for callers that manage their own
  backpressure.
- `app`: add a `--DRY_RUN` flag that validates configuration and exits without
  constructing a queue.
- `queue`: add `enqueueMany()` that is atomic - either every item fits or none
  is added.
BACKLOG

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
    throw new ConfigError(`PORT must be between 1 and 65535, got: ${port}`);
  }

  const level = String(env.LOG_LEVEL ?? 'info').toLowerCase();
  if (!LEVELS.includes(level)) {
    throw new ConfigError(`LOG_LEVEL must be one of ${LEVELS.join(', ')}, got: ${env.LOG_LEVEL}`);
  }

  const capacity = positiveInt(env.QUEUE_CAPACITY, 100, 'QUEUE_CAPACITY');

  return Object.freeze({ port, level, capacity });
}

export const LOG_LEVELS = Object.freeze([...LEVELS]);
CONFIGJS

cat > "$dest/src/queue.js" <<'QUEUEJS'
export class QueueFullError extends Error {
  constructor(capacity) {
    super(`queue is full (capacity ${capacity})`);
    this.name = 'QueueFullError';
    this.capacity = capacity;
  }
}

export function createQueue({ capacity = 100 } = {}) {
  if (!Number.isInteger(capacity) || capacity < 1) {
    throw new RangeError(`capacity must be a positive integer, got: ${capacity}`);
  }

  const items = [];

  return {
    capacity,
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
    dequeue() {
      return items.length === 0 ? undefined : items.shift();
    },
    drain() {
      return items.splice(0, items.length);
    },
  };
}
QUEUEJS

cat > "$dest/src/dispatcher.js" <<'DISPATCHERJS'
export async function dispatch(queue, handler, { log = () => {} } = {}) {
  const processed = [];
  const failed = [];

  while (queue.size > 0) {
    const job = queue.dequeue();
    const id = job && job.id !== undefined ? job.id : 'job';
    try {
      const result = await handler(job);
      processed.push({ job, result });
      log(`ok ${id}`);
    } catch (error) {
      failed.push({ job, error });
      log(`fail ${id}: ${error.message}`);
    }
  }

  return { processed, failed, total: processed.length + failed.length };
}
DISPATCHERJS

cat > "$dest/src/app.js" <<'APPJS'
import { ConfigError, loadConfig } from './config.js';
import { createQueue } from './queue.js';

const FLAGS = new Set(['PORT', 'LOG_LEVEL', 'QUEUE_CAPACITY']);

export function parseFlags(argv = []) {
  const flags = {};

  for (const arg of argv) {
    if (!arg.startsWith('--')) {
      throw new ConfigError(`unexpected argument: ${arg}`);
    }

    const body = arg.slice(2);
    const eq = body.indexOf('=');
    const name = eq === -1 ? body : body.slice(0, eq);
    const value = eq === -1 ? 'true' : body.slice(eq + 1);

    if (!name) throw new ConfigError('empty flag name');
    if (!FLAGS.has(name)) throw new ConfigError(`unknown flag: --${name}`);

    flags[name] = value;
  }

  return flags;
}

export function main(argv = [], env = {}, io = { out: () => {}, err: () => {} }) {
  try {
    const config = loadConfig({ ...env, ...parseFlags(argv) });
    const queue = createQueue({ capacity: config.capacity });
    io.out(`ready port=${config.port} level=${config.level} capacity=${config.capacity}`);
    return { exitCode: 0, config, queue };
  } catch (error) {
    if (error instanceof ConfigError) {
      io.err(`configuration error: ${error.message}`);
      return { exitCode: 2, error };
    }
    throw error;
  }
}

if (process.argv[1] && import.meta.url === `file://${process.argv[1]}`) {
  const { exitCode } = main(process.argv.slice(2), process.env, {
    out: (line) => process.stdout.write(`${line}\n`),
    err: (line) => process.stderr.write(`${line}\n`),
  });
  process.exitCode = exitCode;
}
APPJS

cat > "$dest/test/config.test.js" <<'CONFIGTEST'
import test from 'node:test';
import assert from 'node:assert/strict';

import { ConfigError, LOG_LEVELS, loadConfig } from '../src/config.js';

test('defaults when the environment is empty', () => {
  assert.deepEqual(loadConfig({}), { port: 8080, level: 'info', capacity: 100 });
});

test('reads PORT, LOG_LEVEL, and QUEUE_CAPACITY from the environment', () => {
  const config = loadConfig({ PORT: '9090', LOG_LEVEL: 'debug', QUEUE_CAPACITY: '5' });
  assert.equal(config.port, 9090);
  assert.equal(config.level, 'debug');
  assert.equal(config.capacity, 5);
});

test('accepts LOG_LEVEL case-insensitively', () => {
  assert.equal(loadConfig({ LOG_LEVEL: 'WARN' }).level, 'warn');
});

test('exposes the accepted levels', () => {
  assert.deepEqual([...LOG_LEVELS], ['debug', 'info', 'warn', 'error']);
});

test('rejects a PORT that is not a positive integer', () => {
  for (const raw of ['0', '-1', 'abc', '80.5']) {
    assert.throws(() => loadConfig({ PORT: raw }), ConfigError, `PORT=${raw}`);
  }
});

test('rejects a PORT above the port range', () => {
  assert.throws(
    () => loadConfig({ PORT: '70000' }),
    /PORT must be between 1 and 65535/,
  );
});

test('rejects an unknown log level and names the accepted set', () => {
  assert.throws(
    () => loadConfig({ LOG_LEVEL: 'verbose' }),
    /LOG_LEVEL must be one of debug, info, warn, error/,
  );
});

test('rejects a non-positive capacity', () => {
  assert.throws(() => loadConfig({ QUEUE_CAPACITY: '0' }), ConfigError);
});

test('returns a frozen configuration object', () => {
  const config = loadConfig({});
  assert.ok(Object.isFrozen(config));
  assert.throws(() => {
    'use strict';
    config.port = 1;
  }, TypeError);
});
CONFIGTEST

cat > "$dest/test/queue.test.js" <<'QUEUETEST'
import test from 'node:test';
import assert from 'node:assert/strict';

import { QueueFullError, createQueue } from '../src/queue.js';

test('dequeues in FIFO order', () => {
  const queue = createQueue();
  queue.enqueue('a');
  queue.enqueue('b');
  queue.enqueue('c');

  assert.equal(queue.dequeue(), 'a');
  assert.equal(queue.dequeue(), 'b');
  assert.equal(queue.dequeue(), 'c');
});

test('returns undefined when empty', () => {
  assert.equal(createQueue().dequeue(), undefined);
});

test('reports size after enqueue and dequeue', () => {
  const queue = createQueue({ capacity: 3 });
  assert.equal(queue.size, 0);
  queue.enqueue(1);
  queue.enqueue(2);
  assert.equal(queue.size, 2);
  queue.dequeue();
  assert.equal(queue.size, 1);
});

test('refuses to exceed capacity and names the capacity', () => {
  const queue = createQueue({ capacity: 1 });
  queue.enqueue('only');

  assert.throws(
    () => queue.enqueue('overflow'),
    (error) => error instanceof QueueFullError && error.capacity === 1,
  );
  assert.equal(queue.size, 1);
});

test('reports isFull at the capacity boundary', () => {
  const queue = createQueue({ capacity: 2 });
  assert.equal(queue.isFull, false);
  queue.enqueue('a');
  assert.equal(queue.isFull, false);
  queue.enqueue('b');
  assert.equal(queue.isFull, true);
});

test('drain empties the queue and returns the items in order', () => {
  const queue = createQueue();
  queue.enqueue('a');
  queue.enqueue('b');

  assert.deepEqual(queue.drain(), ['a', 'b']);
  assert.equal(queue.size, 0);
});

test('rejects a capacity below one', () => {
  assert.throws(() => createQueue({ capacity: 0 }), RangeError);
  assert.throws(() => createQueue({ capacity: -5 }), RangeError);
});
QUEUETEST

cat > "$dest/test/dispatcher.test.js" <<'DISPATCHERTEST'
import test from 'node:test';
import assert from 'node:assert/strict';

import { createQueue } from '../src/queue.js';
import { dispatch } from '../src/dispatcher.js';

function queueWith(...jobs) {
  const queue = createQueue({ capacity: jobs.length + 1 });
  for (const job of jobs) queue.enqueue(job);
  return queue;
}

test('processes every job in order', async () => {
  const queue = queueWith({ id: 'a' }, { id: 'b' });
  const seen = [];
  const result = await dispatch(queue, async (job) => {
    seen.push(job.id);
    return job.id.toUpperCase();
  });

  assert.deepEqual(seen, ['a', 'b']);
  assert.deepEqual(result.processed.map((entry) => entry.result), ['A', 'B']);
  assert.equal(result.failed.length, 0);
  assert.equal(result.total, 2);
  assert.equal(queue.size, 0);
});

test('records a failure without stopping the batch', async () => {
  const queue = queueWith({ id: 'bad' }, { id: 'good' });
  const result = await dispatch(queue, async (job) => {
    if (job.id === 'bad') throw new Error('handler exploded');
    return 'done';
  });

  assert.equal(result.failed.length, 1);
  assert.equal(result.failed[0].job.id, 'bad');
  assert.match(result.failed[0].error.message, /handler exploded/);
  assert.equal(result.processed.length, 1);
  assert.equal(result.total, 2);
});

test('logs one line per job', async () => {
  const queue = queueWith({ id: 'a' }, { id: 'b' });
  const lines = [];
  await dispatch(
    queue,
    async (job) => {
      if (job.id === 'b') throw new Error('nope');
      return 'ok';
    },
    { log: (line) => lines.push(line) },
  );

  assert.deepEqual(lines, ['ok a', 'fail b: nope']);
});

test('returns empty results for an empty queue', async () => {
  const result = await dispatch(createQueue(), async () => 'ok');
  assert.deepEqual(result.processed, []);
  assert.deepEqual(result.failed, []);
  assert.equal(result.total, 0);
});
DISPATCHERTEST

cat > "$dest/test/app.test.js" <<'APPTEST'
import test from 'node:test';
import assert from 'node:assert/strict';

import { main, parseFlags } from '../src/app.js';

function capture() {
  const out = [];
  const err = [];
  return {
    io: { out: (line) => out.push(line), err: (line) => err.push(line) },
    out,
    err,
  };
}

test('starts with defaults and prints one ready line', () => {
  const sunk = capture();
  const result = main([], {}, sunk.io);

  assert.equal(result.exitCode, 0);
  assert.deepEqual(sunk.out, ['ready port=8080 level=info capacity=100']);
  assert.deepEqual(sunk.err, []);
  assert.equal(result.queue.size, 0);
});

test('a flag overrides the environment', () => {
  const sunk = capture();
  const result = main(['--PORT=9090'], { PORT: '8081' }, sunk.io);

  assert.equal(result.exitCode, 0);
  assert.equal(result.config.port, 9090);
  assert.deepEqual(sunk.out, ['ready port=9090 level=info capacity=100']);
});

test('the environment applies when no flag is given', () => {
  const sunk = capture();
  const result = main([], { LOG_LEVEL: 'error', QUEUE_CAPACITY: '7' }, sunk.io);

  assert.equal(result.exitCode, 0);
  assert.equal(result.config.level, 'error');
  assert.equal(result.config.capacity, 7);
});

test('an unknown flag exits 2 and names the flag', () => {
  const sunk = capture();
  const result = main(['--BOGUS=1'], {}, sunk.io);

  assert.equal(result.exitCode, 2);
  assert.deepEqual(sunk.out, []);
  assert.match(sunk.err[0], /unknown flag: --BOGUS/);
});

test('a bare flag is accepted as the string true and then validated', () => {
  const sunk = capture();
  const result = main(['--PORT'], {}, sunk.io);

  assert.equal(result.exitCode, 2);
  assert.match(sunk.err[0], /PORT must be a positive integer/);
});

test('an invalid value exits 2', () => {
  const sunk = capture();
  const result = main(['--LOG_LEVEL=verbose'], {}, sunk.io);

  assert.equal(result.exitCode, 2);
  assert.match(sunk.err[0], /LOG_LEVEL must be one of/);
});

test('a positional argument is rejected', () => {
  const sunk = capture();
  const result = main(['serve'], {}, sunk.io);

  assert.equal(result.exitCode, 2);
  assert.match(sunk.err[0], /unexpected argument: serve/);
});

test('parseFlags returns the parsed pairs', () => {
  assert.deepEqual(parseFlags(['--PORT=1', '--LOG_LEVEL=warn']), {
    PORT: '1',
    LOG_LEVEL: 'warn',
  });
});
APPTEST

git -C "$dest" -c init.defaultBranch=main init -q || die "git init failed"
git -C "$dest" add -A || die "git add failed"

# Fixed identity and timestamps: identical content must produce an identical SHA
# on any host, so Appendix B can pin the seed the batch actually ran against.
GIT_AUTHOR_DATE='2000-01-01T00:00:00+0000' \
GIT_COMMITTER_DATE='2000-01-01T00:00:00+0000' \
git -C "$dest" -c user.name='promptkit-bench' -c user.email='bench@invalid' \
    -c commit.gpgsign=false -c core.autocrlf=false \
    commit -q -m 'feat: add the neutral Phase 3b benchmark seed' \
    || die "seed commit failed"

sha=$(git -C "$dest" rev-parse HEAD) || die "cannot read seed SHA"
files=$(git -C "$dest" ls-files | wc -l | tr -d ' ')

printf 'SEED|OK|sha=%s|files=%s|path=%s\n' "$sha" "$files" "$dest"
