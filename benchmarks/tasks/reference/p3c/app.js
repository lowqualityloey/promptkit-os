// Reference overlay for cards P3C-02, P3C-03, P3C-04, P3C-05 and P3C-09.
//
// It is the seed's src/app.js with the four behavioral fixes those cards ask for:
//   - a batch is checked against capacity before any record is written (P3C-05)
//   - a batch the store rejects raises BackpressureError with the queue unchanged
//     (P3C-09, the shape specs/backpressure.spec.js requires)
//   - intake skips ids the store already closed, and still accepts pending ones
//     (P3C-04)
//   - status() replays the log so a closed job is not also pending (P3C-03)
//   - the legacy --DRY_RUN spelling still works and warns exactly once, while
//     --dry-run is the quiet spelling (P3C-02)
//
// It exists so the cards' Verify probes can be validated against a compliant
// implementation. benchmarks/never stages benchmarks/, so it cannot reach an
// agent's clone.
import { CliError, parseArgs } from './cli.js';
import { ConfigError, loadConfig } from './config.js';
import { dispatch } from './dispatcher.js';
import { createMetrics } from './metrics.js';
import { QueueFullError, createQueue } from './queue.js';
import { createStore } from './store.js';

export class BackpressureError extends Error {
  constructor(attempted, cause) {
    super(`store refused the batch of ${attempted} jobs`);
    this.name = 'BackpressureError';
    this.attempted = attempted;
    this.cause = cause;
  }
}

export function createRunner({ store, queue, metrics = createMetrics(), now = () => Date.now(), log = () => {} } = {}) {
  function closedIds() {
    const closed = new Set();
    for (const record of store.readAll()) {
      if (record.type === 'done' || record.type === 'failed') closed.add(record.id);
    }
    return closed;
  }

  async function enqueue(ids) {
    const closed = closedIds();
    const batch = ids.filter((id) => !closed.has(id));
    if (batch.length === 0) return queue.size;

    // Capacity is settled before anything is written: a rejected batch must not
    // leave a record behind for a job that was never accepted.
    if (queue.size + batch.length > queue.capacity) {
      throw new QueueFullError(queue.capacity);
    }

    try {
      for (const id of batch) {
        store.append({ type: 'enqueue', id, at: now() });
      }
    } catch (error) {
      throw new BackpressureError(batch.length, error);
    }

    queue.enqueueMany(batch.map((id) => ({ id })));
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
    const open = new Set();
    const done = new Set();
    const failed = new Set();

    for (const record of store.readAll()) {
      if (record.type === 'enqueue') {
        if (!done.has(record.id) && !failed.has(record.id)) open.add(record.id);
      } else if (record.type === 'done') {
        done.add(record.id);
        open.delete(record.id);
      } else if (record.type === 'failed') {
        failed.add(record.id);
        open.delete(record.id);
      }
    }

    return { pending: open.size, done: done.size, failed: failed.size };
  }

  return { enqueue, run, status };
}

export async function main(argv = [], env = {}, io = { out: () => {}, err: () => {} }) {
  try {
    const { command, flags } = parseArgs(argv);
    const overrides = {};
    for (const [name, value] of Object.entries(flags)) {
      if (name === 'DRY_RUN' || name === 'dry-run' || name === 'JOBS') continue;
      overrides[name] = value;
    }
    const config = loadConfig({ ...env, ...overrides });

    const legacy = flags.DRY_RUN;
    const current = flags['dry-run'];
    if (legacy !== undefined) {
      io.err('warning: --DRY_RUN is deprecated; use --dry-run');
    }

    if (legacy !== undefined || current !== undefined) {
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
