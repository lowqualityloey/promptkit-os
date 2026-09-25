# PromptKit OS Implementation Recipes

Cross-cutting architectural boundary patterns, operational security invariants, and worked implementation examples.

Recipes provide concrete, production-grade solutions for specific architectural seams. Unlike monolithic documentation or heavy framework rules, recipes are loaded **just-in-time (JIT)** by owning workflows or developers, preserving static prompt token headroom.

---

## 1. Recipe Catalog Matrix

| Recipe | Boundary / Domain | Category | Token Budget | Owning Workflow | Description |
|:---|:---|:---|:---|:---|:---|
| [`auth-session.md`](auth-session.md) | Auth & Session Security | `recipe` | $\le$ 1,500 tok | `workflows/auth.md` | Cookie vs Bearer lifecycles, route guards, and refresh token rotation. |
| [`auto-phrase-boundary-sheet.md`](auto-phrase-boundary-sheet.md) | Automation & Routing | `recipe` | $\le$ 1,500 tok | `workflows/auto.md` | Plain-English phrase to `pk:auto` stop-boundary mapping for `PROMPTKIT.md`. |
| [`auto-wave-pause-resume.md`](auto-wave-pause-resume.md) | Automation & Checkpoints | `recipe` | $\le$ 1,500 tok | `workflows/auto.md` | Worked Turbo wave-boundary pause, checkpoint, and human resume with halt-block schema. |
| [`auto-waves-preflight-checklist.md`](auto-waves-preflight-checklist.md) | Automation & Preflight | `recipe` | $\le$ 1,500 tok | `workflows/onboard.md`, `workflows/profile.md` | Pre-flight eligibility checklist for `pk:auto` Turbo wave execution (`--waves N`). |
| [`env-validation.md`](env-validation.md) | Configuration & Preflight | `recipe` | $\le$ 1,500 tok | `workflows/debug.md`, `workflows/onboard.md` | Boot-time preflight validation, client vs server boundaries, and type-safe environment schemas. |
| [`form-mutations.md`](form-mutations.md) | API & Mutation Contracts | `recipe` | $\le$ 1,500 tok | `workflows/api.md` | Standard Action Envelopes, schema validation, optimistic rollbacks, and mutation idempotency. |
| [`test-isolation.md`](test-isolation.md) | Testing & Network Seams | `recipe` | $\le$ 1,500 tok | `workflows/test.md` | Network boundary isolation (MSW), transactional database rollbacks, and deterministic test fixtures. |
| [`webhook-idempotency.md`](webhook-idempotency.md) | API & Webhook Ingestion | `recipe` | $\le$ 1,500 tok | `workflows/api.md` | Raw body preservation, timing-safe HMAC verification, and idempotency ledgers. |

---

## 2. Architectural Intake Criteria

PromptKit OS separates operational guidance into three distinct tiers:

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

### When to Write a Recipe vs. Playbook vs. Rule

- **Write a Rule** (`rules/`):
  - When the invariant is **universal** across every interaction, file, and tool execution (e.g. secret redaction, accidental data loss prevention, non-destructive file operations).
  - Rules are permanently present or referenced in agent directives.
- **Write a Stack Playbook** (`docs/stacks/*.md`):
  - When the guidance is **technology stack-specific** and triggered by repository manifests (e.g. `package.json` $\rightarrow$ `fullstack-nextjs.md`, `Cargo.toml` $\rightarrow$ `systems-rust.md`).
  - Playbooks declare manifest triggers, three-tier verification commands (`fast`, `required`, `extended`), and stack anti-patterns.
- **Write a Recipe** (`docs/recipes/*.md`):
  - When the problem is a **cross-cutting implementation pattern or operational boundary** that applies across multiple tech stacks or specialized sub-flows (e.g. webhook HMAC verification, environment schemas, session storage).
  - Recipes are referenced via single-line links from owning workflows (`workflows/auth.md`, `workflows/api.md`, `workflows/debug.md`, etc.) and loaded strictly when needed.

---

## 3. Recipe Schema & Quality Contract

All recipes must adhere to the Playbook & Recipe Contract and pass verification:

### Required YAML Frontmatter

```yaml
---
name: <slug>
category: recipe
version: 1
token_budget: 1500
description: <concise summary of the architectural boundary>
---
```

### Structural Conventions

1. **Top-Level H1 Heading**: `# <Title> Recipe`
2. **Opening Abstract**: 1–2 sentences defining the architectural boundary and invariants.
3. **Section 1: Non-Negotiable Invariants**: Bulleted list of non-negotiable operational principles.
4. **Section 2: Implementation Patterns & Worked Examples**: Concise, idiomatic code examples (TypeScript/Python/SQL) demonstrating compliant implementation.
5. **Section 3: Anti-Patterns to Avoid**: Explicit pitfalls with explanations of failure modes.

### Token Ceiling Invariant

- **Hard Budget**: Every recipe file must be $\le$ **1,500 tokens** (calculated via the canonical PromptKit `(bytes + 2) / 4` convention).
- **Validation**: Enforced across Linux and Windows in CI:
  ```bash
  bash scripts/tests/run-playbook-contract-tests.sh
  pwsh -File scripts/tests/run-playbook-contract-tests.ps1
  ```

---

## 4. Backlog & Prioritized Gap Candidates

The following cross-cutting boundaries are prioritized for upcoming recipe additions:

1. **Rate Limiting & Tiered Throttling**: Sliding window log, token bucket algorithms, and Redis/memory multi-tenant throttles.
2. **Optimistic Locking & Concurrency Control**: Version columns, ETags, and lost update prevention across distributed updates.
3. **Background Job Dispatch & Dead-Letter Queues**: Outbox pattern, at-least-once delivery, exponential backoff, and poison pill handling.
4. **Tenant Data Isolation**: Row-Level Security (RLS) enforcement, schema-per-tenant vs shared-schema boundaries, and context propagation.
