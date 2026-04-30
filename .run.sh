#!/usr/bin/env bash
# Run an arbitrary dojo command on the test ship (no sync).
# Thin wrapper over .dojo.sh.

set -euo pipefail

COMMAND="${1:?Usage: sh .run.sh <dojo-command>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/.dojo.sh" oxal:ship 150 "${COMMAND}"
