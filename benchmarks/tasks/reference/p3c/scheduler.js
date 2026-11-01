// Reference overlay for card P3C-06: the scheduler gains a `sweep` helper that
// drains a queue through the dispatcher and reports how many jobs it ran, read
// from the dispatcher's `counts` rather than by re-deriving it.
//
// This is the caller no unit test in the seed covers, which is what the card is
// about: a change to the dispatch result that touches only the dispatcher and its
// own test leaves this helper returning the wrong thing.
import { dispatch } from './dispatcher.js';

export function createScheduler({ now = () => Date.now() } = {}) {
  const entries = [];

  return {
    get size() {
      return entries.length;
    },
    add(job, runAt) {
      if (!Number.isFinite(runAt)) {
        throw new RangeError(`runAt must be a finite number, got: ${runAt}`);
      }
      entries.push({ job, runAt });
      entries.sort((a, b) => a.runAt - b.runAt);
      return entries.length;
    },
    due() {
      const at = now();
      return entries.filter((entry) => entry.runAt <= at).map((entry) => entry.job);
    },
    async tick(handler) {
      const at = now();
      const ready = entries.filter((entry) => entry.runAt <= at);
      for (const entry of ready) {
        await handler(entry.job);
        const index = entries.indexOf(entry);
        if (index !== -1) entries.splice(index, 1);
      }
      return ready.length;
    },
    async sweep(queue, handler, options = {}) {
      const result = await dispatch(queue, handler, options);
      return result.counts.total;
    },
  };
}
