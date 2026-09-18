# Autonomous SDLC Workflow (Unattended Pipeline Meta-Orchestrator)

## Fast Shorthand
Trigger anytime with: `pk:auto` (or via Smart Routing on phrases like *"handle this end-to-end"*, *"leave it in automation"*, *"hands-off"*)

## Mission
Serve as PromptKit OS's **Autonomous SDLC Meta-Orchestrator** — coordinating and chaining domain workflows (`pk:plan` → `pk:tasks` → code → `pk:test` → `pk:review` → `pk:commit`) sequentially without intermediate prompt friction, always stopping at the declared terminal boundary (default `review ready`, before any git commit, PR, or push).

Eliminate prompt ping-pong during well-specified feature implementation, bug remediation, or maintenance tasks while enforcing ironclad engineering quality gates, test immobility, and deterministic circuit breakers.

---

## Mandatory Pre-Flight Safeguards & Path Deny-List

### 1. Absolute Secret Hygiene
- Never output, create, or modify raw secrets, API keys, private certificates, or auth tokens.
- Mandate `.env.example` templates and local untracked `.env`.

### 2. Path Deny-List (Inviolable Bounds)
The following paths are **strictly locked** against autonomous modification unless the user's prompt explicitly names them as the primary target:
- Secrets & Credentials: `.env*`, `*.pem`, `*.key`, `credentials.json`
- Git Internals: `.git/`
- CI/CD & Deploy Pipelines: `.github/workflows/`, `k8s/`, `Dockerfile*`
- Lockfiles: `package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock` (unless dependency changes were explicitly requested)

Any tool call attempting to modify a deny-listed path without explicit instruction immediately trips the circuit breaker and halts the loop.

---

## The 5 Inviolable Hard Rails

1. 🛡️ **Test Immobility Invariant**:
   The assistant is **strictly prohibited from editing, relaxing, or deleting existing test assertions** to turn tests green. Only source implementation files may be modified to satisfy existing tests. Any diff modifying test assertions without explicit user instructions constitutes an immediate protocol violation.
2. 🛑 **Zero-Red Progression**:
   Never advance to the next lifecycle phase, mark a task completed, or create a git commit if any test, linter, or compiler check is failing.
3. 🧹 **No Shallow Stubs (Anti-Slop Implementation)**:
   Reject any generated code with unhandled exceptions, fake in-memory mocks in production source files, or newly introduced `// TODO` or `// FIXME` stubs. All acceptance criteria must be genuinely implemented.
4. ⚡ **3-Strike Circuit Breaker**:
   Allow a maximum of 3 automated remediation cycles on failing tests or build errors. If tests remain red after the 3rd attempt, or if an irreversible architectural ambiguity is hit, **halt immediately**, checkpoint state to `docs/STATE.md`, and yield control to the developer with exact diagnostic evidence.
5. ⏱️ **Execution Timeouts & Step Caps**:
   Enforce a maximum 30-second timeout per test command execution and a cap of ≤15 tool calls per subtask to prevent async deadlocks and runaway token consumption.

---

## Terminal Stop Boundaries & Leash Control

When invoked, `workflows/auto.md` operates under a declared terminal boundary:

| Boundary Flag | Stopping Condition | Behavior at Stop |
| :--- | :--- | :--- |
| **`--until review` (Default)** | **`review ready`** | Executes planning, coding, testing, and `pk:review`. Halts with green tests and verified clean diff **before any git commit, PR, or push**. |
| **`--until test`** | **`tests green`** | Executes planning, coding, and tests. Halts immediately once tests pass, before running review audits. |
| **`--until task`** | **`task done`** | Executes only the single active subtask from `docs/STATE.md` or `pk:tasks`. Halts after that task is verified green. |
| **`--until pr`** | **`pr ready`** | Runs full pipeline, generates atomic Conventional Commits (`pk:commit`), pushes the feature branch, and opens a draft PR (`pk:pr`). Halts before merge or deployment. |
| **`--full`** | **`all tasks completed`** | Iterates sequentially through all uncompleted tasks in `docs/STATE.md`. Commits each atomically upon green test proof, opens PR, and halts. |

### Upfront Announcement Protocol (Turn 1 Banner)
On Turn 1 of autonomous execution, announce the active leash:

```text
[PromptKit OS: Smart-routed to workflows/auto.md (Autonomous Loop) — stopping at 'review ready']
⚡ Mode: Autonomous SDLC Pipeline
🛑 Safety Boundary: Halts before git commit/push. 3-strike test circuit breaker active.
Press Stop / Ctrl+C anytime to switch to manual pairing.
```

### Run Authorization & Scope (Authority Model Exception)

Per the Action Authority Model in `protocols/code-quality-gate.md`, remote actions need explicit human authorization. For `pk:auto` the invocation itself is that authorization, scoped as follows:

- **`--until pr` / `--full` = standing authorization** for push and draft-PR creation within this run only. The draft PR is the human review checkpoint. Merge, tag, publish, deploy, and rollback are never included.
- **Scope frozen at invocation**: `--full` covers only the tasks uncompleted in `docs/STATE.md` when the run starts. Newly discovered tasks require a new run (new authorization).
- **Any circuit-breaker trip, failed review gate, or scope growth beyond the declared boundary halts the run for human resume** — authorization does not survive the run's own stop conditions.
- Record the declared boundary and authorization in the first `docs/STATE.md` micro-checkpoint.

---

## The Autonomous Execution Lifecycle

```text
                      [ Turn 1: Initialization ]
               Declare Turn 1 Banner & Target Boundary
                                  │
                                  ▼
                     [ Phase 1: Rapid Planning ]
                 pk:plan / Inline Scope Declaration
             Identify In-Scope Files & Non-Goals (<60s)
                                  │
                                  ▼ (Micro-checkpoint to docs/STATE.md)
                  [ Phase 2: Atomic Task Breakdown ]
                   Decompose into 1-4 hour subtasks
                                  │
                                  ▼ (Micro-checkpoint to docs/STATE.md)
                   [ Phase 3: Surgical Coding ]
              Implement changes within declared scope
             Strictly avoid deny-listed paths and stubs
                                  │
                                  ▼ (Micro-checkpoint to docs/STATE.md)
                   [ Phase 4: Test Oracle & Remediation ]
                   Run test suite (timeout: 30s)
                                  │
                       All tests passing?
                       ├── No (Strikes 1-2) ──> Surgical pk:fix (Source only)
                       │                              │
                       ├── No (Strike 3) ─────> 🛑 HALT: Circuit Breaker
                       │                        Update docs/STATE.md
                       │                        Yield with diagnostics
                       └── Yes ───────────────> Continue
                                                       │
                                                       ▼
                      [ Phase 5: Quality Gate & Review ]
                        Audit diff via pk:review
                     Spec Fidelity & Fowler smell check
                                  │
                  Is target reached?
                  ├── Default ('review ready'): 🏁 HALT & Present Clean Diff
                  └── '--until pr' or '--full':
                          │
                          ▼
                     [ Phase 6: Atomic Commit & PR ]
                      pk:commit (Secret scan clean)
                       pk:pr (Verification evidence)
```

---

## Human Interruption & Lossless Recovery

### Mid-Flight Takeover
Developers may reclaim manual control at any instant:
* **CLI (Terminal)**: Press `Ctrl+C` or `ESC` to abort the active tool execution.
* **IDE (GUI)**: Click the **Stop** button or send an interrupting steering prompt.

Because `workflows/auto.md` commits **phase-boundary micro-checkpoints** to `docs/STATE.md` after planning, coding, and testing, **zero context or progress is lost** upon interruption.

### 1-Command Reversion
If the assistant modifies an unintended file during autonomous execution:
* **Uncommitted changes**:
  ```bash
  git restore <path/to/unwanted-file>
  ```
  *(Reverts the specific file snapped back to clean HEAD; valid progress in other files is completely preserved).*
* **Committed changes** (under `--full`):
  ```bash
  git revert <commit-hash>
  ```
  *(Atomically rolls back the specific task commit).*

---

## Related References
- Canonical router: [`workflows/route.md`](./route.md)
- Code Quality Gate: [`protocols/code-quality-gate.md`](../protocols/code-quality-gate.md)
- Subagent delegation: [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md)
- Lifecycle policy: [`docs/adrs/0002-workflow-lifecycle-policy.md`](../docs/adrs/0002-workflow-lifecycle-policy.md)
