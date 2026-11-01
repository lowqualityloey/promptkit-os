# Task Spec: Rename the dry-run flag without breaking the old spelling

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). The prompt states both
     spellings and the exact warning count, so the rubric adds no hidden
     requirement. -->

- **Task ID**: `P3C-02`
- **Level**: `L1`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `Operators should use --dry-run for the dry run. Accept that spelling, and keep --DRY_RUN working exactly as it does today, but when the old spelling is used print one line to the error sink that says it is deprecated and names --dry-run. The new spelling must print no warning. Passing both spellings together must still produce exactly one warning. Both spellings must print the same dry-run line, and every other flag must parse as it does now.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { main } from './src/app.js'; const run = async (argv) => { const out = []; const err = []; const result = await main(argv, { STORE_PATH: 'data/probe-02.jsonl' }, { out: (l) => out.push(l), err: (l) => err.push(l) }); return { result, out, err }; }; const fresh = await run(['--dry-run']); if (fresh.result.exitCode !== 0) throw new Error('new spelling exit ' + fresh.result.exitCode); if (fresh.out.length !== 1 || !fresh.out[0].startsWith('dry-run port=')) throw new Error('new spelling out ' + JSON.stringify(fresh.out)); if (fresh.err.length !== 0) throw new Error('new spelling warned ' + JSON.stringify(fresh.err)); const legacy = await run(['--DRY_RUN=1']); if (legacy.result.exitCode !== 0) throw new Error('legacy exit ' + legacy.result.exitCode); if (legacy.out.length !== 1 || legacy.out[0] !== fresh.out[0]) throw new Error('legacy out ' + JSON.stringify(legacy.out)); if (legacy.err.length !== 1) throw new Error('legacy warnings ' + legacy.err.length); if (!/deprecat/i.test(legacy.err[0]) || legacy.err[0].indexOf('--dry-run') === -1) throw new Error('warning text ' + legacy.err[0]); const both = await run(['--DRY_RUN', '--dry-run']); if (both.err.length !== 1) throw new Error('both spellings warned ' + both.err.length); console.log('DRYRUN|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: `--dry-run` is accepted by the CLI and by the entry point in both the bare and the `=<value>` form, and the other flags parse as before.
- [ ] `R2`: `--DRY_RUN` keeps working, and the dry run still prints exactly one `dry-run port=... level=... capacity=...` line and returns `exitCode` 0.
- [ ] `R3`: The legacy spelling prints exactly one line to the error sink that says it is deprecated and names `--dry-run`; the new spelling prints none, and using both spellings still prints exactly one.
- [ ] `R4`: Both spellings produce the same dry-run line on the output sink, and nothing else is written to output.
- [ ] `R5`: Only `src/cli.js`, `src/app.js`, `test/cli.test.js` and `test/integration.test.js` are modified, no pre-existing assertion is removed or weakened, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the seed's `BACKLOG.md` ("operator tooling") plus the seed's own
  `--DRY_RUN` flag, which is the only spelling it knows.
- Level: L1 — flag parsing plus one branch at the entry point, no exported
  contract change.
- `R3` is the discriminating item: warning twice (once per spelling present),
  warning on the new spelling, or warning per occurrence of the same flag all
  fail the probe, which counts error-sink lines rather than looking for a
  message.
- The wording of the warning is free apart from two facts the probe checks: it
  contains "deprecat" and it names `--dry-run`.
