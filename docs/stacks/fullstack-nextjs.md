---
name: fullstack-nextjs
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - next.config.js
    - next.config.mjs
    - next.config.ts
    - package.json
verification:
  fast:
    - npm run type-check
  required:
    - npm run build
  extended:
    - npm run lint
    - npm test
invariants:
  - "Default to React Server Components — push 'use client' strictly to the leaves of the tree"
  - "Never import server-only code, database clients, or secrets into client component modules"
  - "Next.js 15+ dynamic request APIs (params, searchParams, cookies, headers) must be awaited"
  - "Route Handlers must return deterministic Response/NextResponse objects with explicit HTTP status"
  - "Data mutations must revalidate paths or tags explicitly using revalidatePath or revalidateTag"
anti_patterns:
  - "Marking layout or page root components with 'use client'"
  - "Fetching data in client components without a dedicated caching layer or abort signal"
  - "Prefixing private API tokens or server environment variables with NEXT_PUBLIC_"
  - "Passing unvalidated client inputs directly from Server Actions into database queries"
---

# Next.js Fullstack Playbook

Operational guidelines, invariants, and failure modes for Next.js App Router applications.

## 1. Architectural Invariants

- **Server-First Boundary**: Treat every component as a Server Component by default. Introduce `"use client"` only when interactive state (`useState`, `useReducer`), browser APIs (`window`, `localStorage`), or event listeners (`onClick`, `onChange`) are strictly required.
- **Data Fetching Colocation**: Fetch data directly inside Server Components using async/await. Do not create intermediate Route Handlers simply to feed same-application Server Components.
- **Server-Only Boundary Guard**: Mark server utility modules and database access layers with `import 'server-only'`. This causes immediate build-time failures if server code is inadvertently imported into a client module.
- **Next.js 15+ Dynamic Request APIs**: Dynamic APIs (`cookies()`, `headers()`, `params`, and `searchParams` in page/layout props) are asynchronous in Next.js 15+. Always await them prior to accessing properties.
- **Mutation Revalidation**: Every Server Action performing database mutations must trigger `revalidatePath()` or `revalidateTag()` to purge stale client router cache entries before completing.

## 2. Critical Anti-Patterns & Pitfalls

- **Root Client Components**: Declaring `"use client"` at the top of a `layout.tsx` or `page.tsx` converts the entire subtree into client rendering, destroying streaming SSR benefits and bloating bundle size.
- **Leaking Secrets via NEXT_PUBLIC_**: Variables prefixed with `NEXT_PUBLIC_` are inlined into the client bundle at build time. Secrets (Stripe secret keys, database credentials) must NEVER have this prefix.
- **Unbounded Client Fetching**: Performing `fetch` inside `useEffect` on the client causes waterfall network requests and flash-of-unstyled-content. Prefer Server Components or SWR/TanStack Query with hydration boundaries.
- **Silent Action Failures**: Swallowing errors inside Server Actions without returning structured error envelopes (`{ error: string, data: null }`) leaves the UI frozen in an optimistic state.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npm run type-check` (or `npx tsc --noEmit`) to verify TypeScript props, async signatures, and imports.
- **Required (L2 Controlled / Pre-Commit)**:
  `npm run build` to validate server/client module bundling, static page generation, and export safety.
- **Extended (L3 Release / CI)**:
  `npm run lint` and `npm test` to assert code hygiene and end-to-end user journeys.
