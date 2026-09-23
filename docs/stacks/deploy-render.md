---
name: deploy-render
category: cloud
version: 1
token_budget: 1500
activation:
  manifests:
    - render.yaml
verification:
  fast:
    - npx @renderinc/cli blueprint validate
  required:
    - curl -f http://localhost:${PORT:-3000}/healthz
  extended:
    - git diff --check
invariants:
  - "Web services must bind to 0.0.0.0 and listen on the dynamically assigned $PORT"
  - "Handle SIGTERM signals gracefully within the platform's configured shutdown deadline (default 30 seconds)"
  - "Treat container filesystems as ephemeral — route persistent files to mounted disks or S3/R2"
  - "Declare environment variable keys in render.yaml with sync: false for confidential values"
  - "Configure a dedicated lightweight health check path that avoids deep database ping cascades"
anti_patterns:
  - "Hardcoding 127.0.0.1, localhost, or static port numbers like 8080 in application listeners"
  - "Saving uploaded assets, SQLite databases, or generated reports to local container directories without disks"
  - "Committing plaintext production secrets, tokens, or private keys directly into render.yaml blueprints"
  - "Ignoring SIGTERM and allowing active HTTP requests to be brutally severed by SIGKILL"
---

# Render Cloud Deployment Playbook

Operational guidelines, invariants, and failure modes for containerized web services and background workers hosted on Render.

## 1. Architectural Invariants

- **Host & Dynamic Port Binding**: Render dynamically allocates an open port via the `PORT` environment variable. Applications must bind to `0.0.0.0` (all interfaces) rather than `127.0.0.1` or `localhost`. Example in Node: `server.listen(process.env.PORT, '0.0.0.0')`.
- **Graceful SIGTERM Handling**: During zero-downtime rolling deploys and autoscaling scale-down events, Render dispatches a `SIGTERM` signal. The application must cease accepting new connections, finish inflight requests, close database connection pools, and exit cleanly before `SIGKILL` is issued. The shutdown deadline is a platform behavior (default 30 seconds, but check current Render docs and project configuration).
- **Ephemeral Storage Separation**: Instance filesystems are wiped clean on every git deploy, configuration change, or instance restart. Any file that must persist across deploys must either reside on a persistent Render Disk (`disk` mount defined in `render.yaml`) or an external object storage bucket (e.g. AWS S3, Cloudflare R2).
- **Blueprint Secret Sanitization**: In `render.yaml` Infrastructure-as-Code files, declare environment variable schemas with `sync: false` to designate secret values populated manually in the dashboard or via environment groups. Never commit literal secrets.
- **Dedicated Health Route**: Define a deterministic endpoint (e.g. `/healthz` or `/api/health`) returning HTTP 200 with minimal overhead. Avoid heavy database queries on health checks to prevent health check timeouts under high load.

## 2. Critical Anti-Patterns & Pitfalls

- **Localhost Binding Trap**: Listening on `http://localhost:3000` causes Render's external reverse proxy health checks to fail continuously, marking the deployment as timed out (`Deploy failed: Port check failed`).
- **Orphaned Writes on Disks**: Assuming local disk storage persists across deploys without configuring an explicit `disk:` mount path in `render.yaml`.
- **Hanging Inflight Connections**: Failing to hook `process.on('SIGTERM', ...)` causes active long-polling connections or file streams to be terminated abruptly when Render rolls instances.
- **Deep Health Check Cascades**: Writing a health check that queries downstream third-party APIs (Stripe, external LLMs). If an external provider experiences transient slowness, Render marks your service unhealthy and restarts it in a crash-loop.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npx @renderinc/cli blueprint validate` (or yaml linter) to verify blueprint syntax, service definitions, and disk mapping schemas.
- **Required (L2 Controlled / Pre-Commit)**:
  `curl -f http://localhost:${PORT:-3000}/healthz` to assert that the health check endpoint starts promptly and returns a clean 200 OK.
- **Extended (L3 Release / CI)**:
  `git diff --check` to assert that no staging secrets, credentials, or whitespace anomalies leaked into cloud deployment manifests.
