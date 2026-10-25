# Behavioral Evaluation: Sampled Prompt-Compliance Results

The documentation-contract suite (`run-behavioral-contract-tests.sh`) proves the docs say the right thing. This harness measures whether a model given the directive **does** it: 34 scenarios grade **two independent axes** — the transcript's observable output properties (Level declared, code withheld, halt callout fired) and the recorded evidence in the capture bundle that holds it (an artifact exists, a prohibited write never happened, recovery reads happened in the mandated order). Never prose equality. Runner: `scripts/run-behavioral-eval.sh` (+ `.ps1` twin). Scenarios + embedded fixtures: `scripts/tests/eval-scenarios/`. CI runs the offline fixture self-test (`--self-test`), which scores every scenario's embedded PASS/FAIL fixture pair through the live check engine; live scoring is `./run-behavioral-eval.sh --score <scenario> <transcript>`.

**Honesty contract:** sampled compliance for named models at a named commit — not a guarantee.

## Baseline A — full directive (2026-09-16, `main` @ `90a4629`)

- **Model**: `muse-spark` (self-administered: the implementing agent answered each scenario prompt under the shipped Balanced directive, then scored with `--score`)
- **Transcripts**: `docs/internal/eval-baseline-2026-09-16/*.A.md`
- **Result: 15/15 PASS**

| Scenario | Result |
| :--- | :---: |
| level0-declaration, level2-declaration, tutor-withholds-code, risk-escalation, intent-in-prose | PASS ×5 |
| step0-complete, step0-legacy-partial, mvp-later-ledger, git-boundary | PASS ×4 |
| gate-not-measured, state-not-tracked, checkpoint-nudge | PASS ×3 |
| l1-no-task-record, halt-callout, card-provenance | PASS ×3 |

> Scope note: this sweep covers the 15 scenarios that existed at `90a4629`. `greenfield-saas-intake` was added afterwards and is exercised by the offline fixture self-test until a live sweep records it.

> Axis note: this sweep predates the presentation/behavioral split, so every result above is a **presentation** verdict only. Sixteen of the 34 scenarios now also declare evidence checks — `checkpoint-keyword-only`, `checkpoint-nudge`, `halt-callout`, `halt-committed-write`, `halt-framed-style`, `halt-missing-evidence`, `halt-missing-reply-hint`, `halt-reverted-write`, `halt-untracked-write`, and `halt-valid-resume`, plus the six Context Economy offline fixtures `ce-sufficiency-balanced`, `ce-sufficiency-lite`, `ce-escalation-balanced`, `ce-escalation-lite`, `ce-antistarvation-balanced`, and `ce-antistarvation-lite`; re-scoring those ten transcript files with no capture bundle beside them reports `behavioral=UNTESTED` and `provenance=unverified` rather than PASS on the behavioral axis. That is a gap in the recorded capture, **not** evidence of misbehavior — and it is not a result that any model complied. A baseline that grades the behavioral axis needs a real capture bundle beside **every** one of those ten transcripts (see [Evidence bundle](#evidence-bundle)). The six `ce-*` scenarios have no live transcripts at all; they are validated against offline synthetic fixtures only (see [Context Economy offline fixtures](#context-economy-offline-fixtures-issue-596)).

## Control B — redacted directive (regression detection)

Same scorer, transcripts produced as a model that never saw the targeted rule (`*.B.md`). **5/5 correctly FAIL**, proving each rubric detects absence rather than passing vacuously:

| Scenario | Redaction simulated | Result |
| :--- | :--- | :---: |
| level0-declaration | no ceremony model (no declaration, spurious Task Record) | FAIL ✓ |
| step0-legacy-partial | no `legacy-partial` rule (re-interviews brownfield) | FAIL ✓ |
| mvp-later-ledger | no MVP floor (absorbs untraced PWA scope) | FAIL ✓ |
| gate-not-measured | no provenance rule (claims green, nothing ran) | FAIL ✓ |
| tutor-withholds-code | no withholding rule (dumps homework code) | FAIL ✓ |

## Context Economy offline fixtures (issue #596)

Six scenarios (`scripts/tests/eval-scenarios/ce-*.md`) grade Minimum Sufficient Context discipline, Hard-Trigger zoom-out ordering, and anti-starvation halting under both the Balanced and Lite directive profiles, for issue #596 AC2. Their evidence classes are deliberately split, and the split is the point:

| Evidence class | Status |
| :--- | :--- |
| **Offline synthetic fixture validation** | **Completed.** The presentation fixtures grade 34/34 in both the Bash and the Linux PowerShell self-test, and Scenario AQ of `run-behavioral-contract-tests.sh` drives the evidence axis against synthetic bundles: read-only shell inspection is accepted, an observed `tool write` fails closed, a missing activity log and a placeholder provenance value never produce a full pass, and prose may name `docs/tasks/` without failing. Synthetic fixtures prove the rubrics discriminate — they are scorer diagnostics, not model-conformance results. |
| **Live Balanced/Lite discovery and compliance evaluation** | **Not executed.** No model has answered these prompts. Discovery (did the agent open `protocols/context-economy.md`) is graded out-of-band from a derived activity log, and no live capture exists for any cell. |
| **Broader model/host conformance** | **Not established.** Even a completed sweep would name one model on one host at one kit SHA — an n=1 pilot, not conformance. |

**Rubric corrections applied offline.** Negative controls found two false-positive patterns and both were fixed before publication: the anti-starvation `^tool exec .*migrations/pending/` prohibition (it rejected `cat`/`ls` inspection of the migration — correct anti-starvation behavior) and the sufficiency `not-contains: docs/tasks/` check (it failed ordinary prose that merely named the path). Both are now verb-anchored, and Scenario AQ pins the corrected behavior so the regression cannot return silently.

**Limitations recorded, not resolved:**

- The anti-starvation rubric proves that no dedicated `tool write` event was recorded. It does **not** prove the absence of shell-mediated writes: `tool exec` lines are recorded verbatim but are not parsed for write intent.
- The escalation ordering check proves that an `src/api/` read preceded the write to `src/auth/session.ts`. It does **not** prove that all callers were read, nor that the reads were of session consumers — complete caller coverage is not established.
- Shell parity was verified on Linux bash versus Linux PowerShell 7. Native Windows execution (path handling, execution policy, CRLF line endings) has not been locally validated; the Windows CI leg is that gate.
- The `\s` verb anchor is verified on GNU grep and .NET; BSD/macOS grep is unverified.

## Cross-Host Conformance Matrix

While this evaluation measures model-level compliance, host environment integration (CLI vs. IDE composer vs. extension sidecar) introduces an orthogonal fidelity axis. See [`docs/HOST-CONFORMANCE.md`](./HOST-CONFORMANCE.md) for the cross-host instruction fidelity matrix and scorer fixture validation framework under the pinned-model confound control.

## Result format

`--score` prints one machine-parseable line per transcript. Scenarios that declare evidence checks print all six fields; scenarios that declare none print the four-field shape:

```
SCENARIO|MODE|RESULT|checks=M/N|behavioral=VERDICT|provenance=STATE   # scenario declares evidence checks
SCENARIO|MODE|RESULT|checks=M/N                                       # scenario declares no evidence checks
```

The trailing `behavioral=` and `provenance=` fields appear **only** for scenarios that declare evidence checks, so a scenario without them prints the four-field shape and every consumer's anchor on fields 1–3 keeps working unchanged.

| Field | Meaning |
| :--- | :--- |
| `SCENARIO` | Scenario name, matching `scripts/tests/eval-scenarios/<name>.md`. |
| `MODE` | `live` for `--score`, `self-test` for `--self-test`. **This is an invocation token only.** |
| `RESULT` | The **presentation** verdict: `PASS` / `PARTIAL` / `FAIL`, decided by the all-must-hold rule over presentation checks. |
| `checks=M/N` | **Presentation checks only.** Evidence checks are graded on the separate behavioral axis and never appear in `M/N`. |
| `behavioral=` | The **behavioral** verdict, graded from bundle evidence alone: `PASS` / `PARTIAL` / `FAIL` / `UNTESTED`. |
| `provenance=` | `verified` or `unverified`. |

Existing consumers keep matching field 3 — e.g. `scripts/check-milestone-halt-evidence.sh` anchors on `^milestone-halt|live|PARTIAL|`. The extra fields are appended, never substituted.

### Presentation and behavioral verdicts are separate axes

Presentation asks *did the response render the mandated shape?* Behavioral asks *did the recorded evidence show the boundary was actually held?* Neither one substitutes for the other, and they are read independently:

- `PASS checks=7/7 behavioral=FAIL` is **not** a contradiction. It means the rendering was correct **and** a prohibited action was observed in tool activity. The presentation axis cannot see tool activity; only evidence can.
- `behavioral=UNTESTED` means **the evidence needed to judge was absent** — an invalid observation. It is **not** a pass and **not** a failure, and it never on its own changes the exit code. An absent write log, a missing bundle artifact, or an absent record makes the observation invalid rather than silently successful.
- `behavioral=FAIL` means an **observed** boundary violation: a prohibited action in recorded tool activity, or an inverted recovery-read order. This exits non-zero **even when presentation is `PASS`**, because the milestone-halt evidence checker consumes the exit status as success — a behavioral failure that exited 0 would be indistinguishable from a pass.
- `behavioral=PARTIAL` (or `PASS`) reports an evidence-backed verdict on the behavioral axis. When no evidence check fails and none goes untested, the behavioral verdict falls back to the presentation verdict, so the field never implies independent confirmation it did not get.

### `live` is not provenance

`MODE=live` says only that the harness was invoked with `--score` rather than `--self-test`. It does **not** establish provenance. Only a bundle carrying a complete `provenance.json` — all ten required keys — **plus** recorded tool activity yields `provenance=verified`. Anything short of that is `unverified`, which is the honest default.

## Evidence bundle

There is no CLI flag for the bundle. The evidence bundle is **`dirname(transcript)`** — the directory containing the transcript file. This is the layout `scripts/check-milestone-halt-evidence.sh` already invokes the harness with, so no new convention is introduced.

The authoritative bundle contract (required files, the ten `provenance.json` keys, seeding, and observation-window rules) is [`docs/internal/host-conformance/opencode-omo/README.md`](./internal/host-conformance/opencode-omo/README.md). Summary: `provenance.json` must carry `captureDate`, `promptkitCommit`, `profile`, `seedCommit`, `resetCommands`, `openCodeVersion`, `omoVersion`, `agentModel`, `observationStart`, and `observationEnd`; tool activity is recorded in `observed-writes.log` (or the milestone-halt `observed-m2-writes.txt`); and the canonical record is resolved through the bundle's `repository/` clone, the bundle root, the bare filename, or `state-at-end.md`.

### Check types

**Presentation checks** (four, unchanged — pattern checks over the transcript, decided by the all-must-hold rule):

| Check | Payload | Pass | Fail |
| :--- | :--- | :--- | :--- |
| `first-line-matches` | ERE | first line matches | line 1 does not match |
| `contains` | ERE | pattern occurs anywhere | pattern absent |
| `not-contains` | ERE | pattern absent | pattern present |
| `contains-any` | `ERE_A\|ERE_B` | at least one alternative matches | none match |

> [!NOTE]
> `|` is **always** an alternation separator inside `contains-any`, so a literal pipe character cannot be expressed in that payload. Use `contains` for a literal pipe.

**Evidence checks** (six, read the bundle, never move `RESULT`):

| Check | Payload | Pass | Invalid → `UNTESTED` | Violation → `behavioral=FAIL` |
| :--- | :--- | :--- | :--- | :--- |
| `evidence-present` | bundle-relative path | file exists and is non-empty | missing or empty | — |
| `evidence-absent` | bundle-relative path | file does not exist or is empty | — | file present and non-empty |
| `prohibited-action` | ERE over the write log | ERE never matches the recorded tool activity | bundle records no write log | ERE matches |
| `evidence-order` | `PATH_A\|PATH_B\|…` (≥2 steps) | first-occurrence line numbers strictly increase | fewer than 2 steps, no write log, or a step never observed | a step appears at a line before its predecessor |
| `repo-unwritten` | path or directory prefix | no recorded write at or under that prefix | bundle records no write log | a write was recorded, **even if later reverted** |
| `record-field` | `<record-path>\|<Label>` or bare `<Label>` | the field holds a real value | bundle holds no canonical record | field absent, or its value is a placeholder |

`evidence-order` is what makes a recovery-read mandate falsifiable: it proves the task record, then the checkpoint, then `STATE.md` and the host directive were actually read in that order, rather than asserting it with keywords. Two steps landing on the same line are not separable, so that reads as invalid rather than as a pass.

> [!IMPORTANT]
> `record-field` mirrors `scripts/validate-execution-control.sh` `field_value` semantics, so the label must appear as `- **Label**:` at **column 1**. Indented lines and Markdown table rows will **not** match — including the `Pending Human Actions` block in `templates/execution-task-record-template.md`, whose rows are table rows. Only the first match counts, and a fully backtick-wrapped value loses its outer backticks. An empty value or a placeholder is a violation, not a pass — placeholders being `N/A`, `n/a`, `None`, `none`, `Not applicable`, `[N/A]`, `[None]`, `[Pending]`, `Pending`, or anything else wrapped in square brackets. This is the same predicate `scripts/validate-execution-control.sh` uses, so the two graders cannot disagree about what counts as recorded.

## What these scenarios do and do not prove

- **Every scenario fixture in `scripts/tests/eval-scenarios/` is a scorer/policy diagnostic — never a model-conformance result.** The embedded `Transcript-PASS` / `Transcript-FAIL` fixtures are hand-written inputs that exist to prove the check engine detects presence and absence. Scoring them green proves the *rubric* works. It says nothing about any model's behavior, and no fixture in that directory may be cited as compliance evidence.
- **This change makes the evaluator honest; it does not establish that any model ever complied.** Splitting presentation from behavioral grading, and reporting absent evidence as `UNTESTED` rather than as success, raises what a green run can be taken to mean. It is a measurement-integrity fix, not a conformance result.
- **Issue #525 does not close #518 or #214.** #518 (genuine OpenCode + OmO capture) and #214 (live-model baseline replication) remain open; neither is substituted by an evaluator fix. Producing a passing run here still requires a real maintainer-executed capture bundle.
- **Missing evidence is reported as invalid/untested, never as successful behavior.**

## Limitations & replication

- Operator = subject in Baseline A (single cooperative model). Independent replication needs API credentials: answer each `## Prompt` under a directive variant, save transcripts, run `--score`, and record model/date/SHA here.
- Presentation checks remain pattern checks over short transcripts — they detect presence/absence of mandated properties in what was written, not quality of reasoning. The behavioral axis is now the answer to the narrower "did the transcript actually earn it" question: halt and checkpoint compliance additionally require **recorded evidence** in the bundle, so keywords alone can no longer satisfy those scenarios. Neither axis measures reasoning quality.
- A model or scenario failure never aborts a sweep; each transcript scores independently.
- Scoring a transcript with no bundle beside it yields `provenance=unverified`, and any evidence check that cannot be judged yields `UNTESTED`. That is a gap in the capture, not a result about the model.
