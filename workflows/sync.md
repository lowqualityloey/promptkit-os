# Protocol Synchronization & Hot-Reload Workflow

## Fast Shorthand
Trigger anytime with: `pk:sync` (or `/pk-sync`, `pk:update`, `pk:refresh`)

## Mission
Eliminate instruction decay, stale working assumptions, and formatting divergence after updating PromptKit OS. Re-read root configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`), inspect newly added or updated workflows, and immediately reload the agent's operational rules from disk — then announce any rule that differs from what the session has been doing.

### Mandatory Re-Entry Recovery

Run this before any project-state write after a fresh-session handover, host-reported compaction or continuation, detected loss of task invariants, or a status interruption that displaced active work. Do not resume from a summary alone.

1. For Level 2/3 or otherwise controlled work, read the canonical Local Task Record (`docs/tasks/<task-id>.md`) and the checkpoint or handoff it identifies; verify task identity and exact revision. For low-risk work without a Task Record, retain the current human instruction as the scope authority and read a handoff/checkpoint only when one exists. If controlled-work authority or a required handoff/checkpoint is unavailable after a fresh-session handover, stop and ask for the missing authority.
2. Read `docs/STATE.md` as a projection when tracked project/task state applies; read the active workflow when one governs the work; and read the applicable installed root directives (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, or host equivalent). For Level 0 requests or work with no applicable STATE/workflow, skip those absent artifacts; their absence alone is not a blocker.
3. For active tracked or controlled work, restore the objective, milestone, frozen scope, authorization source, blockers and pending human actions, and resume condition from those records and identify exactly one next action. For low-risk work without tracking, retain the current human instruction as the objective and scope, and restore only applicable blockers or pending actions. Do not invent task state or require workflow-specific fields for work with no active workflow.
4. Reconcile record/revision conflicts before any write. The Task Record is canonical and STATE is only its projection. If authority is missing, conflicting, or still stopped, preserve that stop state; a summary, `continue`, continuation event, or new session cannot create approval or broaden scope.
5. Resume only after all required reads agree and any applicable recorded resume condition is met. Never invent a missing Task Record or authority from a summary; retain any existing stop condition until authority is established.

Hosts that expose no compaction or continuation signal cannot reliably detect it. Apply recovery on a fresh-session handover or reported context reset; otherwise report detection as unavailable rather than claiming automatic recovery.

---

## Preconditions & When to Sync
- **PromptKit Engine Updated**: Submodule updated, `git -C .promptkit pull origin main`, or `bash .promptkit/init.sh` was just run.
- **Instruction Drift / Formatting Divergence**: The AI is omitting visual callouts (`> [!TIP]`, `> [!IMPORTANT]`), failing to render the telemetry status card when enabled (3 mandatory lines `📊 / 🎯 / 🟢` + optional `📈`; suppressed when `PROMPTKIT.md` declares `status-cards: off`, while halts still fire per `protocols/telemetry-cards.md`), or not prioritizing native interactive selection tools.
- **Post-Compaction Re-Entry**: After a conversation summary/continuation, run **Mandatory Re-Entry Recovery** before resuming project work; do not treat rereading STATE and the active workflow alone or relying on summarized protocol as sufficient.
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

**Read-only by default**: this workflow observes and reports; it never auto-rewrites user-authored profile or configuration. The one-time `tracking:` backfill below is the only permitted automatic `PROMPTKIT.md` mutation — explicitly instructed profile patches may be applied upon human direction, but inferred changes always retain human confirmation. Future additions must not introduce "helpful" auto-fixes.

Before responding, the AI assistant inspects the physical workspace. If the environment grants no workspace access, skip to the fallback: report which checks could not execute and emit `Quality Gate: not measured` — never a claim of "synced" (Provenance Invariant: no executed proof → no green claim).

> **Synthetic-base preflight (read-only).** Before any base-deriving comparison in this workflow — the drift audit's `merge-base --is-ancestor HEAD <upstream-ref>`, a review fixed point, a PR base, or a changelog range — run `scripts/check-synthetic-base.sh` / `.ps1`. It refuses (exit 1) only when `HEAD` is positively tool-owned: the **tip of** a tool-namespace ref such as `refs/gitbutler/*` and carried by no branch, or the **tip of** a tool-owned workspace branch such as `gitbutler/workspace` (GitButler's `refs/heads/gitbutler/workspace`). A commit carried by any ordinary branch, and a detached real commit, report `OK` or `UNKNOWN` and proceed. On refusal, return to the carrying branch or rebase onto a real branch tip. Never derive a base from a synthetic workspace commit ([`docs/MAXIMS.md`](../docs/MAXIMS.md)).

1. **Verify Root Directive Files**:
    Confirm that active host configuration files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`) contain the latest `<!-- PROMPTKIT_START -->` block.
2. **Backfill Missing `tracking:` Line (One-Time Migration)**:
    If `./PROMPTKIT.md` lacks a `tracking: local|github|jira|linear` line, prompt once via native selection tool (same 4 priced options as `pk:onboard` Step 1b, with markdown `Type number & Enter` fallback) and persist it. Never overwrite an existing value. Respect `--tracking=` flag and `PROMPTKIT_NO_INTERACTIVE=1` (flags/default `local`, no picker).
3. **Inspect Engine Path & Workflows**:
   Identify the engine directory (typically `.promptkit/` — the path quoted in your injected directive) and verify available workflows in its `workflows/` directory (count them with the file listing, do not recall a number).
4. **Check Version & Release Records**:
   Do not eyeball `docs/releases/` or scroll a commit log. Run the three comparisons in **Engine Version & Drift Audit** below, then report exactly one of the six states it defines, using that state's remediation text verbatim.

#### Engine Version & Drift Audit

<a id="engine-version-drift-audit"></a>

A stale session is the failure this audit exists to prevent, so nothing here is a judgment call. Classify the install first, then run the three comparisons in order, one command each:

1. **Install classification, two checks that gate everything after them**:
   - `test -e <kit-path>/.git` is false → `<kit-path>` holds no repository, so report `not-a-git-install` and stop this audit. The check passes for a submodule (a gitfile pointing into the host repo's `.git/modules/`) and for a real clone (a directory), so `test -e` is the right test, not `test -d`.
   - `git -C <kit-path> rev-parse --is-shallow-repository` returns true → report `shallow-or-offline` and stop this audit. Never substitute a guess for the missing history.
2. **Comparison (a), directive stamp vs `docs/STATE.md` stamp**: parse the `Engine: <ver> (<sha>)` stamp inside the host file's `<!-- PROMPTKIT_START -->` block, then parse the `**Engine Version**: <ver> @ <sha>` line in `docs/STATE.md`. No git involved. Normalize both to a `<ver>` / `<sha>` pair, then state the outcome as one line: `stamp cross-check: match`, `stamp cross-check: mismatch (directive <ver>/<sha>, STATE.md <ver>/<sha>)`, or `stamp cross-check: STATE.md unstamped`. The directive stamp is the reporting authority; a mismatch is an observation appended after the state line below, never a seventh state.
3. **Comparison (b), stamp vs on-disk engine**: `git -C <kit-path> rev-parse --short HEAD` returns the commit actually sitting in the engine directory. Compare it against the stamped short SHA; equality means the stamp still describes this tree.
4. **Comparison (c), on-disk engine vs upstream**: resolve `<upstream-ref>` (the engine's remote-tracking default branch, normally `origin/main`) from what is already on disk. Then `git -C <kit-path> rev-list --count HEAD..<upstream-ref>` yields the `+n` figure, and `git -C <kit-path> merge-base --is-ancestor HEAD <upstream-ref>` decides divergence: exit 0 means the local engine is an ancestor of upstream, any other exit means it is not. **Both figures come from `HEAD`.** Never substitute the stamped ref: measuring distance from the stamp reports an engine that has since moved against the wrong commit.

Classify by walking the table top to bottom and stopping at the first row that matches. The rows are disjoint by construction — `diverged` is tested before `behind` because a divergent engine usually also has a positive count, and `behind` before `ok` because any positive count disqualifies `ok` — so exactly one state is ever reported:

| State | Condition (first match wins) | Report as |
| :--- | :--- | :--- |
| not-a-git-install | `<kit>/.git` does not exist (npx courier tarball install) | `engine <ver> (courier install — version from release tarball, not git)` |
| unknown | no stamp present in the directive | `engine unknown — re-run the installer to stamp` (warn once, never error) |
| shallow-or-offline | `git rev-parse --is-shallow-repository` is true, OR `<upstream-ref>` cannot be resolved | `engine <ver> cannot verify drift (shallow/offline) — fetch --unshallow to check` |
| diverged | `git merge-base --is-ancestor HEAD <upstream-ref>` exits non-zero | `engine <ver> diverged from upstream — reconcile manually` |
| behind(+n) | is-ancestor exits 0 AND `rev-list --count HEAD..<upstream-ref>` > 0 | `engine <ver> < upstream (+n) — offer pk:sync upgrade` |
| ok | is-ancestor exits 0 AND `rev-list --count HEAD..<upstream-ref>` is 0 | `engine <ver> (<sha>) current` |

**Stamp drift is not engine drift.** Comparison (b) reports whether the stamp still describes the tree; it never changes which state above is reported. Append it as its own observation line after the state, exactly like comparison (a): `stamp vs engine: match`, or `stamp vs engine: stale (stamp <ver>/<sha>, engine <sha>)`. A stale stamp with an up-to-date engine is still `ok` plus that observation — the engine is current, the record of it is not, and conflating the two would send the developer to upgrade an engine that needs no upgrade.

**Hard rules.** Violating any of these reintroduces the exact bug this audit exists to prevent:

- **Never run `git describe --tags --abbrev=0` (or `--abbrev=0` in any form) to produce or store a stamp.** `--abbrev=0` discards the commit distance. Measured in this very repository: `git describe --tags` returns `v1.10.1-12-ge78fde0` while `git describe --tags --abbrev=0` returns `v1.10.1`, silently hiding 12 commits. `describe` output is display-only.
- **When restricting a tag lookup to release tags, use `--match 'v[0-9]*'`.** This repository also carries non-release `backup/*` tags, and an unfiltered `describe --tags` can resolve to one of them and report a garbage version.
- **A shallow install must report `shallow-or-offline`, never a confident `ok` and never a fabricated `+n`.** In a shallow clone, `rev-list --count` and `merge-base --is-ancestor` are both unreliable. Measured here: `rev-list --count v1.11.0..HEAD` returns `4` while `v1.11.0..origin/main` returns `14`.
- **A courier install has no git repository at all.** The npm courier resolves its version from the package manifest and unpacks a pinned release tarball; it invokes git nowhere. Report `not-a-git-install` and continue. Never treat it as an error.

**Read-only, always.** This audit never stages, commits, fetches, pulls, updates a submodule, invokes the installer, or writes any file in the host repository or the engine checkout. Allowed operations are exactly: file reads plus `rev-parse`, `rev-list`, `merge-base`, and `is-shallow-repository`. When a remediation names an action such as `fetch --unshallow` or re-running the installer, that is a request to the developer, never one for the agent to perform.

**Courier installs are recognizable from this file alone.** A `npx promptkit-os` install has no `<kit>/.git` at all: the courier copies an unpacked release tree into the engine directory, so nothing there is a repository. Comparison (c) is therefore `not-a-git-install` by construction, not a failure to retry and not a reason to install git tooling.

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

Conclude the synchronization turn with the standard telemetry status card (3 mandatory lines + optional `📈`) when enabled (skip the decorative card when `PROMPTKIT.md` declares `status-cards: off`; halts still fire per `protocols/telemetry-cards.md`), with every value traced to a file read or command run **this turn**:

```text
📊 Milestone: PromptKit OS Synced — Engine Rules Reloaded From Disk
🎯 Active: pk:sync (disk-first reload complete)
🟢 Quality Gate: <results of checks actually executed this turn>
Session: ~<n>/30 turns — consider pk:checkpoint (estimate; write `not measured` if unknown) (appended)
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

During the Phase 2 diff, treat any new requirement, constraint, artifact, or scope statement the developer introduces mid-implementation as an interception candidate — never absorb it silently into current execution:

| Delta type | Required handling |
| :--- | :--- |
| Documentation-only (doc link, README note, style preference) | Append to the intake record and propose the `PROMPTKIT.md` signals patch; apply only when explicit user instruction authorizes the write, retaining human confirmation for inferred changes; continue. |
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
