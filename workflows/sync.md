# Protocol Synchronization & Hot-Reload Workflow

## Fast Shorthand
Trigger anytime with: `pk:sync` (or `/pk-sync`, `pk:update`, `pk:refresh`)

## Mission
Eliminate instruction decay, stale working assumptions, and formatting divergence after updating PromptKit OS. Re-read root configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`), inspect newly added or updated workflows, and immediately reload the agent's operational rules from disk — then announce any rule that differs from what the session has been doing.

---

## Preconditions & When to Sync
- **PromptKit Engine Updated**: `git submodule update --remote .promptkit` or `./.promptkit/init.sh` was just run.
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

*(If multiple next actions exist, invoke the host's native interactive selection tool e.g. `ask_question` / prompt picker as your final action with Option 1 marked `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`)*

---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
