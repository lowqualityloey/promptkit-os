# Task Record: Valid transition-table scoping fixture

- **Record Type**: `Task Record`
- **Task ID**: TASK-2026-09-08-transition-table-scope
- **Specification**: `synthetic-fixture`
- **External Reference (Optional)**: N/A
- **Owner / Actor**: Fixture validator
- **Execution Scope**: Synthetic fixture
- **Approval Boundary**: Human approval required before remote or release action
- **Created**: 2026-09-08 14:00 UTC
- **Objective**: Prove transition validation reads only the Transition History table, accepts backticked state cells, and permits gated re-plan loops.
- **In Scope**:
  - `fixture/transition-table-scope.md`
- **Explicit Non-Goals**:
  - No remote, release, deployment, or task-record mutation.
- **Dependencies**: None
- **Risk**: Low - deterministic local fixture.
- **Verification Condition**: Run the native validator against this fixture.
- **Mode**: `Gated Mode`
- **Batch Authorization**: N/A
- **Soft Checkpoint**: Around 60 minutes
- **Hard Checkpoint**: At or before 90 minutes
- **Event-Driven Checkpoints**: Gate decision checkpoint
- **Stop Conditions**: Developer abort or failed invariant
- **Host Timer Capability**: Host timer limitation recorded; live generation cannot be forcibly terminated.
- **Execution State**: `in_progress`
- **Mapped `pk:tasks` Status**: `In Progress`
- **Active Task Pointer**: TASK-2026-09-08-transition-table-scope
- **Start Time**: 2026-09-08 14:02 UTC
- **Current Actor**: Fixture validator
- **Next Action**: Execute the rework decided after the first gate.

### Interface Contract

| Field | Shape |
|---|---|
| `q` | optional string; trimmed |
| `tag` | one or more tag IDs, repeated |
| `application_links` | `id`, `user_id`, `application_id`, `label`, `url`, `created_at` |
| `health` | 13 -> `GET /health` with no session |

### Transition History

| Previous State | New State | Timestamp | Actor | Reason | Supporting Evidence |
|---|---|---|---|---|---|
| N/A | planned | 2026-09-08 14:00 UTC | Fixture validator | Record created | Task Record |
| `planned` | `ready` | 2026-09-08 14:01 UTC | Fixture validator | Readiness fields complete | AC-1 |
| `ready` | `in_progress` | 2026-09-08 14:02 UTC | Fixture validator | First gate executing | AC-1 |
| `in_progress` | `awaiting_review` | 2026-09-08 14:03 UTC | Fixture validator | First gate submitted | AC-1 |
| `awaiting_review` | `planned` | 2026-09-08 14:04 UTC | Fixture validator | Rework decided after first gate | AC-1 |
| `planned` | `in_progress` | 2026-09-08 14:05 UTC | Fixture validator | Rework executing | AC-1 |

## 6. Evidence and Completion Gate

- **Changed Files**:
  - `fixture/transition-table-scope.md` - Synthetic fixture input.
- **Scope Change Records**: None
- **Checkpoint Records**: None
- **Handoff Records**: None
- **Verification Evidence**: Transition scoping fields are concrete.
- **CI Evidence**: Local synthetic case.
- **Review Evidence**: N/A
- **Commit Evidence**: N/A
- **Pull Request Evidence**: N/A
- **Release Evidence**: N/A
- **Blocker and Resume Condition**: None
- **Completion State**: Pending
- **Acceptance Results**: AC-1 Pass - scoped transition history is accepted.
- **Changed-File Summary**: Synthetic transition scoping task.
- **Completion Exception**: None
- **Completion Decision and Timestamp**: Pending
- **Branch / Revision**: fixture-matrix @ REV-CASE-001
