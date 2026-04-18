#!/usr/bin/env node
'use strict';

const fs = require('fs');
const { createBuffer, parseFileContent } = require('./lib/buffer');
const { createEditor } = require('./lib/editor');
const { parseKey } = require('./lib/input');
const { render } = require('./lib/render');
const { CURSOR_COL_OFFSET } = require('./lib/constants');
const { getLang } = require('./lang');

const path = require('path');

const arg = process.argv[2];

if (!arg) {
  console.error('Usage: hu <file>');
  process.exit(1);
}

try {
  const stat = fs.statSync(arg);
  if (stat.isDirectory()) {
    console.error('Usage: hu <file>');
    process.exit(1);
  }
} catch (e) {
  // Non-existent path: treat as new file (createBuffer handles ENOENT)
}

// Set tmux window name (disable automatic-rename so tmux doesn't override with "node")
function setTmuxName(file) {
  if (!process.env.TMUX) return;
  const { execSync } = require('child_process');
  const slug = path.basename(file);
  try {
    execSync('tmux set-option -w automatic-rename off', { stdio: 'ignore' });
    execSync(`tmux rename-window "hu:${slug}"`, { stdio: 'ignore' });
  } catch (e) {}
}
setTmuxName(arg);

const buffer = createBuffer(arg, { fs });
const { state, handleKey, clampCursor } = createEditor();

// Run language-specific onOpen hook
const lang = getLang(arg);
if (lang.lineComment) buffer.lineComment = lang.lineComment;
if (lang.onOpen) {
  lang.onOpen(buffer);
  clampCursor(buffer);
}

function loadFileIntoBuffer(file) {
  const content = fs.readFileSync(file, 'utf8');
  buffer.lines = parseFileContent(content);
  buffer.filename = file;
  buffer.dirty = false;
  buffer.stale = false;
  try { buffer.lastMtime = fs.statSync(file).mtimeMs; } catch (e) {}
  buffer.folds.clear();
  buffer.invalidateCache();
  state.cursor = { line: 0, col: 0 };
  state.scroll = 0;
  state.undoStack = [];
  state.redoStack = [];
  const fileLang = getLang(file);
  buffer.lineComment = fileLang.lineComment || null;
  if (fileLang.onOpen) {
    fileLang.onOpen(buffer);
    clampCursor(buffer);
  }
  startWatcher(file);
  setTmuxName(file);
}

// File watcher for stale detection
let watcher = null;
let watchDebounce = null;

function startWatcher(file) {
  if (watcher) { watcher.close(); watcher = null; }
  try {
    watcher = fs.watch(file, () => {
      if (watchDebounce) return;
      watchDebounce = setTimeout(() => {
        watchDebounce = null;
        if (!buffer.checkStale()) return;
        if (!buffer.dirty) {
          buffer.reload();
          buffer.folds.clear();
          const reloadLang = getLang(buffer.filename);
          buffer.lineComment = reloadLang.lineComment || null;
          if (reloadLang.onOpen) reloadLang.onOpen(buffer);
          clampCursor(buffer);
          state.message = 'File reloaded (changed on disk)';
        } else {
          state.message = 'Warning: file changed on disk';
        }
        render(state, buffer, stdout);
      }, 100);
    });
  } catch (e) { /* watch not supported on all platforms/paths; degrade gracefully */ }
}

// Enter raw mode
const stdin = process.stdin;
const stdout = process.stdout;
stdin.setRawMode(true);
stdin.resume();
stdin.setEncoding(null);

if (buffer.filename) startWatcher(buffer.filename);

// Enable SGR mouse tracking
stdout.write('\x1b[?1000h\x1b[?1006h');

// Clear screen and render
stdout.write('\x1b[2J\x1b[H');
render(state, buffer, stdout);

stdin.on('data', (data) => {
  const keys = parseKey(Buffer.from(data));
  for (const key of keys) {
    // Ctrl+C — emergency exit
    if (key.ctrl && key.key === 'c') {
      cleanup();
      process.exit(0);
    }
    // Mouse click — position cursor
    if (key.key === 'mouse') {
      const rows = stdout.rows || 24;
      const editorTop = 2;  // row 1 is metadata, editor starts at row 2
      const editorBot = rows - 2;  // rows-1 is cheat, rows is status
      if (key.row >= editorTop && key.row <= editorBot) {
        const visibleRow = (key.row - editorTop) + state.scroll;
        const visible = buffer.visibleLines();
        if (visibleRow >= 0 && visibleRow < visible.length) {
          state.cursor.line = visibleRow;
          const lineText = visible[visibleRow].text;
          state.cursor.col = Math.min(
            Math.max(0, key.col - CURSOR_COL_OFFSET + state.scrollX),
            lineText.length
          );
        }
      }
      continue;
    }
    handleKey(key, buffer);
    if (state.quit) {
      cleanup();
      process.exit(0);
    }
    if (state.loadFile) {
      const file = state.loadFile;
      state.loadFile = null;
      try {
        loadFileIntoBuffer(file);
        state.message = `Opened ${file}`;
      } catch (e) {
        state.message = `Error: ${e.message}`;
      }
    }
  }
  render(state, buffer, stdout);
});

// Handle resize
stdout.on('resize', () => {
  render(state, buffer, stdout);
});

function cleanup() {
  if (watcher) { watcher.close(); watcher = null; }
  if (watchDebounce) { clearTimeout(watchDebounce); watchDebounce = null; }
  // Restore tmux automatic-rename
  if (process.env.TMUX) {
    const { execSync } = require('child_process');
    try {
      execSync('tmux set-option -w -u automatic-rename', { stdio: 'ignore' });
    } catch (e) {}
  }
  stdout.write('\x1b[?1000l\x1b[?1006l'); // disable mouse tracking
  stdout.write('\x1b]112\x07'); // reset cursor color
  stdout.write('\x1b[?25h'); // show cursor
  stdout.write('\x1b[2J\x1b[H'); // clear screen
  stdin.setRawMode(false);
  stdin.pause();
}

// Handle unexpected exits
process.on('SIGINT', () => { cleanup(); process.exit(0); });
process.on('SIGTERM', () => { cleanup(); process.exit(0); });
process.on('exit', () => {
  stdout.write('\x1b[?25h');
});
