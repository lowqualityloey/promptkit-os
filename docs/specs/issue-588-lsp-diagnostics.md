# Issue #588: workspace LSP diagnostics

## Problem and causes

The original 57-file OMO scan reported typing and shell diagnostics. Argparse's dynamic namespace loses field types; shell findings include dependent local initialization, scalar/array name reuse, pattern-sensitive path prefixes, unused state, and ambiguous literal fixture text.

## Scope and implementation

Type the archive verifier's argparse namespace without changing its CLI. Separate Bash declarations from command results and dependent assignments. Quote literal path prefixes and escape fixture dollars/backticks while preserving their exact values. Remove unused internal state and helpers, identify sourced files for ShellCheck, and preserve validator output and read-only behavior.

The CPAC demo currently accepts a telemetry path but ignores it. Both script twins will instead print an unsupported-input message and exit 2 for a nonempty path. Self-tests keep precedence and the no-path simulated scorecard remains available.

## Compatibility and exclusions

Retain installer content preservation, literal path handling, diagnostic schemas, and equivalent Bash/PowerShell behavior. Keep the reference scanner compatible with Bash 3.2 by retaining its streaming read loop. No LSP binaries, user-specific paths, dependencies, suppression directives, release tags, or publishing changes are included.

## Verification

- Fresh OMO diagnostics for the original 57 code files: all severities clear.
- Bash/Python syntax and whitespace checks.
- Archive verification accepts a matching commit and rejects mismatched contents.
- Installer/profile, references, picker, secret-scan, authorization, execution-control, CI-triage, release-record, and behavioral regression suites.
- Both CPAC twins: self-test success, no-path demo success, supplied-path failure with exit 2 and no simulated scorecard.
- Release-record properties: 12 properties with 100 iterations each; execution-control properties: 5 with 100 each.

## Release impact

Patch-level script corrections. The CPAC supplied-path rejection is the sole intentional CLI behavior change and is documented in the changelog.
