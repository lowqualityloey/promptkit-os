# Task Spec: Report processed and failed counts from the dispatcher

<!-- Phase 3b task (benchmarks/PHASE-3B-PROTOCOL.md section 2): a localized
     change to one module's return contract, drawn from the neutral seed's own
     backlog. The seed is synthetic, so the batch is labeled synthetic-seed and
     no result transfers to consumer code. Not a Phase 3 pilot task. -->

- **Task ID**: `BENCH-L1-03`
- **Level**: `L1`
- **Seed Repository**: `phase3b neutral seed at 16b3cf74c809c23dd48466da2212bd3e67a530ed (built by benchmarks/seed/build-phase3b-seed.sh; operator supplies --seed)`
- **Prompt**: `"Change dispatch in src/dispatcher.js so its result also carries a counts object while the existing processed, failed, and total fields stay unchanged. counts has integer fields processed, failed, and total, equal to the lengths of the two arrays and their sum, including the empty-queue case. Keep the existing log lines and failure handling unchanged. Add tests covering a mixed success and failure batch and the empty queue to test/dispatcher.test.js. Do not change any other file. Keep node --test passing."`
- **Setup**: `None`
- **Verify**: `node --input-type=module -e "import {createQueue} from './src/queue.js'; import {dispatch} from './src/dispatcher.js'; const q=createQueue({capacity:4}); for (const id of ['a','b','c']) q.enqueue({id}); const r=await dispatch(q, async (j) => { if (j.id === 'b') throw new Error('boom'); return j.id; }); if (!r.counts || typeof r.counts !== 'object') throw new Error('counts missing'); if (r.counts.processed !== 2 || r.counts.failed !== 1 || r.counts.total !== 3) throw new Error('counts mixed ' + String(r.counts.processed) + '/' + String(r.counts.failed) + '/' + String(r.counts.total)); if (r.processed.length !== 2 || r.failed.length !== 1 || r.total !== 3) throw new Error('existing fields changed'); const e=await dispatch(createQueue(), async () => 1); if (e.counts.processed !== 0 || e.counts.failed !== 0 || e.counts.total !== 0) throw new Error('counts empty'); if (!Number.isInteger(e.counts.total)) throw new Error('counts not integer'); console.log('COUNTS|OK');"; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]`

## Rubric

- [ ] `R1`: The object returned by `dispatch` carries a `counts` object with integer fields `processed`, `failed`, and `total`.
- [ ] `R2`: On a batch mixing successes and failures, `counts.processed` and `counts.failed` equal the lengths of `processed` and `failed`, and `counts.total` equals their sum.
- [ ] `R3`: On an empty queue all three counts are `0`, and the existing `processed`, `failed`, and `total` fields keep their current shape and values.
- [ ] `R4`: `test/dispatcher.test.js` gains assertions for the mixed batch and the empty queue.
- [ ] `R5`: Only `src/dispatcher.js` and `test/dispatcher.test.js` are modified, the existing per-job log lines and failure handling are unchanged, and the verify packet shows `verify_exit=0`.

## Notes

- Source: the neutral seed's `BACKLOG.md`, item 3 (`dispatcher`: return a summary
  count of processed and failed jobs so callers do not have to measure the
  arrays).
- Level: L1 is a localized change confined to one module's return value, with no
  cross-module contract change and no shared mutable state. It is one of the two
  L1 cells.
- R3 is the discriminating item: an implementation that recomputes `total` from
  the job count instead of from the two arrays, or that drops the existing
  `total`, passes R1 but fails here on the empty case or on the mixed case.
