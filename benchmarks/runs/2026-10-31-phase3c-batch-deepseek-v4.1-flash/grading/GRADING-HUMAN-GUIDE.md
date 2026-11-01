# Human primary grading — Phase 3c batch (owner workflow)

This is the §7 primary grading. The machine sheet (`grading-machine.tsv`,
digest `6bef724e…`, 48/60 accepted) is a secondary check and must not be the
starting point, or the second read stops being independent.

## Files

| File | Purpose |
|---|---|
| `grading-human.tsv` | **The primary sheet.** 60 rows, sha256 `e4294ab3…`. Provenance is in `GRADING-HUMAN.md`: owner-authorized, agent-performed first pass. |
| `grading.tsv` | **Frozen machine sheet — do not edit.** Archived copy: `grading-machine.tsv` (same sha256, verified). |
| `grading-machine.tsv` | Reference only, for after the human sheet is hashed. |
| `grading-worksheet.md` | **The docket to grade from.** All 60 packets, one section each: changed-file set vs the card's allowed set, `verify_exit`, probe/suite line, any deleted lines under `test/`, and one blank verdict row per rubric item (336 rows total). It records facts only — it contains no verdicts. |
| `grading-human-blank.tsv` | Template for the human sheet. `rubric_total` is prefilled from the frozen cards; fill `rubric_passed` and `accepted` per packet, then save the completed sheet as `grading-human.tsv`. |
| `packets-to-cards.tsv` | Blind helper: `blind_id → card` (e.g. `B001 → P3C-06`). Derived from the already-published `GRADING.md` per-task table. **No arm, no scenario, no repeat info.** Use it to pick the rubric. |
| `second-grader-sample.txt` | 30 blind IDs (+ card) for the required ≥50% second read. |
| `B*.diff`, `B*.verify.txt` | The only evidence. 60 packets each. |

## Blinding discipline (read this first)

- Grade from **only**: the packet's `.diff` + `.verify.txt` and its card rubric in `benchmarks/tasks/TASK-P3C-NN.md` (via `packets-to-cards.tsv`).
- **Do not open** while scoring: the blind key (see `../key-location.txt` for where it lives — don't `cat` it), `grading.scenario.tsv`, `../manifest.tsv`, `../order.tsv`, any `../runs/*/` directory (`record.json`, `session.log`, install logs), or `grading-machine.tsv` / `grading.tsv`.
- The word `bare` appears in packets as the seed's own test name ("bare flags") — identical in every packet. Ignore it; judge arm-label shapes only.
- `verify_exit` and `VERIFY|probe=…|tests=…` come from the `.verify.txt` first line; probe markers (e.g. `COUNTS|OK`) per card.

## Scoring each packet

1. Changed-file set ⊆ card's allowed files (each card lists them; e.g. P3C-06 allows only `src/dispatcher.js`, `src/scheduler.js`, `src/app.js`, `test/dispatcher.test.js`, `test/scheduler.test.js`). Out-of-scope edit → fail the file-scope item.
2. No pre-existing assertion deleted or weakened (import rewrites are OK; assertion edits fail the test-scope item).
3. Probe items: pass only if the `.verify.txt` probe output shows the required behavior and `verify_exit=0`.
4. `accepted = (rubric_passed == rubric_total)`. An empty diff is scored item by item like any other packet, not charged with every item: `B054` (the provider-aborted cell) is 4/6 false, because the untouched seed already satisfies R1, R3, R4 and R6 of P3C-10 while R2 and R5 fail. It stays in the ITT denominator per the no-extra-runs rule. (Corrected 2026-11-01 after the second read; the earlier `0/N` rule contradicted the rubric and the primary sheet.)

## Recording

1. Copy `grading-human-blank.tsv` to `grading-human.tsv` and fill it (60 rows, tab-separated `blind_id rubric_passed rubric_total accepted` with `true`/`false`).
2. Hash **before** any unblinding: `sha256sum grading-human.tsv` — record the digest and row count.
3. Second grader independently scores the 30 packets in `second-grader-sample.txt`; report disagreements packet-by-packet (not averaged away).
4. Finalize from the batch directory:
   `bash benchmarks/run-ab-benchmark.sh --finalize "$PWD" --grading "$PWD/grading/grading-human.tsv" --graded-by human`
   Verify `GRADING|PROVENANCE|grader=human|human_accepted=true|records=60`.
5. Append the human figures to the batch `README.md` and `benchmarks/PHASE-3C-DESIGN.md` §10 (keep machine figures intact): per-arm acceptance, per-card table, token/CPAC medians with the `cpac_n` selection caveat, ITT vs complete-case sensitivity. Apply the §8 rule as amended by Amendment A (settled 2026-11-01, before grading): *Tradeoff* needs acceptance ≥ 5 points higher and the ITT token ratio above 1.05; CPAC is reported context, not a second gate. State the decision and whether Phase 4 opens.
