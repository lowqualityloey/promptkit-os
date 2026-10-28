# Task Spec: Add an atomic multi-item enqueue

<!-- Phase 3b task (benchmarks/PHASE-3B-PROTOCOL.md section 2): an all-or-nothing
     mutation of the queue's bounded state, drawn from the neutral seed's own
     backlog. The seed is synthetic, so the batch is labeled synthetic-seed and
     no result transfers to consumer code. Not a Phase 3 pilot task. -->

- **Task ID**: `BENCH-L2-04`
- **Level**: `L2`
- **Seed Repository**: `phase3b neutral seed at 16b3cf74c809c23dd48466da2212bd3e67a530ed (built by benchmarks/seed/build-phase3b-seed.sh; operator supplies --seed)`
- **Prompt**: `"Add an enqueueMany(items) method to the queue returned by createQueue in src/queue.js. When every item fits, it appends them in order and returns the new size. When they do not all fit, it throws QueueFullError and leaves the queue exactly as it was: same size, same head, and no partial append. An empty array is a no-op that returns the current size. Every existing method, error, and bound stays unchanged. Add tests for the success, overflow, and empty cases to test/queue.test.js. Do not change any other file. Keep node --test passing."`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import {createQueue, QueueFullError} from './src/queue.js'; const q=createQueue({capacity:3}); if (q.enqueueMany(['a','b']) !== 2) throw new Error('success return'); if (q.size !== 2) throw new Error('success size'); if (q.dequeue() !== 'a') throw new Error('success order'); const r=createQueue({capacity:3}); r.enqueue('x'); r.enqueue('y'); let threw=false; try { r.enqueueMany(['c','d']); } catch (e) { threw = e instanceof QueueFullError; } if (!threw) throw new Error('overflow must throw QueueFullError'); if (r.size !== 2) throw new Error('partial append left size ' + String(r.size)); if (r.dequeue() !== 'x' || r.dequeue() !== 'y') throw new Error('partial append changed the head or order'); const e=createQueue({capacity:2}); if (e.enqueueMany([]) !== 0) throw new Error('empty return'); e.enqueue('k'); if (e.enqueueMany([]) !== 1) throw new Error('empty return on non-empty queue'); if (e.size !== 1) throw new Error('empty changed state'); const exact=createQueue({capacity:2}); if (exact.enqueueMany(['p','q']) !== 2) throw new Error('exact fit return'); if (exact.size !== 2 || !exact.isFull) throw new Error('exact fit state'); let overflowExact=false; try { exact.enqueueMany(['z']); } catch (err) { overflowExact = err instanceof QueueFullError; } if (!overflowExact || exact.size !== 2) throw new Error('full queue accepted an item'); console.log('ENQUEUEMANY|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: `enqueueMany(items)` exists on the object returned by `createQueue`; when every item fits it appends them in order and returns the new size.
- [ ] `R2`: When the items do not all fit it throws `QueueFullError` and leaves the queue unchanged — same `size`, same head, and the pre-existing items still dequeue in their original order.
- [ ] `R3`: An empty array is a no-op that returns the current size, on an empty queue and on a partially filled one.
- [ ] `R4`: A batch that exactly fills the remaining capacity succeeds and leaves `isFull` true; the next `enqueueMany` call throws and changes nothing.
- [ ] `R5`: Every existing method, error class, and capacity bound is unchanged, and `test/queue.test.js` gains assertions for the success, overflow, and empty cases.
- [ ] `R6`: Only `src/queue.js` and `test/queue.test.js` are modified, no pre-existing test assertion is removed or weakened, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the neutral seed's `BACKLOG.md`, item 6 (`queue`: add `enqueueMany()`
  that is atomic — either every item fits or none is added).
- Level: L2 is a substantive-risk change to shared mutable state: the method must
  decide fit before mutating, so a per-item loop that lets `enqueue` throw
  halfway leaves the queue in a state no caller can recover from without
  draining it. That is the failure mode the rubric targets.
- R2 and R4 are the discriminating items: a loop over the existing `enqueue`
  satisfies R1 and R3 but fails R2 on the partial append, and an implementation
  that checks `size + items.length < capacity` (strict) fails on an exact fit.
- R5 keeps the change additive: a solution that rewrites `enqueue` to return the
  size, or that softens the capacity bound to make the batch fit, is out of
  scope even when the new method is otherwise correct.
