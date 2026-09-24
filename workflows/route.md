# Workflow Router (Lifecycle Decision Matrix)

## Fast Shorthand
Trigger anytime with: `pk:route` (or `/pk-route`)

### Fast Companion Scripts (Optional Sub-150ms Routing)
- **Bash**: `bash scripts/pk-route.sh "YOUR PROMPT"`
- **PowerShell**: `pwsh -NoProfile -File scripts/pk-route.ps1 "YOUR PROMPT"`
- **Axiom**: *"Jev Recommends, PromptKit Decides."* Powered by TypeSafe AI's Jev (System One) with deterministic PromptKit policy arbitration. Hard safety triggers strictly enforce a 0% Unsafe Underclassification floor, falling back cleanly to offline deterministic routing if the API key is missing or the endpoint is unreachable.

## Mission
Quickly orient the developer and AI agent to the right workflow, template, and quality gate based on the current engineering state.

Eliminate decision fatigue and guesswork by mapping every software development stage to a specialized, staff-level development protocol.

---

## Preconditions
- Developer is starting a new task, facing an architectural dilemma, debugging an issue, or preparing a pull request.
- Can be activated at any point during a pairing session to pivot into the proper workflow.

## Task Ceremony Levels & Classification

`workflows/route.md` is the canonical authority for Level 0–3 task ceremony classification, level-selection criteria, escalation, downgrade, and Task Record rules.

> **Terminology:** Use `Level 0`–`Level 3` in explanatory prose and canonical definitions. Use `L0`–`L3` as compact notation in tables, banners, telemetry, injected directives, and other token-sensitive contexts.

> A decision-grade summary of Levels 0–3 ships in the injected directive so agents can classify a request without loading this file. This document remains the canonical authority; where the summary and this file differ, this file wins.

### Upfront Ceremony Declaration Protocol (Turn 1 Announcement)
In the opening turn (Turn 1) of every task or interaction, the assistant must explicitly classify the request and declare its ceremony level on the very first line of output using this exact standardized banner format:

```text
[PromptKit OS: Level <0-3> (<Name>) — <1-line justification>]
```

**Standard Banner Formats by Level**:
- **Level 0**: `[PromptKit OS: Level 0 (Direct) — <Explanation / query / typo fix>. Zero overhead.]`
- **Level 1**: `[PromptKit OS: Level 1 (Standard) — <Localized bug fix / feature>. No Task Record required.]`
- **Level 2**: `[PromptKit OS: Level 2 (Controlled) — <Schema / auth / API / multi-component scope>. Task Record required.]`
- **Level 3**: `[PromptKit OS: Level 3 (Release-Critical) — <Release / deploy / tag candidate>. Full evaluation required.]`

Before executing any request, classify the work using the PromptKit OS 4-level task ceremony model to balance developer velocity with engineering rigor:

### Level 0 — Direct (Zero Overhead & Fast Verification)
- **Applicability**: Conceptual questions, explanations, documentation typos, formatting, syntax lookups, and tiny non-risky single-line tweaks.
- **Expected Behavior**: `understand → change → verify`
- **Verification Tier**: `fast` verification only (e.g. syntax check, markdown/link check, or `tsc --noEmit`).
- **Ceremony**: Direct execution. Zero task records, no GitHub issue required, no state tracking overhead. Single atomic commit.

### Level 1 — Standard (Lightweight Workflow & Targeted Verification)
- **Applicability**: Ordinary localized bug fixes, small self-contained features, or localized refactoring without schema, auth, or breaking contract risks.
- **Expected Behavior**: `understand → plan → implement → targeted verify → review`
- **Verification Tier**: `fast` + `required` verification (targeted unit/component tests passing with exit code 0).
- **Ceremony**: Natural workflow routing (`pk:debug`, `pk:fix`, `pk:test`) with lightweight inline planning. Normal task tracking in `docs/STATE.md` without requiring formal Task Record files.

### Level 2 — Controlled (Durable State & Multi-Tier Verification)
- **Applicability**: Work involving meaningful risk, architecture, relational schema/data migrations, authentication, authorization, public contracts, multiple components, or significant uncertainty.
- **Expected Behavior**: `task record → plan → implement → checkpoints → multi-tier verify → review`
- **Verification Tier**: `fast` + `required` + `extended` verification (integration tests, schema validation, lint/static analysis).
- **Ceremony**: Requires a Local Task Record at `docs/tasks/<task-id>.md` and formal specification (`pk:plan`, `pk:data`, `pk:auth`, `pk:api`). The Task Record is authoritative for scope, acceptance criteria, dependencies, non-goals, and verification conditions before implementation begins.

### Level 3 — Release-Critical (Full Provenance & Evaluation)
- **Applicability**: Release candidates, production deployments, high-impact public contract/API changes, tag generation, or critical security updates.
- **Expected Behavior**: `provenance → authorization → evaluation → full verify → release notes → human approval`
- **Verification Tier**: Full test suite + release candidate evaluation (`pk:ship`) + QA review + security scan.
- **Ceremony**: Uses full release candidate evaluation, contract impact evidence (`pk:ship`), QA review, and explicit human authorization boundaries before tagging, publishing, or deploying.

### Evidence-Gated Verification Matrix

PromptKit OS enforces Evidence-Gated Verification: completion claims strictly require executed evidence appropriate to the task's ceremony level:

| Ceremony Level | Typical Scope | Required Verification Tier | Required Evidence / Artifact |
| :--- | :--- | :--- | :--- |
| **Level 0 (Direct)** | Doc typo, formatting, 1-line localized fix, spike | `fast` (e.g. `tsc --noEmit`, link-check, `cargo check`) | Terminal tool execution with exit code 0 |
| **Level 1 (Standard)** | Localized bug fix, small feature tweak, component repair | `fast` + `required` (targeted unit test, component verification) | Exit code 0 + test output evidence in turn |
| **Level 2 (Controlled)** | Database schema, auth, public API contracts, multi-component | `fast` + `required` + `extended` (integration suite, schema diff, linter) | Exit code 0 + Local Task Record evidence |
| **Level 3 (Release-Critical)** | Release candidates, deployments, tag generation, security patch | Full suite + Release Candidate Evaluation (`pk:ship`) | Exit code 0 + Release Record + Human Approval |

### Canonical Mapping & Legacy Compatibility

The 4-level ceremony model refines and clarifies the system's execution boundaries:

| Level | Ceremony Class | Scope & File Impact | Required Task Record? |
| :--- | :--- | :--- | :--- |
| **Level 0** | **Direct (L0 Work)** | Conceptual queries, syntax lookups, doc typos, formatting, 1-line micro-fixes | **No** (Fast-path direct execution + `fast` verify) |
| **Level 1** | **Standard (Lightweight Work)** | Localized bug fixes, small self-contained feature tweaks, or single-component changes modifying source files without schema/auth/breaking contract risks | **No** (Natural workflow `pk:debug`/`pk:test` with inline/`STATE.md` tracking + `required` verify) |
| **Level 2** | **Controlled Work** | Relational schema/data migrations, auth, permissions, breaking API contracts, or multi-component architectural changes | **Yes** (Canonical Task Record at `docs/tasks/<task-id>.md` + `extended` verify) |
| **Level 3** | **Release-Critical Work** | Release candidates, deployments, tag generation, or high-impact contract changes | **Yes** (Level 2 evidence plus release candidate evaluation `pk:ship` & human approval) |

**Important Rule**: Modifying durable source files during an ordinary bug fix or small localized tweak is classified as **Level 1 (Standard)** and does **not** trigger Level 2 Controlled Work requirements or mandate creating `docs/tasks/<task-id>.md`. Where protocols or templates refer to "Controlled Work", those requirements apply specifically to **Level 2 (Controlled)** and **Level 3 (Release-Critical)** tasks.

### Level Decision, Escalation, Upgrade, and Downgrade Rules

1. **How an Agent Decides Which Level Applies**:
   - Assess incoming prompts for risk indicators: database schema changes, authentication/security logic, public API contract changes, multi-component scope, or release/tagging commands.
   - If no risk indicators and request is trivial or informational → **Level 0 (Direct)**.
   - Localized bug fix or small single-component feature → **Level 1 (Standard)**.
   - Schema, auth, public contract, or multi-component changes → **Level 2 (Controlled)**.
   - Release, tag, publication, or production deployment → **Level 3 (Release-Critical)**.

2. **Task Escalation / Upgrade**:
   - If work initiated at Level 0 or Level 1 expands to affect persistent data, authorization, public contracts, or multiple components, the agent **must escalate** the task to Level 2 (Controlled) or Level 3 (Release-Critical) before writing further code.
   - Announce the escalation briefly: `[PromptKit OS: Escalating to Level 2 (Controlled) due to schema/auth impact]`.

3. **Task Downgrade & Safety Boundaries**:
   - **Level 2 Downgrade**: If analysis reveals a proposed Level 2 task can be simplified into a localized, non-breaking single-file fix without schema/auth/breaking contract impact, it may be downgraded to Level 1 or Level 0. The downgrade MUST be announced with a one-line reason (e.g. `[PromptKit OS: Downgrading to Level 1 — verified single-file, non-breaking]`) and, when a Task Record already exists, noted in `docs/STATE.md`. A silent downgrade is a protocol violation.
   - **Level 3 Downgrade Guardrails**: Downgrading a Level 3 (Release-Critical) task requires ALL of the following:
     1. A documented reason and revised task scope;
     2. Confirmation that no tag creation, release publication, production deployment, or other release-critical action remains in scope;
     3. Explicit human Release Coordinator approval if release evaluation or evidence creation (`pk:ship`) has already begun;
     4. Preservation or an explicit closure record for any existing release evidence. A downgrade must never be used to bypass release provenance, QA review, or human authorization boundaries.

4b. **Tie-Break (Mixed-Level Requests)**: If two or more levels plausibly apply to one request (e.g. "fix this typo and add the index"), classify at the **highest** applicable level and state that choice in the Turn 1 banner. Risk-before-size still applies downward never upward.

4c. **Hierarchical Workflow Composition (Primary vs. Supporting)**:
To eliminate cognitive confusion, duplicate context loads, and conflicting instructions when a task touches multiple domains (e.g., implementing a feature while modifying database schemas and writing tests):
- **One Primary Workflow**: Exactly **one** primary lifecycle workflow owns the active turn and execution state (e.g., `pk:fix` for bug remediation, `pk:plan` for controlled planning, `pk:debug` for root-cause diagnosis).
- **Explicit Supporting Checks**: Auxiliary domain concerns do NOT launch competing primary workflows. Instead, they are declared and evaluated as modular **Supporting Checks** under the primary workflow's lifecycle:
  - *Data Safety Check*: If the primary task touches tables or columns, enforce `workflows/data.md` Expand-Contract invariants without replacing the primary workflow.
  - *Quality Gate Check*: All primary workflows terminate at `protocols/code-quality-gate.md` for machine-verified oracle compliance.
  - *Security Check*: If auth or secrets are touched, attach `workflows/auth.md` invariants as supporting constraints.
- **Rule**: Never load multiple parallel primary workflow files in a single turn. Declare `Primary: <workflow>` and list active `Supporting Checks: [<protocol/workflow>]`.

4d. **JIT Stack Playbook Discovery & Injection**:
To prevent framework bloat while providing deep architectural invariants, the router checks `PROMPTKIT.md` for active stack playbooks:
- **Repository Manifest Signals**: Candidate manifests (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `render.yaml`) map to bounded playbooks in `docs/stacks/`.
- **Bounded JIT Loading**: The assistant loads **only** the candidate playbook(s) declared in `PROMPTKIT.md` (e.g. `docs/stacks/database-turso.md`).
- **Context Exclusion**: Unrelated stack playbooks (e.g. Rust playbooks in a Next.js repo) are strictly excluded to preserve token budgets.
- **Precedence Hierarchy**: Local Project Profile Overrides > PromptKit Stack Playbooks > External Host Skills.
  - *Invocation vs. Classification*: Invoking an external host skill or slash command never reclassifies work. Classification is determined strictly by the produced work (e.g. database migrations produced via a host skill remain Level 2 Controlled Work).
  - *Gate Subordination*: Skill-specific process instructions yield to PromptKit Hard Gates (machine-verified oracle compliance, Expand-Contract data safety, secret hygiene, and milestone boundaries). Domain knowledge is preserved; process instructions yield.
  - *Namespace Collisions*: Host skills named with a `pk-*` prefix collide with PromptKit's `pk:*` text-convention triggers and shadow workflow routing. Host skills should use domain-specific names (e.g. `sql-optimizer`, not `pk-db`).

5. **Proactive Level-Fit Check (Milestone Boundaries)**:
   Escalation has triggers; de-escalation has none — ceremony must not ratchet upward and then coast there. At the **start of each milestone**, before inheriting the previous milestone's level, run a one-line fit check and propose a downgrade when the criteria hold:
   - **Level-1 fit criteria**: single component, no schema/data migration, no auth/permission change, no public or breaking contract change, no new dependency surface.
   - **Proposed, never forced**: announce the proposed level with a one-line rationale and proceed on operator confirmation. The existing downgrade announcement rule above still applies; silence is not confirmation.
   - **Verification is not downgraded**: the Evidence-Gated Verification Matrix above applies at every level. A downgrade reduces records, never verification — Level 1 still requires `fast` + `required` evidence with exit code 0.
   - **Large work unaffected**: schema, auth, multi-component, or contract work keeps its level exactly as today.
   - *Worked example*: a milestone scoped to "add CSV export to the reports page" (one component, no schema/auth/contract change) is proposed as **Level 1** — no Task Record file, verification still required. The same milestone adding a stored `exports` table or a public API route is **Level 2** — Task Record required, cadence unchanged.

5b. **Checkpoint Cadence by Project Size**:
   - **Small projects** (`size: small`, single component, one active lane): a **milestone boundary** is the natural checkpoint. Do not manufacture extra checkpoint/handoff pairs inside a single Level 1 milestone — record-keeping is not progress.
   - **Medium/large or multi-component projects**: keep session-boundary cadence.
   - Canonical cadence numbers (soft/hard checkpoint windows, turn nudges) live in [`workflows/checkpoint.md`](./checkpoint.md) — this rule selects *when a boundary is worth a record*; it never relaxes a Level 2/3 hard checkpoint.

### Model-Tiering & Resource Optimization Guidance

To optimize API cost, token consumption, and reasoning depth, match your LLM selection to the active ceremony level:

| Task Ceremony Level | Recommended Model Class | Example Host Models | Primary Architectural Justification |
| :--- | :--- | :--- | :--- |
| **Level 0 (Direct)** | **Fast / Economy Tier** | Gemini Flash, Claude Haiku, GPT-4o-mini | Sub-second latency, near-zero token cost; ideal for typos, syntax queries, and non-risky 1-line edits. |
| **Level 1 (Standard)** | **Balanced Coding Tier** | Gemini Flash-High, Claude Sonnet, GPT-4o | Fast tool dispatch, reliable multi-file reasoning, high precision for ordinary bug fixes and component features. |
| **Level 2 (Controlled)** | **Frontier Reasoning Tier** | Gemini Pro, Claude Sonnet (Thinking), OpenAI o3-mini/o1 | Deep architectural constraint handling, state invariants, schema migrations, and security boundaries. |
| **Level 3 (Release-Critical)**| **Maximum Reasoning Tier** | Gemini Pro / Ultra, Claude Opus, OpenAI o1 | Zero-tolerance for hallucinations; release provenance, verification synthesis, and rollback planning. |

*Rule of Thumb*: Never waste expensive frontier reasoning budgets on Level 0 syntax formatting; never under-power Level 2/3 database migrations with economy models.

### Controlled Work Ownership Handoff

| Handoff | Owner | Output and boundary |
| :--- | :--- | :--- |
| Classification → architecture | `pk:route` → `pk:plan` | Route the request and readiness inputs; do not decompose tasks or approve implementation. |
| Architecture → task source | `pk:plan` → `pk:tasks` | Carry objective, scope, non-goals, dependencies, acceptance, verification, and invariants into the canonical Task Record. |
| Task source → implementation | `pk:tasks` → Engineer | Start only after readiness and active-task ownership are recorded; implement within scope. |
| Implementation → review/evidence | Engineer → `pk:checkpoint` / `pk:review` | Preserve checkpoints, handoffs, changed files, acceptance, blockers, and review findings. |
| Review → commit/PR/release | `pk:review` → `pk:commit` → `pk:pr` → `pk:ship` | Link evidence while keeping human approval for commit, push, merge, tag, release, deployment, and rollback (except an explicitly authorized `pk:auto` run; see the canonical Action Authority Model in `protocols/code-quality-gate.md`). |

The Local Task Record remains authoritative throughout. `docs/STATE.md` is a synchronized projection, and external issues or dated breakdowns are optional references.

### PromptKit Adaptation Compatibility Contract

The PromptKit SDLC Adaptation is an additive evidence layer over this router:

- `pk:route` remains the sole authority for Level 0–3 task ceremony classification (Level 0 Direct, Level 1 Standard, Level 2 Controlled, Level 3 Release-Critical).
- After classification, `Minimal` or `Full` Planning Interrogation may describe planning depth for Controlled Work; neither is a new execution class or routing branch.
- L0 Work keeps its existing Fast-Path and receives no mandatory Adaptation artifact or interrogation solely because the Adaptation exists.
- Controlled Work keeps the existing Local Task Record readiness, state, active-ownership, and completion gates before implementation.
- Existing workflow owners and human approval boundaries remain unchanged. Planning supplies inputs; it does not approve implementation, commits, pull requests, releases, deployment, or rollback.
- Future Adaptation fields and sections are additive. Existing records remain valid without retroactive migration, and no new execution-control trigger is introduced here.

The shared authority matrix and compatibility boundaries are maintained in [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md). Scope expansion or escalation across Levels 0–3 follows the existing classification and readiness rules above.

---

## The Engineering Lifecycle Decision Matrix

Find your current engineering context below and activate the corresponding workflow:

| Current Context / Problem | Recommended Trigger | Primary Artifact Output | Core Value Delivered |
| :--- | :--- | :--- | :--- |
| **New Feature or Inception** | `pk:plan` | `docs/specs/` | Modular RFC spec, deletion test, threat modeling |
| **New Project / Greenfield Inception** | `pk:onboard` | Intake Record + `PROMPTKIT.md` | Bounded discovery interview (size-classed): MVP intent, surfaces, deployment, design inputs |
| **Existing Repo / Brownfield Intake** | `pk:onboard` | `PROMPTKIT.md` & `docs/STATE.md` | Automated stack scan, command extraction, PROMPTKIT.md generation |
| **Task Breakdown & Acceptance Criteria** | `pk:tasks` | `docs/tasks/` or gh CLI | Atomic issues, Gherkin AC, Kanban lane sync, gh CLI |
| **Relational Database Design** | `pk:data` | `docs/data/` | UUIDv7 keys, composite indexes, RLS policies |
| **Auth, Cookies & Permissions**| `pk:auth` | `docs/auth/` | HttpOnly cookies, OAuth PKCE, RBAC matrix |
| **API Contract & Handshake** | `pk:api` | `docs/api/` | Error envelopes, cursor pagination, typed clients |
| **Upfront Test Planning** | `pk:test` | `docs/tests/` | Pyramid seams, test data factories, mock boundaries |
| **UI, Styling & Design System**| `pk:design` | `docs/design/` | WCAG 2.2 AA contrast, design tokens, anti-slop UI |
| **Unproven Tech or Benchmark** | `pk:spike` | `docs/spikes/` | Sharpest-risk test, baseline comparison, ADR |
| **Defect, Bug or Regression** | `pk:debug` | `docs/rca/` | Red loop first, tagged probes, 5-Whys post-mortem |
| **Remediation & Known Findings** | `pk:fix` | Code repair | Surgical remediation of known findings, security-first ordering |
| **Structural Refactor & Debt** | `pk:refactor` | Code modernization | Golden Master pinning, Mikado method, Strangler Fig |
| **Performance, Latency & Profiling** | `pk:perf` | `docs/perf/` | Baseline metrics, flamegraphs, EXPLAIN ANALYZE, delta audit |
| **Pre-Merge Pull Request Audit**| `pk:review` | `docs/reviews/<review-slug>.md` | Two-axis review: Spec Fidelity vs Technical Standards |
| **Atomic Git Staging & Commit** | `pk:commit` | Git History | Conventional Commits, single-concern staging, secret leak check |
| **Pull Request Description**   | `pk:pr`     | PR Body / `gh pr`    | Verification evidence, migration safety check, rollback plan |
| **Context Bloat & Handover**    | `pk:checkpoint`| `docs/STATE.md` & Notes | Session state compaction, invariant locking, docs/STATE.md sync |
| **Zero-Downtime Deployment**    | `pk:ship`   | `docs/releases/` | Runtime env validation, Expand-Contract migrations |
| **Post-Implementation Retro**   | `pk:retro`  | `docs/adrs/` & journal| MADR records, progress journal, skill matrix updates |
| **Learning & Socratic Coaching**| `pk:tutor`  | Conversation / Notes | 3-tier progressive hints, conceptual mental models |
| **Architecture Defense Drill**  | `pk:grill`  | Conversation / Notes | Staff Engineer Devil's Advocate stress-testing |
| **Wrong Profile / Mode Upgrade**| `pk:profile` | `PROMPTKIT.md` + injected directive | Runtime Lite/Balanced/Turbo switching via the idempotent installer re-injection path |
| **Unattended SDLC & Automation**| `pk:auto` | Verified diff / PR | Autonomous pipeline chaining (plan→tasks→code→test→review), default stop at review-ready |

---

### PromptKit OS Release-Evidence Routing Overlay

This overlay extends the existing lifecycle router without adding a new trigger. Classify requests using the Level 0–3 ceremony model, treat release and evidence work as Level 3 (retaining Task Record, pk:ship, QA review, and human-approval boundaries), and use the existing workflows:

| Request shape | Route | Required result |
| :--- | :--- | :--- |
| **Commit-level release evidence**, Public PromptKit Contract impact, or Maintenance Commit classification | `pk:commit` | Capture or link Contract Impact Evidence, or record an explicit Maintenance Commit declaration stating no intentional public-contract change. Preserve Conventional Commit syntax, one complete reversible concern, scoped staging, and developer confirmation. |
| **Release-evaluation handoff**, QA-to-coordinator handoff, or preliminary candidate checkpoint | `pk:checkpoint` | Record the Evaluation ID, Release Candidate Commit, preliminary candidate, QA status, blockers, source records, handoff status, and one requested next human decision. The handoff is never approval. |
| **Version-candidate** calculation, normalized-history review, filtered **release-note** derivation, draft changelog entries, consistency review, or final internal release decision | `pk:ship` | Evaluate the repository-only Release Range, Effective Change Set, preliminary candidate, Public and Maintenance Release Notes, and Approved Release Record. Keep deployment-specific guidance and external actions separate. |

#### Release-evidence routing rules

1. Route a request about evidence attached to one commit, public-contract impact, breaking guidance, or a no-public-change declaration to `pk:commit`. A `feat`, `fix`, or `perf` label does not determine the SemVer impact.
2. Route a request to preserve an evaluation across a session or role boundary, or to hand a preliminary candidate and blockers to the next owner, to `pk:checkpoint`. `pk:checkpoint` projects handoff state and never approves, tags, publishes, pushes, deploys, or rolls back.
3. Route a request to calculate or review a version candidate, normalize merge/squash/duplicate/revert history, derive Public or Maintenance Release Notes, prepare explicitly unpublished draft Changelog Entries, check cross-record consistency, or record an approval/defer decision to `pk:ship`.
4. Keep the existing `pk:commit → pk:pr → pk:ship` path for ordinary reviewed changes. The optional `pk:checkpoint` release-evaluation handoff supplies evidence to `pk:ship`; it does not replace review, commit, PR, or production-safety gates.
5. Apply this release-evidence policy only to PromptKit OS internal releases. Consumer repositories remain outside its Conventional Commit, SemVer, release-note, changelog, tag, remote, publication, deployment, and rollback requirements.

#### Candidate and external-action boundary

The router may identify the appropriate phase, but routing is not approval. A preliminary candidate, QA result, checkpoint handoff, validator, CI result, or empty blocker list cannot become an Approved Release Version by itself. The Release Coordinator must make separate explicit human decisions for tag creation, hosted release creation, changelog publication, remote operations, production deployment, and rollback. No routing outcome invokes those actions automatically.

Use the existing [`pk:commit`](./commit.md), [`pk:checkpoint`](./checkpoint.md), and [`pk:ship`](./ship.md) workflows for the routed phase. Use [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md), [`templates/contract-impact-evidence-template.md`](../templates/contract-impact-evidence-template.md), and [`templates/release-evaluation-template.md`](../templates/release-evaluation-template.md) as supporting references; do not create a new command.

### Visual Lifecycle Flow

```text
               [ Inception & Intake ]
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
         pk:plan                           pk:onboard
    (Greenfield Intake → RFC)                  (Brownfield Intake)
            │                                 │
            └────────────────┬────────────────┘
                             │
                             ▼
                          pk:tasks
          (Atomic Issues, Gherkin AC & Kanban Sync)
                             │
     ┌──────────────────────┼──────────────────────┐
     ▼                      ▼                      ▼
  pk:data                pk:auth                 pk:api
(Relational Schema)    (Session & RBAC)    (Endpoints & Types)
     │                      │                      │
     └──────────────────────┼──────────────────────┘
                            │
                     [ Implementation ]
                            │
     ┌──────────────────────┼──────────────────────┐
     ▼                      ▼                      ▼
  pk:test               pk:design               pk:spike
(Pyramid & Mocks)     (Tokens & A11y)      (Risk Spikes)
     │                      │                      │
     └──────────────────────┼──────────────────────┘
                            │
                [ Verification & Merge ]
                            │
     ┌──────────────────────┼──────────────────────┐
     ▼                      ▼                      ▼
  pk:debug               pk:perf               pk:review
(Empirical Root Cause) (Latency & Profiling) (Two-Axis Code Audit)
     │                      │                      │
     └──────────────────────┼──────────────────────┘
                            │
                        pk:commit
             (Atomic Conventional Commits)
                            │
                         pk:pr
             (High-Signal PR Descriptions)
                            │
                     [ Release & Ops ]
                            │
                         pk:ship
             (Zero-Downtime Deploy & Rollback)
                            │
             [ Knowledge Capture & Handover ]
                            │
     ┌──────────────────────┴──────────────────────┐
     ▼                                             ▼
  pk:retro                                   pk:checkpoint
(MADR & Journals)                       (Zero-Loss Chat Handover)
```

---

## Diagnostic Questions for Ambiguous Tasks

When a developer asks for help without specifying a command, the assistant should evaluate these 3 triage questions:

1. **What phase of the change are you in?**
   - *Pre-code*: Are we onboarding an existing repository (`pk:onboard`), clarifying requirements (`pk:plan`), decomposing tasks into issues (`pk:tasks`), evaluating an unknown library (`pk:spike`), or designing schemas (`pk:data` / `pk:auth` / `pk:api`)?
   - *Active coding*: Are we building tests (`pk:test`), styling components (`pk:design`), investigating broken behavior (`pk:debug`), or profiling slow performance (`pk:perf`)?
   - *Post-code*: Are we auditing code quality (`pk:review`), staging atomic commits (`pk:commit`), opening a pull request (`pk:pr`), shipping to production (`pk:ship`), or capturing decisions (`pk:retro`)?
   - *Session pause / Handover*: Are we experiencing context window bloat or switching to a fresh chat window (`pk:checkpoint`)?

2. **Is there an active broken state?**
   - If yes: Immediately recommend `pk:debug`. Stop writing speculative code until a deterministic reproduction loop (<3 seconds) is established.

3. **Are you looking for an answer, or looking to build mental models?**
   - If learning or stuck on a concept: Activate `pk:tutor` to receive 3-tier progressive hints instead of unsolicited solution dumping.

---

## Smart Auto-Route Protocol & Guardrails

When working in an environment with PromptKit OS, the developer may prompt using natural language without specifying a `pk:` shorthand. The assistant must evaluate incoming requests according to this two-tier routing policy:

### Tier 1: Fast-Path / L0 (Zero Overhead Guardrail)
If the request is:
- A conceptual question, syntax lookup, or library query (e.g., "How does `useId` work in React 19?")
- A quick single-line or small localized tweak (e.g., "Rename this variable to `userEmail`")
- A simple code explanation, formatting, or lightweight helper request

**Action**: Answer directly, concisely, and immediately.
- For an **informational L0** request (no code changes): Do **not** trigger a workflow ceremony, do **not** write files to `docs/`, do **not** require an atomic commit or Task Record, do **not** output terminal execution evidence, and do **not** add a banner.
- For a **small L0 edit**: Apply proportional local verification only. Do **not** trigger a workflow ceremony or add unnecessary process overhead. Preserve tokens and developer velocity.

### Tier 2: Substantive Protocol Auto-Route
If the request involves non-trivial engineering changes (new features, crashes, schema changes, auth, API modifications, or releases):

**Action**:
1. Announce the active workflow in a single brief line:
   `[PromptKit OS: Auto-routed to pk:<workflow>]`
2. Automatically adhere to that workflow's quality gates, pre-conditions, and artifact outputs:
   - **Bugs, errors, broken tests, unexpected behavior (unknown cause)**: Auto-route to `pk:debug`. Establish the reproduction loop before proposing any fix.
   - **Known defects, review findings, security patches, code smells**: Auto-route to `pk:fix`. Enforce security-first ordering, reproduction/measurement, and single-concern scope.
   - **Structural refactoring, technical debt, code modernization**: Auto-route to `pk:refactor`. Pin behavior with Golden Master snapshots and follow the Mikado method.
   - **Performance regressions, slow queries, latency, memory leaks, bundle bloat**: Auto-route to `pk:perf`. Capture baseline metrics before modifying code.
   - **New features, cross-component additions, new pages**: Auto-route to `pk:plan`. Create the RFC spec before writing code.
   - **Existing codebase intake, repo analysis, setup**: Auto-route to `pk:onboard`. Scan repository manifests and populate PROMPTKIT.md.
   - **Task breakdowns, issue creation, acceptance criteria, Kanban cards**: Auto-route to `pk:tasks`. Structure atomic 1-4 hour issues with Gherkin AC.
   - **Database tables, migrations, RLS policies, indexing**: Auto-route to `pk:data`. Enforce Expand-Contract phased sequencing.
   - **Login, session tokens, cookies, permissions**: Auto-route to `pk:auth`. Establish the capability matrix first.
   - **API routes, endpoints, contracts, error envelopes**: Auto-route to `pk:api`. Define schema types and envelope formats first.
   - **Test suites, unit/integration splits, mock boundaries**: Auto-route to `pk:test`. Allocate pyramid seams before code.
   - **PR review, diff audit, refactoring assessment**: Auto-route to `pk:review`. Audit against spec fidelity and Fowler smells.
   - **Git commits, staging changes, commit message generation**: Auto-route to `pk:commit`. Scan for secret leaks and format Conventional Commit.
   - **Pull requests, PR descriptions, or opening a PR**: Auto-route to `pk:pr`. Compile verification evidence and format PR description.
   - **Context bloat, chat lag, session handover, or pausing**: Auto-route to `pk:checkpoint`. Compress working state, sync `docs/STATE.md`, and generate handover prompt.
   - **Production deployment, env vars, rollback prep**: Auto-route to `pk:ship`. Run runtime env validation and release checklist.
   - **Unattended execution, hands-off automation, end-to-end task runs**: Auto-route to `workflows/auto.md` (`pk:auto`). Announce the active leash on Turn 1 and halt at `review ready` (or declared boundary) with a 3-strike test circuit breaker.

### Tier 3: Subagent Delegation Guardrails
When executing workflows in agentic multi-agent environments (Antigravity, Claude Code, Cursor background agents), follow `.promptkit/protocols/subagent-delegation.md`:
- **Delegate to Subagents**:
  - `pk:spike`: Fan out parallel subagents to benchmark competing frameworks concurrently.
  - `pk:review`: Run Spec Fidelity and Fowler Code Smells audits in concurrent subagents.
  - `pk:onboard`: Delegate deep manifest parsing and directory topology scanning.
  - Heavy exploration requiring reading >3 files or external documentation searches.
- **Retain in Main Thread**:
  - Direct user questions, clarifications, and interactive approvals.
  - Quick single-file edits (<10 lines) and syntax lookups.
  - Git staging, atomic commits (`pk:commit`), and pull request creation (`pk:pr`).
  - Final architectural synthesis and invariant locking (`pk:plan`, `docs/STATE.md`).
- **Synthesis Mandate**: All subagents must return compact 5-15 line synthesized reports (with exact file paths and line numbers) rather than dumping raw tool scrollback into parent context.


---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
