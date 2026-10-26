# Task Spec: Add a configuration-only dry run to the CLI

<!-- Phase 3b task (benchmarks/PHASE-3B-PROTOCOL.md section 2): a localized
     change to flag parsing and the start-up path, drawn from the neutral seed's
     own backlog. The seed is synthetic, so the batch is labeled synthetic-seed
     and no result transfers to consumer code. Not a Phase 3 pilot task. -->

- **Task ID**: `BENCH-L1-04`
- **Level**: `L1`
- **Seed Repository**: `phase3b neutral seed at 16b3cf74c809c23dd48466da2212bd3e67a530ed (built by benchmarks/seed/build-phase3b-seed.sh; operator supplies --seed)`
- **Prompt**: `"Add a --DRY_RUN flag to src/app.js. Extend parseFlags so it accepts --DRY_RUN and keeps its parsing of the other flags unchanged; the flag counts as present whether it is bare or carries a value such as --DRY_RUN=1. When it is present, main validates the configuration exactly as it does today, writes exactly one line to the out sink of the form dry-run port=<port> level=<level> capacity=<capacity>, and returns an object with exitCode 0 and the validated config, without constructing a queue. An invalid configuration under the flag still writes the existing configuration error to the err sink and returns exitCode 2, also without constructing a queue. When the flag is absent, behavior is unchanged. The ready line format and the other flags stay exactly as they are. Add tests for the valid and invalid dry-run cases to test/app.test.js. Do not change any other file. Keep node --test passing."`
- **Setup**: `None`
- **Verify**: `node --test && node --input-type=module -e "import {main, parseFlags} from './src/app.js'; if (!('DRY_RUN' in parseFlags(['--DRY_RUN']))) throw new Error('parseFlags rejected a bare --DRY_RUN'); if (parseFlags(['--PORT=7']).PORT !== '7') throw new Error('parseFlags changed'); const out=[]; const err=[]; const io={out:(l)=>out.push(l), err:(l)=>err.push(l)}; const r=main(['--DRY_RUN=1'],{PORT:'9090'},io); if (r.exitCode !== 0) throw new Error('dry-run exit ' + String(r.exitCode)); if (out.length !== 1 || out[0] !== 'dry-run port=9090 level=info capacity=100') throw new Error('dry-run line ' + JSON.stringify(out)); if (r.queue !== undefined) throw new Error('dry run constructed a queue'); if (!r.config || r.config.port !== 9090) throw new Error('dry-run config'); out.length=0; err.length=0; const bare=main(['--DRY_RUN'],{PORT:'9090'},io); if (bare.exitCode !== 0 || bare.queue !== undefined) throw new Error('bare dry-run exit ' + String(bare.exitCode)); if (out.length !== 1 || out[0] !== 'dry-run port=9090 level=info capacity=100') throw new Error('bare dry-run line ' + JSON.stringify(out)); out.length=0; err.length=0; const bad=main(['--DRY_RUN=1','--PORT=0'],{},io); if (bad.exitCode !== 2) throw new Error('invalid dry-run exit ' + String(bad.exitCode)); if (bad.queue !== undefined) throw new Error('invalid dry run constructed a queue'); if (out.length !== 0) throw new Error('invalid dry run wrote to out'); if (!/configuration error: PORT must be a positive integer/.test(err[0] || '')) throw new Error('invalid dry-run error ' + JSON.stringify(err)); out.length=0; err.length=0; const normal=main([],{},io); if (normal.exitCode !== 0 || !normal.queue) throw new Error('normal path changed'); if (out[0] !== 'ready port=8080 level=info capacity=100') throw new Error('ready line changed ' + JSON.stringify(out)); console.log('DRYRUN|OK');"`

## Rubric

- [ ] `R1`: `--DRY_RUN` is accepted by `parseFlags` and by `main` (no unknown-flag error) in both the bare and `=<value>` form, and the other flags keep their current parsing.
- [ ] `R2`: With a valid configuration the dry run writes exactly one line of the form `dry-run port=<port> level=<level> capacity=<capacity>` to the `out` sink and returns `exitCode` 0.
- [ ] `R3`: The dry-run path constructs no queue: the returned object carries the validated `config` and no constructed queue, and the same holds on the invalid-configuration path.
- [ ] `R4`: An invalid configuration under `--DRY_RUN` returns `exitCode` 2, writes the existing `configuration error: ...` message to the `err` sink, and writes nothing to `out`.
- [ ] `R5`: Without the flag, behavior is unchanged: one `ready ...` line, a constructed queue, `exitCode` 0.
- [ ] `R6`: Only `src/app.js` and `test/app.test.js` are modified, no pre-existing test assertion is removed or weakened, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the neutral seed's `BACKLOG.md`, item 5 (`app`: add a `--DRY_RUN` flag
  that validates configuration and exits without constructing a queue).
- Level: L1 is a localized change to flag parsing and the start-up branch; it
  touches one module and changes no exported record or cross-module contract.
  It is the second of the two L1 cells.
- The prompt states the return shape (`exitCode` 0 plus the validated `config`),
  so R2 and R3 are graded against one contract: a compliant dry run cannot
  return a bare `{ exitCode: 0 }`, and the probe's `config` assertion is not a
  hidden requirement.
- Both flag forms are stated and probed because `parseFlags` turns a bare flag
  into the string `true`; an implementation that only matches `--DRY_RUN=1`
  accepts one form the prompt requires and one it rejects.
- R3 is the discriminating item: an implementation that builds the queue and
  then skips the ready line satisfies R1, R2, and R4 but fails R3, and the
  verify probe checks the result object rather than the absence of a side
  effect it cannot observe.
- The `dry-run` line carries the same three values the `ready` line prints, so
  the dry run proves the configuration it validated instead of only reporting
  that validation passed.
