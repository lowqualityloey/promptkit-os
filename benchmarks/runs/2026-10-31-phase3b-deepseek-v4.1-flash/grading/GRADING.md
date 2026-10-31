# Grading record — Phase 3b batch on `deepseek/deepseek-v4.1-flash`

Scored blind. The grader read only the frozen task rubrics, `B0nn.diff`, and
`B0nn.verify.txt`; `key-location.txt` was read for its digest and row count only,
and neither the key nor `manifest.tsv` was consulted while scoring.

- **Sheet**: `grading.tsv` (blind-id keyed, written and hashed before `--finalize`)
- **Sheet digest**: `6e2962a66a448846973d4bc6fb537245dfff2772699d005d14e22883b1c4a85a`
- **Rows**: 36 (one per packet), 210 rubric items total, 210 passed
- **Result**: 36 of 36 runs accepted; `finalize.log` carries the `RUN|` lines and
  the two `BENCH|SUMMARY|` aggregates

## Grader identity — read this before citing the result

**The grader was the coding agent, not a human.** §4 requires a primary grader
who did not run the batch and forbids the operator grading; it also states that
an AI re-grade is a secondary consistency check and never the primary. This sheet
is therefore **machine grading**: it establishes that every delivered packet
satisfies its frozen rubric on a mechanical reading of the artifacts, and it does
not establish independent acceptance. The batch stays labeled single-grader and
the human primary grading is still outstanding.

Mitigation actually applied, since a model graded its own species' output: every
rubric item is anchored to a probe the harness ran (not to the agent's prose),
the file-scope and test-deletion rules were checked mechanically across all 36
packets (below), and the two judgement calls are named at the end rather than
buried.

## Evidence used per item

| Evidence | What it settles |
| --- | --- |
| `B0nn.diff` | implementation shape, changed-file set, whether a pre-existing test line was deleted |
| `B0nn.verify.txt` | `verify_exit`, `VERIFY\|probe=…\|tests=…`, per-test names and counts |

Mechanical checks run over all 36 packets before scoring:

- every packet's changed-file set is a subset of its task's allowed files;
- no packet removes a line from `test/` (no pre-existing assertion deleted or weakened);
- every packet reports `verify_exit=0`, `VERIFY|probe=0|tests=0`, and a suite of at
  least 29 tests (seed baseline 28), so no packet passed by deleting tests.

## Per-task item counts

| Task | Items | Packets | Passed |
| --- | --- | --- | --- |
| `BENCH-L0-02` (peek) | 5 | B020 B028 B029 B031 B032 B033 | 30/30 |
| `BENCH-L1-03` (dispatcher counts) | 5 | B001 B003 B005 B011 B024 B027 | 30/30 |
| `BENCH-L1-04` (`--DRY_RUN`) | 6 | B008 B016 B017 B021 B026 B030 | 36/36 |
| `BENCH-L2-03` (unbounded capacity) | 6 | B006 B012 B013 B015 B019 B023 | 36/36 |
| `BENCH-L2-04` (`enqueueMany`) | 6 | B002 B009 B010 B014 B018 B025 | 36/36 |
| `BENCH-L3-01` (retry with backoff) | 7 | B004 B007 B022 B034 B035 B036 | 42/42 |

## Measured after unblinding (`finalize.log`)

Per-task medians of three repeats, PromptKit / bare:

| Task | Token ratio | CPAC ratio |
| --- | --- | --- |
| `BENCH-L0-02` | 1.423 | 1.407 |
| `BENCH-L1-03` | 0.934 | 0.934 |
| `BENCH-L1-04` | 1.075 | 1.231 |
| `BENCH-L2-03` | 0.869 | 0.981 |
| `BENCH-L2-04` | 1.375 | 1.364 |
| `BENCH-L3-01` | 1.127 | 1.115 |

L1+ median across the five tasks: **1.075 tokens**, **1.115 CPAC**, with quality
level (all 15 L1+ runs per arm accepted). On point estimates that is the
matrix's *non-inferior, no gain, both ≤ 1.25* row, but the task-cluster bootstrap
(10,000 resamples) puts the 95% interval at **0.869–1.375** tokens and
**0.934–1.364** CPAC: the token interval contains 1.25, which §7.3 defines as
**Inconclusive — no decision, no Phase 4, no public positioning**. That, not a
Keep, is what the batch supports, and it is what [`../README.md`](../README.md)
reports. The L0/L1 ceremony trigger for a #620 proposal does not fire: L0 is
1.423 but neither L1 task exceeds 1.25 (0.934 and 1.075).

## What this batch does and does not show

Every run met its frozen rubric, in both arms, on all three repeats. That is a
**ceiling result**, not a difference between arms: the batch discriminates nothing
about the treatment on quality, and none of these six tasks is hard enough for
this model to separate the conditions. Reported as measured; no claim beyond it.

Two judgement calls are worth naming:

- `BENCH-L1-04` R1: three packets (`B021`, `B026`, `B030`) coerce `DRY_RUN` to
  `true` inside `parseFlags` instead of keeping the raw value. The prompt says the
  flag counts as present bare or with a value, and the other flags keep their
  parsing, so all three pass; a stricter reading of "parseFlags keeps its parsing"
  would fail them, and the probe's `'DRY_RUN' in parseFlags([...])` check is what
  the rubric is anchored to.
- `BENCH-L3-01` R4: `B036` writes `attempts: maxAttempts` rather than a counted
  value. The two coincide because the loop can only fall through after exhausting
  its attempts, so the item passes.
