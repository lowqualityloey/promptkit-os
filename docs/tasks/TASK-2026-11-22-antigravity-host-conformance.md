# Task Record: Generalize host-conformance provenance and capture the first Antigravity probe

<a id="TASK-2026-11-22-antigravity-host-conformance"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-22-antigravity-host-conformance`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `docs/internal/host-conformance/antigravity-capture-plan.md` (merged as `34449d7`)
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: Repository `promptkit-os` — `scripts/run-behavioral-eval.sh`, `scripts/run-behavioral-eval.ps1`, `scripts/check-milestone-halt-evidence.sh`, `scripts/check-milestone-halt-evidence.ps1`, `scripts/tests/run-milestone-halt-evidence-fixtures.sh`, `scripts/tests/run-milestone-halt-evidence-fixtures.ps1`, `scripts/tests/run-behavioral-contract-tests.sh`, `scripts/tests/run-behavioral-contract-tests.ps1`, `scripts/render-capture-transcript.sh` (new), `scripts/render-capture-transcript.ps1` (new), `docs/BEHAVIORAL-EVAL.md`, `docs/internal/host-conformance/opencode-omo/README.md`, `docs/internal/host-conformance/antigravity/` (new), `CHANGELOG.md`
- **Approval Boundary**: Commit, push, and pull-request creation are authorized by the owner's request of 2026-11-22. Merge, release, deployment, and closing any issue each require explicit human confirmation. This record authorizes none of them.
- **Created**: `2026-11-22 10:51 UTC`

## 2. Objective and Boundaries

- **Objective**: Remove the two blockers that make an honest non-OpenCode host capture impossible, then capture the first Antigravity probe end-to-end so the pipeline is proven before the remaining four probes are attempted.
- **In Scope**:
  - The provenance key list in all five code locations plus its documentation, generalized so `hostName` + `hostVersion` is accepted as an alternative to `openCodeVersion` + `omoVersion`.
  - Regression coverage for both the legacy OpenCode shape and the host-neutral shape, in both twins.
  - A milestone-halt seed carrying an `AGENTS.md` that `agy` actually reads, with the new seed commit recorded.
  - A transcript renderer (Bash and PowerShell twins) converting `agy` `stream-json` NDJSON into the format `--score` expects.
  - One live `halt-callout` capture under the proven `bwrap` isolation, with its full bundle.
- **Explicit Non-Goals**:
  - Capturing the other four probes. Phase 2 exists to find pipeline defects on the cheapest probe first.
  - Moving the Antigravity row in `docs/HOST-CONFORMANCE.md` off `Untested`. One probe is not a host verdict, and the matrix update is Phase 4.
  - Hardening the permission deny-rule path. It is recorded as the rejected alternative; `bwrap` is the chosen mechanism.
  - Any change to the measured inputs (`workflows/`, `protocols/`, the measured templates), so the `docs/BENCHMARKS.md` provenance anchor is untouched.
- **Dependencies**: `agy` v1.5.14 and `bwrap` 0.9.0 on the capture host, both verified present. No new runtime dependency for the repository itself.
- **Risk**: `Medium` — the provenance change touches shared scoring code that every scored bundle passes through, so a defect there would misreport every capture. Mitigated by keeping the legacy shape's verdict byte-identical and pinning both shapes with regression controls in both twins.
- **Verification Condition**: `bash scripts/tests/run-behavioral-contract-tests.sh` and its PowerShell twin pass with the new controls; `bash scripts/tests/run-milestone-halt-evidence-fixtures.sh` and its twin pass; `bash scripts/run-behavioral-eval.sh --self-test` passes; all nine committed OpenCode bundles re-score to their committed lines byte-for-byte; `bash scripts/validate-references.sh . --strict`, `bash scripts/check-changelog-entry.sh`, and `bash scripts/validate-execution-control.sh --root . --strict` report no new failure.

## 3. Acceptance Criteria

- [ ] **AC-1**: The provenance key list accepts `hostName` + `hostVersion` as an alternative to `openCodeVersion` + `omoVersion` in all five code locations, and a bundle carrying either pair validates.
  - **Result**: `Pending`
  - **Evidence**: `scripts/run-behavioral-eval.sh`, `.ps1`, `scripts/check-milestone-halt-evidence.sh`, `.ps1`, and both fixture generators
- [ ] **AC-2**: All nine committed OpenCode bundles under `docs/internal/host-conformance/opencode-omo/` re-score to their committed `scorer.txt` lines byte-for-byte, including `provenance=verified`.
  - **Result**: `Pending`
  - **Evidence**: re-score transcript of all nine bundles
- [ ] **AC-3**: A bundle carrying only the host-neutral pair scores `provenance=verified`, and one carrying neither pair scores `provenance=unverified`.
  - **Result**: `Pending`
  - **Evidence**: new regression controls in both contract-test twins
- [ ] **AC-4**: The milestone-halt seed carries an `AGENTS.md` holding the Balanced directive, and the new seed commit is recorded in the capture bundle's provenance.
  - **Result**: `Pending`
  - **Evidence**: seed tree listing and `provenance.json`
- [ ] **AC-5**: A transcript renderer exists in both twins, converts `agy` `stream-json` NDJSON into the `## Events` format, and reproduces a recorded stream's assistant text byte-for-byte.
  - **Result**: `Pending`
  - **Evidence**: `scripts/render-capture-transcript.sh` / `.ps1` and a fixture round-trip
- [ ] **AC-6**: The `halt-callout` capture is taken under `bwrap` isolation, its canary fails to read the kit repository, and its bundle satisfies the artifact contract.
  - **Result**: `Pending`
  - **Evidence**: `docs/internal/host-conformance/antigravity/halt-callout/`
- [ ] **AC-7**: The `^`-anchored `^tool read` / `^tool write` patterns are checked against `rtk`-prefixed tool lines and the result is recorded.
  - **Result**: `Pending`
  - **Evidence**: `scorer.txt` and the bundle README
- [ ] **AC-8**: `docs/BEHAVIORAL-EVAL.md` and the bundle contract README describe both provenance shapes.
  - **Result**: `Pending`
  - **Evidence**: both documents

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Authorization Checkpoint Reference**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes`
- **Hard Checkpoint**: `At or before 90 minutes`
- **Event-Driven Checkpoints**: `Milestone, task switch, scope expansion, handoff, compaction, or context drift`
- **Stop Conditions**: `Missing approval/context, failed verification/CI/invariant, blocker, hard checkpoint, or developer stop`
- **Host Timer Capability**: `Not mechanically enforced; the harness exposes no timer. Checkpoints are observed, not enforced.`

## 5. State and Active Ownership

- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-11-22-antigravity-host-conformance`
- **Start Time**: `2026-11-22 10:51 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: Generalize the provenance key list in all five code locations.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-11-22 10:51 UTC` | `DeepSeek Harness agent` | Record created from the owner's request | `docs/internal/host-conformance/antigravity-capture-plan.md` |
| `planned` | `in_progress` | `2026-11-22 10:51 UTC` | `DeepSeek Harness agent` | Objective, scope, criteria, and policy complete | This record |

## 6. Evidence and Completion Gate

- **Changed Files**: `pending`
- **Scope Change Records**: `none`
- **Checkpoint Records**: `none`
- **Handoff Records**: `none`
- **Verification Evidence**: `pending`
- **CI Evidence**: `pending`
- **Review Evidence**: `none yet — no human review has been requested or received`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: `pending`
- **Release Evidence**: `not applicable`
- **Blocker and Resume Condition**: `none`
- **Completion State**: `In Progress`
- **Acceptance Results**: `AC-1 through AC-8 pending`
- **Changed-File Summary**: `pending`
- **Completion Exception**: `none`
- **Completion Decision and Timestamp**: `pending`
