#!/usr/bin/env bash
# Rsync source and commit %hawk on a specific pier.
#
# Usage: sh .compile.sh <ship-name>
#   e.g. sh .compile.sh walrus-migrev-dolseg
#
# The ship-name is the pier directory name under .piers/.

set -euo pipefail

SHIP="${1:?Usage: .commit.sh <ship-name>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIER_DIR="${SCRIPT_DIR}/.piers/${SHIP}"

if [ ! -d "$PIER_DIR" ]; then
  echo "Error: pier not found at ${PIER_DIR}" >&2
  echo "Available piers:" >&2
  ls "${SCRIPT_DIR}/.piers/" >&2
  exit 1
fi

# Rsync source into the pier's hawk desk
echo "Syncing source to ${SHIP}..." >&2
rsync -avL --delete --exclude='.*' "${SCRIPT_DIR}/" "${PIER_DIR}/hawk/"

# Commit via dojo
echo "Committing %hawk on ${SHIP}..." >&2
"${SCRIPT_DIR}/.dojo-cmd.sh" "hawk:${SHIP}" 360 "|commit %hawk"
