#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Apply pi-patches to pi's installed node_modules.
# Run after `npm install -g @mariozechner/pi-coding-agent` or any pi upgrade.
#
# Usage: bash patches/apply.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_FILE="$SCRIPT_DIR/patches.json"
SOURCES_FILE="$SCRIPT_DIR/sources.json"

# Find pi's install location
PI_PKG="$(dirname "$(which pi 2>/dev/null || echo '')")/../lib/node_modules/@mariozechner/pi-coding-agent"
if [ ! -d "$PI_PKG" ]; then
  # Fallback: check common nvm location
  PI_PKG="$HOME/.nvm/versions/node/$(node -v)/lib/node_modules/@mariozechner/pi-coding-agent"
fi

if [ ! -d "$PI_PKG" ]; then
  echo "ERROR: pi-coding-agent not found. Is pi installed?" >&2
  exit 1
fi

PI_VERSION=$(node -p "require('$PI_PKG/package.json').version")
echo "→ Patching pi $PI_VERSION"

node --input-type=module << SCRIPT
import { existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";

const piPkg = "$PI_PKG";
const scriptDir = "$SCRIPT_DIR";
const basePatchesFile = "$PATCHES_FILE";
const sourcesFile = "$SOURCES_FILE";
let errors = 0;

const fileCache = new Map();

function getContent(filePath) {
  if (!fileCache.has(filePath)) {
    fileCache.set(filePath, readFileSync(filePath, "utf8"));
  }
  return fileCache.get(filePath);
}

function loadManifest(manifestPath, sourceName) {
  const raw = JSON.parse(readFileSync(manifestPath, "utf8"));
  const patches = Array.isArray(raw) ? raw : raw.patches;
  if (!Array.isArray(patches)) {
    throw new Error("Manifest " + manifestPath + " does not contain a patches array");
  }
  const resolvedSource = sourceName || raw.name || manifestPath;
  return patches.map((patch) => ({ ...patch, _source: resolvedSource }));
}

let patches = loadManifest(basePatchesFile, "pi-patches");
if (existsSync(sourcesFile)) {
  const sources = JSON.parse(readFileSync(sourcesFile, "utf8"));
  if (!Array.isArray(sources)) {
    throw new Error("Sources file " + sourcesFile + " must contain an array");
  }
  for (const source of sources) {
    const manifestRef = typeof source === "string" ? source : source.manifest;
    const sourceName = typeof source === "string" ? undefined : source.name;
    if (!manifestRef) {
      throw new Error("Invalid source entry in " + sourcesFile + ": missing manifest");
    }
    const manifestPath = manifestRef.startsWith("/") ? manifestRef : join(scriptDir, manifestRef);
    patches = patches.concat(loadManifest(manifestPath, sourceName));
  }
}

for (const patch of patches) {
  const filePath = join(piPkg, patch.file);
  let content;

  try {
    content = getContent(filePath);
  } catch {
    console.error("  ✗ [" + patch._source + "/" + patch.id + "] FILE MISSING: " + patch.file);
    console.error("    intent: " + patch.intent);
    errors++;
    continue;
  }

  // Already patched?
  if (content.includes(patch.verify)) {
    console.log("  ⊘ " + patch._source + "/" + patch.id + " (already applied)");
    continue;
  }

  const count = content.split(patch.find).length - 1;
  const expected = patch.occurrences ?? 1;

  if (count === 0) {
    console.error("  ✗ [" + patch._source + "/" + patch.id + "] TARGET NOT FOUND in " + patch.file);
    console.error("    intent: " + patch.intent);
    errors++;
    continue;
  }

  if (count !== expected) {
    console.error("  ✗ [" + patch._source + "/" + patch.id + "] OCCURRENCE MISMATCH: expected " + expected + ", found " + count);
    errors++;
    continue;
  }

  const patched = content.replaceAll(patch.find, patch.replace);
  fileCache.set(filePath, patched);
  console.log("  ✓ " + patch._source + "/" + patch.id);
}

if (errors > 0) {
  console.error("\\n✗ " + errors + " patch(es) failed. No files modified.");
  process.exit(1);
}

for (const [filePath, content] of fileCache) {
  writeFileSync(filePath, content);
}

console.log("→ All " + patches.length + " patch(es) applied ✓");
SCRIPT
