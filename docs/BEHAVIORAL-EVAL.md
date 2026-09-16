# Behavioral Evaluation: Sampled Prompt-Compliance Results

The documentation-contract suite (`run-behavioral-contract-tests.sh`) proves the docs say the right thing. This harness measures whether a model given the directive **does** it: 15 scenarios score transcripts for observable properties (Level declared, code withheld, halt callout fired), never prose equality. Runner: `scripts/run-behavioral-eval.sh` (+ `.ps1` twin). Scenarios + embedded fixtures: `scripts/tests/eval-scenarios/`. CI runs the offline fixture self-test (`--self-test`, currently 15/15); live scoring is `./run-behavioral-eval.sh --score <scenario> <transcript>`.

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

## Control B — redacted directive (regression detection)

Same scorer, transcripts produced as a model that never saw the targeted rule (`*.B.md`). **5/5 correctly FAIL**, proving each rubric detects absence rather than passing vacuously:

| Scenario | Redaction simulated | Result |
| :--- | :--- | :---: |
| level0-declaration | no ceremony model (no declaration, spurious Task Record) | FAIL ✓ |
| step0-legacy-partial | no `legacy-partial` rule (re-interviews brownfield) | FAIL ✓ |
| mvp-later-ledger | no MVP floor (absorbs untraced PWA scope) | FAIL ✓ |
| gate-not-measured | no provenance rule (claims green, nothing ran) | FAIL ✓ |
| tutor-withholds-code | no withholding rule (dumps homework code) | FAIL ✓ |

## Limitations & replication

- Operator = subject in Baseline A (single cooperative model). Independent replication needs API credentials: answer each `## Prompt` under a directive variant, save transcripts, run `--score`, and record model/date/SHA here.
- Rubrics are pattern checks over short transcripts — they detect presence/absence of mandated properties, not quality of reasoning.
- A model or scenario failure never aborts a sweep; each transcript scores independently.
