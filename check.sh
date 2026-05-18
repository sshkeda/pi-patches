#!/usr/bin/env bash
# Lightweight repo checks for pi-patches. Does not mutate any Pi install.
# Use `bash check.sh --with-tests` to also run the installed-Pi behavioral suite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

WITH_TESTS=0
case "${1-}" in
  "") ;;
  --with-tests) WITH_TESTS=1 ;;
  *) echo "Usage: bash check.sh [--with-tests]" >&2; exit 2 ;;
esac

echo "→ Validating JSON manifests and source data..."
node --input-type=module <<'SCRIPT'
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

function loadJson(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    throw new Error(`${path}: ${error.message}`);
  }
}

const patches = loadJson("patches.json");
if (!Array.isArray(patches) && !Array.isArray(patches?.patches)) {
  throw new Error("patches.json must be an array or contain a patches array");
}

const extensions = loadJson("pi-update-extensions.json");
if (!Array.isArray(extensions) || extensions.some((name) => typeof name !== "string" || !name.trim())) {
  throw new Error("pi-update-extensions.json must be an array of non-empty strings");
}

const sources = loadJson("sources.json");
if (!Array.isArray(sources)) throw new Error("sources.json must be an array");

for (const source of sources) {
  const manifestRef = typeof source === "string" ? source : source?.manifest;
  if (!manifestRef) throw new Error(`Invalid source entry: ${JSON.stringify(source)}`);
  const manifestPath = manifestRef.startsWith("/") ? manifestRef : join(process.cwd(), manifestRef);
  if (!existsSync(manifestPath)) throw new Error(`External manifest missing: ${manifestRef}`);
  const manifest = loadJson(manifestPath);
  if (!Array.isArray(manifest) && !Array.isArray(manifest?.patches)) {
    throw new Error(`${manifestRef} must be an array or contain a patches array`);
  }
}
SCRIPT

echo "→ Checking shell scripts..."
bash -n apply.sh check.sh pi-update test.sh update.sh upgrade.sh

echo "→ Checking JavaScript helpers..."
node --check pi-update-prefill-extension.js

if [ "$WITH_TESTS" -eq 1 ]; then
  echo "→ Running installed-Pi behavioral tests..."
  bash test.sh
fi

echo "→ check.sh passed ✓"
