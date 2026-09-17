# Task Record: TASK-2026-09-18-readme-rewrite

## Metadata
- **Task ID**: TASK-2026-09-18-readme-rewrite
- **GitHub Issue**: [#283](https://github.com/lowqualityloey/promptkit-os/issues/283)
- **Branch**: `docs/readme-control-plane-rewrite`
- **Ceremony Level**: Level 2 (Controlled)
- **Status**: in_progress
- **Created**: 2026-09-18
- **Owner**: Antigravity agent + human maintainer approval

## Requested Outcome
Restructure README.md from a workflow-catalog layout into a control-plane-first technical product document. Lead with architecture diagram, problem statement, and core idea. Remove workflow count as headline differentiator. Route depth to specialist docs.

## Scope Boundary
**In scope**: README.md only  
**Out of scope**: Any workflow, protocol, template, script, or other doc file

## Acceptance Criteria
- **AC-1**: First 3 sections communicate control-plane architecture, not workflow count
- **AC-2**: validate-references.sh exits 0
- **AC-3**: measure-tokens.sh --strict passes (Balanced <= 2500, Lite <= 1500)
- **AC-4**: run-behavioral-contract-tests.sh passes 178/178
- **AC-5**: run-playbook-contract-tests.sh passes 11/11

## Implementation Checklist
- [x] GitHub Issue #283 created
- [x] Task Record created (this file)
- [x] Branch docs/readme-control-plane-rewrite created
- [ ] README.md replaced with approved draft
- [ ] validate-references.sh -> PASS
- [ ] measure-tokens.sh --strict -> PASS
- [ ] run-behavioral-contract-tests.sh -> PASS
- [ ] run-playbook-contract-tests.sh -> PASS
- [ ] Commit pushed, PR opened referencing #283
- [ ] CI green, halted at Review Ready
