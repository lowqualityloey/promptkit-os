# Task Record: UX Structured 1-by-1 Grills and Standardized Framed Callout Boxes

<a id="TASK-2026-10-02-ux-framed-cards-and-grill-probes"></a>

## 1. Identity and Authority

- **Record Type**: `Task Record`
- **Task ID**: `TASK-2026-10-02-ux-framed-cards-and-grill-probes`
- **PromptKit Adaptation Profile**: `none`
- **Work Type**: `Controlled Work`
- **Specification**: `Resolve Issue #502 by standardizing Mode 2 / Framed Mode ceiling-and-floor callout boxes (╔═ ... ╚═) as default across interactive hosts, mandating explicit '👉 Reply: Type ...' action hints on all human callout blocks, and refactoring pk:grill and pk:plan pre-implementation grilling into a 1-by-1 decision tree with structured options, Option 1 (Recommended), and native selection tool support.`
- **External Reference (Optional)**: `Issue #502 (https://github.com/lowqualityloey/promptkit-os/issues/502)`
- **Owner / Actor**: `PromptKit maintainer (approver) + Antigravity (executor)`
- **Execution Scope**: `promptkit-os repository; protocols/telemetry-cards.md, protocols/code-quality-gate.md, workflows/tutor.md, workflows/plan.md, workflows/tasks.md, workflows/onboard.md, workflows/test.md, workflows/fix.md, templates/project-profile-template.md, docs/tasks/, CHANGELOG.md`
- **Approval Boundary**: `User confirmed task. Branch push and PR creation authorized upon complete verification. Merge remains human-only.`
- **Created**: `2026-10-02`

> This Local Task Source is authoritative for this Controlled Work.

## 2. Objective and Boundaries

- **Objective**: `Eliminate friction and cognitive fatigue in interactive agent sessions: (1) Ban dumping 3-5 open-ended systems engineering questions in a single conversational turn ('Reply with 1: ... 2: ... or skip'). (2) Transform pre-implementation grilling into a 1-by-1 decision probe sequence with structured multiple choices, trade-off rationale, Option 1 marked '(Recommended)', and native interactive selection tools (ask_question) or single-keystroke numeric replies. (3) Standardize high-contrast framed ceiling-and-floor boxes ('╔═ ... ╚═') without fragile side-walls as the default callout visual across interactive CLI/IDE hosts, configurable via 'card-style: framed | markdown | off'. (4) Mandate explicit reply action hints ('👉 Reply: Type ...' or '👉 Action: Press Enter...') on every human callout block (NEXT STEPS, ACTION REQUIRED, BLOCKED, GRILL PROBE).`
- **In Scope**:
  - `protocols/telemetry-cards.md` (framed box format, reply hint contract, GRILL PROBE card spec, card-style configuration)
  - `protocols/code-quality-gate.md` (Decision Card reply hint and recommendation contract)
  - `workflows/tutor.md` (1-by-1 pacing invariant, anti-quiz rule, structured option formatting, ask_question wiring)
  - `workflows/plan.md` (Step 6 pre-implementation grill probe execution aligning with 1-by-1 structured options)
  - `workflows/tasks.md` (completion callout reply hint contract)
  - `workflows/onboard.md` (picker fallback reply hints)
  - `workflows/test.md` (telemetry card and TIP reply hints)
  - `workflows/fix.md` (telemetry card and TIP reply hints)
  - `templates/project-profile-template.md` (card-style configuration documentation)
  - `docs/tasks/TASK-2026-10-02-ux-framed-cards-and-grill-probes.md` (this task record)
  - `CHANGELOG.md` (record entry under [Unreleased])
- **Explicit Non-Goals**:
  - `No changes to package installer scripts (init.sh / init.ps1) logic or runner scripts.`
  - `No changes to ceremony classification levels (Level 0-3).`
  - `No automated merge or tagging actions (human retains merge authority).`
- **Dependencies**: `Issue #502 discussion and user UX feedback on pk:grill batch questions and callout visual readability.`
- **Risk**: `Low — purely additive UX enhancement for terminal/chat presentation and probe pacing, preserving all existing behavioral invariants and contract string pins.`
- **Verification Condition**: `Behavioral contract tests pass; reference validation passes; token budget measurement passes; staged secret scan passes; changelog check passes.`

## 3. Public PromptKit Contract Impact

- **Affected Public PromptKit Contract**: `Telemetry cards protocol, Quality Gate protocol, Plan/Tutor grilling contracts, Tasks/Onboard/Test/Fix human callout guidance, Project Profile template.`
- **Contract Impact Evidence ID / Path**: `EVIDENCE-2026-10-02-ux-framed-cards-and-grill-probes; protocols/telemetry-cards.md, workflows/tutor.md, workflows/plan.md.`
- **Supporting Planning / Review Record**: `Issue #502; docs/tasks/TASK-2026-10-02-ux-framed-cards-and-grill-probes.md.`
- **User-Observable Before Behavior**: `Grilling dumped 3-5 open-ended questions in one turn requiring essay responses or skipping; callouts varied across blockquotes and boxes without explicit instructions on what exact keystrokes or phrases to reply with.`
- **User-Observable After Behavior**: `Grilling proceeds 1 probe per turn with 2-4 concrete trade-off options and Option 1 marked (Recommended); all human callout blocks feature framed ceiling-and-floor boxes with clear '👉 Reply: Type ...' hints.`
- **Impact Classification**: `Workflow & Protocol Contract Enhancement`
- **Proposed SemVer Candidate Impact**: `minor`
- **Impact Rationale**: `Significantly improves interactive UX and human callout ergonomics without breaking backward compatibility.`
- **Migration and Upgrade Guidance**: `N/A - framed cards and 1-by-1 grill probes are fully backward-compatible. Users can opt out or choose markdown via 'card-style: markdown' in PROMPTKIT.md.`
- **Maintenance Commit Declaration**: `N/A`

## 4. Acceptance Criteria

- [x] **AC-1**: `protocols/telemetry-cards.md standardizes Mode 2 / Framed Mode ceiling-and-floor boxes (╔═ ... ╚═) as default across terminal/chat hosts, defines the GRILL PROBE card spec, mandates explicit '👉 Reply: Type ...' hints, and documents 'card-style: framed | markdown | off'.`
- [x] **AC-2**: `workflows/tutor.md enforces the 1-by-1 Pacing & Option Structuring (Anti-Quiz Invariant), bans batch essay question dumps, requires Option 1 (Recommended) with trade-off rationale, and integrates native interactive tools (ask_question) with single-number fallback.`
- [x] **AC-3**: `workflows/plan.md Step 6 aligns pre-implementation grilling with the 1-by-1 probe sequence, structured options, and mandatory reply hint contract.`
- [x] **AC-4**: `protocols/code-quality-gate.md Decision Cards include explicit reply hint requirements and mandatory recommendations.`
- [x] **AC-5**: `workflows/tasks.md, workflows/onboard.md, workflows/test.md, and workflows/fix.md mandate explicit reply hints on human callouts.`
- [x] **AC-6**: `templates/project-profile-template.md documents 'card-style: framed' (default) | markdown | off.`
- [x] **AC-7**: `All contract test string pins remain satisfied and automated verification test suites pass cleanly.`

## 5. Verification Commands and Evidence

- `bash scripts/tests/run-behavioral-contract-tests.sh`
- `bash scripts/validate-references.sh .`
- `bash scripts/measure-tokens.sh --strict`
- `bash scripts/scan-staged-secrets.sh`
- `bash scripts/check-changelog-entry.sh`

## 6. Invariants and Non-Negotiable Rules

- `The Single-Callout Invariant`: At most one human callout block per turn.
- `Anti-Quiz Invariant`: Never dump multiple open-ended probes in a single turn. Present probes 1-by-1 with structured options.
- `Recommendation Invariant`: Option 1 must always be marked `(Recommended)` with a 1-sentence rationale.
- `Mandatory Reply Hint Invariant`: Every human callout must end with an explicit action hint (`👉 Reply: Type '...'` or `👉 Action: Press Enter...`).
- `Human Merge Authority`: Pull requests are merged by the human maintainer; the agent never merges.

## 7. Revision Context and Blocker History

- `2026-10-02`: Created task record following user feedback during SnippetVault project review and Issue #502 creation.

## 8. Prioritized Next Actions and Ceremony State

- `Phase`: Implementation and Verification.
- `Next Action`: Record entry in CHANGELOG.md, execute verification test suites, stage changes, commit with Conventional Commit, push branch, and open PR.

## 9. TDD Enforcement Mode

- **Mode**: `disabled`
- **Rationale**: Workflow markdown documentation and protocol contracts; verified via bash/powershell contract suites and reference validation scripts.

## 10. Scope Change Records

- `N/A - Initial scope unchanged.`
