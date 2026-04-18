'use strict';

const path = require('path');
const { execSync } = require('child_process');
const { createBuffer } = require('./lib/buffer');
const { createEditor } = require('./lib/engine');
const { createEditor: createTerminalEditor } = require('./lib/editor');
const { getLang } = require('./lang');
const { loadTestTree } = require('./lib/mockup');

const tree = loadTestTree(path.join(__dirname, 'help'));

let passed = 0;
let failed = 0;
const failures = [];

function playKeys(handleKey, buf, keys) {
  for (const k of keys) {
    let ctrl = false;
    let shift = false;
    let actualKey = k;
    if (k.startsWith('C-')) {
      ctrl = true;
      actualKey = k.slice(2);
    }
    if (k.startsWith('S-')) {
      shift = true;
      actualKey = k.slice(2);
    }
    if (!shift) shift = actualKey.length === 1 && actualKey >= 'A' && actualKey <= 'Z';
    handleKey({ key: actualKey, ctrl, shift }, buf);
  }
}

function checkFrame(state, buf, frame, relPath, label) {
  if (frame.after) {
    if (JSON.stringify(buf.lines) !== JSON.stringify(frame.after)) {
      return `${label}lines: expected ${JSON.stringify(frame.after)}, got ${JSON.stringify(buf.lines)}`;
    }
  }

  if (frame.cursor) {
    const [line, col] = frame.cursor;
    if (state.cursor.line !== line || state.cursor.col !== col) {
      return `${label}cursor: expected [${line},${col}], got [${state.cursor.line},${state.cursor.col}]`;
    }
  }

  if (frame.mode) {
    if (state.mode !== frame.mode) {
      return `${label}mode: expected "${frame.mode}", got "${state.mode}"`;
    }
  }

  if (frame.commandBuf !== undefined) {
    if (state.commandBuf !== frame.commandBuf) {
      return `${label}commandBuf: expected "${frame.commandBuf}", got "${state.commandBuf}"`;
    }
  }

  if (frame.searchBuf !== undefined) {
    if (state.searchBuf !== frame.searchBuf) {
      return `${label}searchBuf: expected "${frame.searchBuf}", got "${state.searchBuf}"`;
    }
  }

  if (frame.promptCol !== undefined) {
    if (state.promptCol !== frame.promptCol) {
      return `${label}promptCol: expected ${frame.promptCol}, got ${state.promptCol}`;
    }
  }

  if (frame.folds) {
    const expected = [...frame.folds].sort((a, b) => a - b);
    const actual = [...buf.folds].sort((a, b) => a - b);
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
      return `${label}folds: expected [${expected}], got [${actual}]`;
    }
  }

  return null;
}

function runLeaf(node) {
  const { data, filePath } = node;
  const isTreeTest = filePath.includes(path.sep + 'tree' + path.sep);
  const { state, handleKey } = isTreeTest
    ? createTerminalEditor()
    : createEditor({ getLang });
  const buf = createBuffer(null);
  buf.filename = '/tmp/hu-test-dummy.txt';
  buf.lines = data.before.slice();
  if (data.lineComment) buf.lineComment = data.lineComment;
  if (data.beforeFolds) {
    for (const f of data.beforeFolds) buf.folds.add(f);
  }

  const relPath = path.relative(__dirname, filePath);

  if (data.frames) {
    // Story mode: run each frame in sequence
    for (let i = 0; i < data.frames.length; i++) {
      const frame = data.frames[i];
      playKeys(handleKey, buf, frame.keys);
      const label = `frame ${i + 1}${frame.desc ? ' (' + frame.desc + ')' : ''}: `;
      const err = checkFrame(state, buf, frame, relPath, label);
      if (err) {
        failed++;
        failures.push({ path: relPath, error: err });
        return;
      }
    }
  } else {
    // Single-frame mode (backward compatible)
    playKeys(handleKey, buf, data.keys);
    const err = checkFrame(state, buf, data, relPath, '');
    if (err) {
      failed++;
      failures.push({ path: relPath, error: err });
      return;
    }
  }

  passed++;
}

function runTree(nodes) {
  for (const node of nodes) {
    if (node.type === 'group') {
      runTree(node.children);
    } else {
      runLeaf(node);
    }
  }
}

// --- Suite 1: .hu story tests ---
runTree(tree);

console.log(`  help stories: ${passed} passing, ${failed} failing`);
if (failures.length > 0) {
  for (const f of failures) {
    console.log(`  FAIL ${f.path}`);
    console.log(`    ${f.error}\n`);
  }
}

// --- Suite 2+: programmatic test files ---
let suiteFailed = failures.length > 0;
const suites = [
  'test/stale.js',
  'test/terminal/render.js',
];

for (const suite of suites) {
  try {
    const output = execSync(`node ${path.join(__dirname, suite)}`, { encoding: 'utf8' });
    process.stdout.write(output);
  } catch (err) {
    suiteFailed = true;
    if (err.stdout) process.stdout.write(err.stdout);
    if (err.stderr) process.stderr.write(err.stderr);
  }
}

if (suiteFailed) process.exit(1);
