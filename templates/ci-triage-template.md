# CI (Continuous Integration) Triage Record: [Provider / Run]

> **Developer-friendly fill-in guide:** A **Required** field must be filled when its condition applies; an **Optional** field may use the stated `N/A` value; **Not applicable** means the condition does not apply, such as `N/A - not a release candidate`. Use `None` only when the record genuinely has no item of that type and the field permits it. Keep evidence concise but reproducible: name the check, job or command, exact revision, UTC time, relevant configuration, and a short failure excerpt. Example: `State: evidence_requested`, `Missing Evidence: provider run URL`, `Evidence Request Owner: CI triage owner`.
>
> **State and authority reminder:** Record evidence before classification, and classification before a bounded remediation plan. `verified` means the recorded verification passed; `linked_to_pk_ship` means that verified result has been linked to the existing release record. A CI record never retries a job, changes remote configuration, deploys, rolls back, or approves a release.
>
<!-- Replace the example anchor with the immutable CI ID, for example: <a id="CI-github-12345"></a> -->
<a id="CI-<provider>-<run-id>"></a>

- **CI ID [Required]**: `CI-<provider>-<run-id>`
- **State [Required]**: `evidence_requested | evidence_sufficient | classified | remediation_planned | awaiting_confirmation | local_reproduction_or_fix | verification_pending | verified | linked_to_pk_ship | blocked`
- **Owner [Required]**: [CI triage owner]
- **Release Candidate [Required]**: `true | false`
- **State History [Required]**: `evidence_requested > evidence_sufficient > classified > remediation_planned [> awaiting_confirmation] > local_reproduction_or_fix > verification_pending > verified` (append `> linked_to_pk_ship` for release candidates only; `blocked` may be entered from any state with an owner and resume condition)
- **Blocker [Required when blocked or previously blocked]**: `N/A - not blocked`
- **Resume Target [Required when blocked or previously blocked]**: `N/A - not blocked`
- **Resume Condition [Required]**: [Precise condition and accountable owner for the next state]

## CI Evidence

- **CI Evidence [Required]**: [Short evidence-bundle summary]
- **Check Identity [Required when evidence is sufficient]**: [Provider check name or ID]
- **Failed Job or Command [Required when evidence is sufficient]**: [Job and command]
- **Failure Output [Required when evidence is sufficient]**: [Relevant output excerpt or linked captured output]
- **Revision Identifier [Required when evidence is sufficient]**: [Exact revision]
- **Execution Time [Required when evidence is sufficient]**: [UTC timestamp]
- **Configuration Context [Required when evidence is sufficient]**: [Relevant configuration or environment context]
- **Missing Evidence [Required when state is evidence_requested]**: [Missing item]
- **Evidence Request Owner [Required when state is evidence_requested]**: [Person or team]

## Classification

- **Classification [Required when state is classified or later]**: `test | static analysis | build | dependency or environment | infrastructure or transient | deployment | unknown`

## Remediation Plan

- **Remediation Plan [Required when state is remediation_planned or later]**: [Bounded plan summary]
- **Remediation Classification [Required when a plan exists]**: [Classification]
- **Suspected Cause [Required when a plan exists]**: [Evidence-based suspected cause]
- **Affected Scope [Required when a plan exists]**: [Bounded files, jobs, configuration, or environment]
- **Minimal Change [Required when a plan exists]**: [Smallest proposed change]
- **Verification Command [Required when a plan exists]**: [Exact command or recorded verification procedure]
- **Rollback or Reversal Action [Required when a plan exists]**: [Bounded reversal action]
- **Declined Action Outcome [Required after an action is declined]**: `N/A - no action declined`

## Action Confirmation

- **Remote Action Blocks [Required]**: `N/A - no remote action proposed` or [number of independent action blocks]
- **Current Action Epoch [Required when action blocks exist]**: `N/A - no remote action proposed` or [positive confirmation epoch]

### ACTION-<ci-id>-001

- **Action ID [Required]**: `ACTION-<ci-id>-001`
- **Action Epoch [Required]**: [positive confirmation epoch]
- **Action Lifecycle [Required]**: `open | closed`
- **Proposed Action [Required]**: [One remote retry, repository configuration change, deployment, or rollback]
- **Confirmation State [Required]**: `pending | confirmed | declined`
- **Approver [Required]**: `N/A - awaiting confirmation` while pending; otherwise [human approver]
- **Confirmation Timestamp [Required]**: `N/A - awaiting confirmation` while pending; otherwise [UTC timestamp]
- **Bounded Scope [Required]**: [Exact action boundary]
- **Reversal or Rollback Action [Required]**: [How to reverse this action]
- **Resume Condition [Required]**: [Condition after this action decision]

## Cross-Record Links

- **pk:debug Link [Optional]**: `[stable-id](<relative-path>#<stable-id>)` or `N/A - no local reproduction needed`
- **pk:ship Release Link [Required when state is linked_to_pk_ship]**: `[RELEASE-<release-slug>](../<release>.md#RELEASE-<release-slug>)` or `N/A - not a release candidate`
- **Verification Evidence [Required when state is verified or linked_to_pk_ship]**: `Pass - [recorded verification result]`

> CI triage records evidence and bounded plans only. They do not retry jobs, mutate remote configuration, deploy, roll back, approve releases, or execute any external action. A confirmation records a human decision for one bounded action; it does not execute that action or authorize another action.

> A declined action remains in the record as a closed audit entry. A later remediation plan must use a new Action Epoch and a new independent action block; current-epoch decisions alone determine whether the parent can continue. The epoch and lifecycle fields do not execute or authorize any external action.

> For a release candidate, `pk:ship` may resume only after the CI record reaches `verified` and the existing release record reaches `linked_to_pk_ship` with the CI Triage Link, Verification Link, Verified Result, and Resume Condition. The state-transition and declined-action rules are deterministic and network-free; no remote provider access is required.
