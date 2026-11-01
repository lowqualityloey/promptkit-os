// Reference overlay for card P3C-10: `drain` takes the backing array once
// instead of moving every item down a slot, so the cost is proportional to the
// items returned rather than to their count squared. Order and the empty-queue
// behavior are unchanged.
export class QueueFullError extends Error {
  constructor(capacity) {
    super(`queue is full at capacity ${capacity}`);
    this.name = 'QueueFullError';
    this.capacity = capacity;
  }
}

export function createQueue({ capacity = 100 } = {}) {
  if (capacity !== Number.POSITIVE_INFINITY && (!Number.isInteger(capacity) || capacity < 1)) {
    throw new RangeError(`capacity must be a positive integer, got: ${capacity}`);
  }

  const items = [];

  return {
    get capacity() {
      return capacity;
    },
    get size() {
      return items.length;
    },
    get isFull() {
      return items.length >= capacity;
    },
    enqueue(item) {
      if (items.length >= capacity) throw new QueueFullError(capacity);
      items.push(item);
      return items.length;
    },
    enqueueMany(batch) {
      if (items.length + batch.length > capacity) throw new QueueFullError(capacity);
      for (const item of batch) items.push(item);
      return items.length;
    },
    peek() {
      return items.length === 0 ? undefined : items[0];
    },
    dequeue() {
      return items.length === 0 ? undefined : items.shift();
    },
    drain() {
      return items.splice(0, items.length);
    },
  };
}
