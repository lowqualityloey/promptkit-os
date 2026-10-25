# Security Policy

## Reporting a Vulnerability

Report vulnerabilities privately through GitHub's **Report a vulnerability** flow (this repository → *Security* tab → *Advisories* → *Report a vulnerability*). Do not open a public issue for security reports. Include the affected version (npm package version or repository commit), a reproduction, and an impact assessment. Reports are triaged by the maintainer; fixes ship through the normal release process ([`docs/internal/release-evaluation.md`](docs/internal/release-evaluation.md)).

## Supply-Chain Model

- **npm courier integrity**: the `promptkit-os` npm package is a courier, not a dependency. Published couriers `v2.0.0+` pin a per-version SHA-256 digest (`TARBALL_SHA256_BY_VERSION` in `package/bin/promptkit-os.js`) resolved before download and compared in constant time before extraction; a missing or malformed pin fails closed before any network fetch, extraction, or target write. An operator may override the expected digest with `PROMPTKIT_TARBALL_SHA256` (strictly 64 hexadecimal characters).
- **Trust boundary**: integrity pins detect archive mismatches relative to an expected digest; they do not independently establish publisher trust. A compromised publisher, malicious package release, tampered courier binary, or compromised pin source defeats the trust assumption. Historical `promptkit-os@1.11.0` remains fail-open and immutable on npm.
- **Provenance**: releases publish from CI (`.github/workflows/release-npm.yml`) with SLSA provenance attestations; verify the attestation of the version you consume via the npm registry's attestation endpoint before trusting a tarball.
- **Installer safety**: `init.sh` / `init.ps1` refuse to write through swapped symlinks, contain every recovery write to the project root, and leave original files byte-for-byte unchanged on failure.
- **Scoped secret scanning**: the staged-index scan (`scripts/scan-staged-secrets.sh` / `.ps1`) is a candidate signal applied to staged additions only; it is not proof that no secret exists, and unstaged or removed-only content is not scanned.

## Scope

The npm courier, installer and validator scripts, CI workflows, and the workflow/protocol/template content in this repository. Vulnerabilities in third-party AI hosts (Cursor, GitHub Copilot, Windsurf, etc.) are out of scope; report those to the relevant vendor.
