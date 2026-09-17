# Architecture & Operating Model

How the assistant operates, how enforcement works, the full command reference, and the repository layout. Relocated from the README so the front door stays short; no claim changed.

---

## Operating Model

### Subagent Delegation & Sandboxed Worktree Isolation

In multi-agent environments (Antigravity, Claude Code, Cursor background agents), the assistant follows [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md):
- **Offloaded to Subagents**: Multi-candidate architectural benchmarks (`pk:spike`), dual-axis PR reviews (`pk:review`), brownfield codebase surveys (`pk:onboard`), and codebase scans touching >3 files.
- **Retained in Main Thread**: Direct developer conversation, small localized edits (<10 lines), atomic commits (`pk:commit`), and pull request submission (`pk:pr`).
- **Compact Synthesis**: Subagents return 5-15 line synthesized reports with file paths and line numbers instead of dumping raw tool output into parent context.
- **Sandboxed Worktree Execution**: For concurrent subagents or experimental feature spikes, agents can create disposable, isolated worktrees using `scripts/isolate-worktree.sh` (or `scripts/isolate-worktree.ps1`) to prevent dirtying or conflicting with the primary working tree.

### Native MCP Discovery & Graceful Degradation

- **Tooling Precedence**: Native MCP Tools $\rightarrow$ Terminal CLI Commands $\rightarrow$ Manual Human Prompt.
- **Auto-Discovery**: When running in MCP-capable environments (Antigravity, Cursor, Claude Desktop), the assistant automatically prioritizes structured tool calls (e.g., `github-mcp-server`) over terminal commands (`gh`), preventing terminal pager hangs.
- **Host Capability & Progressive Enhancement**: Structured MCP tool discovery is a progressive enhancement dependent on host MCP runtime support. If no MCP servers are configured or supported by the host, the assistant gracefully falls back to standard terminal CLI utilities.

### Dual-Compatible Telemetry Status Cards & Visual Callouts

- **Structured Telemetry Status Cards**: When completing tasks, checkpoints, or PR workflows, the assistant displays a clean, monospace fenced status card (immune to Markdown formatting collisions) or blockquote card:
  ````markdown
  ```text
  📊 Milestone: M2: Core Features — open=7 / closed=5 -> 6/6 after #42 merge
  🎯 Active: TASK-04 PR #42 (Tenant CRUD and RLS isolation)
  🟢 Quality Gate: Clean (lint 0 · typecheck 0 · 435 tests ✓ · 🔒 7 Invariants)
  📈 PRs in flight: #42 open, 0 blocked
  ```
  ````
- **Zero Action-Blindness**: Whenever the assistant halts a turn requiring human decisions, PR review, or local actions, it terminates the message with a high-contrast `> [!IMPORTANT]` callout (`### 🛑 Action Required From You:`). If blocked, it emits `> [!WARNING]` (`### ⚠️ Blocked: Waiting on Human Input`).
- **Opt-out**: set `status-cards: off` in `PROMPTKIT.md` to suppress the decorative card (default `on`; halts still fire).
- **Spend field**: completions may append `> 💰 Spend: <in> / <out> (source: host usage)` when the host exposes per-turn usage (omitted when unmeasured or trivial).
- **Quiet completion**: when `docs/STATE.md` shows nothing pending, the turn ends with `All milestones closed — nothing pending.` instead of a Next-Step recommendation — independent of the card opt-out. `COMPLETED` status seals the project with a closeout record (measured vs estimated spend, gates held) in `docs/STATE.md`.
- **Dual-Compatibility & Markdown Parser Hygiene**: Status cards and callouts render as clean bordered accent blocks in terminal CLIs (OpenCode, Claude Code) and rich alert cards in web IDEs and DeepSeek harnesses. All callouts strictly use the `> [!TYPE]` blockquote syntax to prevent raw unrendered bracket leakage across Markdown renderers.

### Interactive Decision Handoffs

- **Native Selection Modals**: When concluding a task, workflow milestone, or decision point, the assistant executes the host's native interactive selection tool (e.g. OpenCode prompt picker, `ask_question`) as your final tool call of the turn with `(Recommended)` prefixing Option 1. Bounded to closed-set operational choices: for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead — see the Picker routing rule in `workflows/plan.md`.
- **Fast Keyboard Navigation**: Renders an interactive menu right in your chat/terminal interface where you can navigate with arrow keys, press `Enter` for 1-key confirmation, or type custom input instead of staring at a blank prompt.

---

## Enforcement Model & CI

PromptKit is an instruction layer, not a compiler, sandbox, runtime orchestrator, or live-generation timer. Its controls have different authorities:

1. **Protocol guidance**: Workflows classify work, require readiness, define checkpoints, and preserve ownership boundaries.
2. **Optional host gating**: IDE hooks or host controls may provide prompts or tool gating when available, but capability varies by host.
3. **Durable Markdown records**: Task, checkpoint, handoff, scope-change, and evidence records preserve what happened and what must happen next.
4. **Local and CI validation**: Reference checks and execution-control validators test durable repository evidence. They are read-only and cannot observe live chat duration or forcibly terminate generation.
5. **Human approval**: People remain authoritative for scope exceptions, commits, pull requests, tags, releases, publication, deployment, and rollback.

A passing validator or CI job proves only that the recorded evidence is internally consistent. It never approves a version, authorizes a remote action, or replaces review by the owning workflow and human decision-maker.

> [!NOTE]
> PromptKit makes AI assistants **systematic and disciplined**, not mechanically deterministic. Think of it as engineering standards for a junior developer: they follow the playbook most of the time, but you still review their PRs.

### Continuous Integration & Automated Validation

Repository CI validates structural integrity and protocol compliance across Linux (Bash) and Windows (PowerShell) environments:

- **Script Syntax & Quality**: Validates Bash (`bash -n`) and PowerShell syntax for setup and validation scripts.
- **Initialization Safety & Idempotency**: Tests `init.sh` and `init.ps1` to ensure non-destructive directive updates and safe error handling on malformed markers.
- **Documentation-Contract Tests**: Executes scenario suites asserting the shipped prompt text (Level 0–3 classification, fast-path rules, Expand-Contract policy, router consistency) via string-level checks. They verify the contracts exist as specified, not that a live host complied at runtime.
- **Execution-Control Fixtures**: Validates task and state tracker schema formatting, evidence references, and handoff contracts.
- **CI-Triage Fixtures**: Tests failure classification, remediation tracking, and diagnostic record structures.
- **Release Record Validation**: Ensures strict schema and evidence linkage compliance for release evaluation records.
- **Reference & Structural Validation**: Scans all workflow files, templates, protocols, and activities for valid cross-document links and template completeness.

---

## Command Reference

All triggers use the `pk:` prefix to avoid collisions with native slash commands in Antigravity or Cursor:

| Command | Workflow File | Status | Output Target | Description |
| :--- | :--- | :--- | :--- | :--- |
| `pk:route` | [`workflows/route.md`](../workflows/route.md) | Core 🧪 | Conversation | Interactive lifecycle decision matrix and workflow triage. |
| `pk:tutor` | [`workflows/tutor.md`](../workflows/tutor.md) | Core 🧪 | Conversation | Socratic mentorship using 3-tier hints; guides without dumping code. |
| `pk:grill` | [`workflows/tutor.md`](../workflows/tutor.md) (alias) | Core 🧪 | Conversation | Architecture defense drill implemented via `tutor.md`. |
| `pk:plan` | [`workflows/plan.md`](../workflows/plan.md) | Core 🧪 | `docs/specs/` | Spec-driven architecture with MVP floor (every part traces to a stated requirement, rest to the Later ledger), module depth, and zero-downtime migrations. |
| `pk:onboard` | [`workflows/onboard.md`](../workflows/onboard.md) | Core | `PROMPTKIT.md`, `docs/STATE.md` | Project intake: greenfield discovery interview (bounded, size-classed) or brownfield stack scan; scaffolds guardrails. |
| `pk:tasks` | [`workflows/tasks.md`](../workflows/tasks.md) | Core 🧪 | `docs/tasks/` or `gh` | Decomposes specs into atomic 1-4h tasks with Gherkin AC. |
| `pk:data` | [`workflows/data.md`](../workflows/data.md) | Core 🧪 | `docs/data/` | Schema design, composite indexing, RLS policies, and migrations. |
| `pk:auth` | [`workflows/auth.md`](../workflows/auth.md) | Core 🧪 | `docs/auth/` | Cookie security flags, OAuth PKCE flows, and RBAC/ABAC capability matrix. |
| `pk:api` | [`workflows/api.md`](../workflows/api.md) | Core | `docs/api/` | Contract envelopes, cursor pagination, and mutation idempotency. |
| `pk:test` | [`workflows/test.md`](../workflows/test.md) | Core | `docs/tests/` | Testing pyramid seam allocation, data factories, and monorepo `--filter`. |
| `pk:design` | [`workflows/design-system.md`](../workflows/design-system.md) | Core | `docs/design/` | Anti-slop UI tokens, WCAG 2.2 AA accessibility, and mobile ergonomics. |
| `pk:spike` | [`workflows/research.md`](../workflows/research.md) | Core | `docs/spikes/` | Technical risk spikes comparing options against a boring baseline. |
| `pk:debug` | [`workflows/debug.md`](../workflows/debug.md) | Core 🧪 | `docs/rca/` | Scientific debugging: fast reproduction loop, tagged logs, and 5-Whys. |
| `pk:fix` | [`workflows/fix.md`](../workflows/fix.md) | New 🧪 | Code repair | Surgical remediation of known findings with security-first ordering. |
| `pk:refactor` | [`workflows/refactor.md`](../workflows/refactor.md) | Core 🧪 | Code modernization | Structural debt remediation: Golden Master pinning, Mikado method, Strangler Fig. |
| `pk:perf` | [`workflows/perf.md`](../workflows/perf.md) | Core | `docs/perf/` | Baseline quantification, EXPLAIN ANALYZE, flamegraphs, and deltas. |
| `pk:review` | [`workflows/review.md`](../workflows/review.md) | Core | Review report | Two-axis review: Spec Fidelity vs Technical Standards (Fowler's smells). |
| `pk:commit` | [`workflows/commit.md`](../workflows/commit.md) | Core | Git history | Atomic Conventional Commits, single-concern staging, and secret scanning. |
| `pk:pr` | [`workflows/pr.md`](../workflows/pr.md) | Core | PR body / `gh pr` | Pull request descriptions with test evidence and rollback procedures. |
| `pk:ship` | [`workflows/ship.md`](../workflows/ship.md) | Core 🧪 | `docs/releases/` | Runtime env validation (Zod/T3), migration ordering, and smoke tests. |
| `pk:checkpoint` | [`workflows/checkpoint.md`](../workflows/checkpoint.md) | Core | `docs/STATE.md` | Session compaction, invariant locking, and fresh chat handover prompt. |
| `pk:sync` | [`workflows/sync.md`](../workflows/sync.md) | Core 🧪 | Active context | Hot-reload protocols, purge stale memory, and synchronize with disk. |
| `pk:profile` | [`workflows/profile.md`](../workflows/profile.md) | New 🧪 | `PROMPTKIT.md` + directive | Switch Lite/Balanced/Turbo at runtime via the idempotent installer re-injection path. |
| `pk:auto` | [`workflows/auto.md`](../workflows/auto.md) | New 🧪 | Verified diff / PR | Unattended SDLC meta-orchestration (plan→tasks→code→test→review) with circuit breakers and test immobility. |
| `pk:retro` | [`workflows/reflect.md`](../workflows/reflect.md) | Core | `docs/adrs/` & journal | Post-feature retrospective: extracts decisions into standard MADRs. |

*Status Legend: All 24 workflows pass CI structural link validation (`validate-references.sh`). Workflows marked with 🧪 also undergo automated documentation-contract testing (`run-behavioral-contract-tests.sh` — string-level prompt-contract assertions); sampled runtime compliance is measured separately by `scripts/run-behavioral-eval.sh` (see `docs/BEHAVIORAL-EVAL.md`).*

---

## Repository Layout

```text
promptkit-os/
├── .github/
│   └── workflows/
│       └── ci.yml               # Maintainer CI (script syntax, initialization dry-run/idempotency, workflow structure, reference validation, fixture harnesses, and behavioral-contract tests)
├── CHANGELOG.md                 # Official release provenance adhering to Keep a Changelog
├── FAQ.md                       # The 19 questions every developer asks before adopting
├── QUICKSTART.md                # 5-minute introduction with core workflows & 1-line setup
├── init.ps1                     # Setup script for Windows (PowerShell)
├── init.sh                      # Setup script for Linux/macOS (Bash)
├── LICENSE                      # Open-source MIT License
├── docs/
│   ├── ARCHITECTURE.md          # Operating model, enforcement, command reference & layout (this file)
│   ├── BEHAVIORAL-EVAL.md       # Sampled prompt-compliance results & methodology
│   ├── BENCHMARKS.md            # Factual token economics, JIT benchmarks & model tiering
│   ├── COMPARISONS.md           # Host support matrix & competitor comparison
│   ├── WORKFLOW-MAP.md          # Visual decision trees and Mermaid diagrams
│   ├── ADOPTION-GUIDE.md        # Incremental adoption for existing projects
│   ├── INTERESTING-FACTS.md     # Unique insights and design principles
│   ├── DESIGN-MD-FAQ.md         # FAQ on custom DESIGN.md usage & safety
│   ├── token-efficiency-review.md # Token efficiency audit trail
│   ├── stacks/                  # JIT stack playbooks (Next.js, Turso, Supabase, Render, Vercel, Cloudflare)
│   └── adrs/                    # Architecture Decision Records (0001 headroom, 0002 lifecycle)
├── protocols/                   # Non-negotiable AI rules & operating standards
│   ├── setup.md                 # Universal multi-agent configuration protocol
│   ├── context-sync.md          # Tech stack, monorepos, PROMPTKIT.md, DESIGN.md & git detection
│   ├── discovery-intake.md      # Bounded greenfield intake protocol (size classes S/M/L + product-shape questions)
│   ├── telemetry-cards.md       # Lazy-loaded status-card format spec & callout titles
│   ├── code-quality-gate.md     # Non-negotiable definition-of-done & pre-commit gate
│   └── subagent-delegation.md   # Subagent delegation, parallel execution & context preservation
├── workflows/                   # Step-by-step engineering lifecycle procedures (24 workflows)
│   ├── route.md                 # Lifecycle decision matrix & workflow triage (pk:route)
│   ├── tutor.md                 # Socratic mentorship & 3-tier progressive hints (pk:tutor, pk:grill)
│   ├── plan.md                  # Spec-Driven Development & deep modular design (pk:plan)
│   ├── onboard.md               # Project intake (greenfield interview & brownfield scan), monorepo workspaces & PROMPTKIT.md (pk:onboard)
│   ├── tasks.md                 # Atomic issue breakdown, Gherkin AC & Kanban sync (pk:tasks)
│   ├── review.md                # Two-axis PR & Fowler smell review with data safety audit (pk:review)
│   ├── commit.md                # Atomic Conventional Commits & staging hygiene (pk:commit)
│   ├── pr.md                    # High-signal pull request descriptions & evidence audit (pk:pr)
│   ├── debug.md                 # Empirical feedback-loop debugging & root cause analysis (pk:debug)
│   ├── fix.md                   # Surgical remediation of known review findings (pk:fix)
│   ├── refactor.md              # Systematic code refactoring & design pattern alignment (pk:refactor)
│   ├── perf.md                  # Empirical performance profiling & latency SLAs (pk:perf)
│   ├── data.md                  # Relational schema design, composite indexes & RLS (pk:data)
│   ├── auth.md                  # Authentication, cookie security & RBAC/ABAC (pk:auth)
│   ├── api.md                   # API contracts, error envelopes & idempotency (pk:api)
│   ├── test.md                  # Upfront test strategy, seam allocation & mock boundaries (pk:test)
│   ├── ship.md                  # Release engineering, runtime env checks & rollbacks (pk:ship)
│   ├── sync.md                  # Living state synchronization & project health checks (pk:sync)
│   ├── profile.md               # Runtime Lite/Balanced/Turbo profile switching (pk:profile)
│   ├── research.md              # Technical spikes & sharpest-risk benchmark matrix (pk:spike)
│   ├── design-system.md         # Anti-slop UI, Design Tokens, and WCAG 2.2 accessibility (pk:design)
│   ├── reflect.md               # Engineering retrospectives & ADR generation (pk:retro)
│   └── checkpoint.md            # Session state compaction & handover prompt (pk:checkpoint)
├── templates/                   # Structured artifact schemas saved to project docs/
│   ├── agent-directive-template.md # Canonical directive source template rendered during initialization
│   ├── project-profile-template.md # Scaffolds PROMPTKIT.md for project guardrails & monorepo topology
│   ├── design-profile-template.md  # Scaffolds DESIGN.md for brand identity & visual tokens
│   ├── state-tracker-template.md   # Scaffolds docs/STATE.md as a synchronized projection
│   ├── execution-task-record-template.md # Canonical Controlled Work Task Record
│   ├── friction-evaluation-template.md    # Adaptation friction evaluation & improvement
│   ├── execution-scope-change-template.md # Approved scope expansion/change record
│   ├── execution-handoff-template.md # Receiver-validated session or role handoff
│   ├── data-model-spec.md          # Relational schema & RLS specification
│   ├── auth-matrix-template.md     # Auth architecture & RBAC capability matrix
│   ├── api-contract-spec.md        # API endpoint contract & error code catalog
│   ├── test-plan-template.md       # Upfront test strategy & pyramid seam specification
│   ├── release-checklist.md        # Release engineering & zero-downtime deploy checklist
│   ├── release-evaluation-template.md # Release candidate evaluation & approval
│   ├── ci-triage-template.md       # CI classification & remediation tracking
│   ├── contract-impact-evidence-template.md # Contract impact evidence & breaking guidance
│   ├── pull-request-template.md    # High-signal Pull Request description & safety checklist
│   ├── github-issue-template.md    # Standardized native GitHub issue template (.github/ISSUE_TEMPLATE/task.md)
│   ├── perf-audit-template.md      # Performance audit report & before/after delta spec
│   ├── issue-task-template.md      # Staff-level GitHub Issue template with Gherkin AC
│   ├── adr-template.md             # MADR standard Architectural Decision Record
│   ├── tech-spec-template.md       # Engineering RFC / Technical Specification
│   ├── rca-postmortem-template.md  # Blameless Post-Mortem & Incident RCA
│   ├── code-review-checklist.md    # Senior Developer PR Review Checklist
│   ├── design-tokens-spec.md       # Design System & Token Specification
│   └── spike-template.md           # Technical Spike & Benchmark Evaluation Template
├── examples/                    # Real-world production examples
│   ├── README.md                       # Example catalog and usage guide
│   ├── fullstack-feature/              # Narrative lifecycle reference (Invitations, DB migration, UI tokens)
│   ├── production-incident/            # Post-mortem and RCA debugging artifact
│   ├── saas-dashboard/                 # Complete B2B SaaS example (Next.js + Supabase)
│   │   ├── PROMPTKIT.md               # Full project profile with monorepo config
│   │   ├── docs/STATE.md              # Living project tracker across milestones
│   │   ├── docs/adrs/                 # Real ADR: magic link invitations
│   │   └── conversations/             # Before/after code review with security fixes
│   ├── sample-progress-journal.md     # Retrospective entries from real projects
│   └── sample-learning-plan.md        # Engineering OKRs & mental model notes
├── notes/                       # Engineering competency & growth templates
│   ├── README.md                   # Knowledge base guide
│   ├── learning-plan.md            # Template for engineering OKRs & practice katas
│   ├── progress-journal.md         # Template for progressive retro logs
│   ├── skill-matrix.md             # Software Engineering Competency Matrix (L1 → L4)
│   ├── adrs/                       # Local ADR directory (for standalone vault mode)
│   └── spikes/                     # Local Spikes directory (for standalone vault mode)
├── scripts/                     # Validation, isolation, and token measurement utilities
│   ├── isolate-worktree.sh             # Bash: Git worktree sandbox manager (create, merge, remove)
│   ├── isolate-worktree.ps1            # PowerShell: Git worktree sandbox manager (create, merge, remove)
│   ├── measure-tokens.sh               # Bash: Mechanical directive character and token counter
│   ├── measure-tokens.ps1              # PowerShell: Mechanical directive character and token counter
│   ├── measure-tokenizer-delta.sh      # Bash: bytes/4 vs real-tokenizer validation
│   ├── measure-tokenizer-delta.ps1     # PowerShell: bytes/4 vs real-tokenizer validation
│   ├── run-behavioral-eval.sh          # Bash: Prompt-compliance eval harness + offline self-test
│   ├── run-behavioral-eval.ps1         # PowerShell: Prompt-compliance eval harness + offline self-test
│   ├── tests/eval-scenarios/           # Eval rubric scenarios with embedded fixtures (15)
│   ├── setup-github-labels.sh          # Bash: Provision standardized GitHub labels (priority, type, area)
│   ├── setup-github-labels.ps1         # PowerShell: Provision standardized GitHub labels (priority, type, area)
│   ├── validate-references.sh          # Bash: Check all workflow→template references
│   ├── validate-references.ps1         # PowerShell: Check all workflow→template references
│   ├── validate-execution-control.sh   # Bash: Read-only Task/STATE evidence validator
│   ├── validate-execution-control.ps1  # PowerShell: Read-only Task/STATE evidence validator
│   ├── validate-ci-triage.sh           # Bash: CI classification record validator
│   ├── validate-ci-triage.ps1          # PowerShell: CI classification record validator
│   ├── validate-release-records.sh     # Bash: Release evaluation & approval validator
│   ├── validate-release-records.ps1    # PowerShell: Release evaluation & approval validator
│   └── tests/run-execution-control-fixtures.* # Paired regression and isolated fixture harnesses
└── activities/                  # Interactive simulation katas & system design drills
    ├── README.md                   # Interactive simulation catalog
    ├── 01-system-design-spike.md         # High-throughput webhook engine design
    ├── 02-refactoring-clean-arch.md      # Refactoring monolith to Clean Architecture
    ├── 03-async-concurrency-debug.md     # Concurrency race conditions & memory leaks
    ├── 04-accessible-design-system.md    # Accessible, tokenized component library
    └── create-research-workflow.md       # Create custom research workflow templates
```

---

## Related References

- [`../README.md`](../README.md) — Front door: pitch, install, Level model, worked example
- [`BENCHMARKS.md`](./BENCHMARKS.md) — Token economics behind the architecture figures
- [`WORKFLOW-MAP.md`](./WORKFLOW-MAP.md) — Lifecycle diagrams and workflow timing
