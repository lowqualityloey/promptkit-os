---
name: web-astro
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - astro.config.mjs
    - astro.config.ts
    - astro.config.js
    - astro.config.cjs
verification:
  fast:
    - npx astro check
  required:
    - npx astro build
  extended:
    - npm run lint
    - npm test
invariants:
  - "Default to Zero-JS components — render static HTML at build time unless an explicit client directive is declared"
  - "Hydration boundaries require explicit client directives (client:load, client:idle, client:visible, client:media, client:only)"
  - "Do not apply client:load to below-the-fold or off-screen components — prefer client:visible or client:idle"
  - "Content Collections must declare type-safe schemas using defineCollection and z from astro:content"
  - "Server secrets and database clients must never be passed as props into client-hydrated framework islands"
anti_patterns:
  - "Indiscriminately adding client:load to every interactive island"
  - "Querying raw markdown files via fs without Content Collections validation"
  - "Passing server secrets or private environment variables to client island props"
  - "Relying on framework-specific Context across distinct Astro islands"
---

# Astro Web Framework Playbook

Operational guidelines, invariants, and failure modes for Astro content-driven, island-architecture, and hybrid/SSR web applications.

## 1. Architectural Invariants

- **Zero-JS by Default**: Treat every component as pure static templating by default. `.astro` components compile entirely to static HTML and CSS with zero client-side JavaScript runtime overhead.
- **Explicit Hydration Boundaries**: Introduce client-side JavaScript strictly through explicit island directives:
  - `client:load`: High-priority interactive elements immediately visible on first paint (e.g. mobile navigation menus, top search bars).
  - `client:idle`: Lower-priority interactive widgets that can hydrate after main document load (e.g. newsletter signups, analytics trackers).
  - `client:visible`: Below-the-fold components that should hydrate only when entering the viewport (e.g. comment widgets, media embeds).
  - `client:only`: Components that strictly require browser-only globals (`window`, `localStorage`, WebGL) and cannot render on the server.
- **Content Collections Validation**: All structured content (Markdown, MDX, JSON, YAML) must reside in Content Collections (`src/content/`) governed by strict schemas via `defineCollection` and `z` from `astro:content`. Never read unstructured markdown files directly from disk via Node `fs` without schema validation.
- **Server vs. Client Island Isolation**: Framework components (React, Vue, Svelte, Solid) hydrated on the client must never receive server secrets, private database clients, or unredacted API tokens as props. Server-only logic belongs in Astro frontmatter or API route handlers (`src/pages/api/*`).
- **Deterministic Asset Optimization**: Local images must be rendered using `<Image />` or `<Picture />` from `astro:assets` to enforce layout-shift prevention, automatic modern format conversion (WebP/AVIF), and width/height aspect ratio attributes.

## 2. Critical Anti-Patterns & Pitfalls

- **`client:load` Everywhere**: Applying `client:load` to all components turns Astro into an inefficient SPA bundle, defeating the performance benefits of the islands architecture.
- **Cross-Island Context Sharing**: Attempting to share state across distinct islands using framework-specific context providers (such as React Context) fails because each island mounts as an independent root. Use lightweight external state managers (e.g. `nanostores`) or native custom events instead.
- **Exposing Server Secrets in Island Props**: Passing `import.meta.env.SECRET_KEY` into `<InteractiveWidget secret={import.meta.env.SECRET_KEY} client:load />` bakes sensitive credentials directly into the client HTML payload.
- **Uncontrolled Dynamic SSR**: In hybrid or server output mode, leaving dynamic database queries unmemoized or un-cached causes high database connection pool pressure under load.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npx astro check` to validate component templates, Content Collection schemas, and TypeScript types.
- **Required (L2 Controlled / Pre-Commit)**:
  `npx astro build` to assert static page generation, asset optimization, and server adapter compilation.
- **Extended (L3 Release / CI)**:
  `npm run lint` and `npm test` to verify code hygiene, accessibility, and critical user journeys.
