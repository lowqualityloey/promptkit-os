# Task Spec: Count jobs, not attempts

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The prompt names the symptom,
     not the file: finding which module increments the counter is part of the
     work. The seed's own tests do not pin the defect, so the fix cannot be
     discovered by reading a failing assertion. -->

- **Task ID**: `P3C-01`
- **Level**: `L1`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `The jobs counter moves once per attempt, so a job that retries is counted more than once. Make the counters describe jobs instead: a retried job counts once, the counter set stays exactly jobs, processed and failed, and a snapshot still reports only those three names. Do not add a filter, a set, or a dedupe step to the counters themselves; the counter must be told the truth by whoever increments it. Keep node --test passing and add a test that covers a retried job.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { dispatch } from './src/dispatcher.js'; import { createQueue } from './src/queue.js'; import { createMetrics } from './src/metrics.js'; const calls = []; const fake = { inc: (n) => { calls.push(n); }, recordJob: () => {} }; const q = createQueue({ capacity: 3 }); q.enqueue({ id: 'a' }); let n = 0; await dispatch(q, async () => { n += 1; if (n < 3) throw new Error('transient'); return 'ok'; }, { metrics: fake, sleep: async () => {} }); if (calls.filter((c) => c === 'jobs').length !== 1) throw new Error('jobs incremented ' + calls.filter((c) => c === 'jobs').length + ' times for one job'); const real = createMetrics(); const q2 = createQueue({ capacity: 3 }); q2.enqueue({ id: 'b' }); let m = 0; await dispatch(q2, async () => { m += 1; if (m < 2) throw new Error('x'); return 'ok'; }, { metrics: real, sleep: async () => {} }); const snap = real.snapshot(); if (snap.jobs !== 1) throw new Error('jobs ' + snap.jobs + ' after one retried job'); if (Object.keys(snap).sort().join(',') !== 'failed,jobs,processed') throw new Error('snapshot keys ' + Object.keys(snap).join(',')); console.log('METRICS|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: The `jobs` counter moves exactly once per job handled, however many attempts the dispatcher needed, so one retried job leaves `jobs` at 1.
- [ ] `R2`: `processed` and `failed` count jobs by final outcome, and a retried job that succeeds counts once in `processed` and not in `failed`.
- [ ] `R3`: A snapshot still exposes exactly the names `jobs`, `processed` and `failed` — no dedupe set, filter or extra counter is added to make the number right.
- [ ] `R4`: `test/dispatcher.test.js` gains a case covering a retried job's counters, and no pre-existing assertion is removed or weakened.
- [ ] `R5`: Only `src/dispatcher.js` and `test/dispatcher.test.js` are modified, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the seed's `BACKLOG.md` ("counters must describe jobs, not the
  machinery that processes them") and `docs/adr/0002-metrics-idempotency.md`,
  which is explicit that the fix belongs at the increment site: a deduplicating
  counter would make the number right and the meaning wrong.
- Level: L1 is a localized change to one increment site with no cross-module
  contract change.
- `R3` is the discriminating item. The probe passes a fake metrics object and
  counts `inc` calls, so a filter inside `metrics.js` does not satisfy it, and it
  also rejects a fourth counter name that would have carried the real total.
