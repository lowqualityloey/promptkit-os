# Engineering Spec: Empirical Benchmark Scenarios & Evaluation Rubrics (SPEC-0279)

Formal specification of standardized benchmark scenarios, seed fixtures, and mechanical pass/fail assertions for the Cost Per Accepted Change (CPAC) benchmark.

---

## 1. Scope & Objective

This specification defines 3 multi-ecosystem benchmark tasks used to evaluate AI coding agents under the [Benchmark Methodology](../BENCHMARK-METHODOLOGY.md). Each scenario tests real-world architectural discipline, error handling, and invariant preservation under controlled test conditions.

---

## 2. Benchmark Task Matrix

| Scenario ID | Ecosystem | Problem Domain | Target Playbook / Recipe | Primary Invariant Under Test |
| :--- | :--- | :--- | :--- | :--- |
| **`WEB-01`** | Next.js / TypeScript | Webhook Ingestion & Idempotency | `deploy-cloudflare.md`<br>`webhook-idempotency.md` | Raw body byte preservation before JSON parsing; timing-safe HMAC equality. |
| **`SYS-02`** | Go / Systems | Concurrent Worker Pool | `systems-go.md`<br>`test-isolation.md` | Context cancellation propagation; zero goroutine leaks; `-race` clean execution. |
| **`DATA-03`** | SQL / Relational | Zero-Downtime Migration | `database-turso.md`<br>`database-supabase.md` | Expand-Contract non-destructive migrations; transactional test harness rollbacks. |

---

## 3. Scenario Specifications

### Scenario WEB-01: Authenticated Webhook Ingestion

- **Seed Repository Fixture**: Next.js App Router application with existing billing routes and SQLite/Turso database.
- **Task Prompt**:
  > *"Implement a POST route handler at `/api/webhooks/stripe` that receives incoming payment events. The endpoint must verify the HMAC-SHA256 signature using the configured webhook secret, record the event ID in our idempotency ledger table, enqueue the fulfillment job asynchronously, and return HTTP 200 within 2 seconds. Duplicate event deliveries must return HTTP 200 without re-enqueuing."*

#### Mechanical Pass/Fail Assertions:
1. **Raw Body Invariant**: The handler reads `await req.text()` or `await req.arrayBuffer()` directly from the request stream before any `JSON.parse` invocation.
   - *Failure condition*: Parsing JSON first and attempting `JSON.stringify(body)` to compute the HMAC hash.
2. **Timing-Safe Comparison**: The signature verification uses `crypto.timingSafeEqual` (or constant-time equivalent).
   - *Failure condition*: Using string equality `===`.
3. **Idempotency Acknowledgment**: Test sends identical event payload twice; the second call returns HTTP 200 and does NOT trigger a second queue push.
   - *Failure condition*: Throwing unique constraint error resulting in HTTP 500.
4. **Verification Gate**: `npm run type-check` and `npm test` exit with code 0.

---

### Scenario SYS-02: Concurrent Worker Pool with Context Cancellation

- **Seed Repository Fixture**: Go daemon service with CLI entrypoint and work queue channel.
- **Task Prompt**:
  > *"Implement a bounded concurrent worker pool in package `workerpool`. It must process incoming `Job` structs concurrently up to a configurable max worker count (default 5). When the root `context.Context` is cancelled (e.g. SIGINT), all workers must complete their currently executing job, reject new jobs, drain in-flight buffers, and return without goroutine leaks. Must pass with race detector enabled."*

#### Mechanical Pass/Fail Assertions:
1. **Context Propagation**: First parameter of worker functions is `ctx context.Context`, checked via `ctx.Done()` in select loops.
   - *Failure condition*: Spawning unmonitored goroutines without context cancellation handles.
2. **Race Detector Clean**: `go test -race ./...` exits with code 0 and zero data race reports.
   - *Failure condition*: Data race detected on shared counters or status flags.
3. **Goroutine Leak Check**: Test executes `goleak.VerifyNone(t)` after context cancellation; zero orphaned background goroutines.
   - *Failure condition*: Hanging goroutines blocked on unbuffered channels.
4. **Error Discipline**: Zero blank identifier error discards (`_ = fn()`); all errors handled or returned.

---

### Scenario DATA-03: Zero-Downtime Relational Schema Migration

- **Seed Repository Fixture**: Node/TypeScript service using Drizzle/Prisma with Postgres/Turso.
- **Task Prompt**:
  > *"Add an optional `billing_tier` enum column (`'free' \| 'pro' \| 'enterprise'`) to our `accounts` table. Update the account creation service to set the tier, backfill existing records with `'free'`, and ensure our integration test suite executes cleanly in isolated transactions that leave no persisted test rows."*

#### Mechanical Pass/Fail Assertions:
1. **Expand-Contract Discipline**: Migration creates column as nullable or with a non-blocking default; zero instantaneous destructive alters.
2. **Transactional Test Isolation**: Integration test harness executes operations wrapped in `BEGIN ... ROLLBACK` or ephemeral databases.
   - *Failure condition*: Test records remain in the database after the test process terminates.
3. **Verification Gate**: Test assertions pass on both legacy schema and upgraded schema without application downtime.

---

## 4. Scoring & Telemetry Extraction

For each scenario run, the harness records:
1. **`tokens_in` & `tokens_out`**: Collected from host model usage metadata.
2. **`tool_calls_search`**: Ripgrep (`grep_search`), file finder (`find_by_name`), and directory listing (`list_dir`) counts.
3. **`tool_calls_edit`**: File edit (`replace_file_content`) and creation (`write_to_file`) counts.
4. **`rework_loops`**: Number of test/compile execution commands that returned exit code $\ne 0$ before final success.
5. **`wall_clock_seconds`**: Total elapsed execution duration.
6. **`invariants_score`**: Mechanical percentage of scenario-specific invariants satisfied.

---

## 5. Related Documentation

- [`BENCHMARK-METHODOLOGY.md`](../BENCHMARK-METHODOLOGY.md) — Benchmark philosophy and mathematical CPAC formula.
- [`../BENCHMARKS.md`](../BENCHMARKS.md) — Static prompt token budgets.
- [`../../scripts/measure-cpac.sh`](../../scripts/measure-cpac.sh) — Telemetry extraction CLI utility.
