# Task Record: Isolate the bwrap capture HOME portably and scrub host paths from benchmark packets

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: TASK-2026-11-26-capture-home-isolation
- **Specification**: Issue #784 (`fix(capture): isolate bwrap HOME portably without writable credential mounts and scrub host paths from benchmark manifests`)
- **External Reference (Optional)**: https://github.com/lowqualityloey/promptkit-os/issues/784
- **Owner / Actor**: Repository maintainer / implementation subagent `impl-784`
- **Execution Scope**: Capture harness isolation recipe, benchmark packet scrub, their regression coverage, and the documentation that describes both
- **Approval Boundary**: Human approval required before push, pull request, merge, release, tag, publication, deployment, or any remote action; the local commit is the last authorized step
- **Created**: 2026-11-26 UTC

> This Local Task Source is authoritative for this Controlled Work. External trackers and `docs/STATE.md` are references or synchronized projections, not alternate task authority.

## 2. Objective and Boundaries

- **Objective**: Make the capture sandbox derive every path from `os.homedir()` and give it a disposable staged HOME carrying only the narrowest read-only credential, so no capture mounts the operator's real home or its credential, instruction and worktree directories read-write; and stop the benchmark driver from writing raw operator roots into a packet that is meant to be shareable.
- **In Scope**:
  - `scripts/capture-host-session.mjs` - portable HOME resolution, staged capture HOME, narrowed read-only credential binds, `CAPTURE_HOME|` / `CAPTURE_CREDENTIAL|` / `CAPTURE_MOUNTS|` plan lines.
  - `benchmarks/run-ab-benchmark.sh` - scrub the recorded roots on write and expand them on `--finalize`.
  - `scripts/tests/run-capture-host-session-tests.sh` - deterministic mount assertions, `os.homedir()` derivation, root-HOME refusal, and a namespace-guarded live sandbox canary.
  - `scripts/tests/run-capture-host-session-tests.ps1` - the same coverage in the PowerShell twin, plus resolving the running PowerShell instead of a possibly-shimmed `pwsh` on `PATH`.
  - `scripts/tests/run-benchmark-driver-tests.sh` - scrubbed-packet assertions and the placeholder finalize path.
  - `docs/internal/host-conformance/antigravity/README.md` - the documented recipe and its canary coverage.
  - `CHANGELOG.md` - one `[Unreleased]` entry under the existing `### Fixed` heading.
  - `docs/tasks/TASK-2026-11-26-capture-home-isolation.md` - this canonical Task Record and evidence log.
- **Explicit Non-Goals**:
  - Do not rewrite or re-scrub the dated `benchmarks/runs/2026-10-*` and `2026-10-31-*` packets; the scrub is forward-only and historical manifests stay as they were produced.
  - Do not touch `.github/workflows/ci.yml`, `.gitattributes`, `docs/BENCHMARKS.md`, `templates/`, `README.md`, `docs/HOST-CONFORMANCE.md`, `init.ps1`, or `package/`.
  - Do not change the capture contract a bundle already carries (provenance, session, transcript, scorer artifacts), the fixture seeding, or the kit exclusions.
  - Do not push, open a pull request, merge, or publish.
- **Dependencies**: Worktree base `d7ede1f` (merge of #782); `bwrap` 0.9.0 and `agy` 1.5.16 on the development host; PowerShell 7 available for the twin suite.
- **Risk**: Medium - the recipe is the only thing that keeps the answer key out of a `--dangerously-skip-permissions` session, so a regression here silently contaminates every future capture rather than failing loudly. Mitigated by asserting the mounts deterministically on every host and by a live canary where the kernel permits it.
- **Verification Condition**: `scripts/scan-staged-secrets.sh` exits 0; the capture module contains no `/home/` literal and no operator name; both capture suites report `CAPTURE_HOST_SESSION_TESTS|PASS|39 passed` (deterministic sections plus the live canary on a host that permits unprivileged user namespaces); the benchmark driver suite passes including the scrubbed-packet case; both changed Bash files parse with `bash -n` and the module with `node --check`.

## 3. Acceptance Criteria

- [x] **AC-1**: Every user path the capture recipe uses comes from `os.homedir()`, the module carries no hardcoded `/home/` literal, and `scripts/scan-staged-secrets.sh` exits 0.
  - **Result**: Pass
  - **Evidence**: `grep -Fc '/home/' scripts/capture-host-session.mjs` returns 0 matches (exit 1) and `grep -Fc 'heyloey' scripts/capture-host-session.mjs` returns 0 matches (exit 1). The recipe's `--tmpfs` destination, the staged HOME, the credential sources and the `rtk` lookup all resolve at runtime (`homeDir = os.homedir()`, `rtkPath = which('rtk')`), and a HOME of `/` is refused with `cannot isolate HOME` on exit 2, asserted in both suites. `scripts/scan-staged-secrets.sh` exits 0 on the staged change set. It failed once during implementation - exit 3, `Narrative surface HOME_ABSOLUTE_PATH (high) in staged additions: CHANGELOG.md:22` - because the first draft of the changelog entry quoted the operator path it was describing; the entry now describes it instead of reproducing it, and the re-scan is clean.
- [x] **AC-2**: `bwrapArgv` never mounts `~/.gemini` or `~/.config/antigravity` read-write; the canary proves the staged HOME is a different directory from the host's and that the checkout, scenario files, worktrees, brain and `~/.ssh` are unreachable inside it, skipping cleanly where user namespaces are unavailable.
  - **Result**: Pass
  - **Evidence**: the deterministic section reads the argv the harness prints for itself (`CAPTURE_MOUNTS|`) and asserts exactly one read-write bind landing on the host HOME (the staged `<work>/capture-home`), zero read-write binds of any directory under it, one `--tmpfs` at `$HOME` and one at `/tmp`, every `--ro-bind` a regular file bound onto its own path, no `worktrees`, `brain`, `settings.json`, `mcp_config` or `GEMINI.md` surface anywhere in the argv, and every staged credential a file under `$HOME`. The live canary ran on this host and reported the sandbox HOME inode differing from the host's, `CHECKOUT=unreachable`, `SCENARIO=unreachable`, `WORKTREES=unreachable`, `BRAIN=unreachable`, `GEMINI_SETTINGS=unreachable`, `SSH=unreachable`, `TOKEN=readable`, `WRITABLE=yes`, `FIXTURE=fixture-marker`. Both suites report `CAPTURE_HOST_SESSION_TESTS|PASS|39 passed`. The skip path is exercised by construction: the live section guards on `bwrap --dev-bind / / --tmpfs /tmp true` succeeding and prints `SKIP: bwrap cannot create unprivileged user namespaces on this host` otherwise, which is what macOS and Ubuntu 24.04 with `apparmor_restrict_unprivileged_userns=1` take.
- [x] **AC-3**: A driver run's newly generated `manifest.tsv`, `engine-path.txt` and `key-location.txt` carry `<home>`, `<engine>` and `<seed>` placeholders rather than raw operator roots, the scrubbed packet still finalizes on the producing host, and the dated historical runs are untouched.
  - **Result**: Pass
  - **Evidence**: `bash scripts/tests/run-benchmark-driver-tests.sh` reports `82 passed, 0 failed`, including the case that greps each packet file for the raw fake home and the checkout root (no hits), requires `engine-path.txt` to be exactly `<engine>`, requires `isolation.txt` to carry `host_home: <home>`, and requires every manifest run directory to start with `<home>/`; the finalize case additionally requires `FINALIZE|ENGINE|placeholder=resolved` and still translates blind ids and re-extracts both arms. `git status --short` reports no change under `benchmarks/runs/`.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **Batch Authorization**: N/A
- **Soft Checkpoint**: Around 60 minutes
- **Hard Checkpoint**: At or before 90 minutes
- **Event-Driven Checkpoints**: Milestone, task switch, scope expansion, handoff, compaction, or context drift
- **Stop Conditions**: Missing approval/context, failed verification, blocker, hard checkpoint, or developer stop
- **Host Timer Capability**: Host timer limitation recorded; the host cannot forcibly terminate a live generation, so timer evidence is durable policy evidence only.

## 5. State and Active Ownership

- **Execution State**: `awaiting_review`
- **Mapped `pk:tasks` Status**: `In Review`
- **Active Task Pointer**: None
- **Start Time**: 2026-11-26 UTC
- **Current Actor**: implementation subagent `impl-784`
- **Next Action**: Human review of the single local commit; push, pull request, merge and release remain outside this milestone.

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-11-26 UTC | impl-784 | Task Record created from issue #784 | This Task Record |
| planned | in_progress | 2026-11-26 UTC | impl-784 | Recipe and packet defects reproduced on the development host | Section 2, `docs/internal/host-conformance/antigravity/README.md` |
| in_progress | awaiting_review | 2026-11-26 UTC | impl-784 | AC-1 through AC-3 passed with both capture suites and the driver suite green | Sections 3 and 6 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `scripts/capture-host-session.mjs` - portable HOME, staged capture HOME, narrowed read-only credential binds, new plan lines.
  - `benchmarks/run-ab-benchmark.sh` - packet scrub on write, expansion on finalize.
  - `scripts/tests/run-capture-host-session-tests.sh` - deterministic recipe assertions and the live sandbox canary.
  - `scripts/tests/run-capture-host-session-tests.ps1` - the same coverage in the twin.
  - `scripts/tests/run-benchmark-driver-tests.sh` - scrubbed-packet and placeholder-finalize coverage.
  - `docs/internal/host-conformance/antigravity/README.md` - recipe, staged-HOME rationale, canary coverage.
  - `CHANGELOG.md` - one `[Unreleased]` entry.
  - `docs/tasks/TASK-2026-11-26-capture-home-isolation.md` - this record.
- **Branch / Revision**: `fix/784-capture-isolation` @ base `d7ede1f`, plus the single commit described under Commit Evidence.
- **Scope Change Records**: None
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: `node --check scripts/capture-host-session.mjs`, `bash -n benchmarks/run-ab-benchmark.sh`, `bash -n scripts/tests/run-capture-host-session-tests.sh` and `bash -n scripts/tests/run-benchmark-driver-tests.sh` all parsed. `bash scripts/tests/run-capture-host-session-tests.sh` → `CAPTURE_HOST_SESSION_TESTS|PASS|39 passed`. `/opt/microsoft/powershell/7/pwsh -NoProfile -File scripts/tests/run-capture-host-session-tests.ps1` → `CAPTURE_HOST_SESSION_TESTS|PASS|39 passed`. `bash scripts/tests/run-benchmark-driver-tests.sh` → `Benchmark driver harness (Bash): 82 passed, 0 failed.` `bash scripts/check-changelog-entry.sh` passed on the committed range. `bash scripts/scan-staged-secrets.sh` exited 0.
- **CI Evidence**: Not available in this session; the workflow file is out of scope for this change and both suites run from the same entry points CI uses.
- **Review Evidence**: N/A - no pull request is authorized at this stage.
- **Commit Evidence**: one commit, `fix(capture): isolate the sandbox HOME and scrub host paths from packets`, carrying every file listed above. A commit cannot record its own hash, so the SHA is reported in the handoff rather than embedded here; the change is a single commit on top of `d7ede1f` with no intermediate history.
- **Pull Request Evidence**: N/A; not authorized.
- **Release Evidence**: N/A; release-impact review is a later milestone.
- **Blocker and Resume Condition**: None. The `.ps1` twin was executed on this host with the real PowerShell 7 install at `/opt/microsoft/powershell/7/pwsh`; the `pwsh` on `PATH` is a WSL shim that cannot exec, which is why the twin resolves the running PowerShell executable instead of `PATH`.

### Completion Decision

- **Completion State**: awaiting_review
- **Acceptance Results**: AC-1 Pass; AC-2 Pass; AC-3 Pass.
- **Changed-File Summary**: the capture module and the benchmark driver changed; their three test twins, the capture-sandbox documentation, the CHANGELOG and this record changed with them; no workflow, template, release, or historical benchmark file changed.
- **Completion Exception**: None
- **Completion Decision and Timestamp**: Implementation, regression coverage, documentation and local verification complete for issue #784; awaiting human review on 2026-11-26 UTC.

A passing test suite or CI job will provide evidence only. It will not authorize a push, pull request, merge, release, publication, deployment, or rollback.
