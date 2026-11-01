# Task Spec: Report a finished job as finished

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The prompt cites an invariant
     in docs/ARCHITECTURE.md rather than a file, and the seed's suite does not
     pin status()'s arithmetic, so the defect is only visible from the docs and
     the probe. -->

- **Task ID**: `P3C-03`
- **Level**: `L1`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `The status view reports a job as pending even after it has finished, which contradicts invariant I2 in docs/ARCHITECTURE.md. Make the view truthful: a job whose done or failed record exists is not pending, every job appears in exactly one of pending, done and failed, and the counts still come from the store. A job whose only record is an enqueue is pending. Keep node --test passing and add a test for a store holding one finished and one unfinished job.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { createRunner } from './src/app.js'; import { createQueue } from './src/queue.js'; const records = [{ type: 'enqueue', id: 'a', at: 1 }, { type: 'done', id: 'a', at: 2 }, { type: 'enqueue', id: 'b', at: 3 }]; const store = { append: (r) => { records.push(r); return r; }, readAll: () => records }; const runner = createRunner({ store, queue: createQueue({ capacity: 5 }) }); const s = runner.status(); if (s.pending !== 1 || s.done !== 1 || s.failed !== 0) throw new Error('status ' + JSON.stringify(s)); const failedRecords = [{ type: 'enqueue', id: 'c', at: 1 }, { type: 'failed', id: 'c', at: 2 }]; const failedStore = { append: (r) => r, readAll: () => failedRecords }; const failedRunner = createRunner({ store: failedStore, queue: createQueue({ capacity: 5 }) }); const f = failedRunner.status(); if (f.pending !== 0 || f.failed !== 1 || f.done !== 0) throw new Error('failed status ' + JSON.stringify(f)); console.log('STATUS|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: A job with a `done` record is counted as done and not as pending, so a store with one finished and one unfinished job reports `pending` 1, `done` 1, `failed` 0.
- [ ] `R2`: A job with a `failed` record is counted as failed and not as pending, with `pending` 0, `done` 0, `failed` 1.
- [ ] `R3`: Every job id appears in at most one of the three counts, and the counts are still derived from the store rather than from an in-memory tally that a restart would lose.
- [ ] `R4`: `test/integration.test.js` gains a case with one finished and one unfinished job, and no pre-existing assertion is removed or weakened.
- [ ] `R5`: Only `src/app.js` and `test/integration.test.js` are modified, and the verify packet shows `verify_exit=0`.

## Notes

- Source: invariant I2 in `docs/ARCHITECTURE.md` ("a job is pending, or done, or
  failed, and never two of those at once … a job whose `done` record exists is
  done, not pending") and the seed's `BACKLOG.md` ("operator tooling needs a
  truthful view").
- Level: L1 — one function's arithmetic, no contract change.
- `R1` and `R2` are the discriminating items: counting `enqueue` records is the
  defect, and a fix that special-cases `done` but forgets `failed` passes the
  first half of the probe and fails the second.
- `R3` blocks the shortcut of counting the queue's size as pending, which would
  report 0 after a restart.
