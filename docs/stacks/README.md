# PromptKit OS Stack Playbooks

Curated operational guidelines, manifest triggers, tiered verification commands, and architectural invariants for supported technology stacks.

Stack playbooks are activated **just-in-time (JIT)** when detectable project manifests (`package.json`, `Cargo.toml`, `go.mod`, etc.) are identified in a repository. They provide agents and developers with non-negotiable architectural invariants and standard verification commands without loading monolithic framework manuals into static prompt context.

---

## 1. Stack Playbook Catalog

| Playbook | Category | Manifest Triggers | Token Budget | Verification (`fast` / `required` / `extended`) |
|:---|:---|:---|:---|:---|
| [`cli-python.md`](cli-python.md) | `cli` | `pyproject.toml`, `requirements.txt`, `setup.py` | $\le$ 1,500 tok | `ruff check` / `pytest` / `mypy` |
| [`database-supabase.md`](database-supabase.md) | `database` | `supabase/config.toml`, `supabase/migrations/` | $\le$ 1,500 tok | `supabase db lint` / `supabase test db` / `supabase db diff` |
| [`database-turso.md`](database-turso.md) | `database` | `turso.json`, `schema.sql`, `drizzle.config.ts` | $\le$ 1,500 tok | `turso db show` / `turso quickstart` / `npm run test:db` |
| [`deploy-cloudflare.md`](deploy-cloudflare.md) | `cloud` | `wrangler.toml`, `wrangler.json`, `wrangler.jsonc` | $\le$ 1,500 tok | `npx wrangler types` / `npx wrangler deploy --dry-run` / `npm test` |
| [`deploy-docker.md`](deploy-docker.md) | `cloud` | `Dockerfile`, `docker-compose.yml`, `compose.yml` | $\le$ 1,500 tok | `docker compose config` / `docker build` / `trivy image` |
| [`deploy-render.md`](deploy-render.md) | `cloud` | `render.yaml`, `Dockerfile` | $\le$ 1,500 tok | `render blueprints validate` / `docker build` / `npm test` |
| [`deploy-vercel.md`](deploy-vercel.md) | `cloud` | `vercel.json`, `next.config.js`, `package.json` | $\le$ 1,500 tok | `npx vercel pull` / `npx vercel build` / `npm test` |
| [`fullstack-nextjs.md`](fullstack-nextjs.md) | `web` | `next.config.js`, `next.config.mjs`, `next.config.ts` | $\le$ 1,500 tok | `npm run type-check` / `npm run build` / `npm test` |
| [`mobile-expo.md`](mobile-expo.md) | `mobile` | `app.json`, `app.config.js`, `app.config.ts` | $\le$ 1,500 tok | `npx expo-doctor` / `npx expo export` / `npm test` |
| [`mobile-flutter.md`](mobile-flutter.md) | `mobile` | `pubspec.yaml` | $\le$ 1,500 tok | `flutter analyze` / `flutter test` / `flutter build` |
| [`systems-go.md`](systems-go.md) | `systems` | `go.mod`, `go.sum` | $\le$ 1,500 tok | `go vet` / `go test -race ./...` / `golangci-lint run` |
| [`systems-rust.md`](systems-rust.md) | `systems` | `Cargo.toml`, `Cargo.lock` | $\le$ 1,500 tok | `cargo check` / `cargo test` / `cargo clippy -- -D warnings` |
| [`web-astro.md`](web-astro.md) | `web` | `astro.config.mjs`, `astro.config.ts`, `astro.config.js` | $\le$ 1,500 tok | `npx astro check` / `npx astro build` / `npm test` |

---

## 2. Architectural Intake Criteria

PromptKit OS organizes technical guidance into three complementary tiers:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PROMPTKIT GUIDANCE TIERS                        │
├───────────────────┬──────────────────────┬─────────────────────────────┤
│ Tier              │ Location             │ Activation & Scope          │
├───────────────────┼──────────────────────┼─────────────────────────────┤
│ 1. Rules          │ rules/*.md           │ Global, non-negotiable      │
│                   │                      │ invariants in directives    │
├───────────────────┼──────────────────────┼─────────────────────────────┤
│ 2. Playbooks      │ docs/stacks/*.md     │ Stack-specific; activated   │
│                   │                      │ JIT by project manifests    │
├───────────────────┼──────────────────────┼─────────────────────────────┤
│ 3. Recipes        │ docs/recipes/*.md    │ Cross-cutting seams; loaded │
│                   │                      │ on-demand by workflows      │
└───────────────────┴──────────────────────┴─────────────────────────────┘
```

### When to Write a Playbook vs. Recipe vs. Workflow vs. Rule

- **Write a Rule** (`rules/`):
  - When the invariant is **universal and binding across all tasks, repositories, and languages** (e.g. secret redaction, accidental data loss prevention, non-destructive file operations).
  - Rules are permanently mounted in agent setup directives.
- **Write a Stack Playbook** (`docs/stacks/*.md`):
  - When guidance is **bound to a specific technology stack or framework ecosystem** (Next.js, Astro, Rust, Go, Expo, Supabase).
  - Must have **deterministic manifest triggers** (files like `astro.config.mjs`, `go.mod`, `Cargo.toml`).
  - Must define **three verification tiers** (`fast`, `required`, `extended`) to hook into Level 0–Level 3 execution gates.
- **Write a Recipe** (`docs/recipes/*.md`):
  - When the solution addresses a **cross-cutting architectural boundary** or security pattern that spans multiple frameworks (e.g. webhook HMAC verification, cookie auth rotation, environment validation, MSW test mocking).
  - Recipes are loaded on-demand by owning workflows (`workflows/auth.md`, `workflows/api.md`, `workflows/debug.md`).
- **Write a Workflow** (`workflows/*.md`):
  - When defining a **developer operational lifecycle or orchestration protocol** (`pk:plan`, `pk:fix`, `pk:ship`, `pk:debug`, `pk:test`).
  - Workflows govern process phases, verification gates, and artifact deliverables.

---

## 3. Playbook Schema & Quality Contract

All stack playbooks are strictly gated in CI by twin validators:
```bash
bash scripts/tests/run-playbook-contract-tests.sh
pwsh -File scripts/tests/run-playbook-contract-tests.ps1
```

### Required Frontmatter Schema

```yaml
---
name: <stack-slug>
category: web | database | cloud | mobile | systems | cli
version: 1
token_budget: 1500
activation:
  manifests:
    - <trigger-filename>
verification:
  fast:
    - <sub-second command>
  required:
    - <standard test/build command>
  extended:
    - <lint/suite command>
invariants:
  - "<Non-negotiable architectural invariant 1>"
  - "<Non-negotiable architectural invariant 2>"
anti_patterns:
  - "<Critical pitfall to avoid 1>"
  - "<Critical pitfall to avoid 2>"
---
```

### Invariant Rules for Playbook Authors

1. **Clean Array Items**: Prohibit shell chaining operators (`&&`, `||`, `;`) in verification arrays. Each command must be a discrete array item.
2. **Strict Token Ceiling**: Hard ceiling $\le$ **1,500 tokens** (measured via `(bytes + 2) / 4`).
3. **Structured Body**:
   - `## 1. Architectural Invariants`: Detailed operational principles.
   - `## 2. Critical Anti-Patterns & Pitfalls`: Failure modes and remedies.
   - `## 3. Tiered Verification Commands`: Mapping of fast/required/extended tiers to L0–L3 workflow gates.

---

## 4. Gap Matrix & Demand-Driven Roadmap

The following stacks are prioritized for upcoming playbook additions:

### Immediate Wave
1. [`web-astro.md`](web-astro.md) (Shipped): Content-driven, islands architecture, and zero-JS baseline.
2. [`deploy-docker.md`](deploy-docker.md) (Shipped): Universal containerization, multi-stage builds, and non-root execution.
3. `api-fastapi.md` (or `api-python.md`): Python backend, Pydantic v2 schemas, and async route handlers.
4. `api-node.md`: Node.js server frameworks (Express / Hono / Fastify) and type-safe routing.

### Planned Expansions (Demand-Driven)
- **CMS Layer**: `cms-wordpress.md` (`wp-config.php`, theme/plugin headers, nonce verification, `$wpdb->prepare()`, capability checks).
- **Web**: `web-sveltekit.md`, `web-vue-nuxt.md`, `web-remix.md`.
- **Backend / Systems**: `backend-elixir-phoenix.md`, `systems-csharp-dotnet.md`.
