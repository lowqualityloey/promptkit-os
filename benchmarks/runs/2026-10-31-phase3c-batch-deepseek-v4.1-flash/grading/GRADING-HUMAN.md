# Grading record — Phase 3c primary grade

- **Sheet**: `grading-human.tsv`, sha256
  `e4294ab386dadbddea45c1126e21a8c794251d464d1f6a9943e2369c205d7961`
- **Rows**: 60 · **Rubric items**: 314 of 336 passed
- **Accepted**: **48 of 60** packets
- **Finalize with**: `--finalize <batch> --grading grading/grading-human.tsv --graded-by human`

## Provenance — read this before citing the result

The batch owner authorized this sheet as the batch's primary grade on
2026-11-01. **The first pass across all 60 packets was performed by an AI coding
agent (BuffY), not by a person.** The owner reviewed the method and the rejected
packets and accepted the result as the batch's authoritative grade; the owner did
not independently re-read all 60 packets item by item.

So the accurate description of these figures is **owner-authorized agent
grading**. `--graded-by human` records the owner's assertion of the result, and
anyone citing this batch should carry the sentence above with it rather than
describing the score as an independent human review. §7 of
`benchmarks/PHASE-3C-DESIGN.md` asks for a human primary grader who did not run
the batch; the owner qualifies on independence from the run, but the per-packet
judgment was delegated.

What the pass does have behind it: it is a **second, blind, independent read** of
the same packets the original machine sheet scored, by a different model on a
different day, rebuilding its evidence from the cards and packets rather than
from the first sheet.

- Rename history: the sheet was written as `grading-agent-draft.tsv` and this
  record as `GRADING-AGENT-DRAFT.md`, then renamed once the owner authorized it.
  The bytes and the digest are unchanged by the rename — `e4294ab3…` is the same
  sheet either way.

## Method

- Blind: no key, no `manifest.tsv`, no `order.tsv`, no `grading.scenario.tsv`, no
  `runs/` directory, and `grading-machine.tsv` was not opened while scoring.
  `packets-to-cards.tsv` (blind id → card, no arm) was the only mapping used.
- Evidence per item: the diff (implementation shape, changed-file set, deleted
  lines) and the verify packet (`verify_exit`, `VERIFY|probe=|tests=`, probe
  markers such as `COUNTS|OK`, `SPEC|PINNED`, suite totals).
- Mechanical checks over all 60 packets before scoring:
  - changed-file set against the card's allowed set — 6 of 60 were out of scope;
  - **all 17 deleted lines under `test/` across the whole batch are `import`
    statements** — zero assertion deletions, so the "no pre-existing assertion
    removed or weakened" clause is satisfiable in every packet;
  - `verify_exit` and the `VERIFY|` line read from each packet's own first lines.
- Acceptance requires every rubric item in a packet to pass.

## Result by card

| Card | Packets | Accepted | Items passed | Note |
|---|---|---:|---:|---|
| P3C-01 | 6 | 6 | 30/30 | all six move `metrics.inc('jobs')` out of the attempt loop |
| P3C-02 | 6 | 6 | 30/30 | alias + one deprecation warning; two packets ship no test (the card allows it) |
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
  `src/scheduler.js` but never attached to the object `createScheduler()` returns,
  so the card's frozen probe throws `TypeError: scheduler.sweep is not a
  function`. **R3** and **R6** fail. The `counts` object itself is correct, so R1,
  R2, R4 and R5 pass.
- **`B011`** (P3C-05, 4/5): behavior is right, but it adds a `remaining` getter to
  `src/queue.js`, which the card does not allow. **R5** fails.
- **`B007` `B015` `B035` `B048`** (P3C-09, 4/6): behavior and the pinned spec are
  both correct, but the case was written into `test/app.test.js` or
  `test/backpressure.test.js` instead of `test/integration.test.js`. **R5** and
  **R6** fail.
- **`B057`** (P3C-04, 5/6): moves the replay helper into `src/store.js`. **R6**
  fails.
- **`B054`** (P3C-10, 4/6): empty diff, `verify_exit=1`, probe reports
  `shift called 3000 times during drain`. **R2** fails (per-item `shift` remains)
  and **R5** fails (no large-queue case, no `verify_exit=0`). R1, R3, R4 and R6
  pass on the letter: the untouched seed's `drain` is already FIFO-correct and
  returns `[]` when empty, and nothing outside the allowed set was modified.

## Agreement with the original machine sheet

Acceptance is **identical packet for packet**: 48 of 60, the same twelve
rejections. That is an independent replication of the primary endpoint, not a
re-read of the same reasoning — this pass rebuilt its evidence from the cards and
packets and never opened the first sheet.

One item-count difference: **`B054` is 0/6 on the machine sheet and 4/6 here.**
The acceptance verdict is identical either way. The machine sheet charges the
empty packet with every item; this pass applied the items literally to the
delivered code, where the untouched seed satisfies R1, R3, R4 and R6. Charging a
no-op packet with items its code already satisfies could not be defended, but the
difference is recorded rather than smoothed over.

## What this pass found about the cards

- **P3C-06 is under-specified.** Five of six packets read "the scheduler exposes
  `sweep(queue, handler, options)`" as a named module export rather than a method
  on the `createScheduler()` object; only `B041` did both. The card's frozen probe
  settles it, which is why the five fail, but a card 5 of 6 sessions misread is
  measuring a wording detail as much as a behavior. Flagged for the next slate,
  not changed here.
- **Scope violations cluster on the test file.** Five of the twelve rejections
  (four P3C-09, one P3C-05) are behaviorally correct and fail only on where the
  test or helper was put. The file-scope item is doing real work, but it produces
  more of this batch's rejection signal than any correctness failure does.

## What remains open

| Item | State |
|---|---|
| Sheet | `grading-human.tsv`, sha256 `e4294ab3…` |
| Blind | yes — no key, manifest, order, scenario sheet or `runs/` opened |
| Finalize | **run 2026-11-01** — 60 records re-extracted with `grader=human` |
| Second grader (≥50%) | **run 2026-11-01** — [`SECOND-READER.md`](SECOND-READER.md): 30/30 packets identical to this sheet, 0 disagreements. Agent read from the generating model's family, not an independent human |
| Per-arm split and the §8 decision | carried from the machine sheet; acceptance identical packet-for-packet |

Acceptance is the preregistered primary endpoint and it is measured here at 48/60
overall. The per-arm comparison (26/30 against 22/30) was not re-derived here:
this pass stayed blind, so `--finalize` translated its blind ids through the key
on a host that had it. Because both sheets accept and reject the *same* twelve
packets, the per-arm split transfers exactly — but that transfer is a consequence
of the identical acceptance set, not an independent computation.

## Finalized state

`bash benchmarks/run-ab-benchmark.sh --finalize <batch> --grading
grading/grading-human.tsv --graded-by human` ran on 2026-11-01 with the blind key
present. All 60 §5 records now carry `"grading": {"grader": "human",
"human_accepted": …}` — true for the 48 accepted packets, false for the 12
rejected ones — and the re-extraction reproduced the arm totals exactly (22/30
against 26/30). The proxy statement at the top of this record still applies: what
`human` encodes is the owner's authorization of this sheet, not an item-by-item
human re-read.
