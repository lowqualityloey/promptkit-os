# Task Spec: A rejected batch leaves no trace

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The append-only store cannot
     be unwritten, so the only correct fix is to settle capacity before the first
     write. A try/catch around the loop cannot pass. -->

- **Task ID**: `P3C-05`
- **Level**: `L2`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `Batch intake is not all-or-nothing. When a batch does not fit the queue the caller does get QueueFullError, but the store already holds records for the jobs that were never accepted, and after a restart those appear as unfinished work. Settle what the queue can take before writing anything: a refused batch must leave the store and the queue exactly as they were, and an accepted batch must still write one enqueue record per job and queue every one of them. Keep node --test passing and add a test for the refused batch.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { createRunner } from './src/app.js'; import { QueueFullError, createQueue } from './src/queue.js'; const appended = []; const store = { append: (r) => { appended.push(r); return r; }, readAll: () => appended }; const queue = createQueue({ capacity: 2 }); const runner = createRunner({ store, queue, now: () => 1 }); let threw = false; try { await runner.enqueue(['a', 'b', 'c']); } catch (error) { threw = error instanceof QueueFullError; } if (!threw) throw new Error('overflow not refused with QueueFullError'); if (queue.size !== 0) throw new Error('queue size ' + queue.size + ' after a refused batch'); if (appended.length !== 0) throw new Error('store gained ' + appended.length + ' records for a refused batch'); const ok = createRunner({ store: { append: (r) => { appended.push(r); return r; }, readAll: () => appended }, queue: createQueue({ capacity: 3 }) }); if (await ok.enqueue(['x', 'y']) !== 2) throw new Error('accepted batch size'); if (appended.filter((r) => r.type === 'enqueue').length !== 2) throw new Error('accepted batch records ' + appended.length); console.log('BATCH|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: A batch larger than the queue's remaining capacity is refused with `QueueFullError` before any store record is written, so the store gains nothing.
- [ ] `R2`: The refused batch leaves the queue unchanged — no partially added items, and the items already queued are still queued in order.
- [ ] `R3`: An accepted batch still writes one `enqueue` record per job and queues every item, in the order given.
- [ ] `R4`: `test/integration.test.js` gains a case for the refused batch, and no pre-existing assertion is removed or weakened.
- [ ] `R5`: Only `src/app.js` and `test/integration.test.js` are modified, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the seed's `BACKLOG.md` ("batch intake should be all-or-nothing,
  including when the store rejects a write") and invariant I1, which makes the
  store unwritable-after-the-fact: a record cannot be removed, so the check has
  to happen before the first append.
- Level: L2 — a mutation of shared state that has to be decided before it starts.
- `R1` is the discriminating item. Wrapping the existing loop in a try/catch
  catches the error but cannot retract the records already appended, and the
  probe reads the store's record count rather than the thrown error alone.
