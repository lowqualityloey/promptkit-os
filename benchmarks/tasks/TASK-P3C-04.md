# Task Spec: Survive a restart without re-dispatching finished work

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The store is the only durable
     record; the defect is that intake ignores it. The two ways to get this wrong
     (dispatch everything, or skip everything the log mentions) are both caught by
     the probe. -->

- **Task ID**: `P3C-04`
- **Level**: `L2`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `After a restart the same job list re-dispatches work the store already recorded as finished. Intake must skip a job the store has closed, and must still accept one that was recorded but never finished: a job id with only an enqueue record is unfinished. Running the same list twice must dispatch the unfinished jobs once and append one done or failed record for each of them, leaving already finished jobs untouched. Keep node --test passing and add a test for a store holding one finished and one unfinished job.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { createRunner } from './src/app.js'; import { createQueue } from './src/queue.js'; const records = [{ type: 'enqueue', id: 'done-job', at: 1 }, { type: 'done', id: 'done-job', at: 2 }, { type: 'enqueue', id: 'pending-job', at: 3 }]; const store = { append: (r) => { records.push(r); return r; }, readAll: () => records }; const queue = createQueue({ capacity: 10 }); const runner = createRunner({ store, queue, now: () => 9 }); const size = await runner.enqueue(['done-job', 'pending-job', 'brand-new']); if (size !== 2) throw new Error('queued ' + size + ' jobs'); const ran = []; const result = await runner.run(async (job) => { ran.push(job.id); return job.id; }); if (JSON.stringify(ran) !== JSON.stringify(['pending-job', 'brand-new'])) throw new Error('ran ' + JSON.stringify(ran)); const done = records.filter((r) => r.type === 'done').map((r) => r.id).sort(); if (JSON.stringify(done) !== JSON.stringify(['brand-new', 'done-job', 'pending-job'])) throw new Error('done records ' + JSON.stringify(done)); const again = await runner.enqueue(['done-job', 'pending-job', 'brand-new']); if (again !== 0) throw new Error('second intake queued ' + again); console.log('RESTART|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: Intake skips a job the store has closed, so a job with a `done` or `failed` record is not queued again and is not dispatched again.
- [ ] `R2`: A job id that appears only as an `enqueue` record is still accepted and dispatched, so unfinished work survives a restart instead of being dropped.
- [ ] `R3`: Running the loop again with the same ids dispatches nothing, because every id is now closed, and appends no terminal records.
- [ ] `R4`: Exactly one terminal record exists per job id after a run, and the terminal records of jobs that were already closed are not duplicated.
- [ ] `R5`: `test/integration.test.js` gains a case for a store holding one finished and one unfinished job, and no pre-existing assertion is removed or weakened.
- [ ] `R6`: Only `src/app.js` and `test/integration.test.js` are modified, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the seed's `BACKLOG.md` ("a restart must not re-dispatch work the store
  already recorded as finished, and must not drop work that was recorded but
  never finished").
- Level: L2 — intake now depends on a replay of the log, which is a cross-module
  contract between the store and the queue.
- `R2` is the discriminating item, and it is the one a plausible fix gets wrong:
  "skip any id the log mentions" passes `R1` and silently drops the pending job.
  The probe asserts the pending job is the first thing dispatched, so neither a
  full skip nor a full re-dispatch passes.
