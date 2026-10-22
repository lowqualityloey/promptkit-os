# Intake Record - Acme Platform

Project: acme-platform
Intake date: 2026-10-22
close_reason: greenfield intake closed; the event dispatch surface is confirmed

## Size class

size: medium

## Seven-slot coverage table

| Slot | Status | Notes |
| :--- | :--- | :--- |
| 1. Product surface | answered | Internal platform for the Acme workspace service. |
| 2. Users and roles | answered | Platform engineers. |
| 3. Data sensitivity | answered | Internal operational data. |
| 4. Scale and load | answered | Low traffic with bursty batch windows. |
| 5. Existing artifacts | answered | `ARCHITECTURE.md` pre-exists in the repository. |
| 6. Design vibe | assumed | Server-rendered admin console. |
| 7. Deployment target | answered | One cloud region. |

## Decisions I am defaulting for you

- **DECISION-acme-platform-001** (confirmed): Event dispatch MUST use a durable external queue so that dispatch survives a workspace service restart.
- **DECISION-acme-platform-002** (changed): The workspace service owns the domain boundaries.

## Host Documentation Divergence

The detected `ARCHITECTURE.md` states the opposite of `DECISION-acme-platform-001` about the dispatch surface. The document is left untouched. A human designated `decision-authority` on 2026-10-22 (Jordan Vale), so the contradiction is recorded here for architecture reconciliation and the outstanding work is reconciling the host blueprint.

| Divergence ID | Document | Line | Decision ID | Precedence | Designated By | Owner | Next Action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| DIVERGENCE-acme-platform-001 | ARCHITECTURE.md | 2 | DECISION-acme-platform-001 | decision-authority | Jordan Vale (2026-10-22, docs/specs/2026-10-22-intake-acme-platform.md) | Platform lead | Ask the architecture owner to reconcile the dispatch model in `ARCHITECTURE.md` with the designated `decision-authority` precedence; the host document stays untouched until that reconciliation is agreed. |

## Later ledger

- none

## Unknowns

- none

## Assumption records

- **ASSUMPTION-acme-platform-001**: batch dispatch semantics. Owner: Platform lead. Validation action: confirm after the dispatch decision lands.
