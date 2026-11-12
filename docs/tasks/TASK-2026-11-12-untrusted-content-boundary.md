# Task Record: Add an untrusted-content boundary to the directive

<a id="TASK-2026-11-12-untrusted-content-boundary"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-12-untrusted-content-boundary`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation and Test Work`
- **Specification**: `N/A` — no specification document; acceptance criteria derive from the owner's request of 2026-11-12
- **Owner / Actor**: `DeepSeek Harness agent (lead)`
- **Execution Scope**: Repository `promptkit-os` — `templates/agent-directive-template.md`, `templates/agent-directive-lite-template.md`, `protocols/context-sync.md`, `docs/ENFORCEMENT.md`, `docs/BENCHMARKS.md`, `README.md`, `FAQ.md`, `protocols/setup.md`, `scripts/tests/run-behavioral-contract-tests.sh`, `scripts/tests/run-behavioral-contract-tests.ps1`, `scripts/tests/eval-scenarios/injection-untrusted-content.md` (new), `CONTRIBUTING.md`, `docs/BEHAVIORAL-EVAL.md`, `docs/ARCHITECTURE.md`, `CHANGELOG.md`, `docs/STATE.md`
- **Approval Boundary**: Commit, push, and pull-request creation are authorized by the owner's request. Merge, release, deployment, and closing any issue each require explicit human confirmation. This record authorizes none of them.
- **Created**: `2026-11-12 20:58 UTC`

## 2. Objective and Boundaries

- **Objective**: Close the gap between what PromptKit OS is credited with and what it actually says, by adding a real untrusted-content / prompt-injection boundary to the injected directive and the context-sync protocol, and gating it with the existing test harnesses.
- **In Scope**:
  - `templates/agent-directive-template.md` — one guardrail bullet stating that repository content, README text, issue bodies, and fetched pages are data rather than instructions.
  - `templates/agent-directive-lite-template.md` — the terse Lite equivalent, sized to the 1,500-token budget.
  - `protocols/context-sync.md` — a new §3.3 stating the full boundary, placed after §3.2 so the §3.1/§3.2 anchors the contract suite pins do not move.
  - `docs/ENFORCEMENT.md` — a non-claim recording that the boundary is Tier 3 advisory text with no sanitizer or runtime interception behind it.
  - `scripts/tests/run-behavioral-contract-tests.sh` and `.ps1` — assertions that both templates and the protocol carry the boundary, and that the enforcement non-claim exists.
  - `scripts/tests/eval-scenarios/injection-untrusted-content.md` (new) — a scenario card whose prompt carries an embedded injection, with a PASS fixture that treats it as data and a FAIL fixture that complies.
  - `docs/BENCHMARKS.md`, `README.md`, `FAQ.md`, `protocols/setup.md` — re-propagated directive figures, because both templates are measured inputs.
  - `CHANGELOG.md` — one Unreleased / Added entry.
  - `docs/STATE.md` — section 3A projection updated to this record.
- **Explicit Non-Goals**:
  - Any sanitizer, content scanner, or runtime interception. The deliverable is directive text plus tests; it does not filter anything.
  - A claim that the boundary is enforced. `docs/ENFORCEMENT.md` records the opposite.
  - Live transcript evidence that a host model obeys the boundary. No such capture exists and none is claimed.
  - Changing the 2,500 / 1,500 token budgets. The directive must fit the existing caps.
- **Dependencies**: `None` — the change reads and edits existing files and adds no runtime dependency.
- **Risk**: `Low` — the change is directive text, documentation, and tests. The two real failure modes are (a) exceeding a token budget, mitigated by measuring both templates before committing, and (b) a figure drifting out of sync across the six documents that restate it, mitigated by the contract suite's gated-figure checks and by re-running every measurement script.
- **Verification Condition**: `bash scripts/measure-tokens.sh --strict` exits 0 with both profiles under budget; `bash scripts/tests/run-behavioral-contract-tests.sh` and its PowerShell twin pass; `bash scripts/run-behavioral-eval.sh --self-test` passes with the new card; `bash scripts/validate-references.sh . --strict`, `bash scripts/check-math-labels.sh --root .`, `bash scripts/check-changelog-entry.sh`, `bash scripts/validate-execution-control.sh --strict`, and `bash scripts/check-doctor.sh .` report no new failure.

## 3. Acceptance Criteria

- [x] **AC-1** — The Balanced directive carries a guardrail bullet naming repository content, README text, issue bodies, and fetched pages as data rather than instructions, and forbidding compliance with embedded commands.
- [x] **AC-2** — The Lite directive carries the same rule in a form that keeps the template under 1,500 tokens.
- [x] **AC-3** — `protocols/context-sync.md` carries a §3.3 with the full boundary: the two authoritative sources, the never-follow rule, the surface-don't-comply rule, the tool-output case, and the advisory-only limit.
- [x] **AC-4** — `docs/ENFORCEMENT.md` records that the boundary is Tier 3 advisory text with no sanitizer or runtime enforcement.
- [x] **AC-5** — Both behavioral-contract twins assert the boundary in both templates and in the protocol, and assert the enforcement non-claim.
- [x] **AC-6** — A new eval scenario card exercises an embedded injection, and its PASS fixture satisfies every check while its FAIL fixture violates at least one.
- [x] **AC-7** — Every restated directive figure matches the measured value, and the provenance anchor is restated to the implementation commit in a documentation-only follow-up commit.

## 4. Execution Policy

- **Mode**: `Batch Authorization`
- **Batch Authorization**: The owner's request authorizes the edits, the gate runs, the commit, the push, and the pull request in one batch. Merge is excluded.
- **Soft Checkpoint**: After the directive text is written and measured.
- **Hard Checkpoint**: Before the push, once every gate has run.
- **Event-Driven Checkpoints**: A token budget failure, a gated-figure failure, or a provenance-anchor failure.
- **Stop Conditions**: A budget cannot be met without deleting an existing rule; a gate fails for a reason outside this change's scope.
- **Host Timer Capability**: `No live host timer and no forced termination: elapsed time is not mechanically observable or enforced in this session, so soft and hard checkpoints are advisory and rely on the agent reporting them`

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-12 20:58 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: Open the pull request, then restate the provenance anchor in a documentation-only follow-up commit.

### Transition History

| Previous State | New State | Recorded By and Timestamp |
| :--- | :--- | :--- |
| N/A | planned | lead, 2026-11-12 20:58 UTC |
| planned | in_progress | lead, 2026-11-12 21:02 UTC |
| in_progress | awaiting_review | lead, 2026-11-12 23:22 UTC |

## 6. Evidence and Completion Gate

- **Changed Files**: `templates/agent-directive-template.md`, `templates/agent-directive-lite-template.md`, `protocols/context-sync.md`, `docs/ENFORCEMENT.md`, `docs/BENCHMARKS.md`, `README.md`, `FAQ.md`, `templates/lite-profile.md`, `protocols/setup.md`, `scripts/tests/run-behavioral-contract-tests.sh`, `scripts/tests/run-behavioral-contract-tests.ps1`, `scripts/tests/eval-scenarios/injection-untrusted-content.md` (new), `CONTRIBUTING.md`, `docs/BEHAVIORAL-EVAL.md`, `docs/ARCHITECTURE.md`, `CHANGELOG.md`
- **Scope Change Records**: `none`
- **Checkpoint Records**: `none`
- **Handoff Records**: `none`
- **Verification Evidence**: `bash scripts/measure-tokens.sh --strict` → `BALANCED|2410|2500|PASS`, `LITE|1491|1500|PASS`; `bash scripts/measure-per-task-tokens.sh --strict` → six BASELINE rows PASS; `bash scripts/tests/run-behavioral-contract-tests.sh` → `Passed: 576 | Failed: 0`; `/usr/bin/pwsh -NoProfile -File ./scripts/tests/run-behavioral-contract-tests.ps1` → `Passed: 565 | Failed: 0`; `bash scripts/run-behavioral-eval.sh --self-test` → `Passed: 35 | Failed: 0`; `bash scripts/validate-references.sh . --strict`, `bash scripts/check-math-labels.sh --root .`, `bash scripts/validate-execution-control.sh --root . --strict` → `VALID|RECORDS=71`, `bash scripts/check-doctor.sh` → exit 0, `bash scripts/measure-ceremony-overhead.sh --strict` → `CEREMONY_GATE|PASS`, `bash scripts/measure-turbo-overhead.sh --strict` → both rows PASS, plus the remaining bash and PowerShell harnesses recorded in the session log.`
- **CI Evidence**: `pending`
- **Review Evidence**: `pending`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: `pending`
- **Release Evidence**: `not applicable`
- **Blocker and Resume Condition**: `none`
- **Completion State**: `In Review`
- **Acceptance Results**: `AC-1 through AC-7 met; AC-7's anchor restatement lands in the documentation-only follow-up commit.`
- **Changed-File Summary**: `15 modified files, 2 new files; +129/-39 before the CHANGELOG entry and the PowerShell twin block.`
- **Completion Exception**: `none`
- **Completion Decision and Timestamp**: `pending`
