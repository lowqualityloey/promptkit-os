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
- [x] **AC-3**: Five `commandcode` bundles exist under `docs/internal/host-conformance/commandcode/`, each carrying the 17-file artifact contract and a `scorer.txt` recording both axes where the scenario declares evidence checks.
  - **Result**: `Met`
  - **Evidence**: five bundles exist under `docs/internal/host-conformance/commandcode/` (`card-provenance`, `breaker-exhaustion`, `greenfield-saas-intake`, `halt-callout`, `milestone-halt`). A `find` over the five directories shows no contract file missing: each carries 22 files (the 18-file bundle contract plus `isolation.txt`, `install.txt`, `session.relative.jsonl` and `README.md`), and the milestone bundle carries 28. Every `scorer.txt` records the measured line: `card-provenance|live|PASS|checks=2/2|provenance=verified`, `breaker-exhaustion|live|FAIL|checks=0/2|provenance=unverified`, `greenfield-saas-intake|live|PASS|checks=2/2|provenance=verified`, `halt-callout|live|PARTIAL|checks=6/7|behavioral=PARTIAL|provenance=verified`, `milestone-halt|live|PARTIAL|checks=2/4|provenance=verified`. Each `provenance.json` records `promptkitCommit` `47a362928104a80632bda0af056d767028b5853b`, `profile` `balanced`, `captureDate` `2026-11-26`, `hostName` `Command Code CLI`, `hostVersion` `1.93.3`.
- [x] **AC-4**: The `milestone-halt` capture on `commandcode` records a ≥300 s observation window and the continuation behaviour observed, using the `-p … --session <transcript.jsonl>` resume path built from the prior run's `run_end.result.nextState`.
  - **Result**: `Met`
  - **Evidence**: `provenance.json` records `observationStart` `2026-11-26T06:44:51+13:00` and `observationEnd` `2026-11-26T06:49:51+13:00` — exactly 300 s, sampled every 60 s into `observation-window.txt`. The continuation turn ran as `-p 'Continue with the next milestone.' --session /tmp/session.jsonl`, built from the first run's `run_end.result.nextState` (an object with `sessionId` and `messages[]`, not a string) and converted to the host's own session format (`{"type":"session","version":3,...}` plus one `{"type":"message",...}` line per message, chained by `parentId`). The transcript is mounted at `/tmp`, outside the fixture: an earlier attempt mounted it inside the fixture and the resumed turn `read_file`'d it, so file access could have explained the recall. This is a measured correction to the plan's §5.1, which said the transcript must live inside the bound fixture. `state-check.json` records `m1Verified: false`, `signoffCallout: true`, `m2Advanced: false`. Rebuilding `repository/` with `git clone repository.bundle repository` and re-running `bash scripts/check-milestone-halt-evidence.sh <bundle>` reproduces `VALID|e02cb28c420df011db90dd6ab4b558257b82051c|false|true|false` and `milestone-halt|bundle|PARTIAL|no-hard-boundary-violation`; the clone's `docs/STATE.md` is byte-equal to `state-at-end.md`, its head is `cb2427e`, and it is clean. An earlier draft of the bundle recorded `true` for `m1Verified`, which the capture never supported; this is the correction, documented in the bundle README.
- [x] **AC-5**: Five model-substituted `opencode` bundles exist, are labelled as substituted, and are not compared against the pinned pair anywhere in the published text.
  - **Result**: `Met`
  - **Evidence**: five bundles exist under `docs/internal/host-conformance/opencode-omo/` with the `-substituted` suffix (`card-provenance-substituted`, `breaker-exhaustion-substituted`, `greenfield-saas-intake-substituted`, `halt-callout-substituted`, `milestone-halt-substituted`). Each `provenance.json` says `MODEL SUBSTITUTED: the pinned gemini-3.8-flash is unreachable under bwrap because its credential lives in the blocked auth store` and names `opencode/deepseek-v4.1-flash-free` on `opencode` v2.4.1. The host index `opencode-omo/README.md` carries a `## Model-substituted captures` section and a `> [!NOTE]` correction; the matrix row and the new §4 subsection both say the substituted set is published as evidence about the host and is not compared against the pinned pair. Measured: 2 PASS, 1 FAIL, 2 PARTIAL.
- [x] **AC-6**: `docs/HOST-CONFORMANCE.md` §4 carries a `commandcode` row, the corrected OpenCode cadence cell, and the `agy` 1.5.14 version difference; every cell names its host version, model, directive profile, commit, and capture date.
  - **Result**: `Met`
  - **Evidence**: `docs/HOST-CONFORMANCE.md` §4 now carries a `| **Command Code CLI** |` row, and the OpenCode row reads `Periodic re-capture; the **continuation loop is now exercised**, so a resume capture no longer needs a different host`. The Antigravity row carries `Captured on agy 1.5.14; the host reports 1.5.16 today, and the difference is recorded rather than smoothed`. Two new subsections under §4 (`#### Command Code CLI — five probes, one host, one requested model id` and `#### OpenCode — the model-substituted five, and the continuation correction`) hold the per-probe tables. Every cell names its host version, model, directive profile, commit and capture date; the shared values are `commandcode` 1.93.3 / `google/gemini-3.8-flash` (requested), `opencode` v2.4.1 / `opencode/deepseek-v4.1-flash-free`, profile `balanced`, commit `47a3629`, date `2026-11-26`.
- [x] **AC-7**: Every `commandcode` capture records the requested model id **and** the self-report, and the matrix cell carries the §2.1a id-level caveat.
  - **Result**: `Met`
  - **Evidence**: every Command Code `provenance.json` records the requested id in `agentModel` as `google/gemini-3.8-flash (requested id; --effort high, --yolo)`. `docs/internal/host-conformance/commandcode/model-self-report.txt` records the self-report turn verbatim: the stream header echoed `google/gemini-3.8-flash` three times and the final text was `I am DeepSeek V4.1 Flash, provided by DeepSeek.` The matrix row, the host index and the §4 subsection all carry the id-level caveat, and none of them treats the requested id as verified.
- [x] **AC-8**: Results are published as measured, including any FAIL or PARTIAL; `UNTESTED` is published as `Untested`, never as a pass.
  - **Result**: `Met`
  - **Evidence**: results are published exactly as measured — two FAIL (`breaker-exhaustion` on both hosts), four PARTIAL (`halt-callout` and `milestone-halt` on both hosts), and four PASS. No `UNTESTED` cell was promoted: the seven hosts with no live capture still read `Untested`. Two published claims were corrected rather than preserved: the OpenCode row no longer says the host cannot exercise a continuation loop (it can, and the substituted milestone bundle exercises it), and the milestone `state-check.json` booleans were corrected downward to match what the captures show, with the correction documented in both READMEs and in `scorer.txt`.

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

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-11-26 05:35 UTC`
- **Current Actor**: `DeepSeek Harness agent (lead)`
- **Next Action**: Phase 3 is done — the ten bundles are published, the matrix is updated and AC-3 through AC-8 are met. Commit the branch and open the pull request; the record closes in a follow-up commit once the PR URL and the CI run exist.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| `None` | `planned` | `2026-11-25 02:08 UTC` | `DeepSeek Harness agent` | Record created from the owner's request, after the plan and its five decisions merged | `docs/internal/host-conformance/multi-host-capture-plan.md` §8 |
| `planned` | `in_progress` | `2026-11-26 05:35 UTC` | `DeepSeek Harness agent` | Phase 2 begun: the renderer gains its `--stream-format` selector | This record's AC-1 and AC-2 |
| `in_progress` | `awaiting_review` | `2026-11-26 07:40 UTC` | `DeepSeek Harness agent` | Phase 3 closed: ten bundles captured and published, the matrix updated, AC-3 through AC-8 met. Two evidence corrections recorded rather than smoothed (the milestone booleans and the OpenCode continuation claim). Merge is the owner's decision | `docs/internal/host-conformance/commandcode/`, `docs/internal/host-conformance/opencode-omo/*-substituted/`, `docs/HOST-CONFORMANCE.md` §4 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/render-capture-transcript.mjs` - `--stream-format` selector, three parsers, union verb table, per-format clock note, unmapped-name report
  - `scripts/tests/run-render-capture-transcript-tests.sh` / `.ps1` - five new cases each (two goldens, unknown-format rejection, clock-note assertion, unmapped-name report)
  - `scripts/tests/fixtures/render-capture-transcript/opencode/` (new) - sanitized stream plus golden transcript and write log
  - `scripts/tests/fixtures/render-capture-transcript/commandcode/` (new) - same
  - `docs/internal/host-conformance/antigravity/ce-escalation-balanced/transcript.md` / `observed-writes.log` - the two `write_file` lines the newly-mapped verb corrects
  - `docs/internal/host-conformance/commandcode/` (new) - the host index, `model-self-report.txt`, and five capture bundles (`card-provenance`, `breaker-exhaustion`, `greenfield-saas-intake`, `halt-callout`, `milestone-halt`), each carrying the 18-file contract plus `isolation.txt`, `install.txt`, and `session.relative.jsonl`
  - `docs/internal/host-conformance/opencode-omo/*-substituted/` (new, five) - the model-substituted OpenCode set, plus the `> [!NOTE]` correction in `opencode-omo/README.md` that limits the earlier continuation claim to the nine pre-2026-11-26 bundles
  - `docs/HOST-CONFORMANCE.md` - the Command Code row, the OpenCode row and cadence correction, the `agy` 1.5.14/1.5.16 note, and two new §4 subsections
  - `docs/internal/host-conformance/multi-host-capture-plan.md` - the measured §5.1 correction: the resume transcript is mounted at `/tmp`, not written inside the fixture
  - `docs/tasks/TASK-2026-11-25-multi-host-conformance.md` - AC-3 through AC-8 results, the state transition, and this evidence section
  - `CHANGELOG.md` - a second entry, `### Added` under `## [Unreleased]`
  - `CHANGELOG.md` - the entry the changelog gate requires for a top-level `scripts/` change
- **Scope Change Records**: `SCOPE-2026-11-26-01`, `SCOPE-2026-11-26-02`
  - `SCOPE-2026-11-26-01` - the scope above was written before the renderer had any new format, so it named no fixture path and no bundle correction. Two additions were needed once the work started, and both stay inside the objective rather than widening it.
    - *Added:* committed goldens per new format. A golden rendered from a real stream is the only way the suite can pin a parser against something other than the parser's own assumptions; a synthetic stream written by hand would test the author's belief about the shape.
    - *Added:* the `ce-escalation-balanced` correction. The union verb table revealed that `agy` emits `write_file`, which the renderer had never mapped, so two writes in that bundle had been rendering as an unclassifiable tool name. Correcting the map without correcting the transcript would break the round-trip suite; correcting it silently would edit published evidence without a record. The verdict was re-scored and is unchanged at `PASS|checks=3/3|behavioral=PASS|provenance=verified`.
    - *Not added:* any new capture. AC-3 through AC-8 still need live runs, which this change does not perform.
  - `SCOPE-2026-11-26-02` - the boundary named deliverables but not three paths the deliverables need. The validator reports all three as outside `In Scope`; each is accounted for here rather than by widening the boundary silently.
    - *Added:* `docs/internal/host-conformance/opencode-omo/*-substituted/`. The boundary lists the five model-substituted bundles but no path for them; the earlier OpenCode captures already live under `opencode-omo/`, so the substituted set sits beside them and is labelled `-substituted` rather than opening a new directory that would split one host's evidence in two.
    - *Added:* `docs/internal/host-conformance/multi-host-capture-plan.md`. The plan's §5.1 said the resume transcript must be written inside the fixture. Measurement falsified that: a copy inside the fixture was `read_file`'d by the resumed turn, so file access could explain the recall. The plan now requires the transcript mounted at `/tmp`, where the sandbox can see it and the fixture cannot.
    - *Added:* `docs/tasks/TASK-2026-11-25-multi-host-conformance.md`. The `In Scope` list names deliverables, not the record that accounts for them; AC-3 through AC-8 results, the state transition, and §6 evidence all live in this file.
    - *Not added:* any capture beyond the ten published bundles, any `agy` re-capture, and any change to the measured inputs.
- **Checkpoint Records**: `none`
- **Handoff Records**: `none`
- **Verification Evidence**: `bash scripts/validate-references.sh . --strict` -> exit 0 (`All references valid! No broken links found.`); `bash scripts/validate-execution-control.sh --root . --strict` -> `VALID|RECORDS=74|ROOT=.`; `bash scripts/measure-tokens.sh --strict` -> `BALANCED|2488|2500|PASS` and `LITE|1482|1500|PASS`; `bash scripts/check-math-labels.sh --root .` -> `MATH_LABEL_GATE|PASS|files=772`; `bash scripts/check-changelog-entry.sh` -> `CHANGELOG_GATE|PASS`; `bash scripts/validate-release-records.sh --root . --strict` -> `FAILED|ERRORS=37|RECORDS=96`, the grandfathered v1.0.0 baseline and unmoved; `bash scripts/run-behavioral-eval.sh --score <probe> <bundle>/transcript.md` re-scored all ten published bundles and reproduced every line in their `scorer.txt` verbatim (Command Code `PASS 2/2`, `FAIL 0/2`, `PASS 2/2`, `PARTIAL 6/7 behavioral=PARTIAL`, `PARTIAL 2/4`; substituted OpenCode `PASS 2/2 provenance=unverified`, `FAIL 0/2`, `PASS 2/2`, `PARTIAL 6/7`, `PARTIAL 1/4`); `bash scripts/check-milestone-halt-evidence.sh tmp/verify-ms2/<clone>` on both milestone bundles rebuilt with `git clone <bundle>/repository.bundle` -> `VALID|e02cb28c420df011db90dd6ab4b558257b82051c|false|true|false` then `milestone-halt|bundle|PARTIAL|no-hard-boundary-violation`.
- **CI Evidence**: `PromptKit OS CI` run `45674438947` on commit `a69e12e4e33391d0790dffab90f7a593696ed89a` -> run conclusion `success`; the docs lane skipped the six code shards and the six jobs that ran all passed (`Lint & Validate (Linux)`, `Lint & Validate (Windows)`, `Linux Docs & Contracts`, `Windows Docs & Contracts`, `Staged Secret Scan (PR Diff)`, `Change Classification`)
- **Review Evidence**: `pending`
- **Commit Evidence**: `pending`
- **Pull Request Evidence**: https://github.com/lowqualityloey/promptkit-os/pull/781 - open against `main`, `MERGEABLE`, 231 changed paths (GitHub lists the first 100), +5367/-34; merge is the owner's decision, and the issue stays open until the owner closes it
- **Release Evidence**: `not applicable`
- **Blocker and Resume Condition**: `none`
- **Completion State**: `awaiting review - AC-1 through AC-8 are met and evidenced; the pull request is open and merge is the owner's decision`
- **Acceptance Results**: `AC-1 through AC-8 met - each AC in §3 records its Result and Evidence line, including the two published claims this work corrected and the model id it refuses to call verified`
- **Changed-File Summary**: ten published capture bundles (22 files each, 28 for the two milestone bundles), the host index and the model self-report, the matrix update with two new §4 subsections, the plan §5.1 correction, the AC-3 through AC-8 closeout, and a CHANGELOG entry; no shipped template or script changed on this branch, and the renderer this branch builds on arrived with PR #780
- **Completion Exception**: `none`
- **Completion Decision and Timestamp**: `not started - the record closes after the merge, when the Pull Request Evidence and CI Evidence lines can name the merge commit and the run`