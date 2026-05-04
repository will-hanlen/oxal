#!/usr/bin/env bash
# Sync source into the %oxal desk on every ship listed in .env's
# OXAL_SHIPS, then |commit %oxal on each. Thin shim over .dojo-fan.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/.dojo-fan.sh" '|commit %oxal' --sync
