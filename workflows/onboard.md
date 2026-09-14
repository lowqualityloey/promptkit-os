# Brownfield Codebase Intake & Onboarding Workflow

## Fast Shorthand
Trigger anytime with: `pk:onboard` (or `/pk-onboard`, `pk:scan`, `pk:init-repo`)

## Mission
Ingest any existing repository into the PromptKit OS engineering operating system in under 60 seconds. Inspect package manifests, active developer scripts, database schemas, and architectural boundaries. Auto-populate `./PROMPTKIT.md` (and `./DESIGN.md` if frontend surfaces exist), establish a concrete baseline for code quality gates, and index existing technical debt into `docs/tasks/`.

Eliminate day-one setup friction. Replace manual configuration chores with automated, deterministic architectural discovery.

---

## Core Principle: Zero Manual Boilerplate on Day One
The assistant must perform the investigative heavy lifting: reading manifests, configs, and directory structures directly. The developer should never have to manually type out test commands, linter flags, or stack details that are already committed to the repository.

---

## Non-Negotiable Guardrail: 100% Passive Inspection (Zero Rogue Modifications)
The `pk:onboard` workflow and setup scripts are strictly passive and read-only regarding host application code. The assistant performs non-destructive discovery: scanning manifests, tooling, and directory structures. It must **never** create, modify, or delete project application source files unprompted. 

After completing the scan and presenting the findings summary / Executive Scorecard, the assistant must halt and ask the human for confirmation before generating configs or taking any further action.

---

## Preconditions
- The repository contains existing application code, manifests, or configuration files.
- PromptKit OS is installed in `.promptkit/` or `promptkit/`.
- Access to `.promptkit/templates/project-profile-template.md` and `.promptkit/templates/design-profile-template.md`.

---

## 4-Phase Onboarding Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                    PK:ONBOARD LIFECYCLE                     │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Phase 1:     │ Phase 2:     │ Phase 3:     │ Phase 4:       │
│ Manifest &   │ Architecture │ Profile &    │ Health Score-  │
│ Tooling Scan │ & Boundaries │ Guardrail Gen│ card & Backlog │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

### Phase 1: Manifest & Tooling Discovery

> [!IMPORTANT]
> **Passive Inspection Directive**: Phases 1 & 2 are strictly read-only scanning operations. The AI assistant must not create, edit, or delete any host application source files. After scanning manifests and architecture, the assistant presents its findings summary / scorecard and halts to request human confirmation before proceeding to file generation.

1. **Package Manager & Ecosystem Detection**:
   Inspect the repository root for lockfiles and manifests:
   - Node.js / TypeScript: `pnpm-lock.yaml` (pnpm), `bun.lockb` / `bun.lock` (bun), `package-lock.json` (npm), `yarn.lock` (yarn).
   - Python: `uv.lock` (uv), `poetry.lock` (poetry), `Pipfile.lock` (pipenv), `requirements.txt`.
   - Rust / Go / Java: `Cargo.lock` (cargo), `go.mod` (go), `pom.xml` / `build.gradle`.

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
         - label: "Lite (Recommended for new users) (Recommended)"
           description: "6 utility workflows (route, debug, commit, checkpoint, sync, profile) 877 tok, 80% value, fastest onboarding, <1,500 tok"
         - label: "Balanced (Recommended for teams)"
           description: "Full 23 workflows, 2,103 tok, Level 0-3 adaptive ceremony, teams/production, default"
         - label: "Turbo (Experimental)"
           description: "Balanced + parallel subagent waves, 3-5x token cost, still requires human L3 approval, needs --experimental acknowledgement"
       multiSelect: false
     ```
   - Hosts without `ask_question` support: fallback to `> [!TIP] ### 💡 Choose profile (Type number & Enter):` with Option 1 prefixed `(Recommended)` and Option 2 as default.
   - If developer chooses Turbo, require explicit experimental acknowledgement: second confirmation `Acknowledge Turbo experimental cost (3-5x tokens) and that human approval still required for L3? [y/N]`
   - Store choice as machine-readable `profile: lite|balanced|turbo` in `PROMPTKIT.md` (both human section `## 0. PromptKit OS Profile` and bottom `profile:` line) so future sessions don't re-ask.
   - Non-interactive / CI: respect flags `--lite`, `--balanced`, `--turbo --experimental` passed to `init.sh` / `init.ps1`, or `PROMPTKIT.md` existing profile, or default to `balanced`. When `PROMPTKIT_NO_INTERACTIVE=1` is set, skip any picker (this agent-level prompt and the shell-level TTY picker in `init.sh` / `init.ps1`) and apply flags/default only.

2. **Auto-Populate `PROMPTKIT.md`**:
   Copy `.promptkit/templates/project-profile-template.md` to `./PROMPTKIT.md` and fill out all sections using findings from Phases 1 and 2:
   - Project Name inferred from directory or manifest `name`.
   - Active commands configured to the exact detected package manager and runner scripts.
   - If monorepo detected, populate Section 4 (`Monorepo & Workspace Topology`) with the mapped workspace manager, package table, filtered command conventions (`pnpm --filter <pkg>`, `turbo run <cmd> --filter=<pkg>`), and boundary guardrails. If single-package repo, set Section 4 to `N/A (Standalone Repository)`.
   - Document paths set to standard defaults (`docs/specs/`, `docs/tasks/`, `docs/data/`, etc.) and link any detected root documentation (`ARCHITECTURE.md`, `ROADMAP.md`, `RUNBOOK.md`, `STYLE.md`).
   - Task tracking system recorded in Section 5 (`Local Markdown (docs/tasks/)` by default, or `GitHub Issues` / `Linear` / `Jira` if requested).
   - Tailored architectural invariants added (e.g. strict TypeScript, zero loose casting, database check constraints, RLS enforcement).
   - Ensure `## 0. PromptKit OS Profile` section exists with chosen profile (`lite|balanced|turbo`) and machine-readable `profile:` line at bottom for agent parsing (from Step 1).

3. **Auto-Populate `DESIGN.md` (If Frontend Surfaces Exist)**:
   If UI components are detected (`.tsx`, `.jsx`, `.vue`, `.svelte`):
   - Inspect styling configurations: `tailwind.config.*`, `globals.css`, `components.json` (Shadcn UI).
   - Extract primary brand colors, font families, base radius (`rounded-md`), and typography tokens.
   - Scaffold `./DESIGN.md` incorporating PromptKit OS anti-slop directives and detected tokens.

4. **Auto-Populate `docs/STATE.md` (Living Project Tracker)**:
   Copy `.promptkit/templates/state-tracker-template.md` to `./docs/STATE.md`:
   - Populate project name, current branch, and active status.
   - If monorepo, set initial Target Workspace / Package in Section 3 (`Active Working Set`).
   - Record detected architectural invariants in Section 4.
   - Seed Section 8 (`Session Continuity Log`) with an initial onboarding entry:
     `| YYYY-MM-DD | Assistant (pk:onboard) | Brownfield Codebase Intake | Generated PROMPTKIT.md and initialized docs/STATE.md |`

---

### Phase 4: Architecture Health Scorecard & Backlog Ingestion

1. **Emit Executive Architecture Scorecard**:
   Present the developer with a concise summary table in the conversation:
   - **Stack & Tooling**: Confirmed runtime, framework, ORM, and test runners.
   - **Task Tracking System**: Confirmed task lifecycle backend (`Local Markdown (docs/tasks/)`, `GitHub Issues`, `Linear`, or `Jira`).
   - **Active MCP Capabilities**: Catalog detected Model Context Protocol servers (e.g. GitHub MCP, Postgres MCP, Linear) or record `N/A (Standard CLI Fallback)`.
   - **Existing System Documentation**: Catalog detected standard root documentation (`ARCHITECTURE.md`, `ROADMAP.md`, `RUNBOOK.md`, `STYLE.md`) or record `N/A (None Detected)`.
   - **Architectural Strengths**: High test coverage, strict typing, clean modular boundaries.
   - **Vulnerabilities & Missing Seams**: Zero integration tests, unindexed foreign keys, loose `any` types, missing error boundaries.

2. **Technical Debt Indexing (Optional Backlog Scaffolding)**:
   Search for existing codebase debt markers:
   - `git grep -in "TODO:"` or `git grep -in "FIXME:"`.
   - Unmigrated database drafts or missing test suites.
   - Offer to run `pk:tasks` to structure high-priority debt items into atomic task cards in `docs/tasks/`.
   - Record discovered debt tasks in `docs/STATE.md` under initial remediation items.

3. **Announce Ready State**:
   Confirm that `./PROMPTKIT.md` and `./docs/STATE.md` are active and suggest the immediate next workflow:
   - Use `pk:plan` for upcoming new features.
   - Use `pk:tasks` to break down existing backlog items.
   - Use `pk:debug` for active defects.

---

## Completion Criteria
- Manifests and scripts inspected; package manager verified.
- `./PROMPTKIT.md` generated with non-generic, working project commands.
- `./DESIGN.md` generated or skipped with explicit rationale.
- `./docs/STATE.md` initialized with project baseline and active branch.
- Executive Architecture Scorecard delivered to developer.
- Workspace ready for immediate `pk:` workflow pairing.
