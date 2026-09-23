---
name: deploy-vercel
category: cloud
version: 1
token_budget: 1500
activation:
  manifests:
    - vercel.json
verification:
  fast:
    - npx vercel build --dry-run
  required:
    - npm run build
  extended:
    - npx vercel env pull .env.test
    - npm test
invariants:
  - "Serverless functions must remain stateless and bounded within configured execution timeouts"
  - "Edge Middleware bundle size must stay strictly within the 1MB uncompressed limit"
  - "Segregate environment variables explicitly across Production, Preview, and Development environments"
  - "Cache static assets and ISR pages with immutable headers and revalidation tags"
  - "Route database connections through connection poolers or serverless-adapted drivers"
anti_patterns:
  - "Spawning persistent background intervals, WebSockets, or unawaited promises inside serverless functions"
  - "Storing files or state in the local container filesystem expecting persistence across requests"
  - "Importing heavyweight server-side libraries into Edge Middleware causing bundle size limit errors"
  - "Exhausting database connections by establishing raw unpooled connection pools on each serverless invocation"
---

# Vercel Cloud Deployment Playbook

Operational guidelines, invariants, and failure modes for serverless, edge, and Next.js applications deployed to Vercel.

## 1. Architectural Invariants

- **Stateless Serverless Execution**: Serverless route handlers and API endpoints spin up dynamically and freeze or terminate upon completion. Never rely on in-memory global state, module singletons, or unawaited background execution promises surviving between requests.
- **Edge Middleware Limits**: Edge functions and middleware execute on Vercel's global edge network and have a strict 1MB uncompressed code size ceiling. Avoid importing heavy utility packages (e.g. Prisma engines, full AWS SDKs) into middleware.
- **Environment Isolation**: Maintain strict segregation between Production, Preview, and Development environment variables. Sensitive production webhook signing keys or database URLs must never be exposed to branch preview environments where test builds run.
- **Connection Pooling Mandate**: Serverless functions scale elastically with incoming traffic. If each function instance opens a direct connection to a relational database, Postgres connection pools exhaust instantly (`too many clients already`). Always utilize connection poolers (e.g. Prisma Accelerate, PgBouncer, Supabase Pooler port 6543, Neon connection strings).
- **Static & Edge Caching Discipline**: Leverage Vercel CDN edge caching via `Cache-Control` headers, `stale-while-revalidate`, or Next.js Incremental Static Regeneration (ISR) to protect database layers from redundant read pressure.

## 2. Critical Anti-Patterns & Pitfalls

- **Unawaited Background Work**: Executing asynchronous tasks (`fetch()`, analytics logging) after sending the HTTP response without `waitUntil()` causes the runtime environment to freeze immediately, abruptly terminating the incomplete promise.
- **Exceeding Lambda Duration**: Configuring long-running database migrations or synchronous heavy tasks in serverless route handlers triggers `FUNCTION_INVOCATION_TIMEOUT` (duration limits depend on the Vercel plan and Next.js version; check current Vercel documentation). Offload asynchronous tasks to background message queues (e.g. QStash, Inngest).
- **Hardcoding Production URLs**: Relying on static production URLs inside preview branches breaks preview testing. Use `process.env.VERCEL_URL` or `VERCEL_BRANCH_URL` for dynamic domain resolution in preview environments.
- **Local Filesystem Persistence**: Writing files to `/tmp` and expecting them to be accessible on subsequent user requests fails because subsequent invocations may run in entirely different serverless instances.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npx vercel build --dry-run` to validate routing rules, headers, redirects, and rewrites in `vercel.json`.
- **Required (L2 Controlled / Pre-Commit)**:
  `npm run build` to verify that all serverless function bundles compile within size limits and static assets build cleanly.
- **Extended (L3 Release / CI)**:
  `npx vercel env pull .env.test` and `npm test` to validate full integration behavior against configured environment schemas.
