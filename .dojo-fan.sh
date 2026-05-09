#!/usr/bin/env bash
# Fan a dojo command out to every ship listed in .env's OXAL_SHIPS,
# in parallel. Each ship's stdout/stderr is buffered to a temp file
# and then printed in declared order under a `=== ship: <name> ===`
# header. Exits non-zero if any ship's run failed.
#
# Usage: .dojo-fan.sh <command> [--sync]
#   --sync  rsync source into each ship before running. The per-ship
#           sync spec comes from OXAL_<ship>_SYNC in .env, formatted as
#           <src>:<dest> (the same shape .dojo.sh's --sync flag takes).
#           <src> is relative to the repo root; a relative <dest> is
#           resolved to the repo root before being passed through.

set -euo pipefail

COMMAND=""
SYNC=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sync) SYNC=1; shift ;;
    -*)     echo "Unknown flag: $1" >&2; exit 1 ;;
    *)
      if [ -z "$COMMAND" ]; then COMMAND="$1"
      else echo "Unexpected arg: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

if [ -z "$COMMAND" ]; then
  echo "Usage: .dojo-fan.sh <command> [--sync]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: ${ENV_FILE} not found. Copy .env.example to .env and edit." >&2
  exit 1
fi
set -a; . "$ENV_FILE"; set +a

: "${OXAL_TMUX_SESSION:?OXAL_TMUX_SESSION not set in .env}"
: "${OXAL_SHIPS:?OXAL_SHIPS not set in .env}"
: "${OXAL_TIMEOUT:?OXAL_TIMEOUT not set in .env}"

# Validate ship names: must be valid identifier chars (used in env var
# names and as tmux window names).
read -r -a SHIPS <<<"$OXAL_SHIPS"
if [ "${#SHIPS[@]}" -eq 0 ]; then
  echo "Error: OXAL_SHIPS is empty." >&2
  exit 1
fi
for ship in "${SHIPS[@]}"; do
  if ! [[ "$ship" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "Error: invalid ship alias '${ship}' (must match [A-Za-z_][A-Za-z0-9_]*)" >&2
    exit 1
  fi
  if [ "$SYNC" -eq 1 ]; then
    sync_var="OXAL_${ship}_SYNC"
    if [ -z "${!sync_var:-}" ]; then
      echo "Error: ${sync_var} not set in .env (required for --sync)" >&2
      exit 1
    fi
    if [[ "${!sync_var}" != *:* ]]; then
      echo "Error: ${sync_var} must be <src>:<dest>, got '${!sync_var}'" >&2
      exit 1
    fi
  fi
done

TMPROOT="$(mktemp -d -t oxal-fan.XXXXXX)"
trap 'rm -rf "$TMPROOT"' EXIT

# Spawn one background job per ship.
pids=()
for ship in "${SHIPS[@]}"; do
  mkdir -p "${TMPROOT}/${ship}"
  target="${OXAL_TMUX_SESSION}:${ship}"

  args=("$target" "$OXAL_TIMEOUT" "$COMMAND")
  if [ "$SYNC" -eq 1 ]; then
    sync_var="OXAL_${ship}_SYNC"
    spec="${!sync_var}"
    src="${spec%%:*}"
    dest="${spec#*:}"
    case "$dest" in
      /*|~*) ;;
      *) dest="${SCRIPT_DIR}/${dest}" ;;
    esac
    args+=(--sync="${src}:${dest}")
  fi

  (
    set +e
    "${SCRIPT_DIR}/.dojo.sh" "${args[@]}" \
      >"${TMPROOT}/${ship}/stdout" \
      2>"${TMPROOT}/${ship}/stderr"
    echo $? >"${TMPROOT}/${ship}/exit"
  ) &
  pids+=($!)
done

# Wait for all (don't let `set -e` kill us if a job exited non-zero;
# we record exit codes via the inner subshell's trailing echo).
for pid in "${pids[@]}"; do
  wait "$pid" || true
done

# Print blocks in declared order. Headers + .dojo.sh's status messages
# go to stderr; dojo output goes to stdout (preserves pipe-friendly
# stdout-only contract).
overall=0
for ship in "${SHIPS[@]}"; do
  echo "=== ship: ${ship} ===" >&2
  if [ -s "${TMPROOT}/${ship}/stderr" ]; then
    cat "${TMPROOT}/${ship}/stderr" >&2
  fi
  if [ -s "${TMPROOT}/${ship}/stdout" ]; then
    cat "${TMPROOT}/${ship}/stdout"
  fi
  exit_code=$(cat "${TMPROOT}/${ship}/exit" 2>/dev/null || echo 1)
  if [ "$exit_code" -ne 0 ]; then
    overall=1
  fi
done

exit $overall
