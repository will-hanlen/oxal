#!/usr/bin/env bash
# Run an arbitrary dojo command on every ship listed in .env's
# OXAL_SHIPS (no sync). Thin shim over .dojo-fan.sh.

set -euo pipefail

COMMAND="${1:?Usage: sh .run.sh <dojo-command>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/.dojo-fan.sh" "${COMMAND}"
