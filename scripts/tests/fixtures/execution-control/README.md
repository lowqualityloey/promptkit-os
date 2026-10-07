# Execution-Control Validator Fixtures

These fixtures are synthetic and local-only. They contain no real commit, release, remote, or deployment identifiers.

- `valid/` contains a completed Task Record with linked scope-change, checkpoint, handoff, and `docs/STATE.md` projection evidence. Both validators must return `VALID|RECORDS=4|ROOT=.` with exit code 0.
- `invalid/` contains the original compound readiness, policy-limitation, active-task, transition, and scope-change failures. Both validators must return nonzero and the same 13 diagnostic lines.
- `cases/` contains isolated synthetic roots for readiness fields, duplicate active tasks, illegal transitions, hard checkpoints, valid `blocked`/`paused`/`aborted` states, scope expansion, handoffs, blockers, completion evidence, traceability, revision and STATE projections, timer limitations, and legacy/Adaptation profile compatibility. `adaptation-valid/` exercises local planning and assumption links; `legacy-none-profile/` proves an explicit `none` marker stays on the legacy path; the invalid Adaptation cases isolate profile-scoped identity and field/link failures.
- `expected/` contains the tab-separated `cases.tsv` manifest plus one shared summary and diagnostic contract per isolated case. Bash and PowerShell consume the same expected files.
- `imports/` contains foreign `/handoff` payload fixtures for the importer matrix: `complete`, `minimal-linked`, `minimal-unlinked`, `no-task-record`, `placeholder-rejection`, `quick-complete`, `quick-incomplete`, `l0-refused`, `quick-downgrade-linked`, `quick-unknown-task`, `quick-missing-recorded-by`, `quick-invalid-checkpoint-id`, and `quick-backtick-placeholder`. `expected/imports.tsv` plus each `expected/<name>.import-draft.txt` and `expected/<name>.import-unresolved.txt` pin the importer's `IMPORT-DRAFT` (`tier|unresolved|verdict`), `IMPORT-UNRESOLVED`, and `TRACEABILITY_MISSING` contract (exit 0 only for QUICK-VALID or FULL-VALID; every draft is round-tripped through the canonical validator: valid verdicts must pass it and DRAFT-INCOMPLETE drafts must not report VALID). The importer is read-only and never synthesizes a Task ID.
- `examples.tsv` indexes existing synthetic readiness, checkpoint, handoff, and completion records for schema-example coverage without duplicating record bodies.
- `expected-valid.txt`, `expected-invalid.txt`, and `expected-invalid-summary.txt` remain the shared regression contract for the original roots.

Run the paired harnesses from the repository root:

```text
bash scripts/tests/run-execution-control-fixtures.sh
pwsh -NoProfile -File .\scripts\tests\run-execution-control-fixtures.ps1
```

Optional Wave 7 property/example coverage is local-only and dependency-free:

```text
bash -n scripts/tests/run-execution-control-properties.sh
bash scripts/tests/run-execution-control-properties.sh
pwsh -NoProfile -File .\scripts\tests\run-execution-control-properties.ps1
```

The property harnesses run five deterministic in-memory invariant checks with 100 iterations per property, validate the shared example manifest, and snapshot fixture/repository hashes plus Git status. They do not add a CI gate or authorize any remote, release, deployment, or rollback action.

The harnesses invoke the native validator for each platform, capture expected nonzero failure status, normalize semantic diagnostics, and snapshot fixture/repository hashes plus Git status before and after each run. Temporary capture files are created outside the repository.

Execution-control validation is durable evidence only; it cannot observe live chat duration or approve external actions.
