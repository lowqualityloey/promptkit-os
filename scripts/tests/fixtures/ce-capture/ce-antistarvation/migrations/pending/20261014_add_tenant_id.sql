-- Add tenant_id to the events table and backfill it from the authoritative
-- tenant mapping. The mapping is the source of truth for which tenant owns
-- each legacy account; it is not derivable from the events table itself.
--
-- Mapping source: docs/tenants.csv (columns: account_id,tenant_id)

ALTER TABLE events ADD COLUMN tenant_id TEXT;

UPDATE events
SET tenant_id = (
  SELECT m.tenant_id
  FROM tenant_map m
  WHERE m.account_id = events.account_id
)
WHERE tenant_id IS NULL;

ALTER TABLE events ALTER COLUMN tenant_id SET NOT NULL;
