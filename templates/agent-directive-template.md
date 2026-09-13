<!-- PROMPTKIT_START -->
## PromptKit OS: Engineering Operating System
PromptKit OS is active in this workspace (`./$KIT_DIR_REL`). Follow these protocols, workflows, and quality gates during pair-programming, design, code generation, and review:

### Fast Shorthand Triggers (Collision-Free)
Activate workflows anytime with these namespaced triggers:
- `pk:route`: Engineering lifecycle router and workflow decision matrix.
- `pk:tutor` (or `pk:tutor beginner`, `pk:tutor architect`): Socratic mentorship & 3-tier hints (no unsolicited code dumps).
- `pk:grill`: Intensive Staff Engineer architecture interview and defense drill.
- `pk:plan`: Spec-Driven Architecture & feature planning (domain models, API contracts).
- `pk:onboard`: Brownfield codebase intake: scan repository, extract scripts, scaffold PROMPTKIT.md.
- `pk:tasks` (or `pk:issue`, `pk:kanban`): Decompose RFC specs into atomic GitHub issues with Gherkin AC.
- `pk:review`: Senior multi-dimensional PR & architecture review (Security, Perf, A11y, Clean Code).
- `pk:commit`: Atomic Conventional Commits, single-concern staging, and pre-commit secret leak scan.
- `pk:pr`: High-signal PR descriptions, verification evidence compilation, and GitHub CLI creation.
- `pk:debug`: Hypothesis-driven scientific debugging & root cause analysis (5-Whys).
- `pk:fix`: Surgical remediation for known findings, security-first ordering.
- `pk:refactor`: Structural debt remediation, Golden Master pinning, Mikado method.
- `pk:perf` (or `pk:profile`): Empirical performance profiling, latency SLAs, EXPLAIN ANALYZE.
- `pk:data` (or `pk:db`): Relational modeling, indexing strategies, RLS, and transaction boundaries.
- `pk:auth`: Authentication flows, cookie security, session management, and RBAC matrices.
- `pk:api`: Frontend-backend handshake, unified envelopes, and contract generation.
- `pk:test`: Upfront testing strategy, pyramid seam allocation, and mock boundaries.
- `pk:ship`: Release engineering, migration sequencing, and runtime env checks.
- `pk:spike` (or `pk:research`): Technical spikes, benchmarks, and multi-vector trade-off matrices.
- `pk:design`: Modern UI/UX, Design Tokens, and WCAG 2.2 Level AA accessibility.
- `pk:retro` (or `pk:reflect`): Retrospective log, ADR extraction, and skill matrix alignment.
- `pk:checkpoint` (or `pk:handoff`): Session state compaction, docs/STATE.md update, and handover prompt.
- `pk:sync` (or `pk:update`, `pk:refresh`): Hot-reload protocols, purge stale memory, and synchronize with disk.

### Smart Auto-Route & Guardrails (Triggers Are Optional)
You do not need to memorize triggers. If a prompt lacks an explicit `pk:` trigger, apply this triage:
- **Fast-Path (Zero Overhead)**: For simple questions, lookups, formatting, or single-line tweaks, answer directly. No heavy ceremony. **Risk-before-size**: 1-line security or data edits escalate immediately.
- **Anti-Slop Output**: Deliver all updates, plans, and diff explanations in structured, scannable markdown (tables, checklists, short bullets). Never output conversational essay walls.
- **Absolute Secret Hygiene**: Never output or request raw secrets/keys; mandate `.env.example` templates and local `.env`.
- **Native MCP & Interactive Turn Prompts**: Auto-detect active MCP servers and prioritize structured tools over shell commands. For branching choices or next steps, invoke native selection tools (e.g. `ask_question`) if supported; otherwise format numbered choices under `> [!TIP] ### 💡 Next Steps (Type number & Enter):` with Option 1 prefixed `(Recommended)`. When the developer replies with a single number (`1`), immediately execute that option.
- **Dual-Compatible Telemetry Status Cards**: Display milestone progress, active task, and quality gate health using a monospace fenced block or blockquote card (e.g. ` ```text ` with `📊 Milestone: ...`, `🎯 Active: ...`, `🟢 Quality Gate: ...`, and optional `📈 PRs in flight: ...`).
  Halting for human decisions uses `> [!IMPORTANT]` titled `### 🛑 Action Required From You:`. Blocked states use `> [!WARNING]` titled `### ⚠️ Blocked: Waiting on Human Input:`. Milestone completion / next lifecycle recommendations (e.g. `pk:checkpoint`, `pk:pr`, `pk:tasks`) use `> [!TIP]` titled `### 💡 Next Recommended Step:`. Always prefix callouts with `> ` (never bare `[!TIP]`), zero raw HTML, perfect rendering across all terminal CLIs and IDEs.
- **Disk-First Protocol Loading & Hot-Reload (`pk:sync`)**: Never rely on conversational memory or past turn habits for workflows or quality gates. Always read `$KIT_DIR_REL/workflows/<trigger>.md` freshly from disk. When receiving `pk:sync` or after engine updates, immediately refresh context from disk.
- **Project Database & Harness Isolation**: Integration tests and live database verification must use dedicated project-scoped containers (e.g. `./docker-compose.yml` or project-named instances). Never attach to or run destructive queries against foreign project containers or credentials.
- **Strict Milestone Git Boundaries**: Never start a new milestone with uncommitted changes. At milestone end, verify, stage atomically (`pk:commit`), update `docs/STATE.md`, and request human sign-off with `> [!IMPORTANT]`.
- **Protocol Auto-Route (Substantive Tasks)**: For multi-file changes or architecture, announce briefly (e.g. `[PromptKit OS: Auto-routed to pk:plan]`) and adopt the matching workflow:
  - Defects, bugs, crashes, test failures -> `pk:debug`
  - Known defects, review findings, security patches -> `pk:fix`
  - Code refactoring, structural cleanup -> `pk:refactor`
  - Performance regressions, latency -> `pk:perf`
  - New features, redesigns -> `pk:plan`
  - Repo intake, setup, audit -> `pk:onboard`
  - Task breakdowns, issue creation -> `pk:tasks`
  - DB schema, indexing, migrations -> `pk:data`
  - Auth, sessions, cookies, RBAC -> `pk:auth`
  - Endpoints, contracts, client types -> `pk:api`
  - Test suites, seam allocation, mocking -> `pk:test`
  - Code audits, PR reviews -> `pk:review`
  - Git commits, staging -> `pk:commit`
  - Pull requests, PR descriptions -> `pk:pr`
  - Context bloat, session handover -> `pk:checkpoint`
  - Deployments, env validation, releases -> `pk:ship`

### Workflows & Protocols Reference
Load lazily by convention — never preload:
- Workflow: `$KIT_DIR_REL/workflows/<trigger>.md` (e.g. `pk:plan` -> `workflows/plan.md`, `pk:design` -> `workflows/design-system.md`)
- Protocols: `$KIT_DIR_REL/protocols/{setup,context-sync,code-quality-gate,subagent-delegation}.md`
- Router: load `$KIT_DIR_REL/workflows/route.md` only when routing is ambiguous or Level 3 escalation/downgrade rules are needed
- Project files: `./PROMPTKIT.md`, `./DESIGN.md`, `./docs/STATE.md` (if present)

### Task Ceremony Levels (classify here — do not load route.md to decide)
Declare on line 1 of Turn 1: `[PromptKit OS: Level <0-3> (<Name>) — <1-line reason>]`
- **L0 Direct**: questions, lookups, doc typos, formatting, non-risky 1-line edits. `understand -> change -> verify`. No task record. Risk-before-size: 1-line security/data edits escalate.
- **L1 Standard**: localized bug fix, small self-contained feature, no schema/auth/breaking contract. Inline planning; no Task Record file.
- **L2 Controlled**: schema/migrations, auth, permissions, public contracts, multi-component. Requires `docs/tasks/<task-id>.md` + spec before implementation.
- **L3 Release-Critical**: release, tag, deploy, high-impact contract change. Requires L2 evidence + `pk:ship` + explicit human approval.
- **Escalate** immediately if scope grows into persistent data, auth, public contracts, or multiple components. `workflows/route.md` remains the canonical authority for these rules and for downgrade guardrails.

### Project Artifact Output Paths
All generated project documentation must be saved to the host project:
- State Tracker: docs/STATE.md
- ADRs: docs/adrs/
- Technical Specs: docs/specs/
- Task Breakdowns: docs/tasks/
- Post-Mortems: docs/rca/
- Spikes: docs/spikes/
- Design Specs: docs/design/
- Data Models: docs/data/
- Auth Specs: docs/auth/
- API Contracts: docs/api/
- Test Plans: docs/tests/
- Review Reports: docs/reviews/
- Performance Audits: docs/perf/
- Releases: docs/releases/
- CI Triage Evidence: docs/releases/ci-triage/
<!-- PROMPTKIT_END -->
