# Bounded local harness preflight (#243)

## Problem and design
The installer has no committed local preflight; the current prototype omits Git tracking and ignore coverage. Add advisory, read-only inspection before installer writes. Keep a fixed allowlist of local environment, MCP, permission and directive files; never enumerate the project tree, execute configured servers, validate credentials, or send contents over the network. Both platform scripts consume shared path and regex tables.

## Public behavior and compatibility
Report only fixed allowlisted relative locations and rule IDs. Cap each file at 64 KiB and Git index metadata at 4 MiB. Reject symlinks/special files and report incomplete inspection. Check known sensitive paths independently for tracking and ignore coverage, including tracked-but-ignored files. Existing staged-content checks remain mandatory and independent. No new workflow, automatic remediation, or blocking installer behavior. PROMPTKIT_NO_PREFLIGHT=1 is independent of PROMPTKIT_NO_INTERACTIVE.

Exit 0 means no findings within the declared scope, 1 means warnings, and 2 means incomplete (takes precedence). Regex findings are suspicions, not proof of active credentials or effective runtime permissions. Raw-text configuration inspection is not a JSON parser or a full permission audit. Agent invocation and report reading may consume tokens even though the scanner itself invokes no LLM.

## Scope and verification
Affected surfaces: scanner twins and shared data, installer twins, scanner tests, CI, existing commit/security guidance, and preflight documentation. Verify placeholder handling, redaction, tracked-but-ignored files, ignore gaps, read failures/special files, symlink rejection, limits, exit codes, pre-write invocation and opt-out independence; run installer/contract/evaluation/reference and strict token checks. Keep #241 and unrelated archive files out. GitHub Windows CI supplies native PowerShell verification when unavailable locally.

## Release impact
Additive advisory installer and workflow capability; no migration required. Proposed candidate impact: minor, subject to normal release evaluation; this record authorizes no release or changelog publication.
