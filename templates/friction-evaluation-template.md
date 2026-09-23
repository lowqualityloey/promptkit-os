# Adaptation Friction Evaluation: [Evaluation ID]

> Use this optional, network-free record to compare PromptKit process cost with avoided rework. It is a measurement record, not an execution authority. Do not invent empirical results: use `Not measured` when no representative session data exists, and use `N/A` only when a metric does not apply.

## 1. Evaluation Metadata

- **Evaluation ID [Required]**: `FRICTION-<evaluation-slug>`
- **Evaluation Status [Required]**: `draft | complete | deferred`
- **Owner [Required]**: `PromptKit maintainer` or named maintainer
- **Evaluation Mode [Required]**: `static contract review | empirical sample | mixed`
- **Baseline [Required]**: [Current workflow or prior process used for comparison]
- **Adaptation Revision [Required]**: [Task range, commit, or specification revision]
- **Evaluation Date [Required]**: `[YYYY-MM-DD]`
- **Scenario Set [Required]**: `L0 | Minimal L1-L3 | Full L1-L3 | TDD-enabled | CI failure`; record `N/A` only with a reason.
- **External Actions [Not applicable]**: `None - this record measures process only`

## 2. Measurement Rules

Compare the baseline process with the Adaptation overlay. Count required questions and artifacts, not optional guidance or metadata. A conditional control counts only when its trigger is present.

- **L0 Work rule**: Required Adaptation questions and artifacts must remain `0`.
- **Minimal Planning rule**: Required planning inputs must be no more than `3`: requested outcome, observable completion condition, and scope boundary. Existing L1-L3 Work readiness remains separate.
- **Conditional-control rule**: TDD evidence activates only when TDD Enforcement Mode is enabled; CI triage activates only for a CI failure; Full Planning activates only for its documented triggers.
- **Duplication rule**: Record evidence once in its canonical authority and link to it from supporting views.
- **Token rule**: Do not impose a universal token budget. Record relative context overhead as `None`, `Low`, `Medium`, `High`, or `Not measured` with a reason.

## 3. Scenario Results

| Scenario [Required] | Trigger and baseline | Added required questions | Added required artifacts | Assumptions surfaced before implementation | Rework avoided | Classification quality | False positives | Process bypasses | Relative context overhead | Evidence / notes |
|---|---|---:|---:|---|---|---|---:|---:|---|---|
| L0 Work | [Existing fast path] | [0] | [0] | [Not measured / result] | [Not measured / result] | [Pass / result] | [0 / result] | [0 / result] | [None / result] | [Evidence] |
| Minimal L1-L3 Work | [Three-input planning path] | [0-3] | [Record sections, not duplicate workflow] | [Result] | [Result] | [Pass / result] | [Result] | [Result] | [Result] | [Evidence] |
| Full L1-L3 Work | [Full trigger and existing RFC path] | [Result] | [Result] | [Result] | [Result] | [Pass / result] | [Result] | [Result] | [Result] | [Evidence] |
| TDD-enabled Code Work | [Task Record mode enabled] | [Result] | [Intent and execution evidence] | [Result] | [Result] | [Pass / result] | [Result] | [Result] | [Result] | [Evidence] |
| CI failure | [CI failure reported] | [Result] | [CI Triage Record and conditional action blocks] | [Result] | [Result] | [Pass / result] | [Result] | [Result] | [Result] | [Evidence] |

## 4. Evaluation Summary

- **Added Required Questions [Required]**: [Scenario-level comparison]
- **Added Required Artifacts [Required]**: [Scenario-level comparison]
- **Assumptions Found Before Implementation [Required]**: `[count, evidence, or Not measured with reason]`
- **Rework Avoided [Required]**: `[description and evidence, or Not measured with reason]`
- **Classification Quality [Required]**: `[Pass / result and evidence]`
- **False Positives [Required]**: `[count and evidence, or Not measured with reason]`
- **Process Bypasses [Required]**: `[count and evidence, or Not measured with reason]`
- **Relative Context Overhead [Required]**: `[None | Low | Medium | High | Not measured]` with reason

## 5. Excessive-Friction Decision

Treat friction as excessive when any of these conditions is observed:

- L0 Work receives a required Adaptation question or artifact.
- Minimal Planning exceeds three required planning inputs.
- A conditional control activates without its trigger.
- The same evidence is required in more than one authoritative location.
- The process causes a documented bypass, false positive, or avoidable rework increase.

- **Evaluation Result [Required]**: `Pass | Friction identified | Inconclusive | Deferred`
- **Findings [Required]**: [Concise findings with scenario and evidence references]
- **Decision [Required]**: `[Keep overlay | Simplify overlay | Run empirical sample | Defer]`
- **Follow-up Owner [Optional]**: `[PromptKit maintainer or N/A]`
- **Follow-up Condition [Optional]**: `[When another sample or revision is needed, or N/A]`

> A completed static review may conclude `Pass` for contract-level friction while leaving empirical rework, false-positive, or token measurements as `Not measured`. That limitation must remain visible and does not authorize workflow, release, deployment, rollback, or other external action.
