# Performance Profiling & Latency Protocol

## Fast Shorthand
Trigger anytime with: `pk:perf` (or `/pk-perf`, `pk:latency`)

> [!NOTE]
> **Alias retirement**: `pk:profile` was historically listed here as an alias. It is now owned exclusively by the runtime profile switcher (`workflows/profile.md`). Use `pk:latency` or `pk:perf` for profiling.

## Mission
Eliminate silent performance regressions (sluggish API responses, slow database queries, memory leaks, event loop lag, React render thrashing, bundle size bloat, and Core Web Vitals degradation) using empirical profiling, hypothesis testing, and verifiable before-and-after delta audits.

Unlike functional bugs handled in `pk:debug`, performance regressions rarely throw red exceptions or stack traces. They degrade latency, user experience, and cloud infrastructure costs silently.

---

## The Non-Negotiable Performance Law
> **No baseline metric, no optimization code.**
> Never refactor code, add database indexes, wrap components in `useMemo`, or alter caching layers based on intuition or guesswork. You must capture an empirical baseline before modifying a single line of production code.

---

## Preconditions
1. Developer reports sluggish behavior, high latency, memory consumption, or bundle bloat, OR a performance regression was detected in automated testing.
2. The target endpoint, database query, background worker, or frontend component is identifiable.
3. Benchmarking or profiling tooling is available (`autocannon`, `k6`, `EXPLAIN ANALYZE`, Lighthouse, Chrome DevTools, or Node.js profilers).

---

## 4-Phase Profiling Protocol

### Phase 1: Baseline Quantification
Before analyzing code, establish a repeatable benchmark loop under controlled conditions:

1. **Define the Target Metric & SLA**:
   - What exact metric is degraded? (e.g., p95 API response time, database query execution time, client JavaScript bundle size, RSS memory growth, or Core Web Vitals INP).
   - What is the acceptable target budget? (e.g., p95 `< 150ms` under 100 concurrent requests).

2. **Execute Controlled Baseline Benchmark**:
   - Run a minimal, reproducible benchmark command:
     ```bash
     # API endpoint benchmark:
     autocannon -c 50 -d 20s http://localhost:3000/api/v1/workspaces

     # Database query plan:
     EXPLAIN (ANALYZE, BUFFERS, TIMING, COSTS) SELECT ...;

     # Bundle size analysis:
     pnpm build --analyze
     ```
   - Record exact initial values: p50, p95, p99 latency, throughput (req/s), memory RSS, or bundle bytes.

---

### Phase 2: Multi-Layer Bottleneck Localization
Isolate the exact layer responsible for the degradation. Do not assume where the bottleneck lies:

1. **Database & Storage Layer**:
   - Run `EXPLAIN (ANALYZE, BUFFERS)`:
     - Check for `Seq Scan` on large tables (missing composite or covering indexes).
     - Check `Buffers: shared hit vs read` (excessive disk I/O indicates un-indexed filters or un-cached working sets).
     - Check for N+1 query patterns: multiple roundtrips inside loops instead of batch fetching or joins.
     - Check connection pool exhaustion and transaction lock hold times.

2. **Backend Runtime & Network Layer**:
   - Check Node.js event-loop lag and synchronous CPU blocking:
     - Heavy JSON parsing or stringification of oversized payloads.
     - Synchronous cryptographic or regex operations on the main thread.
   - Check sequential asynchronous execution:
     - Sequential `await` calls that can be batched with `Promise.allSettled`.
   - Check caching effectiveness:
     - Missing Cache-Control headers, Redis key misses, or stale-while-revalidate opportunities.

3. **Frontend & Client Runtime Layer**:
   - Check React 19 / client render churn:
     - Unstable object references or inline handlers triggering full subtree re-renders.
     - Context providers passing un-memoized values to deeply nested component trees.
   - Check JavaScript bundle bloat:
     - Duplicate packages across node_modules.
     - Non-tree-shakeable imports (e.g., importing entire utility libraries for a single function).
   - Check Core Web Vitals:
     - INP (Interaction to Next Paint): heavy JavaScript execution on click/keyboard interaction.
     - LCP (Largest Contentful Paint): unoptimized images, render-blocking resources, or slow server time-to-first-byte (TTFB).

---

### Phase 3: Targeted Optimization & Invariant Preservation
Apply the single highest-leverage optimization identified in Phase 2:

1. **Enforce Surgical Interventions**:
   - Implement the minimal code change that directly resolves the identified bottleneck.
   - Examples of high-leverage fixes:
     - Adding a targeted composite index with `CONCURRENTLY` (Expand-Contract safe).
     - Converting an offset-based pagination query to cursor-based keyset pagination.
     - Splitting a monolithic client bundle using dynamic `React.lazy` imports.
     - Replacing an N+1 ORM query loop with a batched dataloader.

2. **Preserve Domain & Security Invariants**:
   - **Tenant Isolation**: Never weaken Row-Level Security (RLS) or WHERE clauses to make a query faster.
   - **Data Integrity**: Never downgrade database transaction isolation levels without explicit concurrency audit.
   - **Code Maintainability**: Reject hyper-optimized micro-tweaks that make code unreadable for fractional millisecond gains.

---

### Phase 4: Empirical Delta Verification & Budget Locking
Prove that the optimization succeeded and lock in the result against future regressions:

1. **Re-Run the Identical Benchmark**:
   - Execute the exact same command used in Phase 1 under matching system load.
   - Calculate the percentage delta for all target metrics:
     $$\Delta\% = \frac{\text{Post} - \text{Pre}}{\text{Pre}} \times 100$$

2. **Verify Against SLA Budget**:
   - Did the change achieve the target performance budget?
   - Did any secondary metric regress? (e.g., did memory usage spike after adding an in-memory cache?).

3. **Compile Audit Report**:
   - Scaffold an audit report in `docs/perf/` using `.promptkit/templates/perf-audit-template.md`:
     - Path: `docs/perf/<feature-name>-perf-audit.md`
   - Include the Before vs After delta table, verbatim `EXPLAIN ANALYZE` or flamegraph summaries, and regression prevention rules.

4. **Lock Regression Guards**:
   - Add automated performance tests or bundle budgets to CI so future commits cannot reintroduce the latency regression.

---

## Diagnostic Triage Questions

When performance issues arise, answer these 3 diagnostic questions:

1. **What layer is dominating elapsed time?**
   - If time is spent waiting on I/O: Inspect database queries and network roundtrips first (`EXPLAIN ANALYZE`, connection pool limits).
   - If time is spent consuming 100% CPU: Inspect event-loop blocking, JSON serialization, or infinite render loops.

2. **Is the degradation constant, or does it degrade with scale ($O(N)$ / $O(N^2)$)?**
   - Constant overhead: Missing cache headers, uncompressed payloads, or excessive client script tags.
   - Scale-dependent degradation: N+1 query loops, missing indexes on foreign keys, or un-virtualized large lists.

3. **Does the fix preserve correctness and security?**
   - Ensure faster code produces the identical output and respects all authorization barriers.

---

## Completion Criteria
- Baseline metric was empirically captured before any code modification.
- Root bottleneck was isolated to a specific database query, runtime operation, or render lifecycle.
- Targeted optimization was applied without violating domain invariants or security boundaries.
- Re-run benchmark proves measurable latency reduction, memory stabilization, or bundle size reduction.
- Performance audit report is documented in `docs/perf/` using `templates/perf-audit-template.md`.
