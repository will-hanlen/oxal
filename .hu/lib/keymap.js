'use strict';
const { INDENT, INDENT_SIZE, MAX_UNDO, CHEAT_SCROLL_STEP } = require('./constants');

// Visible index vs actual line number:
// The cursor (state.cursor.line) is a visible index — an offset into the
// array returned by buffer.visibleLines(). This array excludes folded lines.
// To get the actual line number in buffer.lines[], call actualLineNum(buffer).
// To go the other way, call findVisibleIndex(buffer, lineNum).
// All buffer mutations (insert, delete, etc.) use actual line numbers.
// All cursor/selection operations use visible indices.

function createKeymap(state, opts) {
  const execCommand = opts.execCommand;
  const getLang = opts.getLang;

  // --- Mode stack helpers ---

  function pushMode(mode, data = {}) {
    state._modeStack.push({ mode, data });
  }

  function popMode() {
    if (state._modeStack.length <= 1) return null;
    const frame = state._modeStack.pop();
    if (frame.data.onExit) frame.data.onExit();
    return frame;
  }

  function modeData() {
    return state._modeStack[state._modeStack.length - 1].data;
  }

  function modeDepth() {
    return state._modeStack.length;
  }

  // --- Shared helpers ---

  function visibleLineCount(buffer) {
    return buffer.visibleLines().length;
  }

  function clampCursor(buffer) {
    const count = visibleLineCount(buffer);
    if (state.cursor.line >= count) state.cursor.line = Math.max(0, count - 1);
    if (state.cursor.line < 0) state.cursor.line = 0;
    const visible = buffer.visibleLines();
    if (visible[state.cursor.line]) {
      const lineLen = visible[state.cursor.line].text.length;
      if (state.cursor.col > lineLen) state.cursor.col = lineLen;
    }
    if (state.cursor.col < 0) state.cursor.col = 0;
  }

  function createSnapshot(buffer) {
    return { lines: [...buffer.lines], cursor: { ...state.cursor }, folds: new Set(buffer.folds) };
  }

  function restoreSnapshot(buffer, snap) {
    buffer.lines = snap.lines;
    state.cursor = snap.cursor;
    buffer.folds = snap.folds;
    buffer.dirty = true;
    buffer.invalidateCache();
  }

  function pushUndo(buffer) {
    state.undoStack.push(createSnapshot(buffer));
    if (state.undoStack.length > MAX_UNDO) state.undoStack.shift();
    state.redoStack = [];
  }

  function undo(buffer) {
    if (state.undoStack.length === 0) {
      state.message = 'Nothing to undo';
      return;
    }
    state.redoStack.push(createSnapshot(buffer));
    restoreSnapshot(buffer, state.undoStack.pop());
  }

  function redo(buffer) {
    if (state.redoStack.length === 0) {
      state.message = 'Nothing to redo';
      return;
    }
    state.undoStack.push(createSnapshot(buffer));
    restoreSnapshot(buffer, state.redoStack.pop());
  }

  function actualLineNum(buffer) {
    const visible = buffer.visibleLines();
    if (state.cursor.line >= 0 && state.cursor.line < visible.length) {
      return visible[state.cursor.line].lineNum;
    }
    return 0;
  }

  function findVisibleIndex(buffer, lineNum) {
    const visible = buffer.visibleLines();
    for (let i = 0; i < visible.length; i++) {
      if (visible[i].lineNum === lineNum) return i;
      if (visible[i].lineNum > lineNum) return Math.max(0, i - 1);
    }
    return visible.length - 1;
  }

  // Remove a fold on lineNum if it exists
  function unfoldLine(buffer, lineNum) {
    if (buffer.folds.has(lineNum)) {
      buffer.folds.delete(lineNum);
      buffer.invalidateCache();
    }
  }

  // If lineNum is hidden inside a fold, unfold that fold
  function ensureVisible(buffer, lineNum) {
    buffer.invalidateCache();
    for (const foldLn of buffer.folds) {
      const range = buffer.foldRange(foldLn);
      if (range && lineNum >= range[0] && lineNum <= range[1]) {
        buffer.folds.delete(foldLn);
        buffer.invalidateCache();
        return;
      }
    }
  }

  // Smart case: case-insensitive unless query contains uppercase
  function searchIndexOf(text, q, from) {
    if (q !== q.toLowerCase()) return text.indexOf(q, from);
    return text.toLowerCase().indexOf(q, from);
  }

  function searchNext(buffer, dir, inclusive) {
    if (!state.searchQuery) return;
    const visible = buffer.visibleLines();
    const q = state.searchQuery;
    const offset = inclusive ? 0 : 1;

    // Current actual line number
    const curActual = visible[state.cursor.line].lineNum;

    // Check current line for another match beyond (or before) the cursor
    const curText = buffer.lines[curActual];
    if (dir > 0) {
      const next = searchIndexOf(curText, q, state.cursor.col + offset);
      if (next >= 0) {
        state.cursor.col = next;
        state.message = '';
        return;
      }
    } else {
      const limit = inclusive ? state.cursor.col + 1 : state.cursor.col;
      let prev = -1;
      let idx = 0;
      while (idx < limit) {
        const pos = searchIndexOf(curText, q, idx);
        if (pos < 0 || pos >= limit) break;
        prev = pos;
        idx = pos + 1;
      }
      if (prev >= 0 && prev !== state.cursor.col) {
        state.cursor.col = prev;
        state.message = '';
        return;
      }
    }

    // Search all lines (including folded), wrapping around
    const totalLines = buffer.lines.length;
    const start = curActual + dir;
    for (let i = 0; i < totalLines; i++) {
      const lineNum = ((start + i * dir) % totalLines + totalLines) % totalLines;
      const text = buffer.lines[lineNum];
      if (searchIndexOf(text, q, 0) >= 0) {
        // Unfold if this line is hidden
        ensureVisible(buffer, lineNum);
        // Recompute visible lines after potential unfold
        const newVisible = buffer.visibleLines();
        state.cursor.line = findVisibleIndex(buffer, lineNum);
        if (dir > 0) {
          state.cursor.col = searchIndexOf(text, q, 0);
        } else {
          let last = -1;
          let si = 0;
          while (si < text.length) {
            const pos = searchIndexOf(text, q, si);
            if (pos < 0) break;
            last = pos;
            si = pos + 1;
          }
          state.cursor.col = last;
        }
        state.message = '';
        return;
      }
    }
    state.message = 'Pattern not found';
  }

  function getCharRange(visible) {
    if (!state.selection) return null;
    const anchorLn = visible[state.selection.anchor].lineNum;
    const headLn = visible[state.selection.head].lineNum;
    const anchorCol = state.selection.anchorCol;
    const headCol = state.cursor.col;
    if (anchorLn < headLn || (anchorLn === headLn && anchorCol <= headCol)) {
      return { startLine: anchorLn, startCol: anchorCol, endLine: headLn, endCol: headCol };
    }
    return { startLine: headLn, startCol: headCol, endLine: anchorLn, endCol: anchorCol };
  }

  // direction: 'after' (p) or 'before' (P)
  function pasteContent(buffer, ctx, direction) {
    if (state.yankBuf.length === 0) {
      state.message = 'Nothing to paste';
      return;
    }
    pushUndo(buffer);
    if (direction === 'after') unfoldLine(buffer, ctx.ln);
    if (state.yankType === 'char') {
      const text = state.yankBuf[0];
      const parts = text.split('\n');
      const col = direction === 'after' ? state.cursor.col + 1 : state.cursor.col;
      if (parts.length === 1) {
        buffer.insertChar(ctx.ln, col, text);
        state.cursor.col = col + text.length - 1;
      } else {
        const line = buffer.lines[ctx.ln];
        const before = line.slice(0, col);
        const after = line.slice(col);
        buffer.lines[ctx.ln] = before + parts[0];
        for (let i = 1; i < parts.length - 1; i++) {
          buffer.insertLine(ctx.ln + i, parts[i]);
        }
        buffer.insertLine(ctx.ln + parts.length - 1, parts[parts.length - 1] + after);
        state.cursor.line += parts.length - 1;
        state.cursor.col = parts[parts.length - 1].length;
        buffer.dirty = true;
        buffer.invalidateCache();
      }
      state.message = 'Pasted inline';
    } else {
      const offset = direction === 'after' ? 1 : 0;
      for (let i = 0; i < state.yankBuf.length; i++) {
        buffer.insertLine(ctx.ln + offset + i, state.yankBuf[i]);
      }
      if (direction === 'after') state.cursor.line++;
      state.message = `${state.yankBuf.length} line(s) pasted`;
    }
  }

  // --- Keymaps ---

  const normalKeymap = [
    {
      cheat: ['j/k', 'move'], desc: 'Move cursor up/down',
      keys: ['j', 'down', 'k', 'up'],
      fn(key, buffer, ctx) {
        if (key.key === 'j' || key.key === 'down') {
          state.cursor.line = Math.min(state.cursor.line + 1, ctx.visible.length - 1);
        } else {
          state.cursor.line = Math.max(state.cursor.line - 1, 0);
        }
      }
    },
    {
      cheat: ['h/l', 'col'], desc: 'Move cursor left/right',
      keys: ['h', 'l'],
      fn(key, buffer, ctx) {
        if (key.key === 'h') {
          state.cursor.col = Math.max(state.cursor.col - 1, 0);
        } else if (ctx.visible[state.cursor.line]) {
          state.cursor.col = Math.min(state.cursor.col + 1, ctx.visible[state.cursor.line].text.length);
        }
      }
    },
    {
      cheat: ['w/b', 'word'], desc: 'Next/prev non-whitespace group',
      keys: ['w', 'b'],
      fn(key, buffer, ctx) {
        const line = ctx.visible[state.cursor.line] ? ctx.visible[state.cursor.line].text : '';
        let pos = state.cursor.col;
        if (key.key === 'w') {
          while (pos < line.length && line[pos] !== ' ') pos++;
          while (pos < line.length && line[pos] === ' ') pos++;
        } else {
          if (pos > 0) pos--;
          while (pos > 0 && line[pos] === ' ') pos--;
          while (pos > 0 && line[pos - 1] !== ' ') pos--;
        }
        state.cursor.col = pos;
      }
    },
    {
      cheat: null, desc: null,
      keys: ['left', 'right'],
      fn(key) {
        if (key.key === 'left') {
          state.cheatScrollPx = Math.max(0, (state.cheatScrollPx || 0) - CHEAT_SCROLL_STEP);
        } else {
          state.cheatScrollPx = (state.cheatScrollPx || 0) + CHEAT_SCROLL_STEP;
        }
      }
    },
    {
      cheat: ['J/K', 'barrier'], desc: 'Barrier jump up/down',
      keys: ['J', 'K'],
      fn(key, buffer, ctx) {
        const col = state.cursor.col;
        const dir = key.key === 'J' ? 1 : -1;
        let row = state.cursor.line;
        function isWsAtRow(r) {
          const text = ctx.visible[r]?.text || '';
          if (text.trim().length === 0) return 'blank';
          if (col >= text.length) return 'short';
          return text[col] === ' ' || text[col] === '\t';
        }
        const startStatus = isWsAtRow(row);
        let skippedShort = false;
        let next = row + dir;
        while (next >= 0 && next < ctx.visible.length) {
          const nextStatus = isWsAtRow(next);
          if (nextStatus === 'short') { skippedShort = true; next += dir; continue; }
          if (startStatus === 'blank') {
            if (nextStatus !== 'blank') { row = next; break; }
          } else {
            if (nextStatus === 'blank' || nextStatus !== startStatus) { row = next; break; }
          }
          next += dir;
        }
        if (skippedShort && next >= 0 && next < ctx.visible.length) {
          next = row + dir;
          while (next >= 0 && next < ctx.visible.length) {
            if (isWsAtRow(next) !== 'short') { row = next; break; }
            next += dir;
          }
        }
        if (next >= 0 && next < ctx.visible.length) {
          state.cursor.line = row;
        }
      }
    },
    {
      cheat: ['q/z', 'outdent'], desc: 'Nearest less-indented line above/below',
      keys: ['q', 'z'],
      fn(key, buffer, ctx) {
        const indent = buffer.indentLevel(ctx.ln);
        if (key.key === 'q') {
          for (let i = ctx.ln - 1; i >= 0; i--) {
            if (buffer.isBlank(i)) continue;
            if (buffer.indentLevel(i) < indent) {
              state.cursor.line = findVisibleIndex(buffer, i);
              state.cursor.col = buffer.indentLevel(i);
              break;
            }
          }
        } else {
          for (let i = ctx.ln + 1; i < buffer.lines.length; i++) {
            if (buffer.isBlank(i)) continue;
            if (buffer.indentLevel(i) < indent) {
              state.cursor.line = findVisibleIndex(buffer, i);
              state.cursor.col = buffer.indentLevel(i);
              break;
            }
          }
        }
      }
    },
    {
      cheat: ['g/G', 'top/bot'], desc: 'Top / bottom of file',
      keys: ['g', 'G'],
      fn(key, buffer, ctx) {
        if (key.key === 'g') {
          state.cursor.line = 0;
          state.cursor.col = 0;
        } else {
          state.cursor.line = ctx.visible.length - 1;
          state.cursor.col = 0;
        }
      }
    },
    {
      cheat: ['H/L', 'barrier'], desc: 'Barrier jump left/right',
      keys: ['H', 'L'],
      fn(key, buffer, ctx) {
        const line = ctx.visible[state.cursor.line]?.text || '';
        const col = state.cursor.col;
        const curIsWs = col >= line.length || line[col] === ' ' || line[col] === '\t';
        if (key.key === 'H') {
          for (let c = col - 1; c >= 0; c--) {
            const charIsWs = line[c] === ' ' || line[c] === '\t';
            if (charIsWs !== curIsWs) { state.cursor.col = c; return; }
          }
        } else {
          for (let c = col + 1; c <= line.length; c++) {
            const charIsWs = c >= line.length || line[c] === ' ' || line[c] === '\t';
            if (charIsWs !== curIsWs) { state.cursor.col = c; return; }
          }
        }
      }
    },
    {
      cheat: ['</>',  'indent'], desc: 'Outdent / indent line',
      keys: ['<', '>'],
      fn(key, buffer, ctx) {
        pushUndo(buffer);
        if (key.key === '<') {
          if (buffer.lines[ctx.ln].startsWith(INDENT)) {
            buffer.lines[ctx.ln] = buffer.lines[ctx.ln].slice(INDENT_SIZE);
            state.cursor.col = Math.max(0, state.cursor.col - INDENT_SIZE);
          } else if (buffer.lines[ctx.ln].startsWith(' ')) {
            buffer.lines[ctx.ln] = buffer.lines[ctx.ln].slice(1);
            state.cursor.col = Math.max(0, state.cursor.col - 1);
          }
        } else {
          buffer.lines[ctx.ln] = INDENT + buffer.lines[ctx.ln];
          state.cursor.col += INDENT_SIZE;
        }
        buffer.dirty = true;
        buffer.invalidateCache();
        ensureVisible(buffer, ctx.ln);
        state.cursor.line = findVisibleIndex(buffer, ctx.ln);
      }
    },
    {
      cheat: ['Tab', 'fold'], desc: 'Toggle fold',
      keys: ['tab'],
      fn(key, buffer, ctx) {
        if (ctx.visible[state.cursor.line]) {
          const tabLn = ctx.visible[state.cursor.line].lineNum;
          if (buffer.foldable(tabLn)) {
            buffer.toggleFold(tabLn);
          } else {
            const sec = buffer.section(tabLn);
            if (sec) {
              buffer.toggleFold(sec[0]);
              state.cursor.line = findVisibleIndex(buffer, sec[0]);
            }
          }
          clampCursor(buffer);
        }
      }
    },
    {
      cheat: ['F', 'fold all'], desc: 'Fold all at cursor indent',
      keys: ['F'],
      fn(key, buffer, ctx) {
        const indent = buffer.indentLevel(ctx.ln);
        const count = buffer.foldAllAtIndent(indent);
        clampCursor(buffer);
        state.message = `Folded ${count} blocks at indent ${indent}`;
      }
    },
    {
      cheat: ['E', 'expand'], desc: 'Expand all',
      keys: ['E'],
      fn(key, buffer) {
        buffer.unfoldAll();
        state.message = 'Expanded all';
      }
    },
    {
      cheat: ['Space', 'select'], desc: 'Start line selection',
      keys: [' '],
      fn() {
        pushMode('select', { onExit() { state.selection = null; } });
        state.selectionUnit = 'line';
        state.selection = { anchor: state.cursor.line, head: state.cursor.line };
      }
    },
    {
      cheat: ['v', 'v-sel'], desc: 'Start char selection',
      keys: ['v'],
      fn() {
        pushMode('select', { onExit() { state.selection = null; } });
        state.selectionUnit = 'char';
        state.selection = { anchor: state.cursor.line, head: state.cursor.line, anchorCol: state.cursor.col };
      }
    },
    {
      cheat: ['i/a/I/A', 'insert'], desc: 'Insert before/after/start/end',
      keys: ['i', 'a', 'I', 'A'],
      fn(key, buffer, ctx) {
        pushUndo(buffer);
        pushMode('insert');
        if (key.key === 'a' && ctx.visible[state.cursor.line]) {
          state.cursor.col = Math.min(state.cursor.col + 1, ctx.visible[state.cursor.line].text.length);
        } else if (key.key === 'I') {
          const text = ctx.visible[state.cursor.line] ? ctx.visible[state.cursor.line].text : '';
          const m = text.match(/\S/);
          state.cursor.col = m ? m.index : 0;
        } else if (key.key === 'A' && ctx.visible[state.cursor.line]) {
          state.cursor.col = ctx.visible[state.cursor.line].text.length;
        }
      }
    },
    {
      cheat: ['o/O', 'open line'], desc: 'New line below/above',
      keys: ['o', 'O'],
      fn(key, buffer, ctx) {
        pushUndo(buffer);
        unfoldLine(buffer, ctx.ln);
        const indent = buffer.indentLevel(ctx.ln);
        if (key.key === 'o') {
          buffer.insertLine(ctx.ln + 1, ' '.repeat(indent));
          state.cursor.line++;
          state.cursor.col = indent;
        } else {
          buffer.insertLine(ctx.ln, ' '.repeat(indent));
          state.cursor.col = indent;
        }
        pushMode('insert');
      }
    },
    {
      cheat: ['c', 'clear eol'], desc: 'Clear to end of line, insert',
      keys: ['c'],
      fn(key, buffer, ctx) {
        if (ctx.ln < 0 || ctx.ln >= buffer.lines.length) return;
        pushUndo(buffer);
        const line = buffer.lines[ctx.ln];
        const killed = line.slice(state.cursor.col);
        buffer.lines[ctx.ln] = line.slice(0, state.cursor.col);
        buffer.dirty = true;
        buffer.invalidateCache();
        if (killed.length > 0) state.yankBuf = [killed];
        state.yankType = 'char';
        pushMode('insert');
      }
    },
    {
      cheat: ['d', 'del'], desc: 'Delete line',
      keys: ['d'],
      fn(key, buffer, ctx) {
        if (ctx.ln < 0 || ctx.ln >= buffer.lines.length) return;
        pushUndo(buffer);
        unfoldLine(buffer, ctx.ln);
        const removed = buffer.deleteLine(ctx.ln);
        state.yankBuf = [removed];
        state.yankType = 'line';
        state.message = '1 line deleted';
        clampCursor(buffer);
      }
    },
    {
      cheat: ['y', 'yank'], desc: 'Yank line',
      keys: ['y'],
      fn(key, buffer, ctx) {
        state.yankBuf = [buffer.lines[ctx.ln]];
        state.yankType = 'line';
        state.message = '1 line yanked';
      }
    },
    {
      cheat: ['p', 'paste'], desc: 'Paste below',
      keys: ['p'],
      fn(key, buffer, ctx) {
        pasteContent(buffer, ctx, 'after');
      }
    },
    {
      cheat: ['P', 'paste above'], desc: 'Paste above',
      keys: ['P'],
      fn(key, buffer, ctx) {
        pasteContent(buffer, ctx, 'before');
      }
    },
    {
      cheat: ['m', 'merge'], desc: 'Merge line with previous',
      keys: ['m'],
      fn(key, buffer, ctx) {
        if (ctx.ln <= 0) return;
        pushUndo(buffer);
        unfoldLine(buffer, ctx.ln - 1);
        const prevTrimmed = buffer.lines[ctx.ln - 1].trimEnd();
        const curTrimmed = buffer.lines[ctx.ln].trimStart();
        buffer.lines[ctx.ln - 1] = prevTrimmed + ' ' + curTrimmed;
        buffer.lines.splice(ctx.ln, 1);
        buffer._shiftFolds(ctx.ln + 1, -1, ctx.ln + 1, ctx.ln + 1);
        buffer.dirty = true;
        buffer.invalidateCache();
        state.cursor.line = Math.max(state.cursor.line - 1, 0);
        state.cursor.col = prevTrimmed.length;
      }
    },
    {
      cheat: ['"', 'regs'], desc: 'Yank registers',
      keys: ['"'],
      panel: 'yank',
      onOpen() { state.yankPanelIdx = 0; },
      menu: [
        {
          cheat: ['j/k', 'nav'], desc: 'Navigate registers',
          keys: ['j', 'k', 'up', 'down'],
          fn(key) {
            const regCount = 1 + state.yankMap.size;
            if (key.key === 'j' || key.key === 'down') {
              state.yankPanelIdx = Math.min(state.yankPanelIdx + 1, regCount - 1);
            } else {
              state.yankPanelIdx = Math.max(state.yankPanelIdx - 1, 0);
            }
          },
        },
        {
          cheat: ['p', 'paste'], desc: 'Paste from register',
          keys: ['p'],
          fn(key, buffer) {
            let lines;
            if (state.yankPanelIdx === 0) {
              lines = state.yankBuf;
            } else {
              const keys = [...state.yankMap.keys()];
              lines = state.yankMap.get(keys[state.yankPanelIdx - 1])?.lines || [];
            }
            if (lines.length > 0) {
              pushUndo(buffer);
              const ln = actualLineNum(buffer);
              unfoldLine(buffer, ln);
              for (let i = 0; i < lines.length; i++) {
                buffer.insertLine(ln + 1 + i, lines[i]);
              }
              state.cursor.line++;
              state.message = `${lines.length} line(s) pasted`;
            }
            popMode();
          },
        },
        {
          cheat: ['s', 'save'], desc: 'Save to register',
          keys: ['s'],
          fn() {
            pushMode('prompt', {
              prefix: 'label: ',
              buf: '',
              col: 0,
              label: 'REGISTER LABEL',
              onDone(val) {
                const label = val.trim();
                if (label && state.yankBuf.length > 0) {
                  const used = new Set(state.yankMap.keys());
                  let regKey = null;
                  for (let c = 97; c <= 122; c++) {
                    const ch = String.fromCharCode(c);
                    if (!used.has(ch)) { regKey = ch; break; }
                  }
                  if (regKey) {
                    state.yankMap.set(regKey, { label, lines: [...state.yankBuf] });
                    state.message = `Saved to register ${regKey}`;
                  } else {
                    state.message = 'All registers full';
                  }
                }
              },
            });
          },
        },
        {
          cheat: ['d', 'del'], desc: 'Delete register',
          keys: ['d'],
          fn() {
            if (state.yankPanelIdx > 0) {
              const keys = [...state.yankMap.keys()];
              state.yankMap.delete(keys[state.yankPanelIdx - 1]);
              state.yankPanelIdx = Math.max(0, state.yankPanelIdx - 1);
            }
          },
        },
        {
          cheat: ['"', 'close'], desc: 'Close panel',
          keys: ['"'],
          fn() {
            popMode();
          },
        },
        { cheat: ['Esc', 'close'], desc: 'Close panel', keys: null },
      ],
    },
    {
      cheat: ['u/r', 'undo'], desc: 'Undo / redo',
      keys: ['u', 'r'],
      fn(key, buffer) {
        if (key.key === 'u') undo(buffer);
        else redo(buffer);
      }
    },
    {
      cheat: ['/', 'search'], desc: 'Search',
      keys: ['/'],
      fn() {
        pushMode('prompt', {
          prefix: '/',
          buf: '',
          col: 0,
          label: 'SEARCH',
          _prevQuery: state.searchQuery || '',
          onDone(val, buffer) { state.searchQuery = val; searchNext(buffer, 1, true); },
        });
      }
    },
    {
      cheat: ['n/N', 'next/prev'], desc: 'Next/prev search result',
      keys: ['n', 'N'],
      fn(key, buffer) {
        searchNext(buffer, key.key === 'n' ? 1 : -1);
      }
    },
    {
      cheat: ['s', 'save'], desc: 'Save file',
      keys: ['s'],
      fn(key, buffer) {
        if (buffer.save()) {
          state.message = `Saved ${buffer.filename}`;
        } else {
          state.message = 'No filename';
        }
      }
    },
    {
      cheat: [':', 'cmd'], desc: 'Command mode',
      keys: [':'],
      fn() {
        pushMode('prompt', {
          prefix: ':',
          buf: '',
          col: 0,
          label: 'COMMAND',
          onDone(val, buffer) { execCommand(val, buffer); },
        });
      }
    },
  ];

  const selectKeymap = [
    {
      cheat: ['h/l', 'col'], desc: 'Extend char selection left/right',
      keys: ['h', 'l', 'left', 'right'],
      fn(key, buffer, ctx) {
        if (state.selectionUnit !== 'char') return;
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['w/b', 'word'], desc: 'Extend char selection by word',
      keys: ['w', 'b'],
      fn(key, buffer, ctx) {
        if (state.selectionUnit !== 'char') return;
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['j/k', 'extend'], desc: 'Extend selection',
      keys: ['j', 'down', 'k', 'up'],
      fn(key, buffer, ctx) {
        if (key.key === 'j' || key.key === 'down') {
          state.selection.head = Math.min(state.selection.head + 1, ctx.visible.length - 1);
        } else {
          state.selection.head = Math.max(state.selection.head - 1, 0);
        }
        state.cursor.line = state.selection.head;
      }
    },
    {
      cheat: ['J/K', 'barrier'], desc: 'Barrier jump up/down',
      keys: ['J', 'K'],
      fn(key, buffer) {
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['q/z', 'outdent'], desc: 'Nearest less-indented line above/below',
      keys: ['q', 'z'],
      fn(key, buffer) {
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['g/G', 'top/bot'], desc: 'Top / bottom of file',
      keys: ['g', 'G'],
      fn(key, buffer) {
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['Space', 'cycle unit'], desc: 'Cycle unit (line/section/indent/parent)',
      keys: [' '],
      fn(key, buffer, ctx) {
        if (state.selectionUnit === 'char') {
          state.selectionUnit = 'line';
          state.selection = { anchor: state.cursor.line, head: state.cursor.line };
          return;
        }
        const units = getLang(buffer.filename).selectionUnits;
        const idx = units.indexOf(state.selectionUnit);
        state.selectionUnit = units[(idx + 1) % units.length];
        let range = null;
        switch (state.selectionUnit) {
          case 'section': range = buffer.section(ctx.ln); break;
          case 'indent': range = buffer.indentBlock(ctx.ln); break;
          case 'parent': range = buffer.parentSection(ctx.ln); break;
          default:
            state.selection = { anchor: state.cursor.line, head: state.cursor.line };
            return;
        }
        if (range) {
          state.selection = {
            anchor: findVisibleIndex(buffer, range[0]),
            head: findVisibleIndex(buffer, range[1]),
          };
        }
      }
    },
    {
      cheat: ['d', 'del'], desc: 'Delete selection',
      keys: ['d'],
      fn(key, buffer, ctx) {
        if (!state.selection) return;
        pushUndo(buffer);
        if (state.selectionUnit === 'char') {
          const r = getCharRange(ctx.visible);
          const removed = buffer.deleteRange(r.startLine, r.startCol, r.endLine, r.endCol);
          state.yankBuf = [removed];
          state.yankType = 'char';
          state.cursor.line = findVisibleIndex(buffer, r.startLine);
          state.cursor.col = r.startCol;
          state.message = 'Char range deleted';
        } else {
          const start = Math.min(state.selection.anchor, state.selection.head);
          const end = Math.max(state.selection.anchor, state.selection.head);
          const startLn = ctx.visible[start].lineNum;
          const endLn = ctx.visible[end].lineNum;
          const removed = buffer.deleteLines(startLn, endLn);
          state.yankBuf = removed;
          state.yankType = 'line';
          state.message = `${removed.length} line(s) deleted`;
        }
        popMode();
        clampCursor(buffer);
      }
    },
    {
      cheat: ['y', 'yank'], desc: 'Yank selection',
      keys: ['y'],
      fn(key, buffer, ctx) {
        if (!state.selection) return;
        if (state.selectionUnit === 'char') {
          const r = getCharRange(ctx.visible);
          const parts = [];
          if (r.startLine === r.endLine) {
            parts.push(buffer.lines[r.startLine].slice(r.startCol, r.endCol + 1));
          } else {
            parts.push(buffer.lines[r.startLine].slice(r.startCol));
            for (let i = r.startLine + 1; i < r.endLine; i++) {
              parts.push(buffer.lines[i]);
            }
            parts.push(buffer.lines[r.endLine].slice(0, r.endCol + 1));
          }
          state.yankBuf = [parts.join('\n')];
          state.yankType = 'char';
          state.message = 'Char range yanked';
        } else {
          const start = Math.min(state.selection.anchor, state.selection.head);
          const end = Math.max(state.selection.anchor, state.selection.head);
          const startLn = ctx.visible[start].lineNum;
          const endLn = ctx.visible[end].lineNum;
          state.yankBuf = buffer.lines.slice(startLn, endLn + 1);
          state.yankType = 'line';
          state.message = `${state.yankBuf.length} line(s) yanked`;
        }
        popMode();
      }
    },
    {
      cheat: ['H/L', 'barrier'], desc: 'Barrier jump left/right (extend char selection)',
      keys: ['H', 'L'],
      fn(key, buffer) {
        if (state.selectionUnit !== 'char') return;
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['</>',  'indent'], desc: 'Indent/dedent selection',
      keys: ['>', '<'],
      fn(key, buffer, ctx) {
        if (!state.selection) return;
        pushUndo(buffer);
        const start = Math.min(state.selection.anchor, state.selection.head);
        const end = Math.max(state.selection.anchor, state.selection.head);
        for (let i = start; i <= end; i++) {
          const ln = ctx.visible[i].lineNum;
          if (key.key === '>') {
            buffer.lines[ln] = INDENT + buffer.lines[ln];
          } else {
            if (buffer.lines[ln].startsWith(INDENT)) {
              buffer.lines[ln] = buffer.lines[ln].slice(INDENT_SIZE);
            } else if (buffer.lines[ln].startsWith(' ')) {
              buffer.lines[ln] = buffer.lines[ln].slice(1);
            }
          }
        }
        buffer.dirty = true;
        buffer.invalidateCache();
        const startLn = ctx.visible[start].lineNum;
        const endLn = ctx.visible[end].lineNum;
        for (let i = start; i <= end; i++) {
          ensureVisible(buffer, ctx.visible[i].lineNum);
        }
        state.selection.anchor = findVisibleIndex(buffer, startLn);
        state.selection.head = findVisibleIndex(buffer, endLn);
        state.cursor.line = state.selection.head;
        state.message = key.key === '>' ? 'Indented' : 'Dedented';
      }
    },
    {
      cheat: ['n/N', 'search'], desc: 'Next/prev search result',
      keys: ['n', 'N'],
      fn(key, buffer) {
        dispatch(normalKeymap, key, buffer);
        state.selection.head = state.cursor.line;
      }
    },
    {
      cheat: ['Tab', 'fold'], desc: 'Fold selection',
      keys: ['tab'],
      fn(key, buffer, ctx) {
        if (!state.selection) return;
        const start = Math.min(state.selection.anchor, state.selection.head);
        const startLn = ctx.visible[start].lineNum;
        if (buffer.foldable(startLn)) {
          buffer.folds.add(startLn);
          popMode();
          clampCursor(buffer);
        }
      }
    },
    {
      cheat: ['Esc', 'cancel'], desc: 'Cancel selection',
      keys: ['escape'],
      fn() {
        popMode();
      }
    },
  ];

  const insertKeymap = [
    {
      cheat: ['type', 'insert'], desc: 'Insert characters',
      keys: null,
    },
    {
      cheat: ['Enter', 'newline'], desc: 'New line (auto-indent)',
      keys: ['enter'],
      fn(key, buffer, ctx) {
        unfoldLine(buffer, ctx.ln);
        const indent = buffer.indentLevel(ctx.ln);
        buffer.splitLine(ctx.ln, state.cursor.col);
        state.cursor.line++;
        const newLn = ctx.ln + 1;
        const spaces = ' '.repeat(indent);
        buffer.lines[newLn] = spaces + buffer.lines[newLn].trimStart();
        state.cursor.col = indent;
      }
    },
    {
      cheat: ['Bksp', 'del back'], desc: 'Delete behind',
      keys: ['backspace'],
      fn(key, buffer, ctx) {
        if (state.cursor.col > 0) {
          buffer.deleteChar(ctx.ln, state.cursor.col - 1);
          state.cursor.col--;
        } else if (ctx.ln > 0) {
          unfoldLine(buffer, ctx.ln - 1);
          const prevLen = buffer.lines[ctx.ln - 1].length;
          buffer.joinLines(ctx.ln - 1);
          state.cursor.line--;
          state.cursor.col = prevLen;
        }
      }
    },
    {
      cheat: ['Del', 'del fwd'], desc: 'Delete ahead',
      keys: ['delete'],
      fn(key, buffer, ctx) {
        if (state.cursor.col < buffer.lines[ctx.ln].length) {
          buffer.deleteChar(ctx.ln, state.cursor.col);
        } else if (ctx.ln < buffer.lines.length - 1) {
          unfoldLine(buffer, ctx.ln);
          buffer.joinLines(ctx.ln);
        }
      }
    },
    {
      cheat: ['\u2191\u2193\u2190\u2192', 'move'], desc: 'Move cursor',
      keys: ['left', 'right', 'up', 'down'],
      fn(key, buffer, ctx) {
        switch (key.key) {
          case 'left':
            state.cursor.col = Math.max(0, state.cursor.col - 1);
            break;
          case 'right':
            state.cursor.col = Math.min(buffer.lines[ctx.ln].length, state.cursor.col + 1);
            break;
          case 'up':
            state.cursor.line = Math.max(0, state.cursor.line - 1);
            break;
          case 'down':
            state.cursor.line = Math.min(ctx.visible.length - 1, state.cursor.line + 1);
            break;
        }
      }
    },
    {
      cheat: ['Tab', 'indent'], desc: 'Insert two spaces',
      keys: ['tab'], shift: false,
      fn(key, buffer, ctx) {
        buffer.insertChar(ctx.ln, state.cursor.col, INDENT);
        state.cursor.col += INDENT_SIZE;
      }
    },
    {
      cheat: ['S-Tab', 'dedent'], desc: 'Remove two spaces of indent',
      keys: ['tab'], shift: true,
      fn(key, buffer, ctx) {
        const line = buffer.lines[ctx.ln];
        const spaces = line.length - line.trimStart().length;
        const remove = Math.min(INDENT_SIZE, spaces);
        if (remove > 0) {
          for (let i = 0; i < remove; i++) buffer.deleteChar(ctx.ln, 0);
          state.cursor.col = Math.max(0, state.cursor.col - remove);
        }
      }
    },
    {
      cheat: ['Home/End', 'home/end'], desc: 'Beginning/end of line',
      keys: ['home', 'end'],
      fn(key, buffer, ctx) {
        if (key.key === 'home') {
          state.cursor.col = 0;
        } else {
          state.cursor.col = buffer.lines[ctx.ln].length;
        }
      }
    },
    {
      cheat: ['Esc', 'normal'], desc: 'Return to normal mode',
      keys: ['escape'],
      fn() {
        popMode();
      }
    },
  ];

  // --- Prompt helpers ---

  function getPromptBuf() {
    if (state.mode === 'prompt') return modeData().buf;
    return state.mode === 'command' ? state.commandBuf : state.searchBuf;
  }

  function setPromptBuf(val) {
    if (state.mode === 'prompt') { modeData().buf = val; return; }
    if (state.mode === 'command') state.commandBuf = val;
    else state.searchBuf = val;
  }

  function exitPrompt() {
    popMode();
  }

  const promptKeymap = [
    {
      cheat: ['\u2190\u2192', 'move'], desc: 'Move cursor in prompt',
      keys: ['left', 'right'],
      fn(key) {
        const buf = getPromptBuf();
        if (key.key === 'left') {
          state.promptCol = Math.max(0, state.promptCol - 1);
        } else {
          state.promptCol = Math.min(buf.length, state.promptCol + 1);
        }
      }
    },
    {
      cheat: ['Home/End', 'home/end'], desc: 'Beginning/end of prompt',
      keys: ['home', 'end'],
      fn(key) {
        if (key.key === 'home') {
          state.promptCol = 0;
        } else {
          state.promptCol = getPromptBuf().length;
        }
      }
    },
    {
      cheat: ['Bksp', 'del back'], desc: 'Delete behind',
      keys: ['backspace'],
      fn() {
        const buf = getPromptBuf();
        if (state.promptCol > 0) {
          setPromptBuf(buf.slice(0, state.promptCol - 1) + buf.slice(state.promptCol));
          state.promptCol--;
        } else if (buf.length === 0) {
          exitPrompt();
        }
      }
    },
    {
      cheat: ['Del', 'del fwd'], desc: 'Delete forward',
      keys: ['delete'],
      fn() {
        const buf = getPromptBuf();
        if (state.promptCol < buf.length) {
          setPromptBuf(buf.slice(0, state.promptCol) + buf.slice(state.promptCol + 1));
        }
      }
    },
    {
      cheat: ['Enter', 'submit'], desc: 'Submit', keys: null,
    },
    {
      cheat: ['Esc', 'cancel'], desc: 'Cancel', keys: null,
    },
  ];

  // --- Dispatch + mode handlers ---

  function dispatch(keymap, key, buffer) {
    const visible = buffer.visibleLines();
    const ln = actualLineNum(buffer);
    const ctx = { visible, ln };
    for (const entry of keymap) {
      if (!entry.keys) continue;
      if ((entry.ctrl || false) !== !!key.ctrl) continue;
      if (entry.shift !== undefined && (entry.shift || false) !== !!key.shift) continue;
      if (entry.keys.includes(key.key)) {
        if (entry.menu) {
          pushMode('menu', {
            keymap: entry.menu,
            label: entry.desc || 'MENU',
            panel: entry.panel || null,
          });
          if (entry.onOpen) entry.onOpen();
          return true;
        }
        entry.fn(key, buffer, ctx);
        return true;
      }
    }
    return false;
  }

  function handleInsert(key, buffer) {
    if (dispatch(insertKeymap, key, buffer)) return;
    if (!key.ctrl && key.key.length === 1 && key.key.charCodeAt(0) >= 32) {
      const ln = actualLineNum(buffer);
      buffer.insertChar(ln, state.cursor.col, key.key);
      state.cursor.col++;
    }
  }

  function handlePrompt(key, buffer) {
    const d = modeData();
    if (key.key === 'escape') {
      // Restore previous search query on cancel
      if (d.prefix === '/' && d._prevQuery !== undefined) {
        state.searchQuery = d._prevQuery;
      }
      popMode();
      return;
    }
    if (key.key === 'enter') {
      const val = d.buf;
      const onDone = d.onDone;
      popMode();
      if (onDone) onDone(val, buffer);
      return;
    }
    if (dispatch(promptKeymap, key, buffer)) {
      if (d.prefix === '/') state.searchQuery = d.buf;
      return;
    }
    if (key.key.length === 1 && !key.ctrl) {
      d.buf = d.buf.slice(0, d.col) + key.key + d.buf.slice(d.col);
      d.col++;
    }
    // Live search highlight as user types
    if (d.prefix === '/') state.searchQuery = d.buf;
  }

  function handleMenu(key, buffer) {
    if (key.key === 'escape') {
      popMode();
      return;
    }
    const d = modeData();
    dispatch(d.keymap, key, buffer);
  }

  function handleKey(key, buffer) {
    state.message = '';

    switch (state.mode) {
      case 'normal': dispatch(normalKeymap, key, buffer); break;
      case 'select': dispatch(selectKeymap, key, buffer); break;
      case 'insert': handleInsert(key, buffer); break;
      case 'prompt': handlePrompt(key, buffer); break;
      case 'menu': handleMenu(key, buffer); break;
    }

    clampCursor(buffer);
  }

  return {
    normalKeymap, selectKeymap, insertKeymap, promptKeymap,
    dispatch, handleKey, handleInsert,
    clampCursor, actualLineNum, findVisibleIndex,
    pushUndo, undo, redo,
    pushMode, popMode, modeData, modeDepth,
  };
}

if (typeof module !== 'undefined') module.exports = { createKeymap };
