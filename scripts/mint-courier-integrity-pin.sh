#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: mint-courier-integrity-pin.sh <courier-file> <version> <sha256>" >&2
    exit 2
fi

SOURCE_FILE="$1"
VERSION="$2"
DIGEST="$3"
export SOURCE_FILE VERSION DIGEST
node <<'NODE'
const fs = require('node:fs');

const file = process.env.SOURCE_FILE;
const version = process.env.VERSION;
const digest = process.env.DIGEST;
if (!/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/.test(version)) throw new Error(`invalid courier version: ${version}`);
if (!/^[0-9a-f]{64}$/.test(digest)) throw new Error('invalid computed SHA-256 digest');

const source = fs.readFileSync(file, 'utf8');
const key = JSON.stringify(version);
const entries = source.split('\n').filter((line) => line.trimStart().startsWith(`${key}:`));
if (entries.length > 1) throw new Error(`duplicate integrity pin for ${version}`);
if (entries.length === 1) {
  const existing = entries[0].match(/"([0-9a-f]{64})"/);
  if (!existing || existing[1] !== digest) throw new Error(`committed integrity pin for ${version} does not match archive`);
  console.log(`Existing integrity pin matches ${version}; source unchanged`);
  process.exit(0);
}

const marker = '  // @pin-insert';
if (source.split(marker).length !== 2) throw new Error('integrity pin insertion marker missing or duplicated');
fs.writeFileSync(file, source.replace(marker, `  ${key}: ${JSON.stringify(digest)},\n${marker}`));
console.log(`Inserted integrity pin for ${version}: ${digest}`);
NODE
