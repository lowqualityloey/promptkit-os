# Reflect Workflow (AI Senior Engineering Retrospective)

## Fast Shorthand
Trigger anytime with: `pk:retro` or `pk:reflect` (or `/pk-retro`)

## Mission
Facilitate a deep, high-impact Engineering Retrospective following a development or study block. Transform raw coding sessions into structured insights, Architectural Decision Records (ADRs), Root Cause Analyses (RCAs), and measurable skill matrix advancements.

---

## Retrospective Dimensions

```
   ┌─────────────────────────────────────────────────────────────┐
   │             ENGINEERING RETROSPECTIVE MATRIX                │
   ├──────────────────────────────┬──────────────────────────────┤
   │ 1. Mental Model Shift        │ 2. Architectural Trade-offs  │
   │    What misconception was    │    What alternatives were    │
   │    corrected?                │    considered & why rejected?│
   ├──────────────────────────────┼──────────────────────────────┤
   │ 3. Failure Mode & RCA        │ 4. Competency Advancement    │
   │    What broke, why did it    │    Which skill level was     │
   │    break, & how to prevent?  │    unlocked or reinforced?   │
   └──────────────────────────────┴──────────────────────────────┘
```

---

## Preconditions
- Developer has completed a coding block, spike, debugging session, or architectural milestone.
- Access to `.promptkit/notes/progress-journal.md`, `.promptkit/notes/learning-plan.md`, and `.promptkit/notes/skill-matrix.md`.
- Git repository available to analyze diffs and recent commit logs.

---

## Workflow Steps

### Step 1: Git Diff & Activity Synthesis
1. Run `git status` and `git diff --stat` (or `git log -n 3 -p` if committed) to review code touched during the session.
2. Group changes into engineering categories:
   - **Architecture & Interfaces**: New contracts, domain models, or schemas.
   - **Business Logic & Services**: Core algorithms, mutations, or handlers.
   - **UI & Accessibility**: Components, styling, design tokens, ARIA attributes.
   - **Testing & Tooling**: Unit/integration tests, configs, CI pipelines.
   - **Fixes & Optimizations**: Bug fixes, query tuning, bundle size reductions.
3. Present a crisp 3-bullet snapshot of what was built or refactored.

### Step 2: Socratic Retrospective Inquiry
Prompt the developer with 3-4 targeted reflective questions:
1. **Mental Model**: *"What assumption did you have before this session that changed during implementation?"*
2. **Trade-Offs**: *"What trade-offs (e.g., speed vs. flexibility, memory vs. compute, simplicity vs. extensibility) did you make in your solution?"*
3. **Resilience & Edge Cases**: *"Where is the weakest point in this implementation under extreme load, network failure, or corrupted input?"*
4. **Tooling / DX**: *"What slowed you down during this session, and how can tooling or automation eliminate that friction next time?"*

### Step 3: Extract Architectural Decisions (ADR Check)
Evaluate whether significant architectural or technology choices were made:
- Examples: Choosing an ORM, selecting a state management library, structuring server/client boundaries, defining an authentication strategy, introducing a caching layer.
- If a significant decision occurred:
  1. Recommend drafting an ADR in the project's `./docs/adrs/` folder.
  2. Use `.promptkit/templates/adr-template.md` to scaffold `./docs/adrs/YYYY-MM-DD-<decision-title>.md`.
  3. Assist the developer in documenting Context, Decision, Consequences, and Alternatives Considered.

### Step 4: Extract Bug Root Cause Analysis (RCA Check)
If the session involved debugging a critical defect, race condition, or production issue:
- Guide the developer through the **5 Whys**:
  - Why did the error manifest?
  - Why was the invariant violated?
  - Why was it not caught by static types or unit tests?
  - Why did our testing fixture miss this state?
  - Why was the failure mode possible in our system design?
- Record the preventative action item in `./docs/rca/` (e.g., new lint rule, integration test, or schema constraint).

### Step 5: Update Progress Journal
Draft a rich, tagged entry for `.promptkit/notes/progress-journal.md`:

```markdown
| Date | Focus / Challenge | Key Architectural Insights & Mental Models | Trade-Offs & Decisions | Next High-Leverage Action | Tags |
| :--- | :--- | :--- | :--- | :--- | :--- |
| YYYY-MM-DD | [Component or Feature] | - [Insight 1]<br>- [Insight 2] | - [Decision and rationale] | - [Concrete next step] | `#tag1` `#tag2` |
```

Review the draft with the developer, make adjustments, and append it to the table in `.promptkit/notes/progress-journal.md`.

### Step 6: Advance the Skill Competency Matrix
1. Open `.promptkit/notes/skill-matrix.md`.
2. Check off or advance competencies demonstrated during the session (e.g., TypeScript Generics, State Machine Design, Database Indexing, WCAG 2.2 a11y, Clean Architecture).
3. Align upcoming tasks in `.promptkit/notes/learning-plan.md` to target the next tier in the skill matrix.

> **Kit contributors**: also identify which L1→L4 skill dimension(s) in the kit's [`notes/skill-matrix.md`](../notes/skill-matrix.md) this session exercised, and prompt the developer to update the relevant matrix row so the matrix stays a living record.

### Step 7: Close the Loop & Recommend Next Action
Summarize next steps:
- Run `pk:plan` to design the next feature.
- Run `pk:review` on uncommitted code before opening a PR.
- Take a deliberate break to allow cognitive consolidation.

---

## Completion Criteria
- `.promptkit/notes/progress-journal.md` is updated with a high-fidelity retro entry.
- Major architectural decisions are documented as ADRs under `./docs/adrs/`.
- `.promptkit/notes/learning-plan.md` and `.promptkit/notes/skill-matrix.md` reflect current progress and upcoming goals.
- Developer has clear clarity on their next engineering spike or milestone.