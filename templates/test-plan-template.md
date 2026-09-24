# Test Plan Specification: [Feature / Subsystem Name]

> **Developer-friendly fill-in guide:** `Author`, `Status`, `Created`, and `Test Frameworks` are **Required**. The intent register and test matrices are **Required for the applicable work type**; use the exact `N/A` value shown when a mode or work type makes a section Not applicable. A short entry names the behavior, seam, command, and expected result, for example: `Red command: pnpm test:run -- invite; expected: assertion fails because the invite is not persisted`.
>
> **Acronym guide:** `TDD` means Test-Driven Development; `API` means Application Programming Interface; `RLS` means Row-Level Security; `E2E` means End-to-End; `MSW` means Mock Service Worker; and `CI` means Continuous Integration. These explanations make the existing test-planning terms easier to scan without changing test ownership or TDD authority.
>
- **Author**: [Your Name / Team]
- **Status**: [Draft | In Review | Approved | Implemented]
- **Created**: [YYYY-MM-DD]
- **Test Frameworks**: [Vitest / Playwright / Jest / Testcontainers]

---

## 1. TDD Intent Register (Supporting Test-Plan View)

`pk:test` owns intent planning; the canonical Local Task Record owns TDD mode, readiness, execution state, and execution evidence. This section is a supporting reference and cannot activate TDD or replace the Local Task Record.

- **Task Record Link [Required for Controlled Work]**: `[TASK-<task-slug>](../tasks/<task-id>.md#TASK-<task-slug>)`
- **Work Type Reference [Required for Controlled Work]**: `Code Work | Documentation Work | Configuration Work | Research Work`; ambiguous work follows Code Work until clarified
- **TDD Enforcement Mode Reference [Optional]**: `disabled | enabled | N/A - no Task Record or Level 0 Work`; an absent Task Record field is effective `disabled`
- **Mode Authority [Required]**: `Canonical Local Task Record`; this test plan is a supporting reference and cannot activate TDD.
- **Mode Reconciliation [Required]**: `[Matches Task Record | Disagreement blocks readiness | N/A]`

### Enabled Code Work Intent

When the Task Record mode is `enabled` for Code Work, create one row per behavior before implementation. The expected Red assertion and runnable command must be concrete before the intent becomes `ready`. Keep the same Behavior ID in the Task Record's Red, Green, and Refactor evidence; Green and Refactor rerun the same Red command and retain the acceptance condition.

<!-- Replace the example anchor with each immutable intent ID. -->
<a id="TDD-INTENT-task-slug-001"></a>

| Intent ID [Required] | Behavior ID [Required] | Task Record Link [Required] | Test / Expected Failing Assertion [Required] | Runnable Red Command [Required] | Status [Required] |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `TDD-INTENT-<task-slug>-<nnn>` | `BEHAVIOR-<task-slug>-<nnn>` | `[TASK-<task-slug>](../tasks/<task-id>.md#TASK-<task-slug>)` | `[observable behavior and failing assertion]` | `[exact command]` | `proposed | ready | superseded` |

### Disabled Code Work and Exception Verification

- **Disabled Code Work:** Record `N/A - TDD Enforcement Mode disabled` for the complete intent register instead of inventing rows. The Local Task Record still requires normal dependency-ordered milestones, acceptance criteria, test strategy, review, and verification.
- **Documentation, Configuration, or Research Work:** Record `N/A - <reason>` for the intent register and link the explicit exception verification task. Do not create a hidden TDD chain.
- **Ambiguous Work:** Follow the Code Work path until Work Type and TDD Enforcement Mode are clarified; do not grant an automatic exception.
- `None` means there are no entries only after the applicable mode and work type are recorded.

---

## 2. Feature Risk Assessment & Critical Invariants

| Risk / Invariant Description | Severity | Target Test Seam | Protection Mechanism |
| :--- | :--- | :--- | :--- |
| **Multi-tenant data isolation leak** | Critical | Integration | Real PostgreSQL RLS query test |
| **Concurrent seat over-allocation** | High | Integration | Concurrent requests asserting row lock |
| **Token expiration date calculation** | Medium | Unit | Vitest with fake timers (`useFakeTimers`) |
| **Complete user signup and onboarding**| High | E2E | Playwright browser journey |

---

## 3. Test Seam Allocation Matrix

### Unit Tests (Pure Logic, <1ms execution)
| Test Target | File / Function | Scenarios Tested |
| :--- | :--- | :--- |
| `calculateProration()` | `src/lib/billing.ts` | Leap years, mid-month upgrades, downgrades, zero-dollar plans |
| `InviteFormSchema` | `src/schemas/invite.ts`| Invalid email domains, missing roles, edge whitespace |
| `workspaceReducer()` | `src/state/workspace.ts`| Optimistic member insertion, rollback on rejection |

### Integration Tests (Real Database, API Seam)
*Harness: PostgreSQL via Docker / Testcontainers / Local Supabase CLI*
| Test Target | Endpoint / Service | Scenarios Tested |
| :--- | :--- | :--- |
| `POST /api/v1/invitations` | Invitation API Route | Valid invite creates DB row and dispatches email event |
| `POST /api/v1/invitations` | Invitation API Route | Duplicate invite returns 409 Conflict with error envelope |
| RLS Query Isolation | Document Repository | User from Workspace A cannot read rows from Workspace B |
| Mutation Idempotency | Payment Webhook Handler | Replaying same `Idempotency-Key` does not charge customer twice |

### End-to-End Tests (Playwright Browser Flows)
| Journey Name | File Path | User Steps & Assertions |
| :--- | :--- | :--- |
| `e2e/invite-flow.spec.ts` | User signs in, opens invite modal, enters colleague email, submits form, verifies pending badge in member table. |

---

## 4. External Mock Boundaries

*Rule: Never mock internal database or ORM; mock only external networks.*

| External Service | Mocking Mechanism | Scope / File | Behavior Simulated |
| :--- | :--- | :--- | :--- |
| **Stripe API** | MSW (Mock Service Worker) | `tests/mocks/stripe.ts` | Successful checkout session, declined card error |
| **Resend / SendGrid**| In-memory Fake Adapter | `tests/fakes/mailer.ts` | Intercepts sent emails in array for assertions |
| **AWS S3** | LocalStack / MSW | `tests/mocks/s3.ts` | Pre-signed upload URL generation |

---

## 5. Test Data Factories

```typescript
// tests/factories/workspace.factory.ts
export function buildWorkspace(overrides: Partial<Workspace> = {}): Workspace {
  const id = crypto.randomUUID();
  return {
    id,
    name: `Workspace ${id.slice(0, 6)}`,
    slug: `ws-${id.slice(0, 8)}`,
    tier: 'FREE',
    createdAt: new Date(),
    ...overrides,
  };
}
```

---

## 6. Anti-Flakiness & Timing Checklist
- [ ] Zero arbitrary `sleep()` or `setTimeout()` calls in test suites.
- [ ] Time-dependent tests use `vi.useFakeTimers()`.
- [ ] Database tests use isolated tenant IDs or per-test transaction rollbacks.
- [ ] E2E tests use locator assertions (`expect(locator).toBeVisible()`) with automatic retry polling.

---

## 7. CI Pipeline & Coverage Targets
- **Unit & Integration Suite Execution**: `pnpm test:run` (Target runtime: < 30 seconds)
- **E2E Suite Execution**: `pnpm test:e2e` (Target runtime: < 2 minutes)
- **Core Domain Coverage Target**: [e.g., 90%+ path coverage on billing and auth state machines]
