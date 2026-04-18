#!/usr/bin/env bash
# Sync source into the %oxal desk on the test pier and commit.
# Thin wrapper over .dojo.sh for the common dev loop.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/.dojo.sh" \
  oxal:master-migrev-dolseg \
  150 \
  '|commit %oxal' \
  --sync="${SCRIPT_DIR}/.piers/master-migrev-dolseg/oxal"
