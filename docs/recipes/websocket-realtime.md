---
name: websocket-realtime
category: recipe
version: 1
token_budget: 1500
description: Bound authenticated WebSocket lifecycles, resource use, and reconnect behavior.
---
# WebSocket Realtime Recipe

A WebSocket is a long-lived, authenticated resource. Define its identity, capacity, heartbeat, retry, and cleanup rules before adding message handlers.

## 1. Non-Negotiable Invariants

- Authenticate and authorize the handshake; validate `Origin` for browser clients and scope each subscription to its tenant/resource.
- Bound message size, connection count, outbound queues, and per-identity rate. Apply backpressure instead of buffering without limit.
- Use ping/pong heartbeats and expire peers that miss the configured deadline.
- Treat reconnect as a new session: reauthenticate, resubscribe from a cursor, and deduplicate replayed events.
- Close subscriptions and timers on disconnect; log identifiers and outcomes without tokens or payload secrets.

## 2. Implementation Patterns & Worked Examples

Model the connection lifecycle as `connecting → authenticated → subscribed → closing → closed`. Attach a bounded send queue and heartbeat timer after authorization. Include monotonic event IDs so clients can resume from the last acknowledged cursor; make handlers idempotent because delivery may repeat. Use HTTP/SSE when clients only need server-to-client streaming.

## 3. Anti-Patterns to Avoid

- Do not treat a successful upgrade as authorization for every channel.
- Do not trust a client-supplied tenant ID without server-side membership checks.
- Do not retry forever at a fixed interval; use capped exponential backoff with jitter and a terminal offline state.
- Do not keep sockets alive after logout, ownership changes, or server shutdown.
