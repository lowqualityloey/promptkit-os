---
name: api-node
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - package.json
    - tsconfig.json
    - nest-cli.json
verification:
  fast:
    - npm run lint
    - npx tsc --noEmit
  required:
    - npm test
  extended:
    - npm run test:coverage
invariants:
  - "Validate all external request bodies, parameters, and query strings using runtime schemas (Zod/TypeBox) before processing"
  - "Preserve event loop responsiveness by avoiding synchronous CPU-heavy or blocking I/O calls in route handlers"
  - "Implement graceful shutdown handlers for SIGTERM and SIGINT to drain in-flight requests and close database pools"
  - "Validate environment variables at startup against a strict typed schema, crashing fast on invalid configuration"
  - "Catch all unhandled operational errors in global middleware, returning structured error envelopes without leaking stack traces"
  - "Decouple routing, business logic, and database access layers to ensure testability and prevent query cascades"
anti_patterns:
  - "Trusting raw request payloads without validation, exposing the service to mass-assignment and prototype-pollution"
  - "Using blocking synchronous APIs (fs.readFileSync, crypto.pbkdf2Sync, bcrypt.hashSync) on the main event loop"
  - "Swallowing unhandled promise rejections or uncaught exceptions without structured logging or controlled process restart"
  - "Calling process.exit() immediately on shutdown signals without awaiting in-flight connection draining"
  - "Storing request-scoped mutable data in module-level singletons or global variables, leaking state across concurrent requests"
  - "Scattering raw process.env reads across domain modules instead of centralizing access behind a validated configuration module"
---

# Node.js Server & API Architecture Playbook

Operational guidelines, event loop invariants, schema validation, and verification tiers for Node.js API services (Hono, Fastify, Express, NestJS).

## 1. Architectural Invariants

- **Runtime Schema Boundary Validation**: Every incoming HTTP request boundary (body, query, route params, headers) must be validated against a deterministic runtime schema (such as Zod, Valibot, or TypeBox) before reaching domain controllers. Type casting or trusting `req.body as Payload` is forbidden. In Fastify and Hono, leverage compiled schemas (`TypeBox` or `@hono/zod-validator`) to maximize throughput and ensure automatic OpenAPI serialization.
- **Event Loop Non-Blocking Discipline**: Node.js executes application JavaScript on a single-threaded event loop. Handlers must never invoke synchronous blocking filesystem calls (`fs.readFileSync`), CPU-bound operations (synchronous cryptographic hashing, image processing, massive JSON parsing), or long-running CPU loops. Offload CPU-heavy tasks to `worker_threads`, background message queues, or native asynchronous libuv bindings.
- **Graceful Shutdown & Connection Draining**: Applications must trap POSIX termination signals (`SIGTERM`, `SIGINT`). Upon receipt, stop accepting new incoming HTTP connections (`server.close()`), wait for in-flight requests to complete within a bounded grace period (e.g. 15–30s), flush buffered metrics and logs, and cleanly close database connection pools (Prisma, Drizzle, pg) before exiting with code 0.
- **Boot-Time Environment Schema Validation**: Parse and validate `process.env` against an explicit schema (e.g. `z.object({...})`) during the bootstrap phase before opening the network listener. Crash the process immediately with descriptive diagnostic logs if mandatory database URLs, secret keys, or port configurations are missing or malformed.
- **Predictable Error Envelopes**: Route all unhandled errors through a centralized error-handling middleware. Transform operational domain errors into standard JSON response structures with appropriate HTTP status codes (400, 401, 403, 404, 409, 422). Suppress raw exception messages, internal database error codes, and stack traces from production client responses.

## 2. Critical Anti-Patterns & Pitfalls

- **Unvalidated Mass Assignment**: Passing unvalidated `req.body` directly into database `insert` or `update` operations permits attackers to overwrite administrative flags, permissions, or foreign keys.
- **Event Loop Freezing**: Running `bcrypt.hashSync()` or reading large assets with `fs.readFileSync()` stops the entire Node server from servicing any concurrent network traffic during execution.
- **Zombie Process Hard Termination**: Failing to handle `SIGTERM` causes container orchestrators (Kubernetes, Docker, ECS) to brutally sever active user connections via `SIGKILL` after the shutdown timeout.
- **Global Request State Leaks**: Storing user context, tenant IDs, or auth tokens on global variables rather than using scoped request contexts or `AsyncLocalStorage` causes cross-tenant request bleeding under high concurrency.
- **Silent Exception Swallowing**: Using empty `catch (err) {}` blocks or failing to listen to `process.on('unhandledRejection')` results in hung requests and invisible data corruption.

## 3. Tiered Verification Commands

- **Fast Tier (Pre-Commit / Pre-Build)**:
  - `npm run lint`: Validates code quality, lint rules, and import boundaries.
  - `npx tsc --noEmit`: Performs strict static type checking without generating build artifacts.
- **Required Tier (CI PR Gate / Pre-Merge)**:
  - `npm test`: Runs unit, integration, and route handler test suites.
- **Extended Tier (Nightly / Release Pipeline)**:
  - `npm run test:coverage`: Executes the full test suite with Istanbul/c8 code coverage metrics to assert coverage thresholds.
