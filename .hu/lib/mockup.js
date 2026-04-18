'use strict';
// Renders .hu test file previews in the tree browser's content pane.
// computeStates() replays key sequences against a headless editor to produce
// each frame's state. renderMockup() draws a mini editor view (gutter, folds,
// cursor, selection) for each state. renderLeafView() assembles the full
// before → keys → after display for story-mode and single-frame tests.

const fs = require('fs');
const pathMod = require('path');

const ESC = '\x1b[';
const RESET = `${ESC}0m`;
const DIM = `${ESC}2m`;
const BOLD = `${ESC}1m`;
const CYAN = `${ESC}36m`;
const WHITE = `${ESC}37m`;
const BG_BLUE = `${ESC}44m`;
const BG_MAGENTA = `${ESC}45m`;
const BG_CYAN = `${ESC}46m`;
const BG_RED = `${ESC}41m`;
const YELLOW = `${ESC}33m`;
const REVERSE = `${ESC}7m`;
const SEL_BG = {
  line: BG_BLUE,
  section: BG_MAGENTA,
  indent: BG_CYAN,
  parent: BG_RED,
};

function loadTestTree(dir) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    return [];
  }
  entries.sort((a, b) => a.name.localeCompare(b.name));

  const children = [];
  for (const entry of entries) {
    const fullPath = pathMod.join(dir, entry.name);
    if (entry.isDirectory()) {
      const sub = loadTestTree(fullPath);
      if (sub.length > 0) {
        children.push({
          type: 'group',
          name: entry.name.replace(/^\d+-/, '').replace(/-/g, ' '),
          children: sub,
        });
      }
    } else if (entry.name.endsWith('.hu')) {
      try {
        const data = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
        children.push({
          type: 'leaf',
          name: entry.name.replace(/\.hu$/, ''),
          filePath: fullPath,
          data,
        });
      } catch (e) {
        // skip invalid files
      }
    }
  }
  return children;
}

function computeStates(data) {
  const { createEditor } = require('./editor');
  const { createBuffer } = require('./buffer');

  const { state, handleKey } = createEditor();
  const buf = createBuffer(null);
  buf.lines = (data.before || []).slice();
  if (data.lineComment) buf.lineComment = data.lineComment;
  if (data.beforeFolds) {
    for (const f of data.beforeFolds) buf.folds.add(f);
  }

  const states = [];
  const frames = data.frames || [data];
  for (const frame of frames) {
    for (const k of (frame.keys || [])) {
      let ctrl = false;
      let actualKey = k;
      if (k.startsWith('C-')) {
        ctrl = true;
        actualKey = k.slice(2);
      }
      const isUpper = actualKey.length === 1 && actualKey >= 'A' && actualKey <= 'Z';
      handleKey({ key: actualKey, ctrl, shift: isUpper }, buf);
    }
    states.push({
      line: state.cursor.line,
      col: state.cursor.col,
      selection: state.selection ? { anchor: state.selection.anchor, head: state.selection.head } : null,
      selectionUnit: state.selectionUnit,
      mode: state.mode,
      lines: buf.lines.slice(),
      folds: new Set(buf.folds),
    });
  }

  return states;
}

function renderLeafView(data, cols) {
  const lines = [];
  const boxWidth = Math.min(cols - 4, 60);
  const margin = Math.max(2, Math.floor((cols - boxWidth) / 2));

  const states = computeStates(data);

  if (data.frames) {
    // Story mode: title, before, then each frame separated by dividers
    lines.push(`${BOLD}${data.desc || ''}${RESET}`);
    lines.push('');

    const beforeFolds = new Set(data.beforeFolds || []);
    lines.push(...renderMockup(data.before || [], { line: 0, col: 0 }, boxWidth, beforeFolds));

    for (let i = 0; i < data.frames.length; i++) {
      const frame = data.frames[i];
      const keysStr = (frame.keys || []).join(' ');
      const keysDisplay = `[${keysStr}]`;
      const frameDesc = frame.desc || '';
      // Keys on same line as divider
      const dashCount = Math.max(2, boxWidth - keysDisplay.length - 1);
      lines.push(`${DIM}${'─'.repeat(dashCount)}${RESET} ${YELLOW}${keysDisplay}${RESET}`);
      if (frameDesc) lines.push(`${DIM}${frameDesc}${RESET}`);

      const st = states[i];
      lines.push(...renderMockup(st.lines, st, boxWidth, st.folds));
    }
  } else {
    // Single-frame mode
    const keysStr = (data.keys || []).join(' ');
    const keysDisplay = `[${keysStr}]`;
    const desc = data.desc || '';
    if (desc) lines.push(`${BOLD}${desc}${RESET}`);
    lines.push('');

    const beforeFolds = new Set(data.beforeFolds || []);
    lines.push(...renderMockup(data.before || [], { line: 0, col: 0 }, boxWidth, beforeFolds));
    const dashCount = Math.max(2, boxWidth - keysDisplay.length - 1);
    lines.push(`${DIM}${'─'.repeat(dashCount)}${RESET} ${YELLOW}${keysDisplay}${RESET}`);

    const st = states[0];
    lines.push(...renderMockup(st.lines, st, boxWidth, st.folds));
  }

  return { lines, margin };
}

function indentOf(line) {
  const m = line.match(/^( *)/);
  return m ? m[1].length : 0;
}

function computeVisibleLines(lines, folds) {
  const visible = [];
  let i = 0;
  while (i < lines.length) {
    visible.push({ lineNum: i, text: lines[i] });
    if (folds.has(i)) {
      const baseIndent = indentOf(lines[i]);
      let end = i + 1;
      while (end < lines.length && indentOf(lines[end]) > baseIndent) {
        end++;
      }
      i = end;
    } else {
      i++;
    }
  }
  return visible;
}

function renderMockup(contentLines, cursorState, boxWidth, folds) {
  const result = [];

  const visLines = folds.size > 0 ? computeVisibleLines(contentLines, folds) : contentLines.map((text, i) => ({ lineNum: i, text }));
  const showLines = Math.min(Math.max(visLines.length, 3), 8);

  const curLine = cursorState ? cursorState.line : -1;
  const curCol = cursorState ? (cursorState.col || 0) : 0;
  const sel = cursorState ? cursorState.selection : null;
  const selStart = sel ? Math.min(sel.anchor, sel.head) : -1;
  const selEnd = sel ? Math.max(sel.anchor, sel.head) : -1;
  const selBg = cursorState ? (SEL_BG[cursorState.selectionUnit] || BG_BLUE) : BG_BLUE;

  for (let i = 0; i < showLines; i++) {
    const vis = i < visLines.length ? visLines[i] : null;
    const lineText = vis ? vis.text : '';
    const actualNum = vis ? vis.lineNum : i;
    const lineNum = String(actualNum + 1).padStart(2, ' ');
    const isCursorLine = i === curLine;

    let foldInd = ' ';
    if (vis && folds.has(actualNum)) {
      foldInd = `${CYAN}\u25b8${RESET}`;
    } else if (vis && actualNum < contentLines.length - 1 && indentOf(contentLines[actualNum + 1]) > indentOf(lineText)) {
      foldInd = `${DIM}\u25be${RESET}`;
    }

    const textWidth = boxWidth - 4;
    const truncated = lineText.length > textWidth ? lineText.slice(0, textWidth) : lineText;

    const inSelection = sel && i >= selStart && i <= selEnd;
    let renderedText;
    if (isCursorLine) {
      const col = Math.min(curCol, truncated.length);
      const before = truncated.slice(0, col);
      const cursorChar = col < truncated.length ? truncated[col] : ' ';
      const after = col < truncated.length ? truncated.slice(col + 1) : '';
      if (inSelection) {
        renderedText = `${selBg}${WHITE}${before}${REVERSE}${cursorChar}${RESET}${selBg}${WHITE}${after}${RESET}`;
      } else {
        renderedText = `${before}${REVERSE}${cursorChar}${RESET}${after}`;
      }
    } else if (inSelection) {
      renderedText = `${selBg}${WHITE}${truncated}${RESET}`;
    } else {
      renderedText = truncated;
    }

    result.push(`${DIM}${lineNum}${RESET}${foldInd} ${renderedText}`);
  }

  return result;
}

module.exports = { loadTestTree, renderLeafView };
