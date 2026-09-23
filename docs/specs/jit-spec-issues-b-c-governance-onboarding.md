---
status: Superseded
---

# JIT Implementation Spec: Issues B & C — Governance Relocation & Contribution Documentation

## Problem and Evidence
- `README.md` placed dense maintainer release-governance guidelines (candidate evaluation, range limits, effective change sets, draft changelog entries, approved release records) in the early onboarding path, before Quick Start and core feature overview.
- Consumer repository developers reading `README.md` encountered internal maintainer lifecycle policies intended only for Better-PromptKit maintainers evaluating candidates.
- The repository lacked `CONTRIBUTING.md` for contributor expectations, validation commands, workflow ownership, and maintainer release evidence governance.

## Decision on CHANGELOG.md
- **Decision**: Do NOT add `CHANGELOG.md`.
- **Rationale**: The repository maintains canonical, immutable release evaluation, candidate, QA, and release-note records under `docs/releases/` (e.g. `2026-09-10-v1.1.1-approved-release.md`), and publishes official release notes via GitHub Releases. Creating a separate root `CHANGELOG.md` would establish a competing release schema and duplicate source of truth.

## Root Cause
Detailed maintainer governance was colocated in `README.md` prior to establishing a dedicated `CONTRIBUTING.md` standard file.

## Files / Symbols Affected
- `README.md`: Move Quick Start and Level 1 standard work explanation before maintainer governance; replace dense maintainer release-governance sections with a concise summary and link to `CONTRIBUTING.md`. Preserve all behavioral contract test assertions.
- `CONTRIBUTING.md`: New file containing detailed maintainer release governance, contribution expectations, validation commands, workflow ownership matrix, and release boundaries.
- `docs/specs/jit-spec-issues-b-c-governance-onboarding.md`: JIT specification.

## Public Behavior Impact
- New users scanning `README.md` see product overview, Level 1 standard workflow path, and Quick Start first.
- Maintainers and contributors have a dedicated, single authority at `CONTRIBUTING.md` for contribution rules and release-evidence lifecycle policies.

## Compatibility Considerations
- Preserves all contract assertions in `scripts/tests/run-behavioral-contract-tests.sh` and `.ps1` (Level 0–3 ceremony descriptions, canonical guide links, Maintainer CI descriptions).
- Preserves all workflow references and reference validation passes.

## Verification Commands
- `bash scripts/validate-references.sh .`
- `pwsh -NoProfile -File .\scripts\validate-references.ps1 -PromptKitDir .`
- `bash scripts/tests/run-behavioral-contract-tests.sh`
- `pwsh -NoProfile -File .\scripts\tests\run-behavioral-contract-tests.ps1`

## Release Impact
- Patch level documentation improvement.
