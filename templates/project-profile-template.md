# Project Architectural Profile (`PROMPTKIT.md`)

> **Instructions for AI**: Read this file during every session. Adhere strictly to the project domain boundaries, commands, documentation targets, and non-negotiable architectural rules defined below.

## 0. PromptKit OS Profile
- **Profile**: `balanced` (options: `lite` | `balanced` | `turbo` experimental)
- **Installed**: [YYYY-MM-DD]
- **Engine**: `.promptkit`
- **Description**:
  - `lite`: 4 workflows (route, debug, commit, checkpoint) <1,500 tok, 80% value — onboarding
  - `balanced`: full 22 workflows, Level 0-3 adaptive ceremony (default) — teams, production
  - `turbo`: experimental, Balanced + parallel subagent waves, 3-5x token cost, still requires human L3 approval
- **Upgrade Path**: Run `.promptkit/init.sh --balanced` for full, `--lite` for minimal, `--turbo --experimental` for parallel waves

profile: balanced

---

## 1. Project Overview & Domain
- **Project Name**: [e.g. Acme Dashboard]
- **Domain / Purpose**: [e.g. Multi-tenant B2B analytics platform for logistics tracking]
- **Primary Users**: [e.g. Fleet operators, dispatch managers]

---

## 2. Active Technology Stack
- **Language & Runtime**: [e.g. TypeScript (Strict), Node.js v22]
- **Frontend Framework**: [e.g. Next.js 15 (App Router), React 19]
- **Styling & Design System**: [e.g. Tailwind CSS v4, Radix UI Primitives, Lucide Icons]
- **State & Data Fetching**: [e.g. TanStack Query v5, Server Actions]
- **Backend & Database**: [e.g. PostgreSQL 16, Drizzle ORM]
- **Testing**: [e.g. Vitest (Unit), Playwright (E2E)]

---

## 3. Project Commands (Root / Global)
- **Install**: `pnpm install`
- **Dev Server**: `pnpm dev`
- **Unit Tests**: `pnpm test`
- **E2E Tests**: `pnpm test:e2e`
- **Typecheck**: `pnpm tsc --noEmit`
- **Lint & Format**: `pnpm lint`

---

## 4. Monorepo & Workspace Topology (If Applicable)
> Set to `N/A (Standalone Repository)` if not operating within a multi-package monorepo.

- **Workspace Manager**: [e.g. Turborepo, pnpm workspaces, Nx, Bun workspaces, or N/A]
- **Package Graph & Directory Map**:
  - `apps/web`: Next.js frontend application (`@repo/web`)
  - `apps/api`: Backend API service (`@repo/api`)
  - `packages/db`: Database client, migrations, and Drizzle/Prisma schemas (`@repo/db`)
  - `packages/ui`: Shared design system and Tailwind components (`@repo/ui`)
  - `packages/auth`: Shared authentication utilities and session policies (`@repo/auth`)

- **Scoped Workspace Commands (`--filter`)**:
  - **Dev Specific App**: `pnpm --filter web dev` (or `turbo run dev --filter=web`)
  - **Test Specific Package**: `pnpm --filter @repo/db test` (or `turbo run test --filter=@repo/db`)
  - **Typecheck Package**: `pnpm --filter web typecheck`
  - **Build Specific Target**: `pnpm --filter web build` (or `turbo run build --filter=web...`)

- **Strict Architectural Import Boundaries**:
  - [ ] **Presentation Isolation**: `packages/ui` must never import from application targets (`apps/*`) or server-only packages (`packages/db`).
  - [ ] **Client / Server Boundary**: Client components in `apps/web` (`"use client"`) must never import directly from `@repo/db` or internal server secrets.
  - [ ] **Public Package Exports Only**: Never reach across workspace boundaries using relative deep paths (for example `../../packages/db/src/internal.ts`). Always consume packages through exports declared in their `package.json` (`@repo/db`).
  - [ ] **Workspace Protocol**: Inter-package dependencies must declare explicit workspace protocols in `package.json` (e.g. `"@repo/ui": "workspace:*"`).

---

## 5. Active MCP Capabilities (Optional)
> Record detected or configured Model Context Protocol (MCP) servers (via Docker Desktop MCP, stdio `npx`, or native client configs). PromptKit OS follows a **Progressive Enhancement** model: MCP tools serve as optional accelerators. When available, assistants prioritize native MCP tool calls; when unavailable, assistants seamlessly fall back to structured Markdown and terminal CLI commands with zero errors.

- **Reasoning / Scratchpad MCP**: [e.g. `sequential-thinking` (`@modelcontextprotocol/server-sequential-thinking`) for `pk:debug` hypothesis branching & `pk:plan` tradeoffs | N/A]
- **Documentation / Web Reader MCP**: [e.g. `fetch` (`@modelcontextprotocol/server-fetch`) or Jina reader for clean primary doc lookups | N/A]
- **Task Tracking System**: [Local Markdown (docs/tasks/ + docs/STATE.md) | GitHub Issues | Linear | Jira]
- **GitHub MCP**: [e.g. `github-mcp-server` for PR creation, issue reading, commit search | N/A]
- **Database MCP**: [e.g. `postgres-mcp` or `sqlite-mcp` for read-only schema discovery & `pk:migrate` checks | N/A]
- **Browser / UI MCP**: [e.g. `playwright` for `pk:design` visual and E2E verification | N/A]
- **Execution Precedence**: Native MCP Tools $\rightarrow$ Native IDE Search/Edit Tools $\rightarrow$ Terminal CLI Commands $\rightarrow$ Structured Markdown Fallback

---

## 6. Documentation & Artifact Storage Paths
All artifacts generated by PromptKit workflows must be saved to these host project paths:
- **Architectural Decision Records (ADRs)**: `docs/adrs/`
- **Technical RFC Specs**: `docs/specs/`
- **Incident Post-Mortems (RCAs)**: `docs/rca/`
- **Technical Spikes & Benchmarks**: `docs/spikes/`
- **Design Tokens & UI Specs**: `docs/design/`
- **Data Models & Schemas**: `docs/data/`
- **Authentication & RBAC Matrices**: `docs/auth/`
- **API Contracts & Envelopes**: `docs/api/`
- **Test Strategy & Plans**: `docs/tests/`
- **Release Checklists & Reports**: `docs/releases/`

### Standard Root Documentation (Optional / Detected)
> Pre-existing repository documentation detected during `pk:onboard` or `context-sync`. PromptKit respects these as authoritative references. Set to `N/A` if not present.
- **Architecture Blueprint**: [e.g. `./ARCHITECTURE.md` or N/A]
- **Strategic Roadmap**: [e.g. `./ROADMAP.md` or N/A]
- **Operations Runbook**: [e.g. `./RUNBOOK.md` or `./OPERATIONS.md` or N/A]
- **Code Style Guide**: [e.g. `./STYLE.md` or `./STYLEGUIDE.md` or N/A]

---

## 7. Non-Negotiable Architecture Rules & Guardrails
- [ ] **Zero `any` / Loose Casting**: Strict TypeScript at all times. Use Zod/Valibot schemas for boundary parsing.
- [ ] **No Business Logic in UI**: Presentation components only render props and dispatch intents; business logic lives in domain hooks or service layers.
- [ ] **Database Invariants First**: Foreign keys, unique constraints, and check constraints live in the database schema, not just application code.
- [ ] **WCAG 2.2 AA Compliance**: All interactive elements must support keyboard navigation, visible focus rings, and proper ARIA labels.
- [ ] **Deterministic Error Handling**: No silent `catch {}` blocks. Use typed `Result<T, E>` or centralized error boundaries.
- [ ] **Anti-Slop & Structured Scannable Output**: Output all status updates, plans, and diffs in structured scannable markdown (tables, checklists, short bullets). Prohibit long narrative conversational essays.
- [ ] **Absolute Secret Hygiene & `.env.example`**: Never paste, expose, or request secrets, API keys, or credentials in chat. Maintain `.env.example` with placeholder keys and instruct developers to manage `.env` locally.
- [ ] **Context Window Reset Threshold (~30 Turns)**: When conversation approaches ~30 turns or high token saturation, run `pk:checkpoint` to synchronize `docs/STATE.md` and recommend continuing in a fresh session via `pk:route`.
- [ ] **Standardized Human Action Callouts**: When terminating a turn that requires user decision, approval, or local action (e.g. merging PR, editing `.env`), terminate with a high-contrast `> [!IMPORTANT]` block titled `### 🛑 Action Required From You:`. If blocked, terminate with `> [!WARNING]` titled `### ⚠️ Blocked: Waiting on Human Input`.
- [ ] **Strict Milestone Git Boundaries**: Never start a new milestone or major task phase with an uncommitted or dirty working tree. Upon completing a milestone, run test verification, prompt for or execute atomic staging (`pk:commit`), update `docs/STATE.md`, and obtain human confirmation with `> [!IMPORTANT]` before proceeding.
<!-- Optional: Uncomment if using GitHub Issues or external issue tracker -->
<!-- - [ ] **Issue Tracker Synchronization**: Decompose all feature milestones and bugs into atomic issues with Gherkin AC via `pk:tasks` before active coding. Commits must reference issue IDs (`Closes #N`). -->
