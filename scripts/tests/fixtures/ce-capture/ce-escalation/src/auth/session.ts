/**
 * Session token configuration.
 *
 * The lifetime is consumed by every caller that mints or refreshes a token, so
 * changing it changes the refresh cadence of the whole surface.
 */
export const jwtExpiry = '1h';

export interface SessionClaims {
  sub: string;
  exp: number;
}

export function expiryFromNow(now: Date = new Date()): Date {
  const ms = parseLifetime(jwtExpiry);
  return new Date(now.getTime() + ms);
}

function parseLifetime(lifetime: string): number {
  const match = /^(\d+)([smhd])$/.exec(lifetime);
  if (!match) throw new Error(`unsupported lifetime: ${lifetime}`);
  const value = Number(match[1]);
  const unit = match[2];
  const scale = unit === 's' ? 1000 : unit === 'm' ? 60_000 : unit === 'h' ? 3_600_000 : 86_400_000;
  return value * scale;
}
