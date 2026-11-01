# Grading record — Phase 3c, independent agent re-read

**Score it as what it is.** Every one of the 60 packets was re-graded blind
against its frozen card rubric, reading only `B<nnn>.diff` and
`B<nnn>.verify.txt`. The grader was an AI coding agent (BuffY), not a person,
working under the owner's instruction to settle the verdicts. That makes this
an **independent agent read**, not the §7 human primary grading, and §7's rule
is unchanged: the primary grade needs a human who did not run the batch. The
sheet is named `grading-agent-draft.tsv` for that reason. Finalizing it with
`--graded-by human` would assert something untrue unless a human has actually
reviewed the verdicts first.

The value it does have: it is a **second, independent read** of the same
packets the original machine pass scored, by a different model on a different
day, using a docket assembled from the cards and packets rather than from the
first sheet.

- **Sheet**: `grading-agent-draft.tsv`, sha256
  `e4294ab386dadbddea45c1126e21a8c794251d464d1f6a9943e2369c205d7961`
- **Rows**: 60 · **Rubric items**: 314 of 336 passed
- **Accepted**: **48 of 60** packets

## Method

- Blind: no key, no `manifest.tsv`, no `order.tsv`, no `grading.scenario.tsv`, no
  `runs/` directory, and `grading-machine.tsv` was not opened while scoring.
  `packets-to-cards.tsv` (blind id → card, no arm) was the only mapping used.
- Evidence per item: the diff (implementation shape, changed-file set, deleted
  lines) and the verify packet (`verify_exit`, `VERIFY|probe=|tests=`, probe
  markers such as `COUNT|OK`, `SPEC|PINNED`, suite totals).
- Mechanical checks run over all 60 packets before scoring:
  - changed-file set against the card's allowed set (6 of 60 were out of scope);
  - **17 deleted lines across every `test/` file in the batch are all `import`
    statements** — zero assertion deletions anywhere, so the "no pre-existing
    assertion removed or weakened" clause is satisfiable in every packet;
  - `verify_exit` and the `VERIFY|` line read from each packet's own first lines.
- Acceptance requires every rubric item in a packet to pass.

## Result by card

| Card | Packets | Accepted | Items passed | Note |
|---|---|---:|---:|---|
| P3C-01 | 6 | 6 | 30/30 | all six move `metrics.inc('jobs')` out of the attempt loop |
| P3C-02 | 6 | 6 | 30/30 | alias + one deprecation warning; two packets ship no test (allowed by the card) |
| P3C-03 | 6 | 6 | 30/30 | all six replay the log into a per-id `Map` |
| P3C-04 | 6 | 5 | 35/36 | `B057` adds `jobStates` to `src/store.js` |
| P3C-05 | 6 | 5 | 29/30 | `B011` adds a `remaining` getter to `src/queue.js` |
| P3C-06 | 6 | **1** | 26/36 | five packets export `sweep` at module level only |
| P3C-07 | 6 | 6 | 36/36 | append-only, version stamped, unknown version refused |
| P3C-08 | 6 | 6 | 36/36 | five identical one-line `Math.min` caps; one aliases the RNG |
| P3C-09 | 6 | **2** | 28/36 | four put the case in `test/app.test.js` / `test/backpressure.test.js` |
| P3C-10 | 6 | 5 | 30/36 | `B054` is the empty packet from the provider abort |

## Rejected packets and the items they failed

- **`B001` `B002` `B014` `B038` `B043`** (P3C-06, 4/6): `sweep` is exported from
  `src/scheduler.js` but never attached to the object `createScheduler()`
  returns, so the card's frozen probe throws
  `TypeError: scheduler.sweep is not a function`. **R3** and **R6** fail. The
  `counts` object itself is correct, so R1, R2, R4 and R5 pass.
- **`B011`** (P3C-05, 4/5): behavior is right, but it adds a `remaining` getter to
  `src/queue.js`, which the card does not allow. **R5** fails.
- **`B007` `B015` `B035` `B048`** (P3C-09, 4/6): the behavior and the pinned spec
  are both correct, but the case was written into `test/app.test.js` or
  `test/backpressure.test.js` instead of `test/integration.test.js`. **R5** and
  **R6** fail.
- **`B057`** (P3C-04, 5/6): moves the replay helper into `src/store.js`. **R6**
  fails.
- **`B054`** (P3C-10, 4/6): empty diff, `verify_exit=1`, probe reports
  `shift called 3000 times during drain`. **R2** fails (per-item `shift`
  remains) and **R5** fails (no large-queue case, no `verify_exit=0`). R1, R3,
  R4 and R6 pass on the letter: the untouched seed's `drain` is already
  FIFO-correct and returns `[]` when empty, and nothing outside the allowed set
  was modified.

## Agreement with the original machine sheet

Acceptance is **identical packet for packet**: 48 of 60, the same twelve
rejections. That is a genuine independent replication of the primary endpoint,
not a re-read of the same reasoning — this pass rebuilt its evidence from the
cards and packets and never opened the first sheet.

One item-count difference: **`B054` is 0/6 on the machine sheet and 4/6 here.**
The acceptance verdict is the same either way. The machine sheet charges the
empty packet with every item; this pass applied the items literally to the
delivered code, where the untouched seed happens to satisfy R1, R3, R4 and R6.
Charging a no-op packet with items its code already satisfies is the reading I
could not defend, but the difference is recorded rather than smoothed over.

## What this read found about the cards

- **P3C-06 is under-specified.** Five of six packets read "the scheduler exposes
  `sweep(queue, handler, options)`" as a named module export rather than a method
  on the `createScheduler()` object. Only `B041` did both. The card's frozen
  probe settles it, which is why the five fail, but a card that 5 of 6 sessions
  misread is measuring a wording detail as much as a behavior. Flagged for the
  next slate, not changed here.
- **Scope violations cluster on the test file.** Five of the twelve rejections
  (four P3C-09, one P3C-05) are behaviorally correct and fail only on where the
  test or helper was put. The file-scope item is doing real work, but it is
  producing the batch's rejection signal more than any correctness failure.

## Provenance and what is still open

| Item | State |
|---|---|
| Grader | AI agent (BuffY), under owner instruction |
| Blind | yes — no key, manifest, order, scenario sheet or `runs/` opened |
| Sheet | `grading-agent-draft.tsv`, sha256 `e4294ab3…` |
| §7 human primary grade | **still open** — a human must review and assert it |
| Second grader (≥50%) | sample drawn (`second-grader-sample.txt`), not yet scored |
| `--finalize --graded-by human` | **not run**, and blocked: the blind key is not on this host |
| Decision under §8 | not claimed here; it needs the per-arm split, which needs the key |

Acceptance is the preregistered primary endpoint, and this pass measures it at
48/60 overall. The per-arm comparison (26/30 against 22/30 on the machine sheet)
cannot be recomputed without unblinding, so no arm-level claim is made here.
