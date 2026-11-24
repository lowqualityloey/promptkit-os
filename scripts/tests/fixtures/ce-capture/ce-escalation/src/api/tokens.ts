import { expiryFromNow, jwtExpiry } from '../auth/session';

/** Mint a token payload for an authenticated subject. */
export function mintToken(sub: string) {
  return {
    sub,
    exp: expiryFromNow().toISOString(),
    lifetime: jwtExpiry,
  };
}
