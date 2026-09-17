# Activity 05: Autonomous Orchestration Simulation (`pk:auto`)

## Overview
Run a safe, self-contained simulation of `pk:auto` — autonomous SDLC meta-orchestration — on a fictional bounded task. Internalize its three load-bearing boundaries **before** triggering it on a real project: the search circuit breaker, the test immobility invariant, and the default stop at review-ready.

> No repository, tool, or model access is required. Work through the scenario on paper or in chat with your AI assistant, using the scripted phases below. This kata changes nothing — it is a rehearsal, not an execution.

---

## The Scenario: Fictional Task

You are supervising an autonomous agent implementing this bounded task:

> **Task**: Add email-format validation to the signup form in `src/signup.ts`, with unit tests covering valid, invalid, and empty inputs. The existing suite has 12 passing tests, including `signup.test.ts` with an assertion that empty email must be rejected.

Declared boundary: **`review ready`** (default). The agent must halt with green tests and a clean diff — no commit, PR, or push.

---

## Simulation Steps

### Step 1: Turn 1 Banner — Declare the Leash (`pk:auto`)
1. State the boundary aloud: `pk:auto --until review` on the signup-validation task.
2. Confirm the expected Turn 1 banner: stopping at `review ready`, halts before commit/push, 3-strike test circuit breaker active.
3. Confirm the stop rule: the agent presents a clean diff for human review and does **not** auto-merge or auto-deploy.

### Step 2: Search Loop — Trip the Circuit Breaker
The scripted agent performs read/search calls **without editing or testing**:

1. `read src/signup.ts` — "Let me look at the form."
2. `search "email validation" in repo` — "Let me check existing patterns."
3. `read src/utils.ts` — "Maybe a helper exists."
4. `search "isValidEmail"` — "Checking for prior art."
5. `read docs/api.md` — "Checking the contract."
6. `search "signup"` — "One more sweep."
7. `read src/signup.test.ts` — 7th read/search call, **no edit or test yet**.

**Expected behavior**: At the L0/L1 threshold (≤6 consecutive read/search calls) the agent must **HALT** and ask you for paths or consult `PROMPTKIT.md` — not continue searching. At L2/L3 the limit is ≤12, with the same halt obligation.

> Why it matters: unbounded search loops burn context and tokens while making zero progress. The breaker converts "keep looking" into "ask the human where to look."

Discuss: *what would you tell the agent?* (Example: "Edit `src/signup.ts` directly — the validator belongs next to the submit handler.")

### Step 3: Failing Test — Hold Test Immobility
The agent edits the source, runs tests, and one assertion fails:

```text
FAIL signup.test.ts — "rejects empty email" (expected rejection, got acceptance)
```

The agent proposes: *"The assertion seems too strict — let me relax it so the suite passes."*

**Expected behavior**: **Refuse.** The agent must never edit, relax, or delete an existing test assertion to force green ([Test Immobility Invariant](../workflows/auto.md)). Only source files may change. After 3 failed remediation attempts it halts, checkpoints `docs/STATE.md`, and yields with diagnostics.

Discuss: *what is the correct remediation?* (Example: fix the validator in `src/signup.ts` so empty input is rejected — the test was right.)

### Step 4: Green Suite — Stop at Review-Ready
Tests pass. The agent presents:

```text
✅ 13/13 tests green. Diff: src/signup.ts (+18 lines) + signup.test.ts is untouched.
🏁 HALT at 'review ready' — clean diff below for your review. No commit, PR, or push performed.
```

**Expected behavior**: The agent **stops here**. It does not commit, open a PR, push, or deploy — the default `--until review` boundary halts before any git write. Human re-entry starts now:

1. Review the diff for spec fidelity (does empty/invalid/valid behave correctly?).
2. Run `pk:review` on the uncommitted code.
3. Either approve and run `pk:commit`, or redirect with a new instruction.

### Step 5: Debrief — Name the Three Boundaries
Without re-reading the scenario, state from memory:

1. **Search circuit breaker**: ≤6 (L0/L1) / ≤12 (L2/L3) consecutive read/search calls without an edit or test → HALT and ask.
2. **Test immobility**: never modify test assertions to force green → fix source or halt after 3 strikes.
3. **Review-ready stop**: default boundary halts with clean diff before commit/PR/push → human resumes.

---

## Facilitator Guide

**What to observe**: Does the participant let the agent keep searching past call 6 (Step 2), accept the weakened assertion (Step 3), or wave through an auto-commit (Step 4)? Each is a boundary violation — pause and replay the step.

**What correct behavior looks like**:
- Step 2: participant interrupts the loop and gives a path, citing the ≤6 threshold.
- Step 3: participant refuses the test edit, directs the fix at source, and names the 3-strike limit.
- Step 4: participant confirms the halt, reviews the diff, and describes the human re-entry (`pk:review` → `pk:commit`).

**Reference**: [`workflows/auto.md`](../workflows/auto.md) — the 5 hard rails, stop boundaries, and lifecycle diagram.

---

## Success Criteria
- [ ] Participant halts the scripted search loop at the circuit-breaker threshold and redirects with a path.
- [ ] Participant refuses the test-assertion edit and names test immobility + the 3-strike rule.
- [ ] Participant confirms the review-ready halt with no commit/PR/push and describes human re-entry.
