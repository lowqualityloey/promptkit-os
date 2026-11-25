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
  - Round-trip coverage for the new formats in both renderer test twins — `scripts/tests/run-render-capture-transcript-tests.sh` and `scripts/tests/run-render-capture-transcript-tests.ps1` — with the existing six `agy` bundles still reproducing byte-for-byte.
  - A committed golden transcript and write log per new format, rendered from a real sanitized stream, under `scripts/tests/fixtures/render-capture-transcript/opencode/` and `scripts/tests/fixtures/render-capture-transcript/commandcode/`.
  - The correction of the one published Antigravity transcript the union verb table changes: `docs/internal/host-conformance/antigravity/ce-escalation-balanced/transcript.md` and its `observed-writes.log`, whose verdict is re-checked and must not move.
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

- [x] **AC-1**: The renderer accepts `--stream-format opencode` and `--stream-format commandcode`, and the `agy` default still reproduces all six committed bundles byte-for-byte.
  - **Result**: `Met`
  - **Evidence**: `scripts/render-capture-transcript.mjs` takes `--stream-format agy|opencode|commandcode`, defaults to `agy`, and rejects anything else with exit 2 (`--stream-format is not one of agy, opencode, commandcode: <value>`). `bash scripts/tests/run-render-capture-transcript-tests.sh` → `RENDER_CAPTURE_TRANSCRIPT_TESTS|PASS|28 passed`, which includes the twelve anchored round-trips (six probes + six `ce-*` cells) reproducing their committed transcripts byte-for-byte with no timestamp stripping, and the six stripped round-trips. The PowerShell twin reports the same `28 passed`.
- [x] **AC-2**: `opencode` tool names (`read`, `write`, `shell`) render unchanged, and `commandcode` tool names (`read_file`, `write_file`, `shell_command`, `read_directory`) map to the scorer's vocabulary (`read`, `write`, `shell`, `ls`).
  - **Result**: `Met`
  - **Evidence**: the `VERB` table is one union across the three hosts. `opencode` already emits the scorer's vocabulary, so its entries are identity mappings; `commandcode`'s `read_file`/`write_file`/`shell_command`/`read_directory` map to `read`/`write`/`shell`/`ls`. The committed goldens show the result: `scripts/tests/fixtures/render-capture-transcript/opencode/transcript.md` renders `read a.txt`, `write c.txt`, `shell ls -1`, and `.../commandcode/transcript.md` renders the same three verbs from `read_file`, `write_file`, `shell_command`. An unmapped name renders verbatim and is named on stderr; that warning found a real pre-existing gap — `agy` emits `write_file`, which the renderer did not know, so two writes in `ce-escalation-balanced` had been rendering unclassifiable. Mapping it corrects that bundle's transcript and write log and leaves its verdict at `PASS|checks=3/3|behavioral=PASS|provenance=verified`.
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

- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `TASK-2026-11-25-multi-host-conformance`
- **Start Time**: `2026-11-26 05:35 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: Phase 2 is done (AC-1, AC-2 met). Begin Phase 3 — capture the five probes on `commandcode` under the §3.1 recipe, starting with `card-provenance`, then the model-substituted `opencode` set, then the matrix update.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-11-25 02:08 UTC` | `DeepSeek Harness agent` | Record created from the owner's request, after the plan and its five decisions merged | `docs/internal/host-conformance/multi-host-capture-plan.md` §8 |
| `planned` | `in_progress` | `2026-11-26 05:35 UTC` | `DeepSeek Harness agent` | Phase 2 begun: the renderer gains its `--stream-format` selector | This record's AC-1 and AC-2 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/render-capture-transcript.mjs` - `--stream-format` selector, three parsers, union verb table, per-format clock note, unmapped-name report
  - `scripts/tests/run-render-capture-transcript-tests.sh` / `.ps1` - five new cases each (two goldens, unknown-format rejection, clock-note assertion, unmapped-name report)
  - `scripts/tests/fixtures/render-capture-transcript/opencode/` (new) - sanitized stream plus golden transcript and write log
  - `scripts/tests/fixtures/render-capture-transcript/commandcode/` (new) - same
  - `docs/internal/host-conformance/antigravity/ce-escalation-balanced/transcript.md` / `observed-writes.log` - the two `write_file` lines the newly-mapped verb corrects
  - `CHANGELOG.md` - the entry the changelog gate requires for a top-level `scripts/` change
- **Scope Change Records**:
  - `SCOPE-2026-11-26-01` - the scope above was written before the renderer had any new format, so it named no fixture path and no bundle correction. Two additions were needed once the work started, and both stay inside the objective rather than widening it.
    - *Added:* committed goldens per new format. A golden rendered from a real stream is the only way the suite can pin a parser against something other than the parser's own assumptions; a synthetic stream written by hand would test the author's belief about the shape.
    - *Added:* the `ce-escalation-balanced` correction. The union verb table revealed that `agy` emits `write_file`, which the renderer had never mapped, so two writes in that bundle had been rendering as an unclassifiable tool name. Correcting the map without correcting the transcript would break the round-trip suite; correcting it silently would edit published evidence without a record. The verdict was re-scored and is unchanged at `PASS|checks=3/3|behavioral=PASS|provenance=verified`.
    - *Not added:* any new capture. AC-3 through AC-8 still need live runs, which this change does not perform.
- **Checkpoint Records**: `none`
- **Handoff Records**: `none`
- **Verification Evidence**: `bash scripts/tests/run-render-capture-transcript-tests.sh` -> `RENDER_CAPTURE_TRANSCRIPT_TESTS|PASS|28 passed` (10 before the new cases); `pwsh -NoProfile -File scripts/tests/run-render-capture-transcript-tests.ps1` -> `RENDER_CAPTURE_TRANSCRIPT_TESTS|PASS|28 passed`, identical; all twelve anchored round-trips reproduce their committed transcripts byte-for-byte with no timestamp stripping; `bash scripts/run-behavioral-eval.sh --score ce-escalation-balanced <re-rendered>` -> `ce-escalation-balanced|live|PASS|checks=3/3|behavioral=PASS|provenance=verified`, byte-identical to the committed `scorer.txt`.
- **CI Evidence**: `pending`
- **Review Evidence**: `pending`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: `pending`
- **Release Evidence**: `not applicable`
- **Blocker and Resume Condition**: `none`
- **Completion State**: `in progress - AC-1 and AC-2 met, AC-3 through AC-8 not started`
- **Acceptance Results**: `AC-1 and AC-2 met; AC-3 through AC-8 not started, because they need live captures this record has not performed`
- **Changed-File Summary**: the renderer grew a format selector plus three parsers and two supporting tables; both test twins gained five cases and each new format gained a committed golden rendered from a real sanitized stream; one published Antigravity transcript and its write log were corrected by two lines each because the union verb table revealed an agy write tool the renderer had never recognised.
- **Completion Exception**: `none`
- **Completion Decision and Timestamp**: `not started`
