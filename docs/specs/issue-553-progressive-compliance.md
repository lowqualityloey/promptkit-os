### Metadata

* **Related Spec:** `workflows/route.md` Levels 0–3 — L0 `workflows/route.md` (anchor: `Zero task records, no GitHub issue required, no state tracking overhead`), L1 `workflows/route.md` (anchor: `without requiring formal Task Record files`), Task Record "**No**" `workflows/route.md` (anchor: `**No** (Fast-path direct execution`) / `workflows/route.md` (anchor: `**No** (Natural workflow`), L1 rule `workflows/route.md` (anchor: `does **not** trigger Level 2 Controlled Work requirements or mandate creating`), L0 no-write `workflows/route.md` (anchor: `do **not** write files to`); `scripts/validate-execution-control.sh` — `validate_checkpoint` `scripts/validate-execution-control.sh` (anchor: `validate_checkpoint() {`), label array `scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID" "Task ID"`), `require_value` `scripts/validate-execution-control.sh` (anchor: `require_value() {`), `is_placeholder` `scripts/validate-execution-control.sh` (anchor: `is_placeholder() {`), `TRACEABILITY_MISSING` `scripts/validate-execution-control.sh` (anchor: `Checkpoint references unknown Task ID`); `scripts/validate-execution-control.ps1` (twin), #550 (joint tier contract — **must land first**)
* **Priority:** `priority/p2`
* **Labels:** `type:feature`, `area:tooling`, `priority/p2`
* **Work Classification:** `L2` (validator contract tiers; proposed SemVer impact `minor`)

--------

## User Story & Context

As a developer on a fast/weak model (observed: flash-tier) or working a small task,
I want a minimal-viable checkpoint that always validates with explicit degradation marks, reserving the full label gate for milestones and releases,
So that strictness never again causes *total* documentation abandonment.

Observed failure mode, from `scratch/issue-draft-06-harness-importer.md` and `scratch/issue-draft-04-checkpoint-ignore-aware.md`: an agent unable to satisfy the full gate concluded that writing nothing was the correct response, and wrote nothing for 1.5 days.

### Contract conflict that must be resolved before implementation

The previous draft defined the `quick` tier as the "5-field minimal projection" from #550 — whose first field is `Task ID`. That conflicts with two existing contracts:

1. **L0/L1 do not require a Task Record.** `workflows/route.md` (anchor: `without requiring formal Task Record files`) — L1 uses "Normal task tracking in `docs/STATE.md` without requiring formal Task Record files." `workflows/route.md` (anchor: `**No** (Fast-path direct execution`) / `workflows/route.md` (anchor: `**No** (Natural workflow`) — Task Record "**No**" at L0 and L1, "**Yes**" at L2. `workflows/route.md` (anchor: `does **not** trigger Level 2 Controlled Work requirements or mandate creating`) — an L1 task "does **not** trigger Level 2 Controlled Work requirements or mandate creating `docs/tasks/<task-id>.md`." `workflows/route.md` (anchor: `Zero task records, no GitHub issue required, no state tracking overhead`) — L0 has "Zero task records, no GitHub issue required, no state tracking overhead."
2. **The validator cannot pass a `Task ID` that has no Task Record.** `scripts/validate-execution-control.sh` (anchor: `Checkpoint references unknown Task ID`) requires the checkpoint's `Task ID` to resolve in `TASK_FILE_BY_ID`, which is populated only from real files under `docs/tasks/` (`scripts/validate-execution-control.sh` (anchor: `TASK_FILE_BY_ID["$id"]="$file"`)); otherwise it emits `TRACEABILITY_MISSING`.

**Therefore a `quick` tier containing a `Task ID` is unsatisfiable at L1 unless it also mandates creating a Task Record** — which directly re-creates the ceremony burden this issue exists to remove. Worse, at **L0** a record cannot be written at all: `workflows/route.md` (anchor: `do **not** write files to`) states an informational L0 request must "**not** write files to `docs/`".

The tier must therefore bind to ceremony level **without** inheriting a Task Record requirement at L0/L1.

### Corrections to the previous draft's stated numbers

| Previous draft | Measured |
| :--- | :--- |
| `validate_checkpoint()` — 21 labels | **20** (`scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Checkpoint ID" "Task ID"`)) |
| `validate_handoff()` — 44 labels | **43** array entries, **42 unique** (`Next Action` duplicated, `scripts/validate-execution-control.sh` (anchor: `local labels=("Record Type" "Handoff ID" "Task ID"`)) |
| 23 non-placeholder | **24** value-bearing labels (`scripts/validate-execution-control.sh` (anchor: `local value_labels=("Record Type" "Handoff ID"`)) |

Of the 20 checkpoint labels, **17 require a non-placeholder value** (`scripts/validate-execution-control.sh` (anchor: `require_value "$file" "$id" "$label" "CHECKPOINT_INCOMPLETE"`)) and **3 are presence-only** (`scripts/validate-execution-control.sh` (anchor: `[ "$label" = "Changed Files" ] || [ "$label" = "Blockers" ] || [ "$label" = "Scope Changes" ]`)).

### What already exists (do not duplicate)

* `validate_checkpoint()` / `validate_handoff()` enforce the full contract — keep them as the `full` tier. This issue adds a tier, not a bypass.
* `POLICY_LIMITATION` already exists as a diagnostic category (`scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION`)); reuse it rather than adding a new degradation vocabulary.
* Graceful-degradation precedent: `scripts/measure-per-task-tokens.sh` (anchor: `|| echo "unknown"`), `scripts/isolate-worktree.sh` (anchor: `2>/dev/null || true`), and `scripts/check-changelog-entry.sh` (anchor: `CHANGELOG_GATE|MISSING-BASE`) / `scripts/check-changelog-entry.sh` (anchor: `CHANGELOG_GATE|SKIP`) / `scripts/check-changelog-entry.sh` (anchor: `CHANGELOG_GATE|EMPTY-RANGE`) with its twin `scripts/check-changelog-entry.ps1` (anchor: `CHANGELOG_GATE|MISSING-BASE`).

### Non-Negotiable Invariants

* **[ ] Tier binding is derived, never chosen:** the tier follows the ceremony level established in `workflows/route.md`. An agent cannot self-select a tier, and no environment variable may lower it.
* **[ ] L0 writes nothing:** the `quick` tier must not require writing to `docs/` at L0 (`workflows/route.md` (anchor: `do **not** write files to`)). L0 records are in-conversation only; the tier's floor applies from L1 upward.
* **[ ] L1 requires no Task Record:** a `quick` record at L1 must validate **without** `docs/tasks/<task-id>.md`. Where a Task ID is absent, record its absence explicitly instead of triggering `TRACEABILITY_MISSING` (`scripts/validate-execution-control.sh` (anchor: `Checkpoint references unknown Task ID`)).
* **[ ] No silent partials:** every unresolved `full`-tier label appears as an explicit degradation mark. A `quick` record can never be mistaken for a complete one.
* **[ ] L2/L3 unchanged:** the `full` tier remains mandatory at Controlled and Release-Critical work. Degradation is never approval.
* **[ ] Tier is visible in output:** every record states its tier and its unresolved-label count, so a consumer can never infer completeness from silence.
* **[ ] The Local Task Source is not weakened.** This issue introduces a record that can carry a `Task ID` with no Task Record, so it must state the invariant it is bounded by rather than leave it implied: `docs/MAXIMS.md` (anchor: `**Persist decisions, not transcripts.**`) — "Task Records own execution state" — and `docs/WORKFLOW-MAP.md` (anchor: `The Task Record is authoritative for Controlled Work`). The `quick` tier's floor is a *projection* exemption for L0/L1 ceremony only. It never makes an imported or in-conversation record authoritative for Controlled Work, never satisfies `TRACEABILITY_MISSING` by fabricating a Task ID, and never downgrades the L2/L3 requirement. If the two rules can ever be read as contradicting, this issue is wrong and must be reworked rather than the maxim relaxed.
* **[ ] Token figures repropagated:** this issue edits `workflows/checkpoint.md` and `workflows/route.md`, both of which are in the six files summed into the core-six measurement. Run `bash scripts/measure-tokens.sh` (no `--strict`) and read its `Monolithic (core-6 subset derived)` and `Monolithic (full N-workflow set)` lines — even a prose-only addition moves the total. `scripts/tests/run-behavioral-contract-tests.sh` asserts the published cells equal measurement output, so re-measure and update `docs/BENCHMARKS.md` in the same PR (`docs/BENCHMARKS.md` (anchor: `| Core-six Lite subset | 6 | **30,966 tok** |`)).
* **[ ] Twin parity:** identical diagnostics in `.sh` and `.ps1` (`CONTRIBUTING.md` (anchor: `Script fixes must maintain full behavioral parity`), `PROMPTKIT.md` (anchor: `Bash/PowerShell twin parity`)).

### Out of Scope

* Changing any `full`-tier label requirement, diagnostic code, or exit code.
* Model-capability enforcement or runtime model gating. A model-floor note in documentation is permitted; a hard model restriction is not, and requires conformance evidence that does not exist in this repository.
* Changing the L0/L1 ceremony definitions in `workflows/route.md` — this issue conforms to them.
* Auto-upgrading a `quick` record to `full`.

--------

## Implementation Tasks (The Build)

* [x] 1. **Jointly specify the tier contract with #550 before implementing either half.** Resolve, in one place: the label count (20 / 42 unique / 24 value-bearing), which labels each tier requires, how `Task ID` absence is represented at L1, and which diagnostic marks each unresolved label produces. Do not implement a 5-field projection that includes a `Task ID` while `workflows/route.md` (anchor: `does **not** trigger Level 2 Controlled Work requirements or mandate creating`) says L1 needs no Task Record.
* [x] 2. Define the `quick` tier as a **level-aware** shape, not a fixed field count:
  * **L0** — no `docs/` write at all (`workflows/route.md` (anchor: `do **not** write files to`)); nothing to validate.
  * **L1** — `quick`: state projection fields only, `Task ID` optional and explicitly marked when absent.
  * **L2/L3** — `full`: all 20 labels (17 value-bearing + 3 presence-only), `Task ID` mandatory and required to resolve (`scripts/validate-execution-control.sh` (anchor: `Checkpoint references unknown Task ID`)).
* [x] 3. Split the validator by tier in `scripts/validate-execution-control.sh` (+ `.ps1` twin) with identical behavior. Reuse `POLICY_LIMITATION` (`scripts/validate-execution-control.sh` (anchor: `diagnostic POLICY_LIMITATION`)); introduce no new diagnostic category without a matching `.ps1` twin and a fixture in both harnesses.
* [x] 4. Emit the tier and the unresolved-label count in validator output, so `quick`-tier acceptance is machine-checkable rather than inferred.
* [x] 5. Wire tier selection to `workflows/route.md` ceremony level in `workflows/checkpoint.md`; the level is read from the established declaration, never inferred by the agent.
* [x] 6. Document the model floor as a **guidance note** in `docs/ADOPTION-GUIDE.md` + profile docs: fast-tier models are adequate for L0/L1. Do not encode a hard model restriction; there is no conformance evidence in-repo to support one, and `docs/HOST-CONFORMANCE.md` (anchor: `live host accounts, provider subscriptions, executing fresh sessions`) reserves runtime verification for maintainer-owned sessions.
* [x] 7. Fixtures under `scripts/tests/fixtures/execution-control/` (+ both twins): `quick`-pass at L1 with **no** Task Record file; `quick`-rejected at L3; `full`-unchanged at L2; L0 asserting no `docs/` write.
* [x] 8. Update `CHANGELOG.md` (`[Unreleased]`).

--------

## Acceptance Criteria (The Verifiable Proof)

### Scenario 1: L1 passes with no Task Record

* Given an L1 task with **no** `docs/tasks/<task-id>.md` and no `Task ID`,
* When the record is validated at the `quick` tier,
* Then it passes with explicit degradation marks, emits no `TRACEABILITY_MISSING`, and states its tier and unresolved-label count.

### Scenario 2: Task ID without a Task Record degrades honestly

* Given an L1 record that **does** carry a `Task ID` for which no Task Record file exists,
* When it is validated,
* Then it reports the unresolved linkage as an explicit degradation mark and never silently passes as complete — while still not demanding the agent create a Task Record, per `workflows/route.md` (anchor: `does **not** trigger Level 2 Controlled Work requirements or mandate creating`).

### Scenario 3: L3 demands the full tier

* Given an L3 task with only the `quick` fields,
* When validated,
* Then `quick` is rejected and `full` is demanded — no silent partial at release risk.

### Scenario 4: L0 writes nothing to `docs/`

* Given an informational L0 request,
* When `pk:checkpoint` runs,
* Then no file is written under `docs/` and no record is required, per `workflows/route.md` (anchor: `do **not** write files to`).

### Scenario 5: The full tier is untouched

* Given an L2 task with a complete 20-label record,
* When validated,
* Then behavior is byte-identical to today — no label requirement relaxed, no diagnostic code changed.

### Scenario 6: Placeholders never satisfy a `quick` field

* Given a `quick` record whose `Next Action` is `TBD`,
* When validated,
* Then it is reported unresolved, per `scripts/validate-execution-control.sh` (anchor: `require_value() {`) and `scripts/validate-execution-control.sh` (anchor: `is_placeholder() {`).

### Scenario 7: Degradation is not approval

* Given a `quick`-tier record that validates at L1,
* When execution state is determined,
* Then the record confers no completion, release, or external-action authority, per `docs/WORKFLOW-MAP.md` (anchor: `Preserves and projects evidence; does not approve, commit, release, deploy, or roll back.`).

--------

## Automated Verification Command

```bash
bash scripts/tests/run-execution-control-fixtures.sh
bash scripts/validate-execution-control.sh --root scripts/tests/fixtures/execution-control/valid --strict
bash scripts/tests/run-behavioral-contract-tests.sh
pwsh -NoProfile -File scripts/tests/run-execution-control-fixtures.ps1
```