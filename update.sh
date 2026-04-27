#!/usr/bin/env bash
# Backwards-compatible entrypoint for existing aliases such as:
#   alias pi-update='bash /path/to/pi-patches/update.sh'
#
# pi-update now launches an interactive Pi review session instead of mutating
# the installed Pi package. Use ./upgrade.sh for the explicit install/apply/test
# flow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/pi-update" "$@"
