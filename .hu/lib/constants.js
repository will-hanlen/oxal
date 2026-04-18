'use strict';

// Editor gutter: 4 digits + 1 fold indicator + 1 space
const GUTTER_TOTAL = 6;
// Cursor column offset: gutter + 1-based indexing
const CURSOR_COL_OFFSET = 7;
// Horizontal scroll padding
const H_SCROLL_PAD = 35;

// Indentation
const INDENT = '  ';
const INDENT_SIZE = 2;

// Cheat bar scroll step (pixels per arrow key press)
const CHEAT_SCROLL_STEP = 80;

// Yank panel
const YANK_PANEL_MAX_WIDTH = 50;
const YANK_PANEL_RESERVED_ROWS = 3;

// Undo stack cap
const MAX_UNDO = 100;

module.exports = {
  GUTTER_TOTAL, CURSOR_COL_OFFSET, H_SCROLL_PAD,
  INDENT, INDENT_SIZE,
  CHEAT_SCROLL_STEP,
  YANK_PANEL_MAX_WIDTH, YANK_PANEL_RESERVED_ROWS,
  MAX_UNDO,
};
