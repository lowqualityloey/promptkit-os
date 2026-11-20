---
name: dependency-audit
category: recipe
version: 1
token_budget: 1500
description: Audit-on-install vs audit-in-CI, reachability triage, and lockfile bumps vs version bumps.
---

# Dependency Audit Recipe

How to turn an advisory feed into a decision: where the gate runs, how an advisory is triaged against shipped code, and what a lockfile change means.

---

## 1. Non-Negotiable Invariants

- **The Gate Lives in CI, the Signal Lives Locally**:
  - `npm audit` on install is a signal: early, cheap, skippable. It is not the control.
  - The control is a CI job on a pinned Node version that exits non-zero. A clean local audit is not evidence the build is clean.
- **Triage by Reachability, Not Severity Alone**:
  - Severity describes the advisory in the abstract. Reachability describes your exposure.
  - Record three facts: is the vulnerable package in the production graph, is the vulnerable function called, and does untrusted input reach it.
  - A `critical` in a dev-only test runner and a `moderate` in a request-body parser are not the same decision; severity alone ranks them backwards.
- **A Lockfile Bump Is Not a Version Bump**:
  - A lockfile bump moves the resolved version inside the range declared in `package.json`. The contract is unchanged; the shipped bytes are not.
  - A version bump changes the declared range. The contract changed, and the changelog is required reading.
  - They carry different review obligations and must not share a commit message.
- **Every Accepted Advisory Has an Owner and an Expiry**:
  - An exception without an owner is an orphan; without an expiry it is permanent.
  - Record the advisory id, the reachability justification, the owner, and the re-evaluation date.

---

## 2. Canonical Implementation Patterns

### Pattern A: CI Gate with a Threshold and an Exception Ledger

```typescript
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const RANK = { info: 0, low: 1, moderate: 2, high: 3, critical: 4 } as const;
const THRESHOLD = RANK.high;

interface Exception {
  advisory: string;
  owner: string;
  expires: string;
  reachability: string;
}

const exceptions: Exception[] = JSON.parse(
  readFileSync("security/audit-exceptions.json", "utf8")
);

const report = JSON.parse(
  execFileSync("npm", ["audit", "--json"], { encoding: "utf8" })
);

const today = new Date().toISOString().slice(0, 10);
const active = new Set(
  exceptions
    .filter((e) => e.expires >= today && e.advisory?.trim())
    .map((e) => e.advisory.trim().toUpperCase())
);

// via.url carries the GHSA id; via.source is numeric. Unparsed vias yield "".
const ghsa = (via: any) =>
  (String(via.url ?? "").match(/GHSA-[\w-]+/i)?.[0] ?? "").toUpperCase();

// Any unexcepted advisory blocks; an unknown severity outranks every threshold.
const blocking = Object.values(report.vulnerabilities ?? {}).filter(
  (v: any) =>
    (RANK[v.severity as keyof typeof RANK] ?? Infinity) >= THRESHOLD &&
    v.via.some((via: any) => !active.has(ghsa(via)))
);

if (blocking.length > 0) {
  for (const v of blocking) console.error(`${v.severity}: ${v.name}`);
  process.exit(1);
}
```

> **Expiry Is the Mechanism**: an exception whose date has passed stops suppressing its advisory.

### Pattern B: The Reachability Record

```json
{
  "advisory": "GHSA-xxxx-xxxx-xxxx",
  "package": "example-parser",
  "severity": "moderate",
  "productionGraph": true,
  "vulnerableFunctionCalled": true,
  "untrustedInputReaches": true,
  "owner": "platform-team",
  "expires": "2026-03-01",
  "reachability": "Public API request bodies reach parse() via the upload route."
}
```

The three booleans are the triage. Any `false` downgrades urgency; all three `true` means the advisory is live regardless of label.

### Pattern C: Naming the Two Bumps

```bash
# Lockfile bump: same declared range, different resolved bytes.
npm update example-parser

# Version bump: the declared range changes.
npm install example-parser@^3
```

Review the first as a supply-chain change — diff the lockfile, run the suite. Review the second as a contract change — read the changelog first.

---

## 3. Framework Adaptations

- **pnpm / yarn / bun**: the audit subcommand differs (`pnpm audit`, `yarn npm audit`, `bun audit`), but the gate shape does not — parse JSON, apply a threshold, subtract active exceptions, exit non-zero.
- **Python / Go / Rust**: `pip-audit`, `govulncheck`, and `cargo audit` all emit machine-readable output. `govulncheck` is strongest because it reports reachability, not a flat package list.
- **Container images**: scan the built image, not the source tree — the base image's packages are in the artifact, not the lockfile.

---

## 4. Anti-Patterns & Failure Modes

- **Audit Only on Install**: the developer who runs `npm install --no-audit` never sees it, and CI never runs it.
- **Severity-Only Triage**: ranking a dev-only `critical` above a reachable `moderate` spends remediation effort where the exposure is not.
- **Permanent Exceptions**: an exception with no expiry is a silent policy change that outlives the reason for it.
- **Regenerating the Lockfile to Clear an Advisory**: it clears the advisory by upgrading everything, and the regression arrives without a diff that explains it.
- **Calling a Lockfile Bump a Dependency Upgrade**: the commit message claims a contract change that did not happen, and the reviewer skips the lockfile diff that did.
- **Auditing `node_modules`**: it describes the machine, not the artifact.

---

## 5. Verification Checklist

- [ ] CI runs the audit on a pinned Node version and exits non-zero above the threshold.
- [ ] Exceptions live in a committed file with an owner, a reachability note, and an expiry date.
- [ ] An expired exception re-opens the gate without a manual edit.
- [ ] Lockfile bumps and version bumps are distinguishable in the commit history.
- [ ] The audit covers the shipped artifact, including container base images.
