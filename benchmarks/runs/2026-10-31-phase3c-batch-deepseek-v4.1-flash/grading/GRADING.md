# Grading record — Phase 3c batch on `deepseek/deepseek-v4.1-flash`

Scored blind. The grader read only the frozen task rubrics, `B0nn.diff`, and
`B0nn.verify.txt`. `key-location.txt` was read for its digest and row count only;
neither the key nor `manifest.tsv` was consulted while scoring.

- **Sheet**: `grading.tsv` (blind-id keyed, written and hashed before `--finalize`)
- **Sheet digest**: `6bef724eb9d8bea2be2777b1ce85b5f51b95fc89b39fd1b0ba5488ba090688cb`
- **Rows**: 60 (one per packet), 336 rubric items total, **310 passed**
- **Result**: **48 of 60 runs accepted**; 12 packets failed at least one item

## Grader identity — read this before citing the result

**The grader was the coding agent that ran the batch, not a human.** Finalize was
run with `--graded-by machine`, so all 60 §5 records carry
`"grading": {"grader": "machine", "human_accepted": false}` beside their
`accepted` flag. Under §4 that makes this a **secondary consistency check**, not
the human primary grading §7 requires, and it cannot carry a quality decision.

Mitigation applied, because a model graded its own species output: every rubric
item is anchored to an artifact (probe exit, test names and totals, changed-file
set), the file-scope and test-deletion rules were checked mechanically across all
60 packets, and each rejected packet is named below with the item it failed.

## Evidence used per item

| Evidence | What it settles |
| --- | --- |
| `B0nn.diff` | implementation shape, changed-file set, whether a test line was deleted |
| `B0nn.verify.txt` | `verify_exit`, `VERIFY\|probe=…\|tests=…`, per-test names and totals, probe markers such as `METRICS\|OK` |

Mechanical checks run over all 60 packets before scoring:

- every packet changed-file set is a subset of its card allowed files;
- **no pre-existing assertion was removed or weakened** — the 15 deleted lines
  inside `test/` are all import rewrites (`import { createQueue } from ...`),
  none is an assertion;
- suite totals are 65 (seed baseline) plus the packet own additions, up to 73.

## Per-task item counts

| Card | Items | Packets | Passed |
| --- | --- | --- | --- |
| `P3C-01` (counters) | 5 | B019 B022 B025 B028 B036 B051 | 30/30 |
| `P3C-02` (`--dry-run`) | 5 | B004 B008 B020 B049 B052 B056 | 30/30 |
| `P3C-03` (status buckets) | 5 | B010 B013 B026 B034 B047 B060 | 30/30 |
| `P3C-04` (intake on restart) | 6 | B006 B012 B024 B029 B053 B057 | 35/36 |
| `P3C-05` (atomic batch) | 5 | B011 B021 B030 B039 B044 B058 | 29/30 |
| `P3C-06` (counts and sweep) | 6 | B001 B002 B014 B038 B041 B043 | 26/36 |
| `P3C-07` (store versioning) | 6 | B003 B017 B031 B032 B045 B050 | 36/36 |
| `P3C-08` (backoff cap) | 6 | B009 B016 B023 B027 B040 B055 | 36/36 |
| `P3C-09` (backpressure) | 6 | B007 B015 B018 B033 B035 B048 | 28/36 |
| `P3C-10` (queue drain) | 6 | B005 B037 B042 B046 B054 B059 | 30/36 |

## Rejected packets, and the item each failed

- **`B001` `B002` `B014` `B038` `B043`** (`P3C-06`, 4/6 each): the packet adds a
  `sweep` export that the probe cannot reach —
  `TypeError: scheduler.sweep is not a function` — so **R3** fails and
  `verify_exit=1` fails **R6**. The `counts` object itself is correct, which is
  why R1, R2, R4 and R5 pass.
- **`B011`** (`P3C-05`, 4/5): the fix is sound, but it adds a `remaining` getter
  to `src/queue.js` and the card freezes the changed-file set to
  `src/app.js` and `test/integration.test.js`, so **R5** fails.
- **`B007` `B015` `B035` `B048`** (`P3C-09`, 4/6 each): the behavior is correct
  and the spec stays pinned, but the case was written into
  `test/backpressure.test.js` or `test/app.test.js` instead of
  `test/integration.test.js`, so **R5** and **R6** fail.
- **`B057`** (`P3C-04`, 5/6): moves the replay helper into `src/store.js`, which
  the card does not allow, so **R6** fails.
- **`B054`** (`P3C-10`, 0/6): empty diff (the session lost to the provider abort),
  probe reports `shift called 3000 times during drain`; no item passes.

Six packets report `verify_exit=1` (`B001` `B002` `B014` `B038` `B043` `B054`),
which is the 54 of 60 the run record already reported.

## Judgement calls

- `P3C-06` `B041` builds `counts` inline instead of reusing the returned arrays.
  R2 asks only that the numbers agree with the arrays, and they do.
- `P3C-09` `B007` `B015` `B035` `B048` are the inverse case: the tested behavior
  is right and the file is wrong. Scored 4/6 rather than 6/6, because R5 and R6
  name the file the author is told to extend.
- `P3C-10` `B042` and `B059` drain with `splice(0)` while `B005` `B046` copy with
  `splice(0, items.length)` and `B037` uses `slice()` plus `length = 0`. All four
  satisfy R2 (no per-item `shift`); the rubric does not dictate the idiom.

## Measured after unblinding (`finalize.log`)

| Arm | n | Accepted | Rate | `tokens_total` | rework loops | CPAC n | CPAC median |
|---|---:|---:|---:|---:|---:|---:|---:|
| `bare` | 30 | 22 | 0.73 | 7,722,895 | 34 | 22 | .9283 |
| `promptkit_os` | 30 | 26 | 0.87 | 8,787,241 | 40 | 26 | .9650 |

Per card across three repeats: `promptkit_os` reaches 3/3 wherever `bare` does, and
3/3 alone on `P3C-04`, `P3C-05` and `P3C-10`. `P3C-06` is the only card where
neither arm reaches 3/3 (bare 0/3, `promptkit_os` 1/3), and `P3C-09` splits 1/3
each.

Cost: the median of per-task token ratios is **1.115** over all runs; the median
of per-task CPAC ratios is **0.980** over the 9 cards where both arms have an
accepted run. That CPAC figure is selection-biased and should not be compared
with the token figure: rejected runs score `INF (REJECTED)` and drop out of the
median, so the arm that fails more often has its most expensive runs removed.

Decision: under §8 the result is **Tradeoff** if the cost bar means either ratio
above 1.05 (the token ratio is 1.115) and **Inconclusive** if it means both (the
CPAC ratio is 0.980). The pre-registration does not settle that reading, so it is
recorded as a defect instead of being resolved after the numbers were seen.
Neither reading is a Keep. **No decision is claimed**, because §7 requires a human
primary grader who did not run the batch and that has not happened.
