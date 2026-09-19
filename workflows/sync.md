# Protocol Synchronization & Hot-Reload Workflow

## Fast Shorthand
Trigger anytime with: `pk:sync` (or `/pk-sync`, `pk:update`, `pk:refresh`)

## Mission
Eliminate instruction decay, stale working assumptions, and formatting divergence after updating PromptKit OS. Re-read root configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`), inspect newly added or updated workflows, and immediately reload the agent's operational rules from disk — then announce any rule that differs from what the session has been doing.

---

## Preconditions & When to Sync
- **PromptKit Engine Updated**: Submodule updated, `git -C .promptkit pull origin main`, or `bash .promptkit/init.sh` was just run.
- **Instruction Drift / Formatting Divergence**: The AI is omitting visual callouts (`> [!TIP]`, `> [!IMPORTANT]`), failing to render the telemetry status card (3 mandatory lines `📊 / 🎯 / 🟢` + optional `📈`), or not prioritizing native interactive selection tools.
- **Post-Compaction Re-Entry**: After a conversation summary/continuation, the first substantive action should be a disk re-read of `docs/STATE.md` and the active workflow — do not act from a summarized recollection of protocol.
- **New Session Startup / Protocol Verification**: Starting work on a fresh branch or verifying that the active agent is fully aligned with host repository guardrails.

---

## 3-Phase Sync Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                    PK:SYNC LIFECYCLE                        │
├──────────────────────────────┬──────────────────────────────┤
│ Phase 1: Engine & Rule Audit │ Phase 2: Disk Re-Read & Diff │
├──────────────────────────────┴──────────────────────────────┤
│ Phase 3: Telemetry Confirmation & Protocol Alignment         │
└─────────────────────────────────────────────────────────────┘
```

---

### Phase 1: Engine & Rule Audit

Before responding, the AI assistant inspects the physical workspace:

1. **Verify Root Directive Files**:
    Confirm that active host configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`) contain the latest `<!-- PROMPTKIT_START -->` block.
2. **Backfill Missing `tracking:` Line (One-Time Migration)**:
    If `./PROMPTKIT.md` lacks a `tracking: local|github|jira|linear` line, prompt once via native selection tool (same 4 priced options as `pk:onboard` Step 1b, with markdown `Type number & Enter` fallback) and persist it. Never overwrite an existing value. Respect `--tracking=` flag and `PROMPTKIT_NO_INTERACTIVE=1` (flags/default `local`, no picker).
2. **Inspect Engine Path & Workflows**:
   Identify the engine directory (typically `.promptkit/` — the path quoted in your injected directive) and verify available workflows in its `workflows/` directory (count them with the file listing, do not recall a number).
3. **Check Version & Release Records**:
   Inspect the engine's `docs/releases/` or recent commits on the PromptKit submodule to identify newly added capabilities.

---

### Phase 2: Disk Re-Read & Convention Diffing (Fresh Disk-First Loading)

1. **Re-Read, Then Diff Aloud**:
   A model cannot delete in-context habits; it can only override them with fresher authority. Re-read the injected directive block from disk, then explicitly announce any rule that differs from what the session has been doing (e.g., "prior turns used bare `[!TIP]`; disk standard mandates `> [!TIP]`"). If the conversation is long enough that you distrust your own recall, recommend a fresh session via `pk:checkpoint`.
2. **Mandate Fresh Disk Reads**:
   All subsequent workflow triggers (`pk:plan`, `pk:commit`, `pk:pr`, `pk:tasks`, `pk:test`, `pk:ship`) must be read directly from the engine's `workflows/<name>.md` upon invocation rather than recalled from conversational memory.

#### Profile Drift Audit (`PROMPTKIT.md` vs Repository Reality)

A stale profile makes every session re-derive settled facts. When `./PROMPTKIT.md` declares a stack, toolchain, or commands (Sections 2-3), run one bounded, **detection-only pass**:

1. **Bounded manifest scan (presence only)**: check the canonical candidate manifests in [`workflows/route.md`](./route.md) §4d (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `render.yaml`) plus lockfiles. No dependency resolution, no version analysis, no deep stack inference — that is `pk:onboard`'s job.
2. **Compare declared vs detected** on three surfaces only:

| Surface | Declared in `PROMPTKIT.md` | Detected from the repository |
| :--- | :--- | :--- |
| Manifest presence | "no `package.json` exists", or an unqualified stack claim | manifest present or absent |
| Toolchain selection | declared runner/toolchain, or "unselected" | runner binaries, lockfile, and script entries actually present |
| Root commands | Section 3 command list | command entries that exist in the detected manifests |

3. **Findings, never rewrites**: report the mismatch as findings with the observed evidence and propose the profile patch. **Detection is observation, not promotion** — the memory-vs-policy boundary holds (see "Candidate Learnings Are Not Policy" below). Never auto-rewrite user-authored sections; apply nothing until the developer confirms.
4. **Clean profile is silent**: when declarations match detected reality, report no findings and add no ceremony — the session proceeds normally.

Mismatches that require judgment (framework choice, workspace layout, an intentional aspiration) are surfaced as a question, not silently corrected.

---

### Phase 3: Telemetry Confirmation & Protocol Alignment

Conclude the synchronization turn with the standard telemetry status card (3 mandatory lines + optional `📈`), with every value traced to a file read or command run **this turn**:

```text
📊 Milestone: PromptKit OS Synced — Engine Rules Reloaded From Disk
🎯 Active: pk:sync (disk-first reload complete)
🟢 Quality Gate: <results of checks actually executed this turn>
Session: ~<n>/30 turns — consider pk:checkpoint (estimate; write `not measured` if unknown)
```

> [!TIP]
> ### 💡 Next Recommended Step
> - If starting a new feature or design: run **`pk:plan`** or **`pk:design`**
> - If investigating or fixing an issue: run **`pk:debug`** or **`pk:fix`**
> - If managing tasks and milestones: run **`pk:tasks`** or **`pk:checkpoint`**

*(If multiple next actions exist, invoke the host's native interactive selection tool e.g. `ask_question` / prompt picker as your final action with Option 1 marked `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`; Bounded to closed-set operational choices — for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead, see the Picker routing rule in `workflows/plan.md`)*

---

### New-Requirement Interception (Mid-Implementation Deltas)

<a id="new-requirement-interception"></a>

Canonical table: `workflows/checkpoint.md` and `workflows/plan.md` reference this section instead of restating it.

During the Phase 2 diff, treat any new requirement, attachment, or scope statement the developer introduces mid-implementation as an interception candidate — never absorb it silently into current execution:

| Delta type | Required handling |
| :--- | :--- |
| Documentation-only (doc link, README note, style preference) | Append to the intake record and `PROMPTKIT.md` signals; continue. |
| Scope or acceptance-criteria change | Create a linked Scope Change Record (`docs/tasks/<task-id>.scope-<n>.md`) before continuing; expansion requires human confirmation. |
| Architecture, data-model, auth, or deployment-target change | Block execution (`checkpoint_due`) and re-open planning via `pk:plan`; intake status returns to `partial`. |
| Unsolicited idea / nice-to-have | Record in the intake record's **Later ledger**; it never enters the current plan by default. |

Unrecorded new requirements must be reconciled before execution continues.

---

### Candidate Learnings Are Not Policy

Disk re-reads and session syncs treat `docs/STATE.md` §4A Candidate Learnings as non-authoritative staging: entries with status `pending`, `rejected`, or `deferred` are **never automatically promoted** to Section 4 invariants or project guardrails by rereading, repetition, or checkpoint persistence. Promotion requires the recorded human decision defined in `protocols/context-sync.md` §3.1; if a candidate conflicts with an existing invariant or scoped authority, surface the conflict for human resolution instead of applying it.

---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
