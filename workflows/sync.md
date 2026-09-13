# Protocol Synchronization & Hot-Reload Workflow

## Fast Shorthand
Trigger anytime with: `pk:sync` (or `/pk-sync`, `pk:update`, `pk:refresh`)

## Mission
Eliminate instruction decay, stale in-memory assumptions, and formatting divergence after updating PromptKit OS. Re-read root configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`), inspect newly added or updated workflows, and immediately hot-reload the agent's active operational state from disk.

---

## Preconditions & When to Sync
- **PromptKit Engine Updated**: `git submodule update --remote .promptkit` or `./.promptkit/init.sh` was just run.
- **Instruction Drift / Formatting Divergence**: The AI is omitting visual callouts (`> [!TIP]`, `> [!IMPORTANT]`), failing to render the 4-line telemetry status card, or not prioritizing native interactive selection tools.
- **New Session Startup / Protocol Verification**: Starting work on a fresh branch or verifying that the active agent is fully aligned with host repository guardrails.

---

## 3-Phase Sync Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                    PK:SYNC LIFECYCLE                        │
├──────────────────────────────┬──────────────────────────────┤
│ Phase 1: Engine & Rule Audit │ Phase 2: Memory Invalidation │
├──────────────────────────────┴──────────────────────────────┤
│ Phase 3: Telemetry Confirmation & Protocol Alignment         │
└─────────────────────────────────────────────────────────────┘
```

---

### Phase 1: Engine & Rule Audit

Before responding, the AI assistant inspects the physical workspace:

1. **Verify Root Directive Files**:
   Confirm that active host configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`) contain the latest `<!-- PROMPTKIT_START -->` block.
2. **Inspect Engine Path & Workflows**:
   Identify the location of PromptKit OS (`./.promptkit` or relative workspace path) and verify available workflows in `$KIT_DIR_REL/workflows/`.
3. **Check Version & Release Records**:
   Inspect `$KIT_DIR_REL/docs/releases/` or recent commits on the PromptKit submodule to identify newly added capabilities.

---

### Phase 2: Memory Invalidation & Fresh Disk-First Loading

1. **Discard Stale In-Memory Conventions**:
   The AI assistant explicitly purges any outdated formatting habits learned from earlier turns in the conversation (such as bare `[!TIP]` brackets or conversational essay walls).
2. **Mandate Fresh Disk Reads**:
   All subsequent workflow triggers (`pk:plan`, `pk:commit`, `pk:pr`, `pk:tasks`, `pk:test`, `pk:ship`) must be read directly from `$KIT_DIR_REL/workflows/<name>.md` upon invocation rather than recalled from conversational memory.

---

### Phase 3: Telemetry Confirmation & Protocol Alignment

Conclude the synchronization turn by displaying the 4-line monospace status card and interactive handoff:

```text
📊 Milestone: PromptKit OS Synced — Active Engine Protocols Loaded
🎯 Active: pk:sync (Purged stale context · disk-first loading enabled)
🟢 Quality Gate: Clean (19 workflows · 4 protocols · telemetry active)
📈 PRs in flight: protocols synchronized with disk
```

> [!TIP]
> ### 💡 Next Recommended Step
> - If starting a new feature or design: run **`pk:plan`** or **`pk:design`**
> - If investigating or fixing an issue: run **`pk:debug`** or **`pk:fix`**
> - If managing tasks and milestones: run **`pk:tasks`** or **`pk:checkpoint`**

*(If multiple next actions exist, invoke the host's native interactive selection tool e.g. `ask_question` / prompt picker as your final action with Option 1 marked `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`)*

---

## Related References
- [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md) — Complete workflow navigation & lifecycle mapping
- [`templates/agent-directive-template.md`](../templates/agent-directive-template.md) — Canonical agent system directive
- [`protocols/code-quality-gate.md`](../protocols/code-quality-gate.md) — Pre-commit quality & done-gates
