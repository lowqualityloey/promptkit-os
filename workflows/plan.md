# Plan Workflow (Spec-Driven Architecture & Feature Planning)

## Fast Shorthand
Trigger anytime with: `pk:plan` (or `/pk-plan`)

## Mission
Guide the developer through **Spec-Driven Development (SDD)**, robust architectural planning, and zero-downtime system design before writing production code.

Transform ambiguous product or technical requirements into clear technical specifications, deep modular architectures, strict interface contracts, empirical failure mode analyses (FMEA), zero-downtime database evolution plans, and implementation milestones selected by the canonical Local Task Record's TDD Enforcement Mode.

---

## Architectural Principles to Enforce

### 1. Deep Modules vs. Shallow Wrappers
- **Deep Modules**: The best abstractions provide substantial functionality behind a clean, deceptively simple interface (e.g., standard file I/O, garbage collectors, or a cohesive domain engine).
- **Avoid Shallow Pass-Throughs**: Beware of controllers that simply call a service that simply calls a repository with identical method signatures. This scatters complexity without adding leverage.
- **The Deletion Test**: Before creating an abstraction, ask:
  > *"If we delete this module, does it concentrate complexity into a single coherent place, or does it merely move boilerplate around?"* If it just moves it, inline it.
- **The Interface is the Test Surface**: Design seams where tests can assert real business outcomes through public APIs rather than brittle private mocks.

### 2. Zero-Downtime Schema Evolution (Expand-Contract Pattern)
> [!CAUTION]
> **Accidental Data Loss & Downtime Prevention**: Never plan destructive migrations (`DROP COLUMN`, `DROP TABLE`, table renames) as single instantaneous changes.
>
> All schema modifications must plan for the **Expand-Contract (Parallel Run)** lifecycle:
> 1. **Expand**: Add new columns/tables as nullable or with defaults. Dual-write to old and new schemas.
> 2. **Backfill & Read**: Migrate historical records in asynchronous batches; switch application read paths to the new schema.
> 3. **Contract**: Remove dual-write logic; deprecate and safely drop old columns only after zero running services reference them.

---

## The Spec-Driven Engineering Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                   SPEC-DRIVEN ARCHITECTURE PLAN                  │
├──────────────────────────────────┬───────────────────────────────┤
│ 1. Problem & Non-Goals           │ 2. System Context & Flow      │
│    Scope boundary, metrics, YAGNI│    Deep modules, test surfaces│
├──────────────────────────────────┼───────────────────────────────┤
│ 3. Data Contracts & Evolution    │ 4. FMEA Failure Analysis      │
│    Types, Expand-Contract schema │    Threats, race guards, DLQs │
├──────────────────────────────────┼───────────────────────────────┤
│ 5. Conditional Milestones         │ 6. Spec Artifact & Grilling   │
│    Task Record mode branch        │   docs/specs/ + pk:grill prep │
└──────────────────────────────────┴───────────────────────────────┘
```

## PromptKit Adaptation Compatibility Note

For the PromptKit SDLC Adaptation, `pk:route` classifies work into the canonical 4-level task ceremony model (Level 0 Direct, Level 1 Standard, Level 2 Controlled, Level 3 Release-Critical) before selecting planning depth:

- **Level 0 (Direct / Trivial Work)**: Direct fast-path execution. No formal planning or Task Record required.
- **Level 1 (Standard / Lightweight Work)**: Localized bug fixes or small self-contained features. Uses lightweight inline planning without requiring a formal Task Record file (`docs/tasks/<task-id>.md`).
- **Level 2 (Controlled Work)**: Schema migrations, auth, permissions, breaking API contracts, or multi-component architectural risks. Requires `Minimal` or `Full` planning depth and the canonical Local Task Record at `docs/tasks/<task-id>.md`.
- **Level 3 (Release-Critical Work)**: Releases, deployments, tag generation, or high-impact contract changes. Requires Level 2 planning and Task Record readiness plus release candidate evaluation (`pk:ship`), QA review, and human Release Coordinator authorization.

The planner maps Minimal or Full results into existing architecture, contract, migration, FMEA, milestone, and task inputs. Planning supplies inputs; it does not change execution state or approve implementation, commits, pull requests, releases, deployment, or rollback. Existing workflow ownership and approval boundaries remain authoritative; the shared matrix is maintained in [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md).

### Planning Depth and Assumption Branch

After `pk:route` classifies the request into Levels 0–3:

1. **Level 0 (Direct / Trivial Work):** Direct execution (`understand → change → verify`). Do not create a Planning Record, Assumption Record, or Adaptation artifact.
2. **Level 1 (Standard / Lightweight Work):** Lightweight inline planning only (outcome, completion condition, scope boundary) directly in conversation or `docs/STATE.md`. Do NOT create or populate `docs/tasks/<task-id>.md`.
3. **Level 2 (Controlled Work):** Requires canonical Local Task Record readiness at `docs/tasks/<task-id>.md`. Select `Minimal` or `Full` planning depth:
   - **Minimal Planning (Level 2 default):** Record only requested outcome, observable completion condition, and scope boundary. Map them into the canonical Task Record at `docs/tasks/<task-id>.md` via `pk:tasks`, then stop the planning interrogation without continuing into the full RFC.
   - **Full Planning (Level 2 triggering work):** Record requested outcome, explicit non-goals, affected Behavioral Components, externally visible contracts, failure/rollback considerations, and verification approach. Continue through the full RFC architecture, contracts, Expand-Contract migrations, FMEA matrix, milestones, and grilling steps.
4. **Level 3 (Release-Critical Work):** Requires Level 2 planning and Task Record readiness (`docs/tasks/<task-id>.md`), plus release-critical provenance, candidate evaluation (`pk:ship`), QA review, and explicit human Release Coordinator authorization.
5. **Level 2–3 Missing Inputs:** For Level 2 or Level 3 Work, if a required planning input is unanswered, add an Assumption Record in the same Planning Record before implementation inputs are handed to `pk:tasks`. The assumption remains provisional and includes an owner, impact, validation action, and status.
6. **Question Retention:** Do not ask a completed planning question again unless scope changes, an assumption is invalidated, or new evidence changes the decision. Record the changed scope, assumption, or evidence when re-interrogation is necessary.

### Mandatory Full Planning Triggers

A lightweight request cannot override Full Planning when the work affects public or external contracts, persistent data or schema, authentication or authorization, external integrations, release configuration or release risk, multiple Behavioral Components, serious safety/rollback/data-loss risk, or an explicitly requested architecture plan. These triggers select planning depth only; they do not create a new route or execution class.

### Source-Grounded Technology and Vendor Decisions

Create Decision, Material Claim, Citation, and Uncertainty records only for a material Technology or Vendor Decision. A decision is material when the work adopts, replaces, configures, versions, or materially depends on an external technology, service, platform, framework, library, or managed service and the decision affects compatibility, security behavior, supported limits, pricing, availability, lifecycle, or integration behavior.

- A technology mention that does not change a material decision does not require a Decision Record, source research, or a new planning question. For example, naming an existing database in an architecture description is not a decision by itself.
- Record the decision statement, considered options, selected option, rejected options, Material Claim links, remaining uncertainty, decision owner, and status in the existing Planning Record. Use the canonical `DECISION-<spec-slug>-<nnn>`, `CLAIM-<decision-id>-<nnn>`, `CITATION-<decision-id>-<nnn>`, and `UNCERTAINTY-<decision-id>-<nnn>` identities and same-file links defined by `docs/WORKFLOW-MAP.md`.
- Record only claims that affect the decision. Every Material Claim must link to a Citation Record or an Uncertainty Record; do not present unsupported prose as a verified fact.
- Use primary documentation controlled by the technology, vendor, standards body, or owning project where available. A Citation Record must identify the publisher, document title, canonical URL, access date, and supported Material Claim.
- **MCP Accelerator Note (Optional)**: If active, the `fetch` or doc-reader MCP server can be used to pull current primary documentation into context without search bloat, and `sequentialthinking` can be invoked to systematically evaluate architectural tradeoffs, failure modes, and migration branches before drafting specs.
- If primary documentation is unavailable, inaccessible, stale, or conflicting, do not mark the affected claim verified. Choose only one of these dispositions: defer the decision, run a targeted `pk:spike`, or proceed with an explicitly accepted assumption owned by a named decision maker. Record the impact, resolution action, owner, and status in an Uncertainty Record.
- `pk:spike` owns investigation method and comparison depth. The Planning Record owns the decision provenance and links to any spike or downstream ADR; neither a spike nor an ADR replaces the Planning Record decision record.
- Do not perform automatic web research. Research is targeted to material decisions and must not add ceremony to Trivial Work or incidental technology mentions.

#### Version Selection Policy

For a material decision that includes a technology version:

1. For greenfield work with no existing pin, user preference, or explicit constraint, recommend the latest supported stable version compatible with project constraints. "Latest" means latest supported stable compatible release, not the newest available release regardless of channel or compatibility.
2. Treat production-stable, actively supported or LTS releases as the default where applicable. Never default to prerelease, nightly, experimental, or unsupported channels.
3. For an existing project, preserve current pinned versions. Do not silently upgrade; upgrade only after an explicit request or recorded security, support/lifecycle, compatibility, or other material evidence, with migration and rollback impact recorded when relevant.
4. Require an explicit rationale, named decision owner, and support/lifecycle and compatibility evidence for an older version. Record uncertainty when evidence is incomplete, stale, inaccessible, or conflicting.
5. Record the exact selected version or versions, release channel, support/lifecycle status, compatibility constraints, rationale, citations, citation access date, and exact-version evidence. Do not record `latest` or an unbounded range as the selected version.
6. Treat AI or PromptKit output as a recommendation only. The named decision owner approves the recommendation, approves a deviation, or accepts the documented assumption. User preference and project constraints may override the default when recorded.
7. When evidence is unclear or conflicting, defer, run a targeted `pk:spike`, or proceed only with an explicitly accepted assumption; do not guess.

### Minimal-to-Controlled Readiness Mapping

Minimal planning limits questions, not Controlled Work readiness. `pk:tasks` must still populate every existing Local Task Record readiness field with a concrete value or an explicit `None`/`N/A - <reason>` explanation where applicable:

| Minimal planning input | Local Task Record contribution |
|---|---|
| Requested outcome | `Objective` |
| Observable completion condition | `Acceptance Criteria` input and `Verification Condition` |
| Scope boundary | `In Scope` files/behaviors and `Explicit Non-Goals` |

Dependencies, risk, owner/approval boundary, execution policy, stop conditions, execution scope, active ownership, state, and all existing completion evidence remain governed by the canonical Local Task Record. A Minimal Planning Record alone never makes Controlled Work ready or permits implementation.

---

## Workflow Steps

### Step 1: Define Problem Statement, Metrics & Explicit Non-Goals
1. **User & Business Problem**: What exact friction or capability does this address, for whom, and why now?
2. **Explicit Non-Goals (Scope Boundary)**:
   - What is deliberately excluded from this version?
   - Prevent scope creep by writing down what we are explicitly *not* building.
3. **Measurable Success Metrics / SLAs**:
   - Define concrete targets (e.g., p99 latency < 150ms, zero data loss, 99.9% uptime, Lighthouse score > 95, bundle size delta < 5kB).
4. **Interactive Decision & Trade-Off Clarification**:
   - When resolving architectural choices or ambiguous requirements, prioritize native interactive selection tools (e.g. OpenCode question prompt, `ask_question`) with option 1 prefixed `(Recommended)`.
   - This enables the developer to navigate with arrow keys and confirm with `Enter` in one keystroke rather than typing prose.

### Step 2: System Context & Deep Module Architecture
1. **Map the System Context**:
   - Diagram request/response lifecycles and event flows:
     `Client -> Edge Gateway -> Core Domain Engine -> Storage / Message Queue`
2. **Identify Deep Modules & Seams**:
   - Group cohesive business logic together. Avoid splitting code across too many layers unless each layer provides distinct transformative value.
   - Define clear architectural seams that enable testing without network or filesystem mocking.
3. **State Ownership & Invalidation**:
   - Where is state owned? (Database of record, Redis distributed cache, client cache, URL search params).
   - How is state invalidated or reconciled across concurrent writers?

### Step 3: Define Domain Models & Expand-Contract Evolution
1. **Domain Models & API Contracts First**:
   - Write TypeScript interfaces, Zod validation schemas, or Protocol Buffers before writing implementation code.
   - Specify request parameters, response bodies, and explicit error status codes.
2. **Database Schema & Migration Plan**:
   - Define tables, foreign keys, constraints, and query indexes upfront.
   - For changes to existing data, specify the **Expand-Contract** stages and rollback plan (RPO/RTO).

### Step 4: Threat Modeling & Failure Mode and Effects Analysis (FMEA)
Analyze system failure modes systematically before coding:

1. **Security & Authorization Audit**:
   - Multi-tenant data isolation: How do we isolate multi-tenant data so Tenant A cannot access Tenant B's data?
   - Input validation: Runtime schema boundaries (Zod/Valibot) for all external inputs.
   - Rate limiting, CSRF protection, and secret/PII redaction.
2. **FMEA Matrix (Resilience & Degradation)**:
   | Failure Scenario | Probability / Severity | Detection Method | Mitigation / Fallback | Recovery Strategy |
   | :--- | :--- | :--- | :--- | :--- |
   | Downstream Service Timeout | Medium / High | APM 5xx alert | Circuit breaker + cached response | Exponential backoff retry |
   | Concurrent Double-Submit | High / Medium | Unique constraint violation | Client idempotency key + row lock | Return existing transaction status |
   | Cache Cluster Eviction | Low / High | Cache miss rate spike | Degraded fallback to DB replica | Throttled cache repopulation |

### Step 5: Conditional Implementation Milestones (Task Record TDD Mode)
Select the milestone shape from the canonical Local Task Record. `pk:plan` and `pk:test` may record a TDD proposal or intent reference, but neither can activate TDD. The Task Record field `TDD Enforcement Mode: disabled | enabled` is authoritative; an absent field is `disabled`. If a planning or test-plan value disagrees with the Task Record, readiness is blocked until the records are reconciled, and the Task Record value controls execution.

- **Code Work with `TDD Enforcement Mode: enabled`**: Use an explicit **Red -> Green -> Refactor** sequence. Each behavior has a stable Behavior ID, a test-plan intent, an expected failing assertion and runnable Red command, then linked Green and Refactor evidence in the Task Record. Keep acceptance criteria, test strategy, review, and verification in the sequence.
  - **Red - Contracts and Seams**: Define the observable behavior, contracts, seams, and failing test assertion.
  - **Green - Implementation**: Implement the smallest change that satisfies the recorded Red behavior and preserve the same Behavior ID.
  - **Refactor - Hardening and Verification**: Improve structure, presentation, telemetry, or migration safety without changing the behavior contract; record final test, review, and verification evidence.
- **Code Work with `TDD Enforcement Mode: disabled`**: Use normal dependency-ordered milestones. Include contracts or seams, implementation, presentation or integration as applicable, hardening, acceptance, test strategy, review, and verification, but do not require a Red-Green-Refactor chain.
- **Documentation, Configuration, or Research Work**: Use the appropriate exception verification path with explicit acceptance, evidence, review, and verification. TDD Red/Green/Refactor evidence is `N/A - <reason>` and does not become a hidden requirement.
- **Ambiguous Work**: Treat the work as Code Work until its type and TDD mode are clarified in the Task Record.

The milestone plan must link to the canonical Task Record and test plan, preserve one behavior identity through enabled TDD execution, and never treat a test-plan entry as execution approval.

### Controlled & Release-Critical Work Task-Record Handoff

After the selected planning depth is complete, provide execution inputs for Level 2 (Controlled) and Level 3 (Release-Critical) Work. Minimal Planning hands off its three mapped inputs plus any owned Assumption Records and fills the required Local Task Record readiness fields at `docs/tasks/<task-id>.md`. Full Planning hands off its complete planning inputs after architecture, contracts, migration, FMEA, milestone, and grilling steps. Neither mode changes Local Task Record authority or approval boundaries. Level 0 (Direct) and Level 1 (Standard) work do not require a formal Task Record file.

- **Objective and Scope**: State the observable objective and the files, artifacts, interfaces, or behaviors in scope.
- **Explicit Non-Goals**: List excluded behavior, release actions, and independent concerns.
- **Dependencies and Risk**: Record dependencies with owners or `None`, risk, mitigation, and any approval boundary.
- **Acceptance and Verification Inputs**: Provide stable `AC-*` criteria inputs and one command, check, artifact assertion, or explicit not-applicable verification condition.
- **Execution Policy**: Identify `Gated Mode` or an explicitly approved finite batch, checkpoint intervals, stop conditions, and host timer limitations.
- **TDD Enforcement Mode**: Carry the Task Record-owned `disabled | enabled` value and any Behavior ID or TDD intent links as references. An absent value defaults to `disabled`; a planning or test-plan disagreement blocks readiness.
- **Locked Invariants**: Carry forward architectural decisions and non-negotiable constraints for the Task Record and later handoff.

`pk:plan` supplies architecture and planning inputs. `pk:tasks` creates the stable Task ID and canonical `docs/tasks/<task-id>.md` Task Record; planning does not start implementation, change task state to `in_progress`, or approve commits, pull requests, releases, or deployments.

The Planner / Architect hands the objective, bounded files or behaviors, acceptance inputs, verification condition, dependencies, risks, approval boundary, execution policy, and locked invariants to `pk:tasks`. External issues may be linked for coordination, but they are not required and do not replace the Local Task Source.

### Step 6: Generate Technical Specification & Grilling Pre-Flight
1. Scaffold the RFC document using `.promptkit/templates/tech-spec-template.md`.
2. Save to `./docs/specs/YYYY-MM-DD-spec-<feature-name>.md` (or directory configured in `PROMPTKIT.md`).
3. **Pre-Implementation Grilling**:
   - Before writing code, challenge the design using `pk:grill` to stress-test failure edge cases, scaling limits, and architectural assumptions.

---

## Completion Criteria
- Technical specification documented and approved in `./docs/specs/`.
- Deep module boundaries and test surfaces clearly mapped.
- Zero-downtime Expand-Contract migration plan detailed for all database changes.
- FMEA failure modes and mitigation fallbacks explicitly documented.
- Implementation milestones follow the Task Record's TDD Enforcement Mode: enabled Code Work has Red -> Green -> Refactor evidence; disabled Code Work has complete dependency-ordered milestones without mandatory TDD.
- Documentation, Configuration, and Research Work use an explicit exception verification path, and ambiguous work remains on the Code Work path until clarified.
- **Dual-Compatible Telemetry Status Card**: Conclude with a 3-line telemetry status card (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`) and a `> [!TIP]` callout recommending `pk:grill` or `pk:tasks`. When multiple next steps exist, invoke native interactive selection tools (e.g. `ask_question`) as your final tool call with Option 1 `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`.


---

## Related References
- [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md) — Complete workflow navigation & lifecycle mapping
- [`templates/tech-spec-template.md`](../templates/tech-spec-template.md) — Technical specification template
- [`workflows/tasks.md`](./tasks.md) — Task decomposition & acceptance criteria
