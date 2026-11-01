# Task Spec: Reproducible, bounded backoff

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The formula is stated in the
     prompt so the deadened exponential schedule is a stated requirement rather
     than an inference, and the probe checks the cap, the endpoints and the
     injected source. -->

- **Task ID**: `P3C-08`
- **Level**: `L3`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `Backoff delays must be reproducible from the injected random source and must respect the delay cap. Use floor(random() * min(baseDelayMs * 2 ** (attempt - 1), jitterCapMs)), where random is the source dispatch already accepts and attempt is the 1-based number of the attempt that just failed and will be retried. Draw exactly once per wait. Never sleep before the first attempt or after the final one, so maxAttempts 1 sleeps zero times, and no delay may exceed jitterCapMs. Keep node --test passing and add a test for a capped schedule.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { dispatch } from './src/dispatcher.js'; import { createQueue } from './src/queue.js'; const delays = []; const q = createQueue({ capacity: 2 }); q.enqueue({ id: 'doomed' }); await dispatch(q, async () => { throw new Error('nope'); }, { maxAttempts: 4, baseDelayMs: 100, jitterCapMs: 120, jitter: () => 0.5, sleep: async (ms) => { delays.push(ms); } }); if (JSON.stringify(delays) !== JSON.stringify([50, 60, 60])) throw new Error('delays ' + JSON.stringify(delays)); const q2 = createQueue({ capacity: 2 }); q2.enqueue({ id: 'once' }); let slept = 0; let draws = 0; await dispatch(q2, async () => { throw new Error('nope'); }, { maxAttempts: 1, jitter: () => { draws += 1; return 0.5; }, sleep: async () => { slept += 1; } }); if (slept !== 0 || draws !== 0) throw new Error('slept ' + slept + ' and drew ' + draws + ' for a single attempt'); const q3 = createQueue({ capacity: 2 }); q3.enqueue({ id: 'cap' }); const capped = []; await dispatch(q3, async () => { throw new Error('nope'); }, { maxAttempts: 3, baseDelayMs: 1000, jitterCapMs: 5, jitter: () => 0.999, sleep: async (ms) => { capped.push(ms); } }); if (capped.length !== 2 || capped.some((ms) => ms > 5)) throw new Error('delays above the cap ' + JSON.stringify(capped)); const q4 = createQueue({ capacity: 2 }); q4.enqueue({ id: 'flaky' }); let n = 0; const one = []; await dispatch(q4, async () => { n += 1; if (n < 2) throw new Error('x'); return 'ok'; }, { jitter: () => 0.25, sleep: async (ms) => { one.push(ms); } }); if (JSON.stringify(one) !== JSON.stringify([6])) throw new Error('default schedule ' + JSON.stringify(one)); console.log('BACKOFF|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: The wait between attempts is `floor(random() * min(baseDelayMs * 2 ** (attempt - 1), jitterCapMs))`, computed from the attempt that just failed, so a fixed source produces a fixed sequence.
- [ ] `R2`: No delay exceeds `jitterCapMs`, and the cap is applied to each attempt rather than only to the first.
- [ ] `R3`: The injected source is drawn from exactly once per wait, and not at all when there is no wait — so `maxAttempts` 1 draws nothing and sleeps nothing.
- [ ] `R4`: There is no wait before the first attempt, and no wait after the final failure.
- [ ] `R5`: The default `baseDelayMs` and `jitterCapMs` are unchanged, so a one-retry job with the defaults and a source returning 0.25 waits 6 ms.
- [ ] `R6`: Only `src/dispatcher.js` and `test/dispatcher.test.js` are modified, `test/dispatcher.test.js` gains a capped-schedule case, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the seed's `BACKLOG.md` ("retry backoff should be reproducible from a
  seeded source in tests") and `src/config.js`'s `JITTER_CAP_MS`, which nothing
  currently honours.
- Level: L3 — the visible behavior is timing, and the contract is the exact
  schedule, which only an injected source can pin. The card carries a Rollback
  note below because a wrong cap changes how long a failing batch takes.
- `R2` is the discriminating item: the seed multiplies the base delay without
  ever reading the cap, so a schedule that looks exponential runs 3× past the
  configured ceiling on the third wait.
- `R3`/`R4` catch the two off-by-one shapes that produce plausible schedules: a
  draw or wait before the first attempt, and a wait after the last one.

## Rollback

- The change is confined to the retry loop in one module: no persisted state, no
  wire format, and no exported result change. `git revert` of the single change
  restores the old schedule.
- The non-additive part is timing: with the defaults, a job that exhausts three
  attempts now waits at most 25 + 50 ms instead of 75 ms per job. Any caller that
  needs the old behavior sets `maxAttempts` 1, which the suite pins as unchanged.
