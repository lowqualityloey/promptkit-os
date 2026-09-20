# Issue Task Template

## Title
<!-- Format: <type>(<scope>): <concise summary under 72 chars> -->
<!-- Examples: feat(auth): add session revocation endpoint, fix(cart): prevent double submission on checkout -->

### Metadata
- **Related Spec**: `docs/specs/`
- **Architectural Decision (ADR)**: `docs/adrs/`
- **Milestone**: `[M1: Data & Contracts | M2: Core Logic | M3: UI & Presentation | M4: Hardening]`
- **Priority**: `[#priority/p0 (Blocker) | #priority/p1 (Core) | #priority/p2 (Enhancement) | #priority/p3 (Polish)]`
- **Labels**: `[area:backend, area:frontend, area:data, area:auth, area:ui, area:perf]`
- **Kanban Status**: `[To Do | In Progress | In Review | Done]`

---

## User Story & Context
<!-- Describe who benefits, what capability is unlocked, and why now. -->
**As a** `[user role or persona]`  
**I want** `[action or capability]`  
**So that** `[measurable business or technical value]`

---

## Public PromptKit Contract Impact (Optional)

> Complete this section when planning a material change to PromptKit OS's own workflow, template, protocol, trigger, documented output, required artifact, or documented behavior. It is optional for ordinary task records and does not impose PromptKit OS versioning or release policy on consumer repositories.

- **Affected Public PromptKit Contract**: `[workflow, template, protocol, trigger, output schema, required artifact, or documented behavior]`
- **Contract Impact Evidence ID / Path**: `[evidence ID and record path, or N/A]`
- **Supporting Planning / Review Record**: `[record path or N/A]`
- **User-Observable Before Behavior**: `[what the user or maintainer observes before the change]`
- **User-Observable After Behavior**: `[what the user or maintainer observes after the change]`
- **Impact Classification**: `[User-Facing Additive Contract Change | User-Facing Corrective Contract Change | Breaking Contract Change | Maintenance Commit]`
- **Proposed SemVer Candidate Impact**: `[major | minor | patch | none | blocked]`
- **Impact Rationale**: `[why the proposed impact follows observable contract evidence, not a commit label alone]`
- **Migration and Upgrade Guidance**: `[Required for breaking changes: affected consumers, required actions, and supported transition path. Record Missing and a blocker until complete. Use N/A for non-breaking or maintenance changes.]`
- **Maintenance Commit Declaration**: `[Required when Maintenance Commit: This change has no intentional Public PromptKit Contract change and proposes no SemVer increment. Otherwise N/A.]`

---

## Technical Scope & Invariants

### Files & Endpoints Touched
- **Database Tables / Migrations**: `[path/to/schema.ts or migrations/]`
- **Services / Handlers**: `[path/to/service.ts]`
- **API Endpoints**: `[METHOD /api/v1/path]`
- **UI Components**: `[path/to/component.tsx]`

### Non-Negotiable Invariants (mark applicable items; use `N/A - <reason>` where not applicable)
- [ ] **Data Isolation** (when multi-tenant or persistent data exists): Tenant Row-Level Security (RLS) or organization ID enforced on every query; otherwise `N/A - <reason>`.
- [ ] **Schema Safety** (when schema or migration exists): Expand-Contract pattern followed for live or compatibility-sensitive data — one-shot, disposable, or pre-deployment changes may skip with documented rationale; otherwise `N/A - <reason>` and zero instantaneous destructive drops when EC applies.
- [ ] **Security & Validation** (when external input exists): Runtime schema validation using the project's native mechanism (e.g. Zod/Valibot for TypeScript) applied to all external input; otherwise `N/A - <reason>`.
- [ ] **Budget & Performance** (when API or data path exists): No N+1 query loops; API response p95 within target SLA; otherwise `N/A - <reason>`.

### Out of Scope
<!-- Explicitly list what this issue will NOT address to prevent scope creep. -->
- `[Feature or boundary excluded from this specific issue]`

---

## Controlled Work Execution (Optional)

> Complete this section when the request is Controlled Work. Trivial Work may use the existing issue flow unless it expands into Controlled Work. The Local Task Record under `docs/tasks/` is authoritative; GitHub or another external tracker is an optional reference only.

- **Work Classification**: `[Trivial | Controlled]`
- **Task ID**: `TASK-[YYYY-MM-DD]-[slug]`
- **Local Task Record**: `docs/tasks/<task-id>.md`
- **Specification**: `docs/specs/[specification].md`
- **Execution Scope**: `[Repository, workspace, package, or session boundary]`
- **Owner / Actor**: `[Person, role, or agent]`
- **Approval Boundary**: `[Actions requiring explicit human confirmation]`
- **Dependencies**: `[Dependency and owner, or None]`
- **Execution Policy**: `[Gated Mode | Approved Batch Mode]`
- **Checkpoint Policy**: `[Soft/hard intervals, event triggers, and host timer limitation]`
- **Stop Conditions**: `[Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop]`
- **Execution State**: `[Reference to the Local Task Record; planned | ready | in_progress | checkpoint_due | blocked | paused | handoff_ready | awaiting_review | completed | aborted]`
- **Mapped `pk:tasks` Status**: `[To Do | In Progress | In Review | Done]`
- **Active Task Pointer**: `[Task ID while active, otherwise None]`
- **Checkpoint / Handoff / Scope Change Links**: `[Record paths or None]`
- **Next Action**: `[Exactly one prioritized action]`

Acceptance Criteria in this issue should use stable IDs such as `AC-1` and link to the corresponding results in the Local Task Record. Do not mark Controlled Work complete from the issue alone; completion requires the record's acceptance, verification, changed-file, and commit/PR evidence or an explicit documented exception.

---

## Implementation Tasks (The Build)
<!-- Concrete, ordered sequence of files and functions to create or modify. -->
- [ ] 1. Define schema types and database migration (`Expand` phase) where persistent storage exists; otherwise `N/A - <reason>`.
- [ ] 2. Implement domain service logic and state validation.
- [ ] 3. Expose API endpoint with structured error envelope (or interface-appropriate contract).
- [ ] 4. Wire client query hook and presentation component (or interface-appropriate surface).
- [ ] 5. Write automated unit and integration tests.

---

## Acceptance Criteria (The Verifiable Proof)
<!-- Concrete conditions of satisfaction. All must pass before this issue can be closed. -->

### Scenario 1: Happy Path
- **Given** `[precondition or system state]`
- **When** `[action taken or event triggered]`
- **Then** `[expected outcome or response status]`

### Scenario 2: Negative & Error Edge Cases
- **Given** `[unauthenticated user or invalid payload]`
- **When** `[request is dispatched]`
- **Then** `[expected error (e.g. for HTTP APIs: 400, 401, 403, 409, 429) or interface-appropriate error and structured message]`

### Scenario 3: Boundary & Concurrency (If Applicable)
- **Given** `[duplicate concurrent requests with same idempotency key]`
- **When** `[processed simultaneously]`
- **Then** `[only one transaction succeeds without data corruption]`

---

## Automated Verification Command
<!-- Paste the exact CLI command used to prove this issue meets acceptance criteria. -->
```bash
# Run the specific test suite covering this issue
pnpm test path/to/feature.test.ts
```

---

## GitHub CLI Recipe
<!-- Copy-pasteable command to publish this issue directly from your terminal. -->
```bash
gh issue create \
  --title "<type>(<scope>): <summary>" \
  --body-file docs/tasks/<issue-slug>.md \
  --label "area:<component>,priority:<p0-p3>" \
  --milestone "<Milestone Name>"
```
