---
name: deploy-docker
category: cloud
version: 1
token_budget: 1500
activation:
  manifests:
    - Dockerfile
    - docker-compose.yml
    - docker-compose.yaml
    - compose.yml
    - compose.yaml
verification:
  fast:
    - docker compose config --quiet
    - docker buildx bake --print
  required:
    - docker build --check .
    - docker build -t test-image .
  extended:
    - docker run --rm test-image --dry-run
    - trivy image --severity HIGH,CRITICAL test-image
invariants:
  - "Separate build dependencies from runtime artifacts using multi-stage Docker builds"
  - "Run containers as an explicit unprivileged user (USER node, appuser, or uid:gid)"
  - "Maintain an explicit .dockerignore excluding credentials, git history, and dev artifacts"
  - "Order instructions from least to most volatile to maximize layer cache hits"
  - "Pin base images to explicit version tags or immutable cryptographic SHA256 digests"
  - "Use JSON array exec syntax for ENTRYPOINT and CMD to enable POSIX SIGTERM signal forwarding"
anti_patterns:
  - "Running production processes as root (UID 0) inside container boundaries"
  - "Baking secrets or API keys into build arguments, env vars, or image layers"
  - "Copying source code before dependency manifests, invalidating cache on every edit"
  - "Deploying with unpinned or mutable :latest base image tags"
  - "Using string shell form for CMD or ENTRYPOINT, severing PID 1 shutdown signals"
  - "Omitting .dockerignore and leaking local node_modules, git history, or secrets into context"
---

# Docker & Container Deployment Playbook

Operational guidelines, security invariants, layer caching, and verification tiers for Docker containerized services.

## 1. Architectural Invariants

- **Multi-Stage Build Separation**: Structure Dockerfiles into distinct stages (`builder` and `runtime`). Compile code, install devDependencies, and generate bundles in an unconstrained build stage, then copy only production artifacts and runtime dependencies into a minimal runtime base (Alpine, Debian-slim, or Distroless).
- **Unprivileged Non-Root Execution**: Production processes must not run as `root` (UID 0). Explicitly provision and activate an unprivileged system user (`USER node`, `USER appuser`, or `USER 10001:10001`). Configure explicit directory ownership (`COPY --chown=appuser:appuser`) when write access is required at boot.
- **Strict `.dockerignore` Hygiene**: Every containerized repository must maintain an explicit `.dockerignore` adjacent to the `Dockerfile`. Exclude `.git`, `.env*`, test suites, build output, and local `node_modules` to accelerate build context transfers and prevent credential leakage.
- **Cache-Optimized Layer Ordering**: Place infrequently changed layers before volatile ones. Copy package manifests (`package.json`, `pnpm-lock.yaml`, `pyproject.toml`, `Cargo.lock`) and run dependency installations *before* copying application code (`COPY . .`). This preserves cache hits across routine code edits.
- **Pinned Base Image Digests**: Pin base images to specific semantic version tags or immutable SHA256 digests (e.g., `node:22.11.0-alpine3.20@sha256:...`). Never deploy with `:latest` or unpinned rolling tags to prevent unintended upstream drift.
- **POSIX Signal Forwarding via Exec Syntax**: Define `ENTRYPOINT` and `CMD` using JSON array syntax (e.g., `CMD ["node", "dist/index.js"]`). String forms invoke `/bin/sh -c` as PID 1, which swallows POSIX `SIGTERM` signals and prevents graceful container shutdowns, resulting in hard `SIGKILL` termination after timeout.

## 2. Critical Anti-Patterns & Pitfalls

- **Root User Execution (UID 0)**: Running as root enables container-breakout vulnerabilities to compromise the host kernel. Always downgrade permissions via the `USER` directive in the final runtime stage.
- **Baking Credentials in Layers**: Passing secrets via `ARG` or copying `.env` files bakes confidential keys into image metadata. Utilize BuildKit secret mounts (`RUN --mount=type=secret,id=...`) for build-time private access.
- **Cache-Busting Source Invalidation**: Running `COPY . .` before package installation causes every code change to reinstall all dependencies from scratch, inflating CI duration and bandwidth.
- **Shell-Form Entrypoint Deadlocks**: Using `CMD node server.js` spawns an intermediary shell process that fails to propagate `SIGTERM` to the runtime, breaking zero-downtime rolling deploys and leaving active database transactions uncommitted.
- **Bloated Monolithic Images**: Retaining compilers, build tools, and dev dependencies in the runtime image expands the attack surface and bloats image size from ~50MB to >1GB.

## 3. Tiered Verification Commands

- **Fast Tier (Pre-Commit / Pre-Build)**:
  - `docker compose config --quiet`: Validates Compose syntax, environment variables, and service specs.
  - `docker buildx bake --print`: Verifies multi-target build matrices and BuildKit configuration targets.
- **Required Tier (CI Gate / Pre-Merge)**:
  - `docker build --check .`: Performs static Dockerfile analysis with BuildKit checks (syntax, warnings, best practices).
  - `docker build -t test-image .`: Executes local container assembly to verify artifact compilation and layer generation.
- **Extended Tier (Release / Nightly)**:
  - `docker run --rm test-image --dry-run`: Verifies container startup, non-root user permissions, and entrypoint execution.
  - `trivy image --severity HIGH,CRITICAL test-image`: Scans final container image layers for known CVEs and OS package vulnerabilities.
