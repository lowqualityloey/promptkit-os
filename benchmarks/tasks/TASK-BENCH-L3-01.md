# Task Spec: Retry handler failures with bounded exponential backoff

<!-- Phase 3b task (benchmarks/PHASE-3B-PROTOCOL.md section 2): the L3 cell. It
     changes an exported contract that callers of the dispatcher depend on
     (per-job attempt accounting) and adds timing behavior, which the repository
     taxonomy classes as a Hard Escalation Trigger (public contract / exported
     API), so it carries Level 3 ceremony. The seed is synthetic, so the batch
     is labeled synthetic-seed and no result transfers to consumer code. Not a
     Phase 3 pilot task.

     Owner sign-off on this scope and the Rollback section below is required
     before the protocol is frozen. If the owner declines, the batch runs the
     five-task Phase 3b-L1L2 slate and makes no L3 claim. -->

- **Task ID**: `BENCH-L3-01`
- **Level**: `L3`
- **Seed Repository**: `phase3b neutral seed at 16b3cf74c809c23dd48466da2212bd3e67a530ed (built by benchmarks/seed/build-phase3b-seed.sh; operator supplies --seed)`
- **Prompt**: `"Extend dispatch in src/dispatcher.js to retry handler failures. Extend the existing options object with maxAttempts, a positive integer defaulting to 3; baseDelayMs, a non-negative integer defaulting to 100; and sleep, an optional function that takes a delay in milliseconds and returns a promise, defaulting to a real timer. If maxAttempts or baseDelayMs is invalid, throw a RangeError before dequeuing anything and leave the queue untouched. Attempt each job up to maxAttempts times. After an attempt fails and another attempt will follow, await sleep(baseDelayMs * 2 ** (attempt - 1)), where attempt is the 1-based number of the attempt that just failed. Record attempts, the 1-based count of attempts made, on every entry in processed and failed. A job that succeeds on a later attempt appears once in processed; a job that exhausts its attempts appears once in failed and carries the last error. Write exactly one log line per job, at its final outcome, in the existing ok or fail format. total stays the number of jobs handled, and maxAttempts 1 keeps today behavior. Add tests that inject sleep to cover retry-then-succeed, exhaustion, and the backoff delays to test/dispatcher.test.js. Do not change any other file. Keep node --test passing."`
- **Setup**: `None`
- **Verify**: `node --test && node --input-type=module -e "import {createQueue} from './src/queue.js'; import {dispatch} from './src/dispatcher.js'; const mk=(...ids)=>{const q=createQueue({capacity:ids.length+1}); for (const id of ids) q.enqueue({id}); return q;}; const d1=[]; const l1=[]; let n=0; const q1=mk('a'); const r1=await dispatch(q1, async () => { n++; if (n === 1) throw new Error('flaky'); return 'ok'; }, {sleep: async (ms) => { d1.push(ms); }, log: (l) => l1.push(l)}); if (r1.processed.length !== 1 || r1.failed.length !== 0) throw new Error('retry bucket'); if (r1.processed[0].attempts !== 2) throw new Error('retry attempts ' + String(r1.processed[0].attempts)); if (d1.length !== 1 || d1[0] !== 100) throw new Error('retry delays ' + JSON.stringify(d1)); if (l1.length !== 1 || l1[0] !== 'ok a') throw new Error('retry logs ' + JSON.stringify(l1)); const l2=[]; const q2=mk('b'); const r2=await dispatch(q2, async () => { throw new Error('always'); }, {maxAttempts: 3, baseDelayMs: 50, sleep: async () => {}, log: (l) => l2.push(l)}); if (r2.failed.length !== 1 || r2.processed.length !== 0 || r2.total !== 1) throw new Error('exhaust buckets'); if (r2.failed[0].attempts !== 3) throw new Error('exhaust attempts ' + String(r2.failed[0].attempts)); if (l2.length !== 1 || l2[0] !== 'fail b: always') throw new Error('exhaust logs ' + JSON.stringify(l2)); const d3=[]; const q3=mk('c'); const r3=await dispatch(q3, async () => { throw new Error('x'); }, {maxAttempts: 4, baseDelayMs: 10, sleep: async (ms) => { d3.push(ms); }}); if (r3.failed[0].attempts !== 4) throw new Error('backoff attempts'); if (d3.length !== 3 || d3[0] !== 10 || d3[1] !== 20 || d3[2] !== 40) throw new Error('backoff delays ' + JSON.stringify(d3)); const q4=mk('d','e'); const d4=[]; const r4=await dispatch(q4, async (j) => j.id, {maxAttempts: 1, sleep: async (ms) => { d4.push(ms); }}); if (r4.processed.length !== 2 || r4.processed[0].attempts !== 1 || r4.processed[1].attempts !== 1) throw new Error('maxAttempts 1'); if (d4.length !== 0) throw new Error('maxAttempts 1 slept'); const q5=mk('f'); let touched=false; const original=q5.dequeue; q5.dequeue=()=>{ touched=true; return original.call(q5); }; let range=false; try { await dispatch(q5, async () => 1, {maxAttempts: 0}); } catch (e) { range = e instanceof RangeError; } if (!range) throw new Error('invalid maxAttempts not refused'); if (touched) throw new Error('validation ran after a dequeue'); const q6=mk('g'); let range2=false; try { await dispatch(q6, async () => 1, {baseDelayMs: -1}); } catch (e) { range2 = e instanceof RangeError; } if (!range2 || q6.size !== 1) throw new Error('invalid baseDelayMs'); console.log('RETRY|OK');"`

## Rubric

- [ ] `R1`: `dispatch` accepts `maxAttempts` (positive integer, default `3`), `baseDelayMs` (non-negative integer, default `100`), and an injectable `sleep` function, while keeping the existing `log` option.
- [ ] `R2`: Invalid `maxAttempts` or `baseDelayMs` throws `RangeError` before anything is dequeued, so the queue is untouched.
- [ ] `R3`: A handler that fails once and then succeeds is attempted twice, appears only in `processed`, and its entry records `attempts` 2.
- [ ] `R4`: A handler that always fails is attempted exactly `maxAttempts` times, appears only in `failed` with `attempts` equal to `maxAttempts`, and carries the last error.
- [ ] `R5`: Backoff delays observed through the injected `sleep` are `baseDelayMs * 2 ** (attempt - 1)` between attempts only — no sleep before the first attempt and none after the final one — and `maxAttempts` 1 never sleeps.
- [ ] `R6`: Exactly one log line is written per job, at its final outcome, in the existing `ok <id>` / `fail <id>: <message>` format, and `processed`, `failed`, and `total` still count each job once.
- [ ] `R7`: Only `src/dispatcher.js` and `test/dispatcher.test.js` are modified, no pre-existing test assertion is removed or weakened, and the verify packet shows `verify_exit=0`.

## Rollback

- The change is confined to the seed's dispatcher module: no persisted state, no
  migration, no wire format, no deployment, and no consumers outside the
  repository. Rollback is `git revert` of the single change (or discarding the
  run directory, which is what a benchmark run does anyway); callers that never
  read `attempts` are unaffected because the new field is additive.
- The behavior change that is not additive is timing: retried jobs now spend
  real time in backoff. The default (`maxAttempts` 3, `baseDelayMs` 100) adds at
  most 300 ms per failing job, and any caller that needs the old behavior sets
  `maxAttempts` 1, which the rubric pins as unchanged.

## Notes

- Source: the neutral seed's `BACKLOG.md`, item 2 (`dispatcher`: retry transient
  handler failures with exponential backoff and a per-job attempt cap, and
  record the attempt count on each processed entry).
- Level: L3. The change alters an exported function's result contract and adds
  timing behavior to a loop that drains shared mutable state; the repository's
  own taxonomy escalates public-contract changes to L3, and the protocol
  requires an owner-approved scope and rollback plan for the L3 cell. Owner
  sign-off is recorded in the protocol's Approval section before freeze.
- R5 is the discriminating item. An implementation that sleeps after the final
  failed attempt, or that computes the delay from the next attempt number,
  produces a plausible retry loop that fails only on the observed delay
  sequence; the injected `sleep` makes that sequence exact instead of timing-
  dependent.
- R2 is a safety item: validating after the first dequeue loses a job when the
  options are wrong, which a caller cannot detect from the thrown error.
