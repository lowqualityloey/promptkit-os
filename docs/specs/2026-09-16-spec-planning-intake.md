---
status: Shipped
---

# Technical Design Document (RFC): Bounded Project Intake & Anti-Overengineering Gate

- **Author**: PromptKit OS maintainer
- **Status**: Shipped — delivered via PRs #186, #187, #188 with pilot evidence in `docs/internal/pilots/`; post-merge doc audit applied 2026-09-16.
- **Created**: 2026-09-16
- **Delivery**: Phases 1-3 via GitHub issues #178-#185

---

## Planning Record (PromptKit Adaptation)

<a id="PLAN-planning-intake"></a>

### Planning Record Metadata

- **Planning Record ID [Required]**: `PLAN-planning-intake`
- **Planning Depth [Required]**: `Full` (affects documented public contracts: workflows, protocol, template, output contract)
- **Owner [Required]**: Maintainer / human Release Coordinator
- **Record Status [Required]**: `shipped`
- **Workflow Links [Optional]**: `pk:onboard`, `pk:plan`, `pk:sync`, `pk:checkpoint`, `pk:route`

### Planning Inputs

- **Requested Outcome [Required]**: Greenfield and brownfield projects receive a bounded, low-technical intake that captures MVP intent, surfaces, deployment target, existing artifacts, and design inputs; AI-proposed complexity stops entering scope by default.
- **Observable Completion Condition [Required]**: Issues #178-#185 closed with the intake path documented, the picker routing rule shipped, and `measure-tokens.sh --strict`, `measure-per-task-tokens.sh --strict`, `measure-turbo-overhead.sh --strict`, `validate-references.sh`, `run-behavioral-contract-tests.sh`, and `validate-execution-control.sh --root . --strict` all green.
- **Scope Boundary [Required]**: `protocols/discovery-intake.md` (new), `workflows/{onboard,plan,sync,checkpoint,route}.md`, `templates/project-profile-template.md`, `protocols/{context-sync,setup}.md`, `docs/{BENCHMARKS,WORKFLOW-MAP,token-efficiency-review}.md`, `README.md`, `QUICKSTART.md`, `FAQ.md`, `CHANGELOG.md`, `scripts/tests/run-behavioral-contract-tests.{sh,ps1}`. Excludes: new triggers, directive or installer edits, new docs directories, host enforcement.
- **TDD Enforcement Proposal (Reference Only) [Optional]**: `disabled`; Documentation/Configuration Work exception path.

### Full Planning

- **Explicit Non-Goals**: No new routing trigger; no edits to `templates/agent-directive-template.md` (2,496 of a 2,500 token gate) or the Lite directive; no `init.sh` / `init.ps1` changes; no new `docs/` directory; no change to Levels 0-3 authority, Task Record authority, or Mandatory Full Planning Triggers; no removal of pickers for bounded decisions; no mechanical host enforcement.
- **Affected Behavioral Components**: Greenfield intake; onboarding phases and scorecard; planning Step 0 preflight; interactive-decision guidance; anti-overengineering gate; mid-implementation delta handling; published token claims.
- **Externally Visible Contracts**: `workflows/onboard.md` phase contract and title; `workflows/plan.md` step order and picker guidance; `templates/project-profile-template.md` machine lines (`size:`, `Intake Status:`); Intake Record shape. Existing `profile:` and `tracking:` lines, and `> [!TYPE]` callout standards, are unchanged.
- **Failure or Rollback Considerations**: Over-ceremony -> activation predicate, hard question caps, and an always-available human stop; legacy install re-interview -> a missing `Intake Status:` is treated as `legacy-partial`; CI collateral -> the turbo human-approval phrase in `onboard.md` and the literal `Interactive Decision & Trade-Off Clarification` string in `plan.md` are preserved; documentation drift -> live measurements are quoted, never estimated. Rollback is `git revert` of the affected phase PR.
- **Verification Approach**: `measure-tokens.sh --strict`, `measure-per-task-tokens.sh --strict`, `measure-turbo-overhead.sh --strict`, `validate-references.sh`, `run-behavioral-contract-tests.sh` plus its PowerShell twin, `validate-execution-control.sh --root . --strict`, and a static dry-run of the small and medium intake paths.

### Assumption Records

<a id="ASSUMPTION-planning-intake-001"></a>
- **Assumption ID [Required]**: `ASSUMPTION-planning-intake-001`
- **Unanswered Decision [Required]**: Does bounded intake reduce rework enough to justify its upfront cost?
- **Provisional Answer [Required]**: Yes for medium and large projects; neutral to negative for small ones.
- **Impact if Wrong [Required]**: Added ceremony without a rework saving; small projects become slower.
- **Validation Action [Required]**: Record tokens per intake path and question counts in a static dry-run after Phase 2, before Phase 3 starts.
- **Decision Owner [Required]**: PromptKit maintainer
- **Status [Required]**: `open`

<a id="ASSUMPTION-planning-intake-002"></a>
- **Assumption ID [Required]**: `ASSUMPTION-planning-intake-002`
- **Unanswered Decision [Required]**: Can every supported host carry intake questions in the context window together with attachments?
- **Provisional Answer [Required]**: Yes; attachment reading is a host capability, and the protocol requires a text fallback whenever an attachment cannot be read.
- **Impact if Wrong [Required]**: Design-input capture degrades to text-only.
- **Validation Action [Required]**: Confirm in at least one CLI host and one IDE host during the post-Phase-2 dry-run, recording `not measured` where a host cannot be observed.
- **Decision Owner [Required]**: PromptKit maintainer
- **Status [Required]**: `open`

<a id="ASSUMPTION-planning-intake-003"></a>
- **Assumption ID [Required]**: `ASSUMPTION-planning-intake-003`
- **Unanswered Decision [Required]**: Are existing consumer profile files without `Intake Status:` treated as incomplete?
- **Provisional Answer [Required]**: No - a missing field is `legacy-partial` and never triggers a full re-interview.
- **Impact if Wrong [Required]**: Existing users are re-interviewed, which is the primary adoption risk.
- **Validation Action [Required]**: Phase 1 template rules plus `pk:sync` backfill wording, verified in the post-Phase-2 dry-run.
- **Decision Owner [Required]**: PromptKit maintainer
- **Status [Required]**: `open`

### Technology and Vendor Decision Records

None. No material technology or vendor adoption; every change is a Markdown protocol, workflow, template, or documentation edit inside the existing structure.

---

## 1. Executive Summary & Problem Statement

PromptKit documents greenfield planning as the `pk:plan` path, but `pk:plan` begins at the problem statement and moves directly into architecture, while `pk:onboard` is brownfield-only and refuses a repository without existing code. A fresh project therefore has no discovery step: the profile template ships `[e.g. ...]` placeholders, and the agent fills the gaps with its own recommendations.

Three defects produce the wrong-build loop reported by users:

1. **No bounded intake.** Nothing asks what the smallest useful version is, where it will run, or what stack constraints exist.
2. **Consent manufacturing.** The interactive-decision guidance mandates a native modal picker with `(Recommended)` prefixed to Option 1. A modal cannot carry an attachment, and a recommended first option makes the agent's preference the path of least resistance.
3. **No complexity ceiling.** Nothing requires a proposed service, queue, cache, or abstraction to trace back to a requirement the human actually stated.

This RFC adds a bounded intake ahead of planning, routes attachment-bearing questions to the context window, and introduces an MVP floor with a Later ledger so agent-proposed complexity cannot enter scope by default. Planning depth for risky work is unchanged.

## 2. Goals and Explicit Non-Goals

### Goals (In Scope)

- A size class (`small` / `medium` / `large`) that bounds the number of questions and rounds.
- A seven-slot coverage checklist so intake is a checklist, not open-ended interrogation.
- An explicit stop contract: the human may always end intake, and the reason is recorded.
- A picker routing rule that keeps modals for bounded decisions and moves free-text or attachment answers to the context window.
- An MVP floor, requirement trace, complexity budget, and Later ledger.
- A recorded path for information supplied mid-implementation.

### Non-Goals (Out of Scope)

- No new trigger, no directive or installer edits, no new documentation directory.
- No change to Levels 0-3 ceremony, Task Record authority, or Mandatory Full Planning Triggers.
- No mechanical enforcement claim: this remains an instruction-layer change.

## 3. System Context & Module Boundaries

```text
[ Greenfield repo ]              [ Brownfield repo ]
        │                                │
        └──────────► pk:onboard ◄────────┘
                         │
              Phase 0: Project Intake (protocols/discovery-intake.md)
                         │  Intake Record + size: + Intake Status:
                         ▼
                     pk:plan (Step 0 preflight -> Steps 1-6 unchanged)
                         │
                         ▼
                     pk:tasks -> Task Record -> implementation
                         │
        mid-build delta ─┴─► pk:sync / pk:checkpoint interception
```

| Module | Interface | Hidden Complexity |
| :--- | :--- | :--- |
| `protocols/discovery-intake.md` | Size class, seven slots, question loop, picker rule, MVP gate, delta table | Budget arithmetic, stop conditions, legacy compatibility |
| `workflows/onboard.md` Phase 0 | Activates only when no manifest or source exists | Staying passive/read-only; not re-interviewing brownfield users |
| `workflows/plan.md` Step 0 | Reads intake state; complete -> proceed, incomplete -> bounded intake | Preserving Levels 0-3 authority and the existing picker string |
| `templates/project-profile-template.md` | `size:`, `Intake Status:` machine lines | Legacy default without re-interviewing |
| `pk:sync` / `pk:checkpoint` | Delta interception rule | Not creating scope-change ceremony for docs-only deltas |

## 4. Detailed Design & Contracts First

### 4.1 Size Class and Question Budget

| Size | Signal | Rounds | Max questions | Extra artifacts |
| :--- | :--- | :--- | :--- | :--- |
| `small` | One surface, solo, short-lived tool or MVP | 1 | 5 | Intake Record only |
| `medium` | Two to three surfaces (for example web plus API) | 2 | 8 | `DESIGN.md` when a UI surface exists |
| `large` | Three or more surfaces, or auth plus data plus deployment | 3 | 12 | Architecture spec plus Decision Records |

The human states the size; the agent may only suggest it and must label a suggestion as a suggestion. The value persists as the `size:` machine line in the project profile, mirroring the existing `profile:` and `tracking:` pattern, so a later session never re-asks.

### 4.2 Coverage Slots

Intake walks seven slots in order, at most five questions per turn, in plain language:

1. Outcome and MVP floor - the smallest version that is genuinely useful.
2. Users and success signal - who benefits, and how success is observed.
3. Surfaces in scope - UI, API, database, background work, and similar.
4. Deployment target - local only, managed platform, virtual server, or cloud.
5. Existing artifacts - architecture, style guide, design system, specification, or tracker board links that already exist.
6. Design inputs (only when a UI surface is in scope) - design-tool link, screenshots, token export, or an explicit decision to use agent defaults.
7. Constraints - required stack, deadline, budget, or compliance limits.

### 4.3 Question Protocol and Stop Contract

- **Round shape**: three to five questions per turn. Each accepted answer is acknowledged in one line. An unanswered slot receives a proposed default recorded as an owned assumption, never a silent gap.
- **Loop**: every round closes with a single open-ended invitation in the context window - anything to add, including links, screenshots, or files, or the human may end intake.
- **Stop conditions (any one)**: all seven slots covered; the human ends intake; a full round yields no new information; the question budget is reached.
- **Close**: the Intake Record records `close_reason: complete | human_stopped | no_new_info | budget_reached` plus the explicit still-unknown list, so "agreed for now" becomes an auditable fact rather than ambiguity.
- **Attachments**: when the host cannot read an attachment, say so and ask for text or a quoted excerpt; never guess its content. When it can be read, restate in one line what was extracted before relying on it.
- **No re-interrogation**: a slot already answered is never re-asked unless scope changes or new evidence invalidates the answer, consistent with the existing question-retention rule in `workflows/plan.md`.

### 4.4 Interactive Picker Routing Rule

> A native modal picker is used **only** when all three hold: the option set is closed and has at most four entries; the answer needs no attachment and no free text; and the agent has evidence-based grounds, or the picker itself offers an explicit no-recommendation option.
> Otherwise the question is asked in the context window.
> An agent preference is never placed as Option 1 for an intent question (MVP scope, whether to include auth, tenancy model, or similar). Intent belongs to the human; the agent asks and records it.

Bounded decisions that remain picker-eligible: profile selection, tracker selection, ceremony level, planning depth, and equivalent closed-set operational choices.

### 4.5 MVP Floor and Anti-Overengineering Gate

1. **MVP floor first**: architecture may only be proposed after slot 1 is answered in the human's own words.
2. **Requirement trace**: every proposed service, queue, cache, table, or abstraction must cite a requirement the human stated. A component that fails the trace moves to the Later ledger instead of into scope.
3. **Boring default plus upgrade path**: prefer the option with the fewest moving parts and state what would be added if the project grows.
4. **Complexity budget**: declare the moving-part count (services, tables, external dependencies) and require explicit human approval to exceed the MVP floor.
5. **Defaults disclosure**: emit a short "Decisions I am defaulting for you" list that the human accepts or changes before architecture is written, converting silent assumptions into a reviewable diff.
6. **No unrequested scope**: an agent-proposed feature is a suggestion recorded in the Later ledger with a one-line cost; it never enters milestones automatically.

### 4.6 Mid-Implementation Delta Path

| Delta type | Action | Record |
| :--- | :--- | :--- |
| Documentation or configuration only, no behavior change | Apply and continue | `docs/STATE.md` session log |
| Changes scope, acceptance criteria, or in-scope files | Scope Change Record required before continuing, then re-run the affected planning depth | Task Record update plus planning record |
| Changes architecture, data ownership, or contracts | Block execution and re-open planning at the correct depth | Planning record revision and assumption reconciliation |
| New idea not needed now | Record one line | Intake Record Later ledger |

Interception rule: when `pk:sync` or `pk:checkpoint` observes new requirements in a session that are not recorded anywhere, the delta must be classified and recorded before work continues. Task Record authority and `docs/STATE.md` projection ownership are unchanged.

### 4.7 Artifacts and Authority

- **Intake Record**: `docs/specs/YYYY-MM-DD-intake-<project>.md` - owns the interview answers: size class, seven-slot coverage, attachments and links received, defaults accepted or changed, Later ledger, `close_reason`, and open assumptions. Stored under the existing specification path so no new directory or installer change is required.
- **Authority model**: the Intake Record owns the answers; the project profile is their derived projection; the canonical Task Record remains authoritative for execution. No new authority is created and no second task database is introduced.

### 4.8 Data Models and Schema

Not applicable - documentation-only change. Two machine lines are added to the project profile using the existing parser-friendly convention:

- `size: small | medium | large`
- `Intake Status: unanswered | legacy-partial | complete`, where an absent value resolves to `legacy-partial`

### 4.9 Interfaces and Contracts

No API surface is added. Output contracts are:

- Intake Record headings: size class, seven-slot coverage table, attachments received, defaults accepted or changed, Later ledger, `close_reason`, open assumptions.
- `pk:onboard` Phase 0 activates on an empty repository and must leave no `[e.g. ...]` placeholder in the profile sections it answers.
- `pk:plan` Step 0 is a read-then-branch step: complete intake proceeds unchanged; incomplete intake runs the bounded intake or routes to `pk:onboard`.

## 5. Security, Privacy & Failure Modes (FMEA)

No new secret surface, no authentication change, and no tenancy impact. Generated artifacts continue to exclude secrets, and `.env.example` hygiene is unchanged.

| Failure | Prob/Sev | Detection | Mitigation | Recovery |
| :--- | :--- | :--- | :--- | :--- |
| Over-ceremony creep into small work | Med / High | Dry-run question counts | Activation predicate, hard caps, always-available human stop | Tighten the predicate and caps |
| Legacy install re-interviewed | High / Med | Template rules review | Missing `Intake Status:` resolves to `legacy-partial` | Restore the skip rule and re-test |
| CI guard collateral in `onboard.md` | Med / Med | `measure-turbo-overhead.sh --strict` | Preserve the turbo human-approval phrase | Restore the phrase, re-run the gate |
| Orphaned trigger token shipped | Low / High | `validate-references.sh` warnings | Never introduce an unresolvable trigger token | Replace the wording |
| Published token claims drift | High / Low-Med | `measure-tokens.sh --strict` versus docs | Quote live measurements only | Refresh the documented figures |
| Attachment content hallucinated | Low / High | Human review | Say "cannot read", request text; restate what was read | Re-ask for the excerpt |
| Half-landed multi-phase delivery | Med / Med | Phase review | Each phase is independently coherent; Phase 1 wires the entry point | Land the remaining phase |

## 6. Implementation Milestones and Issue Index

Work Type: Documentation/Configuration Work. TDD Enforcement Mode: `disabled` (reference only). The exception verification path applies and Red/Green/Refactor is not applicable.

| Milestone | Scope | Issues |
| :--- | :--- | :--- |
| **M1 - Intake Core** | Protocol, greenfield Phase 0, profile signals, contract tests, spec | [#178](https://github.com/lowqualityloey/promptkit-os/issues/178), [#179](https://github.com/lowqualityloey/promptkit-os/issues/179), [#180](https://github.com/lowqualityloey/promptkit-os/issues/180) |
| **M2 - Planning Gate** | Step 0 preflight, picker routing rule, MVP floor, token-claim refresh | [#181](https://github.com/lowqualityloey/promptkit-os/issues/181), [#182](https://github.com/lowqualityloey/promptkit-os/issues/182), [#183](https://github.com/lowqualityloey/promptkit-os/issues/183) |
| **M3 - Lateral Guards** | Mid-build delta path, sync and checkpoint interception, registry and adoption docs | [#184](https://github.com/lowqualityloey/promptkit-os/issues/184), [#185](https://github.com/lowqualityloey/promptkit-os/issues/185) |

Delivery mapping: M1 ships as the Phase 1 pull request, M2 as Phase 2, and M3 as Phase 3. Between Phase 2 and Phase 3 a static dry-run records tokens per intake path and question counts for `ASSUMPTION-planning-intake-001`.

Each milestone is independently coherent: M1 alone gives a fresh project a working intake, M1 plus M2 wires planning and the complexity ceiling, and M3 closes the mid-build and registry gaps.

## 7. Sign-off & Grilling Checklist

- [ ] Architecture challenged via `pk:grill`.
- [ ] Zero-downtime database evolution recorded as not applicable.
- [ ] Non-goals agreed (no new trigger, no directive or installer edits, no new directory).
- [ ] Levels 0-3 authority, Task Record authority, and Mandatory Full Planning Triggers unchanged.
- [ ] Ready for the exception verification path (documentation and configuration work, TDD not applicable).
- [ ] Token gates unchanged: Balanced directive at or below 2,500 and Lite at or below 1,500.