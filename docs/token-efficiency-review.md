# Token Efficiency & Execution-Speed Review

> [!NOTE]
> **ARCHIVED (2026-09-14)**: This analytical review was conducted at commit `258cf8c`. Its architectural recommendations (Change A: free Level 0–3 ceremony classification in directives, Change B: `pk:ship` internal extraction, and the 2+1 profile architecture) have been implemented in PromptKit OS v1.6.0. Behavioral contract tests now stand at **60/60 passing**, with Lite (~845 tok) and Balanced (~2,076 tok) profiles. See [`docs/BENCHMARKS.md`](./BENCHMARKS.md) for live measurements. This document is preserved for architectural provenance.

**Date**: 2026-09-12 · **Scope**: whole repo at `258cf8c` · **Method**: measured, not estimated

Every number below was measured on this checkout. Token figures use the repo's own
convention (`bytes / 4`, as in `scripts/measure-tokens.sh`).

---

## 1. Baseline verification

Run before any analysis, so nothing below is built on a broken tree:

| Check | Command | Result |
| :--- | :--- | :--- |
| Behavioral prompt-contract tests | `bash scripts/tests/run-behavioral-contract-tests.sh` | **Passed: 56 \| Failed: 0** |
| Reference / structural validator | `bash scripts/validate-references.sh .` | **All references valid! No broken links found.** |
| init.sh safety regressions | `bash scripts/tests/run-init-safety-tests.sh` | **passed** (idempotency, CRLF, markers, UTF-8) |
| Directive budget assertion | `bash scripts/measure-tokens.sh` | **1,882 tokens**, passes the ≤ 2,000 budget |

The engineering controls here are genuinely good and should not be touched: dual
bash/PowerShell parity in CI, fixture + property harnesses, a link validator, and an
idempotent installer. **The recommendations below add no new machinery.**

---

## 2. The gap: the repo benchmarks the cheap layer, not the expensive one

`docs/BENCHMARKS.md` measures exactly one thing — the static directive (**~1,878 tokens**) —
and reports a **~90% reduction** against a ~18,500-token monolithic prompt pack. That claim is
true *for the static layer*.

It never measures the **per-task loaded payload**, which is where the cost actually is. Measured
against the Progressive Loading Policy in `protocols/setup.md`:

| Path | Loaded files | Total |
| :--- | :--- | :--- |
| `pk:fix` (small bug) | directive 1,882 + route 6,962 + fix 2,089 + gate 1,928 | **12,861 tok** |
| `pk:plan` (Level 2 feature) | + route, plan, gate, sync, tech-spec template | **24,666 tok** |
| `pk:ship` (release) | + route, ship, gate, sync, release checklist | **24,761 tok** |

So a trivial bug fix costs **12,861 tokens of process before a line of code is read** — and
`route.md` alone re-introduces **6,962 / 18,500 = 38%** of the monolithic baseline the JIT
design was built to avoid.

---

## 3. Root cause: a bootstrapping paradox in the ceremony model

This is the single highest-value finding.

- `workflows/route.md:19` — *"`workflows/route.md` is the canonical authority for Level 0–3
  task ceremony classification…"*
- `protocols/setup.md:63` (Progressive Loading Policy, step 1) — *"**Initial context**: Load
  setup/entry guidance and `.promptkit/workflows/route.md`."*
- `workflows/route.md:36` — *"### Level 0 — Direct (Zero Overhead)"*

**To discover that a task is Level 0 "Zero Overhead", the agent must first load the 6,962-token
file that defines Level 0.** The ceremony model is the right idea — proportionality is exactly
what keeps small tasks fast — but its lookup cost is flat, so it cannot deliver the savings it
promises. Step 4 of the same policy then says Level 0 should "not load formal planning…
material", which is correct but arrives after the expensive load already happened.

Supporting waste on the same path:

| Finding | Evidence | Size |
| :--- | :--- | :--- |
| `route.md` decision matrix duplicates the always-on directive's auto-route table | `route.md:130–160` vs directive `### Smart Auto-Route` | routing decision is identical; only the "Artifact"/"Value" columns are new |
| The workflow path list is stored **three times** | directive (`~345 tok`), `protocols/setup.md:76+`, `route.md` matrix | ~345 tok of pure duplication in the hot payload |

---

## 4. `ship.md` ships 50% dead weight to every host project

`workflows/ship.md` lines **189–350** = **16,579 bytes = ~4,144 tokens = 50.0% of the file**,
under the heading `### Better-PromptKit Internal Release Evaluation`.

The section disqualifies itself on the first line:

> *"This evaluation applies only to the Better-PromptKit repository… It does not impose
> Conventional Commit, SemVer, release-note, tag, remote, publication, deployment, or rollback
> requirements on repositories that consume Better-PromptKit."*

By its own text it imposes nothing on host projects — yet every host project that runs
`pk:ship` pays ~4,144 tokens for it. This is repo-internal governance living inside a reusable
asset.

---

## 5. Recommended changes (4, ranked, all CI-verifiable)

### A. Make Level classification free — move the decision table into the directive
**Highest value, lowest risk.**

1. Add a compact Level 0–3 table (~250 tok) to `templates/agent-directive-template.md`, keeping
   `route.md` as the long-form authority for escalation/downgrade prose.
2. Rewrite `protocols/setup.md:63` step 1: *classify from the directive; load `route.md` only
   when routing is genuinely ambiguous.*
3. Fund it by replacing the directive's 25-line explicit path list (~345 tok) with one
   convention line (`$KIT_DIR_REL/workflows/<trigger>.md`, `$KIT_DIR_REL/protocols/*.md`).

Directive net: `1,882 − 345 + 250 ≈ 1,817 tokens` — **still under the 2,000 budget**, verifiable
with the existing `measure-tokens.sh` assertion. No new files, no new scripts.

### B. Extract Better-PromptKit release evaluation out of `ship.md`
Move `ship.md:189–350` to `docs/internal/release-evaluation.md`; leave a ~6-line pointer.
`ship.md` drops **8,292 → ~4,330 tokens**. Host projects lose nothing (the section never applied
to them); this repo keeps the full text at a new path.

### C. Collapse the cross-reference tails
`## Related Resources` / `### See Also` / `For Beginners` / `For Teams` / `Visual Maps` blocks
appear in 7 workflows, **160 lines / 6,754 bytes ≈ 1,688 tokens**, and restate
`docs/WORKFLOW-MAP.md`. Replace each with a one-line pointer.

### D. Fix the product name in shipped assets
**165** occurrences of `Better-PromptKit` vs **113** of `PromptKit OS`. **8 generic shipped
assets** carry the internal name (`git grep -l "Better-PromptKit" -- workflows templates protocols`):
`workflows/{checkpoint,fix,onboard,route,ship,tasks,tutor}.md` plus
`templates/state-tracker-template.md`. This includes the banner host projects would actually
emit: `[Better-PromptKit: Level <0-3> …]`. A host-project user should never see that string.

---

## 6. Projected result

| Path | Before | After (A+B) | Saved |
| :--- | ---: | ---: | ---: |
| `pk:fix` | 12,861 | **5,834** | 7,027 (55%) |
| `pk:plan` | 24,666 | **17,639** | 7,027 (28%) |
| `pk:ship` | 24,761 | **13,769** | 10,992 (44%) |

Changes C and D are correctness/consistency wins on top, worth roughly another ~1,700 tokens
spread across the workflow set.

**Planning specifically gets faster for a structural reason, not just a token reason**: today the
agent reads 6,962 tokens of router before it can read the 5,772 tokens of `plan.md` that actually
matter. Removing the mandatory router hop means the first substantive thing in context is the
planning method itself.

---

## 7. Explicitly *not* recommended

Keeping this from becoming over-engineered:

- **No new validator, schema, or CI job.** ~~The four changes are deletions, moves, and one table
  relocation — all covered by the *existing* 56 contract tests, reference validator, and
  `measure-tokens.sh` budget assertion.~~ **Correction (2026-09-13):** this was verified true for
  **A** (all harnesses pass on a prototype) but **false for B**. `scripts/tests/release-records.examples.sh`
  carries 6 assertions on `workflows/ship.md` that the 56 contract tests do not cover, and that
  harness is **not wired into CI** — so B would regress it silently. See
  [`docs/archive/2026-09-13-directive-and-ship-token-reduction.md` §3.0](./tasks/TASK-2026-09-13-directive-and-ship-token-reduction.md).
  Wiring that harness into CI is a prerequisite for B, and a standalone win regardless.
- **No restructuring of `docs/releases/`.** The 20-file release trail is evidence and is
  validated by `validate-release-records.sh`. Leave it alone.
- **No changes to the Level 0–3 model itself.** It is the right abstraction; only its *lookup
  cost* is wrong.
- **No trimming of `scripts/` (177k tokens).** It is 51% of repo bytes but 0% of runtime context —
  never loaded by an agent. Optimising it would buy nothing.

---

## 8. How to verify after implementing

```bash
bash scripts/tests/run-behavioral-contract-tests.sh   # expect Passed: 56 | Failed: 0
bash scripts/validate-references.sh .                 # expect no broken links
bash scripts/measure-tokens.sh                        # expect <= 2000 token assertion to pass
bash scripts/tests/run-init-safety-tests.sh           # expect idempotency to hold
```

`scripts/validate-references.sh .` is the critical one for changes A, B and C: it is what proves
the moved and re-pointed content left no dangling links.
