# Task Spec: Publish counts, and update the caller no test covers

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The scheduler's sweep helper is
     not covered by the seed's suite, so a change confined to the dispatcher and
     its own test passes every test and still returns the wrong thing. -->

- **Task ID**: `P3C-06`
- **Level**: `L2`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `The dispatch result must also carry a counts object with integer processed, failed and total fields, alongside the existing processed, failed and total fields, which keep their current meaning. Then add a sweep helper to the scheduler: it takes a queue, a handler and the dispatch options, drains the queue through dispatch, and returns how many jobs ran, read from counts.total. The CLI summary must keep printing the same line it prints today. Keep node --test passing and add tests for counts and for sweep.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { dispatch } from './src/dispatcher.js'; import { createQueue } from './src/queue.js'; import { createScheduler } from './src/scheduler.js'; const q = createQueue({ capacity: 3 }); q.enqueue({ id: 'a' }); q.enqueue({ id: 'b' }); const r = await dispatch(q, async () => 'ok', { sleep: async () => {} }); if (r.total !== 2) throw new Error('total ' + r.total); if (!r.counts || r.counts.total !== 2 || r.counts.processed !== 2 || r.counts.failed !== 0) throw new Error('counts ' + JSON.stringify(r.counts)); if (!Number.isInteger(r.counts.total) || !Number.isInteger(r.counts.processed) || !Number.isInteger(r.counts.failed)) throw new Error('counts are not integers'); const scheduler = createScheduler({ now: () => 0 }); const q2 = createQueue({ capacity: 3 }); q2.enqueue({ id: 'x' }); const swept = await scheduler.sweep(q2, async () => 'ok'); if (swept !== 1) throw new Error('sweep returned ' + swept); const q3 = createQueue({ capacity: 3 }); q3.enqueue({ id: 'y' }); q3.enqueue({ id: 'z' }); const swept2 = await scheduler.sweep(q3, async () => { throw new Error('nope'); }, { maxAttempts: 1 }); if (swept2 !== 2) throw new Error('sweep counted ' + swept2 + ' for two failing jobs'); console.log('COUNTS|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: `dispatch` returns a `counts` object with integer `processed`, `failed` and `total`, and the pre-existing `processed`, `failed` and `total` fields keep their values and meaning.
- [ ] `R2`: `counts` describes the same run as the arrays: `counts.processed` equals the length of `processed`, `counts.failed` the length of `failed`, and `counts.total` their sum.
- [ ] `R3`: The scheduler exposes `sweep(queue, handler, options)` that drains through `dispatch` and returns the number of jobs run, read from `counts.total`, counting failed jobs as handled.
- [ ] `R4`: The CLI summary still prints `processed=<n> failed=<n> total=<n>` with the same numbers, and no other command output changes.
- [ ] `R5`: `test/dispatcher.test.js` and `test/scheduler.test.js` gain cases for `counts` and `sweep`, and no pre-existing assertion is removed or weakened.
- [ ] `R6`: Only `src/dispatcher.js`, `src/scheduler.js`, `src/app.js`, `test/dispatcher.test.js` and `test/scheduler.test.js` are modified, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the seed's `BACKLOG.md` ("counters must describe jobs") and the
  scheduler module, whose `tick` already reports how many jobs it ran.
- Level: L2 — an exported result contract changes, and one of its callers is not
  covered by any seed test.
- `R3` is the discriminating item. The seed has no `sweep`, and a change that
  touches only the dispatcher leaves the scheduler without it, so the probe fails
  on the missing caller rather than on the result shape.
- The second half of the probe sweeps two failing jobs and requires 2: a `sweep`
  built on `processed.length` looks right on the happy path and returns 0 here.
