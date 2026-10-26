# Task Spec: Accept an unbounded queue capacity

<!-- Phase 3b task (benchmarks/PHASE-3B-PROTOCOL.md section 2): a cross-module
     contract change between configuration validation and the queue, drawn from
     the neutral seed's own backlog. The seed is synthetic, so the batch is
     labeled synthetic-seed and no result transfers to consumer code. Not a
     Phase 3 pilot task. -->

- **Task ID**: `BENCH-L2-03`
- **Level**: `L2`
- **Seed Repository**: `phase3b neutral seed at 16b3cf74c809c23dd48466da2212bd3e67a530ed (built by benchmarks/seed/build-phase3b-seed.sh; operator supplies --seed)`
- **Prompt**: `"Extend src/config.js and src/queue.js so QUEUE_CAPACITY=unbounded, compared case-insensitively, yields a configuration whose capacity is Number.POSITIVE_INFINITY. createQueue must accept that capacity, never throw QueueFullError for it, and keep isFull false at every size, while size, enqueue, dequeue, drain, and the ready line keep their current behavior. Every other capacity rule stays as it is today: an absent or empty value still defaults to 100, and zero, negative, fractional, or non-numeric values still raise ConfigError. Do not change src/app.js or any other file. Add tests for the unbounded case to test/config.test.js and test/queue.test.js. Keep node --test passing."`
- **Setup**: `None`
- **Verify**: `node --test && node --input-type=module -e "import {loadConfig} from './src/config.js'; import {createQueue} from './src/queue.js'; import {main} from './src/app.js'; const inf=Number.POSITIVE_INFINITY; if (loadConfig({QUEUE_CAPACITY:'unbounded'}).capacity !== inf) throw new Error('config unbounded'); if (loadConfig({QUEUE_CAPACITY:'UNBOUNDED'}).capacity !== inf) throw new Error('config unbounded case'); if (loadConfig({}).capacity !== 100) throw new Error('default capacity'); if (loadConfig({QUEUE_CAPACITY:''}).capacity !== 100) throw new Error('empty capacity'); for (const raw of ['0','-1','1.5','lots']) { let refused=false; try { loadConfig({QUEUE_CAPACITY: raw}); } catch (e) { refused = e.name === 'ConfigError'; } if (!refused) throw new Error('accepted capacity ' + raw); } const q=createQueue({capacity:inf}); for (let i=0;i<500;i++) q.enqueue(i); if (q.size !== 500) throw new Error('unbounded size'); if (q.isFull) throw new Error('unbounded isFull'); if (q.dequeue() !== 0 || q.drain().length !== 499) throw new Error('unbounded fifo'); let threw=false; try { createQueue({capacity:0}); } catch (e) { threw = e instanceof RangeError; } if (!threw) throw new Error('finite validation changed'); const out=[]; const r=main([], {QUEUE_CAPACITY:'unbounded'}, {out:(l)=>out.push(l), err:()=>{}}); if (r.exitCode !== 0) throw new Error('app exit ' + String(r.exitCode)); if (out[0] !== 'ready port=8080 level=info capacity=Infinity') throw new Error('app line ' + JSON.stringify(out)); if (r.queue.size !== 0 || r.queue.isFull) throw new Error('app queue'); console.log('UNBOUNDED|OK');"`

## Rubric

- [ ] `R1`: `loadConfig` accepts `QUEUE_CAPACITY=unbounded` case-insensitively and returns a frozen configuration whose `capacity` is `Number.POSITIVE_INFINITY`.
- [ ] `R2`: `createQueue` accepts that capacity, never throws `QueueFullError` for it, and keeps `isFull` false at every size while `size`, `enqueue`, `dequeue`, and `drain` behave as they do for a finite queue.
- [ ] `R3`: Every other capacity rule is unchanged: absent or empty defaults to `100`, and `0`, negative, fractional, and non-numeric values still raise `ConfigError`; a finite `capacity` below `1` still raises `RangeError` from `createQueue`.
- [ ] `R4`: `app.main` with `QUEUE_CAPACITY=unbounded` starts successfully, returns `exitCode` 0, and prints `ready port=8080 level=info capacity=Infinity`, so the configuration flows through the unchanged wiring.
- [ ] `R5`: `test/config.test.js` and `test/queue.test.js` each gain assertions for the unbounded case.
- [ ] `R6`: Only `src/config.js`, `src/queue.js`, `test/config.test.js`, and `test/queue.test.js` are modified, no pre-existing test assertion is removed or weakened, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the neutral seed's `BACKLOG.md`, item 4 (`config`: allow
  `QUEUE_CAPACITY=unbounded` for callers that manage their own backpressure).
- Level: L2 is a substantive-risk change. It spans two modules and changes what
  `capacity` means across the config/queue boundary — a value that was a
  positive integer becomes a value that may be `Infinity` — so it requires the
  dependency validation L2 calls for rather than a local edit.
- The representative is explicit: `Number.POSITIVE_INFINITY`, not a sentinel
  string or `null`. A string sentinel left in `config.capacity` satisfies R1
  only if `createQueue` also special-cases it; the verify probe reads the value
  the configuration actually returns and the ready line the unchanged `app.js`
  prints, so a sentinel surfaces as a mismatch.
- R3 protects against the tempting over-correction: relaxing `positiveInt` so
  broadly that `0`, `-1`, `1.5`, or `lots` also stop raising.
