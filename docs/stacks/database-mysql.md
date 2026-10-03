---
name: database-mysql
category: database
version: 1
token_budget: 1500
activation:
  manifests:
    - .env.example
    - application.yml
    - application.properties
    - settings.py
    - compose.yaml
    - docker-compose.yml
    - knexfile.js
    - prisma/schema.prisma
    - drizzle.config.ts
verification:
  fast:
    - mysql "$DATABASE_URL" -e 'select 1'
  required:
    - run the repository migration validation command
  extended:
    - run the repository database integration suite
invariants:
  - Treat applied migration files as immutable; add a new forward migration.
  - Check indexes against predicates, ordering, and leftmost-prefix behavior.
  - Bound transactions and account for DDL lock and implicit-commit behavior.
anti_patterns:
  - N+1 queries and unbounded result sets.
  - Editing historical migrations or relying on silent coercion.
  - Running destructive schema changes without recovery evidence.
---
# MySQL Playbook

Confirm an active module datasource using an explicit MySQL URL (`mysql://`, `jdbc:mysql:`, or `jdbc:mariadb:` when the target is MySQL-compatible), ORM/provider value (`mysql`), dialect-specific migration configuration, or a MySQL service image used by the module's integration environment. Knex, Prisma, Drizzle, compose files, and migration directories are candidate paths: inspect their content and active references. An installed driver or generic `migrations/` folder alone is not proof. Prefer the module's configured engine; if PostgreSQL and MySQL signals conflict, report that datasource as unconfirmed. Separate active modules may select both and must record scope. If the project uses a managed MySQL-compatible service, follow its existing provider playbook as well.

## 1. Architectural Invariants

- Treat applied migrations as immutable; add a new forward migration and record any required backfill separately.
- Use constraints and explicit transaction boundaries. Check whether the target DDL is online-safe for the deployed MySQL version and storage engine.
- Design composite indexes for actual predicates and ordering. MySQL generally uses the leftmost prefix; validate with representative `EXPLAIN` output.
- Parameterize values and explicitly constrain tenant ownership. Use bounded pagination and batch sizes.
- Size connection pools against database limits and the number of application replicas.

## 2. Critical Anti-Patterns & Pitfalls

- Do not execute one query per ORM row or load unbounded relations.
- Do not assume DDL is transactional or lock-free; plan a forward recovery path.
- Do not depend on permissive string/number coercion for identifiers or security predicates.
- Do not edit migration history already applied outside a disposable local database.

## 3. Tiered Verification Commands

Fast: use the configured client for `select 1`; required: run the migration tool's validate/check command; extended: run integration tests against isolated MySQL. Discover repository-specific commands and never verify by mutating production data.
