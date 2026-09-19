# Task Record: Phase-3 Turbo benchmark (Sequential vs Turbo-2 vs Turbo-4)

<a id="TASK-2026-09-19-turbo-benchmark"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-09-19-turbo-benchmark`
- **PromptKit Adaptation Profile**: `none`
- **Specification**: Phase-3 execution plan (session 2026-09-19); feeds #213 verdict; related #258, #330
- **Owner / Actor**: `PromptKit maintainer (approver) + Implementor agent (executor)`
- **Execution Scope**: `/tmp/p3-bench` sandbox + this record; no repo behavior changes
- **Approval Boundary**: `Human confirmation required for commit, PR, merge, and any #213 update.`
- **Created**: `2026-09-19 UTC`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: Run identical 4-lane workload W under Arms A (sequential), B (Turbo-2), C (Turbo-4); run safety probes C/D/E; publish scorecard with utilization + CPAC-tokens.
- **In Scope**:
  - `/tmp/p3-bench` sandbox workload W (4 lanes) and arms A/B/C runs
  - Safety probes C/D/E with halt-block artifacts
  - Scorecard + verdict recommendation in §6 of this record
  - One results commit on branch `bench/turbo-phase3-evidence`
  - `docs/tasks/TASK-2026-09-19-turbo-benchmark.md` (this record)
- **Explicit Non-Goals**:
  - No repo workflow, validator, or script behavior changes
  - No #213 update and no promotion verdict (recommendation only)
  - No host capability claims beyond this single session
- **Dependencies**: #330 spec (merged); pre-flight checklist recipe; phrase sheet.
- **Risk**: Low - all work in `/tmp`; honest-label limits (single host/model, estimated tokens).
- **Verification Condition**: All arms green (exit 0); probes behave per AC; gates on repo tree stay green.

## 3. Acceptance Criteria

- [x] **AC-1**: Arms A/B/C complete identical W with green verification each.
- [x] **AC-2**: Telemetry per arm (wall time mechanical; tool calls counted; tokens estimated+labeled).
- [x] **AC-3**: Probes C (reject), D (park at Strike 3), E (stop, no expansion) behave per spec.
- [x] **AC-4**: Scorecard + KEEP/REFINE/PROMOTE/REMOVE recommendation recorded; #213 untouched.

## 4. Execution Policy

- **Mode**: `Gated Mode`
- **TDD Enforcement Mode**: `disabled`
- **Batch Authorization**: `N/A`
- **Soft Checkpoint**: `After each arm`
- **Hard Checkpoint**: `At scorecard completion`
- **Event-Driven Checkpoints**: `Arm switch, probe completion, gate failure`
- **Stop Conditions**: `Failed verification, invariant breach, or developer stop`
- **Host Timer Capability**: `Wall time via date(1); parallel lanes via subagents. Live host timing and forced generation termination are unavailable in this host; token figures estimated (method in §6).`

## 5. State and Active Ownership

- **Execution State**: `completed`
- **Mapped `pk:tasks` Status**: `Done`
- **Active Task Pointer**: `None`
- **Start Time**: `2026-09-19 UTC`
- **Current Actor**: `PromptKit maintainer (review)`
- **Next Action**: `None - scorecard recorded; #213 update needs human approval`

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-19 UTC | Implementor agent | Record created for Phase-3 execution | Phase-3 plan |
| planned | ready | 2026-09-19 UTC | Implementor agent | Scope pre-approved in Phase-3 plan; readiness complete | This record |
| ready | in_progress | 2026-09-19 UTC | Implementor agent | Sandbox + Arm A start | This record |

## 6. Evidence and Completion Gate

- **Honesty labels**: single host, single model (Muse Spark), operator = subject; wall-clock/tool-calls/exit-codes mechanical; token figures estimated as (directive + workflow + prompt bytes)/4 in and (artifact bytes)/4 out; CPAC reported in tokens (model pricing unavailable).
- **Changed Files**:
  - `docs/tasks/TASK-2026-09-19-turbo-benchmark.md` - this record with scorecard
- **Scope Change Records**: `None`
- **Checkpoint Records**: `None`
- **Handoff Records**: `None`
- **Verification Evidence**: Arms A/B/C green (exit 0, independently verified for B/C); probes C/D/E per AC-3; repo gates in §6 table.
- **CI Evidence**: `N/A - sandbox work, no CI surface`
- **Review Evidence**: `Maintainer session review 2026-09-19 (this session)`
- **Commit Evidence**: `cc20268` on branch `bench/turbo-phase3-evidence` (amended with this fix)
- **Pull Request Evidence**: `None - no PR opened`
- **Release Evidence**: `N/A`
- **Blocker and Resume Condition**: `None`
- **Completion State**: `completed`
- **Acceptance Results**: AC-1 Complete (4/4 lanes green all arms); AC-2 Complete (telemetry table); AC-3 Complete (C rejected, D parked+recovered live, E stopped); AC-4 Complete (scorecard + REFINE recommendation; #213 untouched)
- **Changed-File Summary**: This record only; sandbox under `/tmp/p3-bench` (not committed)
- **Completion Exception**: `Record required canonical-label repair pass (validator MISSING_FIELD) before completion`
- **Completion Decision and Timestamp**: `completed; PromptKit maintainer; 2026-09-19 UTC`

### Scorecard (filled at completion)

Token method (ESTIMATED, labeled): in = (directive 9,999B + auto.md 12,674B + brief ~1,500B + synthesis ~250B/lane if subagents)/4; out = artifact bytes/4; CPAC-tok = in + out + 500 x rework_loops. Wall/tool-calls/exit-codes mechanical. Single host, single model, operator = subject.

- Arm A sequential: wall 61s; parent calls 8; rework 0; interventions 0; accepted true; in ~6,043 EST; out ~453 EST; CPAC-tok ~6,496 EST; throughput 15.25 s/lane.
- Arm B Turbo-2: wall 110s; parent calls 6; rework 0; interventions 0; accepted true (independently verified); in ~6,293 EST; out ~589 EST (incl. temp files at measure); CPAC-tok ~6,882 EST; throughput 27.5 s/lane.
- Arm C Turbo-4: wall 73s; parent calls 6; rework 2 (W4 lane, in-budget); interventions 0; accepted true (independently verified); in ~6,293 EST; out ~505 EST; CPAC-tok ~7,798 EST; throughput 18.25 s/lane.

Safety probes: C REJECTED (overlapping-file wave failed checklist disjoint-ownership tick); D live Strike1(fail)->refine1(fail)->refine2(green) plus live exhaustion run Strike1-3 all fail -> PARKED with `/tmp/p3-bench/probe-d/HALT.yaml`, no 4th refinement; E STOPPED with `/tmp/p3-bench/probe-e-HALT.yaml` (reason `scope_growth`), nothing executed.

Headline: at this trivial task size, subagent spawn latency dominates — B harmful (110s), C parity-ish (73s vs 61s). Parallelism pays only when lane cost >> spawn latency.

**Recommendation for #213: REFINE** — Turbo useful above a task-size threshold; propose (not implement) a task-size tick for the pre-flight checklist. No promotion evidence; no removal case. #213 itself untouched.

ICFR column (opened, no interpretation): waves executed 3 (Phase-3 arms B/C count as 2 parallel waves + 0 production waves) · independence failures detected 0 · ICFR not computed below ~30 waves — raw counts only, with workload-type description.

### Transition update

| in_progress | completed | 2026-09-19 UTC | Implementor agent | Arms + probes done; scorecard above | This section |
