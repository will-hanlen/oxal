#!/usr/bin/env bash
# Sync source into the %oxal desk, commit, then trigger the doctest
# runner via HTTP and print the response.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Sync + commit
"${SCRIPT_DIR}/.commit.sh"

# Trigger the runner
echo
echo "=> running doctests via /oxal/doctest"
echo
curl -sS -X GET http://localhost:80/oxal/doctest
echo
