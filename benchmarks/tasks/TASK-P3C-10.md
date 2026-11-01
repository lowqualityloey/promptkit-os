# Task Spec: Draining must not degrade with queue size

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The cost is measured by counting
     shift() calls during drain, which is deterministic and needs no timing. -->

- **Task ID**: `P3C-10`
- **Level**: `L3`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `Draining a large queue gets slower per item than enqueueing it. Make drain take the remaining items in one operation instead of moving each item down a slot, so the work is proportional to the items returned rather than to their square. Order stays FIFO, the queue is empty afterwards, and draining an empty queue still returns an empty array. Do not change enqueue, dequeue or peek. Keep node --test passing and add a test that drains a large queue in order.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { createQueue } from './src/queue.js'; const queue = createQueue({ capacity: 5000 }); for (let i = 0; i < 3000; i += 1) queue.enqueue(i); const original = Array.prototype.shift; let shifts = 0; Array.prototype.shift = function patched() { shifts += 1; return original.call(this); }; let drained; try { drained = queue.drain(); } finally { Array.prototype.shift = original; } if (drained.length !== 3000) throw new Error('drained ' + drained.length); if (drained[0] !== 0 || drained[2999] !== 2999) throw new Error('order changed'); if (shifts !== 0) throw new Error('shift called ' + shifts + ' times during drain'); if (queue.size !== 0) throw new Error('size after drain ' + queue.size); const empty = createQueue({ capacity: 2 }); const none = empty.drain(); if (!Array.isArray(none) || none.length !== 0) throw new Error('empty drain ' + JSON.stringify(none)); const again = createQueue({ capacity: 3 }); again.enqueue('a'); again.enqueue('b'); const first = again.drain(); again.enqueue('c'); if (JSON.stringify(first) !== JSON.stringify(['a', 'b'])) throw new Error('first drain ' + JSON.stringify(first)); if (again.size !== 1 || again.peek() !== 'c') throw new Error('queue not reusable after drain'); console.log('DRAIN|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: `drain` returns the remaining items in FIFO order and leaves the queue empty.
- [ ] `R2`: Draining does not move each item down a slot — the backing array is taken in one operation — so draining 3000 items performs no per-item `shift`.
- [ ] `R3`: Draining an empty queue returns an empty array, and the queue is still usable afterwards.
- [ ] `R4`: `enqueue`, `dequeue`, `peek`, `size`, `isFull` and the capacity bound are unchanged in behavior; no pre-existing test assertion is removed or weakened.
- [ ] `R5`: `test/queue.test.js` gains a case that drains a large queue in order, and the verify packet shows `verify_exit=0`.
- [ ] `R6`: Only `src/queue.js` and `test/queue.test.js` are modified.

## Notes

- Source: the seed's `BACKLOG.md` ("draining a large queue should not get slower
  per item than enqueueing it").
- Level: L3 — the requirement is asymptotic, so the evidence has to be a measured
  step count rather than a passing assertion; the probe replaces
  `Array.prototype.shift` for the duration of the drain and counts calls, which is
  deterministic on any host.
- `R2` is the discriminating item. A partial fix that switches `dequeue` to an
  index cursor but leaves `drain` calling `dequeue` still moves each item; the
  probe measures the drain itself, so the item stays red until the drain changes.
- The probe requires exactly zero shifts, because `splice(0, length)` and
  `slice`-then-`length = 0` both satisfy the requirement and neither calls shift.
