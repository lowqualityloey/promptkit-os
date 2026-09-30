#!/usr/bin/env node
/**
 * Deterministic Concurrency Verification for Refresh Token Rotation (Issue #465)
 *
 * Verifies:
 * 1. Given two concurrent refresh-token exchanges presenting the same valid token:
 *    - At most one successor token issues.
 *    - The losing exchange detects reuse/conflict and triggers family revocation.
 * 2. Given a revoked token family:
 *    - When any member token is presented (including winning successor, original token, or predecessor),
 *      no token remains usable.
 * 3. Compares atomic transactional consumption vs non-atomic (demonstrating why the race occurred).
 */

import assert from "node:assert";

// Implementation of Pattern C from docs/recipes/auth-session.md
export async function rotateRefreshToken(tokenId, store) {
  const result = await store.consumeAndRotate(tokenId);

  if (result.status === "not_found") {
    throw new Error("UNAUTHORIZED: Unknown token");
  }

  // Invariant: Failed consumption due to prior use triggers immediate family invalidation
  if (result.status === "reuse_detected") {
    if (result.familyId) await store.revokeFamily(result.familyId);
    throw new Error("SECURITY_ALERT: Token reuse detected; family revoked");
  }

  if (result.status === "family_revoked") {
    throw new Error("UNAUTHORIZED: Token family is revoked");
  }

  if (!result.successorTokenId) {
    throw new Error("INTERNAL_ERROR: Failed to issue successor token");
  }

  return result.successorTokenId;
}

// Atomic store simulating a single-transaction or conditional update (CAS)
class AtomicTokenStore {
  constructor() {
    this.tokens = new Map(); // id -> { id, familyId, used, userId }
    this.revokedFamilies = new Set();
    this.tokenCounter = 1;
    this.mutex = Promise.resolve(); // Simulates database row/table lock in transaction
  }

  seedToken(id, familyId, userId) {
    this.tokens.set(id, { id, familyId, used: false, userId });
  }

  async revokeFamily(familyId) {
    this.revokedFamilies.add(familyId);
  }

  async consumeAndRotate(tokenId) {
    // Atomically execute inside simulated transaction
    const executeInTx = async () => {
      const token = this.tokens.get(tokenId);
      if (!token) {
        return { status: "not_found" };
      }

      if (this.revokedFamilies.has(token.familyId)) {
        return { status: "family_revoked", familyId: token.familyId };
      }

      // Conditional consume: check if used == false
      if (token.used) {
        // Reuse detected!
        await this.revokeFamily(token.familyId);
        return { status: "reuse_detected", familyId: token.familyId };
      }

      // Mark used and create successor in same atomic transaction
      token.used = true;
      const successorId = `tok_succ_${this.tokenCounter++}`;
      this.tokens.set(successorId, {
        id: successorId,
        familyId: token.familyId,
        used: false,
        userId: token.userId,
      });

      return { status: "success", successorTokenId: successorId, familyId: token.familyId };
    };

    // Serialize access across concurrent awaits to model transactional serialization
    const currentLock = this.mutex;
    let release;
    this.mutex = new Promise((resolve) => {
      release = resolve;
    });

    await currentLock;
    try {
      return await executeInTx();
    } finally {
      release();
    }
  }
}

// Flawed non-atomic store for comparison demonstrating the race condition
class FlawedNonAtomicStore {
  constructor() {
    this.tokens = new Map();
    this.tokenCounter = 1;
  }

  seedToken(id, familyId, userId) {
    this.tokens.set(id, { id, familyId, used: false, userId });
  }

  async get(id) {
    // Simulated async network delay before returning
    await new Promise((r) => setTimeout(r, 10));
    return this.tokens.get(id) || null;
  }

  async markUsed(id) {
    await new Promise((r) => setTimeout(r, 10));
    const t = this.tokens.get(id);
    if (t) t.used = true;
  }

  async create(userId, familyId) {
    const successorId = `flawed_succ_${this.tokenCounter++}`;
    this.tokens.set(successorId, { id: successorId, familyId, used: false, userId });
    return successorId;
  }
}

async function flawedRotate(tokenId, store) {
  const token = await store.get(tokenId);
  if (!token) throw new Error("UNAUTHORIZED: Unknown token");
  if (token.used) {
    throw new Error("SECURITY_ALERT: Token reuse detected");
  }
  await store.markUsed(token.id);
  return store.create(token.userId, token.familyId);
}

async function runTests() {
  console.log("🧪 Running Refresh-Token Concurrency Verification");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // 1. Verify that flawed non-atomic pattern suffers from race condition
  {
    const flawedStore = new FlawedNonAtomicStore();
    flawedStore.seedToken("tok_flawed_1", "fam_flawed", "user_1");

    const [res1, res2] = await Promise.all([
      flawedRotate("tok_flawed_1", flawedStore),
      flawedRotate("tok_flawed_1", flawedStore),
    ]);

    // Both succeeded! (The defect identified in audit finding 1)
    assert(res1 && res2 && res1 !== res2, "Flawed pattern issued duplicate successors");
    console.log("  ✅ PASS: Verified flawed non-atomic pattern produces race condition (duplicate successors issued)");
  }

  // 2. AC-1: Given two concurrent refresh-token exchanges, at most ONE successor issues and reuse triggers family revocation
  const atomicStore = new AtomicTokenStore();
  const initialToken = "tok_valid_001";
  const familyId = "fam_alpha";
  atomicStore.seedToken(initialToken, familyId, "user_123");

  const results = await Promise.allSettled([
    rotateRefreshToken(initialToken, atomicStore),
    rotateRefreshToken(initialToken, atomicStore),
  ]);

  const fulfilled = results.filter((r) => r.status === "fulfilled");
  const rejected = results.filter((r) => r.status === "rejected");

  assert.strictEqual(fulfilled.length, 1, "Exactly one exchange must succeed");
  assert.strictEqual(rejected.length, 1, "Exactly one exchange must fail with reuse detection");

  const winningSuccessor = fulfilled[0].value;
  assert(winningSuccessor.startsWith("tok_succ_"), "Successor token must be minted for winner");
  assert.match(rejected[0].reason.message, /SECURITY_ALERT: Token reuse detected; family revoked/);

  console.log("  ✅ PASS: AC-1 verified: Exactly 1 successor issued; parallel call caught reuse and triggered family revocation");

  // 3. AC-2: Given a revoked token family, no member token remains usable
  // Check winning successor:
  await assert.rejects(
    async () => {
      await rotateRefreshToken(winningSuccessor, atomicStore);
    },
    /UNAUTHORIZED: Token family is revoked/,
    "Winning successor must be unusable once family is revoked"
  );

  // Check original token:
  await assert.rejects(
    async () => {
      await rotateRefreshToken(initialToken, atomicStore);
    },
    /UNAUTHORIZED: Token family is revoked/,
    "Original token must be unusable once family is revoked"
  );

  console.log("  ✅ PASS: AC-2 verified: Post-revocation unusability confirmed for all family tokens");

  // 4. Sequential valid rotation when no race condition exists
  const cleanStore = new AtomicTokenStore();
  cleanStore.seedToken("tok_clean_1", "fam_clean", "user_456");

  const succ1 = await rotateRefreshToken("tok_clean_1", cleanStore);
  assert(succ1, "First rotation must succeed");

  const succ2 = await rotateRefreshToken(succ1, cleanStore);
  assert(succ2, "Second rotation using valid successor must succeed");

  // Re-presenting old token triggers reuse
  await assert.rejects(
    async () => {
      await rotateRefreshToken("tok_clean_1", cleanStore);
    },
    /SECURITY_ALERT: Token reuse detected; family revoked/,
    "Re-presenting already consumed token must trigger reuse alert"
  );

  console.log("  ✅ PASS: Sequential single-use rotation and reuse detection confirmed");

  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("🎉 All refresh-token concurrency tests passed!");
}

runTests().catch((err) => {
  console.error("❌ Test failed:", err);
  process.exit(1);
});
