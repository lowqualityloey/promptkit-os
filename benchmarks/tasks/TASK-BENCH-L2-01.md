# Task Spec: Config validation module

<!-- Synthetic example (fixture-grade): demonstrates the format at Level 2 —
     multi-file change with a failure path. Runs against the operator's seed
     repo; not a claim about real-world performance. -->

- **Task ID**: `BENCH-L2-01`
- **Level**: `L2`
- **Seed Repository**: `[operator-provided seed repo with src/config.ts and a test runner configured]`
- **Prompt**: `"Create src/validate-config.ts exporting validateConfig(raw: unknown): Config that parses the raw object with fields host (non-empty string) and port (integer 1-65535). Throw an Error listing ALL violated field constraints (not just the first) when validation fails. Add tests for the valid case and for each invalid-field case, and make sure the whole test suite passes. Update src/config.ts to use validateConfig on startup."`
- **Setup**: `None`
- **Verify**: `npm test`

## Rubric

- [ ] `R1`: `src/validate-config.ts` exists and exports `validateConfig` accepting one argument.
- [ ] `R2`: Validation rejects a non-string/empty `host` and an out-of-range or non-integer `port` (integer 1–65535 bounds enforced).
- [ ] `R3`: The thrown error lists every violated constraint in a single failure (an input violating both fields reports both).
- [ ] `R4`: `src/config.ts` calls `validateConfig` on startup.
- [ ] `R5`: Tests cover the valid case and each invalid-field case, and the harness verify output (`B<nnn>.verify.txt`) shows the full test suite passing.

## Notes

- R3 is the discriminating item: agents that fail-fast on the first violation fail it.
- R5 grades from the harness-produced verify packet, never from session logs
  (they contain scenario names and arm-revealing output), matching the
  methodology's evidence-gated verification dimension.
