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

PI_PREFIX="$(cd "$(dirname "$PI_BIN")/.." && pwd)"
PI_NPM="$PI_PREFIX/bin/npm"

if [ ! -x "$PI_NPM" ]; then
  echo "ERROR: npm not found next to active pi binary at $PI_NPM" >&2
  exit 1
fi

read -r -p "This will run npm install -g and mutate your active Pi install. Continue? [y/N] " answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Aborted."; exit 0 ;;
esac

echo "→ Updating pi via $PI_NPM..."
"$PI_NPM" install -g --prefix "$PI_PREFIX" @mariozechner/pi-coding-agent

echo "→ Re-applying local pi patches..."
bash "$SCRIPT_DIR/apply.sh"

echo "→ Verifying patched install..."
bash "$SCRIPT_DIR/test.sh"

echo "→ pi upgrade complete ✓"
