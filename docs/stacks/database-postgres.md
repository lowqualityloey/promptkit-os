---
name: database-postgres
category: database
version: 1
token_budget: 1500
activation:
  manifests:
    - migrations/
    - db/migrations/
    - alembic.ini
    - prisma/schema.prisma
    - drizzle.config.ts
verification:
  fast:
    - psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c 'select 1'
  required:
    - run the repository migration validation command
  extended:
    - run the repository database integration suite
invariants:
  - Treat applied migration files as immutable; add a new forward migration.
  - Index foreign keys and query predicates using measured workload evidence.
  - Bound transactions and inspect query plans before changing hot paths.
anti_patterns:
  - N+1 queries and unbounded result sets.
  - Editing historical migrations or relying on implicit casts in critical predicates.
  - Running destructive DDL without a rollback or forward-recovery plan.
---
# PostgreSQL Playbook

Confirm PostgreSQL from connection configuration, driver, or migration syntax; generic migration folders alone identify a database candidate, not its engine.

## 1. Architectural Invariants

- Add schema changes as new migrations. Never rewrite a migration that may have reached a shared environment.
- Make constraints authoritative in the database. Keep application validation for useful errors, not as a substitute for constraints.
- Index referencing foreign keys and common filter/order combinations; use `EXPLAIN (ANALYZE, BUFFERS)` with representative safe data before claiming a plan improved.
- Keep transactions short. Use keyset pagination for large/changing datasets and bound batch writes.
- Use parameterized SQL and explicit ownership/tenant predicates. Review RLS policies and remember privileged roles may bypass them.

## 2. Critical Anti-Patterns & Pitfalls

- Do not hide N+1 access behind ORM navigation loops; inspect query counts and batch or join deliberately.
- Do not use `SELECT *` for stable API projections or load unbounded tables into memory.
- Do not mutate applied migration history or run destructive DDL without a recovery path.
- Do not assume a successful migration in a local database proves production lock impact is safe.

## 3. Tiered Verification Commands

Fast: use the configured client for `select 1`; required: run the migration tool's validate/check command; extended: run repository database integration tests against an isolated PostgreSQL instance. Discover exact commands and never point verification at production.
