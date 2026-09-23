---
name: database-supabase
category: database
version: 1
token_budget: 1500
activation:
  manifests:
    - supabase/config.toml
    - supabase/migrations
verification:
  fast:
    - supabase status
  required:
    - supabase db lint
  extended:
    - supabase test db
    - supabase db diff
invariants:
  - "Row Level Security (RLS) must be enabled on every table exposed in public schemas"
  - "RLS mutation policies must be defined correctly: UPDATE policies need both USING and WITH CHECK, INSERT needs WITH CHECK, DELETE needs USING"
  - "Never expose the service_role key to browser clients — use anon key with JWT auth.uid() scoping"
  - "SECURITY DEFINER database functions must specify an explicit search_path"
  - "Index every foreign key and tenant column evaluated in RLS policies"
anti_patterns:
  - "Leaving public schema tables unprotected without enabling Row Level Security"
  - "Using the service_role client in web UI server components to bypass user authorization checks"
  - "Writing RLS policies with unscoped subqueries causing nested full table scans"
  - "Calling third-party webhook endpoints directly inside synchronous Postgres database triggers"
---

# Supabase Postgres Database Playbook

Operational guidelines, invariants, and failure modes for Supabase Postgres backends.

## 1. Architectural Invariants

- **Mandatory Row Level Security (RLS)**: Every table created in the `public` schema must have RLS explicitly enabled: `ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;`. By default, Postgres allows read/write access if RLS is omitted.
- **Policy Operation Guards**: Define RLS policies by operation:
  - `SELECT` / `DELETE` require only a `USING` clause (governing visibility).
  - `INSERT` requires only a `WITH CHECK` clause (governing validity of incoming data).
  - `UPDATE` requires both `USING` (visibility) and `WITH CHECK` (validity of new data) to prevent hijacking records.
- **Key Boundary Isolation**: 
  - `anon` key: Safe for browser and client applications, gated strictly by RLS and `auth.uid()`.
  - `service_role` key: Elevated administrative bypass key. NEVER expose to the client, frontend bundles, or unauthenticated server endpoints.
- **Security Definer Function Hardening**: When writing PostgreSQL stored functions with `SECURITY DEFINER`, always declare `SET search_path = public, auth` to prevent search path hijacking attacks.
- **RLS Policy Indexing**: When an RLS policy references a tenant identifier or foreign key (e.g. `WHERE auth.uid() = user_id` or `workspace_id IN (...)`), create a dedicated B-tree index on that column. Without indexes, every row evaluation triggers sequential scans.

## 2. Critical Anti-Patterns & Pitfalls

- **Bypassing RLS with Admin Clients**: Instantiating the Supabase client using `SUPABASE_SERVICE_ROLE_KEY` inside user-facing Next.js Server Components or Express routes circumvents all RLS policies, making data leak vulnerabilities trivial.
- **Missing WITH CHECK Clauses**: Writing an `UPDATE` policy with only `USING (auth.uid() = user_id)` allows an attacker to update their record's `user_id` to another user's ID, stealing ownership. Always add `WITH CHECK (auth.uid() = user_id)`.
- **Heavy Logic in Database Triggers**: Placing HTTP requests (`net.http_post`), slow cryptographic hashing, or heavy batch jobs inside synchronous Postgres table triggers blocks transactions and drains connection poolers.
- **Untracked Schema Drifts**: Modifying tables directly in the Supabase Dashboard without generating a corresponding migration file via `supabase db diff` creates fatal production migration divergences.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `supabase status` to verify local emulator Docker services, Postgres reachability, and active ports.
- **Required (L2 Controlled / Pre-Commit)**:
  `supabase db lint` to detect security misconfigurations, missing RLS policies, and search-path vulnerabilities.
- **Extended (L3 Release / CI)**:
  `supabase test db` (pgTAP suite) and `supabase db diff` to assert schema parity and policy correctness against test seeds.
