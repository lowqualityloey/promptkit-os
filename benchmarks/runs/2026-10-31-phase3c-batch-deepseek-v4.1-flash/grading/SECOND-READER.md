# Second read — Phase 3c (30 of 60 blind packets)

Completed 2026-11-01. This is the §7 second-grader sample, scored from the
packets alone and compared with the primary sheet packet-by-packet.

**Result: 30 of 30 packets identical to the primary sheet. 0 disagreements.**
25 accepted, 5 rejected, 160 of 170 rubric items — the same 25, 5 and 160 as
`grading-human.tsv` on these packets.

The sample was re-derived from the documented rule before scoring:
`sha256("phase3c-second-sample|<batch>|<BID>")`, ordered ascending, first 30 of
60. Recomputing it reproduces `second-grader-sample.txt` exactly, in order.

## Method

- Evidence was `B*.diff` + `B*.verify.txt` and the frozen card rubric only.
  No key, `manifest.tsv`, `order.tsv`, `grading.scenario.tsv` or `runs/*/` was
  opened.
- Card assignment came from `second-grader-sample.txt`; the card column is an
  index into the frozen rubrics, not information about the arm.
- An objective fact table was computed by script for all 30 packets before
  scoring: changed-file set against the card's allowed files, count of removed
  non-import lines in `*.test.js`, `VERIFY|probe`/`tests`, and `SPEC|PINNED`.
  It was then checked against every verdict, so the mechanical components
  (file scope, verify exit, "no pre-existing assertion removed") do not rest on
  a reading of the code.
- `grading-second.tsv` holds the scores, sha256
  `1d1913576c83f7ee24d1e80794c7daebd69ecf81fed4b1434ca5516323f043d8`.
  Comparison was mechanical, not visual: the two sheets were parsed and diffed
  row by row.

## Fact table

| Fact | Packets |
|---|---|
| Out-of-scope file in the changed set | `B035`, `B015` (both add `test/app.test.js`) |
| `VERIFY\|probe` nonzero | `B043`, `B038` (and `B054`, empty diff) |
| `SPEC\|PINNED` present | `B035`, `B018`, `B015` (the three P3C-09 packets) |
| Pre-existing test assertion lines removed | none, in any of the 30 |
| Packets with no diff | `B054` |

None of the 30 removed or weakened an existing assertion; every "no pre-existing
assertion removed or weakened" item therefore turns only on file scope and
`verify_exit`.

## Per-packet result

| Blind | Card | Second | Primary | Accepted | What it turns on |
|---|---|---|---|---|---|
| B026 | P3C-03 | 5/5 | 5/5 | yes | `status()` replayed by job id; test added |
| B050 | P3C-07 | 6/6 | 6/6 | yes | v2 writes, v1 read-back, mixed, unknown refused |
| B039 | P3C-05 | 5/5 | 5/5 | yes | capacity settled before the first write |
| B023 | P3C-08 | 6/6 | 6/6 | yes | cap inside the schedule |
| B005 | P3C-10 | 6/6 | 6/6 | yes | `splice(0)` |
| B020 | P3C-02 | 5/5 | 5/5 | yes | alias flag, one warning on the legacy spelling |
| B049 | P3C-02 | 5/5 | 5/5 | yes | alias in the parser, warning from raw argv |
| B034 | P3C-03 | 5/5 | 5/5 | yes | replay by job id |
| B035 | P3C-09 | 4/6 | 4/6 | **no** | behaviour correct, test landed in a new `test/app.test.js` |
| B037 | P3C-10 | 6/6 | 6/6 | yes | `slice()` then `length = 0` |
| B010 | P3C-03 | 5/5 | 5/5 | yes | replay by job id |
| B043 | P3C-06 | 4/6 | 4/6 | **no** | module-level `sweep`, but `createScheduler()` has no `.sweep` |
| B038 | P3C-06 | 4/6 | 4/6 | **no** | same probe failure: `scheduler.sweep is not a function` |
| B053 | P3C-04 | 6/6 | 6/6 | yes | opened/closed replay plus an in-process queued set |
| B045 | P3C-07 | 6/6 | 6/6 | yes | version on write, version 1 on read-back |
| B009 | P3C-08 | 6/6 | 6/6 | yes | cap inside the schedule |
| B024 | P3C-04 | 6/6 | 6/6 | yes | closed/opened replay |
| B032 | P3C-07 | 6/6 | 6/6 | yes | three-generation read, unknown refused |
| B018 | P3C-09 | 6/6 | 6/6 | yes | `BackpressureError` plus the integration case |
| B044 | P3C-05 | 5/5 | 5/5 | yes | capacity precheck, `enqueueMany` after the writes |
| B012 | P3C-04 | 6/6 | 6/6 | yes | closed/opened replay |
| B060 | P3C-03 | 5/5 | 5/5 | yes | done and failed cases both added |
| B028 | P3C-01 | 5/5 | 5/5 | yes | `inc('jobs')` moved out of the attempt loop |
| B006 | P3C-04 | 6/6 | 6/6 | yes | replay plus queued set |
| B054 | P3C-10 | 4/6 | 4/6 | **no** | empty diff |
| B016 | P3C-08 | 6/6 | 6/6 | yes | cap inside the schedule |
| B027 | P3C-08 | 6/6 | 6/6 | yes | cap inside the schedule, `random` as an alias for `jitter` |
| B055 | P3C-08 | 6/6 | 6/6 | yes | cap inside the schedule |
| B015 | P3C-09 | 4/6 | 4/6 | **no** | behaviour correct, test landed in a new `test/app.test.js` |
| B021 | P3C-05 | 5/5 | 5/5 | yes | capacity precheck, writes then `enqueueMany` |

## The five rejections, and why they are rejections

- **P3C-06 (`B043`, `B038`), 4/6.** Both return the `counts` object correctly and
  both add a `sweep` that drains through `dispatch` and reads `counts.total`. But
  they export it as a module function from `src/scheduler.js`, and the frozen
  probe calls `scheduler.sweep(...)` on the object `createScheduler()` returns.
  The probe dies on `TypeError: scheduler.sweep is not a function`, so R3 fails
  on the contract the card states, and R6 fails because `verify_exit=1`. Every
  test in the suite passes, including their own `sweep` tests — the missing
  caller is exactly what the card was written to catch.
- **P3C-09 (`B035`, `B015`), 4/6.** Both implement `BackpressureError` with
  `attempted` equal to the batch size, leave the queue untouched on a store
  rejection, keep the empty batch a no-op, and leave the pinned spec untouched
  (`SPEC|PINNED`). But both put the new test in a new `test/app.test.js`, so
  `test/integration.test.js` gains no case (R5) and the changed set leaves the
  card's allowed files (R6).
- **P3C-10 (`B054`), 4/6.** Empty diff — the provider-aborted cell. Scored item by
  item: R1, R3, R4 and R6 hold on the unmodified seed (its `drain` already
  returns FIFO and empties, its other operations are untouched, and "only these
  files are modified" is true of a no-op); R2 fails because the drain still
  shifts per item, and R5 fails because no test was added and `verify_exit=1`.

## The one instrument defect this read found

`GRADING-HUMAN-GUIDE.md` §Scoring item 4 said an empty diff "scores `0/N false`".
Applied literally, that gives `B054` 0/6. The rubric gives 4/6: P3C-10's R6 has
no `verify_exit` clause (R5 carries it), so a no-op satisfies R6, and it
satisfies R1, R3 and R4 on the seed as shipped.

The primary sheet already scored `B054` 4/6 item by item — so the primary was
right and the guide's sentence was wrong. The frozen machine sheet applied the
guide's rule and holds 0/6, which is why the two sheets differ by 4 items
(`314/336` against `310/336`) while agreeing on all 60 acceptance verdicts.
My first pass followed the guide and wrote 0/6; re-deriving the card item by item
corrected it to 4/6 before comparison, and it is recorded here rather than
smoothed over.

Fixed: the guide's sentence now states the item-by-item rule and names `B054`'s
actual score. No sheet, record or finalize was changed — acceptance was identical
under both readings, and the primary sheet's digest `e4294ab3…` is unchanged.

## Limits — read before citing this

1. **Not a human read.** This is an agent second read, like the primary pass.
2. **Not strictly blind.** `grading-human.tsv` was loaded into the session before
   scoring, during orientation. Verdicts were derived packet by packet from the
   diff and verify files, and every mechanical component was recomputed by script,
   but anchoring cannot be excluded. A genuinely blind second read needs a context
   that has never opened the primary sheet.
3. **Same model family as the packets.** `deepseek/deepseek-v4.1-flash` produced
   the packets; this read was produced by a DeepSeek-family model. Full agreement
   is therefore weak evidence that the rubric was applied *correctly* and stronger
   evidence that it was applied *consistently*. It does not substitute for an
   independent human grader.
4. **Half the batch.** The other 30 packets have not been read a second time.

## How to cite

> Second read: agent, fresh session, 30 of 60 packets, 30/30 agreement with the
> primary sheet (0 disagreements), not independent of the generating model.
