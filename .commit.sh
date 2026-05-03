#!/usr/bin/env bash
# Sync source into the %oxal desk on the test pier and commit.
# Thin wrapper over .dojo.sh for the common dev loop.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: ${ENV_FILE} not found. Copy .env.example to .env and edit." >&2
  exit 1
fi
set -a; . "$ENV_FILE"; set +a

exec "${SCRIPT_DIR}/.dojo.sh" \
  "${OXAL_TMUX_TARGET}" \
  "${OXAL_TIMEOUT}" \
  '|commit %oxal' \
  --sync="${SCRIPT_DIR}/${OXAL_PIER}"
