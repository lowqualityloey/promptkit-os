# Task Spec: Version the store format without rewriting the old one

<!-- Phase 3c task (benchmarks/PHASE-3C-DESIGN.md). Invariant I1 forbids rewriting
     a record, so the only migration available is a read-time one: new lines carry
     a version, old lines are interpreted. -->

- **Task ID**: `P3C-07`
- **Level**: `L3`
- **Seed Repository**: `phase3c neutral seed at b0ef652d91b20c57965eb4257cab93301ff68999 (built by benchmarks/seed/build-phase3c-seed.sh; operator supplies --seed)`
- **Prompt**: `Store records need a format version so a reader can tell generations apart. Records written from now on carry version 2. Files written before this change have no version field and must still be read, with those records reading back as version 1. Existing lines must never be rewritten: docs/ARCHITECTURE.md invariant I1 requires the log to stay append-only. A record whose version this build does not know must be refused with a StoreError rather than misread as either generation. Keep node --test passing and add tests for a v1 file, a mixed file, and an unknown version.`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import { createStore } from './src/store.js'; const NL = String.fromCharCode(10); const line = (record) => JSON.stringify(record) + NL; const lines = []; const io = { existsSync: () => true, mkdirSync: () => {}, appendFileSync: (p, text) => { lines.push(text); }, readFileSync: () => line({ type: 'enqueue', id: 'v1-job' }) + line({ type: 'failed', id: 'v1-other' }) }; const store = createStore({ path: '/s/jobs.jsonl', io }); const records = store.readAll(); if (records.length !== 2) throw new Error('records ' + records.length); if (records[0].version !== 1 || records[1].version !== 1) throw new Error('v1 read back as ' + JSON.stringify(records.map((r) => r.version))); if (records[0].type !== 'enqueue' || records[0].id !== 'v1-job') throw new Error('v1 record lost ' + JSON.stringify(records[0])); store.append({ type: 'done', id: 'v1-job' }); if (lines.length !== 1) throw new Error('appends ' + lines.length); const written = JSON.parse(lines[0]); if (written.version !== 2) throw new Error('written version ' + written.version); if (written.type !== 'done' || written.id !== 'v1-job') throw new Error('written record ' + lines[0]); const readWith = (text) => ({ ...io, readFileSync: () => text }); const mixed = createStore({ path: '/s/jobs.jsonl', io: readWith(line({ type: 'enqueue', id: 'old' }) + line({ version: 2, type: 'done', id: 'old' })) }); const both = mixed.readAll(); if (both.length !== 2 || both[0].version !== 1 || both[1].version !== 2) throw new Error('mixed read ' + JSON.stringify(both.map((r) => r.version))); let refused = false; try { createStore({ path: '/s/jobs.jsonl', io: readWith(line({ version: 3, type: 'enqueue', id: 'future' })) }).readAll(); } catch (error) { refused = error.name === 'StoreError'; } if (!refused) throw new Error('unknown version accepted'); let refusedMixed = false; try { createStore({ path: '/s/jobs.jsonl', io: readWith(line({ version: 3, type: 'enqueue', id: 'future' }) + line({ type: 'enqueue', id: 'later' })) }).readAll(); } catch (error) { refusedMixed = error.name === 'StoreError'; } if (!refusedMixed) throw new Error('unknown version accepted in a mixed file'); console.log('VERSION|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: Records appended after the change carry `version` 2 and keep their existing fields, so one line is still one JSON object with its `type`.
- [ ] `R2`: A file written before the change has no `version` field, still parses, and each record reads back with `version` 1 and its original fields intact.
- [ ] `R3`: A mixed file reads both generations in order, with each record reporting its own version.
- [ ] `R4`: A record carrying a version this build does not support is refused with `StoreError`, including when it appears beside a readable record, rather than being skipped or reinterpreted.
- [ ] `R5`: No existing line is rewritten — the store stays append-only — and no pre-existing assertion is removed or weakened.
- [ ] `R6`: Only `src/store.js` and `test/store.test.js` are modified, `test/store.test.js` gains cases for the v1, mixed and unknown-version reads, and the verify packet shows `verify_exit=0`.

## Notes

- Source: `docs/adr/0001-store-format.md` ("the first format carries no version
  field … a reader must handle both") and invariant I1.
- Level: L3 — a persisted format gains a generation, and the reader has to stay
  compatible with data it did not write. There is no migration step available,
  which is why the read path carries the whole change.
- `R4` is the discriminating item: skipping an unknown record instead of refusing
  it turns a newer build's log into a quietly wrong status view, which is exactly
  what ADR 0001 says must not happen. The probe checks the mixed case too, so a
  reader that only validates the first record fails.
- `R2` is what a "just add `version: 2` to writes" change misses: old records then
  read back with `version` absent, and the probe requires 1.
