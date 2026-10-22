# Intake Record — Acme Platform

Project: acme-platform
Slug: acme-platform
Intake date: 2026-10-21

## Intake metadata

| Field | Value |
| :--- | :--- |
| Size | medium |
| Rounds used | 2 |
| Questions asked | 5 |

## Decisions

| Decision ID | Status | Statement | Provenance |
| :--- | :--- | :--- | :--- |
| DECISION-acme-platform-001 | confirmed | Event dispatch MUST use a durable external queue so that dispatch survives a workspace service restart. | Jordan Vale confirmed 2026-10-21 |
| DECISION-acme-platform-002 | accepted-default | Vitest is the test runner for every platform package. | DEFAULT-acme-platform-001 |
| DECISION-acme-platform-003 | confirmed | The workspace service owns the domain boundaries. | Jordan Vale confirmed 2026-10-21 |
| DECISION-acme-platform-004 | open | The managed database vendor is not yet selected. | Not decided |

## Accepted defaults

| Default ID | Status | Accepted value | Scope | Resolves | Adjacent decisions that stay open |
| :--- | :--- | :--- | :--- | :--- | :--- |
| DEFAULT-acme-platform-001 | accepted | A disposable PostgreSQL container for integration tests. | The ad hoc container used only by the integration-test suite. | none | DECISION-acme-platform-002, DECISION-acme-platform-004 |

## Assumption records

| Assumption ID | Statement | Owner | Validation action | Status | Linked decision | Residual risk | Destination |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ASSUMPTION-acme-platform-001 | Batch dispatch order is best-effort. | Platform lead | Confirm after the dispatch decision lands. | accepted by DECISION-acme-platform-001 | DECISION-acme-platform-001 | Connection-pool limits may still change. | docs/STATE.md §5 |
| ASSUMPTION-acme-platform-002 | The managed vendor stays undecided. | Platform lead | Confirm with the platform budget owner. | open | DECISION-acme-platform-004 | - | - |

## Verification obligations

| Obligation ID | Statement | Owner | Status | Destination |
| :--- | :--- | :--- | :--- | :--- |
| OBLIGATION-acme-platform-001 | Confirm the queue survives a workspace service restart. | Platform lead | open | docs/STATE.md §7 |

## Round log

| Round | Questions | Closed by |
| :--- | :--- | :--- |
| 1 | 3 | "Anything to add?" |
| 2 | 2 | "Anything to add?" |
