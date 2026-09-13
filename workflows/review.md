# Review Workflow (Two-Axis Senior Code & Architecture Review)

> **Developer-friendly review guide:** A **Required** field or report section must be completed before the review can be considered complete. **Optional** evidence may be recorded when it exists; **Not applicable** means the concern does not apply and should say why. A **fixed point** is the exact baseline revision used for the comparison, and the two axes are independent: **Spec Fidelity** asks whether the requested behavior was implemented, while **Standards & Code Quality** asks whether it was implemented safely and maintainably. Keep findings concise and reproducible by naming the file/section, observed risk, and next action. **Example:** `src/auth.ts:42 - [IMPORTANT] missing authorization check - add the role guard and rerun the focused test`.
>
> **Acronym guide:** `PR` means Pull Request; `OWASP` means the Open Worldwide Application Security Project; `a11y` means accessibility; and `YAGNI` means You Aren't Gonna Need It. These terms explain the existing review language and do not create approval, merge, release, deployment, or rollback authority.

## Fast Shorthand
Trigger anytime with: `pk:review` (or `/pk-review`)

## Mission
Conduct a thorough, multi-dimensional Senior/Staff Software Engineer review on uncommitted changes, branches, or PR diffs.

Review across **two orthogonal axes**:
1. **Spec Fidelity**: Does the change faithfully implement what the issue, PR, or user spec requested without scope creep or missed constraints?
2. **Standards & Code Quality**: Does the change adhere to documented project standards, Martin Fowler's code smell baseline, OWASP security, performance, accessibility, and zero accidental data loss?

## Canonical Review Report

`pk:review` owns one durable two-axis report at `docs/reviews/<review-slug>.md`. The report has the immutable identity `REVIEW-<review-slug>` and exposes that identity as an explicit `<a id="REVIEW-<review-slug>"></a>` anchor immediately before its heading.

### Review Record Metadata

- **Review ID [Required]**: `REVIEW-<review-slug>`
- **Review Status [Required]**: `draft | complete | superseded`
- **Resolved Diff Reference [Required]**: `[non-empty fixed-point diff link or revision]`

The report remains the sole home for review findings and the recommendation-only Simplification Audit; keep that audit inside the existing two-axis report and write the exact result `No Simplification Candidates found` when no defensible candidate exists. Do not create a separate simplification authority or use the untracked `semantic-review/` directory as a canonical path.

From a Task Record, link the report with `[REVIEW-<review-slug>](../reviews/<review-slug>.md#REVIEW-<review-slug>)`; from another directory, use the relative path to `docs/reviews/<review-slug>.md`. A same-file link uses `[REVIEW-<review-slug>](#REVIEW-<review-slug>)`. Link the report to the canonical Task Record when reviewing Level 2 (Controlled) or Level 3 (Release-Critical) Work. Level 0 and Level 1 reviews do not require a formal Task Record link. A review report records findings and recommendations only; it does not edit source or authorize commit, merge, release, deployment, rollback, or other remote actions.

---

## Why Two Axes?
A pull request can fail in two completely distinct ways:
- **Standards Pass, Spec Fail**: Code conforms to all lint rules, architectural patterns, and type constraints, but implements the wrong business behavior or omits critical edge cases.
- **Spec Pass, Standards Fail**: Code implements every requested feature, but introduces code smells, security vulnerabilities, or performance regressions.

Reporting them separately ensures neither axis masks the other.

---

## Mandatory Pre-Flight Guardrails

### 1. Diff Baseline Pinning
Establish and validate the appropriate diff comparison baseline before reviewing:

- **Branch / PR Review (Committed feature branch against base)**:
  ```bash
  git rev-parse <fixed-point>                    # Confirm reference exists (e.g. main, origin/main, HEAD~3)
  git diff <fixed-point>...HEAD                  # Extract three-dot comparison against merge-base
  git log <fixed-point>..HEAD --oneline          # Inspect commit history
  ```
- **Staged Changes Review (Index before commit)**:
  ```bash
  git diff --cached                              # Extract staged changes ready for commit
  ```
- **Working Tree / Uncommitted Review (Working directory edits)**:
  ```bash
  git diff HEAD                                  # Extract all uncommitted (staged + unstaged) changes
  git status -s                                  # Inspect untracked files to avoid missing new files
  ```

> [!NOTE]
> When reviewing uncommitted changes directly on `main`, running `git diff main...HEAD` produces an empty diff. Select the matching baseline mode (`git diff HEAD` or `git diff --cached`) rather than stalling. If the selected baseline produces an empty diff and no untracked files exist, halt and clarify the target revision before continuing.

### 2. Accidental Data Loss Audit (STOP AND VERIFY)
> [!CAUTION]
> **MANDATORY BLOCKING AUDIT**: Review every migration, script, and database call for irreversible data loss.
>
> Any finding matching the following criteria is automatically flagged as **🚨 [BLOCKING]**:
> - **Destructive Migrations**: `DROP TABLE`, `DROP COLUMN`, `TRUNCATE`, or destructive type alterations without a backward-compatible, multi-phase migration strategy (Expand-Contract Pattern).
> - **Unbounded Deletions**: SQL `DELETE` without a strict `WHERE` clause, or bulk cascade deletions missing soft-delete flags.
> - **Filesystem & Cloud Storage Destruction**: Un-versioned object deletions (`rm -rf`, bucket purge scripts) without backup confirmation.
> - **Hard Resets**: In-code process automation running destructive Git resets or database purges.

### Controlled & Release-Critical Work Traceability Preflight

Before applying the two-axis review for Level 2 (Controlled) or Level 3 (Release-Critical) Work, validate the evidence without creating or repairing it:

- Confirm the Task ID/specification and canonical `docs/tasks/<task-id>.md` record match the reviewed branch and execution scope.
- Confirm the Task Record state, active-task ownership, allowed transitions, changed-file scope, stable `AC-*` results, verification/CI evidence, and current revision.
- Confirm blockers, Scope Change Records, Exception Records, Checkpoint/Handoff Records, and receiver validation are complete where applicable.
- Treat stale handoffs, unresolved blockers, illegal transitions, scope violations, missing completion evidence, and revision mismatches as review findings. Route them through the existing severity framework; do not silently repair records or create a third review axis.
- A passing validator, checkpoint, or CI job supports traceability only. It is not code-review approval, merge approval, release approval, or authorization for remote actions.

QA/Reviewer records stale or inconsistent execution evidence as findings in the existing severity framework, links review evidence to the Task Record, and does not silently repair records or create a third review axis. Review findings do not become release approval; the Release Coordinator remains the owner of release evaluation.

---

## Review Severity Framework

```
┌─────────────────────────────────────────────────────────────┐
│                 REVIEW COMMENT SEVERITY TIERS               │
├───────────────┬─────────────────────────────────────────────┤
│ 🚨 [BLOCKING]  │ Data loss risk, security vulnerability,     │
│               │ broken spec contract, race condition, or    │
│               │ broken build/test. Must be fixed before PR. │
├───────────────┼─────────────────────────────────────────────┤
│ ⚠️ [IMPORTANT]│ Performance degradation, missing error case,│
│               │ poor test coverage, code smell, or a11y bug.│
├───────────────┼─────────────────────────────────────────────┤
│ 💡 [SUGGEST]  │ Architectural elegance, idiomatic refactor, │
│               │ DX improvement, or naming clarity.          │
├───────────────┼─────────────────────────────────────────────┤
│ 👏 [PRAISE]   │ Clean pattern, great test, or clever design. │
└───────────────┴─────────────────────────────────────────────┘
```

---

## Evaluation Axes

> [!TIP]
> **Subagent Delegation for Dual-Axis Auditing (`protocols/subagent-delegation.md`)**:
> In agentic environments, delegate Axis 1 (Spec Fidelity) and Axis 2 (Technical Standards) to concurrent subagents. The parent agent receives both synthesized reports and merges them into the final side-by-side review comment table.

### Axis 1: Spec Fidelity Review
Review the diff against the originating specification, issue description, or PR requirements:
- [ ] **Missing Requirements**: What requirements did the spec ask for that are omitted or only partially implemented?
- [ ] **Scope Creep**: Does the diff include unasked-for behavior, speculative abstractions, or unrelated changes?
- [ ] **Flawed Implementations**: Which requirements look implemented on the surface, but fail boundary conditions, error flows, or business rules?

---

### Axis 2: Standards & Code Quality Review

Audit the diff against documented project standards (`PROMPTKIT.md`, `CODING_STANDARDS.md`), plus the universal **Martin Fowler Code Smell Baseline**:

#### Martin Fowler Code Smell Baseline
1. **Mysterious Name**: Variable, function, or class name obscures intent.  
   $\rightarrow$ *Remedy*: Rename to reveal the domain concept or responsibility.
2. **Duplicated Code**: Identical or near-identical logic appears across multiple hunks.  
   $\rightarrow$ *Remedy*: Extract a shared pure function, hook, or utility.
3. **Feature Envy**: A function or method reaches into another object's fields more than its own.  
   $\rightarrow$ *Remedy*: Move the method onto the object owning the data.
4. **Data Clumps**: The same 3-4 fields or parameters continually travel together.  
   $\rightarrow$ *Remedy*: Bundle them into a dedicated type, struct, or interface.
5. **Primitive Obsession**: Raw strings or numbers representing domain concepts (e.g., currency, status, ID).  
   $\rightarrow$ *Remedy*: Introduce branded types, enums, or value objects.
6. **Repeated Switches**: The same `switch` or `if/else` chain on a type or status appears in multiple files.  
   $\rightarrow$ *Remedy*: Replace with polymorphism or a centralized lookup map.
7. **Shotgun Surgery**: A single logical business change requires edits scattered across many unrelated files.  
   $\rightarrow$ *Remedy*: Re-group and co-locate cohesive modules.
8. **Divergent Change**: One file is frequently modified for multiple unrelated business reasons.  
   $\rightarrow$ *Remedy*: Split the module along single-responsibility boundaries.
9. **Speculative Generality**: Generic hooks, config flags, or abstractions added for unrequested future needs.  
   $\rightarrow$ *Remedy*: Delete unused abstractions and inline the code (YAGNI).
10. **Message Chains**: Deep dereferencing walks (`a.getB().getC().getD()`).  
    $\rightarrow$ *Remedy*: Apply the Law of Demeter; encapsulate the walk behind a root method.
11. **Middle Man**: A class or helper that does nothing except delegate to another module.  
    $\rightarrow$ *Remedy*: Remove the middleman; call the target module directly.
12. **Refused Bequest**: A subclass or implementation that ignores or overrides most inherited behavior.  
    $\rightarrow$ *Remedy*: Replace inheritance with composition.

#### The 6 Core Technical Pillars
- **Architecture & Cohesion**: Single responsibility, clean module boundaries, minimal coupling.
- **Correctness & Concurrency**: Async race protection (`AbortController`), unhandled promise rejection safety, atomic state updates.
- **Security & Safety**: Runtime schema validation (Zod), parameterized queries (SQL injection immunity), sanitized HTML (XSS prevention), secret/PII redaction.
- **Performance & Resources**: Eliminated N+1 queries, indexed lookups, memoized expensive computations, teardown of event listeners/timers/subscriptions.
- **Accessibility (a11y) & UX**: WCAG 2.2 AA compliance, semantic HTML (`<button>`, `<main>`, `<nav>`), keyboard navigation, clear focus rings, ARIA labels.
- **Testing & Observability**: Tests asserting observable behavior at the real seam, failure-mode test cases, structured logging with correlation IDs.

---

## Review Report Output Format

```markdown
# Senior Code Review: <PR Title or Feature Name>

## Executive Summary
- **Overall Verdict**: [Approved | Changes Requested | Discussion Required]
- **Fixed Point Baseline**: `git diff <base>...HEAD` (<N> files changed, +<X> / -<Y>)
- **Spec Fidelity**: [Clean Match | Scope Creep Detected | Missing Requirements]
- **Technical Standards**: [High Quality | Minor Code Smells | Blocking Issues Found]

---

## Axis 1: Spec Fidelity
*(Review against originating issue / technical specification)*

### Missing / Partial Requirements
- **`docs/specs/feature-x.md:L42`**: Missing rate-limiting fallback on tier downgrade.
  - *Detail*: Spec mandates a 429 response with `Retry-After`, but current implementation silently drops the request.

### Scope Creep / Unrequested Behavior
- None detected.

### Implementation Discrepancies
- **`src/services/billing.ts:L88`**: Discount calculation applies before tax instead of after.

---

## Axis 2: Standards & Code Quality
*(Review against project standards, OWASP, Fowler smells, and data safety)*

### 🚨 [BLOCKING]
- **`prisma/migrations/20260906_drop_user_column/migration.sql:L3`**: Irreversible column drop.
  - *Risk*: `DROP COLUMN phone_number` without an Expand-Contract transition will break rolling zero-downtime deployments.
  - *Required Fix*: Retain column as nullable/deprecated until next major deployment.

### ⚠️ [IMPORTANT]
- **`src/hooks/useProjectFilter.ts:L34`**: [Repeated Switches / Race Condition]
  - *Finding*: Filter triggers asynchronous fetch without an `AbortController`. Rapid filter clicks cause stale resolution.
  - *Remedy*: Pass `signal` to fetch client.

### 💡 [SUGGEST]
- **`src/components/UserBadge.tsx:L12`**: [Primitive Obsession]
  - *Finding*: Role passed as raw string `string`.
  - *Remedy*: Use `UserRole` enum or branded union type.

### 👏 [PRAISE]
- **`src/lib/auth/token.ts:L55`**: Flawless timing-safe buffer comparison preventing timing attacks.

---

## Simplification Audit

The Simplification Audit is a recommendation-only section inside this existing `pk:review` report. It is not a third review workflow, severity axis, execution authority, or replacement for the Spec Fidelity and Standards & Code Quality axes.

### Audit Trigger and Record

Run this section only after the mandatory pre-flight, including a resolved fixed-point baseline, and only when the resolved diff is non-empty. If the diff is empty or the baseline is unresolved, stop the review and resolve the baseline; do not record a successful no-candidate result for an empty diff.

- **Review ID [Required]**: `REVIEW-<review-slug>`
- **Audit Status [Required]**: `draft | complete | superseded`
- **Resolved Diff Reference [Required]**: `[fixed-point revision or link]`
- **Audit Result [Required]**: `Candidate(s) recorded | No Simplification Candidates found`
- **Authority [Required]**: `pk:review`; the report remains the sole home for findings and recommendations

Inspect the resolved diff for behavior-preserving opportunities supported by concrete evidence. Record only candidates classified as one of:

- `deletion`
- `consolidation`
- `inlining`
- `control-flow reduction`

Do not duplicate the existing review axes or Fowler smell baseline. An unsupported cleanup idea, a speculative refactor, or an item without preservation evidence and a verification path is not a Simplification Candidate.

### Simplification Candidate Record

For each defensible candidate, expose the exact immutable ID as an anchor immediately before the candidate heading:

<a id="SIMPLIFICATION-REVIEW-<review-slug>-001"></a>
#### Simplification Candidate: `SIMPLIFICATION-REVIEW-<review-slug>-001`

- **Candidate ID [Required]**: `SIMPLIFICATION-REVIEW-<review-slug>-<nnn>`
- **Classification [Required]**: `deletion | consolidation | inlining | control-flow reduction`
- **Affected Location [Required]**: `[File path and symbol, section, or line range]`
- **Diff Evidence [Required]**: `[Specific fixed-point diff hunk or linked review evidence]`
- **Behavior-Preservation Condition [Required]**: `[Observable behavior, contract, invariant, or compatibility condition that must remain true]`
- **Risk [Required]**: `[Risk if the recommendation is applied]`
- **Verification Action [Required]**: `[Test, check, review, or other evidence required before accepting the recommendation]`
- **Recommendation [Required]**: `[Behavior-preserving simplification recommendation for a human owner to consider]`

A candidate is valid only when every required field is supported by the resolved diff and has a verification action. The audit records a recommendation only: it does not edit, delete, stage, commit, approve, change review severity, trigger cleanup work, or authorize merge, release, deployment, rollback, or another remote action.

### No-Candidate Result

When the resolved, non-empty diff contains no defensible candidate, record exactly:

`No Simplification Candidates found`

Candidate-only fields are `N/A - no defensible candidate` only with that explicit result. Do not invent cleanup ideas to populate the section. A passing audit, validator, checkpoint, or CI result is evidence only and does not approve an implementation change.

---

## Independent Fresh-Context Verification (Level 2 & 3 Work)

When an agent reviews code it authored within the same conversation, it faces cognitive confirmation bias (assuming edge cases, null boundaries, and negative flows were naturally satisfied).

For **Level 2 (Controlled)** and **Level 3 (Release-Critical)** Work, the lead agent should delegate the two-axis audit to a dedicated **Fresh-Context Verifier Subagent** ([`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md)):

1. **Scope Exclusions (Zero Overhead)**:
   - **Level 0 & Level 1**: **Bypassed completely (0 extra tokens)**. Single-agent review remains standard for localized fixes, small components, and everyday tasks.
   - **Level 2 & Level 3**: Invoked before final PR submission for relational schema changes, auth rewires, breaking public API modifications, or release candidates.
2. **Verifier Briefing Inputs**:
   - The verifier subagent receives *only*:
     - The target Gherkin Acceptance Criteria (`AC-*`) from `docs/tasks/<task-id>.md` or RFC spec.
     - The fixed-point git diff (`git diff <baseline>...HEAD`).
     - The automated test runner commands.
3. **Strict Bounds & Token Caps**:
   - **Single-Pass Contract**: Perform a single-pass audit; child-agent delegation and background iteration loops are strictly forbidden. Hosts capable of enforcing tool/turn budgets should apply them.
   - **15-Line Synthesis**: Output is capped at a 15-line Pass/Fail matrix with file/line references for missing edge cases.
   - **Targeted Verifier Scope**: Input is strictly bounded to the target Acceptance Criteria, fixed-point diff, and test commands; returns a concise synthesis, preventing expensive multi-turn downstream debugging.

---

## Socratic Debrief & Next Steps
1. Guide the author on resolving `🚨 [BLOCKING]` items first.
2. Confirm all fixes pass the Quality Gate in `.promptkit/protocols/code-quality-gate.md`.

---

## Completion Criteria
- Dual-axis evaluation completed (Spec Fidelity vs. Technical Standards).
- Durable report saved to `docs/reviews/<review-slug>.md` with a `REVIEW-<review-slug>` anchor.
- Zero unaddressed `🚨 [BLOCKING]` data loss or security issues.
- All code smells linked to actionable refactoring remedies.
- Verification tests pass against `.promptkit/protocols/code-quality-gate.md`.


---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
