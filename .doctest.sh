#!/usr/bin/env bash
# Sync source into the %oxal desk, commit, then run the doctest
# generator on the dev ship and print its tang.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Sync + commit
"${SCRIPT_DIR}/.commit.sh"

# Run the doctest generator
echo
echo "=> running +oxal!doctest-run"
echo
exec "${SCRIPT_DIR}/.run.sh" '+oxal!doctest-run'
