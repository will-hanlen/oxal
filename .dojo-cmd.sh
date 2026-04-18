#!/usr/bin/env bash
# Send a command to an Urbit dojo running in tmux and return its output.
#
# Usage: dojo-cmd.sh <tmux-target> <timeout_secs> <command>
#
# stdout:  Dojo output (between start and done sentinels)
# stderr:  OK / TIMEOUT
# Exit 0:  Command completed. Inspect stdout for results/errors.
# Exit 1:  Timeout or couldn't get a clean prompt.
#
# Strategy: Generate a unique ID per invocation. Send %start-<id> before
# the command and %done-<id> after. Both are valid dojo expressions that
# produce echo lines (> %start-<id>, > %done-<id>). The dojo queues typed
# input so the done sentinel waits until the real command finishes. We
# extract everything between the two sentinel echoes — no false matches.

set -euo pipefail

TARGET="${1:?tmux target required}"
TIMEOUT="${2:?timeout required}"
COMMAND="${3:?command required}"
INTERVAL=1

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
  echo "$text" | grep -nF -- "$pattern" | head -1 | cut -d: -f1
}

last_match_line() {
  local text="$1" pattern="$2"
  echo "$text" | grep -nF -- "$pattern" | tail -1 | cut -d: -f1
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
  LAST_LINE=$(capture_pane | grep -v '^\s*$' | tail -1)
  if echo "$LAST_LINE" | grep -qE ':dojo[^>]*>\s*$'; then
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
  if capture_pane | grep -qF -- "$START_ECHO"; then
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

  echo "$OUTPUT" | grep -qF -- "$DONE_ECHO" || continue

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
      | grep -vF -- "$START_SENT" \
      | grep -v ':dojo[^>]*>' \
      | grep -vxF -- "> ${COMMAND}" \
      | trim_blank || true
  fi

  echo "OK" >&2
  exit 0
done

echo "TIMEOUT after ${TIMEOUT}s" >&2
capture_pane | tail -30 >&2
exit 1
