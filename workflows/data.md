# Data Workflow (Database Modeling, Indexing Strategy & Multi-Tenant Isolation)

## Fast Shorthand
Trigger anytime with: `pk:data` (or `/pk-data`)

## Mission
Guide the developer through production-grade relational database design, schema modeling, indexing strategies, multi-tenant Row-Level Security (RLS), transaction boundaries, and audit logging.

Prevent common data architecture failures: unindexed foreign keys, race conditions on concurrent writes, flawed soft-delete constraints, and multi-tenant security leaks.

---

## Preconditions
- Developer is designing a new entity, data model, relational schema, or database migration.
- Target storage directory: `./docs/data/` in the host project.
- Access to `.promptkit/templates/data-model-spec.md`.

---

## Core Data Engineering Pillars

### 1. Primary Keys and Relational Invariants
- **Primary Key Selection**:
  - Prefer time-sortable identifiers for high-write tables: **UUIDv7** or **CUID2**. They eliminate B-Tree page fragmentation caused by random UUIDv4 while remaining distributed and collision-free.
  - Use `BIGINT GENERATED ALWAYS AS IDENTITY` for purely internal append-only lookup tables where identifiers are never exposed to clients.
- **Foreign Key Constraints and Cascade Rules**:
  - Never omit foreign key constraints.
  - Default to `ON DELETE RESTRICT` for financial, user, and critical parent records to prevent accidental cascading data wipes.
  - Use `ON DELETE CASCADE` only for strictly owned child entities (for example, deleting a `Workspace` cascades to its `WorkspaceMembers`).
- **Domain Check Constraints**:
  - Enforce business invariants at the database layer, not solely in application code:
    ```sql
    CONSTRAINT check_positive_price CHECK (price_cents >= 0),
    CONSTRAINT check_valid_percentage CHECK (discount_percent BETWEEN 0 AND 100)
    ```

---

### 2. Indexing Strategy and Query Optimization
Indexes accelerate reads at the cost of write latency and disk memory. Every index must satisfy a specific query pattern:

1. **Foreign Key Indexing**:
   - In PostgreSQL, foreign key columns are **not** indexed by default. Always add explicit B-Tree indexes on foreign key columns (`user_id`, `workspace_id`, `organization_id`) to prevent table scans during JOINs and cascade checks.
2. **Composite Index Column Ordering (ESR Rule)**:
   - When building compound indexes for queries with multiple clauses, arrange columns in this order:
     1. **Equality (`=`)** columns first.
     2. **Sort (`ORDER BY`)** columns second.
     3. **Range (`>`, `<`, `BETWEEN`)** columns last.
   - Example: For `WHERE workspace_id = $1 AND status = 'ACTIVE' ORDER BY created_at DESC`:
     ```sql
     CREATE INDEX idx_tasks_workspace_status_created 
     ON tasks (workspace_id, status, created_at DESC);
     ```
3. **Covering Indexes (`INCLUDE`)**:
   - For frequent high-throughput reads, include projection columns to enable Index-Only Scans:
     ```sql
     CREATE INDEX idx_users_email_covering 
     ON users (email) INCLUDE (id, role, password_hash);
     ```
4. **Partial / Filtered Indexes**:
   - Save disk space and memory by indexing only the active subset of a table:
     ```sql
     CREATE INDEX idx_orders_unprocessed 
     ON orders (created_at) WHERE status IN ('PENDING', 'PROCESSING');
     ```

---

### 3. Multi-Tenant Isolation and Row-Level Security (RLS)
For applications using PostgreSQL or Supabase, enforce tenancy guarantees at the database engine level:

1. **Explicit Tenancy Column**:
   - Every tenant-scoped table must include an immutable `workspace_id` or `tenant_id` column.
2. **Enable Row-Level Security**:
   ```sql
   ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
   ALTER TABLE documents FORCE ROW LEVEL SECURITY;
   ```
3. **Defense-in-Depth Policies**:
   - Structure policies to read user tenancy from validated session claims rather than client-supplied inputs:
     ```sql
     -- Supabase / Postgres RLS policy pattern
     CREATE POLICY "Users can only read documents in their workspace"
     ON documents FOR SELECT
     USING (
       workspace_id IN (
         SELECT workspace_id FROM workspace_members 
         WHERE user_id = auth.uid()
       )
     );

     CREATE POLICY "Users can only insert documents into their workspace"
     ON documents FOR INSERT
     WITH CHECK (
       workspace_id IN (
         SELECT workspace_id FROM workspace_members 
         WHERE user_id = auth.uid() AND role IN ('ADMIN', 'EDITOR')
       )
     );
     ```
4. **Security Definer Function Precautions**:
   - Set an explicit `search_path` on all `SECURITY DEFINER` functions to prevent search-path hijacking:
     ```sql
     CREATE FUNCTION get_user_workspace() 
     RETURNS uuid LANGUAGE sql SECURITY DEFINER 
     SET search_path = public, pg_temp AS $$ ... $$;
     ```

---

### 4. Transaction Boundaries and Concurrency Control
1. **Explicit Transaction Blocks**:
   - Any business operation that alters more than one row or table must run within an atomic transaction.
2. **Preventing Race Conditions**:
   - **Pessimistic Locking**: When modifying inventory, balances, or single-seat claims, lock the target row before writing:
     ```sql
     SELECT * FROM accounts WHERE id = $1 FOR UPDATE;
     ```
   - **Optimistic Concurrency**: For document editing and collaborative records, use a version integer:
     ```sql
     UPDATE documents 
     SET content = $1, version = version + 1 
     WHERE id = $2 AND version = $3;
     ```
     If rows affected is 0, reject with a 409 Conflict.

---

### 5. Auditability and Deletion Semantics
1. **Standard Audit Columns**:
   - Every mutable table must include:
     - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
     - `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
     - `created_by UUID REFERENCES users(id)` (if applicable)
2. **Soft-Delete vs Tombstoning vs Hard Delete**:
   - **Soft-Delete (`deleted_at TIMESTAMPTZ NULL`)**:
     - *Caution*: Soft-deletes break standard unique constraints. If using soft-deletes, define unique indexes with a partial filter:
       ```sql
       CREATE UNIQUE INDEX uq_users_workspace_email 
       ON users (workspace_id, email) WHERE deleted_at IS NULL;
       ```
   - **Tombstoning / Status State Machine**:
     - Prefer explicit domain statuses (`ACTIVE`, `SUSPENDED`, `ARCHIVED`) over generic boolean deletion flags.
   - **Compliance Purges**:
     - For GDPR / CCPA right-to-be-forgotten requests, perform explicit hard deletions or cryptographic shredding of PII columns.

---

### 6. Real-Engine Testing vs In-Memory Blind Spots
- **Mandate Real PostgreSQL in CI & Project-Scoped Isolation**:
  - Never test database logic against in-memory SQLite when deploying to PostgreSQL. In-memory SQLite lacks row-level locking semantics (`FOR UPDATE`), handles JSONB queries differently, ignores composite index behavior, and does not support Row-Level Security.
  - Run integration tests against a real local PostgreSQL container (via Docker, Testcontainers, or project-scoped `./docker-compose.yml`).
  - **Database Harness Isolation**: Database verification harnesses must always use dedicated project-scoped database containers (e.g. `project-db` instances). Agents must never attach to or run destructive queries against foreign project containers or credentials.

---

## Workflow Steps

### Step 1: Ingest Requirements and Map Entities
1. Identify all core entities, their domain boundaries, and relationship cardinality (1:1, 1:N, N:M).
2. Clarify tenancy model: Single-tenant, shared database with column tenancy, or schema-per-tenant.

### Step 2: Draft Schema and Invariants
1. Write table definitions with explicit types, nullability, default values, and foreign keys.
2. Define check constraints for numerical, date, and status ranges.

### Step 3: Design Indexes Against Target Access Patterns
1. List the critical query read paths and sort operations.
2. Formulate composite and partial indexes following the Equality-Sort-Range (ESR) rule.
3. Verify that all foreign keys have dedicated indexes.

### Step 4: Specify Security and Tenancy Policies
1. Write explicit RLS policies for `SELECT`, `INSERT`, `UPDATE`, and `DELETE`.
2. Define role permissions and access hierarchies.

### Step 5: Document Rollback and Seeding Strategy
1. Provide deterministic seed data for local development.
2. Detail Expand-Contract rollback procedures in the event of failure following the phased policy: Expand → migrate/backfill → compatibility period → verify consumers → Contract (where removal of deprecated columns or tables occurs only after verified consumer migration and rollback assessment).

### Step 6: Generate Data Specification Artifact
1. Use `.promptkit/templates/data-model-spec.md`.
2. Save specification to `./docs/data/YYYY-MM-DD-data-<subsystem>.md`.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Risk | Remedy |
| :--- | :--- | :--- |
| **Unindexed Foreign Keys** | Full table scans during JOINs and parent deletions. | Add B-Tree index on all foreign key columns. |
| **Naive Soft-Deletes** | Collisions with unique constraints on re-created records. | Use partial unique indexes with `WHERE deleted_at IS NULL`. |
| **Raw JSONB Dumping** | Bypasses schema constraints, indexability, and relational integrity. | Normalize relational data; reserve JSONB for truly polymorphic attributes. |
| **In-Memory SQLite Testing** | False confidence in CI; hides concurrency and RLS bugs. | Test against real PostgreSQL instances via Docker or Testcontainers. |
| **Implicit Read-Modify-Write** | Concurrency race conditions resulting in negative balances or double bookings. | Use atomic SQL updates or explicit `FOR UPDATE` row locks. |
| **Cross-Project DB Sharing** | Risk of destructive queries against foreign project databases. | Enforce project-scoped database containers (`project-db`). |

---

## Completion Criteria
- Comprehensive data spec generated in `./docs/data/`.
- All foreign keys indexed and cascade rules explicit.
- Row-Level Security policies documented with verifiable SQL.
- Migration rollback plan and real PostgreSQL test harness defined.
- **Dual-Compatible Telemetry Status Card**: Conclude with a 3-line telemetry status card (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`) and a `> [!TIP]` callout recommending downstream implementation or verification. When multiple next steps exist, invoke native interactive selection tools (e.g. `ask_question`) as your final tool call with Option 1 `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`. Bounded to closed-set operational choices: for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead — see the Picker routing rule in `workflows/plan.md`.
