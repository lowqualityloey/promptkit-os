// Reference overlay for cards P3C-01, P3C-06 and P3C-08.
//
// The seed's dispatcher with three fixes:
//   - `jobs` moves once per job, outside the attempt loop (P3C-01, invariant I3)
//   - the delay is floor(jitter() * min(base, jitterCapMs)) from the injected
//     source, so a seeded source reproduces it exactly (P3C-08)
//   - the result also carries `counts`, without dropping `total` (P3C-06)
export const RETRY_DEFAULTS = Object.freeze({
  maxAttempts: 3,
  baseDelayMs: 25,
  jitterCapMs: 200,
});

const realSleep = (delayMs) => new Promise((resolve) => setTimeout(resolve, delayMs));

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

    if (metrics) metrics.inc('jobs');

    let attempts = 0;
    let lastError;
    let result;
    let ok = false;

    while (attempts < maxAttempts) {
      attempts += 1;
      try {
        result = await handler(job);
        ok = true;
        break;
      } catch (error) {
        lastError = error;
        if (attempts < maxAttempts) {
          const base = baseDelayMs * 2 ** (attempts - 1);
          await sleep(Math.floor(jitter() * Math.min(base, jitterCapMs)));
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

  const total = processed.length + failed.length;
  return {
    processed,
    failed,
    total,
    counts: { processed: processed.length, failed: failed.length, total },
  };
}
