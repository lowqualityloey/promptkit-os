// Reference overlay for card P3C-07: records carry a format version, v1 files
// stay readable and are never rewritten (invariant I1), and a record from a
// generation this build does not know is refused rather than misread.
import { appendFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs';
import { dirname } from 'node:path';

export class StoreError extends Error {
  constructor(message) {
    super(message);
    this.name = 'StoreError';
  }
}

export const FORMAT_VERSION = 2;

const SUPPORTED_VERSIONS = new Set([1, 2]);
const defaultIo = { appendFileSync, existsSync, mkdirSync, readFileSync };

export function createStore({ path, io = defaultIo } = {}) {
  if (typeof path !== 'string' || path === '') {
    throw new StoreError('store path must be a non-empty string');
  }

  function append(record) {
    if (record === null || typeof record !== 'object') {
      throw new StoreError('record must be an object');
    }
    try {
      const dir = dirname(path);
      if (!io.existsSync(dir)) {
        io.mkdirSync(dir, { recursive: true });
      }
      const line = { version: FORMAT_VERSION, ...record };
      io.appendFileSync(path, `${JSON.stringify(line)}\n`, 'utf8');
    } catch (error) {
      throw new StoreError(`append failed: ${error.message}`);
    }
    return record;
  }

  function readAll() {
    if (!io.existsSync(path)) return [];
    let text;
    try {
      text = io.readFileSync(path, 'utf8');
    } catch (error) {
      throw new StoreError(`read failed: ${error.message}`);
    }
    const records = [];
    for (const line of text.split('\n')) {
      if (line.trim() === '') continue;
      let parsed;
      try {
        parsed = JSON.parse(line);
      } catch {
        throw new StoreError('store contains a line that is not JSON');
      }
      if (parsed === null || typeof parsed !== 'object' || typeof parsed.type !== 'string') {
        throw new StoreError('store record is missing its type');
      }
      const version = parsed.version === undefined ? 1 : parsed.version;
      if (!SUPPORTED_VERSIONS.has(version)) {
        throw new StoreError(`unsupported store record version: ${version}`);
      }
      records.push({ ...parsed, version });
    }
    return records;
  }

  return { path, append, readAll };
}
