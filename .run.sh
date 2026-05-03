#!/usr/bin/env bash
# Run an arbitrary dojo command on the test ship (no sync).
# Thin wrapper over .dojo.sh.

set -euo pipefail

COMMAND="${1:?Usage: sh .run.sh <dojo-command>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: ${ENV_FILE} not found. Copy .env.example to .env and edit." >&2
  exit 1
fi
set -a; . "$ENV_FILE"; set +a

exec "${SCRIPT_DIR}/.dojo.sh" "${OXAL_TMUX_TARGET}" "${OXAL_TIMEOUT}" "${COMMAND}"
