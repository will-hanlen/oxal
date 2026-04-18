# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## Overview

hu is a terminal-based text editor written in Node.js with vim-style modal editing. It uses indentation as the sole structural signal for navigation, folding, and selection — making it useful for any indentation-based language (Hoon, Python, YAML, Haskell, etc.). Hoon-specific features are limited to `::` comment highlighting and auto-folding arms on `.hoon` file open.

## Running

```
node hu.js <file>
```

No dependencies, no build step, no package.json. Pure Node.js with only `fs` as an external module.

## Hot-reloading

To test changes, restart the running process in tmux session `hawk`, window `hhh`.

## Architecture

The editor follows a unidirectional flow: **input → state update → render**.

- **`hu.js`** — Entry point. Sets up raw stdin, wires the event loop: `parseKey → handleKey → render`. Handles cleanup and signals.
- **`lib/input.js`** — Parses raw stdin bytes into structured key objects `{ key, ctrl, shift }`. Handles escape sequences, CSI codes, and control characters.
- **`lib/editor.js`** — Terminal editor wrapper. `createEditor()` returns `{ state, handleKey, clampCursor }`. Thin pass-through to the shared engine.
- **`lib/buffer.js`** — File data and manipulation. `createBuffer(filename)` returns an object holding `lines[]` (raw strings), `folds` (Set of folded line numbers), and all mutation methods (insert/delete/split/join lines and chars). Also contains indentation-based structural queries: `section()`, `parentSection()`, `nextSibling()`, `prevSibling()`, `indentBlock()`, `foldAllAtIndent()`. Blank lines are terrain-transparent — they don't affect indentation calculations.
- **`lib/render.js`** — Converts state + buffer into ANSI escape sequences written to stdout. Handles the four UI sections, yank panel overlay, and cursor positioning. Reads prompt/menu data from `_modeStack` frames for status line content, cheat bar keymap/label, and cursor positioning.

## UI layout

The editor screen has four sections, top to bottom:

1. **Metadata line** (row 1) — Shows the current file's relative path and a `[+]` modified flag when dirty. Shows `[no file]` when no file is loaded.
2. **Editor** (rows 2 to rows-2) — The main content area with gutter (line numbers + fold indicators) and syntax-highlighted text.
3. **Cheat line** (row rows-1) — Full-width bar showing the current mode label and context-sensitive keybinding hints. Scrollable with left/right arrows.
4. **Status line** (row rows) — Full-width bottom line for transient information: command input (`:`), search input (`/`), register label prompts, or messages. Empty when there is nothing to display.


## Key design details

- **Visible lines vs actual lines**: The buffer maintains raw `lines[]` indexed by actual line number. Folds hide ranges, so `buffer.visibleLines()` returns `[{ lineNum, text }]`. The editor cursor operates on visible indices; `actualLineNum()` maps back to real line numbers. This distinction is critical when modifying buffer contents.
- **Fold model**: Folds are indent-based. A line is foldable if the next non-blank line has greater indent. `folds` is a Set of line numbers where folding starts. `.hoon` files auto-fold all arms (`++`/`+$` lines) on startup. `J`/`K` navigate between siblings (same-indent lines). `F` folds all foldable lines at cursor's indent level.
- **Mode stack**: `state._modeStack` is an array of `{ mode, data }` frames. The bottom frame is always `{ mode: 'normal', data: {} }`. `state.mode` is a getter/setter on the top frame, so all existing `state.mode === 'X'` and `state.mode = 'X'` code works unchanged. Mode transitions use `pushMode(mode, data)` and `popMode()` from `lib/keymap.js`. `popMode()` calls `data.onExit()` if defined (used for cleanup like clearing selection). `modeData()` returns the top frame's data object. `modeDepth()` returns the stack length.
- **Modes**: `normal`, `select`, `insert`, `prompt`, `menu`. Selection mode cycles through units: `line → section → indent → parent`.
- **Prompt mode**: Unified handler for `:` command and `/` search. Frame data carries `{ prefix, buf, col, label, onDone(val, buffer) }`. The `onDone` callback runs after the user presses Enter. `state.commandBuf`, `state.searchBuf`, and `state.promptCol` are backward-compat getter/setters that delegate to the prompt frame's data when in prompt mode. Old `command`/`search` mode names no longer exist — tests assert `"mode": "prompt"`.
- **Menu mode**: For tree-shaped keybindings. A keymap entry can have a `menu` array (a sub-keymap) instead of just `fn`. Pressing that key pushes a menu frame whose data carries `{ keymap, label, panel }`. The cheat bar reads from `modeData().keymap` and the mode label from `modeData().label`. Escape pops the menu. Menus can push further modes (e.g. yank menu's `s` key pushes a prompt for the register label).
- **Undo**: Snapshot-based (copies entire `lines[]` array + cursor + folds). Capped at 100 entries. Each mutation should call `pushUndo()` before modifying the buffer.
- **Yank registers**: Default yank buffer (`yankBuf`) plus named registers in `yankMap` (Map of `key → { label, lines }`). The `"` key pushes a menu mode with `panel: 'yank'`; the renderer checks `_modeStack` for a frame with `data.panel === 'yank'` to show the overlay panel.

## Key binding constraints

No ctrl-modifier keybindings. All inputs must be single keypress sequences (no chording). Ctrl+C is the sole exception (emergency terminal exit). This ensures compatibility with tmux (which intercepts ctrl combos) and browsers (which reserve ctrl shortcuts).

## Terminal + Web parity

The web UI (`web/`) is a subset of the terminal UI — it renders only the metadata line and the editor area, wrapped in its own cheat line. It has no status line or yank panel. Any behavioral or visual change to the metadata line, editor, or cheat bar in the terminal (`lib/render.js`) should be mirrored in the web UI, and vice versa.

## Web server

The tmux session called hu:web runs a simple web server in python that serves the correct files to localhost:9999 and opensit up
