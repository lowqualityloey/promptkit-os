---
name: deploy-cloudflare
category: cloud
version: 1
token_budget: 1500
activation:
  manifests:
    - wrangler.json
    - wrangler.toml
verification:
  fast:
    - npx wrangler types
  required:
    - npx wrangler deploy --dry-run
  extended:
    - npm test
invariants:
  - "Workers run on V8 isolates — Node.js built-ins require explicit nodejs_compat configuration"
  - "D1, KV, R2, and Queues must be accessed via typed runtime bindings rather than process.env"
  - "Asynchronous background work executed after response dispatch must use ctx.waitUntil"
  - "CPU time is strictly bounded — offload heavy computational workloads or batch them cleanly"
  - "Cloudflare D1 queries requiring atomic consistency must execute via db.batch rather than multi-turn transactions"
anti_patterns:
  - "Importing native C++ Node.js addons or unbundled filesystem dependencies into Workers"
  - "Accessing storage or database resources via raw connection strings instead of typed bindings"
  - "Spawning unawaited promises after sending the HTTP response without wrapping in ctx.waitUntil"
  - "Attempting interactive multi-turn SQL transactions across HTTP roundtrips with D1"
---

# Cloudflare Workers & Pages Deployment Playbook

Operational guidelines, invariants, and failure modes for serverless applications, APIs, and edge storage hosted on Cloudflare.

## 1. Architectural Invariants

- **V8 Isolate Runtime (workerd)**: Cloudflare Workers execute inside lightweight V8 isolates rather than traditional Node.js processes. To use built-in Node modules (e.g. `crypto`, `buffer`, `events`), you must specify the `nodejs_compat` compatibility flag in `wrangler.json` or `wrangler.toml`. Native C++ Node addons are fundamentally unsupported.
- **Typed Runtime Bindings**: Resources such as D1 databases, KV key-value stores, R2 object storage, Vectorize indexes, and Queues are exposed directly on the environment context object (e.g. `env.DB`, `env.BUCKET`, `env.MY_KV`). Never attempt to configure raw database hostnames or global connection strings when a Cloudflare binding is available.
- **Background Execution via `ctx.waitUntil()`**: Cloudflare terminates isolate execution immediately when the client `Response` stream finishes. If your handler needs to log analytics, record telemetry, or push jobs to a queue after returning a response, you MUST pass that promise to `ctx.waitUntil(promise)`.
- **CPU Time Budgets**: The runtime meters actual CPU execution time, not idle wall-clock I/O time. Free tier workers are allocated 10ms of CPU time; Standard workers receive 50ms. Complex cryptographic operations or heavy JSON parsing must be optimized to prevent CPU timeout termination.
- **D1 Atomic Batching**: Cloudflare D1 operates on distributed SQLite. It does not support interactive multi-turn transactions (`BEGIN TRANSACTION ... COMMIT` across multiple network roundtrips). Group multiple queries atomically using the `db.batch([stmt1, stmt2])` API.

## 2. Critical Anti-Patterns & Pitfalls

- **Process.env Assumption**: Referencing `process.env.DB` or `process.env.SECRET` instead of accessing `env.SECRET` from the Worker handler arguments returns `undefined` at runtime.
- **Dangling Post-Response Promises**: Invoking `fetch()` or database inserts asynchronously without `await` and without `ctx.waitUntil()` results in silent data loss because the isolate freezes instantly after returning the response.
- **Subrequest Limits**: Workers are limited to 50 simultaneous outbound `fetch` subrequests per invocation on standard plans. Firing unbounded parallel HTTP requests causes subrequest limit exceptions (`Too many subrequests`).
- **Missing Wrangler Types**: Developing without running `wrangler types` leaves `env` un-typed, leading to runtime undefined errors when accessing bindings.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npx wrangler types` to generate accurate TypeScript interfaces for all D1, KV, R2, and secret bindings declared in your configuration.
- **Required (L2 Controlled / Pre-Commit)**:
  `npx wrangler deploy --dry-run` to validate bundle compilation, compatibility flags, route syntax, and asset bindings.
- **Extended (L3 Release / CI)**:
  `npm test` (using `@cloudflare/vitest-pool-workers`) to execute integration tests inside an authentic local workerd runtime.
