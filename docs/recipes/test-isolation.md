---
name: test-isolation
category: recipe
version: 1
token_budget: 1500
description: Network boundary isolation (MSW), transactional database rollbacks, and deterministic test fixtures.
---

# Test Isolation & Network Boundary Recipe

Operational testing invariants and canonical patterns for hermetic test execution, network boundary mocking, and database transaction isolation.

---

## 1. Non-Negotiable Invariants

- **Hermetic Network Boundaries**:
  - Tests must never emit live HTTP requests to external third-party services (Stripe, GitHub, OpenAI). Intercept outbound boundaries using Mock Service Worker (MSW) or equivalent. Unhandled network requests must fail immediately (`onUnhandledRequest: 'error'`).
- **Transactional Database Isolation**:
  - Database tests must execute inside isolated transactions that roll back at completion (`BEGIN ... ROLLBACK`), or against dedicated ephemeral databases. Never allow persistent mutations to leak across test cases.
- **Deterministic Clocks**:
  - Time-dependent tests (token expiry, rate limits, timeouts) must use fake timers (`vi.useFakeTimers()`). Never introduce real-time sleeps (`await sleep(1000)`) in automated test suites.
- **Order-Independent Test Hermeticity**:
  - Every test case must be self-contained and runnable independently or in parallel without depending on previous tests.

---

## 2. Canonical Implementation Patterns

### Pattern A: Network Mocking with MSW

```typescript
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

export const handlers = [
  http.post("https://api.stripe.com/v1/customers", () => {
    return HttpResponse.json({ id: "cus_test_123", object: "customer" });
  }),
];

export const server = setupServer(...handlers);

export function setupNetworkMocking() {
  beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
}
```

### Pattern B: Transactional Rollback Harness

```typescript
export interface DbClient {
  query: (sql: string, params?: unknown[]) => Promise<unknown>;
}

export async function withTestTransaction<T>(
  db: DbClient,
  testFn: (tx: DbClient) => Promise<T>
): Promise<T> {
  await db.query("BEGIN;");
  try {
    return await testFn(db);
  } finally {
    // Invariant: Always roll back, even if test assertions failed
    await db.query("ROLLBACK;");
  }
}
```

### Pattern C: Deterministic Clock Simulation

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

describe("Session Expiry", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00.000Z"));
  });
  afterEach(() => vi.useRealTimers());

  it("marks session expired after TTL", () => {
    const session = { expiresAt: Date.now() + 15 * 60 * 1000 };
    vi.advanceTimersByTime(16 * 60 * 1000);
    expect(Date.now() > session.expiresAt).toBe(true);
  });
});
```

---

## 3. Framework Adaptations

- **Vitest / Jest**: Configure `setupFiles` with MSW hooks and fake timers.
- **Playwright (E2E)**: Intercept external requests via `page.route()`.
- **Go**: Use `httptest.NewServer` or `testcontainers-go` for ephemeral databases.
- **Python (pytest)**: Use `responses` or `pytest-mock` for HTTP mocking; `freezegun` for timers.

---

## 4. Anti-Patterns & Failure Modes

- **Live Third-Party Calls in CI**: Network blips or rate limits cause flaky CI builds and unwanted billing.
- **Real-Time `sleep()`**: Inflates test duration and causes race conditions under heavy CPU load.
- **Shared Mutable Fixtures**: Mutating global records makes tests fail when run out of order.
- **Permissive Unhandled Requests**: Omitting `onUnhandledRequest: 'error'` lets real HTTP calls leak silently.

---

## 5. Verification Checklist

- [ ] Unmocked outbound HTTP calls fail fast.
- [ ] Database tests run in rolled-back transactions or ephemeral containers.
- [ ] Time-sensitive tests use fake timers instead of real delays.
- [ ] Tests run deterministically in random order.
