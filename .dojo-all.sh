#!/usr/bin/env bash
# Send a dojo command to every running pier in .piers/ and print output.
#
# Usage: .dojo-all.sh <timeout_secs> <command>
#
# Iterates over all pier directories in .piers/ that have a live .vere.lock.
# Runs .dojo-cmd.sh against each one sequentially, printing labeled output.

set -euo pipefail

TIMEOUT="${1:?Usage: .dojo-all.sh <timeout_secs> <command>}"
COMMAND="${2:?Usage: .dojo-all.sh <timeout_secs> <command>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIERS_DIR="${SCRIPT_DIR}/.piers"

if [ ! -d "$PIERS_DIR" ]; then
  echo "No .piers/ directory found" >&2
  exit 1
fi

FOUND=0

for PIER_DIR in "$PIERS_DIR"/*/; do
  [ -d "$PIER_DIR" ] || continue
  SHIP=$(basename "$PIER_DIR")

  # Check if ship is running via .vere.lock
  LOCK="${PIER_DIR}.vere.lock"
  if [ ! -f "$LOCK" ]; then
    continue
  fi
  PID=$(cat "$LOCK" 2>/dev/null || true)
  if [ -z "$PID" ] || ! kill -0 "$PID" 2>/dev/null; then
    continue
  fi

  FOUND=$((FOUND + 1))
  echo "── ${SHIP} ──"

  if ! "${SCRIPT_DIR}/.dojo-cmd.sh" "hawk:${SHIP}" "$TIMEOUT" "$COMMAND"; then
    echo "FAILED on ${SHIP}" >&2
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "No running piers found in ${PIERS_DIR}" >&2
  exit 1
fi
