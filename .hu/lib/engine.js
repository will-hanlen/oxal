'use strict';

const { createKeymap } = require('./keymap');
const { H_SCROLL_PAD } = require('./constants');

// --- createState: shared editor state ---

function createState(extraFields) {
  const state = {
    _modeStack: [{ mode: 'normal', data: {} }],
    cursor: { line: 0, col: 0 },
    selection: null,
    selectionUnit: 'line',
    scroll: 0,
    scrollX: 0,
    _commandBuf: '',
    _searchBuf: '',
    searchQuery: '',
    _promptCol: 0,
    message: '',
    yankBuf: [],
    yankType: 'line',
    yankMap: new Map(),
    yankPanelIdx: 0,
    undoStack: [],
    redoStack: [],
    quit: false,
    forceQuit: false,
    cheatScrollPx: 0,
    keymap: null,
  };

  if (extraFields) Object.assign(state, extraFields);

  Object.defineProperty(state, 'mode', {
    get() { return this._modeStack[this._modeStack.length - 1].mode; },
    set(val) { this._modeStack[this._modeStack.length - 1].mode = val; },
    enumerable: true,
  });
  Object.defineProperty(state, 'commandBuf', {
    get() {
      const d = this._modeStack[this._modeStack.length - 1].data;
      if (this.mode === 'prompt' && d && d.prefix === ':') return d.buf;
      return this._commandBuf;
    },
    set(val) {
      const d = this._modeStack[this._modeStack.length - 1].data;
      if (this.mode === 'prompt' && d && d.prefix === ':') { d.buf = val; return; }
      this._commandBuf = val;
    },
    enumerable: true,
  });
  Object.defineProperty(state, 'searchBuf', {
    get() {
      const d = this._modeStack[this._modeStack.length - 1].data;
      if (this.mode === 'prompt' && d && d.prefix === '/') return d.buf;
      return this._searchBuf;
    },
    set(val) {
      const d = this._modeStack[this._modeStack.length - 1].data;
      if (this.mode === 'prompt' && d && d.prefix === '/') { d.buf = val; return; }
      this._searchBuf = val;
    },
    enumerable: true,
  });
  Object.defineProperty(state, 'promptCol', {
    get() {
      const d = this._modeStack[this._modeStack.length - 1].data;
      return d && d.col !== undefined ? d.col : this._promptCol;
    },
    set(val) {
      const d = this._modeStack[this._modeStack.length - 1].data;
      if (d && d.col !== undefined) { d.col = val; }
      else { this._promptCol = val; }
    },
    enumerable: true,
  });

  return state;
}

// --- createEditor: shared editor setup ---

function createEditor(opts) {
  const getLang = opts.getLang;
  const state = createState(opts.extraState);

  const km = createKeymap(state, {
    execCommand(cmd, buffer) {
      cmd = cmd.trim();
      if (cmd === 'w') {
        if (buffer.save()) {
          state.message = `Saved ${buffer.filename}`;
        } else {
          state.message = 'No filename';
        }
      } else if (cmd === 'q') {
        if (buffer.dirty) {
          state.message = 'Unsaved changes (use :q! to force)';
        } else {
          state.quit = true;
        }
      } else if (cmd === 'wq') {
        if (buffer.save()) {
          state.quit = true;
        } else {
          state.message = 'No filename';
        }
      } else if (cmd === 'q!') {
        state.quit = true;
        state.forceQuit = true;
      } else if (cmd === 'help') {
        if (buffer.dirty) {
          state.message = 'Unsaved changes (use :w first)';
        } else {
          state.loadFile = require('path').join(__dirname, '..', 'help', 'README');
        }
      } else if (/^\d+$/.test(cmd)) {
        const targetLine = parseInt(cmd, 10) - 1;
        const vi = km.findVisibleIndex(buffer, targetLine);
        state.cursor.line = vi;
        state.cursor.col = 0;
      } else {
        state.message = `Unknown command: ${cmd}`;
      }
    },
    getLang,
  });

  state.keymap = {
    normal: km.normalKeymap,
    select: km.selectKeymap,
    insert: km.insertKeymap,
    prompt: km.promptKeymap,
  };

  return { state, handleKey: km.handleKey, clampCursor: km.clampCursor, km };
}

// --- computeViewport: vertical + horizontal scroll ---

function computeViewport(state, editorRows, displayCols) {
  const half = Math.floor(editorRows / 2);
  if (state.selection) {
    const rStart = Math.min(state.selection.anchor, state.selection.head);
    const rEnd = Math.max(state.selection.anchor, state.selection.head);
    const regionHeight = rEnd - rStart + 1;
    if (regionHeight <= editorRows) {
      const regionMid = (rStart + rEnd) / 2;
      state.scroll = Math.round(regionMid) - half;
    } else {
      state.scroll = state.cursor.line - half;
    }
  } else {
    state.scroll = state.cursor.line - half;
  }

  const hPad = Math.min(H_SCROLL_PAD, Math.floor(displayCols / 2) - 1);
  if (state.cursor.col >= state.scrollX + displayCols - hPad)
    state.scrollX = state.cursor.col - displayCols + hPad + 1;
  if (state.cursor.col < state.scrollX + hPad)
    state.scrollX = Math.max(0, state.cursor.col - hPad);
  if (state.scrollX < 0) state.scrollX = 0;
}

// --- deriveCharRange: char-selection geometry ---

function deriveCharRange(state, visible) {
  if (state.selectionUnit !== 'char' || !state.selection) return null;
  const clampedAnchor = Math.max(0, Math.min(state.selection.anchor, visible.length - 1));
  const clampedHead = Math.max(0, Math.min(state.selection.head, visible.length - 1));
  const anchorLn = visible[clampedAnchor] ? visible[clampedAnchor].lineNum : 0;
  const headLn = visible[clampedHead] ? visible[clampedHead].lineNum : 0;
  const anchorCol = state.selection.anchorCol;
  const headCol = state.cursor.col;
  if (anchorLn < headLn || (anchorLn === headLn && anchorCol <= headCol)) {
    return { startLn: anchorLn, startCol: anchorCol, endLn: headLn, endCol: headCol };
  }
  return { startLn: headLn, startCol: headCol, endLn: anchorLn, endCol: anchorCol };
}

// --- deriveModeInfo: mode label + effective mode + cheat keymap ---

function deriveModeInfo(state) {
  let effectiveMode = state.mode === 'command' || state.mode === 'search' || state.mode === 'prompt' ? 'prompt' : state.mode;

  let keymap;
  if (effectiveMode === 'menu') {
    const d = state._modeStack[state._modeStack.length - 1].data;
    keymap = d.keymap || [];
  } else {
    keymap = (state.keymap && state.keymap[effectiveMode]) || [];
  }

  let label = ` ${effectiveMode.toUpperCase()} `;
  if (effectiveMode === 'prompt') {
    if (state.mode === 'prompt') {
      const d = state._modeStack[state._modeStack.length - 1].data;
      label = d && d.label ? ` ${d.label} ` : ' PROMPT ';
    } else {
      label = state.mode === 'command' ? ' COMMAND ' : ' SEARCH ';
    }
  } else if (effectiveMode === 'menu') {
    const d = state._modeStack[state._modeStack.length - 1].data;
    label = d && d.label ? ` ${d.label.toUpperCase()} ` : ' MENU ';
  } else if (effectiveMode === 'select' && state.selectionUnit) {
    label = ` SELECT:${state.selectionUnit.toUpperCase()} `;
  }

  return { effectiveMode, label, keymap };
}

module.exports = { createState, createEditor, computeViewport, deriveCharRange, deriveModeInfo };
