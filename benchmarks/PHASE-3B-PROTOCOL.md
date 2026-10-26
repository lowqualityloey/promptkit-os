# Phase 3b — Confirmatory A/B Protocol (Draft)

- **Status**: DRAFT — not frozen, not signed, not run. The document
  structure was approved on 2026-10-26; Phase 3b execution approval remains
  pending.
- **Date drafted**: 2026-10-26
- **Owner**: repository owner
- **Supersedes for decisions**: the Phase 3 pilot (`n=6`); the pilot remains
  published as a pilot, not as confirmatory evidence.
- **Related**: [#607](https://github.com/lowqualityloey/promptkit-os/issues/607),
  [#596](https://github.com/lowqualityloey/promptkit-os/issues/596),
  [#541](https://github.com/lowqualityloey/promptkit-os/issues/541),
  [#620](https://github.com/lowqualityloey/promptkit-os/issues/620), and the
  closed pilot issue
  [#694](https://github.com/lowqualityloey/promptkit-os/issues/694).

Read with:

- [Benchmark harness README](README.md)
- [Benchmark methodology](../docs/BENCHMARK-METHODOLOGY.md)
- [Empirical benchmark spec](../docs/specs/SPEC-empirical-benchmark.md)
- [Phase 3 pilot report](runs/2026-10-26-phase3-deepseek-v4.1-flash/README.md)
- [Post-publication B003/B006 re-grade](runs/2026-10-26-phase3-deepseek-v4.1-flash/README.md#post-publication-blind-re-grade-b003b006)

## 1. Purpose

Phase 3b is a **confirmatory** run, not an exploratory one. It asks one primary
question:

> At L1 and above, does the PromptKit `balanced` arm preserve blind-accepted
> quality without disproportionate token or modeled-CPAC overhead, compared with
> a neutral bare arm on the same tasks, model, host, and budget?

Secondary questions:

1. Is there measurable L0/L1 ceremony overhead without an L1 quality gain?
2. Does any quality or cost difference concentrate at L2/L3?
3. Is the cost per accepted task materially different?
4. Does any result survive the pre-registered timeout and cache-read
   sensitivity analyses?

The allowed claim is narrow: **in this batch, on these tasks, with this model,
seed, host, and protocol**. No result from six tasks supports a general claim
about PromptKit OS, other models, consumer application code, or long-horizon
work.

The pilot is not the basis for a keep/cut decision. It had three tasks, one
repeat, no L3, partial L0 blinding, a seed-level `AGENTS.md`/`heyloey` confound,
and two L2 sessions that hit the 900-second cap. Phase 3b exists to replace that
pilot with a pre-registered, isolated, repeated design.

## 2. Design

A paired, randomized block design:

- **6 tasks** × **2 arms** × **3 repeats** = **36 primary sessions**.
- Task blocks: **1 L0** (cost-only), **2 L1**, **2 L2**, **1 L3**.
- The arm is the only intended difference: `promptkit_os` receives
  `init.sh --balanced --host=agents`; `bare` receives no PromptKit install.
- All other variables are frozen: seed SHA, engine SHA, model, CLI version,
  prompt bytes, permission mode, tools, max turns, timeout, host profile, and
  grading procedure.
- The unit of analysis is the **task-run**. The task is the cluster. Repeats are
  not pooled as if independent tasks.
- All 36 primary runs are reported. No run is dropped because its result is
  inconvenient; infrastructure replacements are the only permitted substitution
  and are logged separately.

### 2.1 Why six tasks, not the original 8–12

Six tasks is the minimum confirmatory subset that doubles the pilot's task
coverage, triples its repeats, and adds an L3 cell within a 42-session hard cap.
It is **not** the full 8–12-task Phase 3. If the owner wants the full sample,
the task slate and cap must be expanded **before** the protocol is frozen; do
not add tasks after unblinding.

Six tasks is still small. The design can detect a consistent two-repeat quality
loss and a large, consistent cost ratio. It cannot estimate small effects with
confidence, and it does not justify a significance claim. The report must say
so.

### 2.2 Order and randomization

- Pre-register two separate numeric seeds: `--order-seed` for task/arm
  ordering and `--shuffle-seed` for blind-id assignment. The driver refuses to
  start without both and records both in `<out>/env.txt` and
  `<out>/isolation.txt`.
- Randomize the order of the six task blocks with the order seed.
- Within each task block, randomize arm order and repeat order. The driver
  takes the required `--order-seed` and derives the plan from it: it sorts
  SHA-256 digests of the seed with each task id and with each arm × repeat
  cell, writes the **complete** plan to `<out>/order.tsv` before the preflight
  exit and before the first session, and executes it as written, so neither arm
  is always first. The same seed reproduces the plan, and a mid-batch stop
  cannot truncate the pre-registration. Duplicate `Task ID`s are rejected
  before any session. Alternating would mean A-B, B-A, A-B across the three
  repeats; the driver uses the seeded shuffle instead. A second counterbalanced
  block would double the sessions and does not fit the 42-session cap; it is
  not used here.
- Randomize blind ids across all 36 runs, not per task or per arm, seeded from
  `--shuffle-seed`. The blind-to-scenario key stays out of the grading
  workspace.

### 2.3 Task selection

Tasks must be real backlog slices, not benchmark-artifact edits. Each task must
have:

- a frozen prompt and a frozen rubric written before any run;
- a deterministic `Verify` command that exits 0 on a compliant artifact;
- a bounded file scope and no destructive operation;
- no dependency on the pilot's already-discussed edits;
- a task-specific acceptance rule that is checkable from the stripped diff and
  the path-scrubbed verify packet.

**No task from the Phase 3 pilot may be a primary endpoint in Phase 3b.** The
pilot tasks were already seen, discussed, and used to tune the harness. They may
be used only as smoke tests/calibration and must not enter the 36-run analysis.
At least two of the six tasks must change executable code (not documentation
only). The L3 task must have an owner-approved scope and rollback plan; if no
real L3 task is available, run five tasks (1 L0, 2 L1, 2 L2), label the batch
`Phase 3b-L1L2`, and make no L3 claim rather than relabeling an L2 task.

The task slate is frozen in Appendix A before the run. If fewer than six
suitable new tasks exist, stop and revise the protocol; do not fill slots with
pilot tasks or invented tasks.

## 3. Seed and host isolation

### 3.1 Neutral seed

Preferred: a **neutral consumer repository** with a real backlog. Fallback: a
**neutralized copy of this repository** at a frozen SHA. In either case:

- Remove or replace all agent-instruction surfaces: `AGENTS.md`, `CLAUDE.md`,
  `PROMPTKIT.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`, `.clinerules`,
  `.cursor/rules`, `.claude/`, `.promptkit/`, `.github/instructions/`,
  `.github/copilot-instructions.md`, and any `heyloey` reference. A tracked
  `PROMPTKIT.md` or `.promptkit/` is a PromptKit install marker: `init.sh`
  treats it as an existing install and keeps its profile, so it is not a
  neutral surface for either arm.
- The bare arm starts from this neutral seed. The treatment arm's
  `init.sh --balanced --host=agents` writes the only PromptKit directive.
- The seed's tests must pass after neutralization; the task specs and `Verify`
  commands must run against the neutral seed.
- Record the neutral seed commit SHA and the neutralization procedure. Do not
  edit the seed during the run.
- The engine path remains the canonical PromptKit repo at the pinned SHA;
  `--engine` and `--seed` may point to different repositories.
- If the fallback self-referential seed is used, label the result
  **self-referential seed**; it does not generalize to consumer code.

### 3.2 Clean host

Use a dedicated OS user or container with:

- a fresh `HOME` containing only the minimum Command Code auth material;
- empty `~/.commandcode/taste/taste.md`;
- no `~/.commandcode` instructions, skills, hooks, MCP servers, or global
  `AGENTS.md`;
- no `heyloey` on `PATH`;
- the same `PATH`, environment, CLI version, and auth for both arms;
- no IDE or editor extensions injecting instructions.

If any surface cannot be neutralized, **stop**; do not run a “neutral-ish”
batch. The driver's isolation guard enforces the seed and host surfaces above
before any session, with no override; `--preflight-only` exercises it with zero
spend and a pass is recorded in `<out>/isolation.txt`. The JSON checks strip
whitespace before matching, so an empty `{}` or `[]` `hooks`/`mcpServers` value
passes in any formatting while any non-empty value fails closed.

## 4. Blinding and grading

- Blind ids assigned by a whole-batch shuffle; key stored outside the grading
  workspace.
- Grader receives only the task rubric, `B*.diff`, and `B*.verify.txt`; no
  manifest, scenario names, session logs, report, or key.
- Before grading, scan every packet for `promptkit_os`, `bare`, `BENCH-L`,
  absolute run paths, and scenario ids. Any hit stops the batch.
- The grader writes and hashes the grading sheet **before** the key is opened.
  Unblinding happens only after the sheet is locked.
- Primary grader: a human who did **not** run the batch and has not seen the
  mapping. The operator must not grade.
- If no separate human is available, label the batch **operator-adjacent,
  single human reviewer**; it cannot claim independent acceptance.
- A second human grader grades at least 50% of packets; report agreement and
  adjudicate disagreements with the rubric.
- An AI re-grade is a secondary consistency check only, never the primary. The
  pilot's post-publication B003/B006 re-grade does not substitute for
  human-independent grading.
- L0 acceptance is reported but is not part of the primary quality gate; an L0
  quality failure is investigated, not ignored.

## 5. Timeout and failure policy

- `--max-turns 40`; `--timeout 1800` for every session. If L2/L3 still hit
  1800, that is a timeout, not an invitation to extend.
- **Primary analysis is intention-to-treat (ITT): a timeout counts as task
  failure.** Artifact-graded acceptance is a per-protocol sensitivity analysis.
- Infrastructure failure before the first model turn may be replaced once, with
  a maximum of six replacements total, each logged. Model/tool failures after
  the first turn are not replaced.
- No re-run because the output looks bad. No outcome-based exclusion.
- If a task is broken for both arms, stop, fix under a logged deviation, and
  restart only if the fix happens before unblinding.

## 6. Metrics

**Quality** (primary at L1+):

- acceptance per task-run: all rubric items pass = accepted; partial = not
  accepted;
- rubric pass counts;
- accepted repeats per task;
- L3 quality is reported separately and included in L1+.

**Cost**:

- `tokens_total`, with successful/rework splits;
- input, output, and cache-read tokens separately;
- actual `transcript_cost_usd` from the CLI;
- modeled CPAC at the frozen reference prices ($3.00/1M input, $15.00/1M
  output, $0.05/rework loop; cache-read reported but not priced);
- tokens per attempted run (primary cost), tokens per accepted run (secondary).

**Operational**:

- wall-clock transcript span, `cli_exit`, timeout flag, rework loops,
  interventions.

No composite score; report components.

## 7. Pre-registered thresholds and decision rules

These are **proposed freeze values**. The owner must approve or change them
before the protocol is frozen. They may not be changed after unblinding.

### 7.1 Quality

- **Quality loss on a task**: PromptKit’s accepted repeats are **at least 2
  fewer** than bare’s out of 3.
- **Non-inferior aggregate**: PromptKit’s L1+ acceptance is **no more than 1
  accepted run lower** than bare’s out of 15 (5 L1+ tasks × 3).
- **Quality gain**: PromptKit is at least 2 accepted runs higher out of 15, or
  at least 2 repeats higher on any task.
- **Quality worse**: any L1+ task has a 2-repeat loss, or the aggregate is more
  than 1/15 lower.
- L3: no quality-loss task permitted; a single L3 loss is reported as a serious
  finding, not averaged away.

### 7.2 Cost

- Compute the per-task ratio PromptKit/bare from the median of three repeats.
- **Disproportionate**: median L1+ token ratio **> 1.25**, or median L1+ CPAC
  ratio **> 1.25**.
- **Material**: either ratio **> 1.50**.
- Token ratio is primary; CPAC is secondary. If they disagree, report both; a
  keep decision requires both ≤ 1.25.

### 7.3 Decision matrix

| Quality at L1+ | Cost (median token and CPAC) | Decision |
|---|---|---|
| Non-inferior, no gain | Both ≤ 1.25 | **Keep**; publish confirmatory result |
| Non-inferior, no gain | Either > 1.25 | **Overhead without benefit**; if L0/L1 corroborate, prepare #620; no public efficiency claim |
| Better | Both ≤ 1.25 | **Keep**; publish confirmatory result with quality gain |
| Better | Either > 1.25 and both ≤ 1.50 | **Tradeoff**; keep, report quality gain, no efficiency claim |
| Better | Either > 1.50 | **No public positioning**; investigate cost driver |
| Worse | Any | **No public claim**; keep as personal tooling; investigate |
| Inconclusive | Any | **No decision**; no Phase 4, no public positioning |

**L0/L1 ceremony trigger**: L0 is cost-only. Prepare a #620 proposal only if the
L0 token ratio is > 1.25 **and** at least one L1 task is > 1.25 with no L1
quality gain. A single L0 task is not enough.

**Inconclusive** means: the 95% bootstrap interval for the median token ratio
includes 1.25; or quality is mixed; or more than two protocol deviations
occurred; or more than 20% of primary runs are missing. Report the interval and
counts.

**Stop rules**: 42 sessions, 24 wall-clock hours, or $25 actual
`transcript_cost_usd`, whichever comes first. Six infrastructure failures also
stop the batch. No extension without a new protocol.

## 8. Analysis

- Paired by task; per-task median ratios for tokens and CPAC.
- Report median and mean of task ratios, individual task values, and n.
- Cluster bootstrap by task (10,000 resamples) for a descriptive 95% interval;
  do not present it as proof or a significance test.
- Quality: exact acceptance counts; per-task repeat comparisons; report
  McNemar only as secondary.
- Sensitivity: ITT vs artifact-graded timeout handling; cache-read
  included/excluded; actual cost vs modeled CPAC; L0 excluded; per-level.
- No subgroup fishing. Exploratory analyses are labeled exploratory.
- All 36 runs, replacements, timeouts, and deviations appear in the report.

## 9. Spend cap

| Item | Hard cap |
|---|---:|
| Primary sessions | 36 |
| Infrastructure replacements | 6 |
| Total CLI sessions | **42** |
| Wall-clock | **24 hours** |
| Per-session timeout | **1,800 seconds** |
| Max turns | 40 |
| Actual `transcript_cost_usd` guardrail | **$25** |

The session and time caps are binding; modeled CPAC is not a bill. No extra
runs, no “just one more repeat,” no re-running a task because the first result
was surprising.

## 10. Preregistration and change control

- Fill Appendix A (task slate) and Appendix B (frozen parameters) before the
  run.
- Commit the protocol; record the protocol commit SHA in Appendix B in a
  follow-up docs-only commit. The run starts only after both commits.
- Freeze the task bundle hash, model, CLI version, engine SHA, seed SHA,
  neutralization script SHA, shuffle seeds, thresholds, and cap.
- Any change after freeze is a deviation in Appendix C. A change after
  unblinding invalidates the confirmatory claim.
- The protocol, task specs, and report are published together; raw transcripts
  and the key stay local.

## 11. Execution checklist

- [ ] Owner approves task slate, thresholds, and spend cap.
- [ ] Neutral seed built; instruction surfaces removed; seed SHA recorded.
- [ ] Clean host verified: empty taste, no instructions/skills/hooks/MCP, no
  `heyloey`, same environment both arms.
- [ ] Isolation preflight guard passes.
- [ ] Driver patch for randomized/alternating task and arm order passes its
  tests.
- [ ] Task specs frozen; bundle hash recorded.
- [ ] `--preflight-only` passes; zero spend.
- [ ] Blind key generated and stored outside the grading workspace.
- [ ] Batch runs within cap; all operational failures logged.
- [ ] Blinding audit passes; grading sheet written and hashed before
  unblinding.
- [ ] Independent grader completes; second grader samples ≥50%.
- [ ] Finalize, analyze, and write the report with the decision.
- [ ] Only then: Phase 4 or a “no decision” closeout.

## 12. What Phase 3b does not establish

- General efficiency or quality of PromptKit OS.
- Other models, hosts, or consumer codebases.
- Long-horizon or multi-user behavior.
- L3 if no L3 task was available.
- Human independence if no separate human grader was available.
- A public positioning change; that requires the Phase 5 decision memo.

Phase 4 cross-model work starts only after a **Keep** or **Tradeoff** decision.
An **Inconclusive** or **Worse** result closes this line without Phase 4.

## Appendix A — Frozen task slate (fill before run)

| Slot | Level | Task ID | Issue | Seed area | Rubric | Verify | Status |
|---|---|---|---|---|---|---|---|
| 1 | L0 | TBD | TBD | TBD | TBD | TBD | new task; cost-only |
| 2 | L1 | TBD | TBD | TBD | TBD | TBD | new task; executable code |
| 3 | L1 | TBD | TBD | TBD | TBD | TBD | new task |
| 4 | L2 | TBD | TBD | TBD | TBD | TBD | new task |
| 5 | L2 | TBD | TBD | TBD | TBD | TBD | new task |
| 6 | L3 | TBD | TBD | TBD | TBD | TBD | owner-approved scope/rollback |

Rules: no pilot task; at least two executable-code tasks; no benchmark-artifact
edits; if no L3, use five tasks and label `Phase 3b-L1L2`.

## Appendix B — Frozen parameters (fill before run)

- Protocol commit: __________
- Freeze date: __________
- Owner approval: __________
- Model: __________
- Command Code version: __________
- Engine SHA: __________
- Seed SHA: __________
- Neutralization procedure SHA: __________
- Task bundle SHA-256: __________
- Blind-id shuffle seed: __________
- Task/arm order seed: __________
- Price inputs: $3.00/$15.00/$0.05; cache-read reported only
- Thresholds: quality 1-run aggregate / 2-repeat task loss; cost 1.25/1.50
- Spend cap: 42 sessions / 24 hours / $25 actual-cost guardrail

## Appendix C — Deviations log

| Date | Change | Reason | Before/after | Impact | Approved by |
|---|---|---|---|---|---|
| | | | | | |

## Appendix D — Preflight checklist

- [ ] `command-code --version` matches the frozen version.
- [ ] Model is pinned and available.
- [ ] Seed is neutral; no `AGENTS.md`, `CLAUDE.md`, Cursor/Claude/Copilot
  instructions, or `heyloey`.
- [ ] Host `HOME` has only auth; taste is empty; no hooks/skills/MCP/global
  instructions.
- [ ] `heyloey` is absent from `PATH`.
- [ ] Both arms see the same prompt bytes, tools, permission mode, max turns,
  and timeout.
- [ ] Task `Verify` commands pass on a known-good artifact and fail on a
  known-bad artifact.
- [ ] Blinding audit passes on a dry-run packet.
- [ ] Key is outside the grading workspace.
- [ ] Spend cap and stop rules are recorded.

## Approval

- [ ] I approve the task slate in Appendix A.
- [ ] I approve the thresholds in §7.
- [ ] I approve the 42-session / 24-hour / $25 cap in §9.
- [ ] I confirm the neutral seed and clean host preflight passed.

**Owner signature / date**: ______________________________

---

This document is the protocol. Phase 3b must not run until Appendix A and
Appendix B are filled, the owner signs the Approval section, and the protocol is
frozen by commit. That approval does not authorize benchmark spend or the
harness patch; those are separate, explicit steps.
