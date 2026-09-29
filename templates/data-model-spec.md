# Data Model Specification: [Subsystem / Feature Name]

- **Author**: [Your Name / Team]
- **Status**: [Draft | In Review | Approved | Implemented]
- **Created**: [YYYY-MM-DD]
- **Target Engine**: [PostgreSQL 16+ / Supabase / MySQL / SQLite]
- **ORM / Query Builder**: [Prisma / Drizzle / Kysely / Raw SQL]

> **Engine scope:** the SQL below targets **Supabase (PostgreSQL + Supabase Auth)**. `auth.uid()`, `auth.users`, `gen_random_uuid()`, `UUID`, `TIMESTAMPTZ`, and `JSONB` are not plain-PostgreSQL-portable as written: on PostgreSQL without Supabase Auth, replace `auth.uid()` with a per-transaction session setting (e.g. `current_setting('app.current_user_id')`) and point user foreign keys at your own users table. For MySQL, SQLite, or other engines, substitute engine-native types and functions — do not run this DDL verbatim elsewhere.

---

## 1. Entity-Relationship Overview

### Mermaid Diagram
```mermaid
erDiagram
    ORGANIZATION ||--o{ WORKSPACE : contains
    WORKSPACE ||--o{ WORKSPACE_MEMBER : has
    USER ||--o{ WORKSPACE_MEMBER : joins
    WORKSPACE ||--o{ DOCUMENT : owns

    WORKSPACE {
        uuid id PK
        string name
        string slug UK
        timestamptz created_at
    }

    WORKSPACE_MEMBER {
        uuid id PK
        uuid workspace_id FK
        uuid user_id FK
        string role
    }

    DOCUMENT {
        uuid id PK
        uuid workspace_id FK
        string title
        jsonb content
        int version
        timestamptz deleted_at
    }
```

---

## 2. Table Schemas & Invariants

### Table: `workspaces`
```sql
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(60) NOT NULL,
    tier VARCHAR(20) NOT NULL DEFAULT 'FREE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_valid_tier CHECK (tier IN ('FREE', 'PRO', 'ENTERPRISE'))
);

CREATE UNIQUE INDEX uq_workspaces_slug ON workspaces (slug);
```

### Table: `documents`
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content JSONB NOT NULL DEFAULT '{}'::jsonb,
    version INT NOT NULL DEFAULT 1,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL
);
```

-- Tenant immutability guard (`workflows/data.md` requires an immutable tenant
-- column: RLS WITH CHECK alone cannot stop a dual-member move, so enforce it
-- at the schema level)
CREATE OR REPLACE FUNCTION forbid_workspace_transfer() RETURNS trigger AS $$
BEGIN
  IF NEW.workspace_id IS DISTINCT FROM OLD.workspace_id THEN
    RAISE EXCEPTION 'workspace_id is immutable (tenant move rejected)';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_documents_no_workspace_transfer
BEFORE UPDATE OF workspace_id ON documents
FOR EACH ROW EXECUTE FUNCTION forbid_workspace_transfer();
```

---

## 3. Indexing Strategy

| Index Name | Table | Columns & Ordering | Query Pattern Satisfied | Scan Type Expected |
| :--- | :--- | :--- | :--- | :--- |
| `idx_docs_ws_created` | `documents` | `(workspace_id, created_at DESC)` | `WHERE workspace_id = $1 ORDER BY created_at DESC` | Index Scan |
| `idx_docs_active_title`| `documents`| `(workspace_id, title) WHERE deleted_at IS NULL` | Document search by title for non-deleted records | Partial Index Scan |
| `idx_docs_created_by` | `documents` | `(created_by)` | Foreign key JOIN to users table | Index Scan |

---

## 4. Multi-Tenant Row-Level Security (RLS) (when multi-tenant data exists; otherwise `N/A - <reason>` — e.g., single-tenant or non-Postgres engine with org-ID isolation)

```sql
-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents FORCE ROW LEVEL SECURITY;

-- Read Policy
CREATE POLICY "Users can view workspace documents"
ON documents FOR SELECT
USING (
    workspace_id IN (
        SELECT workspace_id FROM workspace_members 
        WHERE user_id = auth.uid()
    )
    AND deleted_at IS NULL
);

-- Mutation Policy
CREATE POLICY "Users can insert documents into owned workspace"
ON documents FOR INSERT
WITH CHECK (
    workspace_id IN (
        SELECT workspace_id FROM workspace_members 
        WHERE user_id = auth.uid() AND role IN ('ADMIN', 'EDITOR')
    )
);

-- Update Policy
CREATE POLICY "Editors can update workspace documents"
ON documents FOR UPDATE
USING (
    workspace_id IN (
        SELECT workspace_id FROM workspace_members
        WHERE user_id = auth.uid() AND role IN ('ADMIN', 'EDITOR')
    )
    AND deleted_at IS NULL
)
WITH CHECK (
    workspace_id IN (
        SELECT workspace_id FROM workspace_members
        WHERE user_id = auth.uid() AND role IN ('ADMIN', 'EDITOR')
    )
);

-- Delete Policy (hard deletes restricted; application code soft-deletes via UPDATE of deleted_at)
CREATE POLICY "Admins can hard-delete workspace documents"
ON documents FOR DELETE
USING (
    workspace_id IN (
        SELECT workspace_id FROM workspace_members
        WHERE user_id = auth.uid() AND role = 'ADMIN'
    )
);

-- Purge path note: PostgreSQL also applies the SELECT policy's USING check to
-- rows matched by a filtered DELETE, so the SELECT policy above (which hides
-- soft-deleted rows) makes tombstones invisible even to admins. Purging them
-- requires a privileged path outside row-level checks — e.g. a scheduled
-- maintenance job running as a role that bypasses RLS, or a SECURITY DEFINER
-- function owned by such a role — never a relaxation of the SELECT policy.
```

---

## 5. Concurrency & Transaction Boundaries

- **Critical Concurrent Flow**: [e.g., Workspace seat allocation / Document version updates]
- **Concurrency Control Mechanism**: [Pessimistic row locking with `SELECT FOR UPDATE` | Optimistic locking with `version` column]
- **Resolution Strategy**: [If version mismatch occurs, return HTTP 409 Conflict with latest document state]

---

## 6. Seed Data & Test Harness

### Seed Fixtures
```sql
-- Deterministic local development seed data
INSERT INTO workspaces (id, name, slug, tier) 
VALUES ('00000000-0000-0000-0000-000000000001', 'Acme Corp', 'acme', 'PRO')
ON CONFLICT (id) DO NOTHING;
```

### Integration Test Environment
- Test harness engine: [Docker / Testcontainers / Local Supabase CLI]
- Verification commands: [e.g., `npm run test:db` or `pnpm test:integration`]

---

## 7. Zero-Downtime Migration & Rollback Plan (when live or compatibility-sensitive data exists; otherwise `N/A - <reason>` — one-shot, disposable, or pre-deployment changes may skip with documented rationale)

1. **Phase 1 (Expand)**: [Add column/table as nullable]
2. **Phase 2 (Backfill)**: [Backfill historical rows via background job]
3. **Phase 3 (Contract)**: [Add NOT NULL constraint or drop deprecated column]
- **Rollback Procedure**: [Revert migration SQL — only when the migration itself is the demonstrated cause AND a separately verified database recovery procedure exists; otherwise roll back application code only and never roll back schema during an active incident, per `workflows/ship.md`]
