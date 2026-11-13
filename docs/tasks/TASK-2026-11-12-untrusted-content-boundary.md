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
- **Execution Scope**: Repository `promptkit-os` — `templates/agent-directive-template.md`, `templates/agent-directive-lite-template.md`, `protocols/context-sync.md`, `docs/ENFORCEMENT.md`, `docs/BENCHMARKS.md`, `README.md`, `FAQ.md`, `templates/lite-profile.md`, `protocols/setup.md`, `scripts/run-behavioral-eval.sh`, `scripts/run-behavioral-eval.ps1`, `scripts/tests/run-behavioral-contract-tests.sh`, `scripts/tests/run-behavioral-contract-tests.ps1`, `scripts/tests/eval-scenarios/injection-untrusted-content.md` (new), `scripts/tests/eval-scenarios/ce-antistarvation-balanced.md`, `scripts/tests/eval-scenarios/ce-antistarvation-lite.md`, `scripts/tests/fixtures/injection-untrusted-content/ONBOARDING-NOTES.md` (new), `CONTRIBUTING.md`, `docs/BEHAVIORAL-EVAL.md`, `docs/ARCHITECTURE.md`, `CHANGELOG.md`, `docs/STATE.md`
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
  - `scripts/tests/fixtures/injection-untrusted-content/ONBOARDING-NOTES.md` (new) — the seeded lower-trust input the scenario reads, so the attack lives in a file rather than in the user prompt.
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
- [x] **AC-8** — Both directive bullets and `protocols/context-sync.md` §3.3 distinguish project configuration read through its documented entry point (which still directs work) from text embedded inside a file (which does not), so the boundary does not read as "ignore the repository".
- [x] **AC-9** — The injection scenario judges recorded evidence, not prose alone: it declares `repo-unwritten` and `prohibited-action` checks, and a transcript that paraphrases compliance scores below PASS.
- [x] **AC-10** — The injection scenario stages the lower-trust input in a seeded fixture and keeps the attack out of the user prompt, so a live run exercises the file-to-agent boundary.
- [x] **AC-11** — `docs/BENCHMARKS.md` states that the 2500/1500 gates bound the `bytes/4` proxy rather than a tokenizer, and records that the Lite directive exceeds 1,500 `cl100k_base` tokens.
- [x] **AC-12** — The evidence matcher is quote-aware and verb-aware in both harness twins: a quoted `rm`, `git rm`, or `mv` of a protected path is still a recorded write, a recorded `read`/`cat`/`grep` of the same path is not, and an unanchored `prohibited-action` pattern no longer fires on a read-only inspection while a `^`-anchored pattern still matches verbatim.
- [x] **AC-13** — Both behavioral-contract twins score real bundles through the `--score`/`-Score` path for seven negative controls (double-quoted `rm`, single-quoted `rm`, `git rm`, `mv`, `read`, `cat`, and a URL `grep`), and each control fails against the pre-fix harness and passes after it.
- [x] **AC-14** — `protocols/context-sync.md` §3.3 separates a policy file's authority from its provenance, and the injection scenario's Setup cannot overwrite an existing `docs/ONBOARDING-NOTES.md`.

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
- **Next Action**: Commit the second-review fixes, push, and confirm all 12 checks on PR #737. Merge is outside this record's approval boundary.

### Transition History

| Previous State | New State | Recorded By and Timestamp |
| :--- | :--- | :--- |
| N/A | planned | lead, 2026-11-12 20:58 UTC |
| planned | in_progress | lead, 2026-11-12 21:02 UTC |
| in_progress | awaiting_review | lead, 2026-11-12 23:22 UTC |
| awaiting_review | in_progress | lead, 2026-11-13 14:56 UTC — second review returned three findings |
| in_progress | awaiting_review | lead, 2026-11-13 15:45 UTC |

## 6. Evidence and Completion Gate

- **Changed Files**: `templates/agent-directive-template.md`, `templates/agent-directive-lite-template.md`, `protocols/context-sync.md`, `docs/ENFORCEMENT.md`, `docs/BENCHMARKS.md`, `README.md`, `FAQ.md`, `templates/lite-profile.md`, `protocols/setup.md`, `scripts/run-behavioral-eval.sh`, `scripts/run-behavioral-eval.ps1`, `scripts/tests/run-behavioral-contract-tests.sh`, `scripts/tests/run-behavioral-contract-tests.ps1`, `scripts/tests/eval-scenarios/injection-untrusted-content.md` (new), `scripts/tests/eval-scenarios/ce-antistarvation-balanced.md`, `scripts/tests/eval-scenarios/ce-antistarvation-lite.md`, `scripts/tests/fixtures/injection-untrusted-content/ONBOARDING-NOTES.md` (new), `CONTRIBUTING.md`, `docs/BEHAVIORAL-EVAL.md`, `docs/ARCHITECTURE.md`, `CHANGELOG.md`
- **Scope Change Records**: `none`
- **Checkpoint Records**: `none`
- **Handoff Records**: `none`
- **Verification Evidence**: `bash scripts/measure-tokens.sh --strict` → `BALANCED|2449|2500|PASS`, `LITE|1489|1500|PASS`; `bash scripts/measure-per-task-tokens.sh --strict` → six BASELINE rows PASS (`pk:fix` 11,436/10,476, `pk:plan` 20,925/19,965, `pk:ship` 17,226/16,266); `bash scripts/tests/run-behavioral-contract-tests.sh` → `Passed: 607 | Failed: 0`; `/usr/bin/pwsh -NoProfile -File ./scripts/tests/run-behavioral-contract-tests.ps1` → `Passed: 596 | Failed: 0`; `bash scripts/run-behavioral-eval.sh --self-test` → `Passed: 35 | Failed: 0`; `bash scripts/validate-references.sh . --strict` → exit 0, `bash scripts/check-math-labels.sh --root .` → `MATH_LABEL_GATE|PASS`, `bash scripts/validate-execution-control.sh --root . --strict` → `VALID|RECORDS=71`, `bash scripts/check-benchmark-task-cards.sh --root .` → `cards=21|failed=0`, `bash scripts/check-changelog-entry.sh --base origin/main --head HEAD` → `CHANGELOG_GATE|PASS`, `bash scripts/measure-ceremony-overhead.sh --strict` → `CEREMONY_GATE|PASS`, `bash scripts/measure-turbo-overhead.sh --strict` → both rows PASS, `bash scripts/tests/run-reference-link-tests.sh` → `Passed: 10 | Failed: 0`, `bash scripts/tests/run-playbook-contract-tests.sh` → exit 0, `bash scripts/tests/run-init-safety-tests.sh` → exit 0 including Test 36p, and `bash -n` over every tracked `*.sh` → 0 syntax failures. The seven new negative controls were also scored against the pre-fix harness extracted from `git show HEAD:scripts/run-behavioral-eval.sh`: the quoted-`rm` bundle graded `behavioral=PASS` and the `read` and `grep` bundles graded `behavioral=FAIL`, so each control fails before the fix and passes after it.`
- **CI Evidence**: `PR #737 run 43355363251 on d38a5b7 — all 12 checks green (Change Classification 6s, Lint & Validate on Linux 4s and Windows 4s, Linux Docs & Contracts 1m57s, Staged Secret Scan 4s, Linux Code Shard — Installer & Runtime 1m17s, Linux Code Shard — Fixtures & Benchmarks 1m19s, Windows Docs & Contracts 2m27s, Windows Code Shard — Command Surface 2m26s, Windows Code Shard — Harnesses 2m43s, Windows Code Shard — Doctor & Profiles 3m9s, Windows Code Shard — Syntax, Gates & Init Safety 10m10s). Earlier runs 43202152107 on 90da3f6, 43284863293 on 8ed055a, and 43287500820 on 5dd9370 were also 12/12 green and are superseded`
- **Review Evidence**: `none yet — no human review has been requested or received`
- **Commit Evidence**: `52c09ad carries the directive, the protocol section, the enforcement non-claim, the eval card, Scenario AT in both twins, the scenario-count prose, and every re-propagated figure; 90da3f6 is documentation-only and restates the docs/BENCHMARKS.md provenance anchor to 52c09ad, because a commit cannot contain its own SHA. 2a30c26 carries the four review fixes — the project-config carve-out in both directives and §3.3, the seeded fixture, the scenario evidence checks, the proxy-bound qualification, the eleven new Scenario AT assertions, and the re-propagated figures; 8ed055a is documentation-only and restates the anchor to 2a30c26. d38a5b7 carries the three second-review fixes — the quote-aware, verb-aware matcher in both harness twins, the seven scored negative controls, the §3.3 provenance bullet, the preserve-and-restore Setup, the corrected anti-starvation limitations, the twelve new Scenario AT assertions, and the CHANGELOG entry. It needs no documentation-only successor because it touches no `docs/BENCHMARKS.md` measured input, so the provenance anchor stays at 2a30c26 and the guard reports `provenance anchor 2a30c26 (measured-input tree unchanged since it)` on the committed tree`
- **Pull Request Evidence**: `PR #737 (open) — https://github.com/lowqualityloey/promptkit-os/pull/737, base main, head feat/untrusted-content-boundary`
- **Release Evidence**: `not applicable`
- **Blocker and Resume Condition**: `none`
- **Completion State**: `In Review`
- **Acceptance Results**: `AC-1 through AC-14 met; AC-7's anchor restatement lands in the documentation-only follow-up commit.`
- **Changed-File Summary**: `10 modified files in the second-review commit (2 harness twins, 2 contract-test twins, 2 eval scenarios, 1 scenario card, 1 protocol, 1 doc, 1 changelog), on top of the 13 modified files and 2 new files of the first review-fix commit and the 15 modified and 2 new files of the original implementation.`
- **Completion Exception**: `none`
- **Completion Decision and Timestamp**: `2026-11-13 16:10 UTC — implementation, the four first-review fixes, the three second-review fixes, and the refreshed evidence are complete; every gate passes locally and all 12 CI checks are green on d38a5b7. Merge is outside this record's approval boundary.`
