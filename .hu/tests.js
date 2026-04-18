#!/usr/bin/env node
'use strict';

const path = require('path');
const { parseKey } = require('./lib/input');
const { loadTestTree, renderLeafView } = require('./lib/mockup');

const ESC = '\x1b[';
const RESET = `${ESC}0m`;
const DIM = `${ESC}2m`;
const BOLD = `${ESC}1m`;
const CYAN = `${ESC}36m`;
const YELLOW = `${ESC}33m`;
const GRAY = `${ESC}90m`;
const REVERSE = `${ESC}7m`;
const BG_LIGHT = `${ESC}48;5;252m`;
const FG_BLACK = `${ESC}38;5;16m`;
const FG_MGRAY = `${ESC}38;5;59m`;

const tree = loadTestTree(path.join(__dirname, 'help'));

const state = {
  path: [],       // stack of indices into group children
  cursor: 0,
  scroll: 0,
  viewing: null,  // { data, lines, margin } when viewing a leaf
  leafScroll: 0,
};

function currentList() {
  let nodes = tree;
  for (const idx of state.path) {
    nodes = nodes[idx].children;
  }
  return nodes;
}

function breadcrumb() {
  const parts = ['tests'];
  let nodes = tree;
  for (const idx of state.path) {
    parts.push(nodes[idx].name);
    nodes = nodes[idx].children;
  }
  return parts.join(' > ');
}

function clampList() {
  const list = currentList();
  if (state.cursor >= list.length) state.cursor = Math.max(0, list.length - 1);
  if (state.cursor < 0) state.cursor = 0;
}

function clampScroll(areaHeight) {
  if (state.cursor < state.scroll) state.scroll = state.cursor;
  if (state.cursor >= state.scroll + areaHeight) state.scroll = state.cursor - areaHeight + 1;
  if (state.scroll < 0) state.scroll = 0;
}

function handleKey(key) {
  if (key.key === 'q' || (key.ctrl && key.key === 'c')) {
    cleanup();
    process.exit(0);
  }

  if (state.viewing) {
    // Leaf view
    switch (key.key) {
      case 'j': case 'down':
        state.leafScroll++;
        break;
      case 'k': case 'up':
        if (state.leafScroll > 0) state.leafScroll--;
        break;
      case 'J':
        state.leafScroll += 10;
        break;
      case 'K':
        state.leafScroll = Math.max(0, state.leafScroll - 10);
        break;
      case 'g':
        state.leafScroll = 0;
        break;
      case 'G':
        // clamped during render
        state.leafScroll = Infinity;
        break;
      case 'h': case 'escape':
        state.viewing = null;
        state.leafScroll = 0;
        break;
      case 'l': case 'enter': {
        // Advance to next leaf
        const list = currentList();
        for (let i = state.cursor + 1; i < list.length; i++) {
          if (list[i].type === 'leaf') {
            state.cursor = i;
            const { lines, margin } = renderLeafView(list[i].data, (stdout.columns || 80));
            state.viewing = { data: list[i].data, lines, margin, name: list[i].name };
            state.leafScroll = 0;
            return;
          }
        }
        break;
      }
    }
  } else {
    // List view
    const list = currentList();
    switch (key.key) {
      case 'j': case 'down':
        if (state.cursor < list.length - 1) state.cursor++;
        break;
      case 'k': case 'up':
        if (state.cursor > 0) state.cursor--;
        break;
      case 'g':
        state.cursor = 0;
        break;
      case 'G':
        state.cursor = list.length - 1;
        break;
      case 'l': case 'enter': {
        const item = list[state.cursor];
        if (!item) break;
        if (item.type === 'group') {
          state.path.push(state.cursor);
          state.cursor = 0;
          state.scroll = 0;
        } else {
          const cols = stdout.columns || 80;
          const { lines, margin } = renderLeafView(item.data, cols);
          state.viewing = { data: item.data, lines, margin, name: item.name };
          state.leafScroll = 0;
        }
        break;
      }
      case 'h': case 'escape':
        if (state.path.length > 0) {
          state.cursor = state.path.pop();
          state.scroll = 0;
        }
        break;
    }
  }
}

function render() {
  const rows = stdout.rows || 24;
  const cols = stdout.columns || 80;
  const areaHeight = rows - 2; // row 1 = breadcrumb, last row = hints

  let output = `${ESC}?25l${ESC}H`;

  // Clear all rows
  for (let r = 1; r <= rows; r++) {
    output += `${ESC}${r};1H${ESC}2K`;
  }

  // Breadcrumb (row 1)
  const crumb = breadcrumb();
  if (state.viewing) {
    output += `${ESC}1;1H ${DIM}${crumb} > ${RESET}${BOLD}${state.viewing.name}${RESET}`;
  } else {
    output += `${ESC}1;1H ${DIM}${crumb}${RESET}`;
  }

  if (state.viewing) {
    // Leaf view: render mockup lines
    const { lines, margin } = state.viewing;
    const maxScroll = Math.max(0, lines.length - areaHeight);
    if (state.leafScroll > maxScroll) state.leafScroll = maxScroll;

    for (let r = 0; r < areaHeight; r++) {
      const li = r + state.leafScroll;
      if (li >= lines.length) break;
      output += `${ESC}${r + 2};${margin}H${lines[li]}`;
    }

    // Scroll indicator
    if (lines.length > areaHeight) {
      const pct = maxScroll > 0 ? Math.round((state.leafScroll / maxScroll) * 100) : 0;
      output += `${ESC}1;${cols - 5}H${DIM}${pct}%${RESET}`;
    }

    // Hints
    output += `${ESC}${rows};1H`;
    output += `${BG_LIGHT}${FG_BLACK} ${FG_MGRAY}h${FG_BLACK}:back ${FG_MGRAY}j/k${FG_BLACK}:scroll ${FG_MGRAY}l${FG_BLACK}:next ${FG_MGRAY}q${FG_BLACK}:quit${' '.repeat(Math.max(0, cols - 36))}${RESET}`;
  } else {
    // List view
    const list = currentList();
    clampList();
    clampScroll(areaHeight);

    for (let r = 0; r < areaHeight; r++) {
      const idx = state.scroll + r;
      if (idx >= list.length) break;
      const item = list[idx];
      const selected = idx === state.cursor;
      const prefix = item.type === 'group' ? `${CYAN}▸${RESET} ` : `${DIM}·${RESET} `;
      const name = item.name;

      output += `${ESC}${r + 2};1H`;
      if (selected) {
        output += ` ${REVERSE} ${prefix}${name} ${RESET}`;
      } else {
        output += `  ${prefix}${name}`;
      }
    }

    // Count
    const total = list.length;
    output += `${ESC}1;${cols - 10}H${DIM}${state.cursor + 1}/${total}${RESET}`;

    // Hints
    output += `${ESC}${rows};1H`;
    output += `${BG_LIGHT}${FG_BLACK} ${FG_MGRAY}j/k${FG_BLACK}:nav ${FG_MGRAY}l${FG_BLACK}:open ${FG_MGRAY}h${FG_BLACK}:back ${FG_MGRAY}q${FG_BLACK}:quit${' '.repeat(Math.max(0, cols - 34))}${RESET}`;
  }

  output += `${ESC}?25l`;
  stdout.write(output);
}

// --- Terminal setup ---

const stdin = process.stdin;
const stdout = process.stdout;
stdin.setRawMode(true);
stdin.resume();
stdin.setEncoding(null);

stdout.write('\x1b[2J\x1b[H');
render();

stdin.on('data', (data) => {
  const keys = parseKey(Buffer.from(data));
  for (const key of keys) {
    handleKey(key);
  }
  render();
});

stdout.on('resize', () => {
  // Invalidate cached leaf render on resize
  if (state.viewing) {
    const cols = stdout.columns || 80;
    const { lines, margin } = renderLeafView(state.viewing.data, cols);
    state.viewing.lines = lines;
    state.viewing.margin = margin;
  }
  render();
});

function cleanup() {
  stdout.write('\x1b[?25h');
  stdout.write('\x1b[2J\x1b[H');
  stdin.setRawMode(false);
  stdin.pause();
}

process.on('SIGINT', () => { cleanup(); process.exit(0); });
process.on('SIGTERM', () => { cleanup(); process.exit(0); });
process.on('exit', () => { stdout.write('\x1b[?25h'); });
