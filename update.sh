#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "→ Updating pi via npm..."
npm install -g @mariozechner/pi-coding-agent

echo "→ Re-applying local pi patches..."
bash "$SCRIPT_DIR/apply.sh"

echo "→ Verifying patched install..."
bash "$SCRIPT_DIR/test.sh"

echo "→ pi update complete ✓"
