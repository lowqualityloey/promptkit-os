import { jwtExpiry } from '../auth/session';

/** Client-side hint for when to schedule the next silent refresh. */
export function refreshHintMs(): number {
  const hours = Number(jwtExpiry.replace(/[^0-9]/g, ''));
  return Math.max(hours - 1, 1) * 3_600_000;
}
