---
status: Superseded
---

# JIT Implementation Spec: Issue D — Dedicated pk:fix Workflow

## Problem and Evidence
- `pk:debug` is specialized for scientific, hypothesis-driven investigation of **unknown root causes** (5-Whys, 3-5 ranked hypotheses).
- `pk:review` generates findings across Spec Fidelity and Code Quality axes.
- When a defect, security vulnerability, or performance bottleneck has an **already known root cause** (from review, static analysis, security report, or clear diagnosis), developers lacked a dedicated remediation protocol.
- Using `pk:debug` for known findings creates unnecessary hypothesis-ranking overhead, while jumping directly to `pk:commit` bypasses targeted reproduction/measurement and security-first ordering.

## Root Cause
Lack of a dedicated remediation workflow linking known diagnostic findings (`pk:review`, static analysis, explicit bug reports) to surgical execution (`pk:commit`).

## Files / Symbols Affected
- `workflows/fix.md`: Dedicated `pk:fix` remediation workflow document.
- `workflows/route.md`: Add `pk:fix` to fast shorthand, decision matrix, auto-route rules, visual flows, and ceremony mappings.
- `README.md`: Add `pk:fix` to shorthand table, protocol auto-route list, and layout diagram.
- `QUICKSTART.md`: Include `pk:fix` in relevant workflow lists.
- `scripts/validate-references.sh` & `scripts/validate-references.ps1`: Add `fix.md` to core workflows list.
- `scripts/tests/run-behavioral-contract-tests.sh` & `run-behavioral-contract-tests.ps1`: Add Scenario assertions for `pk:fix`.

## Public Behavior Impact
- `pk:fix` provides structured remediation for known findings.
- Enforces reproduction for functional defects and baseline measurement for performance findings.
- Preserves security-first ordering (blocking security/data-loss issues resolved before non-blocking items).
- Requires one load-bearing root cause per change set.
- Requires targeted regression verification before staging.
- Outlines clear handoff boundaries to `pk:debug` (if root cause turns out unknown), `pk:review`, `pk:test`, `pk:commit`, `pk:pr`, and `pk:ship`.
- Aligns with Level 0–3 ceremony model: Level 1 for localized low-risk fixes; Level 2 for schema/auth/contract/multi-component risks; Level 3 for release-critical work.

## Compatibility Considerations
- Fully additive change. Existing triggers (`pk:debug`, `pk:review`, `pk:commit`) retain their existing roles.

## Verification Commands
- `bash scripts/validate-references.sh .`
- `pwsh -NoProfile -File .\scripts\validate-references.ps1 -PromptKitDir .`
- `bash scripts/tests/run-behavioral-contract-tests.sh`
- `pwsh -NoProfile -File .\scripts\tests\run-behavioral-contract-tests.ps1`

## Release Impact
- Additive public contract change proposed for core candidate `minor` release.
