#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Apply pi-patches to pi's installed node_modules.
# Run after `npm install -g @earendil-works/pi-coding-agent` or any pi upgrade.
#
# Usage: bash patches/apply.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_FILE="$SCRIPT_DIR/patches.json"
SOURCES_FILE="$SCRIPT_DIR/sources.json"

# Find every visible pi install under the @earendil-works scope. Developers often
# have both Homebrew and nvm pi binaries; patching only `command -v pi` lets one
# terminal pass while another crashes at runtime.
if ! PI_PKGS_RAW="$(node <<'NODE'
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const candidates = [];
function add(candidate) {
  if (!candidate) return;
  try { candidate = fs.realpathSync(candidate); } catch {}
  if (fs.existsSync(path.join(candidate, "package.json"))) candidates.push(candidate);
}
function addFromBin(bin) {
  if (!bin) return;
  try {
    const realBin = fs.realpathSync(bin);
    add(path.resolve(path.dirname(realBin), ".."));
  } catch {}
  add(path.resolve(path.dirname(bin), "../lib/node_modules/@earendil-works/pi-coding-agent"));
}
try {
  for (const bin of execFileSync("which", ["-a", "pi"], { encoding: "utf8" }).split(/\n+/).filter(Boolean)) addFromBin(bin);
} catch {}
const nvmRoot = path.join(process.env.HOME, ".nvm/versions/node");
add(path.join(nvmRoot, process.version, "lib/node_modules/@earendil-works/pi-coding-agent"));
for (const name of fs.existsSync(nvmRoot) ? fs.readdirSync(nvmRoot) : []) {
  add(path.join(nvmRoot, name, "lib/node_modules/@earendil-works/pi-coding-agent"));
}
const seen = new Set();
const unique = candidates.filter((candidate) => !seen.has(candidate) && seen.add(candidate));
if (unique.length === 0) process.exit(1);
console.log(unique.join("\n"));
NODE
)"; then
  echo "ERROR: pi-coding-agent not found. Is pi installed?" >&2
  exit 1
fi

while IFS= read -r PI_PKG; do
PI_VERSION=$(node -p "require('$PI_PKG/package.json').version")
echo "→ Patching pi $PI_VERSION at $PI_PKG"

if ! PI_PKG="$PI_PKG" node -e 'require.resolve("unicodeit", { paths: [process.env.PI_PKG] })' >/dev/null 2>&1; then
  echo "→ Installing unicodeit for terminal LaTeX rendering"
  npm install --prefix "$PI_PKG" --no-save --omit=dev --ignore-scripts unicodeit@0.7.5 >/dev/null
fi

PI_PKG="$PI_PKG" SCRIPT_DIR="$SCRIPT_DIR" PATCHES_FILE="$PATCHES_FILE" SOURCES_FILE="$SOURCES_FILE" node --input-type=module <<'SCRIPT' 
import { existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";

const piPkg = process.env.PI_PKG;
const scriptDir = process.env.SCRIPT_DIR;
const basePatchesFile = process.env.PATCHES_FILE;
const sourcesFile = process.env.SOURCES_FILE;
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
done <<< "$PI_PKGS_RAW"
