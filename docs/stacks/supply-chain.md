---
name: supply-chain
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - package.json
verification:
  fast:
    - npm ci --ignore-scripts
  required:
    - npm audit --audit-level=high
  extended:
    - npm run build
    - npx @cyclonedx/cyclonedx-npm --output-file sbom.json
invariants:
  - "CI installs from the committed lockfile; the resolved graph is never recomputed at build time"
  - "The audit gate runs in CI on a pinned Node version, not only on developer installs"
  - "A machine-readable SBOM is generated from the lockfile at build time and shipped with the release"
  - "CI actions and container base images are pinned to immutable references, not mutable tags"
  - "Package install scripts are treated as code execution and disabled unless explicitly allowlisted"
anti_patterns:
  - "Running npm install in CI, which rewrites the lockfile and tests an unreviewed graph"
  - "Failing the build on every advisory severity, which trains the team to bypass the gate"
  - "Deleting the lockfile to resolve a conflict, silently upgrading every transitive dependency"
  - "Referencing a CI action by a mutable tag or branch"
  - "Generating the SBOM from a developer machine instead of the release artifact"
---
# Supply Chain Playbook

Operational guidelines for the dependency graph a build actually resolves, and the trust boundary between that graph and the pipeline that ships it.

Select for a `package.json` with a committed lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`). The manifest is the trigger, not the scope: the invariants below apply to any ecosystem that resolves a graph from a lockfile, and the commands shown are the npm form. A repository with no committed lockfile has no reproducible graph to verify — report that as the finding rather than applying this playbook.

## 1. Architectural Invariants

- **Lockfile Is the Build Input**: CI installs with `npm ci`, never `npm install`. `npm ci` fails when the lockfile and manifest disagree, which is the point: the disagreement is the bug. Review lockfile diffs as code — a new transitive package is a new trust decision, and a diff that adds forty packages to fix one advisory is a finding, not a fix.
- **Audit in CI, Not on Install**: A local audit is a signal; the gate belongs in CI where it cannot be skipped and runs on a pinned Node version. Gate on a severity threshold, not on "any advisory", and record every accepted exception with an owner and an expiry date.
- **SBOM Is a Release Artifact**: Generate a machine-readable inventory (CycloneDX or SPDX) from the lockfile during the build, attach it to the release, and keep it. When an advisory lands, the SBOM answers "are we affected" from the shipped artifact instead of from a developer's `node_modules`.
- **Pinned Actions and Registries**: A workflow referencing `actions/checkout@v4` trusts a mutable tag; pin the commit SHA. Pin container base images by digest, not by `node:22`. Commit `.npmrc` so the registry is explicit and a build cannot silently resolve from a different one.
- **Install Scripts Are Code Execution**: A `postinstall` hook runs with CI credentials and network access. Install with `--ignore-scripts` and run only the build steps you need, or allowlist the packages permitted to execute scripts.

## 2. Critical Anti-Patterns & Pitfalls

- **`npm install` in CI**: it resolves and rewrites the lockfile, so the build tests a dependency graph nobody reviewed and the diff is discarded.
- **Audit Gate on `low`**: a threshold that fails on informational advisories does not add security; it teaches the team to bypass the gate, and a bypassed gate protects nothing.
- **Deleting the Lockfile to Fix a Conflict**: regenerating from scratch upgrades every transitive dependency at once, and the resulting diff no longer shows which change caused a regression.
- **Floating Action References**: `uses: some/action@main` executes whatever upstream pushed today, with your repository token and your secrets in scope.
- **SBOM After the Fact**: an inventory produced from a developer machine describes that machine, not the artifact that shipped.
- **`--force` as a Habit**: it resolves the graph by ignoring the constraint that exists to prevent an incompatible combination; the conflict is information.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npm ci --ignore-scripts` to install exactly the locked graph without executing package scripts.
- **Required (L2 Controlled / Pre-Commit)**:
  `npm audit --audit-level=high` to fail on high and critical advisories while leaving accepted exceptions recorded.
- **Extended (L3 Release / CI)**:
  `npm run build` and `npx @cyclonedx/cyclonedx-npm --output-file sbom.json` to produce the release artifact and its inventory from the same lockfile.
