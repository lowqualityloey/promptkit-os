---
name: database-turso
category: database
version: 1
token_budget: 1500
activation:
  manifests:
    - drizzle.config.ts
    - schema.prisma
    - turso.json
verification:
  fast:
    - turso db show
  required:
    - npm run db:migrate
  extended:
    - npm run db:check
    - npm test
invariants:
  - "Embedded replicas are read-only — all write queries must route to the primary database"
  - "Enforce PRAGMA foreign_keys = ON on every connection"
  - "Database migrations must follow Expand-Contract methodology and remain strictly idempotent"
  - "Keep interactive transactions short-lived to prevent write serialization bottlenecks"
  - "Model booleans, dates, and JSON explicitly with application-layer schema validation"
anti_patterns:
  - "Issuing write mutations directly against a local replica file without write-delegation configured"
  - "Relying on SQLite default foreign key behavior which permits orphaned relational records"
  - "Holding interactive write transactions open across external HTTP calls or slow asynchronous tasks"
  - "Executing destructive ALTER TABLE DROP COLUMN migrations without intermediate compatibility phases"
---

# Turso & libSQL Database Playbook

Operational guidelines, invariants, and failure modes for Turso and distributed libSQL databases.

## 1. Architectural Invariants

- **Write Routing Architecture**: In Turso embedded replica setups, local SQLite database replicas operate strictly in read-only mode for sub-millisecond local reads. Every mutating query (`INSERT`, `UPDATE`, `DELETE`, `CREATE`) must be directed to the primary database URL via client write-delegation or a dedicated primary client instance.
- **Explicit Foreign Key Enforcement**: SQLite disables foreign key constraint checks by default. Every connection pool initializer must execute `PRAGMA foreign_keys = ON;` immediately upon establishing a session.
- **Idempotent Migration Sequencing**: All database migrations must execute idempotently using `CREATE TABLE IF NOT EXISTS`, conditional column additions, or tracking tables (e.g. Drizzle/Prisma migration journals). Never execute raw, untracked DDL against production databases.
- **Expand-Contract Schema Evolution**: When renaming or dropping columns, follow the 3-phase Expand-Contract pattern: (1) Add new column, (2) Backfill and update application code to write to both, (3) Deprecate and drop old column after old application code has retired.
- **Data Type Modeling**: SQLite utilizes dynamic typing. Protect data boundaries by strictly defining data types (booleans stored as integers `0/1`, timestamps stored as ISO-8601 strings or epoch integers) with Zod or ORM schema parsers.

## 2. Critical Anti-Patterns & Pitfalls

- **Direct Replica Writes**: Attempting to write directly to an embedded replica SQLite database file without configuring remote URL synchronization throws `SQLITE_READONLY` errors at runtime.
- **Unbounded Serialization Locks**: SQLite and libSQL serialize all write operations via a single writer lock. Long-running transactions or transactions awaiting external API responses will block all concurrent write traffic.
- **Unindexed Filter Columns**: While SQLite reads are extremely fast, omitting indexes on frequently filtered columns (`WHERE user_id = ?`) forces full table scans that degrade edge memory performance.
- **Missing Migration Reversals**: Creating migration steps that cannot be rolled back safely without preserving pre-migration state.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `turso db show` to confirm connection reachability, replica status, and database health.
- **Required (L2 Controlled / Pre-Commit)**:
  `npm run db:migrate` (or local migration runner against libSQL memory instance) to verify DDL idempotency and foreign key integrity.
- **Extended (L3 Release / CI)**:
  `npm run db:check` and `npm test` to validate full application relational queries and schema parity.
