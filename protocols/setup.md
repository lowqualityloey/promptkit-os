# Universal Agent Setup Protocol

## Purpose
Ensure any modern AI coding assistant or CLI (Antigravity, Claude Code, Gemini CLI, Cursor, Windsurf, GitHub Copilot, Aider, Roo Code) is equipped with PromptKit OS workflows, protocols, and senior engineering standards by updating the appropriate root briefing configuration file.

---

## Supported AI Ecosystem Files

| Assistant / Environment | Configuration Target File |
| :--- | :--- |
| **Claude Code** | `CLAUDE.md` |
| **Gemini CLI / Antigravity** | `GEMINI.md` or `AGENTS.md` |
| **Cursor IDE** | `.cursorrules` or `.cursor/rules/promptkit.mdc` |
| **Windsurf IDE** | `.windsurfrules` |
| **GitHub Copilot** | `.github/copilot-instructions.md` |
| **Aider / Open-Source Agents** | `CONVENTIONS.md` or `AGENTS.md` |

---

## Preconditions
1. PromptKit OS is located in `.promptkit/` (recommended) or `promptkit/` relative to the workspace root.
2. Standard shell utilities or file tools are available.

If no known agent configuration file exists in the repository root, create `AGENTS.md` as the universal standard fallback.

---

## Execution Steps

### 1. Identify Workspace & Configuration Files
Inspect the repository root for existing agent configuration files:
- Check for: `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `.cursorrules`, `.cursor/rules/`, `.windsurfrules`, `.github/copilot-instructions.md`.
- If none exist, default to creating `./AGENTS.md`.

### 2. Verify Existing Integration
Check if the target configuration file already contains `PromptKit OS: Engineering Operating System` or `<!-- PROMPTKIT_START -->`:
- If the configuration is already present and up to date, report status to the developer and transition immediately to active session mode.
- If missing or outdated, proceed to Step 3.

### 3. Ensure Project Documentation Directories Exist
Ensure the host repository contains documentation directories so generated artifacts are tracked by Git:
- `docs/adrs/`: Architectural Decision Records
- `docs/specs/`: Technical RFC Specifications
- `docs/rca/`: Root Cause Analysis Incident Post-Mortems
- `docs/spikes/`: Technical Spikes & Benchmarks
- `docs/design/`: Design Token Specs & UI Architecture
- `docs/data/`: Database Models & Schema Specifications
- `docs/auth/`: Authentication & Authorization Matrices
- `docs/api/`: API Contracts & Error Specifications
- `docs/tests/`: Test Plans, Seam Allocations & Test Matrices
- `docs/perf/`: Performance Audits, Query Execution Plans & Profiling Reports
- `docs/tasks/`: Task Breakdowns, Issue Drafts & Milestone Trackers
- `docs/releases/`: Release Checklists, Rollback Decision Logs & Verification Reports

If `PROMPTKIT.md` does not exist in the project root, copy `.promptkit/templates/project-profile-template.md` to `./PROMPTKIT.md` for project-specific rules and commands. If `DESIGN.md` is desired for custom visual identity, copy `.promptkit/templates/design-profile-template.md` to `./DESIGN.md`. If `docs/STATE.md` does not exist, copy `.promptkit/templates/state-tracker-template.md` to `./docs/STATE.md` for living project state tracking.

### 4. Inject PromptKit Core Directives
Append or merge the exact contents of `templates/agent-directive-template.md` into the detected configuration file(s). Do not hardcode the markdown here. `templates/agent-directive-template.md` is the single source of truth for the injected block. Replace `$KIT_DIR_REL` in the template with the relative path to the `.promptkit` repository (e.g. `.promptkit`).

### Progressive Loading Policy
To optimize context window efficiency and minimize token overhead, agents must follow this progressive loading sequence:
1. **Initial context**: Load setup/entry guidance. Classify the task using the Task Ceremony Levels table in the injected directive — do not load `.promptkit/workflows/route.md` for classification. Load `route.md` only when routing is genuinely ambiguous, or when Level 3 escalation / downgrade guardrails are needed.
2. **After routing**: Load only the workflow or workflows relevant to the routed task.
3. **Artifact-on-demand**: Load templates only when required by the routed level or workflow.
4. **Level-specific behavior**:
   - **Level 0 (Direct)**: Direct execution and verification; do not load formal planning, release, CI, or artifact templates.
   - **Level 1 (Standard)**: Minimal loading path. Load relevant implementation/test/debug workflow; use inline planning; do not load Task Record (`docs/tasks/<task-id>.md`) or release material.
   - **Level 2 (Controlled)**: Load relevant planning/risk workflows and required Task Record/template material.
   - **Level 3 (Release-Critical)**: Load Level-2 material plus release-evidence and `pk:ship` guidance.
5. **Explicit request exception**: Load additional material when the developer explicitly asks for it.

Progressive loading is an instruction-efficiency policy to conserve context, not a runtime guarantee or hidden enforcement mechanism.

Persistent memory is not policy: setup and reinjection must not import session learnings as project rules. Follow the Memory vs Policy Boundary in `protocols/context-sync.md` §3.1; candidate notes remain non-authoritative until explicit human approval, and existing scoped document authorities remain unchanged.

### Workflows & Protocols Reference
- **Route**: `.promptkit/workflows/route.md`
- **Tutor**: `.promptkit/workflows/tutor.md`
- **Plan**: `.promptkit/workflows/plan.md`
- **Onboard**: `.promptkit/workflows/onboard.md`
- **Tasks**: `.promptkit/workflows/tasks.md`
- **Review**: `.promptkit/workflows/review.md`
- **Commit**: `.promptkit/workflows/commit.md`
- **Pull Request**: `.promptkit/workflows/pr.md`
- **Debug**: `.promptkit/workflows/debug.md`
- **Performance**: `.promptkit/workflows/perf.md`
- **Data**: `.promptkit/workflows/data.md`
- **Auth**: `.promptkit/workflows/auth.md`
- **API**: `.promptkit/workflows/api.md`
- **Test**: `.promptkit/workflows/test.md`
- **Ship**: `.promptkit/workflows/ship.md`
- **Research**: `.promptkit/workflows/research.md`
- **Design System**: `.promptkit/workflows/design-system.md`
- **Reflect**: `.promptkit/workflows/reflect.md`
- **Checkpoint**: `.promptkit/workflows/checkpoint.md`
- **Profile**: `.promptkit/workflows/profile.md`
- **Quality Gate (DoD)**: `.promptkit/protocols/code-quality-gate.md`
- **Context Sync**: `.promptkit/protocols/context-sync.md`
- **Subagent Delegation**: `.promptkit/protocols/subagent-delegation.md`
- **Discovery Intake**: `.promptkit/protocols/discovery-intake.md`
- **Telemetry Cards**: `.promptkit/protocols/telemetry-cards.md`

> Note: `templates/agent-directive-template.md` intentionally lists only the four always-needed protocols and omits `discovery-intake.md`, which is lazy-loaded via `workflows/onboard.md` Phase 0 and `workflows/plan.md` Step 0. This keeps the static directive under the 2500-token Balanced budget (currently 2495/2500).
- **Project Profile & Rules**: `./PROMPTKIT.md` (if present)
- **Visual Identity & Brand**: `./DESIGN.md` (if present)
- **Living State & Tracker**: `./docs/STATE.md` (if present)

### Project Artifact Output Paths
All generated project documentation must be saved to the host project:
- State Tracker: `docs/STATE.md`
- ADRs: `docs/adrs/`
- Technical Specs: `docs/specs/`
- Task Breakdowns: `docs/tasks/`
- Post-Mortems: `docs/rca/`
- Spikes: `docs/spikes/`
- Design Specs: `docs/design/`
- Data Models: `docs/data/`
- Auth Specs: `docs/auth/`
- API Contracts: `docs/api/`
- Test Plans: `docs/tests/`
- Performance Audits: `docs/perf/`
- Releases: `docs/releases/`
<!-- PROMPTKIT_END -->
```

### 5. Initialize Context & Welcome Developer
After updating configuration:
1. Run `.promptkit/protocols/context-sync.md` to detect active technologies, inspect `./PROMPTKIT.md`, and check recent git status.
2. Ask the developer which workflow they wish to activate:
   - `[pk:route]`: Navigate workflows using the engineering lifecycle decision matrix.
   - `[pk:tutor]`: Explore a concept, debug together, or build mental models.
   - `[pk:plan]`: Design an architecture, draft an RFC/spec, or break down a feature.
   - `[pk:onboard]`: Ingest an existing codebase and generate a tailored PROMPTKIT.md.
   - `[pk:tasks]`: Decompose specs into atomic issues with Gherkin AC and GitHub Projects sync.
   - `[pk:review]`: Conduct a Senior-level code & architecture audit on recent changes.
   - `[pk:commit]`: Stage atomic changes, scan for secret leaks, and format Conventional Commits.
   - `[pk:pr]`: Compile high-signal pull request descriptions, verification evidence, and safe rollback plans.
   - `[pk:debug]`: Perform systematic root cause analysis on a defect.
   - `[pk:perf]`: Profile latency, run EXPLAIN ANALYZE, isolate bottlenecks, and verify performance deltas.
   - `[pk:data]`: Design relational schemas, indexes, and RLS policies.
   - `[pk:auth]`: Architect authentication, cookies, and RBAC matrices.
   - `[pk:api]`: Define frontend-backend contracts and error envelopes.
   - `[pk:test]`: Define upfront testing strategy, pyramid seam allocation, and mock boundaries.
   - `[pk:ship]`: Execute release checklist, runtime env checks, zero-downtime migration, and rollback plan.
   - `[pk:spike]`: Run a technical spike comparing libraries/patterns.
   - `[pk:design]`: Design accessible UI components with modern tokens.
   - `[pk:retro]`: Run a retro on completed work, capture insights, and generate ADRs.
   - `[pk:checkpoint]`: Compress active session context and generate a handover prompt for a fresh chat.

---

### Post-Setup Guidance: The 3-Step Day 1 Experience
1. **Initialize**: Run `./.promptkit/init.sh` (or `.\.promptkit\init.ps1` on Windows) to scaffold `./docs/`, `./PROMPTKIT.md`, and inject root agent directives.
2. **Inspect `PROMPTKIT.md`**: Review or customize project-specific commands, test runners, and architectural invariants in `./PROMPTKIT.md` (or run `pk:onboard` for passive stack discovery).
3. **Prompt Task**: Start pairing by prompting your task naturally or invoking a workflow (`pk:route`, `pk:debug`, `pk:plan`). The assistant declares its ceremony level upfront and proceeds with lightweight or controlled execution.

---

### Visual Callout Standards for Human Actions
To eliminate ambiguity and prevent pairing deadlocks, assistants must use standardized GitHub-Flavored Markdown Alerts at the end of turns requiring human attention:

#### 1. Human Action Required (`> [!IMPORTANT]`)
When halting for user decisions, code review, merge approval, or local credential setup:
```markdown
> [!IMPORTANT]
> ### 🛑 Action Required From You:
> - **[Decision / Task]**: [Concise, concrete explanation of decision or command needed]
```

#### 2. Blocked / Waiting on Input (`> [!WARNING]`)
When halted due to environment errors, missing credentials, or unresolvable test blockers:
```markdown
> [!WARNING]
> ### ⚠️ Blocked: Waiting on Human Input
> - **[Blocker]**: [Specific missing key, access right, or decision needed to resume]
```

---

### MCP Progressive Enhancement & Tool Precedence Matrix
When operating in AI development environments with Model Context Protocol (MCP) server support, assistants prioritize structured, tool-native interactions over terminal CLI execution or text approximations:

| Capability Domain | 1. Native MCP Tool (Highest Priority) | 2. Native IDE Tool (Second Priority) | 3. Terminal CLI (Fallback) | 4. Manual Human Prompt |
| :--- | :--- | :--- | :--- | :--- |
| **Source Control & PRs** | `github-mcp` (`create_pull_request`, `issue_read`, `issue_write`, `list_commits`) | N/A | `gh pr create`, `gh issue view`, `git` | Asking developer to open PR manually |
| **Database Discovery** | `postgres-mcp` / DB MCP (`query`, `list_tables`, `describe_table`) | N/A | `psql`, `sqlite3`, ORM migration CLI | Asking developer for table schemas |
| **Interactive Selection** | Modal Prompt / `ask_question` / prompt picker modal | Native IDE UI Pickers | Terminal CLI input / raw prompt | Free-form conversational text |
| **Codebase Search** | N/A | `grep_search`, `find_by_name`, `file_search` | `rg`, `grep`, `find`, `fd` | Asking developer for file paths |
| **File Manipulation** | N/A | `view_file`, `replace_file_content`, `write_to_file` | `cat`, `sed`, `awk`, shell redirection | Asking developer to edit code |
| **Diagnostics & Type Integrity** | `lsp-mcp` (`textDocument/diagnostic`, `hover`, `references`) | Native IDE diagnostics panel | `tsc --noEmit`, `biome check`, `eslint` (JSON output) | Manual reviewer inspection |

#### Degradation & Progressive Enhancement Rules
1. **Detect MCP Capabilities**: Assistants inspect available MCP tools at session start.
2. **Graceful Degradation**: If an MCP tool is not configured in the host environment or fails due to missing daemon/connectivity, immediately and silently fall back to Native IDE tools or Terminal CLI commands.
3. **Never Block on Missing MCP**: MCP tooling is a progressive enhancement, never a hard barrier to workflow execution.
4. **Never Block on Missing LSP**: Language-server diagnostics are a progressive enhancement. When no LSP bridge or editor language server is available, assistants fall back to the typecheck and lint commands declared in `PROMPTKIT.md` and record unmeasured evidence as `not measured`.

---

## Completion Criteria
- Root agent file (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, or `.cursorrules`) contains valid PromptKit OS pointers.
- Project `docs/` directories are initialized.
- The assistant is oriented to use `pk:` triggers, Socratic rules, and senior engineering workflows.
