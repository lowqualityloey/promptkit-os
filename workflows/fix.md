# Remediation & Surgical Fix Workflow (Known Root Cause Findings)

## Fast Shorthand
Trigger anytime with: `pk:fix` (or `/pk-fix`)

## Mission
Guide the developer and AI assistant through surgical, disciplined remediation of **known defects, code review findings, security vulnerabilities, or performance bottlenecks** where the root cause has already been identified and classified.

Bridge the gap between diagnosis (`pk:review`, static analysis, security audit, or explicit bug report) and execution (`pk:commit`). Eliminate speculative code edits, enforce security-first resolution ordering, require targeted reproduction or baseline measurement, and lock in regression coverage before committing.

---

## Remediation vs. Scientific Debugging

| Dimension | `pk:debug` (Hypothesis-Driven) | `pk:fix` (Targeted Remediation) |
| :--- | :--- | :--- |
| **Root Cause State** | **Unknown** / Unclear failure mode requiring 5-Whys investigation and 3–5 ranked hypotheses. | **Known** / Classified finding from code review (`pk:review`), audit, static analysis, or explicit report. |
| **Primary Focus** | Establishing reproduction loop, isolating load-bearing variables, and hypothesis testing. | Surgical code repair, security-first ordering, single-concern scope, and regression lock-in. |
| **Handoff Rule** | If root cause is found, execute surgical fix or hand off to `pk:fix`. | If fixing reveals unexpected deeper failure or unknown root cause, hand off immediately to `pk:debug`. |

---

## Level 0–3 Task Ceremony Alignment

Before applying any fix, classify the task using the PromptKit OS ceremony model:

- **Level 0 — Direct Fix (Zero Overhead)**: Documentation typos, formatting, syntax lookups, and tiny 1-line non-risky tweaks. Direct execution: `understand → change → fast verify → atomic commit`. Zero Task Records, no GitHub issue required, no state tracking overhead.
- **Level 1 — Standard Fix (Low-Risk)**: Localized bug fix, code smell cleanup, or single-component repair without schema, auth, authorization, public contract, or multi-component risks. Modifies source files using natural workflow routing (`pk:fix` $\rightarrow$ `pk:test` $\rightarrow$ `pk:commit`) with lightweight inline tracking. Does **not** require a Task Record file (`docs/tasks/<task-id>.md`).
- **Level 2 — Controlled Fix (High-Risk)**: Fix involving relational schema/data migrations, auth/permissions, breaking public API contracts, or multi-component architectural changes. Requires a canonical Local Task Record at `docs/tasks/<task-id>.md` and formal specification before implementation.
- **Level 3 — Release-Critical Fix**: Production emergency patch or release candidate fix. Requires Level 2 evidence plus candidate evaluation (`pk:ship`), QA review, contract impact evidence, and explicit human authorization.

---

## The 7-Step Remediation Lifecycle

```text
┌─────────────────────────────────────────────────────────────┐
│                    PK:FIX LIFECYCLE                         │
├─────────────────────────────────────────────────────────────┤
│ Step 1: Finding Review & Scope Lock                        │
│ Step 2: Security-First Priority Check                      │
│ Step 3: Reproduction or Baseline Measurement                │
│ Step 4: Surgical Fix Implementation                        │
│ Step 5: Detour Entry, Failure Classification & Restore     │
│ Step 6: Evidence-Gated Verification & Escape Hatch         │
│ Step 7: Handoff & Atomic Conventional Commit               │
└─────────────────────────────────────────────────────────────┘
```

---

### Step 1: Finding Review & Scope Lock

1. **Inspect Finding**:
   Review the exact finding text, file paths, line numbers, and identified root cause from `pk:review`, code review checklist, lint output, or incident report.
2. **Single Root Cause Rule**:
   Scope the current change set to **one load-bearing root cause**. Do not combine unrelated code refactoring, styling tweaks, or multi-feature edits into a single fix.
3. **Validate Seam**:
   Identify the target file, module, or component where the fix belongs.

---

### Step 2: Security-First Priority Check

> [!CAUTION]
> **SECURITY & SAFETY ORDERING**: Address blocking security vulnerabilities, data loss risks, and unhandled access control defects first.

When remediating a batch of findings (e.g., from `pk:review` or an audit report), process issues in strict priority order:

1. **🚨 [BLOCKING] Security & Data Safety**: Parameterized queries (SQLi immunity), sanitized inputs (XSS prevention), authorization guards, HttpOnly cookie flags, zero `DROP TABLE`/`DROP COLUMN` drops without Expand-Contract when live or compatibility-sensitive data exists — one-shot, disposable, or pre-deployment changes may skip with documented rationale; otherwise `N/A - <reason>`.
2. **⚠️ [IMPORTANT] Performance & Reliability**: Missing `AbortController` signal, N+1 query elimination, unhandled promise rejections, missing error handling.
3. **💡 [SUGGEST] Code Smells & Maintainability**: Martin Fowler code smells (Mysterious Name, Duplicated Code, Primitive Obsession, Feature Envy).

Never defer a `🚨 [BLOCKING]` safety finding to implement a cosmetic suggestion.

---

### Step 3: Reproduction or Baseline Measurement

Before writing or editing code:

- **For Functional Defects & Code Smells**:
  Establish or execute a targeted reproduction check (a failing unit/integration test, curl command, or CLI script) that demonstrates the finding.
- **For Performance Findings**:
  Capture an empirical baseline measurement (`performance.now()`, query execution time, memory usage, or profiler trace) before modifying code. Never apply speculative performance tweaks without a baseline metric.

---

### Step 4: Surgical Fix Implementation

1. **Apply Minimal Change**:
   Make the smallest complete modification required to resolve the specific root cause.
2. **Preserve Invariants**:
   Ensure existing architectural constraints, type safety invariants, and public contracts remain intact.
3. **Clean Code Hygiene**:
   Purge any temporary diagnostic probes (`[DEBUG-xxxx]`) created during verification.

---

### Step 5: Detour Entry, Failure Classification & Parent Restoration

> [!IMPORTANT]
> **DETOUR DISCIPLINE**: A `pk:fix` run started *inside* an unfinished parent task is a **detour**, not the parent's completion. Record the parent continuation before touching code, then restore it. Repairing the bug does not complete the parent.

1. **Detour Entry — Capture Parent Continuation (no new state system)**:
   Before the first detour edit, write these into the **existing canonical Task Record** (`docs/tasks/<task-id>.md`; Level 0/1 uses inline tracking or `docs/STATE.md`): parent task ID and milestone, interrupted next action, parent objective, approved scope and non-goals, authorization reference, pending stop condition. A small bounded detour entry **inside** the current record — never a second record type, parallel ledger, or independent state system.
2. **Classify the Failure — Exactly One Verdict**:
   - **Approved-scope remediation**: the defect blocks the parent objective and its repair is inside approved scope → continue the detour.
   - **Blocking new requirement**: a new constraint blocks the parent objective → route through the existing Scope Change Record or planning re-open (`intake status: partial`) per the canonical New-Requirement Interception table in `workflows/sync.md`.
   - **Unrelated finding**: outside the parent objective → record it in the **Later ledger** or as its own Task Record. Never silently absorb it into the detour.
3. **Record Detour Verification and Result**: capture the detour's minimal verification command and result (Step 6 tiers scoped to the detour only). Detour evidence never satisfies the parent's remaining acceptance criteria.
4. **Detour Exit — Restore the Parent**:
   - *On success*: restore the parent's recorded next action, remaining acceptance criteria, and stop conditions. The parent returns to `in_progress` and continues its **own** remaining criteria; a green detour is not parent completion.
   - *Unresolved*: keep the captured parent continuation intact, record the blocker with owner and precise resume condition, and HALT with the canonical `> [!WARNING]` `### 🚫BLOCKED:` callout per `protocols/telemetry-cards.md`. Respect the Step 6 repair limit and any milestone sign-off. **A detour cannot grant new authority**: expanded scope, new approvals, or widened non-goals require human confirmation through the existing interception routes.
5. **Recover an Active Detour After Compaction or Handoff**: on a reported compaction, continuation, or fresh-session handover, run the canonical recovery in `workflows/sync.md`, then resume the captured parent continuation — reconcile against the recorded detour entry so recovery never spawns a duplicate parent task or drops a pending next action.

> [!NOTE]
> PromptKit states this discipline; the host executes it. There is no mechanical enforcement — record `POLICY_LIMITATION` when the host cannot observe an in-flight detour, and never claim this closes measured session drift.

---

### Step 6: Evidence-Gated Verification & Escape Hatch

1. **Lock-In Regression Test**:
   Convert the reproduction check into a permanent regression test at the real call-site seam (`pk:test`).
2. **Evidence-Gated Verification (Machine-Verified Quality Gate)**:
    - **Tiered Execution**: Execute the verification command matching the task ceremony level defined in `PROMPTKIT.md`:
     - *Level 0 (Direct)*: `fast` verification tier (e.g. `pnpm tsc --noEmit` or `cargo check`).
     - *Level 1 (Standard)*: `fast` + `required` verification tier (targeted unit/component tests).
     - *Level 2/3 (Controlled/Release)*: `fast` + `required` + `extended` verification tiers (full suite, schema validation, lint).
   - **Strict Completion Claim Invariant**: Completion claims strictly require executed evidence with `exit code 0`. You are forbidden from emitting a green Quality Gate card until this evidence exists in the current turn.
   - **Bounded Repair**: If verification fails (`exit code != 0`), apply a maximum of 2 automated repair attempts. If the 3rd attempt fails, HALT immediately with the canonical `> [!WARNING]` `### 🚫BLOCKED:` callout per `protocols/telemetry-cards.md`.
3. **Deterministic Verification Escape Hatch**:
   - If an environment prerequisite is genuinely unavailable (e.g. missing Docker daemon, live database credentials, mobile emulator):
   - The assistant is **strictly prohibited from looping in blind auto-repair attempts**.
   - **Protocol**:
     1. Record the blocked prerequisite in the evidence record: `> [!WARNING] Verification Blocked: Prerequisite '<name>' unavailable in environment.`
     2. Attempt permitted local fallback (e.g. static typecheck, schema lint, or unit dry-run).
     3. If verification remains blocked, **HALT immediately** and request human decision. Never claim completion without executed evidence.
4. **Instruction Layer Restraint**:
   - PromptKit prescribes policy and required evidence; command execution remains with host agent tools and local shell. PromptKit introduces no runtime daemons or execution engines.

---

### Step 7: Handoff & Atomic Conventional Commit

Once verified, hand off to downstream workflows:

- **`pk:commit`**: Stage single-concern files and format atomic Conventional Commit (`fix(scope): concise summary`). Include root cause context in commit body.
- **`pk:review`**: Re-audit complex multi-file fixes across Spec Fidelity and Technical Standards.
- **`pk:pr`**: Compile test evidence and update PR description.
- **`pk:ship`**: Evaluate candidate for production release if Level 3 Release-Critical.
- **`pk:debug`**: Hand off immediately if the fix fails or reveals an unknown deeper defect.

---

## Completion Criteria
- [ ] Finding classified with known root cause and scope locked to one load-bearing issue.
- [ ] Security-first ordering enforced (`🚨 [BLOCKING]` resolved first).
- [ ] Reproduction check or performance baseline captured prior to editing code.
- [ ] Minimal surgical fix applied without unrelated scope creep.
- [ ] Verification required by the task's ceremony level passes (Step 6 `fast` / `required` / `extended` tiers). Regression test added when the defect is behaviorally testable and an appropriate test seam exists.
- [ ] Detour bookkeeping (Step 5) satisfied when this fix ran mid-task: parent continuation captured before the detour, failure classified into exactly one verdict, detour verification recorded, and the parent's next action and remaining acceptance criteria restored on exit — or the blocker, pending stop condition, and resume condition recorded when unresolved.
- [ ] Changes staged cleanly via `pk:commit` with atomic Conventional Commit message.
- [ ] **Dual-Compatible Telemetry Status Card**: Conclude with a 3-line telemetry status card (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`). Add a `> [!TIP]` recommending `pk:commit` or downstream verification only when no higher-priority `[!IMPORTANT]` or `[!WARNING]` halt is active. Every human callout block must include an explicit action hint (`👉 Reply: Type '...'` or `👉 Action: Press Enter to accept Option 1 ...`). When multiple next steps exist, invoke native interactive selection tools (e.g. `ask_question`) as your final tool call with Option 1 `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`. If PROMPTKIT.md declares `status-cards: off`, skip the decorative card; halts still fire. Bounded to closed-set operational choices: for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead — see the Picker routing rule in `workflows/plan.md`.
