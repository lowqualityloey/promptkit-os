#!/usr/bin/env node
/**
 * Deterministic Concurrency Verification for Refresh Token Rotation (Issue #465)
 *
 * Verifies:
 * 1. Automatic parity with docs/recipes/auth-session.md:
 *    - Validates discriminated union requires familyId on reuse_detected.
 *    - Validates unconditional store.revokeFamily(result.familyId) in the recipe text.
 *    - Extracts and tests the exact rotateRefreshToken implementation from the recipe.
 * 2. AC-1: Given two concurrent refresh-token exchanges presenting the same valid token:
 *    - At most one successor token issues.
 *    - The losing exchange detects reuse and calls store.revokeFamily unconditionally.
 *    - The adapter does NOT revoke internally, proving that the wrapper performs the revocation.
 * 3. AC-2: Given a revoked token family:
 *    - Presenting any member token fails with UNAUTHORIZED: Token family is revoked.
 * 4. Isolated wrapper verification:
 *    - Direct adapter returning reuse_detected without internal revocation triggers store.revokeFamily.
 * 5. Flawed comparison:
 *    - Non-atomic read/write pattern demonstrably permits duplicate successor issuance.
 */

import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const recipePath = path.resolve(__dirname, "../../docs/recipes/auth-session.md");

// 1. Parity validation & dynamic extraction from docs/recipes/auth-session.md
assert(fs.existsSync(recipePath), `Recipe file missing: ${recipePath}`);
const recipeContent = fs.readFileSync(recipePath, "utf8");

// Assert recipe publishes discriminated union requiring familyId on reuse_detected
assert(
  /\|\s*\{\s*status:\s*"reuse_detected";\s*familyId:\s*string\s*\}/.test(recipeContent),
  "docs/recipes/auth-session.md must require familyId in RotationResult for reuse_detected"
);

// Assert recipe publishes unconditional store.revokeFamily without conditional bypass
assert(
  recipeContent.includes("await store.revokeFamily(result.familyId);"),
  "docs/recipes/auth-session.md must unconditionally call await store.revokeFamily(result.familyId)"
);
assert(
  !recipeContent.includes("if (result.familyId) await store.revokeFamily"),
  "docs/recipes/auth-session.md must not conditionally guard revokeFamily (familyId is required)"
);

// Extract Pattern C implementation directly from recipe
const patternCMatch = recipeContent.match(
  /### Pattern C: Refresh Token Rotation[^\n]*\n\n```typescript\n([\s\S]*?)\n```/
);
assert(patternCMatch, "Failed to locate Pattern C code block in docs/recipes/auth-session.md");

const tsCode = patternCMatch[1];

// Strip TypeScript annotations for direct Node.js execution
const jsFunctionCode = tsCode
  .replace(/export type RotationResult[\s\S]*?;\n/, "")
  .replace(/export async function rotateRefreshToken\([\s\S]*?\): Promise<string> \{/, "async function rotateRefreshToken(tokenId, store) {");

// Compile the extracted recipe function
const createRecipeFunction = new Function(`${jsFunctionCode}\nreturn rotateRefreshToken;`);
const rotateRefreshToken = createRecipeFunction();

// 2. Atomic store simulating transaction/CAS
// NOTE: consumeAndRotate deliberately DOES NOT revoke families internally upon reuse.
// This ensures that family revocation can ONLY occur if rotateRefreshToken invokes store.revokeFamily.
class AtomicTokenStore {
  constructor() {
    this.tokens = new Map(); // id -> { id, familyId, used, userId }
    this.revokedFamilies = new Set();
    this.tokenCounter = 1;
    this.mutex = Promise.resolve();
    this.revokeFamilyCallCount = 0;
  }

  seedToken(id, familyId, userId) {
    this.tokens.set(id, { id, familyId, used: false, userId });
  }

  async revokeFamily(familyId) {
    this.revokeFamilyCallCount++;
    this.revokedFamilies.add(familyId);
  }

  async consumeAndRotate(tokenId) {
    const executeInTx = async () => {
      const token = this.tokens.get(tokenId);
      if (!token) {
        return { status: "not_found" };
      }

      if (this.revokedFamilies.has(token.familyId)) {
        return { status: "family_revoked", familyId: token.familyId };
      }

      // Conditional consume
      if (token.used) {
        // Return reuse detected with required familyId.
        // DO NOT revoke internally: store.revokeFamily must be invoked by the caller.
        return { status: "reuse_detected", familyId: token.familyId };
      }

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

// 3. Flawed non-atomic store for comparison demonstrating the race condition
class FlawedNonAtomicStore {
  constructor() {
    this.tokens = new Map();
    this.tokenCounter = 1;
  }

  seedToken(id, familyId, userId) {
    this.tokens.set(id, { id, familyId, used: false, userId });
  }

  async get(id) {
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

  // 1. Verify published recipe parity and function extraction
  console.log("  ✅ PASS: Published recipe parity verified (discriminated union requires familyId; unconditional revocation)");

  // 2. Verify flawed non-atomic pattern suffers from race condition
  {
    const flawedStore = new FlawedNonAtomicStore();
    flawedStore.seedToken("tok_flawed_1", "fam_flawed", "user_1");

    const [res1, res2] = await Promise.all([
      flawedRotate("tok_flawed_1", flawedStore),
      flawedRotate("tok_flawed_1", flawedStore),
    ]);

    assert(res1 && res2 && res1 !== res2, "Flawed pattern issued duplicate successors");
    console.log("  ✅ PASS: Verified flawed non-atomic pattern produces race condition (duplicate successors issued)");
  }

  // 3. Verify wrapper mandatory revocation in isolation
  {
    let revoked = false;
    let targetRevokedFamily = null;
    const isolatedStore = {
      async consumeAndRotate(id) {
        return { status: "reuse_detected", familyId: "fam_isolated_99" };
      },
      async revokeFamily(familyId) {
        revoked = true;
        targetRevokedFamily = familyId;
      },
    };

    await assert.rejects(
      async () => {
        await rotateRefreshToken("tok_any", isolatedStore);
      },
      /SECURITY_ALERT: Token reuse detected; family revoked/,
      "Wrapper must reject on reuse_detected"
    );

    assert.strictEqual(revoked, true, "Wrapper must invoke store.revokeFamily");
    assert.strictEqual(targetRevokedFamily, "fam_isolated_99", "Wrapper must pass correct familyId to revokeFamily");
    console.log("  ✅ PASS: Isolated wrapper verification: store.revokeFamily invoked unconditionally with required familyId");
  }

  // 4. AC-1: Given two concurrent refresh-token exchanges, at most ONE successor issues and reuse triggers family revocation
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

  // Assert store.revokeFamily was called and added familyId to revokedFamilies
  assert.strictEqual(atomicStore.revokeFamilyCallCount, 1, "store.revokeFamily must be called by wrapper");
  assert(atomicStore.revokedFamilies.has(familyId), "Family must be marked revoked");

  console.log("  ✅ PASS: AC-1 verified: Exactly 1 successor issued; parallel call caught reuse and triggered family revocation");

  // 5. AC-2: Given a revoked token family, no member token remains usable
  await assert.rejects(
    async () => {
      await rotateRefreshToken(winningSuccessor, atomicStore);
    },
    /UNAUTHORIZED: Token family is revoked/,
    "Winning successor must be unusable once family is revoked"
  );

  await assert.rejects(
    async () => {
      await rotateRefreshToken(initialToken, atomicStore);
    },
    /UNAUTHORIZED: Token family is revoked/,
    "Original token must be unusable once family is revoked"
  );

  console.log("  ✅ PASS: AC-2 verified: Post-revocation unusability confirmed for all family tokens");

  // 6. Sequential valid rotation when no race condition exists
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

  assert(cleanStore.revokedFamilies.has("fam_clean"), "Family must be revoked after re-presenting old token");
  console.log("  ✅ PASS: Sequential single-use rotation and reuse detection confirmed");

  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("🎉 All refresh-token concurrency tests passed!");
}

runTests().catch((err) => {
  console.error("❌ Test failed:", err);
  process.exit(1);
});
