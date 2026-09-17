# Project Intake & Onboarding Workflow (Greenfield & Brownfield)

## Fast Shorthand
Trigger anytime with: `pk:onboard` (or `/pk-onboard`, `pk:scan`, `pk:init-repo`)

## Mission
Bring any project into the PromptKit OS engineering operating system: interview a greenfield repository that has no code yet, or ingest an existing repository in under 60 seconds. For brownfield work, inspect package manifests, active developer scripts, database schemas, and architectural boundaries. For greenfield work, run the bounded Project Discovery Intake to establish MVP intent, surfaces, deployment target, constraints, and design inputs before any architecture is proposed. Auto-populate `./PROMPTKIT.md` (and `./DESIGN.md` if frontend surfaces exist), establish a concrete baseline for code quality gates, and index existing technical debt into `docs/tasks/`.

Eliminate day-one setup friction. Replace manual configuration chores with deterministic discovery for existing code, and with a bounded low-technical interview for new projects. Brownfield keeps the passive read-only discovery path; greenfield asks instead of assuming.

## Core Principle: Ask Before Assuming
For a greenfield repository there is nothing to inspect, so the assistant asks instead of inventing. The bounded interview in [`discovery-intake.md`](../protocols/discovery-intake.md) collects only what the human can answer, and every unanswered slot becomes an owned assumption rather than a silent agent default. This is the intake that prevents an agent's preferred architecture from becoming the project's architecture by default.

---

## Core Principle: Zero Manual Boilerplate on Day One
The assistant must perform the investigative heavy lifting: reading manifests, configs, and directory structures directly. The developer should never have to manually type out test commands, linter flags, or stack details that are already committed to the repository.

---

## Non-Negotiable Guardrail: 100% Passive Inspection (Zero Rogue Modifications)
The `pk:onboard` workflow and setup scripts are strictly passive and read-only regarding host application code. The assistant performs non-destructive discovery: scanning manifests, tooling, and directory structures. It must **never** create, modify, or delete project application source files unprompted. 

After completing the scan and presenting the findings summary / Executive Scorecard, the assistant must halt and ask the human for confirmation before generating configs or taking any further action.

---

## Preconditions
- **Brownfield**: the repository contains existing application code, manifests, or configuration files.
- **Greenfield**: the repository is empty or contains only documentation, licence, and git metadata — Phase 0 applies.
- PromptKit OS is installed in `.promptkit/` or `promptkit/`.
- Access to `.promptkit/templates/project-profile-template.md` and `.promptkit/templates/design-profile-template.md`.
- Greenfield only: access to `.promptkit/protocols/discovery-intake.md` (the bounded interview protocol).

---

## 5-Phase Onboarding Protocol

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                              PK:ONBOARD LIFECYCLE                            │
├────────────────┬──────────────┬───────────────┬──────────────┬──────────────┤
│ Phase 0:       │ Phase 1:     │ Phase 2:      │ Phase 3:     │ Phase 4:     │
│ Greenfield     │ Manifest &   │ Architecture  │ Profile &    │ Health Score-│
│ Intake (cond.) │ Tooling Scan │ & Boundaries  │ Guardrail Gen│ card & Backlog│
└────────────────┴──────────────┴───────────────┴──────────────┴──────────────┘
```

> Phase 0 is **conditional**: it activates only for greenfield repositories. If any application code, manifest, or lockfile is detected, skip Phase 0 entirely and run Phases 1–4 unchanged.

---

### Phase 0: Greenfield Discovery Intake (Greenfield Only)

**Activation gate**: run this phase only when the repository has no application code, no package manifests, and no lockfiles (documentation, licence, and git metadata are acceptable). Otherwise proceed directly to Phase 1.

1. **Load the bounded interview protocol**: read [`discovery-intake.md`](../protocols/discovery-intake.md) and determine the size class (`S`/`M`/`L`) from the user's first description. Never load the protocol for brownfield runs.
2. **Ask in the context window, never in choice menus**: every intake question is asked as plain conversation so the human can paste Figma links, screenshots, `ARCHITECTURE.md`/`STYLE.md`/`DESIGN.md` references, or Jira/GitHub board links as answers. Modal pickers are permitted only for genuinely closed-set questions (≤4 options, no attachment expected, evidence-based or explicitly marked "no recommendation").
3. **Cover the 7 intake slots within the size-class round cap** (S ≤ 1 round / ≤ 5 questions, M ≤ 2 / ≤ 8, L ≤ 3 / ≤ 12): MVP intent, surfaces, deployment target, auth & data, constraints, design inputs, integrations. Accept "not sure" and record it as an open question.
4. **Close the loop**: after each round ask *"Is there anything you want to add?"* and *"Is this enough for now?"* — close on explicit user signal, all slots covered, round cap reached, or no new information in a round. Record the `close_reason`.
5. **Never propose architecture during intake**: unanswered slots become owned `ASSUMPTION-*` entries with a validation owner — never silent agent defaults. Any AI-suggested capability that lacks a user-stated requirement goes to the **Later ledger**, not the plan.
6. **Propose tooling accept-or-change, never default it**: only after the intent slots are answered, offer at most three stack proposals (package manager, data-fetching, runner). Each names its rationale and vintage (e.g. "2026-era default: pnpm — compatible and fast"). Nothing is written, installed, or assumed until the human explicitly accepts; changing any line overturns that slot, and unanswered proposals stay open questions.
7. **Product-shaped requests get questions, never a stack**: when slot 3 reports two or more surfaces (a SaaS-class request: accounts plus data plus auth or billing), also ask the five Product-Shape Cover Questions in [`discovery-intake.md`](../protocols/discovery-intake.md), folded into the same size-class question budget. The first response to such a request is questions, not files: never name, choose, install, or announce a stack, generator, or starter template — tooling stays accept-or-change under step 6, and an unattended build still requires `pk:plan`/`pk:tasks` plus milestone approval.
8. **Persist**: record the Intake Record per the protocol; the durable projection (`size:` and `intake-status:` lines in `PROMPTKIT.md`) is written during Phase 3.

---

### Phase 1: Manifest & Tooling Discovery

> [!IMPORTANT]
> **Passive Inspection Directive**: Phases 1 & 2 are strictly read-only scanning operations. The AI assistant must not create, edit, or delete any host application source files. After scanning manifests and architecture, the assistant presents its findings summary / scorecard and halts to request human confirmation before proceeding to file generation.

1. **Package Manager & Ecosystem Detection**:
   Inspect the repository root for lockfiles and manifests:
   - Node.js / TypeScript: `pnpm-lock.yaml` (pnpm), `bun.lockb` / `bun.lock` (bun), `package-lock.json` (npm), `yarn.lock` (yarn).
   - Python: `uv.lock` (uv), `poetry.lock` (poetry), `Pipfile.lock` (pipenv), `requirements.txt`.
   - Rust / Go / Java: `Cargo.lock` (cargo), `go.mod` (go), `pom.xml` / `build.gradle`.
   - Record the detected toolchain as ground truth. Never propose switching package managers, runners, or frameworks on brownfield runs; the only stack question permitted is a missing capability the task requires.

2. **Monorepo & Workspace Manifest Detection**:
   Inspect root directory for multi-package monorepo managers:
   - Turborepo: `turbo.json`.
   - pnpm Workspaces: `pnpm-workspace.yaml`.
   - Nx: `nx.json`.
   - Lerna: `lerna.json`.
   - Bun / npm / yarn workspaces: `"workspaces"` field in root `package.json` or `bunfig.toml`.
   - Parse workspace target globs (e.g. `apps/*`, `packages/*`, `libs/*`).

3. **Developer Script Extraction**:
   Parse project scripts (e.g. `scripts` in `package.json`, `Makefile`, `justfile`, `pyproject.toml`) to identify exact commands:
   - **Unit Tests**: e.g., `pnpm test`, `npm run test:unit`, `pytest`, `cargo test`.
   - **Integration / E2E Tests**: e.g., `pnpm test:e2e`, `playwright test`, `cypress run`.
   - **Typecheck**: e.g., `pnpm tsc --noEmit`, `mypy .`, `pyright`.
   - **Linter & Formatter**: e.g., `pnpm lint`, `biome check`, `eslint .`, `ruff check`.
   - **Dev Server & Build**: e.g., `pnpm dev`, `pnpm build`.

---

### Phase 2: Architecture & Boundary Mapping

1. **Structural Layering & Pattern Detection**:
   Inspect directory layout to classify architecture:
   - **Next.js App Router**: `app/` directory, Server Components, Route Handlers.
   - **Next.js Pages Router**: `pages/` directory, `pages/api/`.
   - **Clean / Hexagonal Architecture**: `domain/`, `application/`, `infrastructure/`, `adapters/`.
   - **Feature-Sliced Design**: `src/features/*`, `src/modules/*`.
   - **Monorepo Multi-Package Topology**:
     If monorepo manifests are detected:
     - Scan all packages matching workspace globs (`apps/*`, `packages/*`, `libs/*`).
     - Catalog each package's `name` and domain responsibility (e.g. `@repo/web` $\rightarrow$ Frontend, `@repo/api` $\rightarrow$ API server, `@repo/db` $\rightarrow$ Database & ORM, `@repo/ui` $\rightarrow$ Shared component library).
     - Inspect inter-package dependencies (`dependencies` using `workspace:*`).
     - Map boundary rules: identify server vs client packages and verify that shared UI packages do not depend on backend services.

2. **Data & Persistence Inspection**:
   Identify database engine and ORM layers:
   - Prisma: `prisma/schema.prisma`.
   - Drizzle: `drizzle.config.ts`, `schema/`.
   - Supabase: `supabase/migrations/`, `supabase/config.toml`.
   - SQL / Raw: `migrations/`, `db/`.

3. **Authentication & Authorization Model**:
   Detect identity providers and session strategies:
   - Supabase Auth, NextAuth / Auth.js, Clerk, Lucia, Better-Auth, Stytch, Firebase.
   - Session storage mechanism: HttpOnly cookies, JWT headers, or server sessions.

4. **API Communication Style**:
   Identify communication conventions:
   - tRPC (`server/routers/`), Server Actions (`"use server"`), GraphQL, RESTful endpoints (`app/api/*`).

5. **Standard Root Documentation Scan**:
   Passively check for pre-existing repository documentation:
   - `ARCHITECTURE.md`: System design blueprints and domain boundaries.
   - `ROADMAP.md`: Strategic product milestones and sequencing.
   - `RUNBOOK.md` / `OPERATIONS.md`: Operational SRE manuals and rollback procedures.
   - `STYLE.md` / `STYLEGUIDE.md`: Repository-specific code style conventions.
   - If detected, record these files for linkage in `PROMPTKIT.md`. If absent, silently continue with zero warnings.

---

### Phase 3: Profile & Guardrail Generation

> [!TIP]
> **Profile Selection — Visual Decision (2+1 Modes):** PromptKit OS now ships with 2 official + 1 experimental profiles. For onboarding, you MUST use native interactive selection tools (e.g. `ask_question` / prompt picker) to let the developer choose visually, not just via flags. This is the agent-level equivalent of the shell TTY picker in `init.sh`.

1. **Profile Selection via Native Interactive Tools (Visual Decision):**
   - Check `PROMPTKIT.md` for existing `profile: lite|balanced|turbo` line. If present, respect it and skip prompt.
   - If missing and running in interactive host (Claude Code, Cursor, OpenCode, etc.), invoke native selection tool as final action of Phase 2 / first action of Phase 3:
     ```
     ask_question:
       question: "Choose PromptKit OS profile for this project"
       header: "Profile"
       options:
         - label: "Lite (Recommended for new users)"
           description: "6 utility workflows (route, debug, commit, checkpoint, sync, profile), 80% of value, fastest onboarding, fits the <1,500 tok lite budget"
         - label: "Balanced (Recommended for teams)"
           description: "Full 23-workflow set, Level 0-3 adaptive ceremony, teams/production, default"
         - label: "Turbo (Experimental)"
           description: "Balanced + parallel subagent waves, up to ~2x measured token cost, still requires human L3 approval, needs --experimental acknowledgement"
       multiSelect: false
     ```
   - Hosts without `ask_question` support: fallback to `> [!TIP] ### 💡 Choose profile (Type number & Enter):` with Option 1 prefixed `(Recommended)` and Option 2 as default.
   - If developer chooses Turbo, require explicit experimental acknowledgement: second confirmation `Acknowledge Turbo experimental cost (up to ~2x measured tokens) and that human approval still required for L3? [y/N]`
   - Store choice as machine-readable `profile: lite|balanced|turbo` in `PROMPTKIT.md` (both human section `## 0. PromptKit OS Profile` and bottom `profile:` line) so future sessions don't re-ask.
    - Non-interactive / CI: respect flags `--lite`, `--balanced`, `--turbo --experimental` passed to `init.sh` / `init.ps1`, or `PROMPTKIT.md` existing profile, or default to `balanced`. When `PROMPTKIT_NO_INTERACTIVE=1` is set, skip any picker (this agent-level prompt and the shell-level TTY picker in `init.sh` / `init.ps1`) and apply flags/default only.

1b. **Task Tracker Selection via Native Interactive Tools (Visual Decision):**
    - Check `PROMPTKIT.md` for existing `tracking: local|github|jira|linear` line. If present, respect it and skip prompt.
    - If missing and running in interactive host, invoke native selection tool immediately after profile selection:
      ```
      ask_question:
        question: "Where should PromptKit tasks live for this project?"
        header: "Tracker"
        options:
          - label: "Local Markdown (Recommended for solo / offline)"
            description: "Writes docs/tasks/*.md + docs/STATE.md only, offline, import to GitHub/Jira later, reversible"
          - label: "GitHub Issues"
            description: "Publishes via gh CLI or github-mcp-server, ~2 min, needs gh auth + labels script, reversible"
          - label: "Jira"
            description: "Formats to Jira schema, manual import / copy-paste, no auto-push, needs project key"
          - label: "Linear"
            description: "Formats to Linear schema, manual import / copy-paste, no auto-push, needs project key"
        multiSelect: false
      ```
    - Hosts without `ask_question` support: fallback to `> [!TIP] ### 💡 Choose tracker (Type number & Enter):` with Option 1 prefixed `(Recommended)`. A single-number reply (`1`) executes that option.
    - Store choice as machine-readable `tracking: local|github|jira|linear` in `PROMPTKIT.md` (Section 5 + bottom machine line) so future sessions don't re-ask.
    - Non-interactive / CI: respect `--tracking=<value>` passed to `init.sh` / `init.ps1`, or existing `tracking:` line, or default to `local`. When `PROMPTKIT_NO_INTERACTIVE=1` is set, skip picker and apply flags/default only.

2. **Auto-Populate `PROMPTKIT.md`**:
   Copy `.promptkit/templates/project-profile-template.md` to `./PROMPTKIT.md` and fill out all sections using findings from Phases 1 and 2:
   - Project Name inferred from directory or manifest `name`.
   - Active commands configured to the exact detected package manager and runner scripts.
   - If monorepo detected, populate Section 4 (`Monorepo & Workspace Topology`) with the mapped workspace manager, package table, filtered command conventions (`pnpm --filter <pkg>`, `turbo run <cmd> --filter=<pkg>`), and boundary guardrails. If single-package repo, set Section 4 to `N/A (Standalone Repository)`.
    - Document paths set to standard defaults (`docs/specs/`, `docs/tasks/`, `docs/data/`, etc.) and link any detected root documentation (`ARCHITECTURE.md`, `ROADMAP.md`, `RUNBOOK.md`, `STYLE.md`).
    - Task tracking system recorded in Section 5 from Step 1b picker (`Local Markdown (docs/tasks/)` default, or `GitHub Issues` / `Jira` / `Linear`). Jira/Linear are manual import / copy-paste with no auto-push; Local Task Record at `docs/tasks/<task-id>.md` remains authoritative and board status is a projection only.
    - Tailored architectural invariants added (e.g. strict TypeScript, zero loose casting, database check constraints, RLS enforcement).
    - Ensure `## 0. PromptKit OS Profile` section exists with chosen profile (`lite|balanced|turbo`), machine-readable `profile:` line, and machine-readable `tracking: local|github|jira|linear` line at bottom for agent parsing (from Steps 1 and 1b).
    - Write the machine-readable `size: small|medium|large` and `intake-status: unanswered|partial|complete` lines below `profile:`: greenfield copies them from the Phase 0 Intake Record (`complete` when closed); brownfield writes best-effort `size:` and `intake-status: legacy-partial` (never `complete` — the scan cannot answer intent slots).

3. **Auto-Populate `DESIGN.md` (If Frontend Surfaces Exist)**:
   If UI components are detected (`.tsx`, `.jsx`, `.vue`, `.svelte`):
   - Inspect styling configurations: `tailwind.config.*`, `globals.css`, `components.json` (Shadcn UI).
   - Extract primary brand colors, font families, base radius (`rounded-md`), and typography tokens.
   - Scaffold `./DESIGN.md` incorporating PromptKit OS anti-slop directives and detected tokens.

4. **Auto-Populate `docs/STATE.md` (Living Project Tracker)**:
   Copy `.promptkit/templates/state-tracker-template.md` to `./docs/STATE.md`:
   - Populate project name, current branch, and active status.
   - If monorepo, set initial Target Workspace / Package in Section 3 (`Active Working Set`).
   - Record detected architectural invariants in Section 4, keeping each line's documented source (user-stated constraint vs manifest-derived observation) so intake findings are distinguishable from human-approved policy.
   - Seed Section 8 (`Session Continuity Log`) with an initial onboarding entry:
     `| YYYY-MM-DD | Assistant (pk:onboard) | Project Intake (Greenfield or Brownfield) | Generated PROMPTKIT.md and initialized docs/STATE.md |`

---

### Phase 4: Architecture Health Scorecard & Backlog Ingestion

1. **Emit Executive Architecture Scorecard**:
   Present the developer with a concise summary table in the conversation:
    - **Stack & Tooling**: Confirmed runtime, framework, ORM, and test runners.
    - **Task Tracking System**: Confirmed task lifecycle backend from Step 1b (`tracking: local|github|jira|linear`). Jira/Linear are manual import with no auto-push.
    - **Active MCP Capabilities**: Catalog detected Model Context Protocol servers (e.g. GitHub MCP, Postgres MCP, Linear) or record `N/A (Standard CLI Fallback)`. This step is non-blocking advise only — the agent cannot enable MCP; the human configures it in-host. Recommend: tracker=github → `github-mcp-server`; `pk:data` planned → `postgres-mcp` read-only; frontend → `playwright`. Always add fallback line: `No MCP? Zero errors — falls back to gh CLI + markdown.` Store in `PROMPTKIT.md §5`.
   - **Existing System Documentation**: Catalog detected standard root documentation (`ARCHITECTURE.md`, `ROADMAP.md`, `RUNBOOK.md`, `STYLE.md`) or record `N/A (None Detected)`.
   - **Architectural Strengths**: High test coverage, strict typing, clean modular boundaries.
   - **Vulnerabilities & Missing Seams**: Zero integration tests, unindexed foreign keys, loose `any` types, missing error boundaries.

2. **Technical Debt Indexing (Optional Backlog Scaffolding)**:
   Search for existing codebase debt markers:
   - `git grep -in "TODO:"` or `git grep -in "FIXME:"`.
   - Unmigrated database drafts or missing test suites.
   - Offer to run `pk:tasks` to structure high-priority debt items into atomic task cards in `docs/tasks/`.
   - Record discovered debt tasks in `docs/STATE.md` under initial remediation items.

3. **Invariant Handoff (Sync to STATE.md)**:
   Append any hard constraints, non-negotiables, or architectural rules discovered during the intake or manifest scan (e.g., "Must use UUIDv7", "Zero raw hex colors in CSS", "No ORM") directly into Section 4 (`Locked Technical Invariants`) of `docs/STATE.md`, annotating each entry's source. Rules stated by the human are invariants; agent observations from manifests or code are **Candidate Learnings** staged in Section 5 with status `pending` under the memory-vs-policy boundary (`protocols/context-sync.md` §3.1) and require explicit human approval to promote.

4. **Announce Ready State**:
   Confirm that `./PROMPTKIT.md` and `./docs/STATE.md` are active and suggest the immediate next workflow:
   - Use `pk:plan` for upcoming new features.
   - Use `pk:tasks` to break down existing backlog items.
   - Use `pk:debug` for active defects.

---

## Completion Criteria
- Greenfield: bounded intake closed with a recorded `close_reason`; `size:` and `intake-status:` written to `PROMPTKIT.md`; unanswered slots carry owned `ASSUMPTION-*` entries.
- Manifests and scripts inspected; package manager verified.
- `./PROMPTKIT.md` generated with non-generic, working project commands.
- `./DESIGN.md` generated or skipped with explicit rationale.
- `./docs/STATE.md` initialized with project baseline and active branch.
- **Invariant Handoff**: Human-stated rules persisted to `docs/STATE.md` Section 4; manifest-derived observations staged as pending Candidate Learnings per the memory-vs-policy boundary.
- Executive Architecture Scorecard delivered to developer.
- Workspace ready for immediate `pk:` workflow pairing.
