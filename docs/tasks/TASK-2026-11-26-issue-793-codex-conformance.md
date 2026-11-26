# Task Record: Codex CLI live conformance captures (issue #793, reduced scope)

<a id="TASK-2026-11-26-issue-793-codex-conformance"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-11-26-issue-793-codex-conformance`
- **Ceremony Level**: `Level 2 (Controlled)`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Documentation Work`
- **Specification**: `GitHub issue #793; docs/internal/host-conformance/multi-host-capture-plan.md sections 3.1-3.2 and 5; the issue's host-count criterion is reduced to one host by the measured inventory recorded under Reduced Scope below.`
- **External Reference**: `GitHub issue #793`
- **Owner / Actor**: `DeepSeek Harness agent (executor)`
- **Execution Scope**: `promptkit-os repository; new capture bundles under docs/internal/host-conformance/codex-cli/, the Codex CLI row and prose in docs/HOST-CONFORMANCE.md, the host-count sentence in README.md, and this record. No file under scripts/, workflows/, protocols/, templates/, or docs/BENCHMARKS.md; no implementation change of any kind. Local captures and one local documentation commit on branch feat/793-codex-conformance.`
- **Approval Boundary**: `Live capture on the local machine, artifact publication under docs/internal/host-conformance/codex-cli/, the documentation updates listed in Execution Scope, and one local commit on feat/793-codex-conformance are authorized. Push, pull request, merge, tag, release, npm publication, and any edit or closure of issue #793 remain unauthorized; the issue must stay open because its host-count criterion is unmet.`
- **Created**: `2026-11-26`

## 2. Objective and Boundaries

- **Objective**: `Produce one honest, reproducible Codex CLI 0.172.0 live conformance arm on this machine: the four single-turn probes plus the two-turn milestone-halt probe, run under the #784 bwrap isolation recipe with ChatGPT authentication, published as scrubbed artifact bundles, and reflected in the HOST-CONFORMANCE matrix and README count as a single newly measured host rather than as the three the issue asks for.`
- **Reduced Scope (issue #793)**: `The issue asks for live captures on at least three previously Untested mainstream hosts. The measured inventory on this machine on 2026-11-26 is: codex 0.172.0 present and previously Untested; opencode v2.4.1, commandcode 1.93.3, and agy 1.5.18 present but already captured and therefore not previously Untested; claude, cursor-agent, gemini, aider, and copilot absent. Only one previously Untested host is reachable, so this task can add at most one host, the issue's first acceptance criterion cannot be met on this machine, and issue #793 must remain open with that finding recorded. This record does not claim the three-host criterion and does not substitute a previously tested host for it.`
- **In Scope**:
  - `docs/internal/host-conformance/codex-cli/card-provenance/` — live capture bundle
  - `docs/internal/host-conformance/codex-cli/breaker-exhaustion/` — live capture bundle
  - `docs/internal/host-conformance/codex-cli/greenfield-saas-intake/` — live capture bundle
  - `docs/internal/host-conformance/codex-cli/halt-callout/` — live capture bundle
  - `docs/internal/host-conformance/codex-cli/milestone-halt/` — two-turn live capture bundle with the 300 s observation window
  - `docs/internal/host-conformance/codex-cli/README.md` — host index carrying the measured results and the reduced-scope note
  - `docs/HOST-CONFORMANCE.md` — Codex CLI row moved from Untested to measured, plus the per-probe table and capture metadata
  - `README.md` — host-conformance count sentence updated from three of eleven to four of eleven and from eight Untested to seven
  - `docs/tasks/TASK-2026-11-26-issue-793-codex-conformance.md` (this record) — reduced-scope restatement and evidence
- **Explicit Non-Goals**:
  - `No change to scripts/capture-host-session.mjs, scripts/render-capture-transcript.mjs, scripts/run-behavioral-eval.sh, or any other script; Codex emission has no renderer branch, so the transcript and write log are derived mechanically by a one-off documented transform and the raw post-scrub JSONL is preserved.`
  - `No implementation change to workflows/, protocols/, templates/, or the PromptKit surface; captures observe the installed directive, they do not edit it.`
  - `No capture on opencode, commandcode, or agy, because those hosts are already represented and the issue asks for previously Untested hosts.`
  - `No claim that Codex CLI meets the three-host criterion, no issue closure, and no promotion of an Untested cell without a live bundle behind it.`
  - `No push, pull request, merge, tag, release, or issue update in this phase.`
- **Dependencies**: `Codex CLI 0.172.0 at /home/linuxbrew/.linuxbrew/bin/codex, authenticated through ChatGPT (codex login status exits 0); bwrap 0.9.0; git; the five seed fixtures recovered from the published commandcode repository bundles.`
- **Risk**: `Medium — live host behaviour is not fully predictable and the Codex CLI path has no committed renderer, so a bad transform could misreport the arm. Mitigated by preserving the raw JSONL, scrubbing only paths, recording the transform in provenance.json, and publishing FAIL or PARTIAL exactly as scored.`
- **Verification Condition**: `Five bundles exist under docs/internal/host-conformance/codex-cli/ with the 22-file contract, each scorer.txt records the measured line, the isolation canary reports CANNOT-READ under bwrap while the same command reads unisolated, the milestone bundle carries a 300 s observation window and reproduces its state-check via bash scripts/check-milestone-halt-evidence.sh, no tracked artifact contains a raw host home path, docs/HOST-CONFORMANCE.md and README.md state four of eleven and seven Untested, and bash scripts/validate-execution-control.sh --root . --strict passes with this record in_progress or completed as appropriate.`

## 3. Acceptance Criteria

- [ ] **AC-1**: `This record restates the reduced scope, names the measured host inventory, explains why at least three previously Untested hosts cannot be met on this machine, and keeps issue #793 open.`
- [ ] **AC-2**: `Five Codex CLI 0.172.0 bundles exist under docs/internal/host-conformance/codex-cli/, each carrying the 22-file contract, the raw post-scrub session JSONL, a scorer.txt recorded from the probe's real checks, and a README naming the host, model, date, and transform.`
- [ ] **AC-3**: `Every bundle records a negative isolation canary (CANNOT-READ under bwrap) and a positive unisolated control, with the exact bwrap invocation in isolation.txt.`
- [ ] **AC-4**: `The milestone-halt bundle records a 300 s observation window, a resumed turn with no sign-off, state-check.json, and a reproducible bash scripts/check-milestone-halt-evidence.sh result.`
- [ ] **AC-5**: `No tracked artifact in the five bundles or the host index contains /home/heyloey, /home/linuxbrew, or any other raw host home path; paths are masked as $HOME and <repo>.`
- [ ] **AC-6**: `docs/HOST-CONFORMANCE.md records the Codex CLI row as measured with per-probe verdicts and capture metadata, and README.md states four of eleven host configurations with live captures and seven Untested.`
- [ ] **AC-7**: `No file under scripts/, workflows/, protocols/, templates/, or the measured inputs changes; git diff against origin/main touches only docs/internal/host-conformance/codex-cli/, docs/HOST-CONFORMANCE.md, README.md, and this record.`

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `Around 60 minutes; advisory.`
- **Hard Checkpoint**: `At or before 90 minutes; advisory.`
- **Event-Driven Checkpoints**: `Milestone, scope change, handoff, or context drift.`
- **Stop Conditions**: `Failed verification, scope expansion, missing authorization for a gated action, a capture that cannot be made honest, or developer stop.`
- **Host Timer Capability**: `The host cannot mechanically enforce checkpoint deadlines and cannot force-terminate a live probe at a chosen moment; the milestone-halt observation window measures repository state at 60 s intervals after the host exits. Timing remains a manual protocol limitation.`

## 5. State and Active Ownership

- **Execution State**: `blocked`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26`
- **Current Actor**: `DeepSeek Harness agent`
- **Next Action**: `Resolve the credential-isolation blocker: the owner must decide how Codex authentication is supplied to an isolated capture without the agent reading the credential store, or run the captures directly.`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 | DeepSeek Harness agent | Reduced scope derived from the measured host inventory and the issue's first criterion. | Issue #793; this record, section 2 |
| planned | in_progress | 2026-11-26 | DeepSeek Harness agent | Record restated; capture phase starting under bwrap isolation. | Section 6 |
| in_progress | blocked | 2026-11-26 | DeepSeek Harness agent | CC Safety Net blocked the credential copy required for isolated Codex authentication; no workaround attempted. | Section 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `docs/tasks/TASK-2026-11-26-issue-793-codex-conformance.md` — reduced-scope restatement; capture evidence pending
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: `The reduced-scope record validated at commit 32c1d35 with bash scripts/validate-execution-control.sh --root . --strict -> VALID|RECORDS=85|ROOT=. No capture bundle exists yet. The blocking event was: BLOCKED by CC Safety Net; Reason: Access to a sensitive path is not allowed; Rule: secret.cli.codex; Segment: /home/heyloey/.codex/auth.json.`
- **CI Evidence**: `Pending — branch not pushed, so no workflow ran.`
- **Review Evidence**: `Pending human review of the published bundles and counts.`
- **Commit Evidence**: `Pending — one local documentation commit is created after the captures.`
- **Pull Request Evidence**: `Pending separate authorization.`
- **Release Evidence**: `N/A — no release action in scope.`
- **Blocker and Resume Condition**: `CC Safety Net rule secret.cli.codex blocked copying /home/heyloey/.codex/auth.json into the bwrap scratch CODEX_HOME. The block instruction forbids retrying or working around it, and an isolated Codex CLI cannot authenticate without that credential, so the five captures cannot start in this session. Resume after the owner either runs the captures in a session they control or decides how authentication is supplied to the isolated host without the sandboxed model being able to read the credential store; then resume at card-provenance.`
- **Completion State**: `blocked`
- **Acceptance Results**: `AC-1 Pass — the record restates the reduced scope, the measured inventory, and the unmet three-host criterion. AC-2 through AC-7 Blocked — no capture bundle, matrix row, or count update was produced because the isolated host could not authenticate.`
- **Changed-File Summary**: `The #793 task record restating the reduced one-host scope and the unmet three-host criterion. Capture bundles, matrix row, and README count follow in the same branch.`
- **Completion Exception**: `The issue's criterion of at least three previously Untested hosts cannot be met on this machine: only Codex CLI 0.172.0 is both installed and previously untested, while opencode, commandcode, and agy are already captured and claude, cursor-agent, gemini, aider, and copilot are absent.`
- **Completion Decision and Timestamp**: `Blocked pending owner decision — 2026-11-26.`
- **Branch / Revision**: `feat/793-codex-conformance at origin/main 6e381e1`
