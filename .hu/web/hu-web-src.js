// --- mapKeyEvent (replaces lib/input.js for browser) ---

function mapKeyEvent(e) {
  const map = {
    ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right',
    Enter: 'enter', Backspace: 'backspace', Tab: 'tab', Escape: 'escape',
    Delete: 'delete', Home: 'home', End: 'end',
    PageUp: 'pageup', PageDown: 'pagedown',
  };

  let key = map[e.key] || e.key;
  const ctrl = e.ctrlKey || e.metaKey;
  const shift = e.shiftKey;

  // Normalize: Ctrl+Shift+letter comes through uppercase; we want lowercase for ctrl combos
  if (ctrl && key.length === 1 && key >= 'A' && key <= 'Z') {
    key = key.toLowerCase();
  }

  // Prevent browser defaults for keys we handle
  if (key === 'tab' || key === 'escape' || ctrl) {
    e.preventDefault();
  }
  // Also prevent Space in normal/select mode (will be checked by caller)
  // Prevent slash (search trigger)
  if (key === '/' || key === ':') {
    e.preventDefault();
  }

  return { key, ctrl, shift };
}


// --- Canvas renderer (replaces lib/render.js) ---

const COLORS = {
  bg:       '#1e1e1e',
  fg:       '#c8c8c8',
  dim:      '#666666',
  bold:     '#ffffff',
  cyan:     '#4ec9b0',
  yellow:   '#dcdcaa',
  gray:     '#666666',
  gutter:   '#858585',
  cheatBg:  '#c8c8c8',
  cheatFg:  '#1e1e1e',
  cheatDim: '#555555',
  statusBg: '#c8c8c8',
  statusFg: '#1e1e1e',

  // Selection backgrounds
  selLine:    '#264f78',
  selSection: '#5c2d5c',
  selIndent:  '#2d5c5c',
  selParent:  '#5c2d2d',

  // Mode label colors (dark bg)
  modeNormal: '#569cd6',
  modeSelect: '#dcdcaa',
  modeInsert: '#6a9955',
  modePrompt: '#c586c0',

  // Mode label colors (light cheat bar)
  modeNormalLight: '#1a5a9e',
  modeSelectLight: '#8a7a20',
  modeInsertLight: '#3a6a2a',
  modePromptLight: '#8a2a8a',

  // Cursor
  cursorNormal: '#ffffff',
  cursorInsert: '#00cc00',
};

const SEL_COLORS = {
  line: COLORS.selLine,
  section: COLORS.selSection,
  indent: COLORS.selIndent,
  parent: COLORS.selParent,
  char: COLORS.selLine,
};

const MODE_LABEL_COLORS = {
  normal: COLORS.modeNormal,
  select: COLORS.modeSelect,
  insert: COLORS.modeInsert,
  prompt: COLORS.modePrompt,
};

const MODE_LABEL_COLORS_LIGHT = {
  normal: COLORS.modeNormalLight,
  select: COLORS.modeSelectLight,
  insert: COLORS.modeInsertLight,
  prompt: COLORS.modePromptLight,
};

function renderCanvas(ctx, state, buffer, cols, rows, charW, lineH, pixelRatio) {
  const w = cols * charW;
  const h = rows * lineH;

  ctx.save();
  ctx.scale(pixelRatio, pixelRatio);

  // Clear
  ctx.fillStyle = COLORS.bg;
  ctx.fillRect(0, 0, w, h);

  const visible = buffer.visibleLines();
  const contentRows = rows - 4; // status + message + 2-row cheat bar
  const lang = getLang(buffer.filename);
  const lineComment = lang.lineComment;

  // --- Content area dimensions ---
  const gutterChars = 4;  // line number width
  const foldChars = 1;    // fold indicator
  const gutterTotal = gutterChars + foldChars + 1; // +1 space
  const displayCols = cols - gutterTotal;

  // Compute scroll and char-range via shared engine
  computeViewport(state, contentRows, displayCols);
  const charRange = deriveCharRange(state, visible);

  // Selection range
  const selStart = state.selection ? Math.min(state.selection.anchor, state.selection.head) : -1;
  const selEnd = state.selection ? Math.max(state.selection.anchor, state.selection.head) : -1;
  const selBg = SEL_COLORS[state.selectionUnit] || COLORS.selLine;

  // --- Row 0: Status bar ---
  const statusY = 0;
  ctx.fillStyle = COLORS.statusBg;
  ctx.fillRect(0, statusY, w, lineH);

  const modFlag = buffer.dirty ? ' [modified]' : '';
  const fname = buffer.filename || '[no file]';
  const actualLine = visible[state.cursor.line] ? visible[state.cursor.line].lineNum + 1 : 0;
  const colNum = state.cursor.col + 1;
  const statusLeft = ` ${fname}${modFlag} | ${actualLine}:${colNum}`;
  const statusRight = `${visible.length} lines `;

  ctx.fillStyle = COLORS.statusFg;
  ctx.fillText(statusLeft, 0, statusY + lineH * 0.78);
  ctx.fillText(statusRight, (cols - statusRight.length) * charW, statusY + lineH * 0.78);

  // --- Content rows ---

  for (let r = 0; r < contentRows; r++) {
    const y = (r + 1) * lineH;
    const visIdx = state.scroll + r;
    if (visIdx < 0 || visIdx >= visible.length) continue;

    const { lineNum, text } = visible[visIdx];
    const inSelection = state.selection && visIdx >= selStart && visIdx <= selEnd;

    // Selection background
    if (charRange && lineNum >= charRange.startLn && lineNum <= charRange.endLn) {
      // Char-level: partial row highlight
      const textX = gutterTotal * charW;
      let hlStart = 0;
      let hlEnd = text.length;
      if (lineNum === charRange.startLn) hlStart = charRange.startCol;
      if (lineNum === charRange.endLn) hlEnd = charRange.endCol + 1;
      const hlStartPx = textX + Math.max(0, hlStart - state.scrollX) * charW;
      const hlEndPx = textX + Math.max(0, hlEnd - state.scrollX) * charW;
      ctx.fillStyle = selBg;
      ctx.fillRect(hlStartPx, y, hlEndPx - hlStartPx, lineH);
    } else if (inSelection) {
      ctx.fillStyle = selBg;
      ctx.fillRect(0, y, w, lineH);
    }

    // Gutter: line number
    const gutterStr = String(lineNum + 1).padStart(gutterChars, ' ');
    ctx.fillStyle = COLORS.dim;
    ctx.fillText(gutterStr, 0, y + lineH * 0.78);

    // Fold indicator
    const foldX = gutterChars * charW;
    if (buffer.folds.has(lineNum)) {
      ctx.fillStyle = COLORS.cyan;
      ctx.fillText('\u25b8', foldX, y + lineH * 0.78); // ▸
    } else if (buffer.foldable(lineNum)) {
      ctx.fillStyle = COLORS.dim;
      ctx.fillText('\u25be', foldX, y + lineH * 0.78); // ▾
    }

    // Text content
    const textX = gutterTotal * charW;
    let lineText = text.slice(state.scrollX, state.scrollX + displayCols);

    // Fold suffix
    let foldSuffix = '';
    if (buffer.folds.has(lineNum)) {
      const count = buffer.foldedLineCount(lineNum);
      if (count > 0) foldSuffix = `  [${count} lines]`;
    }

    // Determine if this line is in char-level selection
    const isCharSelected = charRange && lineNum >= charRange.startLn && lineNum <= charRange.endLn;

    // Comment highlighting
    if (lineComment) {
      const commentIdx = lineText.indexOf(lineComment);
      if (commentIdx >= 0) {
        const before = lineText.slice(0, commentIdx);
        const comment = lineText.slice(commentIdx);
        ctx.fillStyle = (inSelection || isCharSelected) ? COLORS.bold : COLORS.fg;
        ctx.fillText(before, textX, y + lineH * 0.78);
        ctx.fillStyle = (inSelection || isCharSelected) ? COLORS.dim : COLORS.gray;
        ctx.fillText(comment, textX + commentIdx * charW, y + lineH * 0.78);
      } else {
        ctx.fillStyle = (inSelection || isCharSelected) ? COLORS.bold : COLORS.fg;
        ctx.fillText(lineText, textX, y + lineH * 0.78);
      }
    } else {
      ctx.fillStyle = (inSelection || isCharSelected) ? COLORS.bold : COLORS.fg;
      ctx.fillText(lineText, textX, y + lineH * 0.78);
    }

    // Fold suffix (always dim)
    if (foldSuffix) {
      ctx.fillStyle = COLORS.dim;
      ctx.fillText(foldSuffix, textX + lineText.length * charW, y + lineH * 0.78);
    }
  }

  // --- Yank panel overlay ---
  const yankFrame = state._modeStack.find(f => f.data && f.data.panel === 'yank');
  if (yankFrame) {
    renderYankPanelCanvas(ctx, state, cols, rows, charW, lineH);
  }

  // --- Message line (row rows-3) ---
  const msgY = (rows - 3) * lineH;
  ctx.fillStyle = COLORS.bg;
  ctx.fillRect(0, msgY, w, lineH);

  if (state.mode === 'prompt') {
    const d = state._modeStack[state._modeStack.length - 1].data;
    ctx.fillStyle = COLORS.fg;
    ctx.fillText(d.prefix + d.buf, 0, msgY + lineH * 0.78);
  } else if (state.mode === 'command') {
    ctx.fillStyle = COLORS.fg;
    ctx.fillText(':' + state.commandBuf, 0, msgY + lineH * 0.78);
  } else if (state.mode === 'search') {
    ctx.fillStyle = COLORS.fg;
    ctx.fillText('/' + (state.searchBuf || ''), 0, msgY + lineH * 0.78);
  } else if (state.message) {
    ctx.fillStyle = COLORS.dim;
    ctx.fillText(state.message, 0, msgY + lineH * 0.78);
  }

  // --- Cheat bar (row rows-1) ---
  const cheatButtons = renderCheatBarCanvas(ctx, state, cols, charW, lineH, (rows - 1) * lineH);

  // --- Cursor ---
  let cursorScreenRow, cursorScreenCol;
  if (state.mode === 'prompt') {
    const d = state._modeStack[state._modeStack.length - 1].data;
    cursorScreenRow = rows - 2;
    cursorScreenCol = d.col + d.prefix.length;
  } else if (state.mode === 'command' || state.mode === 'search') {
    cursorScreenRow = rows - 2;
    cursorScreenCol = state.promptCol + 1;
  } else {
    cursorScreenRow = state.cursor.line - state.scroll + 1;
    cursorScreenCol = state.cursor.col - state.scrollX + gutterTotal;
  }

  const cursorX = cursorScreenCol * charW;
  const cursorY = cursorScreenRow * lineH;

  if (state.mode === 'insert') {
    // Line cursor for insert mode
    ctx.fillStyle = COLORS.cursorInsert;
    ctx.fillRect(cursorX, cursorY + 1, 2, lineH - 2);
  } else {
    // Block cursor
    ctx.fillStyle = COLORS.cursorNormal;
    ctx.globalAlpha = 0.5;
    ctx.fillRect(cursorX, cursorY, charW, lineH);
    ctx.globalAlpha = 1.0;
  }

  ctx.restore();
  return cheatButtons;
}

function renderCheatBarCanvas(ctx, state, cols, charW, lineH, y) {
  const info = deriveModeInfo(state);
  const mode = info.effectiveMode;
  const keymap = info.keymap;
  const modeColor = MODE_LABEL_COLORS_LIGHT[mode] || COLORS.modeNormalLight;
  const modeLabel = info.label;

  // Build button list: split compound cheat keys into individual buttons
  const buttons = [];
  for (const entry of keymap) {
    if (!entry.cheat) continue;
    if (!entry.keys) continue; // skip display-only entries (like 'type insert')
    const [keyStr, descStr] = entry.cheat;
    const cheatKeys = keyStr.split('/');
    for (let ki = 0; ki < cheatKeys.length; ki++) {
      const displayKey = cheatKeys[ki];
      // Map display key to the actual key to fire
      let fireKey = displayKey;
      let ctrl = entry.ctrl || false;
      if (displayKey === 'Tab') fireKey = 'tab';
      else if (displayKey === 'Space') fireKey = ' ';
      else if (displayKey === 'Esc') fireKey = 'escape';
      else if (displayKey === 'Enter') fireKey = 'enter';
      else if (displayKey === 'Bksp') fireKey = 'backspace';
      else if (displayKey === 'Del') fireKey = 'delete';
      else if (displayKey.startsWith('C-')) { fireKey = displayKey.slice(2); ctrl = true; }
      else if (displayKey === '\u2191\u2193\u2190\u2192') fireKey = null; // arrow symbols, not tappable
      buttons.push({ displayKey, desc: descStr, fireKey, ctrl });
    }
  }

  // Background
  ctx.fillStyle = COLORS.cheatBg;
  ctx.fillRect(0, y, cols * charW, lineH);

  // Mode label
  ctx.fillStyle = modeColor;
  ctx.fillText(modeLabel, 0, y + lineH * 0.78);

  // Button area starts after mode label
  const btnPadX = charW * 0.5;   // horizontal padding inside button
  const btnGap = charW * 0.5;    // gap between buttons
  const btnRadius = 3;
  const modeLabelPx = modeLabel.length * charW;
  const areaStartX = modeLabelPx + charW;
  const areaEndX = cols * charW - charW;

  // Render buttons and build hit-test array
  const cheatButtons = [];
  let xPos = areaStartX - (state.cheatScrollPx || 0);

  for (let i = 0; i < buttons.length; i++) {
    const btn = buttons[i];
    const keyText = btn.displayKey;
    const descText = ' ' + btn.desc;
    const textW = (keyText.length + descText.length) * charW;
    const btnW = textW + btnPadX * 2;
    const btnX = xPos;
    const btnY = y + 2;
    const btnH = lineH - 4;

    // Skip buttons that are entirely off-screen left
    if (btnX + btnW < areaStartX) {
      xPos += btnW + btnGap;
      continue;
    }
    // Stop if button starts past right edge
    if (btnX > areaEndX) break;

    // Button background (rounded rect)
    ctx.fillStyle = '#aaaaaa';
    ctx.beginPath();
    ctx.roundRect(btnX, btnY, btnW, btnH, btnRadius);
    ctx.fill();

    // Key part (bold dark)
    ctx.fillStyle = COLORS.cheatFg;
    ctx.fillText(keyText, btnX + btnPadX, y + lineH * 0.78);

    // Desc part (dimmer)
    ctx.fillStyle = COLORS.cheatDim;
    ctx.fillText(descText, btnX + btnPadX + keyText.length * charW, y + lineH * 0.78);

    // Store hit rect in CSS pixels (pre-DPR) for tappable buttons
    if (btn.fireKey) {
      cheatButtons.push({
        x: btnX, y: y, w: btnW, h: lineH,
        key: btn.fireKey, ctrl: btn.ctrl || false,
      });
    }

    xPos += btnW + btnGap;
  }

  return cheatButtons;
}

function renderYankPanelCanvas(ctx, state, cols, rows, charW, lineH) {
  const panelWidthChars = Math.min(Math.floor(cols * 0.4), 50);
  const panelX = (cols - panelWidthChars) * charW;
  const panelRows = rows - 4;
  const startRow = 1;
  const panelW = panelWidthChars * charW;

  // Panel background
  ctx.fillStyle = '#252525';
  ctx.fillRect(panelX, startRow * lineH, panelW, panelRows * lineH);

  // Border
  ctx.strokeStyle = COLORS.dim;
  ctx.lineWidth = 1;
  ctx.strokeRect(panelX + 0.5, startRow * lineH + 0.5, panelW - 1, panelRows * lineH - 1);

  // Title
  ctx.fillStyle = COLORS.bold;
  ctx.fillText(' yanks ', panelX + charW, (startRow + 1) * lineH - lineH * 0.22);

  const registers = [{ key: '_', label: '(last yank)', lines: state.yankBuf }];
  for (const [k, v] of state.yankMap) {
    registers.push({ key: k, label: v.label || '', lines: v.lines });
  }

  let r = startRow + 1;
  for (let ri = 0; ri < registers.length && r < startRow + panelRows - 1; ri++) {
    const reg = registers[ri];
    const selected = ri === state.yankPanelIdx;
    const rowY = r * lineH;

    if (selected) {
      ctx.fillStyle = COLORS.selLine;
      ctx.fillRect(panelX, rowY, panelW, lineH);
    }

    // Key label
    ctx.fillStyle = selected ? COLORS.bold : COLORS.yellow;
    ctx.fillText(` ${selected ? '\u25b8' : ' '} ${reg.key}`, panelX, rowY + lineH * 0.78);
    ctx.fillStyle = COLORS.dim;
    ctx.fillText(`  ${reg.label}`, panelX + 5 * charW, rowY + lineH * 0.78);
    r++;

    // Preview lines
    const preview = reg.lines.slice(0, 3);
    for (const pline of preview) {
      if (r >= startRow + panelRows - 1) break;
      const truncated = pline.slice(0, panelWidthChars - 8);
      ctx.fillStyle = COLORS.dim;
      ctx.fillText(`     ${truncated}`, panelX, r * lineH + lineH * 0.78);
      r++;
    }
    if (reg.lines.length > 3 && r < startRow + panelRows - 1) {
      ctx.fillStyle = COLORS.dim;
      ctx.fillText(`     ... (${reg.lines.length} lines)`, panelX, r * lineH + lineH * 0.78);
      r++;
    }
    r++; // blank separator
  }

  // Hints at bottom
  const hintRow = startRow + panelRows;
  if (hintRow < rows) {
    ctx.fillStyle = COLORS.dim;
    ctx.fillText(' j/k:nav p:paste s:save d:del Esc:close', panelX, hintRow * lineH + lineH * 0.78);
  }
}


// ============================================================
// <h-edit> Web Component
// ============================================================

class HEdit extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this._buffer = null;
    this._editor = null;
    this._canvas = null;
    this._ctx = null;
    this._charW = 0;
    this._lineH = 0;
    this._rows = 0;
    this._cols = 0;
    this._fileMap = {};
    this._cheatButtons = [];
    this._resizeObserver = null;
    this._boundKeyDown = this._onKeyDown.bind(this);
  }

  connectedCallback() {
    // Shadow DOM structure
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          position: relative;
          overflow: hidden;
          outline: none;
        }
        canvas {
          display: block;
          width: 100%;
          height: 100%;
        }
      </style>
      <canvas></canvas>
    `;

    this._canvas = this.shadowRoot.querySelector('canvas');
    this._ctx = this._canvas.getContext('2d');

    // Parse slotted files
    this._parseSlottedFiles();

    // Create buffer from first file
    const filenames = Object.keys(this._fileMap);
    const firstName = filenames[0] || 'untitled';
    const firstContent = this._fileMap[firstName] || '';

    this._buffer = createBuffer(firstName, {
      content: firstContent,
      onSave: (filename, content) => {
        // Update virtual file map on save
        this._fileMap[filename] = content;
        this.dispatchEvent(new CustomEvent('save', {
          detail: { filename, content },
          bubbles: true,
        }));
      },
    });

    // Run language-specific onOpen hook
    const initLang = getLang(firstName);
    if (initLang.lineComment) this._buffer.lineComment = initLang.lineComment;
    if (initLang.onOpen) {
      initLang.onOpen(this._buffer);
    }

    // Create editor
    this._editor = createEditor({ getLang });

    // Measure font and dimensions
    this._measureFont();
    this._updateDimensions();

    // Wire events
    this.setAttribute('tabindex', '0');
    this.addEventListener('keydown', this._boundKeyDown);

    // Focus on click
    this._canvas.addEventListener('mousedown', () => this.focus());

    // Touch events for mobile
    this._canvas.addEventListener('touchstart', this._onTouchStart.bind(this), { passive: false });
    this._canvas.addEventListener('touchmove', this._onTouchMove.bind(this), { passive: false });
    this._canvas.addEventListener('touchend', this._onTouchEnd.bind(this), { passive: false });

    // Resize observer
    this._resizeObserver = new ResizeObserver(() => {
      this._measureFont();
      this._updateDimensions();
      this._render();
    });
    this._resizeObserver.observe(this);

    // Initial render
    this._render();
    this.focus();
  }

  disconnectedCallback() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect();
      this._resizeObserver = null;
    }
    this.removeEventListener('keydown', this._boundKeyDown);
  }

  _parseSlottedFiles() {
    this._fileMap = {};
    const scripts = this.querySelectorAll('script[data-path]');
    for (const script of scripts) {
      const path = script.getAttribute('data-path');
      let content = script.textContent;
      // Trim leading newline (common in inline content)
      if (content.startsWith('\n')) content = content.slice(1);
      // Trim trailing whitespace/newline
      content = content.replace(/\s+$/, '');
      this._fileMap[path] = content;
    }
  }

  _measureFont() {
    // Get computed font from the host element
    const style = getComputedStyle(this);
    const font = style.font || `${style.fontSize || '14px'} ${style.fontFamily || 'monospace'}`;
    this._ctx.font = font;
    this._font = font;

    // Measure character width
    const metrics = this._ctx.measureText('M');
    this._charW = metrics.width;

    // Line height
    const fontSize = parseFloat(style.fontSize) || 14;
    this._lineH = Math.ceil(fontSize * 1.4);
  }

  _updateDimensions() {
    const rect = this.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    this._canvas.width = Math.floor(rect.width * dpr);
    this._canvas.height = Math.floor(rect.height * dpr);
    this._canvas.style.width = rect.width + 'px';
    this._canvas.style.height = rect.height + 'px';

    // Re-set font after canvas resize (clears context state)
    this._ctx.font = this._font;

    this._cols = Math.floor(rect.width / this._charW);
    this._rows = Math.floor(rect.height / this._lineH);
  }

  _onKeyDown(e) {
    // Don't capture if canvas doesn't have focus
    if (this.shadowRoot.activeElement && this.shadowRoot.activeElement !== this._canvas) return;

    const key = mapKeyEvent(e);

    // Prevent Space from scrolling in normal/select mode
    if (key.key === ' ' && (this._editor.state.mode === 'normal' || this._editor.state.mode === 'select')) {
      e.preventDefault();
    }

    // Prevent backspace from navigating back
    if (key.key === 'backspace') {
      e.preventDefault();
    }

    this._editor.handleKey(key, this._buffer);

    // Handle quit
    if (this._editor.state.quit) {
      this.dispatchEvent(new CustomEvent('quit', { bubbles: true }));
      this._editor.state.quit = false;
      this._editor.state.forceQuit = false;
    }

    this._render();
  }

  _onTouchStart(e) {
    e.preventDefault();
    this.focus();
    const touch = e.touches[0];
    const rect = this._canvas.getBoundingClientRect();
    this._touchStartX = touch.clientX - rect.left;
    this._touchStartY = touch.clientY - rect.top;
    this._touchStartTime = Date.now();
    this._touchMoved = false;
    this._touchStartCheatScrollPx = this._editor ? (this._editor.state.cheatScrollPx || 0) : 0;
  }

  _onTouchMove(e) {
    e.preventDefault();
    if (!this._editor) return;
    const touch = e.touches[0];
    const rect = this._canvas.getBoundingClientRect();
    const x = touch.clientX - rect.left;
    const y = touch.clientY - rect.top;
    const dx = x - this._touchStartX;
    const dy = y - this._touchStartY;

    if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
      this._touchMoved = true;
    }

    // Horizontal scroll on cheat bar row (bottom row)
    const cheatBarTop = (this._rows - 1) * this._lineH;
    if (this._touchStartY >= cheatBarTop) {
      this._editor.state.cheatScrollPx = Math.max(0, this._touchStartCheatScrollPx - dx);
      this._render();
    }
  }

  _onTouchEnd(e) {
    e.preventDefault();
    if (!this._editor || !this._buffer) return;

    // If it was a tap (not a swipe)
    if (!this._touchMoved) {
      const x = this._touchStartX;
      const y = this._touchStartY;

      // Hit-test against cheat buttons
      const buttons = this._cheatButtons || [];
      for (const btn of buttons) {
        if (x >= btn.x && x <= btn.x + btn.w && y >= btn.y && y <= btn.y + btn.h) {
          this._editor.handleKey({ key: btn.key, ctrl: btn.ctrl, shift: false }, this._buffer);
          if (this._editor.state.quit) {
            this.dispatchEvent(new CustomEvent('quit', { bubbles: true }));
            this._editor.state.quit = false;
            this._editor.state.forceQuit = false;
          }
          this._render();
          return;
        }
      }
    }

    this._touchStartX = null;
    this._touchStartY = null;
  }

  _render() {
    if (!this._ctx || !this._buffer || !this._editor) return;

    const dpr = window.devicePixelRatio || 1;
    this._ctx.font = this._font;

    this._cheatButtons = renderCanvas(
      this._ctx,
      this._editor.state,
      this._buffer,
      this._cols,
      this._rows,
      this._charW,
      this._lineH,
      dpr
    ) || [];
  }

  // --- Public API ---

  get filename() {
    return this._buffer ? this._buffer.filename : '';
  }

  get content() {
    return this._buffer ? this._buffer.lines.join('\n') + '\n' : '';
  }

  get mode() {
    return this._editor ? this._editor.state.mode : 'normal';
  }

  get files() {
    return { ...this._fileMap };
  }

  openFile(path) {
    if (this._fileMap[path] && this._editor && this._buffer) {
      this._editor.state.mode = 'normal';
      const content = this._fileMap[path];
      this._buffer.filename = path;
      this._buffer.lines = content.split('\n');
      if (this._buffer.lines.length > 1 && this._buffer.lines[this._buffer.lines.length - 1] === '') {
        this._buffer.lines.pop();
      }
      this._buffer.dirty = false;
      this._buffer.folds.clear();
      this._buffer._visibleCache = null;
      this._editor.state.cursor = { line: 0, col: 0 };
      this._editor.state.scroll = 0;
      this._editor.state.undoStack = [];
      this._editor.state.redoStack = [];
      const loadLang = getLang(path);
      this._buffer.lineComment = loadLang.lineComment || null;
      if (loadLang.onOpen) {
        loadLang.onOpen(this._buffer);
      }
      this._render();
    }
  }
}

customElements.define('h-edit', HEdit);
