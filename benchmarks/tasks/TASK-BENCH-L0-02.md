# Task Spec: Expose the queue head without consuming it

<!-- Phase 3b task (benchmarks/PHASE-3B-PROTOCOL.md section 2): the smallest
     slice of the neutral seed's own backlog, used as the cost-only L0 cell.
     The seed is synthetic, so the batch is labeled synthetic-seed and no
     result transfers to consumer code. Not a Phase 3 pilot task. -->

- **Task ID**: `BENCH-L0-02`
- **Level**: `L0`
- **Seed Repository**: `phase3b neutral seed at 16b3cf74c809c23dd48466da2212bd3e67a530ed (built by benchmarks/seed/build-phase3b-seed.sh; operator supplies --seed)`
- **Prompt**: `"In src/queue.js, add a peek() method to the queue returned by createQueue. It returns the item at the head without removing it, and returns undefined when the queue is empty. Add a test covering both cases to test/queue.test.js. Do not change any other file. Keep node --test passing."`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import {createQueue} from './src/queue.js'; const q=createQueue({capacity:3}); if (q.peek() !== undefined) throw new Error('empty peek must be undefined'); q.enqueue('a'); q.enqueue('b'); if (q.peek() !== 'a') throw new Error('peek must return the head'); if (q.size !== 2) throw new Error('peek must not consume'); if (q.peek() !== 'a') throw new Error('peek must be repeatable'); if (q.dequeue() !== 'a') throw new Error('order after peek'); if (q.dequeue() !== 'b') throw new Error('order after peek'); if (q.size !== 0) throw new Error('size after drain'); console.log('PEEK|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: `src/queue.js` adds a `peek` method to the object returned by `createQueue`.
- [ ] `R2`: `peek()` returns the head item and changes neither `size` nor the dequeue order.
- [ ] `R3`: `peek()` returns `undefined` on an empty queue.
- [ ] `R4`: `test/queue.test.js` gains assertions for the empty case and the populated case.
- [ ] `R5`: Only `src/queue.js` and `test/queue.test.js` are modified, no pre-existing test assertion is removed or weakened, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the neutral seed's `BACKLOG.md`, item 1 (`queue`: expose `peek()` so a
  caller can read the head without consuming it). The seed is synthetic, so this
  is a seed backlog slice, not a GitHub issue.
- Level: L0 is the direct, no-design cell. The change is one method and one test
  with fully specified semantics, and it is the seed's smallest backlog item;
  its role in the batch is cost-only, and its acceptance is reported but is not
  part of the primary quality gate.
- R2 is the discriminating item: a `peek` implemented with `shift()`/`unshift()`
  returns the right value but consumes the item, which the verify probe catches
  through `size` and the following dequeue order.
