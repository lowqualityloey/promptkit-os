# Root Cause Analysis (RCA) & Incident Post-Mortem

- **Incident ID / Title**: [INC-YYYY-MM-DD: Short Description of Failure]
- **Date & Time of Incident**: [YYYY-MM-DD HH:MM UTC]
- **Incident Severity**: [P0 - Critical Outage | P1 - Major Degradation | P2 - Minor Defect]
- **Lead Investigator**: [Your Name]
- **Status**: [Investigating | Fix Deployed | Closed / Action Items In Progress]

> Worked example — every name, timestamp, metric, and status below is illustrative. Replace all fields with the real incident's data; never present this example as evidence.

---

## 1. Executive Summary
[A brief, non-technical summary of what happened, what users experienced, how long it lasted, and what fixed it.]

---

## 2. Timeline of Events (UTC)
| Timestamp | Event / Action Taken | Observed By / Actor |
| :--- | :--- | :--- |
| **14:02** | Release v2.4.1 deployed to staging/production. | CI/CD Automation |
| **14:08** | Error rate on `/api/checkout` spiked from 0.01% to 14.8%. | Datadog Alert |
| **14:15** | Incident channel opened; triage engineer begins investigation. | On-call Engineer |
| **14:27** | Hypothesis confirmed: Database connection pool exhausted due to unclosed transaction. | Senior Dev |
| **14:35** | Rollback to v2.4.0 initiated; error rates returned to 0%. | Release Manager |
| **15:10** | Hotfix PR deployed with transaction cleanup and connection pool guardrails. | Tech Lead |

---

## 3. Root Cause Analysis (The 5 Whys)

1. **Why did the checkout API start returning 500 errors?**
   - *Because database queries timed out waiting for an available connection from the pool.*
2. **Why was the connection pool exhausted?**
   - *Because connections opened by the new promotional coupon service were never released back to the pool on validation failure.*
3. **Why were they not released on validation failure?**
   - *Because the transaction commit was wrapped in a `try` block, but the `release()` call was placed after the catch block rather than inside a `finally` block.*
4. **Why was this not caught during automated testing?**
   - *Because the unit tests used an in-memory mock that did not simulate connection pool capacity limits.*
5. **Why was connection leak detection absent in staging?**
   - *Because our staging telemetry alerts did not have threshold monitors configured for PostgreSQL active connection pool saturation.*

---

## 4. Where We Got Lucky vs. Where We Failed
- **Lucky**: The Datadog anomaly monitor alerted within 6 minutes of release.
- **Failure**: Missing `finally` block in resource acquisition; integration tests did not verify connection recycling under failure conditions.

---

## 5. Corrective & Preventative Action Items

| Action Item | Type | Owner | Target Date | Status |
| :--- | :--- | :--- | :--- | :--- |
| Move all DB transaction handlers to scoped `using` / `try...finally` resource patterns | Preventative (Code) | [Engineer] | [Date] | Done |
| Add integration test suite testing 1,000 concurrent failed transactions with tight connection pool | Preventative (Test) | [Engineer] | [Date] | In Progress |
| Configure Datadog connection pool saturation alert at 75% threshold | Detective (Monitor)| [DevOps] | [Date] | Done |
| Add ESLint rule enforcing `finally` cleanup on acquired pool handles | Preventative (Lint) | [Lead] | [Date] | Open |

---

## 6. Lessons Learned & Retrospective
- **What went well**: Fast response time and clear rollback procedure.
- **What to improve**: Add load testing for new data-access paths before merging to main.
