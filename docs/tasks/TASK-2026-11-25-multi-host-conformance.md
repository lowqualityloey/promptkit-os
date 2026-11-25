# Task Record: Capture the multi-host conformance matrix

<a id="TASK-2026-11-25-multi-host-conformance"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-25-multi-host-conformance`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Code Work`
- **Specification**: `docs/internal/host-conformance/multi-host-capture-plan.md` (merged as `f35578b`; the owner's five decisions recorded in `4afb8f4`)
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: Repository `promptkit-os` — `scripts/render-capture-transcript.mjs` (a `--stream-format` selector), `scripts/tests/run-render-capture-transcript-tests.sh`, `scripts/tests/run-render-capture-transcript-tests.ps1`, `docs/internal/host-conformance/commandcode/` (new), `docs/internal/host-conformance/opencode-omo/` (new model-substituted bundles), `docs/internal/host-conformance/multi-host-capture-plan.md` (gate closure), `docs/HOST-CONFORMANCE.md` (matrix rows), `CHANGELOG.md`
- **Approval Boundary**: Commit, push, and pull-request creation are authorized by the owner's request of 2026-11-25. Merge, release, deployment, and closing issue #600 each require explicit human confirmation. This record authorizes none of them.
- **Created**: `2026-11-25 02:08 UTC`

## 2. Objective and Boundaries

- **Objective**: Produce the first cross-host conformance comparison this repository can honestly make — two hosts measured on the same pinned model, under enforced isolation, against the same five documented probes — and publish the result as measured, including any FAIL.
- **In Scope**:
  - A `--stream-format` selector on `scripts/render-capture-transcript.mjs` (`agy` default, `opencode`, `commandcode`), preserving the two load-bearing properties the current renderer documents: the two-space indent on event bodies, and the mapping from host tool names to the scorer's verb vocabulary.
  - Round-trip coverage for the new formats in both renderer test twins, with the existing six `agy` bundles still reproducing byte-for-byte.
  - Five `commandcode` capture bundles under `docs/internal/host-conformance/commandcode/<probe>/`, each satisfying the 17-file artifact contract.
  - Five model-substituted `opencode` capture bundles, published in a separate labelled column and never compared against the pinned pair.
  - The `docs/HOST-CONFORMANCE.md` §4 matrix update: the `commandcode` row added, the OpenCode row's stale cadence cell corrected, and the `agy` version difference recorded rather than smoothed.
  - The capture plan's Phase 1–4 gate items closed against measured results.
  - The `CHANGELOG.md` entry the changelog gate requires for a top-level `scripts/` change.
- **Explicit Non-Goals**:
  - Re-capturing the `agy` arm. §8 decision 5 reuses the published 1.5.14 bundles; the directive blob is byte-identical at every capture commit and at `HEAD`.
  - Lifting or copying the `opencode` Vercel credential. §8 decision 2 keeps the `secret.cli.opencode` rule.
  - Claiming a three-way model pin. §2.1a records that the pin is id-level on `commandcode`, and the matrix must carry that caveat.
  - Claiming universal conformance from two hosts. Issue #600's non-goal stands.
  - Any change to the measured inputs (`workflows/`, `protocols/`, the measured templates), so the `docs/BENCHMARKS.md` provenance anchor is untouched.
- **Dependencies**: `bwrap` 0.9.0, `commandcode` 1.88.5, `opencode` v2.4.1, and the published `agy` 1.5.14 bundles, all verified present on 2026-11-25. No new runtime dependency for the repository itself.
- **Risk**: `Medium` — the renderer change touches the code every scored bundle passes through, so a defect there would misreport every capture. Mitigated by keeping the `agy` path's output byte-identical and pinning it with the existing round-trip suites before any new format is added.
- **Verification Condition**: `bash scripts/tests/run-render-capture-transcript-tests.sh` and its PowerShell twin pass with the new formats and still reproduce all six committed `agy` bundles; every new bundle satisfies the artifact contract and its `scorer.txt` records both axes; `bash scripts/validate-references.sh . --strict`, `bash scripts/check-changelog-entry.sh`, and `bash scripts/validate-execution-control.sh --root . --strict` report no new failure.

## 3. Acceptance Criteria

- [ ] **AC-1**: The renderer accepts `--stream-format opencode` and `--stream-format commandcode`, and the `agy` default still reproduces all six committed bundles byte-for-byte.
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-2**: `opencode` tool names (`read`, `write`, `shell`) render unchanged, and `commandcode` tool names (`read_file`, `write_file`, `shell_command`, `read_directory`) map to the scorer's vocabulary (`read`, `write`, `shell`, `ls`).
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-3**: Five `commandcode` bundles exist under `docs/internal/host-conformance/commandcode/`, each carrying the 17-file artifact contract and a `scorer.txt` recording both axes where the scenario declares evidence checks.
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-4**: The `milestone-halt` capture on `commandcode` records a ≥300 s observation window and the continuation behaviour observed, using the `-p … --session <transcript.jsonl>` resume path built from the prior run's `run_end.result.nextState`.
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-5**: Five model-substituted `opencode` bundles exist, are labelled as substituted, and are not compared against the pinned pair anywhere in the published text.
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-6**: `docs/HOST-CONFORMANCE.md` §4 carries a `commandcode` row, the corrected OpenCode cadence cell, and the `agy` 1.5.14 version difference; every cell names its host version, model, directive profile, commit, and capture date.
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-7**: Every `commandcode` capture records the requested model id **and** the self-report, and the matrix cell carries the §2.1a id-level caveat.
  - **Result**: `Not started`
  - **Evidence**: pending
- [ ] **AC-8**: Results are published as measured, including any FAIL or PARTIAL; `UNTESTED` is published as `Untested`, never as a pass.
  - **Result**: `Not started`
  - **Evidence**: pending

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

- **Execution State**: `planned`
- **Mapped `pk:tasks` Status**: `To Do`
- **Active Task Pointer**: `None`
- **Start Time**: `not started`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: Begin Phase 2 — add the `--stream-format` selector to `scripts/render-capture-transcript.mjs` and pin the `agy` path with the existing round-trip suites before adding either new format.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-11-25 02:08 UTC` | `DeepSeek Harness agent` | Record created from the owner's request, after the plan and its five decisions merged | `docs/internal/host-conformance/multi-host-capture-plan.md` §8 |

## 6. Evidence and Completion Gate

- **Changed Files**: `none yet`
- **Scope Change Records**: `none`
- **Checkpoint Records**: `none`
- **Handoff Records**: `none`
- **Verification Evidence**: `none yet`
- **CI Evidence**: `none yet`
- **Review Evidence**: `none yet`
- **Commit Evidence**: `none yet`
- **Pull Request Evidence**: `none yet`
- **Release Evidence**: `not applicable`
- **Blocker and Resume Condition**: `none`
- **Completion State**: `not started`
- **Acceptance Results**: `AC-1 through AC-8 not started`
- **Changed-File Summary**: `none yet`
- **Completion Exception**: `none`
- **Completion Decision and Timestamp**: `not started`
