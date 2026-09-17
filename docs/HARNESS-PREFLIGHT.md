# Local harness preflight

Both installers run advisory inspection **before writing project files**. Set `PROMPTKIT_NO_PREFLIGHT=1` to skip it; `PROMPTKIT_NO_INTERACTIVE=1` only disables the picker and does not skip inspection.

Run it separately from the kit checkout:

```bash
bash scripts/check-harness-security.sh /absolute/project/path
```

```powershell
pwsh -NoProfile -File scripts/check-harness-security.ps1 -Root C:\project
```

The existing commit and security-quality workflows reuse this scanner. It does not replace their staged-index secret checks or checkpoint behavior. No new workflow trigger or automatic remediation is added.

## Scope and limits

The shared `scripts/harness-security-paths.txt` lists 20 fixed relative paths: common root environment/credential files, `.cursor/mcp.json`, `.vscode/mcp.json`, `.mcp.json`, Claude permission settings, and `AGENTS.md`/`CLAUDE.md`. It is **not** a recursive repository-wide secret scanner: nested credentials, other filenames, host-global configuration, and effective runtime permission resolution are outside scope.

Each content file is limited to **65,536 bytes**; oversize files are not scanned. NUL-containing binary/UTF-16 content, unreadable/special files, and symlinks at a scanned path or its immediate parent are incomplete checks. Use a stable local directory, not a concurrently modified adversarial filesystem; portable shell path checks are not an atomic filesystem sandbox. The caller-supplied root's ancestor links are resolved by the OS.

Git metadata queries check sensitive allowlisted paths independently for tracking and ignore coverage (`check-ignore --no-index` detects tracked-but-ignored cases correctly). Git index files over **4 MiB** are rejected. No raw `.git` content recursion takes place. Git's own metadata/config processing is not given a wall-clock limit; this is a bounded content scan, not a hard runtime governor. Linked worktrees, `.git` pointer files and symlinked Git directories/indexes report incomplete; a non-Git directory reports Git checks not applicable. No MCP server, credential probe, network request, hook, or automatic fix is executed.

Shared regex rules in `scripts/harness-security-rules.txt` check recognizable private-key/token shapes and selected broad approval/bypass settings. Placeholders such as `replace_me` do not match. JSON is inspected as text, not parsed: warnings may be false positives and complex, escaped or indirect settings can be missed. Suspected-secret regexes cannot verify active credentials; configured permissions do not prove effective runtime permissions. Review locally without pasting secrets into chat.

## Output and exit codes

Records use `PREFLIGHT|severity|rule|location`, with scope/summary records alongside them. Locations are fixed allowlisted relative paths, never arbitrary filenames or matching values; errors from file/Git operations are not printed. The scanner does not invoke an LLM or send contents to one. Agent invocation and reading the report can still consume tokens.

| Exit | Meaning | Installer action |
|---|---|---|
| 0 | No findings within fixed scope (not security certification) | Continue |
| 1 | Warning: `SUSPECTED_SECRET`, `TRACKED_SENSITIVE`, `IGNORE_GAP`, `BROAD_APPROVAL`, `PERMISSION_BYPASS`, or `BROAD_PERMISSION` | Continue with advisory |
| 2 | Incomplete: path/read/encoding/size/Git/rule availability problem; takes precedence over warnings | Continue with advisory |

Users may apply a stricter policy separately after reviewing findings. This installer does not block on heuristics. Opt-out prints `PREFLIGHT|SKIPPED|USER_OPT_OUT`; skipped/incomplete checks must never be described as a clean scan.

## Verification

Run `bash scripts/tests/run-harness-security-tests.sh` and `pwsh -NoProfile -File scripts/tests/run-harness-security-tests.ps1`. CI runs the twins on Linux and Windows alongside the existing installer and contract suites. Tests use synthetic values and temporary directories, never live credentials.
