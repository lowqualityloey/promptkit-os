# Task Record: TASK-2026-09-18-dual-mode-telemetry

## Metadata
- **Task ID**: TASK-2026-09-18-dual-mode-telemetry
- **GitHub Issue**: [#316](https://github.com/lowqualityloey/promptkit-os/issues/316)
- **Branch**: `feat/dual-mode-telemetry-formatting`
- **Ceremony Level**: Level 2 (Controlled)
- **Status**: in_progress
- **Created**: 2026-09-18
- **Owner**: Antigravity agent + human maintainer approval

## Requested Outcome
Standardize visual output across both Markdown-capable environments (Cursor, VS Code, Antigravity) and non-markdown CLI terminals (Cline, OpenCode, Aider), enforcing the Single-Callout Invariant and universal anti-glitch progress bars.

## Scope Boundary
**In scope**:
- `protocols/telemetry-cards.md` (Markdown and CLI specifications, Single-Callout Invariant, square progress bar rule, link format)
- `templates/agent-directive-template.md` & `agent-directive-lite-template.md` (Single-callout and progress bar constraints)
- `workflows/checkpoint.md` (Milestone completion and handover templates updated)
- `scripts/tests/run-behavioral-contract-tests.sh` & `.ps1` (Automated behavioral assertions)

**Out of scope**:
- Functional changes to prompt routing, ceremony levels, or state trackers.

## Acceptance Criteria
- **AC-1**: `protocols/telemetry-cards.md` codifies the Single-Callout Invariant (max 1 callout per turn; priority IMPORTANT > WARNING > TIP).
- **AC-2**: Progress bars in both Markdown and CLI modes use the anti-glitch square standard `[■■■■■■■■□□]`; shaded characters (`▓`, `▒`, `░`) are banned.
- **AC-3**: CLI mode specifies ceiling and floor boxes (`╔═ <EMOJI><TITLE> ═════╗` / `╚═════╝`) with zero vertical side-walls (`║`).
- **AC-4**: Opening sections in Markdown mode specify two-column tables (`| What Changed | Verification Evidence |`) and descriptive links (`👉 [text](url)`).
- **AC-5**: Strict token budget gate passes (Balanced <= 2500, Lite <= 1500).
- **AC-6**: Behavioral contract tests pass in both Bash and PowerShell twins.

## Implementation Checklist
- [x] GitHub Issue #316 created
- [x] Branch feat/dual-mode-telemetry-formatting created
- [x] Task Record created (this file)
- [ ] Update protocols/telemetry-cards.md
- [ ] Update templates/agent-directive-template.md and lite template
- [ ] Update workflows/checkpoint.md examples
- [ ] Add contract assertions to run-behavioral-contract-tests.sh & .ps1
- [ ] Validate references & token gates
- [ ] Run behavioral & playbook test suites
- [ ] Push branch and open PR referencing #316
