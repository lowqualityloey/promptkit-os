# Performance Audit & Optimization Report

> [!NOTE]
> **Stack Neutrality**: The worked example in this template illustrates a web/API/PostgreSQL stack. Treat every layer, metric, and tool as *illustrative*: keep the structure (baseline → layered findings → root cause → surgical change → measured delta → regression guards) and substitute the layers, metrics, and tooling of the detected project stack (e.g., Rust: `criterion` / flamegraph; Go: `pprof` / benchmarks; Python: `py-spy` / `cProfile`; CLI: benchmark harnesses; databases: `EXPLAIN ANALYZE`-style query plans). Drop sections that do not apply and record `N/A - not applicable to this stack` rather than inventing measurements.

## Metadata & Target Scope

| Attribute | Specification |
| :--- | :--- |
| **Target Service / Endpoint / Component** | `[e.g., GET /api/v1/workspaces/:id/dashboard or <DataTable />]` |
| **Audit Date** | `YYYY-MM-DD` |
| **Author / Lead Engineer** | `[Name / Handle]` |
| **Target Environment** | `[e.g., Staging / Production Replica / Local Benchmark Host]` |
| **Profiling & Load Tooling** | `[e.g., k6, autocannon, pg_stat_statements, EXPLAIN ANALYZE, Lighthouse, 0x]` |
| **Optimization Target Goal** | `[e.g., Reduce p95 latency from 850ms to <100ms under 200 req/s]` |

---

## 1. Baseline Quantification (Pre-Optimization)

Capture verifiable baseline performance under controlled, reproducible conditions before modifying code:

| Metric | Target SLA / Budget | Measured Baseline | Status |
| :--- | :--- | :--- | :--- |
| **p50 Latency (Median)** | `< 50ms` | `[e.g., 280ms]` | Exceeds Budget |
| **p95 Latency** | `< 150ms` | `[e.g., 850ms]` | Degraded |
| **p99 Latency (Tail)** | `< 300ms` | `[e.g., 2,100ms]` | Critical |
| **Max Throughput** | `> 500 req/s` | `[e.g., 75 req/s]` | Saturated |
| **Error Rate under Load** | `< 0.1%` | `[e.g., 4.2% (504 Gateway Timeout)]` | Failing |
| **Memory Footprint / Leak**| `< 256MB RSS` | `[e.g., 890MB growing linearly]` | Leak Suspected |
| **Client Bundle / Render** | `< 150KB JS / < 16ms render` | `[e.g., 780KB JS / 120ms render frame]` | Degraded |

### Benchmark Reproduction Command
```bash
# Example load command (autocannon or k6):
autocannon -c 50 -d 30s -p 10 http://localhost:3000/api/v1/workspaces/ws_123/dashboard
```

---

## 2. Multi-Layer Profiling Findings

### A. Database & Query Layer (`EXPLAIN (ANALYZE, BUFFERS)`)
*Run `EXPLAIN (ANALYZE, BUFFERS, TIMING, COSTS)` on slow queries. Never guess index effectiveness.*

```sql
-- Paste verbatim EXPLAIN ANALYZE output:
Seq Scan on workspace_events (cost=0.00..18450.20 rows=452300 width=128) (actual time=0.045..82.340 rows=450000 loops=1)
  Filter: (workspace_id = 'ws_123'::uuid AND created_at >= '2026-01-01'::timestamptz)
  Buffers: shared hit=4210 read=14240
Planning Time: 0.142 ms
Execution Time: 86.410 ms
```

- **Query Pathology Detected**: Sequential scan scanning 450,000 rows due to missing composite index on `(workspace_id, created_at DESC)`.
- **N+1 Query Detection**: Endpoint executes 1 root query + 50 loop queries fetching member avatars instead of a single joined query or batch dataloader.
- **Connection Pool / Locks**: Transaction held for 350ms while awaiting external API response, exhausting connection pool limit (10 connections).

### B. Backend Runtime & Event-Loop Layer
- **CPU Bottleneck**: CPU flamegraph reveals synchronous JSON serialization of 10,000 raw objects blocking the Node.js event loop for 180ms.
- **Memory Profile**: Detached closures retained in memory cache without TTL or maximum size eviction policy.
- **I/O Serialization**: Sequential asynchronous `await` calls executed in a loop rather than batched with `Promise.allSettled`.

### C. Client & Frontend Layer (React 19 / Core Web Vitals)
- **Render Thrashing**: Parent `<DashboardLayout />` recreates inline callback objects, triggering re-renders of 45 child components per keystroke.
- **Bundle Bloat**: Page imports entire `lodash` (72KB gzipped) and `moment.js` (68KB gzipped) instead of modular date utilities.
- **Core Web Vitals**:
  - **INP (Interaction to Next Paint)**: `[e.g., 420ms]` (Budget: `< 200ms`) due to heavy synchronous DOM mutations.
  - **LCP (Largest Contentful Paint)**: `[e.g., 3.8s]` (Budget: `< 2.5s`) caused by unoptimized hero image without `priority` flag.

---

## 3. Root Cause Analysis & Empirical Hypothesis

### Root Cause
`[Explain the exact technical mechanism causing the degradation. State why the system slows down under load.]`

### Working Hypothesis
If we `[apply specific architectural / query change X]`, then `[metric Y]` will decrease from `[baseline]` to `[target]` because `[technical reasoning: e.g. eliminating disk reads via B-tree index traversal]`.

---

## 4. Optimization Strategy & Invariant Preservation

### Surgical Changes Made
1. **Database**: Added composite covering index `idx_workspace_events_composite` on `workspace_events(workspace_id, created_at DESC) INCLUDE (event_type, actor_id)`.
2. **Backend**: Implemented cursor-based pagination limiting page size to 50 records; replaced sequential ORM loop with single batched query.
3. **Frontend**: Isolated expensive list rendering behind `React.memo` with stable selector callbacks; dynamically imported chart heavy-weights.

### Preserved Invariants
- **Row-Level Security (RLS)**: Verification that index filters strictly adhere to tenant isolation policies.
- **Transaction Consistency**: No read-uncommitted isolation level introduced to bypass locking.
- **Code Readability**: Rejected complex micro-optimizations that obscure domain logic for sub-1% gains.

---

## 5. Empirical Verification Delta (Post-Optimization)

Re-run the exact reproduction workload under identical conditions:

| Metric | Pre-Optimization Baseline | Post-Optimization Result | Delta (% Change) | SLA Met? |
| :--- | :--- | :--- | :--- | :--- |
| **p50 Latency** | `[e.g., 280ms]` | `[e.g., 18ms]` | `-93.6%` | YES |
| **p95 Latency** | `[e.g., 850ms]` | `[e.g., 42ms]` | `-95.1%` | YES |
| **p99 Latency** | `[e.g., 2,100ms]` | `[e.g., 95ms]` | `-95.5%` | YES |
| **Max Throughput** | `[e.g., 75 req/s]` | `[e.g., 680 req/s]`| `+806.7%` | YES |
| **Database Execution Time**| `[e.g., 86.4ms]` | `[e.g., 1.2ms]` | `-98.6%` | YES |
| **Shared Buffer Reads** | `[e.g., 14,240 blocks]`| `[e.g., 18 blocks]` | `-99.8%` | YES |
| **Client Bundle Size** | `[e.g., 780KB]` | `[e.g., 185KB]` | `-76.3%` | YES |

---

## 6. Regression Guards & Performance Budgets

Lock in performance improvements so future commits cannot silently regress latency:

1. **Automated Load Test Script**:
   Save load test script to `tests/load/workspace-dashboard.k6.js` or equivalent.
2. **CI Threshold Check**:
   Configure CI to fail if bundle size increases by more than 5KB or if database query plans revert to sequential scans.
3. **Production Telemetry Alert**:
   Set alert threshold on p95 latency exceeding `150ms` over a 5-minute rolling window.
