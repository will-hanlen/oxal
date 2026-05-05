#!/usr/bin/env bash
# Send a command to an Urbit dojo running in tmux and return its output.
#
# Usage: dojo.sh <session:window> <timeout_secs> <command> [--sync=<pier-location>]
#   e.g. dojo.sh oxal:master-migrev-dolseg 30 '(add 2 3)'
#        dojo.sh oxal:master-migrev-dolseg 360 '|commit %oxal' \
#                --sync=.piers/master-migrev-dolseg/oxal
#
# The first arg is passed to tmux as the exact target (the `=` prefix
# is added when this script calls tmux), so it may be any valid tmux
# session:window pair — the window name need not match the ship's @p.
#
# --sync=<desk-location> (optional): before running the command,
# rsync this repo's source tree into <desk-location> (the
# development desk). Pair with '|commit %oxal' to apply source changes.
#
# stdout:  Dojo output (between start and done sentinels)
# stderr:  OK / TIMEOUT / ABORT
# Exit 0:  Command completed. Inspect stdout for results/errors.
# Exit 1:  Timeout, couldn't get a clean prompt, start sentinel never
#          echoed (dojo not in an interactable state), or bad args.
#
# Strategy: Generate a unique ID per invocation. Send %start-<id> before
# the command and %done-<id> after. Both are valid dojo expressions that
# produce echo lines (> %start-<id>, > %done-<id>). The dojo queues typed
# input so the done sentinel waits until the real command finishes. We
# extract everything between the two sentinel echoes — no false matches.

set -euo pipefail

TARGET=""
TIMEOUT=""
COMMAND=""
PIER=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sync=*) PIER="${1#--sync=}"; shift ;;
    --sync)   PIER="${2:?--sync requires a pier location}"; shift 2 ;;
    -*)       echo "Unknown flag: $1" >&2; exit 1 ;;
    *)
      if   [ -z "$TARGET" ];  then TARGET="$1"
      elif [ -z "$TIMEOUT" ]; then TIMEOUT="$1"
      elif [ -z "$COMMAND" ]; then COMMAND="$1"
      else echo "Unexpected arg: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

if [ -z "$TARGET" ] || [ -z "$TIMEOUT" ] || [ -z "$COMMAND" ]; then
  echo "Usage: dojo.sh <session:window> <timeout_secs> <command> [--sync=<pier-location>]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERVAL=1

if [ -n "$PIER" ]; then
  if [ ! -d "$PIER" ]; then
    echo "Error: pier location not found at ${PIER}" >&2
    exit 1
  fi
  echo "Syncing source to ${PIER}..." >&2
  rsync -avL --delete --exclude='.*' "${SCRIPT_DIR}/" "${PIER}"
fi

# Unique ID prevents collisions between concurrent/sequential runs
RUN_ID=$(printf '%04x%04x' $((RANDOM)) $((RANDOM)))
START_SENT="%start-${RUN_ID}"
START_ECHO="> ${START_SENT}"
DONE_SENT="%done-${RUN_ID}"
DONE_ECHO="> ${DONE_SENT}"

# ── Helpers ───────────────────────────────────────────────────────────
capture_pane() {
  tmux capture-pane -t "=${TARGET}" -p -S -2000 -J 2>/dev/null || true
}

first_match_line() {
  local text="$1" pattern="$2"
  echo "$text" | grep -anF -- "$pattern" | head -1 | cut -d: -f1
}

last_match_line() {
  local text="$1" pattern="$2"
  echo "$text" | grep -anF -- "$pattern" | tail -1 | cut -d: -f1
}

clear_input() {
  tmux send-keys -t "=${TARGET}" C-a C-k 2>/dev/null || true
}

trim_blank() {
  awk '
    { lines[NR] = $0 }
    /[^[:space:]]/ { if (!start) start = NR; end = NR }
    END { if (start) for (i = start; i <= end; i++) print lines[i] }
  '
}

# ── Step 1: Wait for a clean prompt ──────────────────────────────────
clear_input
CLEAN_ELAPSED=0
CLEAN=false
while [ "$CLEAN_ELAPSED" -lt 10 ]; do
  sleep 1
  CLEAN_ELAPSED=$((CLEAN_ELAPSED + 1))
  LAST_LINE=$(capture_pane | grep -av '^\s*$' | tail -1)
  if echo "$LAST_LINE" | grep -aqE ':dojo[^>]*>\s*$'; then
    CLEAN=true
    break
  fi
  clear_input
done

if [ "$CLEAN" = false ]; then
  echo "TIMEOUT: could not get clean dojo prompt after 10s" >&2
  capture_pane | tail -20 >&2
  exit 1
fi

# ── Step 2: Send start sentinel and verify it lands ──────────────────
tmux send-keys -t "=${TARGET}" -- "$START_SENT" Enter
START_WAIT=0
START_OK=false
while [ "$START_WAIT" -lt 5 ]; do
  sleep 1
  START_WAIT=$((START_WAIT + 1))
  if capture_pane | grep -aqF -- "$START_ECHO"; then
    START_OK=true
    break
  fi
done

if [ "$START_OK" = false ]; then
  # The start sentinel is a bare %term typed into dojo. If the dojo
  # doesn't echo it back, possible causes include:
  #   - Leftover text in the input buffer (previous command still on
  #     the line, or a syntax error left partial input). clear_input
  #     should handle this, but tmux key delivery can race.
  #   - Ship is busy (long-running computation or OTA) and hasn't
  #     processed the input yet.
  #   - Dojo is in a multi-line entry mode (e.g. after an incomplete
  #     expression) so the sentinel is absorbed as continuation text.
  #   - The tmux target doesn't point at a dojo pane (wrong session,
  #     window, or pane index).
  #   - The ship crashed or is in a boot loop and never reaches a
  #     prompt.
  echo "ABORT: dojo is not in an interactable state (start sentinel never echoed)" >&2
  capture_pane | tail -20 >&2
  exit 1
fi

# ── Step 3: Send command, then done sentinel ─────────────────────────
clear_input
sleep 0.2
tmux send-keys -t "=${TARGET}" -- "$COMMAND" Enter
sleep 0.3
clear_input
sleep 0.2
tmux send-keys -t "=${TARGET}" -- "$DONE_SENT" Enter

# ── Step 4: Wait for done sentinel echo ──────────────────────────────
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
  OUTPUT=$(capture_pane)

  echo "$OUTPUT" | grep -aqF -- "$DONE_ECHO" || continue

  # Find both sentinel echoes (unique per invocation — no false matches)
  START_LINE=$(first_match_line "$OUTPUT" "$START_ECHO") || true
  DONE_LINE=$(last_match_line "$OUTPUT" "$DONE_ECHO") || true
  [ -z "$START_LINE" ] || [ -z "$DONE_LINE" ] && continue

  # Extract lines between start sentinel echo and done sentinel echo
  # Skip: start sentinel echo, start sentinel result, command echo line
  # The start sentinel produces two lines: "> %start-xxxx" and "%start-xxxx"
  # Then the command echo: "> command"
  # Then the command output
  # Then "> %done-xxxx"
  start=$((START_LINE + 1))
  end=$((DONE_LINE - 1))
  if [ "$start" -le "$end" ]; then
    echo "$OUTPUT" | sed -n "${start},${end}p" \
      | grep -avF -- "$START_SENT" \
      | grep -av ':dojo[^>]*>' \
      | grep -avxF -- "> ${COMMAND}" \
      | trim_blank || true
  fi

  echo "OK" >&2
  exit 0
done

echo "TIMEOUT after ${TIMEOUT}s" >&2
capture_pane | tail -30 >&2
exit 1
