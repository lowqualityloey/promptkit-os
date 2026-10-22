# State Tracker — Acme Platform

## 4. Locked Technical Invariants (Do Not Undo)

- Event dispatch uses a durable external queue (DECISION-acme-platform-001).

## 5. Known Blockers, Risks & Open Questions

- Connection-pool limits may still change once the managed vendor is selected.

## 7. Next Immediate Actions (Queued)

- Confirm the queue survives a workspace service restart (OBLIGATION-acme-platform-001).
