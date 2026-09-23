# Task Breakdown & Acceptance Criteria Workflow

## Fast Shorthand
Trigger anytime with: `pk:tasks` (or `/pk-tasks`, `pk:issue`, `pk:kanban`, `pk:task`)

## Mission
Transform architectural specifications (`pk:plan`), technical RFCs (`docs/specs/`), or user feature requests into atomic, single-responsibility tasks with strict Acceptance Criteria (Gherkin format + checklists), technical invariant locking, priority tagging (`#priority/p0-p3`), and traceability to the configured tracking system — GitHub Issues (copy-pasteable `gh issue create` commands, Projects v2 Kanban) or manual import for Linear, Jira, or Local Markdown.

Bridge the critical operational gap between high-level architectural design and hands-on coding. Prevent scope creep, untracked work, and forgotten edge cases before any code is written.

---

## Core Principle: No Acceptance Criteria, No Active Coding
An issue is only ready for implementation when its completion can be objectively proven through automated tests and explicit behavioral assertions. Vague tasks ("Build checkout page") are strictly forbidden.

---

## Preconditions
- A technical RFC spec exists in `docs/specs/`, or a concrete feature request has been described.
- Target architectural boundaries and data models are understood (via `pk:plan` or domain specs).

---

## 4-Phase Task Breakdown Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                     PK:TASKS LIFECYCLE                      │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Phase 1:     │ Phase 2:     │ Phase 3:     │ Phase 4:       │
│ Spec Triage  │ Atomic Task  │ AC & Invariant│ Local Storage │
│ & Boundaries │ Breakdown    │ Formulation  │ & Kanban Sync  │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

### Phase 1: Spec Triage & Scope Boundary

1. **Locate Source Requirements**:
   - Inspect `docs/specs/` for the latest technical specification.
   - If no spec exists, ask the user or run `pk:plan` first for substantive features.
2. **Define Phasing Strategy**:
   - **Code Work, including Full-Stack or Multi-Layer Features**: First read the canonical Local Task Record's `TDD Enforcement Mode`. When it is `enabled`, order the work as Red -> Green -> Refactor with a stable Behavior ID and linked execution evidence. When it is `disabled`, use normal dependency-ordered milestones covering contracts or seams, implementation, presentation or integration as applicable, hardening, acceptance, test strategy, review, and verification. Do not require a Red-Green-Refactor chain in the disabled branch.
   - **Documentation, Configuration, and Research Work**: Use an exception verification path with explicit acceptance, evidence, review, and verification rather than Code Work TDD milestones.
   - **Ambiguous Work**: Follow the Code Work path until the work type and TDD mode are clarified in the Task Record.
   - **Localized Code Work**: Use an adaptive flat list ordered strictly by dependency (Task 1 -> Task 2 -> Task 3), applying the same enabled or disabled TDD branch.
3. **Inspect Task Tracking Strategy**:
    - Check `PROMPTKIT.md` Section 5 (`Task Tracking System` + machine `tracking:` line).
    - If set to `GitHub Issues`: In Phase 4, invoke `github-mcp-server` tool calls or generate `gh issue create` CLI commands, and link assigned issue numbers (`#N`) into `docs/STATE.md`.
    - If set to `Linear` or `Jira`: In Phase 4, format tasks matching the external tracker's schema for manual import / copy-paste. No auto-push. State explicitly in output: `Jira/Linear: manual import, no auto-push — board is projection only, Local Task Record authoritative.`
    - If set to `Local Markdown` (the default) or unspecified: Maintain task records locally in `docs/tasks/` and `docs/STATE.md` without requiring external credentials or network access.

### Controlled & Release-Critical Work Execution Overlay

When Phase 1 classifies work as Level 2 (Controlled) or Level 3 (Release-Critical) Work, create the canonical Local Task Source at `docs/tasks/<task-id>.md` before active coding. Level 0 (Direct) and Level 1 (Standard) work modify source files directly or with inline planning without requiring a formal Task Record file:

- Assign a stable `Task ID` and create `docs/tasks/<task-id>.md` from the execution task-record template.
- Consume the canonical Planning Record produced by `pk:plan`. In Minimal mode, map requested outcome to `Objective`, observable completion condition to `Acceptance Criteria` and `Verification Condition`, and scope boundary to `In Scope` and `Explicit Non-Goals`.
- Treat Minimal Planning as a question limit only. Populate every existing Local Task Record readiness field; use concrete `None` or `N/A - <reason>` explanations where a field is genuinely not applicable. A Minimal Planning Record alone does not make the task ready.
- Reject or escalate a Minimal request when a Full trigger applies: public/external contract, persistent data, auth/authorization, external integration, release configuration or risk, multiple components, serious safety/rollback/data-loss risk, or explicit architecture planning. Full planning must complete before task decomposition continues.
- Carry forward the objective, in-scope files/work, explicit non-goals, dependencies or `None`, owner/approval boundary, risk, verification condition, and execution policy. Any unanswered required planning input must link to its owned Assumption Record; an assumption is not a confirmed decision.
- Give every acceptance condition a stable `AC-*` identifier and link it to the issue-facing Gherkin scenario or checklist result.
- Keep external GitHub/Jira/Linear references optional. A dated breakdown document or external issue may index the work, but the per-task Local Task Record remains authoritative for L1-L3 Work.
- Do not move the record to `in_progress` until readiness is complete, the start time and execution scope are recorded, and the active-task pointer is owned by exactly one task in the current scope.
- If the task expands its objective, files, acceptance criteria, dependencies, non-goals, risk, or verification, create a Scope Change Record before implementation. Independent discoveries become separate Task Records.

### Task Record TDD Enforcement Contract

The canonical Local Task Record owns the separate fields `Work Type: Code Work | Documentation Work | Configuration Work | Research Work` and `TDD Enforcement Mode: disabled | enabled`. An absent TDD field is interpreted as `disabled` for legacy records. Ambiguous Work Type follows Code Work until clarified. Do not overload the existing execution-policy field `Mode: Gated Mode`; `Mode` continues to control execution authorization and batch policy.

- A planning record or test plan may contain a `TDD Enforcement Mode` proposal/reference and TDD intent entries, but those values do not activate TDD or control task state.
- If planning, test-plan, and Task Record values disagree, readiness is blocked until the disagreement is reconciled. After reconciliation, the Task Record value is authoritative.
- For Code Work with `enabled`, create Red -> Green -> Refactor milestones. Keep one `BEHAVIOR-<task-slug>-<nnn>` identity through the `TDD-INTENT-<task-slug>-<nnn>` intent and `TDD-EXEC-<task-slug>-<behavior-seq>` execution evidence. Red records the expected failing assertion and runnable command; Green and Refactor retain that same behavior identity.
- For Code Work with `disabled`, create complete dependency-ordered milestones with acceptance criteria, test strategy, review, and verification. Red-Green-Refactor evidence is not mandatory.
- Documentation, Configuration, and Research Work use an exception verification path with an explicit reason and evidence link. They do not acquire hidden TDD requirements.
- Ambiguous work follows the Code Work path until the Task Record clarifies the work type and mode.

### TDD Milestone and Evidence Handoff

After the Task Record is ready, `pk:tasks` decomposes the work from the authoritative TDD mode without changing execution state or creating a second authority:

| Task Record branch | Task decomposition | Required evidence handoff |
| :--- | :--- | :--- |
| Code Work with `enabled` | Red -> Green -> Refactor milestones for each stable Behavior ID | `pk:test` intent link plus Local Task Record `TDD-EXEC` results using the same Behavior ID and Red command |
| Code Work with `disabled` | Complete dependency-ordered milestones for contracts or seams, implementation, integration, hardening, acceptance, test strategy, review, and verification | TDD intent register and TDD execution evidence are each `N/A - TDD Enforcement Mode disabled`; normal milestone evidence remains required |
| Documentation, Configuration, or Research Work | Exception verification task with explicit acceptance, evidence, review, and verification | TDD fields are `N/A - exception work type`; link the exception verification and reason |
| Ambiguous Work | Follow the Code Work path until Work Type and TDD mode are clarified | No automatic TDD exception; readiness remains blocked or follows the clarified Code Work branch |

For enabled Code Work, the Red milestone records the expected failing assertion and exact runnable command from the test plan. Green and Refactor retain the same Behavior ID, rerun the same Red command, and cannot silently change the acceptance condition. `pk:tasks` creates the milestone order and evidence links, but only the Local Task Record records execution results and controls readiness or completion. One behavior does not require three separate issues.

The execution states `planned`, `ready`, `in_progress`, `checkpoint_due`, `blocked`, `paused`, `handoff_ready`, `awaiting_review`, `completed`, and `aborted` map onto the existing Kanban statuses without replacing them:

| Execution states | Existing Kanban status |
| :--- | :--- |
| `planned`, `ready`, `aborted` | `To Do` |
| `in_progress`, `checkpoint_due`, `blocked`, `paused`, `handoff_ready` | `In Progress` |
| `awaiting_review` | `In Review` |
| `completed` | `Done` |

The Task Record, not a conversational completion claim or board status alone, controls readiness and completion.

---

### Phase 2: Atomic Task Decomposition & Sizing

1. **Prefer the 1-to-4 Hour Task Size**:
    - Prefer atomic tasks completable in roughly 1 to 4 hours. If a task materially exceeds that range, split it where meaningful; if splitting would create artificial boundaries, document the reason instead of splitting.
2. **Assign Priority Tags**:
   - `#priority/p0`: Blocker or critical path (data migrations, core security, authentication).
   - `#priority/p1`: High priority / core user flow.
   - `#priority/p2`: Medium priority / edge cases, enhancements, optimizations.
   - `#priority/p3`: Polish / nice-to-have, secondary styling adjustments.
3. **Assign Area & Type Labels**:
   - Component Area: `area:data`, `area:backend`, `area:frontend`, `area:auth`, `area:ui`, `area:perf`.
   - Issue Type: `type:feature`, `type:bug`, `type:refactor`, `type:test`.

---

### Phase 3: Acceptance Criteria & Invariant Formulation

For each decomposed task, fill out `.promptkit/templates/issue-task-template.md`:

1. **User Story / Intent**:
   - State the actor, capability, and value: `As a <user>, I want <action> so that <value>`.
2. **Technical Scope & Invariants**:
    - Exact files, endpoints, and database tables touched.
    - Applicable technical invariants identified by the planning/specification process (e.g. tenant isolation, Expand-Contract schema safety, input validation schemas, performance budgets) — include only what applies; record the rest as `N/A - <reason>`.
    - Explicit "Out of Scope" declaration to prevent mid-flight scope creep.
3. **Verifiable Acceptance Criteria**:
    - **Happy Path (Gherkin)**: `Given <context>, When <action>, Then <outcome>`.
    - **Negative & Error Path**: Explicit assertions for the task's interface-appropriate failure paths (e.g. for HTTP APIs: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 409 Conflict, or 429 Rate Limit).
   - **Boundary Conditions**: Empty states, maximum payload boundaries, concurrent double-submit guards.
4. **Automated Verification Command**:
   - Provide the exact test runner command that validates the criteria (e.g., `pnpm test path/to/feature.test.ts`).

---

### Phase 4: Local Storage & Tracker Sync (GitHub steps below are the GitHub adapter)

1. **Persist the Canonical Local Source of Truth**:
   - For each L1-L3 Work unit, create one canonical Task Record at `docs/tasks/<task-id>.md` from `.promptkit/templates/execution-task-record-template.md`.
   - A dated breakdown document may index the per-task records, but it cannot replace them or become a second lifecycle authority.
   - This provides offline resilience and protects against agent context compaction (`pk:checkpoint`).
2. **Provision Standard GitHub Labels & Issue Template**:
   - Repositories can provision the standardized labels (`priority/p0-p3`, `type:*`, `area:*`) with zero token overhead by running the local provisioning script:
     - PowerShell: `pwsh -NoProfile -File .promptkit/scripts/setup-github-labels.ps1`
     - Bash: `bash .promptkit/scripts/setup-github-labels.sh`
   - PromptKit OS automatically scaffolds `.github/ISSUE_TEMPLATE/task.md` during `init.ps1` / `init.sh` so human contributors and agents have a consistent Gherkin structure when opening issues directly on GitHub.
3. **Generate GitHub CLI (`gh issue create`) Commands or Invoke MCP Tools**:
   - When `Task Tracking System` in `PROMPTKIT.md` is set to `GitHub Issues` (or if requested by the user), create issues via native MCP (`github-mcp-server`) or append ready-to-run CLI commands at the bottom of an index or issue document. External issues may coordinate work but must link to the canonical Task Record and never replace it:
     ```bash
     gh issue create \
       --title "feat(cart): implement server-side discount validation" \
       --body-file docs/tasks/issue-01-discount-validation.md \
       --label "type:feature,priority/p1,area:backend" \
       --milestone "M2: Core Domain Logic"
     ```
4. **GitHub Projects v2 & Kanban Sync (Optional)**:
   - If using GitHub Projects v2, link each created issue to your project board:
     ```bash
     gh project item-add <project-number> --owner <owner> --url <issue-url>
     ```
   - Track progress through standard Kanban status lanes:
     `To Do` -> `In Progress` -> `In Review` -> `Done`
   - Treat board status as a mapping from the Task Record execution state, not as a replacement for the record.
   - For local Obsidian Kanban users, format cards matching the `kanban-project-planner` conventions:
     - `## To Do`: `- [ ] <Task description> #priority/pX`
     - `## In Progress`: `- [/] <Task description> #priority/pX`
     - `## Done`: `- [x] <Task description> #priority/pX ✅ YYYY-MM-DD`
5. **Living State Projection Sync (`docs/STATE.md`)**:
   - If `./docs/STATE.md` exists, update Section 2 (`Milestone & Task Progress`) with the newly decomposed tasks (`- [ ] TASK-XX: ...`).
   - Contribute links to the generated task spec in `docs/tasks/` to Section 3 (`Active Working Set`) without rewriting other Section 3 content.
   - `docs/STATE.md` is a synchronized projection owned by `pk:checkpoint` (see State Mutation Contract in `workflows/checkpoint.md`); the canonical `docs/tasks/<task-id>.md` Task Record remains authoritative. If no state file exists, offer to scaffold it from `templates/state-tracker-template.md`.

### Engineer Handoff

Before implementation, the Engineer validates the Task ID, scope, acceptance criteria, revision context, blockers, invariants, and exactly one prioritized next action. The Engineer also confirms the Task Record's `TDD Enforcement Mode`, checks that any planning or test-plan proposal agrees with it, and follows the enabled, disabled, or exception path recorded there. Scope expansion requires a Scope Change Record before changing the objective, files, acceptance criteria, dependencies, non-goals, risk, or verification condition.

---

## Completion Criteria
- Tasks decomposed into preferentially 1-to-4 hour atomic units (exceptions documented with reason) with priority tags (`p0`-`p3`).
- Every task includes non-negotiable technical invariants and out-of-scope boundaries.
- Every task includes both happy path and negative/edge-case Acceptance Criteria.
- Automated verification commands provided for every testable task.
- Tasks document saved to `docs/tasks/` with copy-pasteable `gh issue create` commands.
- Living tracker in `docs/STATE.md` updated with the active milestone tasks (if present).
- **Dual-Compatible Telemetry Status Card**: Conclude with the single 3-line blockquote spec (`> 📊 **Milestone**: <name> [■■■■□□] n/m — source: STATE.md read this turn \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: measured this turn / not measured`) and a `> [!TIP]` callout recommending `pk:test` or implementing the first task. When multiple next steps exist, invoke native interactive selection tools (e.g. `ask_question`) as your final tool call with Option 1 `(Recommended + why)` so the developer can navigate with arrow keys and confirm with `Enter`. If PROMPTKIT.md declares `status-cards: off`, skip the decorative card; `[!IMPORTANT]` / `[!WARNING]` halts still fire.
