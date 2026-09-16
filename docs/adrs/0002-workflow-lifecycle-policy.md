# ADR 0002: Workflow Lifecycle Policy (Addition, Retirement, Alias Sunset)

- **Status**: Accepted
- **Date**: 2026-09-16
- **Context**: The project ships 24 workflows and 28 templates. The on-disk workflow count is mechanically guarded (`run-behavioral-contract-tests.sh/.ps1` fail on divergence), but nothing governs retirement — growth is one-directional. Every addition raises documentation, testing, and coherence costs. Related issue: #198. This ADR originally locked the count at 23; issue #238 admitted the 24th workflow (`workflows/auto.md`) under the gate below.

## Decision

### 1. Adding a workflow (the 24th-workflow gate)

A new-workflow proposal must state, in the PR body:

- **Non-overlap**: which existing workflows were considered and why none covers the need (name them).
- **Ceremony fit**: the Level 0–3 classification and why the work cannot live as a section inside an existing workflow.
- **Artifacts shipped in the same PR**: workflow file, `setup.md` reference row, directive trigger entry (or a recorded reason for omission, cf. ADR 0001), WORKFLOW-MAP rows, README/FAQ count updates, and new or extended behavioral-contract assertions in **both** `.sh` and `.ps1` twins.
- **Token cost**: `measure-tokens.sh --strict` and `measure-per-task-tokens.sh --strict` results; any budget-constant change needs its own written justification.

A proposal missing any of these is incomplete, not controversial — request changes, don't debate taste.

#### Worked Example: Issue #238 `pk:auto` (The 24th Workflow)
Issue #238 introduced `workflows/auto.md` under this exact gate:
- **Non-overlap**: Existing workflows (`pk:plan`, `pk:debug`, `pk:test`, `pk:review`, `pk:commit`) are single-domain lifecycle procedures. None can chain end-to-end SDLC phases without violating single responsibility. `pk:auto` is strictly the unattended meta-orchestrator coordinating handoffs across them.
- **Ceremony fit**: Adaptive Level 1–2 ceremony chaining with strict circuit breakers, test immobility, and default stop at `review ready`.
- **Shipped artifacts**: `workflows/auto.md`, updated `workflows/route.md`, directive trigger and auto-route entries, `WORKFLOW-MAP.md` rows, README/FAQ counts, and behavioral test assertions in both `.sh` and `.ps1` twins.

### 2. Retiring a workflow

Retirement is a breaking contract change and follows the breaking-change path:

- **Justification**: usage evidence or supersession (which workflow absorbs the surface), not preference.
- **Required artifacts, all in the same PR**:
  1. This policy's update if the rules themselves change (new ADR superseding this one).
  2. `CHANGELOG.md` entry with a `BREAKING CHANGE` notice and explicit migration path (old trigger → new trigger or procedure).
  3. Workflow-count guard update in **both** test twins (expected count + stale-claim patterns), so the suite is green at merge — a retirement never lands red.
  4. Directive trigger-to-file exception-list sync (`templates/agent-directive-template.md`, currently the exceptions line) — remove or repoint the entry.
  5. `protocols/setup.md` reference removal, plus README, WORKFLOW-MAP, FAQ, and QUICKSTART updates wherever the retired trigger was listed; `validate-references.sh` must pass.
- **One release, one retirement**: batch retirements only when they share a single migration story; otherwise one per release so each `BREAKING CHANGE` entry stays readable.

### 3. Alias retirement

Aliases are cheap to create and expensive to remove, so they get their own rule: an alias may be repointed (kept working, new meaning documented) or retired (removed). Repointing needs a CHANGELOG entry; removal needs the full §2 path including the `BREAKING CHANGE` notice, because consumers invoke aliases directly. The directive exception list is the registry of record for which trigger spellings exist.

## Worked Example (descriptive precedent): v1.7.0 `pk:profile` retirement

v1.7.0 did this correctly ad hoc: `pk:profile` was retired as a `pk:perf` alias and repurposed as the runtime profile switcher, with a documented `BREAKING CHANGE` notice and migration path (`Use pk:perf or pk:latency for profiling`) in `CHANGELOG.md`. Under this policy that change classifies as an alias repointing (§3, first path): CHANGELOG entry required, full §2 artifact sweep not required since no trigger spelling was removed. Had the spelling been removed outright, §2 items 2–5 would have applied.

## Consequences

- The drift guard keeps detecting deletion; this policy adds the human gate the guard cannot express (semantic justification, migration story).
- Future retirements update the guard constants rather than fighting them; the twins stay in parity.
- Lite-as-flagship (#199) and README restructuring (#197) are unaffected — this policy governs process, not those outcomes.
