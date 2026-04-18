'use strict';

const path = require('path');
const { getLang } = require('../lang');
const {
  GUTTER_TOTAL, CURSOR_COL_OFFSET,
  YANK_PANEL_MAX_WIDTH, YANK_PANEL_RESERVED_ROWS,
} = require('./constants');
const { computeViewport, deriveCharRange, deriveModeInfo } = require('./engine');

const ESC = '\x1b[';
const RESET = `${ESC}0m`;
const DIM = `${ESC}2m`;
const REVERSE = `${ESC}7m`;
const BOLD = `${ESC}1m`;
const CYAN = `${ESC}36m`;
const YELLOW = `${ESC}33m`;
const GRAY = `${ESC}90m`;
const BG_BLUE = `${ESC}44m`;
const BG_MAGENTA = `${ESC}45m`;
const BG_CYAN = `${ESC}46m`;
const BG_RED = `${ESC}41m`;
const BG_GRAY = `${ESC}48;5;236m`;
const BG_CURSORLINE = `${ESC}48;5;236m`;
const BG_YELLOW = `${ESC}43m`;
const BG_LIGHT = `${ESC}48;5;252m`;
const FG_BLACK = `${ESC}38;5;16m`;
const FG_DGRAY = `${ESC}38;5;240m`;
const FG_MGRAY = `${ESC}38;5;59m`;
const WHITE = `${ESC}37m`;

const SEL_BG = {
  line: BG_BLUE,
  section: BG_MAGENTA,
  indent: BG_CYAN,
  parent: BG_RED,
  char: BG_BLUE,
};

const MODE_COLORS = {
  normal: `${ESC}34m`,    // blue
  select: `${ESC}33m`,    // yellow
  insert: `${ESC}32m`,    // green
  prompt: `${ESC}35m`,    // magenta
  menu: `${ESC}33m`,      // yellow
};

function renderCheatBar(state, cols) {
  const info = deriveModeInfo(state);
  const mode = info.effectiveMode;
  const entries = info.keymap.filter(e => e.cheat).map(e => e.cheat);
  const modeColor = MODE_COLORS[mode] || MODE_COLORS.normal;
  const modeLabel = info.label;

  // Build entry strings with visual lengths
  const rendered = entries.map(([key, desc]) => ({
    text: `${FG_BLACK}${BOLD}${key}${RESET}${BG_LIGHT}${FG_DGRAY}${DIM}:${RESET}${BG_LIGHT}${FG_MGRAY}${desc}`,
    len: key.length + 1 + desc.length,
  }));

  // Available width: cols - mode label - 2 chars for indicators - 2 for spacing
  const modeLabelLen = modeLabel.length;
  const areaWidth = cols - modeLabelLen - 4;

  // Convert pixel-based scroll to character offset (8px ≈ 1 char)
  const scrollChars = Math.floor((state.cheatScrollPx || 0) / 8);
  let startIdx = 0;
  let skipWidth = 0;
  for (let i = 0; i < rendered.length; i++) {
    const entryWidth = rendered[i].len + 1;
    if (skipWidth + entryWidth <= scrollChars) {
      skipWidth += entryWidth;
      startIdx = i + 1;
    } else break;
  }

  // Render entries starting from startIdx
  let usedWidth = 0;
  let visibleEntries = '';
  let lastVisible = startIdx;
  for (let i = startIdx; i < rendered.length; i++) {
    const needed = rendered[i].len + (usedWidth > 0 ? 1 : 0); // 1 for space separator
    if (usedWidth + needed > areaWidth) break;
    if (usedWidth > 0) { visibleEntries += ' '; usedWidth += 1; }
    visibleEntries += rendered[i].text;
    usedWidth += rendered[i].len;
    lastVisible = i;
  }

  const hasLeft = startIdx > 0;
  const hasRight = lastVisible < rendered.length - 1;
  const leftInd = hasLeft ? '◀' : ' ';
  const rightInd = hasRight ? '▶' : ' ';
  const padding = Math.max(0, areaWidth - usedWidth);

  return `${BG_LIGHT}${modeColor}${BOLD}${modeLabel}${RESET}${BG_LIGHT}${FG_BLACK}${leftInd} ${visibleEntries}${' '.repeat(padding)} ${rightInd}${RESET}`;
}

// Renders a line of text with comment highlighting, line selection, and/or
// char-level selection. The three concerns can overlap (e.g. a comment inside
// a char selection range), producing ~8 possible states per character.
function renderLineText(lineText, lineNum, lineComment, charRange, inSelection, selBg, scrollX, searchQuery, isCursorLine) {
  const R = isCursorLine ? `${RESET}${BG_CURSORLINE}` : RESET;

  // Char-level selection: highlight a column range, possibly interleaved with comments
  if (charRange && lineNum >= charRange.startLn && lineNum <= charRange.endLn) {
    return renderCharSelection(lineText, lineNum, lineComment, charRange, selBg, scrollX);
  }

  // Find search matches in this line (smart case: insensitive unless query has uppercase)
  const matches = [];
  if (searchQuery && searchQuery.length > 0) {
    const caseSensitive = searchQuery !== searchQuery.toLowerCase();
    const haystack = caseSensitive ? lineText : lineText.toLowerCase();
    const needle = caseSensitive ? searchQuery : searchQuery.toLowerCase();
    let idx = 0;
    while (idx < haystack.length) {
      const pos = haystack.indexOf(needle, idx);
      if (pos < 0) break;
      matches.push({ start: pos, end: pos + needle.length });
      idx = pos + 1;
    }
  }

  // No search matches: use the original fast path
  if (matches.length === 0) {
    if (lineComment) {
      const commentIdx = lineText.indexOf(lineComment);
      if (commentIdx >= 0) {
        const code = lineText.slice(0, commentIdx);
        const comment = lineText.slice(commentIdx);
        if (inSelection) return `${selBg}${WHITE}${code}${DIM}${comment}${R}`;
        return code + `${GRAY}${comment}${R}`;
      }
    }
    if (inSelection) return `${selBg}${WHITE}${lineText}${R}`;
    return lineText;
  }

  // Render with search highlighting
  const commentIdx = lineComment ? lineText.indexOf(lineComment) : -1;
  let result = '';
  let pos = 0;
  for (const m of matches) {
    // Text before match
    if (m.start > pos) {
      result += renderSpan(lineText.slice(pos, m.start), pos, commentIdx, inSelection, selBg, R);
    }
    // The match itself — yellow bg always wins over selection
    const matchText = lineText.slice(m.start, m.end);
    result += `${BG_YELLOW}${FG_BLACK}${matchText}${R}`;
    pos = m.end;
  }
  // Text after last match
  if (pos < lineText.length) {
    result += renderSpan(lineText.slice(pos), pos, commentIdx, inSelection, selBg, R);
  }
  return result;
}

// Render a non-match span with comment and selection styling
function renderSpan(text, startPos, commentIdx, inSelection, selBg, R) {
  if (commentIdx >= 0 && startPos + text.length > commentIdx && commentIdx >= startPos) {
    const cOff = commentIdx - startPos;
    const code = text.slice(0, cOff);
    const comment = text.slice(cOff);
    if (inSelection) return `${selBg}${WHITE}${code}${DIM}${comment}${R}`;
    return code + `${GRAY}${comment}${R}`;
  }
  if (commentIdx >= 0 && startPos >= commentIdx) {
    if (inSelection) return `${selBg}${DIM}${text}${R}`;
    return `${GRAY}${text}${R}`;
  }
  if (inSelection) return `${selBg}${WHITE}${text}${R}`;
  return text;
}

// Handles the complex case: char-level selection range intersected with comment highlighting.
// Splits the line into three segments (before selection, selected, after selection) and
// renders each with the appropriate comment/selection styling.
function renderCharSelection(lineText, lineNum, lineComment, charRange, selBg, scrollX) {
  let hlStart = 0;
  let hlEnd = lineText.length;
  if (lineNum === charRange.startLn) hlStart = charRange.startCol - scrollX;
  if (lineNum === charRange.endLn) hlEnd = charRange.endCol - scrollX + 1;
  hlStart = Math.max(0, Math.min(hlStart, lineText.length));
  hlEnd = Math.max(hlStart, Math.min(hlEnd, lineText.length));

  const before = lineText.slice(0, hlStart);
  const hl = lineText.slice(hlStart, hlEnd);
  const after = lineText.slice(hlEnd);

  if (!lineComment) {
    return before + `${selBg}${WHITE}${hl}${RESET}` + after;
  }

  const commentIdx = lineText.indexOf(lineComment);
  if (commentIdx < 0) {
    return before + `${selBg}${WHITE}${hl}${RESET}` + after;
  }

  // Walk three segments (pre-selection, selection, post-selection),
  // applying comment dimming where the comment token starts.
  let result = '';
  let pos = 0;
  const segments = [
    { end: hlStart, sel: false },
    { end: hlEnd, sel: true },
    { end: lineText.length, sel: false },
  ];
  for (const seg of segments) {
    const segText = lineText.slice(pos, seg.end);
    if (segText.length > 0) {
      const cIdx = segText.indexOf(lineComment);
      if (cIdx >= 0 && pos + cIdx >= commentIdx) {
        const pre = segText.slice(0, cIdx);
        const com = segText.slice(cIdx);
        if (seg.sel) {
          result += `${selBg}${WHITE}${pre}${DIM}${com}${RESET}`;
        } else {
          result += pre + `${GRAY}${com}${RESET}`;
        }
      } else if (pos >= commentIdx) {
        result += seg.sel ? `${selBg}${DIM}${segText}${RESET}` : `${GRAY}${segText}${RESET}`;
      } else {
        result += seg.sel ? `${selBg}${WHITE}${segText}${RESET}` : segText;
      }
    }
    pos = seg.end;
  }
  return result;
}

function render(state, buffer, out) {
  const rows = out.rows || 24;
  const cols = out.columns || 80;

  const contentCols = cols;

  const visible = buffer.visibleLines();
  const areaHeight = rows - 2; // rows 1 to rows-2 (cheat at rows-1, status at rows)
  const editorRows = areaHeight - 1; // rows 2 to rows-2 (row 1 = metadata line)

  const displayCols = contentCols - GUTTER_TOTAL;

  // Compute scroll and char-range via shared engine
  computeViewport(state, editorRows, displayCols);
  const charRange = deriveCharRange(state, visible);

  const lang = getLang(buffer.filename);
  const lineComment = lang.lineComment;

  let output = `${ESC}?25l`; // hide cursor
  output += `${ESC}H`; // home

  // Clear content rows
  for (let r = 0; r < areaHeight; r++) {
    output += `${ESC}${r + 1};1H${ESC}2K`;
  }

  // Metadata line (row 1)
  output += `${ESC}1;1H`;
  const relPath = buffer.filename || '[no file]';
  const dirtyIndicator = buffer.dirty ? ` ${YELLOW}[+]${RESET}` : '';
  output += ` ${DIM}${relPath}${RESET}${dirtyIndicator}`;

  // Map cursor visible-line index to actual line number for selection check
  const selStart = state.selection ? Math.min(state.selection.anchor, state.selection.head) : -1;
  const selEnd = state.selection ? Math.max(state.selection.anchor, state.selection.head) : -1;
  const selBg = SEL_BG[state.selectionUnit] || BG_BLUE;

  for (let r = 0; r < editorRows; r++) {
    const visIdx = state.scroll + r;
    if (visIdx >= 0 && visIdx < visible.length) {
      const { lineNum, text } = visible[visIdx];
      const inSelection = state.selection && visIdx >= selStart && visIdx <= selEnd;

      const isCursorLine = visIdx === state.cursor.line && !inSelection && state.mode === 'normal';

      // Position at content area start (row 2+ because row 1 = metadata)
      output += `${ESC}${r + 2};1H`;
      // Fill row with cursorline bg
      if (isCursorLine) output += `${BG_CURSORLINE}${ESC}2K`;

      // Build line content
      let lineText = text;

      // Gutter (line number + fold indicator)
      const gutterNum = String(lineNum + 1).padStart(4, ' ');
      let foldInd;
      if (buffer.folds.has(lineNum)) {
        foldInd = `${CYAN}▸${RESET}${isCursorLine ? BG_CURSORLINE : ''}`;
      } else if (buffer.foldable(lineNum)) {
        foldInd = `${DIM}▾${RESET}${isCursorLine ? BG_CURSORLINE : ''}`;
      } else {
        foldInd = ' ';
      }
      output += `${isCursorLine ? BG_CURSORLINE : ''}${DIM}${gutterNum}${RESET}${isCursorLine ? BG_CURSORLINE : ''}${foldInd} `;

      // Check if folded
      let foldSuffix = '';
      if (buffer.folds.has(lineNum)) {
        const count = buffer.foldedLineCount(lineNum);
        if (count > 0) {
          foldSuffix = `  ${DIM}[${count} lines]${RESET}`;
        }
      }

      // Slice to horizontal viewport
      lineText = lineText.slice(state.scrollX, state.scrollX + displayCols);

      // Apply syntax highlighting (comment detection) + selection
      output += renderLineText(lineText, lineNum, lineComment, charRange, inSelection, selBg, state.scrollX, state.searchQuery, isCursorLine);

      output += foldSuffix;
      if (isCursorLine) output += RESET;
    }
  }

  // Yank panel overlay — shown when a menu frame with panel: 'yank' is active
  const yankFrame = state._modeStack.find(f => f.data && f.data.panel === 'yank');
  if (yankFrame) {
    output += renderYankPanel(state, rows, cols);
  }

  // Cheat bar (second-to-last row)
  output += `${ESC}${rows - 1};1H${ESC}2K`;
  output += renderCheatBar(state, cols);

  // Status line (last row): prompt > message > filename
  const statusRow = rows;
  output += `${ESC}${statusRow};1H${ESC}2K`;
  if (state.mode === 'prompt') {
    const d = state._modeStack[state._modeStack.length - 1].data;
    output += `${d.prefix}${d.buf}`;
  } else if (state.mode === 'command') {
    output += `:${state.commandBuf}`;
  } else if (state.mode === 'search') {
    output += `/${state.searchBuf || ''}`;
  } else if (state.message) {
    output += `${DIM}${state.message}${RESET}`;
  } else if (state.searchQuery) {
    output += `${DIM}/${state.searchQuery}${RESET}`;
  }

  // Position cursor
  if (state.mode === 'prompt') {
    const d = state._modeStack[state._modeStack.length - 1].data;
    output += `${ESC}${statusRow};${d.col + d.prefix.length + 1}H`;
  } else if (state.mode === 'command' || state.mode === 'search') {
    output += `${ESC}${statusRow};${state.promptCol + 2}H`;
  } else {
    const cursorScreenRow = state.cursor.line - state.scroll + 2; // +2: row 1 is metadata
    const cursorScreenCol = state.cursor.col - state.scrollX + CURSOR_COL_OFFSET;
    output += `${ESC}${cursorScreenRow};${cursorScreenCol}H`;
  }

  // Cursor color: green in insert mode, default otherwise
  if (state.mode === 'insert') {
    output += `\x1b]12;#00cc00\x07`;
  } else {
    output += `\x1b]112\x07`;
  }
  output += `${ESC}?25h`; // show cursor
  out.write(output);
}

function renderYankPanel(state, rows, cols) {
  const panelWidth = Math.min(Math.floor(cols * 0.4), YANK_PANEL_MAX_WIDTH);
  const startCol = cols - panelWidth + 1;
  const panelRows = rows - YANK_PANEL_RESERVED_ROWS;
  const startRow = 1;

  let out = '';

  // Top border
  out += `${ESC}${startRow};${startCol}H${BOLD}┌─ yanks ${'─'.repeat(panelWidth - 10)}┐${RESET}`;

  const registers = [{ key: '_', label: '(last yank)', lines: state.yankBuf }];
  for (const [k, v] of state.yankMap) {
    registers.push({ key: k, label: v.label || '', lines: v.lines });
  }

  let r = startRow + 1;
  for (let ri = 0; ri < registers.length && r < startRow + panelRows - 1; ri++) {
    const reg = registers[ri];
    const selected = ri === state.yankPanelIdx;
    const marker = selected ? `${REVERSE} ▸ ${RESET}` : '   ';
    const keyLabel = `${YELLOW}${reg.key}${RESET}  ${DIM}${reg.label}${RESET}`;
    out += `${ESC}${r};${startCol}H│${marker}${keyLabel}`;
    // Pad to panel edge
    out += `${ESC}${r};${startCol + panelWidth - 1}H│`;
    r++;

    // Preview (up to 3 lines)
    const preview = reg.lines.slice(0, 3);
    for (const pline of preview) {
      if (r >= startRow + panelRows - 1) break;
      const truncated = pline.slice(0, panelWidth - 8);
      out += `${ESC}${r};${startCol}H│     ${DIM}${truncated}${RESET}`;
      out += `${ESC}${r};${startCol + panelWidth - 1}H│`;
      r++;
    }
    if (reg.lines.length > 3 && r < startRow + panelRows - 1) {
      out += `${ESC}${r};${startCol}H│     ${DIM}... (${reg.lines.length} lines)${RESET}`;
      out += `${ESC}${r};${startCol + panelWidth - 1}H│`;
      r++;
    }
    // Blank separator
    if (r < startRow + panelRows - 1) {
      out += `${ESC}${r};${startCol}H│${' '.repeat(panelWidth - 2)}│`;
      r++;
    }
  }

  // Fill remaining rows
  while (r < startRow + panelRows - 1) {
    out += `${ESC}${r};${startCol}H│${' '.repeat(panelWidth - 2)}│`;
    r++;
  }

  // Bottom border
  out += `${ESC}${r};${startCol}H${BOLD}└${'─'.repeat(panelWidth - 2)}┘${RESET}`;
  r++;
  // Hints
  if (r <= rows - 2) {
    out += `${ESC}${r};${startCol}H${DIM} j/k:nav p:paste s:save d:del Esc:close${RESET}`;
  }

  return out;
}

module.exports = { render };
