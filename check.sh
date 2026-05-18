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
node --input-type=module <<'SCRIPT'
import piUpdatePrefill from "./pi-update-prefill-extension.js";

const previousPrompt = process.env.PI_UPDATE_PREFILL_PROMPT;
const previousExitCode = process.exitCode;
const previousSetTimeout = globalThis.setTimeout;
const previousExit = process.exit;
const previousError = console.error;

try {
  const handlers = new Map();
  piUpdatePrefill({
    on(event, handler) {
      handlers.set(event, handler);
    },
  });

  for (const event of ["session_start", "model_select", "before_agent_start"]) {
    if (typeof handlers.get(event) !== "function") {
      throw new Error(`pi-update prefill did not register ${event} guard`);
    }
  }

  globalThis.setTimeout = () => ({ unref() {} });
  process.exit = ((code) => {
    throw new Error(`unexpected process.exit(${code}) during guard test`);
  });
  console.error = () => {};

  let editorText = "";
  let title = "";
  let shutdowns = 0;
  const notifications = [];
  const ctx = (model) => ({
    model,
    shutdown() {
      shutdowns += 1;
    },
    ui: {
      getEditorText: () => editorText,
      setEditorText: (value) => {
        editorText = value;
      },
      setTitle: (value) => {
        title = value;
      },
      notify: (message, level) => notifications.push({ message, level }),
    },
  });

  process.env.PI_UPDATE_PREFILL_PROMPT = "review prompt";
  process.exitCode = 0;
  await handlers.get("session_start")({}, ctx({ provider: "pi-codex", id: "gpt-5.5-fast" }));
  if (editorText !== "review prompt" || title !== "pi-update patch review") {
    throw new Error("pi-update prefill did not populate editor for the required model");
  }

  editorText = "";
  title = "";
  shutdowns = 0;
  notifications.length = 0;
  process.exitCode = 0;
  await handlers.get("session_start")({}, ctx({ provider: "google", id: "gemini-3.1-pro-preview" }));
  if (shutdowns !== 1 || process.exitCode !== 1 || !editorText.includes("requires active model pi-codex/gpt-5.5-fast")) {
    throw new Error("pi-update session_start guard did not fail fast on the wrong model");
  }
  if (notifications[0]?.level !== "error") {
    throw new Error("pi-update guard did not notify with an error level");
  }

  shutdowns = 0;
  process.exitCode = 0;
  await handlers.get("model_select")(
    { model: { provider: "google", id: "gemini-3.1-pro-preview" } },
    ctx({ provider: "pi-codex", id: "gpt-5.5-fast" }),
  );
  if (shutdowns !== 1 || process.exitCode !== 1) {
    throw new Error("pi-update model_select guard did not fail fast on a wrong selected model");
  }

  shutdowns = 0;
  process.exitCode = 0;
  await handlers.get("before_agent_start")({}, ctx({ provider: "openai", id: "gpt-5.5-fast" }));
  if (shutdowns !== 1 || process.exitCode !== 1) {
    throw new Error("pi-update before_agent_start guard did not fail fast on a wrong active provider");
  }
} finally {
  if (previousPrompt === undefined) delete process.env.PI_UPDATE_PREFILL_PROMPT;
  else process.env.PI_UPDATE_PREFILL_PROMPT = previousPrompt;
  process.exitCode = previousExitCode;
  globalThis.setTimeout = previousSetTimeout;
  process.exit = previousExit;
  console.error = previousError;
}
SCRIPT

if [ "$WITH_TESTS" -eq 1 ]; then
  echo "→ Running installed-Pi behavioral tests..."
  bash test.sh
fi

echo "→ check.sh passed ✓"
