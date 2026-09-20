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

## The 6-Step Remediation Lifecycle

```text
┌─────────────────────────────────────────────────────────────┐
│                    PK:FIX LIFECYCLE                         │
├─────────────────┬─────────────────┬─────────────────────────┤
│ Step 1:         │ Step 2:         │ Step 3:                 │
│ Finding Review  │ Security-First  │ Reproduction or         │
│ & Scope Lock    │ Priority Check  │ Baseline Measurement    │
├─────────────────┼─────────────────┼─────────────────────────┤
│ Step 4:         │ Step 5:         │ Step 6:                 │
│ Surgical Fix    │ Evidence-Gated  │ Handoff & Atomic        │
│ Implementation  │ Verification    │ Conventional Commit     │
└─────────────────┴─────────────────┴─────────────────────────┘
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

### Step 5: Evidence-Gated Verification & Escape Hatch

1. **Lock-In Regression Test**:
   Convert the reproduction check into a permanent regression test at the real call-site seam (`pk:test`).
2. **Evidence-Gated Verification (Machine-Verified Quality Gate)**:
    - **Tiered Execution**: Execute the verification command matching the task ceremony level defined in `PROMPTKIT.md`:
     - *Level 0 (Direct)*: `fast` verification tier (e.g. `pnpm tsc --noEmit` or `cargo check`).
     - *Level 1 (Standard)*: `fast` + `required` verification tier (targeted unit/component tests).
     - *Level 2/3 (Controlled/Release)*: `fast` + `required` + `extended` verification tiers (full suite, schema validation, lint).
   - **Strict Completion Claim Invariant**: Completion claims strictly require executed evidence with `exit code 0`. You are forbidden from emitting a green Quality Gate card until this evidence exists in the current turn.
   - **Bounded Repair**: If verification fails (`exit code != 0`), apply a maximum of 2 automated repair attempts. If the 3rd attempt fails, HALT immediately with a `> [!WARNING] Blocked` callout.
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

### Step 6: Handoff & Atomic Conventional Commit

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
- [ ] Verification required by the task's ceremony level passes (Step 5 `fast` / `required` / `extended` tiers). Regression test added when the defect is behaviorally testable and an appropriate test seam exists.
- [ ] Changes staged cleanly via `pk:commit` with atomic Conventional Commit message.
- [ ] **Dual-Compatible Telemetry Status Card**: Conclude with a 3-line telemetry status card (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`) and a `> [!TIP]` callout recommending `pk:commit` or downstream verification. When multiple next steps exist, invoke native interactive selection tools (e.g. `ask_question`) as your final tool call with Option 1 `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`. If PROMPTKIT.md declares `status-cards: off`, skip the decorative card; `[!IMPORTANT]` / `[!WARNING]` halts still fire. Bounded to closed-set operational choices: for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead — see the Picker routing rule in `workflows/plan.md`.
