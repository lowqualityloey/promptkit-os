# Ecosystem Enforcement Packs — T1 Design Specification

<a id="SPEC-2026-11-26-ECOSYSTEM-ENFORCEMENT-PACKS"></a>

### Metadata

- **Issue:** #789. This record answers the three owner decisions that issue requires of Stage T1 and authorizes no implementation.
- **Priority / Labels / Wave:** `priority/p2`; `type:design`; Wave D (ecosystem).
- **Work Classification:** `L2` Controlled Work; Work Type `docs`; proposed SemVer impact `none` — T1 changes no behavior surface, so no consumer-visible contract moves.
- **Status:** design complete, awaiting maintainer ruling confirmation. T2 (pilot) and T3 (rollout) each require their own L2 record; nothing here pre-authorizes them.
- **Related authority:** [`docs/ENFORCEMENT.md`](../ENFORCEMENT.md) (anchor: `The PromptKit OS Enforcement Ladder`); [`docs/HOST-CONFORMANCE.md`](../HOST-CONFORMANCE.md) (anchor: `## 4. Untested Hosts Registry`); [`docs/BEHAVIORAL-EVAL.md`](../BEHAVIORAL-EVAL.md) (anchor: `### Check types`); [`issue-553-progressive-compliance.md`](./issue-553-progressive-compliance.md) (tier-contract precedent); `docs/MAXIMS.md` (anchor: `Synthetic-Base`) for the git-state rule that keeps a design commit off a rewritten base.
- **Measurement point:** every count in this document was re-derived at commit `d7ede1f` in the isolated worktree `pk-wt-789`, on branch `rfc/789-ecosystem-enforcement-spec`. Counts are stated with their basis because the issue body carries three of them and only two reconcile exactly (§1.5).
- **Verification:** §10. The commands there are the complete T1 gate; no behavioral suite runs at this stage because no behavior changed.

--------

## 1. Problem Statement

The product makes a specific promise about its own strength: `docs/ENFORCEMENT.md` (anchor: `The PromptKit OS Enforcement Ladder`) maps what binds where, and it states that the ladder descends as it leaves the kit repository — `CI can reject a commit; pk:doctor can only report; the directive can only instruct`. The gap the issue calls ecosystem enforcement is the distance between that honest self-description and what a consumer of the kit can actually acquire. Four findings block closing it, and each one is independently sufficient.

### 1.1 Gap 1 — the consumer Tier-1 vacuum

Every mechanical gate in the repository inspects the repository. `docs/ENFORCEMENT.md` §1 states the default posture of Tier 1 in a user project as `**Never applies.** A user project inherits none of it`, §2 restates it as `A user project that installs PromptKit OS gets **zero** of these gates`, and §3 records that Tier 2 has no scheduler at all: `No hook, no pipeline, no pre-commit wiring exists by default`.

The document already names the escape hatch and its cost, in §6: `wiring the shipped validators into your own CI is possible (they are plain scripts), but it is a user-side integration, not a shipped feature`. That sentence is the whole of the current consumer story. A consumer who wants the kit's own standards enforced must read the CI workflow, reverse-engineer which dozen of its 12 jobs apply to a project that is not the kit, reproduce the twin dispatch on their own runner, and accept that the result is unsupported and undocumented. The kit ships the checks and then declines to say how to use them.

Consequence for the issue: there is no product to sell, only an unbundled pile of validators. Any enforcement pack has to begin by inventing a consumer distribution channel, which is Decision 1.

### 1.2 Gap 2 — deterministic host hook surfaces are unclaimed

`docs/ENFORCEMENT.md` §4 states the boundary in the negative: `PromptKit OS ships **no daemon, hook, or interceptor** that can block an edit, abort a turn, or force a zoom-out.` §5 qualifies it with the only two executables that exist, and §5's closing line fixes their scope: `Neither generalizes into a governance daemon, and none is planned.`

The evidence base is advisory-only, by construction. `docs/HOST-CONFORMANCE.md` §2 lists five probes and a fixture matrix; §4 carries 11 host rows, of which 3 are `**PARTIAL**` (Antigravity / Gemini CLI, OpenCode, Command Code CLI) and 8 are `Untested`. Section 2's cross-host table records `**Live Runtime Fidelity**` as `**Untested**` for all three hosts it covers. The behavioral evaluator grades only the assistant's prose: `docs/BEHAVIORAL-EVAL.md` (anchor: `These four grade **the model's own words only**`). Nothing in the tree captures a lifecycle event at all.

So the kit cannot answer the question a pack would have to answer — which host, if any, would actually block a write on instruction — and it cannot say what a pack must emit to satisfy a host that does expose such a surface. The issue names `PreToolUse` and `Stop`; against this tree the PromptKit validation status of every such surface is `NONE`, not `Untested`. `Untested` means a probe exists and has not been run for that host. `NONE` means no probe, no fixture, and no registry row exist for that surface anywhere.

Consequence: any enforcement pack that ships before Decision 2 is settled must be labeled advisory, which is the product the kit already ships. Decision 2 is therefore a gate on the whole idea, not a detail.

### 1.3 Gap 3 — legacy flat host files versus progressive discovery

`init.sh` maps each supported host to one flat file — `host_file` returns `.cursorrules` for `cursor`, `.windsurfrules` for `windsurf`, `.github/copilot-instructions.md` for `copilot`, and the same shape for `cline`, `trae`, `aider`, and the universal `AGENTS.md`. The native progressively discovered location appears only in a migration branch: `init.sh` detects a pre-existing `.cursor/rules/promptkit.mdc` so an older install is still recognized, but the file it writes is `.cursorrules`.

That choice has a measured cost. The Antigravity double-injection finding in `docs/HOST-CONFORMANCE.md` records one Balanced directive at `9,936 B ≈ 2,484 tok` by `scripts/measure-tokens.sh`, against a host aggregate rules budget — a number that only matters because a flat file is loaded whether or not the turn needs it. A pack that is merely a larger flat file would make the one cost the kit already fights worse.

The kit also has no artifact for the progressive form. `SKILL.md` appears exactly once outside captures, as a literal written by a benchmark-driver test (`scripts/tests/run-benchmark-driver-tests.sh`), and the repo ships no skill artifact at all. That is a statement about the kit, not about hosts: hosts that discover scoped rule files or skill packages are simply unaddressed.

Consequence: a pack needs a generation contract with one canonical body and several native render targets, and that contract has to be idempotent and drift-checked. Decision 3.

### 1.4 Gap 4 — dual-shell maintenance tax and scorer literalism

The cross-platform surface is genuinely large, and the parity discipline that keeps it honest is also the tax on every new check.

| Twin | Bash | PowerShell | Pair lines |
| :--- | :--- | :--- | ---: |
| Installer | `init.sh` 1,464 | `init.ps1` 1,519 | 2,983 |
| Behavioral evaluator | `scripts/run-behavioral-eval.sh` 1,421 | `scripts/run-behavioral-eval.ps1` 1,426 | 2,847 |
| Execution-control validator | `scripts/validate-execution-control.sh` 1,358 | `scripts/validate-execution-control.ps1` 1,254 | 2,612 |
| Behavioral contract tests | `scripts/tests/run-behavioral-contract-tests.sh` 2,436 | `scripts/tests/run-behavioral-contract-tests.ps1` 2,168 | 4,604 |

Those four pairs are 13,046 lines maintained twice and asserted equal by twins in CI (`docs/ENFORCEMENT.md` (anchor: `installer safety, twin parity`)). Every new pack check pays that tax twice unless the check is written in the one language both shells already forward to — a precedent that exists for two scripts only (`scripts/render-capture-transcript.{sh,ps1}` and `scripts/capture-host-session.{sh,ps1}` both exec an `.mjs` implementation).

The second half of Gap 4 is the rubric the pack would be graded by. `docs/BEHAVIORAL-EVAL.md` (anchor: `### Check types`) defines exactly four presentation checks — `first-line-matches`, `contains`, `not-contains`, `contains-any` — each decided by an ERE over the assistant text, and none of them is case-insensitive. The consequence is visible in the kit's own captures rather than hypothesized: `docs/HOST-CONFORMANCE.md` records `breaker-exhaustion` as `PARTIAL` because the model `failed only for not spelling HALT in capitals`, and records a `milestone-halt` run where `The two misses are literal` — `verification passed` and `[!IMPORTANT]` were both absent from a callout that made the same commitment in other words. A shipped fixture depends on literal glyphs at the byte level: `scripts/tests/eval-scenarios/halt-framed-style.md` requires the framed banner literally.

Consequence: a pack would be graded by an instrument that measures spelling as much as behavior. Adding deterministic enforcement on top of that would multiply a measurable false-negative rate, so the rubric needs its own bounded ruling (Decision 3, §6.5) before any pack can claim a pass means pass.

### 1.5 Measured inventory and reconciliation

| Surface | Count | Lines | Basis | Issue #789 | Delta |
| :--- | ---: | ---: | :--- | ---: | :--- |
| Tracked shell scripts | 86 | 31,045 | `git ls-files '*.sh'`, `wc -l` per file | — | — |
| Extensionless entry point | 1 | 46 | `scripts/pk`, tracked, no extension | — | — |
| Shell total | 87 | 31,091 | above two rows combined | 87 / 31,095 | +4 lines in the issue |
| PowerShell scripts | 75 | 25,122 | `git ls-files '*.ps1'`, `wc -l` per file | 25,123 | matches when the unterminated final line counts |
| Node ESM implementations | 4 | 2,011 | `git ls-files '*.mjs'` | — | — |
| Twin pairs above | 8 | 13,046 | the table in §1.4 | more than 12,000 | consistent with the claim |
| CI jobs | 12 | 898 workflow lines | `.github/workflows/ci.yml` | — | — |
| Validated hook surfaces | 0 | — | `grep` for `PreToolUse` / `Stop` hook captures: no matches | — | — |
| Registry host rows / `PARTIAL` / `Untested` | 11 / 3 / 8 | — | `docs/HOST-CONFORMANCE.md` §4 | — | — |

**The one figure that does not reconcile is the shell total.** The issue states 87 files and 31,095 lines; the measured tree is 87 files and 31,091 lines. The file count matches because `scripts/pk` carries 46 lines and is the only extensionless shell file, and every tracked `*.sh` sums to 31,045. Four lines cannot be attributed to any tracked shell file: `scripts/pk` has carried 46 lines since its only commit (`1ca82cb`), and the PowerShell 25,123 reading — which does reconcile — comes from a trailing-newline count, not a shell file. The likely explanations are a different counting basis in the issue or a stale figure; neither is recoverable from the tree.

**Ruling (measurement basis):** T1 adopts the measured figures with their method stated, records the issue figure as a claim of record, and does not restate either as a target. Every later stage cites the number together with its basis, so a recount that differs is visible as a recount rather than as drift. This is the same honesty rule the kit applies to host captures: a number without its method is an attitude. The four-line delta changes no decision — it is 0.013 percent of the total — which is exactly why adopting the issue number silently would be a cheaper lie and a worse precedent.

--------

## 2. Current-State Map

Nothing in this section is proposed; it is the inventory a pack must extend rather than duplicate.

| Concern | Existing mechanism | Where | What it does not do |
| :--- | :--- | :--- | :--- |
| Enforcement ladder | Three tiers, descending strength | `docs/ENFORCEMENT.md` §1–§4 | Tier 1 does not travel to a consumer |
| Opt-in executables | Two managed-block hook installers, fail-closed, removable | `scripts/install-attribution-hook.sh`, `scripts/install-benchmark-task-card-hook.sh` | Scoped to one artifact class each; neither is a pack |
| Host validation | Five probes, fixture matrix, 11-host registry | `docs/HOST-CONFORMANCE.md` | No lifecycle-hook probe, no hook evidence |
| Behavioral rubric | Four presentation checks, ERE over assistant text | `docs/BEHAVIORAL-EVAL.md`, `scripts/run-behavioral-eval.sh` | Case-sensitive only; no case-folded variant |
| Cross-platform logic | Node ESM implementations behind thin shell forwarders | `scripts/render-capture-transcript.{sh,ps1}` → `.mjs`; `scripts/capture-host-session.{sh,ps1}` → `.mjs` | Two pairs consolidated out of four twin pairs |
| CI | 12 jobs on `ubuntu-latest` and `windows-latest` only | `.github/workflows/ci.yml` | No `shellcheck`, no `PSScriptAnalyzer`, no macOS job |
| Installer | Host file map, managed directive block, idempotency tests | `init.sh`, `init.ps1` | Flat host files only; no hook installation, by design |

### 2.1 The pattern any future executable must follow

`docs/ENFORCEMENT.md` (anchor: `Both hooks follow the same shape: **opt-in, reversible, managed-block, single-purpose, scoped to one artifact class**. That is the pattern any future executable enforcement would have to follow.`) This is a hard constraint on Decisions 1–3, not a stylistic preference. Two of its properties are load-bearing for everything below: *managed-block* means the installer owns a delimited region and nothing else, and *reversible* means removal restores the file, not that removal is offered.

### 2.2 The cross-platform precedent

`scripts/render-capture-transcript.sh` states its own scope: `This is a thin forwarder. The renderer itself lives in scripts/render-capture-transcript.mjs`. The rationale is the drift argument, in the same sentence — the two shells exist so the behavior is identical `by construction rather than by review: there is no second copy to drift`. The PowerShell twin adds the failure contract T1 reuses: a missing `node` exits 2 rather than pretending to pass. Selective consolidation (§6.3) is an application of this precedent, not a new idea.

--------

## 3. Stage Gates

| Stage | Question it answers | Deliverable | Exit gate | Explicitly out of scope |
| :--- | :--- | :--- | :--- | :--- |
| T1 (this record) | What would a pack be, and under which rules? | This specification and its task record | Merged design with the three rulings confirmed; zero code change | Any `.sh`, `.ps1`, `.mjs`, workflow, `init*`, template, protocol, or hook edit |
| T2 (pilot) | Does one pack, on one host, with one hook, actually enforce? | One consumer entry point, one pack, one host install path behind `--with-hooks`, idempotency and drift fixtures, a capture registered in `docs/HOST-CONFORMANCE.md` | `shellcheck` and `PSScriptAnalyzer` green on touched files; re-run and `--remove` proven byte-identical; hook capture passes the five conditions in §5.3 | Second host, pack registry, marketplace, rollout docs |
| T3 (rollout) | Does it generalize without lying about it? | Documented consumer channel, per-host cells with evidence or explicit `NONE`, migration note | Every shipped cell carries a capture or is labeled advisory; `docs/ENFORCEMENT.md` states the consumer tier | Hosted checker, telemetry, pricing |

**What T1 authorizes:** exactly two documents and one changelog line. The issue's non-goal — zero code changes in T1 — is treated as a ceiling, not a floor: this stage does not add a test, a fixture, or a workflow step that would begin implementing the design.

**Gate accounting:** T2's exit gate reuses four invariants from §7 verbatim (I2 managed-block, I3 no installer-installed hooks, I4 exit contract, I5 one implementation). A stage that cannot meet its gate does not proceed with a caveat; it returns to the decision and reopens it.

--------

## 4. Decision 1 — Consumer Distribution Channel

**Question:** how does a consumer acquire enforcement — ship the checks and let the consumer wire them into their own pipeline, publish a reusable CI Action, or both?

| Criterion | A. Templates plus opt-in local wiring | B. Reusable GitHub Action | C. Both, staged, one entry point |
| :--- | :--- | :--- | :--- |
| Works with no CI at all | yes | no | yes |
| Works on GitLab, Gitea, local hooks | yes | no | yes |
| Needs no npm dependency or network | yes | yes | yes |
| Reversible by the consumer | delete the hook block | delete the workflow step | either |
| Idempotency burden on the kit | high — must define re-run semantics | none — declarative | high, but defined once |
| Maintenance surface | dual-shell tax continues | one wrapper, but a second check definition unless it calls A | one definition, two front doors |
| Time to first value | one command | edit a workflow file | one command, then a workflow file |
| Discoverability for open-source consumers | low | high | high after A exists |

**Ruling D1: Option C — staged as A then B, over a single hermetic entry point.**

Rationale, in the order it binds:

1. **A must come first because the checks are not a product yet.** `docs/ENFORCEMENT.md` §6 already concedes that consumer wiring is `a user-side integration, not a shipped feature`. Option A converts that concession into a supported path over scripts the kit already audits with. It needs no new hosting, no marketplace metadata, and no release cadence.
2. **B must not define check logic.** A reusable Action that reimplements the checks would recreate the second copy the `.mjs` precedent exists to prevent (`scripts/render-capture-transcript.sh` (anchor: `there is no second copy to drift`)). B is therefore a wrapper that invokes A's entry point with a pinned ref, which also means B cannot ship before the entry point has a stable contract.
3. **The entry point is the actual deliverable.** Exit codes `0` pass, `1` violation, `2` error and fail-closed; a `--root` argument; machine-readable `KEY|VALUE` lines on stdout; no writes, no network, no interactive prompts. Both front doors call it. Its contract is small enough to freeze at T2 and is the only interface B depends on.

**Ordering constraint:** A defines the entry point; B wraps it. If B is ever built first, D1 is violated regardless of what ships.

**Reversal conditions:** if no consumer uses GitHub by T3, B is dropped and A stands alone; if A cannot satisfy the idempotency contract in §6.1, both options are blocked rather than weakened, because a non-idempotent installer is the failure the two shipped executables spent their entire design avoiding.

**Consequences for later stages:** T2 must produce the entry point, the installer, and the hook opt-in path; T3 may produce the Action wrapper and the consumer documentation. Neither stage may add a check that the entry point does not own.

--------

## 5. Decision 2 — Deterministic Host-Hook Matrix

### 5.1 Two channels, not one spectrum

| Channel | Who decides | Evidence in this tree | Can it block a tool call? |
| :--- | :--- | :--- | :--- |
| Advisory directive | the host model | 11 registry rows, 5 probes, 40+ rendered captures | no |
| Deterministic lifecycle hook | the host runtime, if it executes one | zero captures, zero fixtures, zero registry rows | only if the host documents and executes it |

The distinction is not rhetorical. Every artifact in `docs/internal/host-conformance/` is a rendered transcript graded as assistant text — `docs/BEHAVIORAL-EVAL.md` (anchor: `These four grade **the model's own words only**`) — so the entire evidence base measures the first channel. The second channel has no evidence at all, which is why §5.3 defaults closed.

### 5.2 The matrix

The issue asserts that at least two hosts document lifecycle surfaces (`PreToolUse`, `Stop`). T1 records that as a claim and does not restate vendor semantics, because no vendor documentation was read for this record and quoting a schema the tree has never executed would violate the same evidence rule the rest of the document follows. The column below is therefore *claimed in the issue*, and the enforcement column is *measured in this tree*.

| Host | Lifecycle surface claimed in issue #789 | PromptKit validation | Enforcement this cell may claim | T2 pilot candidate |
| :--- | :--- | :---: | :--- | :---: |
| Claude Code CLI | `PreToolUse`, `Stop` | `NONE` | none until a capture exists | yes |
| Cursor Composer | hook surface claimed | `NONE` | none until a capture exists | no (T3) |
| GitHub Copilot Agent | none claimed | `NONE` | advisory only | no |
| Antigravity / Gemini CLI | none claimed | `NONE` | advisory only (`PARTIAL` host evidence) | no |
| OpenCode | none claimed | `NONE` | advisory only (`PARTIAL` host evidence) | no |
| Command Code CLI | none claimed | `NONE` | advisory only (`PARTIAL` host evidence) | no |
| Windsurf, Cline / Roo, Trae, Aider, Codex CLI | none claimed | `NONE` | advisory only (`Untested` host evidence) | no |

`NONE` is deliberately distinct from the registry's `Untested`. A registry row marked `Untested` means a probe exists and has not been run against that host; `docs/HOST-CONFORMANCE.md` §1 insists that `Untested Boundaries Are Never Implied`. A hook cell marked `NONE` means the capability itself has never been probed anywhere, so even the question is open. Collapsing the two would let a future reader think a hook probe is merely queued for a host. It is not scheduled at all until T2 defines the probe.

T2 pilot selection is one host and one surface, and the honest reason to prefer `PreToolUse` is that a deny is observable inside a single turn: the capture either shows the tool call blocked or it does not. A `Stop` hook's effect is observable only across a turn boundary, which the registry already shows is exactly where the observed state is least trustworthy (the Antigravity resume capture in §4 records the model accepting `its own requested token as human sign-off`).

### 5.3 Default-deny rule

A hook cell moves off `NONE` only when a capture satisfies all five conditions. Until then the only permitted consumer-facing sentence is *advisory only*.

1. **Pinned host version,** recorded in the capture provenance beside the commit and the date.
2. **Documented configuration path,** stated in the capture: which file the hook is installed into, and how the host was told to run it.
3. **Both outcomes shown,** allow and deny on the same host, in the same session shape.
4. **Fail-closed on checker error,** shown by forcing exit `2` and observing the tool call blocked rather than allowed.
5. **Opt-in and removable,** shown by installing and removing with the check absent from the default install path.

Rules that follow from the same principle, and are not negotiable at T2 or later: a user-supplied hook configuration is not evidence; a model's own claim that it would block is not evidence, which is the exact failure the milestone-halt resume capture documents; and a hook that cannot block on exit `2` cannot enforce, because an enforcement path whose error state allows is an advisory path with extra steps.

If a host's runtime treats hooks as suggestions, the capture will show it and the cell stays `NONE` permanently. §8 records what that would mean for the design.

### 5.4 The PromptKit side of the hook contract

T1 fixes only what the kit owns, because every host-side schema is unread:

- the checker's exit codes are `0` pass, `1` violation, `2` error;
- `2` must be treated by the installed hook as blocking, matching the shipped precedent in `docs/ENFORCEMENT.md` §5a where the installed line ends `|| exit 1` and an unreadable payload blocks the commit;
- the checker never writes, never opens a socket, and never prompts;
- the same input produces the same exit code, with no clock or environment dependence. A check that cannot be made deterministic does not belong in this channel.

### 5.5 What a hook must never claim

A block is not a change. A `PreToolUse` deny prevents an edit; a `Stop` hook prevents a turn from ending cleanly; neither repairs what already happened. Consumer documentation must state the surface a check binds to — before the write, at the end of the turn, or at commit time — because *before the write* and *after the write* are different products and the kit has repeatedly overstated the weaker one. This is the same honesty requirement as `docs/ENFORCEMENT.md` §6's list of what the ladder does not claim.

--------

## 6. Decision 3 — Idempotency and Progressive-Discovery Contract

### 6.1 The idempotency contract

Every installed artifact is owner-scoped, re-entrant, reversible, and drift-checkable. The existing executables already meet this, and their header states the properties together: `--remove restores the original byte-for-byte and mode-for-mode. Installing and removing are explicit and idempotent` (`scripts/install-attribution-hook.sh`).

| Property | Requirement | How it is proven |
| :--- | :--- | :--- |
| Marker-managed | The installer owns exactly the region between `# >>> PROMPTKIT_<NAME> >>>` and `# <<< PROMPTKIT_<NAME> <<<` (the two shipped installers use this exact pair) | grep the markers, assert one pair per install |
| Re-entrant | A second identical run leaves the file byte-identical | sha256 before and after, fixture |
| Reversible | `--remove` restores the file byte-for-byte, including mode | sha256 and mode before install, after remove |
| Drift-detectable | `--check` exits `1` when the installed region differs from the shipped body | mutate one byte, assert exit `1` and no write |
| Non-destructive on conflict | Pre-existing foreign content is preserved; a user edit inside the managed region makes `--remove` refuse with exit `2` rather than delete it | fixture with edited region |
| Deterministic body | The managed region is a pure function of pack id, profile, and host; no timestamps, no absolute paths, no version strings inside the region | generate twice from different directories, compare |

The last row is the one a pack is most likely to break, because a version stamp inside the block is the obvious way to detect staleness and it destroys byte-stability. Staleness is detected by comparing the region against a freshly rendered body, not by writing the version into the region.

### 6.2 The progressive-discovery contract

A pack has one canonical body and several render targets. Host artifacts are generated from the canonical body, never hand-edited, and never carry content that is not derived from it. This is what makes the flat-to-native transition a rendering change rather than a second source of truth.

| Target class | Discovery unit | Status in this tree |
| :--- | :--- | :--- |
| Universal flat file | `AGENTS.md` | shipped and exercised; `init.sh` writes it |
| Host flat files | `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, `.clinerules`, `.traerules`, `.github/copilot-instructions.md`, `CONVENTIONS.md` | shipped via the `host_file` map |
| Native scoped rules | `.cursor/rules/*.mdc` | recognized only as a pre-existing install; never written |
| Native skill packages | `SKILL.md` directories | not shipped anywhere in the tree |

Rules:

1. **A native target ships only after the kit has produced it in a T2 capture.** The issue asserts these formats exist; the tree has never written one. Until a capture shows the host loading the artifact, the pack ships the flat fallback.
2. **The flat fallback is labeled.** Its cost is disclosed with a measured number, not an adjective, using `scripts/measure-tokens.sh` and the budget asserted in `docs/BENCHMARKS.md`.
3. **Generated artifacts carry a machine-checkable provenance header** naming the canonical source path and its content hash. The exact syntax is fixed at T2; what T1 fixes is that it must be checkable by `--check` without executing the pack.
4. **A stale artifact is an error under `--strict`,** not a warning. Drift between canonical body and rendered target is the failure mode progressive discovery invites, because the native artifact loads silently.
5. **Nested scoping is opt-in per pack.** One root artifact is the T2 default; per-directory scoping requires its own capture, because discovery order is host-specific and unmeasured.

### 6.3 Selective consolidation to Node ESM

Consolidation is permitted only when all four hold:

1. the logic is a pure text or file transform with no host interaction and no privilege;
2. both shells can become thin forwarders, keeping the parity tests as the parity proof;
3. a missing `node` fails loudly with exit `2` (the `scripts/render-capture-transcript.ps1` contract), not silently;
4. the bash forwarder keeps its `command -v node` guard and its `exec node` handoff, so the process tree and exit code are unchanged.

| Twin pair | Candidate | Reason |
| :--- | :---: | :--- |
| `init.sh` / `init.ps1` | no — excluded permanently | interactive TTY prompts, host detection, and filesystem mutation; the least deterministic code in the tree |
| `scripts/run-behavioral-eval.{sh,ps1}` | yes | regex scoring over rendered text is the pure-transform case the precedent was built for |
| `scripts/validate-execution-control.{sh,ps1}` | yes | parse-and-report over files; no host interaction |
| `scripts/tests/run-behavioral-contract-tests.{sh,ps1}` | yes, lowest priority | mostly text assertions, but the harness also spawns suites |

**Ruling:** at most one pair is consolidated in T2, chosen by size times divergence risk, and no pair is consolidated in T1. The 13,046-line twin surface is a real tax, but each conversion is a behavior-preserving rewrite that needs its own fixtures, and doing one inside a docs-only stage would break the stage's own zero-code gate. The excluded pair is excluded permanently rather than deprioritized: an installer that asks questions and rewrites host files is not a transform, and hiding it behind Node would move the least testable code into the least reviewed place.

### 6.4 CI gates: shellcheck, PSScriptAnalyzer, macOS

| Gate | Runner | Scope at admission | Why this scope |
| :--- | :--- | :--- | :--- |
| `shellcheck` | `ubuntu-latest` | changed `*.sh` files in the diff, severity error plus warning | 31,045 lines have never been linted; a whole-tree gate would open red on day one and be disabled within a week |
| `PSScriptAnalyzer` | `windows-latest` | changed `*.ps1` files, pinned version, documented suppressions | same baseline problem, plus rule-version drift |
| macOS subset | `macos-latest` | one job: reference validation, changelog gate, shell smoke | BSD userland is the untested axis; the workflow currently has no macOS job at all |

All three are admitted at T2 as changed-files-only, promoted to whole-tree only after a baseline lands. None is admitted in T1, because this record edits no workflow. Adding them changes what Tier 1 asserts, so `docs/ENFORCEMENT.md` §2 must be updated in the same T2 change that adds the jobs — a documentation obligation this record records but does not discharge.

Cost is stated rather than hidden: one new Linux job, one new Windows job, one new macOS job. The Windows and macOS jobs are the expensive ones, and the macOS job is deliberately a subset for that reason.

### 6.5 Rubric matching and `contains-i:`

The issue asks T1 to resolve case-insensitive matching. The observed failures are spelling failures, not comprehension failures: `docs/HOST-CONFORMANCE.md` records `breaker-exhaustion` as `PARTIAL` where the model `halted correctly but never wrote the literal HALT`, and a `milestone-halt` run where `Three of four rubric misses are literal`.

**Ruling D3.1: add case-insensitive variants of all three content checks — `contains-i:`, `not-contains-i:`, and `contains-any-i:` — rather than a case-insensitive mode for `contains` alone, or a case-insensitivity flag on the whole fixture.**

Rationale: a flag applied to one polarity leaves `not-contains` case-sensitive, so a model that writes `Halt` would pass the positive check and also slip past the negative one — a strictly worse grader than today's, because it would look more forgiving while still grading the wrong surface. A whole-fixture flag would silently change every existing fixture, including the ones whose literalism is deliberate (`scripts/tests/eval-scenarios/halt-framed-style.md`), turning a narrow fix into an unmeasured sweep. Three explicit variants keep adoption per-check and reviewable.

Fixed semantics, so the two scorers cannot diverge:

- the payload remains a POSIX ERE; only case folding is added;
- matching still reads the assistant text blocks only, with indentation preserved and `^` anchored at plain-prose line starts;
- `contains-any-i:` splits on `|` exactly like `contains-any:` and matches if any alternative does;
- existing checks keep their current semantics, so no fixture is required to migrate.

**Non-goal:** no fuzzy, edit-distance, or semantic matching. A vocabulary miss that is not a case miss stays a miss, and the registry keeps recording it. The instrument should stop grading capital letters, not start grading approximations.

**Landing point:** `docs/BEHAVIORAL-EVAL.md`'s check-type table, both scorers, and both contract suites, in one T2 change with a fixture proving `Halt` and `HALT` both pass `contains-i: HALT` and both fail `contains: HALT`.

--------

## 7. Non-Goals and Invariants

### 7.1 Non-goals

- Zero code changes in T1. This record touches no `.sh`, `.ps1`, `.mjs`, `.yml`, `.gitattributes`, `init*`, template, protocol, or workflow file.
- No background daemon, proxy server, mandatory npm dependency, or network service — ever, at any stage, not just T1.
- No silent install. No Git or IDE hook is installed without an explicit opt-in command (`--with-hooks` or an `install-*` script). `init.sh` and `init.ps1` install no hooks, and T2 does not change that.
- No T2 or T3 authorization: no pack registry, marketplace, pricing, telemetry, hosted checker, or multi-host support.
- No change to the three existing ladder tiers or to the two shipped executables.
- No rubric capability beyond the case variants in §6.5, and no semantic grading.
- No consolidation of `init.sh` / `init.ps1`, at any stage.
- No vendor hook schema restated in kit documentation. T1 cites none because none was read.

### 7.2 Invariants

1. **I1 — Evidence before claim.** A capability is described as enforced only with a capture; otherwise it is described as advisory (`docs/HOST-CONFORMANCE.md` §1: `Untested Boundaries Are Never Implied`).
2. **I2 — One managed region, one owner.** Every installed artifact uses the marker pair and can be removed byte-for-byte (§6.1).
3. **I3 — The installer installs no enforcement.** `docs/ENFORCEMENT.md` §5: `Neither hook is installed by the installer, the courier, or CI`.
4. **I4 — Exit codes are a contract.** `0` pass, `1` violation, `2` error that fails closed.
5. **I5 — One implementation per cross-platform behavior.** Shells forward; they do not fork (§6.3, `there is no second copy to drift`).
6. **I6 — Parity is a gate.** Twin suites remain the proof, including after consolidation.
7. **I7 — Consumer gates are consumer-owned.** Tier 1 inspects the kit's tree (`Every one of these checks inspects the kit's tree`); a consumer gate is a separate artifact the consumer installs and can delete.
8. **I8 — No silent context cost.** A pack that is always-loaded discloses its measured token cost and only ships as a fallback.

--------

## 8. Risks and Open Questions

| Risk | Where it bites | Mitigation | Residual |
| :--- | :--- | :--- | :--- |
| Host lifecycle surfaces change without notice | the matrix goes stale silently | every cell records host version plus capture date; default-deny | a shipped cell can decay between captures |
| A host treats hooks as advisory | the whole enforcement thesis | the T2 capture must show exit `2` blocking | if it cannot, packs are advisory-only and D2 collapses to D1 |
| Silent enforcement breaks a consumer workflow | trust | opt-in, `--check` before install, `--remove` | a consumer who ignores the plan output can still be surprised |
| Consolidation changes scorer behavior | every verdict | one pair per stage, parity fixtures first, forwarders kept | one pair may prove unconvertible |
| `shellcheck` on an unbaselined tree | CI availability | changed-files-only, then baseline | baseline may be large enough to deprioritize |
| macOS job cost and flake | CI minutes | Tier-1 subset only, one job | subset misses BSD-specific breakage outside the subset |
| `contains-i:` masks real literalism | grading strictness | case-sensitive stays the default; per-check adoption; registry keeps the miss record | reviewers may adopt it too broadly |
| Consumer gate mistaken for kit Tier 1 | the honesty contract | every doc names the tier explicitly; `docs/ENFORCEMENT.md` gains a consumer section at T2 | documentation lag between code and ladder |

**The question that could invalidate the design:** if a `PreToolUse` capture shows the host allows a tool call after the hook exits `2`, then deterministic host-side enforcement does not exist for that host, Decision 2 produces no usable cells, and the ecosystem story reduces to Decision 1 — checks at commit time, measured, reversible, and honestly advisory during the turn. That outcome is a valid result, not a failure: it would make the ladder's existing honesty the shipped product, with the Tier-1 vacuum filled at the only layer the kit actually controls.

Open questions, each with what resolves it:

| # | Question | Resolved by |
| :---: | :--- | :--- |
| Q1 | `PreToolUse` or `Stop` for the T2 pilot? | the phase-1 capture that can show allow and deny in one turn |
| Q2 | Does the consumer entry point need a PowerShell twin at all? | T2 measurement of Windows consumer demand against the changed-files gate |
| Q3 | Is a reusable Action acceptable if it must pin a tag and a SHA? | owner ruling at T3, with the entry-point contract frozen |
| Q4 | Which twin pair consolidates first? | T2 divergence measurement using the existing parity suites |
| Q5 | Does T2 need per-directory scoping, or is one root artifact enough? | the single-host T2 capture of discovery order |
| Q6 | Is a warn-only mode (`--warn`, exit `0` with findings) ever allowed? | deferred; T2 exports only `0`/`1`/`2` |

--------

## 9. Acceptance Criteria

- [ ] **AC-1** — This specification exists at `docs/specs/2026-11-26-spec-ecosystem-enforcement-packs.md` and answers D1, D2, and D3, each with an explicit ruling, its rationale, and its reversal condition.
- [ ] **AC-2** — Every quantitative claim states its measurement basis, and §1.5 reconciles the one figure that does not reproduce.
- [ ] **AC-3** — Every hook cell records `NONE` with the five promotion conditions from §5.3, and no vendor schema is restated.
- [ ] **AC-4** — Zero code change: `git diff --name-only` lists exactly three files, and none of them is a script, workflow, installer, template, or protocol.
- [ ] **AC-5** — The T1 task record exists, validates as `L2` Controlled Work, and records its acceptance results and transition history.
- [ ] **AC-6** — `CHANGELOG.md` carries exactly one `[Unreleased]` `### Documentation` bullet, and no heading repeats within that section.
- [ ] **AC-7** — The commands in §10 pass on the committed tree.

--------

## 10. Automated Verification Command

```bash
bash scripts/validate-references.sh . --strict
bash scripts/check-changelog-entry.sh
git diff --check
git status --short
```

Expected: the first command passes with no broken links or template references; the second passes with `CHANGELOG_GATE|PASS` — a docs-only range carries no behavior-surface path, and the structural check has no repeated heading to reject; `git diff --check` prints nothing; `git status --short` lists exactly the three files in AC-4.

No PowerShell suite runs at this stage. The repository's `pwsh` is an unusable shim in this environment, and no behavior changed, so there is no .ps1 subject to exercise. That omission is stated here rather than left for a reader to infer from an empty log.

