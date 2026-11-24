import { expiryFromNow, jwtExpiry } from '../auth/session';

/** Refresh an existing token, preserving the configured lifetime. */
export function refreshToken(sub: string) {
  return {
    sub,
    exp: expiryFromNow().toISOString(),
    refreshedFrom: jwtExpiry,
  };
}
