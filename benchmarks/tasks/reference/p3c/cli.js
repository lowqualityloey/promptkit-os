// Reference overlay for card P3C-02: `--dry-run` is accepted alongside the
// legacy `--DRY_RUN` spelling. The warning lives in src/app.js, where the sink
// is available; this module only has to stop rejecting the new spelling.
export class CliError extends Error {
  constructor(message) {
    super(message);
    this.name = 'CliError';
  }
}

const COMMANDS = new Set(['run', 'status']);
const FLAGS = new Set([
  'PORT',
  'LOG_LEVEL',
  'QUEUE_CAPACITY',
  'STORE_PATH',
  'JOBS',
  'DRY_RUN',
  'dry-run',
]);

export function parseArgs(argv = []) {
  const flags = {};
  const positional = [];
  let command = 'run';

  for (const arg of argv) {
    if (typeof arg !== 'string' || arg === '') {
      throw new CliError(`arguments must be non-empty strings, got: ${String(arg)}`);
    }
    if (arg.startsWith('--')) {
      const body = arg.slice(2);
      const eq = body.indexOf('=');
      const name = eq === -1 ? body : body.slice(0, eq);
      const value = eq === -1 ? true : body.slice(eq + 1);
      if (name === '') throw new CliError('empty flag name');
      if (!FLAGS.has(name)) throw new CliError(`unknown flag: --${name}`);
      flags[name] = value;
    } else if (COMMANDS.has(arg) && positional.length === 0) {
      command = arg;
    } else {
      positional.push(arg);
    }
  }

  if (positional.length > 0) {
    throw new CliError(`unexpected argument: ${positional[0]}`);
  }
  return { command, flags };
}

export const CLI_FLAGS = Object.freeze([...FLAGS]);
export const CLI_COMMANDS = Object.freeze([...COMMANDS]);
