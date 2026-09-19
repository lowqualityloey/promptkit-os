# Subagent Delegation & Parallel Execution Protocol

## Purpose
Define the operational rules for delegating engineering tasks to background subagents versus executing them in the primary conversation thread. This protocol protects the parent agent's context window from token exhaustion, minimizes hallucinations caused by context clutter, and accelerates complex tasks through parallel execution.

---

## 1. The Context Preservation Law

```
┌─────────────────────────────────────────────────────────────┐
│                 THE CONTEXT PRESERVATION LAW                │
├─────────────────────────────────────────────────────────────┤
│ The parent agent context is precious, finite, and reserved  │
│ for high-altitude reasoning, architectural invariants, and  │
│ direct user alignment.                                      │
│                                                             │
│ High-volume exploration, file scraping, heavy test logs,    │
│ and multi-branch spikes must be offloaded to subagents.     │
└─────────────────────────────────────────────────────────────┘
```

When an agent reads dozens of files, runs large test suites, or scrapes web documentation directly in the main thread, the context window fills with low-signal noise. This results in:
- Severe token lag and slow response times.
- Instruction drift (ignoring earlier rules and non-negotiables).
- Premature context compaction and loss of nuanced decisions.

---

## 2. Delegation Decision Matrix

Evaluate your upcoming task against this triage before executing:

| Task Characteristics | Execution Target | Rationale |
| :--- | :--- | :--- |
| **Broad Codebase Survey** (inspecting >3 files or unfamiliar folders) | **Subagent** | Keeps raw file dumps out of the parent conversation. |
| **External Documentation / Web Search** (API docs, GitHub issues) | **Subagent** | Eliminates long HTML/markdown search dumps. |
| **Parallel Risk Spikes** (evaluating Library A vs Library B) | **Subagent (Parallel)** | Enables concurrent exploration in `pk:spike`. |
| **Two-Axis PR Audits** (Spec Fidelity vs Fowler Code Smells) | **Subagent (Parallel)** | Enables independent, unbiased reviews in `pk:review`. |
| **Independent Verification** (Level 2/3 Controlled Work) | **Subagent (Single-Pass)** | Eliminates author confirmation bias; single-pass audit contract; no child-agent delegation; max 15-line synthesis. |
| **Long-Running Test / Linter Runs** (full CI simulation) | **Subagent / Task** | Prevents terminal scrollback from cluttering context. |
| **Direct User Interaction & Alignments** | **Main Thread Only** | Subagents must never prompt the human developer directly. |
| **Small Localized Edits** (<10 lines, single file tweaks) | **Main Thread Only** | Spawning a subagent introduces unnecessary latency overhead. |
| **Git Staging, Commits & PR Submission** (`pk:commit`, `pk:pr`) | **Main Thread Only** | Requires unified workspace visibility and secret verification. |
| **Strategic Architectural Decisions** (`pk:plan`, ADR writing) | **Main Thread Only** | Parent agent must lock invariants into project memory. |

---

## 3. The 4-Part Subagent Briefing Contract

When invoking a subagent, provide a crisp, self-contained prompt adhering to this 4-part structure:

### 1. Role & Persona
Define a specialized role with clear capabilities:
- Examples: `Codebase Researcher`, `API Contract Auditor`, `Benchmark Analyst`, `Accessibility Inspector`.

### 2. File & Directory Boundaries
Set explicit bounds so the subagent does not wander across the repo:
- Allowed paths: `src/features/billing/`, `docs/specs/`, `packages/db/`
- Excluded paths: `node_modules/`, `dist/`, `.git/`

### 3. Concrete Actionable Objective
State the precise question to answer or experiment to run:
- Good: "Find all usages of `getUserSession` and report if any call sites omit tenant ID validation."
- Bad: "Look around the codebase and check auth."

### 4. Compact Synthesis Requirement (Mandatory)
Strictly forbid raw dumps. Require the subagent to return a compact 5-15 line synthesized markdown summary:
- **Findings**: What was discovered (with exact file paths and line numbers).
- **Risks / Invariants**: What constraints must be respected.
- **Actionable Recommendation**: 1-3 concrete next steps.
- **Structured worker evidence** (for wave workers — evidence, not prose assurance):
  - `files_changed`: exact paths touched
  - `verification`: each command run with its exit code (failures reported, never summarized away)
  - `contract`: which acceptance criteria are satisfied
  - `known_risks`: explicit list, or `none`

---

## 4. Multi-Agent Coordination Patterns

### Pattern A: Parallel Research Spike (Fan-Out / Fan-In)
When running `pk:spike` to evaluate competing architectures:
```text
                    [ Parent Agent: pk:spike ]
                                │
                 ┌──────────────┴──────────────┐
                 ▼                             ▼
        [ Subagent 1: Drizzle ]      [ Subagent 2: Prisma ]
        - Inspect schema syntax      - Inspect schema syntax
        - Benchmark cold starts      - Benchmark cold starts
                 │                             │
                 └──────────────┬──────────────┘
                                ▼
                    [ Parent Agent Synthesis ]
                    - Compiles trade-off matrix
                    - Writes ADR to docs/adrs/
```

### Pattern B: Dual-Axis Review
When running `pk:review` on a substantial pull request:
1. **Subagent 1 (Spec Fidelity)**: Compares modified files against `docs/specs/` to catch missing requirements or scope creep.
2. **Subagent 2 (Technical Standards)**: Audits diff against Fowler's 12 code smells, security hygiene, and `DESIGN.md`.
3. **Parent Agent**: Merges both reports side-by-side into the final PR review.

### Pattern C: Independent Fresh-Context Verification (Level 2/3 Controlled Work)
When an agent writes a complex feature (relational schema changes, authentication rewiring, breaking public APIs, or release candidates), reviewing its own implementation in the same thread introduces author confirmation bias.
1. **Scope Exclusions**: Level 0 and Level 1 tasks bypass this pattern completely (0 token impact; standard single-agent review).
2. **Execution Contract**: The parent agent spawns a single fresh-context verifier subagent with *only* the Gherkin Acceptance Criteria, the fixed-point git diff, and the runnable test commands.
3. **Strict Bounded Caps**:
   - **Single-Pass Contract**: Verifier performs a single-pass evaluation; child-agent delegation and recursive loops are strictly forbidden. Hosts with tool/turn budgets may enforce this ceiling.
   - **Targeted Verifier Scope**: Keep context strictly bounded to Acceptance Criteria, the resolved diff, and test commands to minimize token consumption.
   - **Concise Output Ceiling**: Max 15-line response with a concise Pass/Fail matrix and exact line references.

### Pattern D: Isolated Worktree Execution (Level 2/3 Risky Multi-File Tasks)
When a task involves high-risk multi-file refactoring, dependency upgrades, or parallel spike implementations, running edits directly in the main working tree risks dirtying the workspace and corrupting local state.
1. **Sandbox Creation**: Use PromptKit's zero-dependency isolation script:
   - Windows: `.\scripts\isolate-worktree.ps1 create <task-id>`
   - Linux/macOS: `./scripts/isolate-worktree.sh create <task-id>`
2. **Isolated Execution**:
   - The subagent or developer operates entirely inside `.worktrees/<task-id>`, backed by a dedicated branch (`worktree/<task-id>`).
   - Run tests, compile artifacts, and verify criteria in isolation.
3. **Reconciliation & Cleanup**:
   - Once verification passes: `isolate-worktree.ps1 merge <task-id>`
   - Clean up the scratch worktree: `isolate-worktree.ps1 remove <task-id>`
   - The parent project `.gitignore` automatically excludes `.worktrees/` to prevent untracked leakage.

---

## 5. Failure Recovery & Timeout Handling

- If a subagent returns incomplete information or encounters a tool error, do not spawn another subagent blindly.
- Inspect the subagent's returned error message.
- If the task is small, execute the remaining check directly in the main thread.
- If the task is still large, refine the briefing prompt with narrower file boundaries and re-invoke once.
