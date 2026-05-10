#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Explicit one-shot Pi upgrade flow: reinstall pi globally, re-apply local
# pi-patches, then verify them. This is intentionally separate from pi-update,
# which now launches an interactive review session instead of mutating installs.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_BIN="$(command -v pi || true)"

if [ -z "$PI_BIN" ]; then
  echo "ERROR: pi not found on PATH. Install pi before running pi-patches." >&2
  exit 1
fi

PI_NPM="$(command -v npm || true)"

if [ -z "$PI_NPM" ] || [ ! -x "$PI_NPM" ]; then
  echo "ERROR: npm not found on PATH." >&2
  exit 1
fi

PI_PREFIX="$("$PI_NPM" prefix -g)"
if [ -z "$PI_PREFIX" ] || [ ! -d "$PI_PREFIX" ]; then
  echo "ERROR: could not determine npm global prefix from $PI_NPM." >&2
  exit 1
fi

read -r -p "This will run npm install -g and mutate your active Pi install. Continue? [y/N] " answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Aborted."; exit 0 ;;
esac

echo "→ Updating pi via $PI_NPM..."
# Pi moved npm scopes in 0.74.0. Use the new package name; --force lets npm
# replace the existing `pi` bin when it is still owned by the legacy package.
"$PI_NPM" install -g --force --prefix "$PI_PREFIX" @earendil-works/pi-coding-agent@latest

echo "→ Re-applying local pi patches..."
bash "$SCRIPT_DIR/apply.sh"

echo "→ Verifying patched install..."
bash "$SCRIPT_DIR/test.sh"

echo "→ pi upgrade complete ✓"
