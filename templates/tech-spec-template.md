# Technical Design Document (RFC, Request for Comments): [Feature / System Name]

> **Developer-friendly fill-in guide:** Mark each prompt **Required**, **Optional**, or **Not applicable** in your working copy. Required prompts should be specific enough for another developer to act on; Optional prompts add useful context when available; Not applicable prompts should say why they do not apply. Prefer concise, observable values such as `Target Release: Milestone 3`, `Verification Approach: run the API contract and migration checks`, or `Externally Visible Contracts: None - internal refactor`.
>
> **Status map:** `Author`, `Status`, `Created`, and `Target Release` are **Required**. The Planning Record fields already show their conditional status. Architecture, contracts, security, failure-mode, milestone, and sign-off prompts are **Required when the corresponding concern is in scope**; otherwise record **Not applicable** with a short reason. Material technology decisions require their decision, claim, citation, and uncertainty records; when no material decision exists, record `None` as instructed.
>
> **Acronym guide:** `RFC` means Request for Comments; `TDD` means Test-Driven Development; `API` means Application Programming Interface; `FMEA` means Failure Mode and Effects Analysis; `RBAC` means Role-Based Access Control; `RPO/RTO` mean Recovery Point Objective/Recovery Time Objective; and `SLA` means Service-Level Agreement. These terms describe the same existing fields and do not add new approval or execution authority.

- **Author**: [Your Name / Team]
- **Status**: [Draft | In Review | Approved | Implemented]
- **Created**: [YYYY-MM-DD]
- **Target Release**: [Sprint / Milestone]

---

## Planning Record (PromptKit Adaptation)

<!-- Replace the example anchor with the immutable planning ID, for example: <a id="PLAN-checkout"></a> -->
<a id="PLAN-spec-slug"></a>

> **Use this section for Controlled Work only.** Trivial Work keeps the existing fast path and does not require a Planning Record or Assumption Record. This section is the canonical planning location; do not create a parallel `docs/plans/` artifact.

### Planning Record Metadata

- **Planning Record ID [Required]**: `PLAN-<spec-slug>`
- **Planning Depth [Required]**: `Minimal | Full`
- **Owner [Required]**: [Person, role, or team]
- **Record Status [Required]**: `draft | ready | blocked | superseded`
- **Local Task Record Link [Required for Controlled Work]**: `[TASK-<task-slug>](../tasks/<task-id>.md#TASK-<task-slug>)`
- **Workflow Links [Optional]**: `[workflow anchor links]`

### Planning Inputs

- **Requested Outcome [Required]**: [What observable result is requested?]
- **Observable Completion Condition [Required]**: [What will show that the outcome is complete?]
- **Scope Boundary [Required]**: [Files, behaviors, interfaces, or components in scope and excluded]
- **TDD Enforcement Proposal (Reference Only) [Optional]**: `disabled | enabled | None`; this proposal cannot activate TDD. The canonical Local Task Record owns `TDD Enforcement Mode`, and an absent Task Record field defaults to `disabled`.

### Minimal Planning

When **Planning Depth** is `Minimal`, the three Planning Inputs above are the only required planning questions. They seed the Local Task Record but do not satisfy its full readiness contract. Full-only fields below are `N/A - Minimal depth` when genuinely not required in this planning record; the Local Task Record still requires explicit non-goals, dependencies, owner/approval boundary, verification, and execution-policy values.

### Full Planning

Select `Full` when work affects a public or external contract, persistent data or schema, authentication or authorization, an external integration, release configuration or release risk, multiple Behavioral Components, serious safety/rollback/data-loss risk, or an explicitly requested architecture plan. A lightweight request cannot override these triggers.

- **Explicit Non-Goals [Required in Full; Not applicable in Minimal]**: [What is deliberately excluded?]
- **Affected Behavioral Components [Required in Full; Not applicable in Minimal]**: [Screens, APIs, jobs, commands, libraries, data areas, or deployment behaviors]
- **Externally Visible Contracts [Required in Full; Not applicable in Minimal]**: [APIs, data formats, commands, integrations, or user-visible behavior; write `None` if not applicable]
- **Failure or Rollback Considerations [Required in Full; Not applicable in Minimal]**: [Failure modes, data-loss risk, rollback or recovery considerations]
- **Verification Approach [Required in Full; Not applicable in Minimal]**: [How the design and implementation will be verified]

After Full inputs are recorded, continue through the existing architecture, contracts, migration, FMEA, milestone, and grilling sections below. Do not repeat those workflow sections in this Planning Record.

### Assumption Records

If a required planning input is unanswered, record an owned provisional assumption before handing inputs to `pk:tasks`. If no unanswered required input exists, write `None` instead of leaving this section blank. An Assumption Record is not a confirmed decision and remains in this Planning Record; it does not create a second authority.

For each assumption, expose the exact immutable ID as an anchor immediately before the assumption heading or record block, for example `<a id="ASSUMPTION-checkout-001"></a>`:

- **Assumption ID [Required]**: `ASSUMPTION-<spec-slug>-<nnn>`
- **Unanswered Decision [Required]**: [What must be decided?]
- **Provisional Answer [Required]**: [Current working answer]
- **Impact if Wrong [Required]**: [What could change or be harmed?]
- **Validation Action [Required]**: [How and when will this be checked?]
- **Decision Owner [Required]**: [Named person or role]
- **Status [Required]**: `open | validated | accepted | rejected | superseded`
- **Supporting Evidence [Optional]**: `[<stable-id>](<relative-path>#<stable-id>)` or `None`
- **Resolution Evidence [Not applicable until resolved]**: `[<stable-id>](<relative-path>#<stable-id>)` or `N/A - unresolved`

Do not repeat a completed planning question unless scope changes, an assumption is invalidated, or new evidence changes the decision. Record the changed scope, assumption, or evidence when asking it again.

### Technology and Vendor Decision Records

Create the following records only when the Planning Record contains a material Technology or Vendor Decision. This includes adopting, replacing, configuring, versioning, or materially depending on an external technology, service, platform, framework, library, or managed service when the choice affects compatibility, security behavior, supported limits, pricing, availability, lifecycle, or integration behavior. If no material decision exists, write `None`. Merely naming an existing technology in an architecture description does not create a decision record or require research.

Keep all records in this Planning Record. Do not create a parallel `docs/decisions/` directory. Use the exact stable ID as an HTML anchor immediately before each record heading. A Material Claim must link to a Citation Record or an Uncertainty Record. Use primary documentation where available, and do not mark a claim verified when the source is unavailable, inaccessible, stale, or conflicting.

<a id="DECISION-spec-slug-001"></a>
#### Decision Record: `DECISION-spec-slug-001`

- **Decision ID [Required]**: `DECISION-spec-slug-001`
- **Decision Statement [Required]**: [What material technology or vendor decision must be made?]
- **Considered Options [Required]**: [Options compared and the relevant decision criteria]
- **Selected Option(s) [Required]**: [Selected option(s); use `None` while status is `proposed` or `deferred`]
- **Rejected Option(s) [Required]**: [Rejected option(s) and reasons; use `None` while status is `proposed` or `deferred`]
- **Material Claim Links [Required]**: `[CLAIM-DECISION-spec-slug-001-001](#CLAIM-DECISION-spec-slug-001-001)` or `None` with an explanation
- **Remaining Uncertainty [Required]**: `[UNCERTAINTY-DECISION-spec-slug-001-001](#UNCERTAINTY-DECISION-spec-slug-001-001)` or `None`
- **Decision Owner [Required]**: [Named person or role accountable for the decision]
- **Status [Required]**: `proposed | decided | deferred | superseded`

##### Version Selection Fields

Complete these fields when the material decision includes a technology, platform, framework, library, service, or tool version. Otherwise record `Not applicable` with a reason where a conditional field is shown.

- **Version Selection Context [Required when versioned]**: `Greenfield/no preference | Existing project | Explicit upgrade request | Other recorded constraint`; `Not applicable - no version selected` when the decision does not include a version.
- **AI Recommendation [Optional when versioned]**: [Recommended exact version or versions and supporting rationale]; `Not applicable - no AI recommendation` if none.
- **Selected Exact Version(s) [Required when versioned]**: [Exact pinned version or versions; never use `latest`, an unbounded range, prerelease, nightly, or experimental value as the selected default]
- **Release Channel [Required when versioned]**: `stable | LTS | prerelease | nightly | experimental`; explain any non-stable selection and do not use it as the default recommendation.
- **Support/Lifecycle Status [Required when versioned]**: [Production support, active support, LTS, maintenance, or end-of-life status with evidence]
- **Compatibility Constraints [Required when versioned]**: [Runtime, platform, dependency, API, deployment, and support constraints]
- **Version Rationale [Required when versioned]**: [Why this exact version was selected, preserved, or explicitly upgraded]
- **Exact-Version Evidence [Required when versioned]**: [Citation links, access dates, and source evidence supporting the exact version and its status]
- **Existing Version Baseline [Required for existing project]**: [Current pinned version or versions and preservation/upgrade evidence]; `Not applicable - greenfield or no existing pin` when applicable.
- **Decision Owner Approval or Accepted Assumption [Required]**: [Named owner, approval or acceptance state, and date/evidence. AI or PromptKit recommendation alone is not approval.]

- **pk:spike or ADR Link [Optional]**: `[workflow or supporting record link]` or `None`

<a id="CLAIM-DECISION-spec-slug-001-001"></a>
#### Material Claim Record: `CLAIM-DECISION-spec-slug-001-001`

- **Claim ID [Required]**: `CLAIM-DECISION-spec-slug-001-001`
- **Decision Link [Required]**: `[DECISION-spec-slug-001](#DECISION-spec-slug-001)`
- **Material Claim [Required]**: [The concrete factual claim that affects the decision]
- **Citation or Uncertainty Link [Required]**: `[CITATION-DECISION-spec-slug-001-001](#CITATION-DECISION-spec-slug-001-001)` or `[UNCERTAINTY-DECISION-spec-slug-001-001](#UNCERTAINTY-DECISION-spec-slug-001-001)`

<a id="CITATION-DECISION-spec-slug-001-001"></a>
#### Citation Record: `CITATION-DECISION-spec-slug-001-001`

- **Citation ID [Required]**: `CITATION-DECISION-spec-slug-001-001`
- **Publisher [Required]**: [Technology, vendor, standards body, or project publisher]
- **Document Title [Required]**: [Title of the primary document]
- **Canonical URL [Required]**: [Canonical source URL]
- **Access Date [Required]**: `[YYYY-MM-DD]`
- **Supported Claim Link [Required]**: `[CLAIM-DECISION-spec-slug-001-001](#CLAIM-DECISION-spec-slug-001-001)`
- **Citation Status [Required]**: `candidate | verified | stale | inaccessible | conflicting | superseded`

<a id="UNCERTAINTY-DECISION-spec-slug-001-001"></a>
#### Uncertainty Record: `UNCERTAINTY-DECISION-spec-slug-001-001`

- **Uncertainty ID [Required]**: `UNCERTAINTY-DECISION-spec-slug-001-001`
- **Affected Claim or Context [Required]**: [Claim or decision context that remains unverified]
- **Impact [Required]**: [What could change or be harmed if the uncertainty is wrong?]
- **Resolution Action [Required]**: `Defer the decision | Run a targeted pk:spike | Proceed with an explicitly accepted assumption`
- **Decision Owner [Required]**: [Named person or role]
- **Status [Required]**: `open | resolved | accepted | deferred | superseded`
- **Supporting Evidence [Optional]**: `[<stable-id>](<relative-path>#<stable-id>)` or `None`

When a source is unavailable, inaccessible, stale, or conflicting, keep the affected Citation at its corresponding non-verified status and record the impact and permitted resolution action in the Uncertainty Record. `pk:spike` owns investigation method and comparison depth; the Planning Record remains the authority for decision provenance. The Local Task Record may link to a concluded decision as planning context or a locked invariant, but it does not own the decision, source status, or research method.

---

## 1. Executive Summary & Problem Statement
[A 1-2 paragraph high-level overview of what this project accomplishes, who it is for, why it is necessary now, and the primary business/engineering outcome it delivers.]

---

## 2. Goals and Explicit Non-Goals

### Goals (In Scope)
- [Goal 1: Measurable outcome, e.g., Implement optimistic workspace membership invitations with email verification]
- [Goal 2: Performance SLA, e.g., API response time p99 < 120ms under 500 req/sec]
- [Goal 3: Reliability target, e.g., Zero downtime deployment with zero unhandled promise rejections]

### Non-Goals (Explicit Scope Boundary)
- [Non-Goal 1: What we are deliberately NOT building in this version, e.g., SAML/SSO enterprise authentication]
- [Non-Goal 2: What is deferred to V2, e.g., Bulk CSV user upload]

---

## 3. Architecture & System Context

> Worked example below is illustrative for a web service (Next.js + PostgreSQL + queue/worker). Replace with the project's native architecture and stack-appropriate diagram.

### High-Level Architecture Diagram (example — replace with project's native architecture)
```text
┌──────────────┐       HTTPS        ┌────────────────┐       SQL        ┌──────────────────┐
│ Client (Web) ├───────────────────►│ Next.js API    ├─────────────────►│ PostgreSQL (DB) │
└──────────────┘                    │ (Server Action)│                  └──────────────────┘
                                     └───────┬────────┘
                                             │ Dispatches
                                             ▼
                                     ┌────────────────┐       Async      ┌──────────────────┐
                                     │ Event Queue    ├─────────────────►│ Transactional    │
                                     │ (Redis / SQS)  │                  │ Email Worker     │
                                     └────────────────┘                  └──────────────────┘
```

### Deep Module Decomposition & Seams
> *Deletion Test: Does this module concentrate complexity, or merely scatter it? Ensure interfaces are deep (simple interface, powerful internal logic).*

| Module / Seam | Public Interface / Boundary | Internal Complexity Hidden |
| :--- | :--- | :--- |
| **InvitationEngine** | `createInvite()`, `claimToken()` | State transitions, cryptographic token generation, rate-limit check, TTL calculation |
| **MembershipStore** | `saveInvitation()`, `atomicPromote()` | Row locking, transaction atomicity, multi-tenant isolation |
| **InviteModal** | `<InviteDialog onInvite={...} />` | Accessible Radix dialog, Zod client validation, optimistic state |

---

## 4. Detailed Design & Contracts First

### 4.1 Data Models & Schemas (example — Prisma for a relational web app; use the project's native representation)
```prisma
// Example Schema Definition
model WorkspaceInvitation {
  id          String   @id @default(cuid())
  email       String
  workspaceId String
  role        Role     @default(MEMBER)
  token       String   @unique
  expiresAt   DateTime
  createdAt   DateTime @default(now())
  workspace   Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)

  @@index([email, workspaceId])
  @@index([token])
}
```

### 4.2 Zero-Downtime Migration Plan (Expand-Contract) — when live or compatibility-sensitive data exists; otherwise `N/A - <reason>` (one-shot/disposable/pre-deployment may skip with rationale)
If modifying existing live or compatibility-sensitive schemas or columns, describe the zero-downtime lifecycle:
1. **Phase 1 (Expand)**: Add new column as nullable; write to both old and new columns.
2. **Phase 2 (Backfill & Read Switch)**: Backfill historical records via background job; switch application read queries to new column.
3. **Phase 3 (Contract)**: Stop writes to old column; drop old column in subsequent deployment after verification.
- **Rollback Plan (RPO/RTO)**: [How to revert safely if the migration fails during deployment]

### 4.3 API Endpoints & Contracts (example — Zod for TypeScript; use the project's native validation mechanism)
```typescript
export const SendInviteRequestSchema = z.object({
  workspaceId: z.string().cuid(),
  email: z.string().email(),
  role: z.enum(['ADMIN', 'MEMBER', 'VIEWER']),
});
export type SendInviteRequest = z.infer<typeof SendInviteRequestSchema>;

export const SendInviteResponseSchema = z.object({
  success: z.boolean(),
  invitationId: z.string(),
  expiresAt: z.string().datetime(),
});
export type SendInviteResponse = z.infer<typeof SendInviteResponseSchema>;
```

---

## 5. Security, Privacy & Failure Modes (FMEA)

### Security & Multi-Tenancy Audit (scope each item to the change — `N/A - <reason>` where not applicable)
- **Tenancy Boundary** (multi-tenant systems only): How do we ensure Tenant A cannot read or mutate Tenant B's data?
- **Authentication & RBAC** (where auth exists): Required permissions to invoke this endpoint (`MANAGE_MEMBERS`).
- **Input Sanitization**: Runtime validation using the project's native mechanism (e.g. Zod for TypeScript) on all inputs; parameterized database queries.
- **Secrets & PII**: Ensure email addresses and tokens are omitted from public client payloads and unredacted logs.

### FMEA Resilience Matrix
| Failure Scenario | Probability / Severity | Detection Method | Mitigation / Fallback | Recovery Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Email Worker Down** | Medium / High | Queue lag alert | Retain in durable queue with DLQ | Exponential backoff retry |
| **Duplicate Invite Sent** | High / Low | Unique index constraint | Upsert: refresh token & extend TTL | Return existing invite status |
| **Rate Limit Exceeded** | Low / Medium | HTTP 429 response count | Client toast warning with retry timer | User retries after cooldown |

---

## 6. Conditional Implementation Milestones

The canonical Local Task Record owns `TDD Enforcement Mode: disabled | enabled`; an absent field defaults to `disabled`. This technical specification may propose a mode, but the proposal is reference-only. If the proposal or test plan disagrees with the Task Record, readiness is blocked until reconciled, and the Task Record controls execution.

### Code Work with TDD Enforcement Mode `enabled`

Use the Red -> Green -> Refactor sequence. Every behavior keeps the same `BEHAVIOR-<task-slug>-<nnn>` identity from the test-plan intent through Task Record execution evidence.

- [ ] **Milestone 1 - Red: Contracts and Seams**:
  - Define schema, API, domain, or interface contracts and the observable behavior.
  - Record the expected failing assertion and runnable Red command in the test plan.
- [ ] **Milestone 2 - Green: Smallest Satisfying Implementation**:
  - Implement the minimum code that satisfies the recorded Red behavior.
  - Record Green results without changing the Behavior ID or acceptance meaning.
- [ ] **Milestone 3 - Refactor: Hardening and Verification**:
  - Improve structure, presentation, telemetry, migration safety, and test quality without changing the behavior contract.
  - Record Refactor results, acceptance, review, and final verification evidence.

### Code Work with TDD Enforcement Mode `disabled`

Use normal dependency-ordered milestones. Include contracts or seams, implementation, presentation or integration as applicable, hardening, acceptance criteria, test strategy, review, and verification. Do not require Red, Green, or Refactor evidence when the Task Record mode is disabled.

### Documentation, Configuration, or Research Work

Use an exception verification path with explicit acceptance, evidence, review, and verification. TDD execution fields are `N/A - <reason>` when this work type does not have Code Work behavior to exercise.

### Sign-off Readiness

The selected milestone branch, Task Record link, test-plan reference, acceptance criteria, review path, and verification condition are recorded before implementation. A proposal or test-plan intent never authorizes implementation by itself.

---

## 7. Sign-off & Grilling Checklist
- [ ] Architecture challenged via `pk:grill`.
- [ ] Zero-downtime database evolution verified.
- [ ] Non-goals agreed upon with stakeholders.
- [ ] Ready for the selected Task Record milestone path: enabled TDD, disabled Code Work, or an exception verification path.
