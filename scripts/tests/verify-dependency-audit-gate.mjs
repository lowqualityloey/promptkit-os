#!/usr/bin/env node
/**
 * Deterministic verification for the Dependency Audit recipe (docs/recipes/dependency-audit.md).
 *
 * Verifies:
 * 1. Parity with the recipe text:
 *    - Pattern A no longer matches exceptions against via.source (a number) or via.url (a full URL).
 *    - Pattern A parses the GHSA id out of via.url before consulting the ledger.
 *    - Pattern A drops ledger rows with an empty, whitespace, or non-string advisory id,
 *      and normalizes case.
 *    - Pattern A blocks when any single advisory is unexcepted, not only when all are.
 *    - Pattern A treats an unrecognized severity as above every threshold.
 *    - Pattern B records the same GHSA id shape the ledger stores.
 * 2. Behaviour of the extracted Pattern A gate against a realistic npm audit --json payload:
 *    - An active exception suppresses its advisory.
 *    - An expired exception stops suppressing it, with no edit to the gate.
 *    - The severity threshold still admits everything at or above it.
 *    - A malformed ledger row suppresses nothing; a lowercase row still matches.
 *    - A non-string advisory id is a malformed row, not a crash.
 *    - A package with one excepted and one unexcepted advisory still blocks.
 *    - An unrecognized severity blocks instead of passing silently.
 * 3. The regressions themselves: the pre-fix comparison demonstrably fails to suppress
 *    an advisory the ledger has an active exception for, the pre-fix ledger demonstrably
 *    fails open on an empty advisory id, the pre-fix aggregation demonstrably suppresses
 *    a package over one excepted advisory, and the pre-fix threshold lookup demonstrably
 *    passes an unrecognized severity.
 *
 * The fixture is synthetic and local-only. No network, no npm invocation, no real advisory ids.
 */

import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const recipePath = path.resolve(__dirname, "../../docs/recipes/dependency-audit.md");
const fixtureDir = path.resolve(__dirname, "fixtures/dependency-audit");
const reportPath = path.join(fixtureDir, "npm-audit-report.json");
const exceptionsPath = path.join(fixtureDir, "audit-exceptions.json");

// ---------------------------------------------------------------------------
// 1. Parity validation against the recipe text
// ---------------------------------------------------------------------------

assert(fs.existsSync(recipePath), `Recipe file missing: ${recipePath}`);
const recipeContent = fs.readFileSync(recipePath, "utf8").replace(/\r\n/g, "\n");

assert(
  !recipeContent.includes("via.source ?? via.url"),
  "docs/recipes/dependency-audit.md must not match exceptions against via.source or via.url directly"
);

assert(
  /const ghsa = \(via: any\) =>\n  \(String\(via\.url \?\? ""\)\.match\(\/GHSA-\[\\w-\]\+\/i\)\?\.\[0\] \?\? ""\)\.toUpperCase\(\);/.test(
    recipeContent
  ),
  "docs/recipes/dependency-audit.md must parse the GHSA id out of via.url and normalize it before consulting the ledger"
);

assert(
  /\.filter\(\(e\) => e\.expires >= today && typeof e\.advisory === "string" && e\.advisory\.trim\(\)\)/.test(
    recipeContent
  ),
  "docs/recipes/dependency-audit.md must drop ledger rows whose advisory id is empty, whitespace, or not a string"
);

assert(
  /\.map\(\(e\) => e\.advisory\.trim\(\)\.toUpperCase\(\)\)/.test(recipeContent),
  "docs/recipes/dependency-audit.md must normalize ledger ids to uppercase before comparison"
);

assert(
  /active\.has\(ghsa\(via\)\)/.test(recipeContent),
  "docs/recipes/dependency-audit.md must consult the ledger with the parsed GHSA id"
);

assert(
  /v\.via\.some\(\(via: any\) => !active\.has\(ghsa\(via\)\)\)/.test(recipeContent),
  "docs/recipes/dependency-audit.md must block when any single advisory is unexcepted, not only when every advisory is"
);

assert(
  /\(RANK\[v\.severity as keyof typeof RANK\] \?\? Infinity\) >= THRESHOLD/.test(recipeContent),
  "docs/recipes/dependency-audit.md must treat an unrecognized severity as above every threshold"
);

assert(
  /"advisory": "GHSA-xxxx-xxxx-xxxx"/.test(recipeContent),
  "docs/recipes/dependency-audit.md Pattern B must record the GHSA id shape the ledger stores"
);

// ---------------------------------------------------------------------------
// 2. Extract and transpile Pattern A
// ---------------------------------------------------------------------------

const patternAMatch = recipeContent.match(
  /### Pattern A: CI Gate with a Threshold and an Exception Ledger\n\n```typescript\n([\s\S]*?)\n```/
);
assert(patternAMatch, "Failed to locate Pattern A code block in docs/recipes/dependency-audit.md");

const jsCode = patternAMatch[1]
  .replace(/import \{ execFileSync \} from "node:child_process";\n/, "")
  .replace(/import \{ readFileSync \} from "node:fs";\n/, "")
  .replace(/interface Exception \{[\s\S]*?\n\}\n\n/, "")
  .replace(/ as const/g, "")
  .replace(/const exceptions: Exception\[\] = /, "const exceptions = ")
  .replace(/\(via: any\) =>/g, "(via) =>")
  .replace(/\(v: any\) =>/g, "(v) =>")
  .replace(/RANK\[v\.severity as keyof typeof RANK\]/g, "RANK[v.severity]");

assert(
  !/\bany\b/.test(jsCode.replace(/\/\/.*$/gm, "")),
  "Pattern A transpilation left a TypeScript annotation behind"
);

// The recipe exits before returning, so capture the blocking set at the point it is
// computed. This is the only instrumentation added to the extracted code.
const instrumented = jsCode.replace(
  "if (blocking.length > 0) {",
  "__capture(blocking);\nif (blocking.length > 0) {"
);
assert(
  instrumented !== jsCode,
  "Failed to instrument Pattern A: the blocking guard moved, update the harness"
);

class GateExit extends Error {
  constructor(code) {
    super(`gate exited with ${code}`);
    this.code = code;
  }
}

/**
 * Execute the recipe's own Pattern A gate against a supplied audit report and ledger.
 * readFileSync and execFileSync are injected so the gate never touches the network or npm.
 */
function runGate(reportJson, exceptionsJson) {
  const errors = [];
  let exitCode = null;
  const fakeProcess = {
    env: {},
    exit(code) {
      exitCode = code;
      throw new GateExit(code);
    },
  };
  const fakeConsole = { error: (message) => errors.push(String(message)) };

  let blocking = [];
  const factory = new Function(
    "readFileSync",
    "execFileSync",
    "process",
    "console",
    "__capture",
    `${instrumented}\nreturn blocking;`
  );

  try {
    factory(
      () => exceptionsJson,
      () => reportJson,
      fakeProcess,
      fakeConsole,
      (value) => {
        blocking = value;
      }
    );
  } catch (err) {
    if (!(err instanceof GateExit)) throw err;
  }

  return { blocking, errors, exitCode };
}

const reportJson = fs.readFileSync(reportPath, "utf8");
const exceptionsJson = fs.readFileSync(exceptionsPath, "utf8");
const report = JSON.parse(reportJson);
const exceptions = JSON.parse(exceptionsJson);

const names = (result) => result.blocking.map((v) => v.name).sort();

// ---------------------------------------------------------------------------
// 3. Behavioural cases
// ---------------------------------------------------------------------------

const cases = [];
function test(name, fn) {
  cases.push({ name, fn });
}

test("active exception suppresses its advisory", () => {
  const result = runGate(reportJson, exceptionsJson);
  const blocked = names(result);
  assert(
    !blocked.includes("example-parser"),
    `example-parser has an active exception but was blocked: ${blocked.join(", ")}`
  );
  assert(
    !blocked.includes("patched-lib"),
    `patched-lib has an active exception but was blocked: ${blocked.join(", ")}`
  );
});

test("expired exception re-opens the gate without an edit", () => {
  const result = runGate(reportJson, exceptionsJson);
  const blocked = names(result);
  assert(
    blocked.includes("legacy-crypto"),
    `legacy-crypto has an expired exception and must block, got: ${blocked.join(", ")}`
  );
});

test("extending the expiry suppresses the same advisory", () => {
  const extended = exceptions.map((e) =>
    e.advisory === "GHSA-dddd-eeee-ffff" ? { ...e, expires: "2099-01-01" } : e
  );
  const result = runGate(reportJson, JSON.stringify(extended));
  const blocked = names(result);
  assert(
    !blocked.includes("legacy-crypto"),
    `legacy-crypto should be suppressed once its expiry moves forward, got: ${blocked.join(", ")}`
  );
});

test("a malformed ledger row suppresses nothing", () => {
  const baseline = names(runGate(reportJson, exceptionsJson));
  for (const malformed of ["", "   "]) {
    const ledger = [...exceptions, { ...exceptions[0], advisory: malformed }];
    const blocked = names(runGate(reportJson, JSON.stringify(ledger)));
    assert.deepStrictEqual(
      blocked,
      baseline,
      `a ledger row with advisory ${JSON.stringify(malformed)} must not suppress anything (baseline=${baseline.join(", ")}, got=${blocked.join(", ")})`
    );
  }
  const missing = [...exceptions, { owner: "x", expires: "2099-01-01", reachability: "y" }];
  assert.deepStrictEqual(
    names(runGate(reportJson, JSON.stringify(missing))),
    baseline,
    "a ledger row with no advisory field must not suppress anything"
  );
});

test("a non-string advisory id is a malformed row, not a crash", () => {
  const baseline = names(runGate(reportJson, exceptionsJson));
  for (const malformed of [1098392, {}, [], null, true]) {
    const ledger = [...exceptions, { ...exceptions[0], advisory: malformed }];
    let blocked;
    assert.doesNotThrow(() => {
      blocked = names(runGate(reportJson, JSON.stringify(ledger)));
    }, `a ledger row with advisory ${JSON.stringify(malformed)} must not throw`);
    assert.deepStrictEqual(
      blocked,
      baseline,
      `a ledger row with advisory ${JSON.stringify(malformed)} must not suppress anything (baseline=${baseline.join(", ")}, got=${blocked.join(", ")})`
    );
  }
});

test("a lowercase ledger entry still suppresses its advisory", () => {
  const lowered = exceptions.map((e) => ({ ...e, advisory: e.advisory.toLowerCase() }));
  const blocked = names(runGate(reportJson, JSON.stringify(lowered)));
  assert(
    !blocked.includes("example-parser"),
    `a lowercase ledger id must still suppress example-parser, got: ${blocked.join(", ")}`
  );
  assert(
    !blocked.includes("patched-lib"),
    `a lowercase ledger id must still suppress patched-lib, got: ${blocked.join(", ")}`
  );
  assert(
    blocked.includes("legacy-crypto"),
    `lowercasing must not revive an expired exception, got: ${blocked.join(", ")}`
  );
});

test("a package with one excepted and one unexcepted advisory still blocks", () => {
  const result = runGate(reportJson, exceptionsJson);
  const blocked = names(result);
  assert(
    blocked.includes("multi-vuln"),
    `multi-vuln has one excepted and one unexcepted advisory and must block, got: ${blocked.join(", ")}`
  );
  const vias = report.vulnerabilities["multi-vuln"].via;
  assert.strictEqual(vias.length, 2, "the multi-vuln fixture must carry exactly two advisories");
  const excepted = vias.filter((via) => exceptions.some((e) => e.advisory === via.url.split("/").pop()));
  assert.strictEqual(
    excepted.length,
    1,
    "exactly one of multi-vuln's advisories must be excepted, or the case proves nothing"
  );
});

test("an unrecognized severity blocks instead of passing silently", () => {
  for (const severity of ["HIGH", "unknown", "Critical", ""]) {
    const mutated = JSON.parse(reportJson);
    mutated.vulnerabilities["tiny-http"].severity = severity;
    const result = runGate(JSON.stringify(mutated), exceptionsJson);
    assert(
      names(result).includes("tiny-http"),
      `severity ${JSON.stringify(severity)} is not a RANK key and must block rather than pass, got: ${names(result).join(", ")}`
    );
  }
});

test("the pre-fix aggregation demonstrably suppresses a package over one excepted advisory", () => {
  const RANK = { info: 0, low: 1, moderate: 2, high: 3, critical: 4 };
  const THRESHOLD = RANK.high;
  const today = new Date().toISOString().slice(0, 10);
  const active = new Set(
    exceptions
      .filter((e) => e.expires >= today && e.advisory?.trim())
      .map((e) => e.advisory.trim().toUpperCase())
  );
  const ghsa = (via) => (String(via.url ?? "").match(/GHSA-[\w-]+/i)?.[0] ?? "").toUpperCase();

  // The pre-fix aggregation suppressed the whole package when any one via matched.
  const legacyBlocking = Object.values(report.vulnerabilities ?? {}).filter(
    (v) => RANK[v.severity] >= THRESHOLD && !v.via.some((via) => active.has(ghsa(via)))
  );
  assert(
    !legacyBlocking.map((v) => v.name).includes("multi-vuln"),
    "the pre-fix aggregation should suppress multi-vuln over its one excepted advisory; if it no longer does, the fixture no longer exercises the defect"
  );
  assert(
    names(runGate(reportJson, exceptionsJson)).includes("multi-vuln"),
    "the fixed aggregation must block multi-vuln"
  );
});

test("the pre-fix threshold lookup demonstrably passes an unrecognized severity", () => {
  const RANK = { info: 0, low: 1, moderate: 2, high: 3, critical: 4 };
  const THRESHOLD = RANK.high;
  const mutated = JSON.parse(reportJson);
  mutated.vulnerabilities["tiny-http"].severity = "HIGH";

  // The pre-fix lookup read RANK["HIGH"], which is undefined, and undefined >= 3 is false.
  const legacyBlocking = Object.values(mutated.vulnerabilities).filter(
    (v) => RANK[v.severity] >= THRESHOLD
  );
  assert(
    !legacyBlocking.map((v) => v.name).includes("tiny-http"),
    "the pre-fix threshold lookup should pass an unrecognized severity; if it no longer does, the case no longer exercises the defect"
  );
  assert(
    names(runGate(JSON.stringify(mutated), exceptionsJson)).includes("tiny-http"),
    "the fixed threshold lookup must block an unrecognized severity"
  );
});

test("severity threshold still admits everything at or above it", () => {
  const result = runGate(reportJson, exceptionsJson);
  const blocked = names(result);
  assert(
    blocked.includes("tiny-http"),
    `tiny-http is high severity with no exception and must block, got: ${blocked.join(", ")}`
  );
  assert(
    !blocked.includes("dev-linter"),
    `dev-linter is moderate and below the threshold, got: ${blocked.join(", ")}`
  );
  assert(
    !blocked.includes("safe-util"),
    `safe-util is low and below the threshold, got: ${blocked.join(", ")}`
  );
});

test("a blocking advisory exits non-zero and names itself", () => {
  const result = runGate(reportJson, exceptionsJson);
  assert.strictEqual(result.exitCode, 1, "the gate must exit 1 when anything blocks");
  assert(
    result.errors.some((line) => line.includes("legacy-crypto")),
    `the gate must name the blocking advisory, got: ${result.errors.join(" | ")}`
  );
});

test("a clean report exits zero and prints nothing", () => {
  const clean = {
    auditReportVersion: 2,
    vulnerabilities: {
      "dev-linter": report.vulnerabilities["dev-linter"],
      "safe-util": report.vulnerabilities["safe-util"],
    },
    metadata: report.metadata,
  };
  const result = runGate(JSON.stringify(clean), exceptionsJson);
  assert.deepStrictEqual(names(result), [], "nothing at or above the threshold should block");
  assert.strictEqual(result.exitCode, null, "the gate must not exit when nothing blocks");
  assert.deepStrictEqual(result.errors, [], "the gate must stay silent when nothing blocks");
});

test("the pre-fix comparison demonstrably fails to suppress", () => {
  const RANK = { info: 0, low: 1, moderate: 2, high: 3, critical: 4 };
  const THRESHOLD = RANK.high;
  const today = new Date().toISOString().slice(0, 10);
  const active = new Set(
    exceptions.filter((e) => e.expires >= today).map((e) => e.advisory)
  );

  const legacyBlocking = Object.values(report.vulnerabilities ?? {}).filter(
    (v) =>
      RANK[v.severity] >= THRESHOLD &&
      !v.via.some((via) => active.has(via.source ?? via.url))
  );

  const legacyNames = legacyBlocking.map((v) => v.name);
  assert(
    legacyNames.includes("example-parser"),
    "the pre-fix comparison should fail to suppress example-parser; if it now suppresses, the fixture no longer exercises the defect"
  );
  assert(
    legacyNames.includes("patched-lib"),
    "the pre-fix comparison should fail to suppress patched-lib; if it now suppresses, the fixture no longer exercises the defect"
  );

  const fixed = names(runGate(reportJson, exceptionsJson));
  assert(
    fixed.length < legacyNames.length,
    `the fixed gate must block strictly fewer advisories than the pre-fix comparison (fixed=${fixed.length}, legacy=${legacyNames.length})`
  );
});

test("the pre-fix ledger demonstrably fails open on an empty advisory id", () => {
  const RANK = { info: 0, low: 1, moderate: 2, high: 3, critical: 4 };
  const THRESHOLD = RANK.high;
  const today = new Date().toISOString().slice(0, 10);

  // The pre-fix ledger kept whatever the file held, including an empty id.
  const legacyActive = new Set(
    [...exceptions, { ...exceptions[0], advisory: "" }]
      .filter((e) => e.expires >= today)
      .map((e) => e.advisory)
  );
  const ghsa = (via) => String(via.url ?? "").match(/GHSA-[\w-]+/i)?.[0] ?? "";

  const legacyBlocking = Object.values(report.vulnerabilities ?? {}).filter(
    (v) => RANK[v.severity] >= THRESHOLD && !v.via.some((via) => legacyActive.has(ghsa(via)))
  );
  const legacyNames = legacyBlocking.map((v) => v.name);

  assert(
    !legacyNames.includes("wrapper-pkg"),
    "the pre-fix ledger should fail open and suppress wrapper-pkg's bare-string via; if it no longer does, the fixture no longer exercises the defect"
  );

  const fixed = names(runGate(reportJson, JSON.stringify([...exceptions, { ...exceptions[0], advisory: "" }])));
  assert(
    fixed.includes("wrapper-pkg"),
    `the fixed ledger must still block wrapper-pkg, got: ${fixed.join(", ")}`
  );
  assert(
    fixed.length > legacyNames.length,
    `the fixed ledger must block strictly more than the pre-fix ledger (fixed=${fixed.length}, legacy=${legacyNames.length})`
  );
});

// ---------------------------------------------------------------------------
// 4. Runner
// ---------------------------------------------------------------------------

let passed = 0;
for (const { name, fn } of cases) {
  try {
    fn();
    passed += 1;
    console.log(`  ok  ${name}`);
  } catch (err) {
    console.error(`  FAIL  ${name}`);
    console.error(`        ${err.message}`);
    process.exit(1);
  }
}

console.log(`✅ Dependency Audit recipe verified (${passed}/${cases.length} cases)`);
