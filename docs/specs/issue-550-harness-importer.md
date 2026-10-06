### Metadata

* **Related Spec:** `scripts/validate-execution-control.sh` (anchor: `validate_checkpoint() {`), `scripts/validate-execution-control.sh` (anchor: `validate_handoff() {`), `scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID"`), `scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Handoff ID"`), `scripts/validate-execution-control.sh` (anchor: `local value_labels=("Record Type" "Handoff ID"`), `scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION "$id" "$path" "Host timer capability`), `scripts/validate-execution-control.ps1` (twin), `docs/WORKFLOW-MAP.md` (anchor: `The Task Record is authoritative for Controlled Work`), `docs/WORKFLOW-MAP.md` (anchor: `Controlled readiness, execution state, active ownership, and completion`), `docs/WORKFLOW-MAP.md` (anchor: `Preserves and projects evidence; does not approve, commit, release, deploy, or roll back.`), `docs/WORKFLOW-MAP.md` (anchor: `## Canonical Artifact Contract`), `workflows/checkpoint.md` (anchor: `Phase 4 may synchronize`), `templates/state-tracker-template.md` (anchor: `## 3A. Execution-Control Projection (Optional)`), #553 (tier contract — **must land first**)
* **Priority:** `priority/p2`
* **Labels:** `type:feature`, `area:tooling`, `priority/p2`
* **Work Classification:** `L2` (validator + template contract; proposed SemVer impact `minor`)

--------

## User Story & Context (follow-up to #516)

As a developer who prefers a foreign harness's `/handoff` UX over `pk:checkpoint`,
I want a `/handoff` payload to be mechanically importable into a Checkpoint or Handoff Record with explicit degradation marks,
So that using `/handoff` no longer leaves `docs/STATE.md §3A` empty.

### Authority: this extends the existing hierarchy, it does not compete

The previous draft's framing on this point was wrong and is corrected here. The repository **already** declares the precedence this issue must respect:

* `docs/WORKFLOW-MAP.md` (anchor: `The Task Record is authoritative for Controlled Work`) — "The Task Record is authoritative for Controlled Work. `docs/STATE.md` is a synchronized projection owned by `pk:checkpoint`; external issues, dated breakdowns, board statuses, and conversation claims are supporting references."
* `docs/WORKFLOW-MAP.md` (anchor: `Controlled readiness, execution state, active ownership, and completion`) — Controlled readiness/execution/completion is owned by the canonical Local Task Record; "external trackers and projections cannot override it."
* `docs/WORKFLOW-MAP.md` (anchor: `Preserves and projects evidence; does not approve, commit, release, deploy, or roll back.`) — `pk:checkpoint` "Preserves and projects evidence; does not approve, commit, release, deploy, or roll back."
* `docs/WORKFLOW-MAP.md` (anchor: `## Canonical Artifact Contract`) — the Canonical Artifact Contract is "the single Phase 3 contract … Workflows and templates may explain the contract, but they must not create a competing schema or authority."
* `workflows/checkpoint.md` (anchor: `Phase 4 may synchronize`) — "STATE is a projection owned by `pk:checkpoint`; the canonical `docs/tasks/<task-id>.md` Task Record remains the Local Task Source."

An imported `/handoff` payload is therefore a **supporting reference** that must degrade *into* the existing contract. It never becomes a peer authority, and importing one grants no execution authority.

### Empirical finding: the previous draft's happy path is infeasible

The previous draft claimed a `/handoff` payload of *branch + revision + next action* yields "a valid Checkpoint Record". Measured against the real validator, using this repository's own valid fixture set as baseline:

* Baseline: `bash scripts/validate-execution-control.sh --root <fixtures>` → `VALID|RECORDS=4`
* Baseline + the 5-field happy-path record → **`FAILED|ERRORS=15`**, all `CHECKPOINT_INCOMPLETE`, **0** `TRACEABILITY_MISSING`

**Corrections to the previous draft's stated numbers:**

| Previous draft | Measured |
| :--- | :--- |
| `validate_checkpoint()` — 21 labels | **20** labels (`scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID"`)) |
| `validate_handoff()` — 44 labels | **43** array entries but **42 unique** — `Next Action` is duplicated (`scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Handoff ID"`)) |
| 23 non-placeholder (value-bearing) | **24** value-bearing labels (`scripts/validate-execution-control.sh` (anchor: `local value_labels=("Record Type" "Handoff ID"`)) |

Of the 20 checkpoint labels, **17 require a non-placeholder value** (`scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID"`), rejecting empties and placeholders per `require_value` (`scripts/validate-execution-control.sh` (anchor: `require_value() {`)) / `is_placeholder` (`scripts/validate-execution-control.sh` (anchor: `is_placeholder() {`))) and **3 require presence only** (`scripts/validate-execution-control.sh` (anchor: `[ "$label" = "Changed Files" ] || [ "$label" = "Blockers" ] || [ "$label" = "Scope Changes" ]`): `Changed Files`, `Blockers`, `Scope Changes`). Additional hard gates: `Record Type` must equal `Checkpoint Record` (`scripts/validate-execution-control.sh` (anchor: `[ "$(field_value "$file" "Record Type")" = "Checkpoint Record" ]`)); `Checkpoint ID` must match `CHECKPOINT-YYYY-MM-DD-task-id-sequence` (`scripts/validate-execution-control.sh` (anchor: `diagnostic INVALID_ID "$id" "$path" "Checkpoint ID is not stable`), regex `scripts/validate-execution-control.sh` (anchor: `is_valid_child_id() {`)); and `Task ID` must resolve in `TASK_FILE_BY_ID`, else `TRACEABILITY_MISSING` (`scripts/validate-execution-control.sh` (anchor: `diagnostic TRACEABILITY_MISSING "$id" "$path" "Checkpoint references unknown Task ID`)).

### What already exists (do not duplicate)

* `validate_checkpoint()` / `validate_handoff()` already enforce the target contract; the importer degrades into it, never around it.
* #516 (closed) bound external-harness runs to `pk:auto` boundaries. This issue does **not** reopen that — it adds the *import* half.
* `scratch/body-516.txt` documents the observed M2-written-while-STATE-says-pending divergence.
* `POLICY_LIMITATION` already exists as a validator diagnostic category (`scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION "$id" "$path" "Host timer capability`)) and must be reused, not reinvented.
* `templates/state-tracker-template.md` (anchor: `## 3A. Execution-Control Projection (Optional)`) is the correct home for the projection definition.

### Non-Negotiable Invariants

* **[ ] An imported draft is not a validated checkpoint.** The importer emits a **draft** record; it is valid only once every required field resolves. Never report a partially-imported record as valid.
* **[ ] No silent acceptance:** every unmappable field degrades explicitly (`not measured`, `POLICY_LIMITATION`, `TRACEABILITY_MISSING`) — never inferred, never silently omitted.
* **[ ] No fabricated task identity:** the importer MUST NOT synthesize a Task ID to satisfy `TRACEABILITY_MISSING` (`scripts/validate-execution-control.sh` (anchor: `diagnostic TRACEABILITY_MISSING "$id" "$path" "Handoff references unknown Task ID`)). When the payload has no canonical Task Record, it records the missing linkage and stops short of validity.
* **[ ] No self-authorization** (inherited from #516): importing a payload grants no commit/push/PR authority, and never promotes imported content above its `supporting reference` status (`docs/WORKFLOW-MAP.md` (anchor: `The Task Record is authoritative for Controlled Work`), `docs/WORKFLOW-MAP.md` (anchor: `Controlled readiness, execution state, active ownership, and completion`)).
* **[ ] Token budget and figures repropagated:** `templates/state-tracker-template.md` additions are measured against BALANCED 2,500 / Lite budgets (`scripts/measure-tokens.sh` (anchor: `TOKEN_BUDGET_BALANCED=2500`), `scripts/measure-tokens.sh` (anchor: `TOKEN_BUDGET_LITE=1500`)). This issue also edits `workflows/checkpoint.md`, one of the six files summed into the core-six measurement: run `bash scripts/measure-tokens.sh` (no `--strict`) and read its `Monolithic (core-6 subset derived)` and `Monolithic (full N-workflow set)` lines — even a prose-only addition moves the total. `scripts/tests/run-behavioral-contract-tests.sh` asserts the published cells equal measurement output, so re-measure and update `docs/BENCHMARKS.md` in the same PR (`docs/BENCHMARKS.md` (anchor: `| Core-six Lite subset | 6 | **30,966 tok** |`)).
* **[ ] Twin parity:** validator changes ship in both `.sh` and `.ps1` with identical diagnostics (`CONTRIBUTING.md` (anchor: `**Behavioral Contract & Parity**`), `PROMPTKIT.md` (anchor: `**Bash/PowerShell twin parity**`)).

### Out of Scope

* Harness-specific integration code — PromptKit stays zero-runtime.
* Reopening #516's boundary semantics.
* Changing any `full`-tier label requirement or diagnostic code.
* Making imported records authoritative over Task Records (forbidden by `docs/WORKFLOW-MAP.md` (anchor: `## Canonical Artifact Contract`)).

--------

## Implementation Tasks (The Build)

* [ ] 1. Define the minimal projection in `templates/state-tracker-template.md` (anchor: `## 3A. Execution-Control Projection (Optional)`) as an explicit **field-mapping table over the 20 labels at `scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID"`)**, documenting for each label whether it is (a) supplied by a `/handoff` payload, (b) derivable from local Git state, or (c) requires `POLICY_LIMITATION` degradation. Correct the count from the previous draft's 21 to 20.
* [ ] 2. Implement the importer in `scripts/validate-execution-control.sh` (+ `.ps1` twin) parsing `/handoff` prose into Checkpoint/Handoff fields, reusing the existing `POLICY_LIMITATION` (`scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION "$id" "$path" "Host timer capability`)) and `TRACEABILITY_MISSING` (`scripts/validate-execution-control.sh` (anchor: `diagnostic TRACEABILITY_MISSING "$id" "$path" "Handoff references unknown Task ID`)) diagnostics. Never invent new diagnostic categories for this feature.
* [ ] 3. Emit the result as a **draft** with an explicit validity verdict (`DRAFT-INCOMPLETE` when fields are unresolved), so a caller cannot mistake an imported draft for a validated checkpoint. Record the count of unresolved fields.
* [ ] 4. Bind harness-spawned sessions to the #516 `workflows/auto.md --until review` default (one-line hook, no new semantics).
* [ ] 5. Fixtures under `scripts/tests/fixtures/execution-control/` (+ both twins):
  * **complete** — a payload that resolves every required label → valid, zero diagnostics
  * **minimal** — branch + revision + next action only → `DRAFT-INCOMPLETE` naming exactly which of the 15 unresolved labels are missing
  * **no task record** — a resolvable-looking Task ID with no `docs/tasks/<task-id>.md` → `TRACEABILITY_MISSING`, and no synthesized ID
  * **placeholder rejection** — a payload whose fields are literal placeholders (`N/A`, `TBD`, `[…]`) → `CHECKPOINT_INCOMPLETE`, proving `is_placeholder` (`scripts/validate-execution-control.sh` (anchor: `is_placeholder() {`)) is honored
* [ ] 6. Document the three-store precedence (`docs/tasks/<task-id>.md` canonical → `docs/STATE.md` §3A projection → harness-private store as supporting reference) in `protocols/context-sync.md`, citing `docs/WORKFLOW-MAP.md` (anchor: `The Task Record is authoritative for Controlled Work`), `docs/WORKFLOW-MAP.md` (anchor: `Controlled readiness, execution state, active ownership, and completion`), `docs/WORKFLOW-MAP.md` (anchor: `Preserves and projects evidence; does not approve, commit, release, deploy, or roll back.`). **Do not** reference `AGENTS.md` line numbers — no tracked `AGENTS.md` exists in this repository and those line numbers are unverifiable. `handoff.md` is not a PromptKit artifact; records live under `docs/tasks/`.
* [ ] 7. Update `CHANGELOG.md` (`[Unreleased]`).

> **Dependency:** the tier shape must be reconciled with #553 first, since #553 currently proposes a 5-field `quick` tier whose `Task ID` cannot resolve at L0/L1 (see that issue). Land the joint contract before implementing either importer.

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: Complete payload becomes a valid record

* Given a `/handoff` payload supplying branch, revision, next action, **and** a Task ID that resolves to an existing `docs/tasks/<task-id>.md`,
* When the importer runs,
* Then the emitted record satisfies **all 20** labels at `scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID"`) — 17 with non-placeholder values plus the 3 presence-only labels — and the validator reports **zero** `CHECKPOINT_INCOMPLETE` and **zero** `TRACEABILITY_MISSING` for that record.

### Scenario 2: Minimal payload is an honest draft

* Given a `/handoff` payload containing only branch, revision, and next action,
* When the importer runs,
* Then the result is `DRAFT-INCOMPLETE`, and it names **15** unresolved labels — `Specification`, `Created`, `Checkpoint Type`, `Execution State`, `Objective`, `Completed Work`, `Remaining Work`, `Changed Files`, `Locked Decisions and Invariants`, `Verification Evidence`, `CI Evidence`, `Blockers`, `Scope Changes`, `Resume Condition`, `Recorded By` — and does **not** claim validity.

> Reproduces the measured baseline: `FAILED|ERRORS=15` against this repository's own fixture set.

### Scenario 3: No canonical Task Record

* Given a payload with a Task ID that does **not** resolve to an existing Task Record,
* When the importer runs,
* Then it reports `TRACEABILITY_MISSING` per `scripts/validate-execution-control.sh` (anchor: `diagnostic TRACEABILITY_MISSING "$id" "$path" "Handoff references unknown Task ID`), records the missing linkage, and does **not** synthesize a Task ID to force a pass.

### Scenario 4: Placeholders do not satisfy required values

* Given a payload whose `Objective` is `TBD` and whose `Next Action` is `N/A`,
* When the importer runs,
* Then both are reported as unresolved — `require_value` (`scripts/validate-execution-control.sh` (anchor: `require_value() {`)) rejects placeholders via `is_placeholder` (`scripts/validate-execution-control.sh` (anchor: `is_placeholder() {`)).

### Scenario 5: Imported content stays a supporting reference

* Given a valid imported record for a Controlled (L2) task whose canonical Task Record says otherwise,
* When execution proceeds,
* Then the Task Record remains authoritative per `docs/WORKFLOW-MAP.md` (anchor: `The Task Record is authoritative for Controlled Work`) and `docs/WORKFLOW-MAP.md` (anchor: `Controlled readiness, execution state, active ownership, and completion`), and the imported record is treated as evidence only — it cannot change execution state or grant approval.

### Scenario 6: Import grants no external authority

* Given a successful import,
* When no human confirmation exists,
* Then no commit, push, PR, release, or deployment action is authorized or executed.

--------

## Automated Verification Command

```bash
bash scripts/tests/run-execution-control-fixtures.sh
bash scripts/validate-execution-control.sh --root scripts/tests/fixtures/execution-control/valid --strict
bash scripts/tests/run-behavioral-contract-tests.sh
pwsh -NoProfile -File scripts/tests/run-execution-control-fixtures.ps1
```