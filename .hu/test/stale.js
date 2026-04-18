'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const { createBuffer } = require('../lib/buffer');

let passed = 0;
let failed = 0;
const failures = [];

function assert(name, condition, msg) {
  if (condition) {
    passed++;
  } else {
    failed++;
    failures.push(`${name}: ${msg}`);
  }
}

function tmpFile(content) {
  const p = path.join(os.tmpdir(), `hu-test-${Date.now()}-${Math.random().toString(36).slice(2)}.txt`);
  fs.writeFileSync(p, content);
  return p;
}

// Test: lastMtime is set on initial load
const f1 = tmpFile('hello\nworld\n');
const buf1 = createBuffer(f1, { fs });
assert('lastMtime set on load', buf1.lastMtime > 0, `expected >0, got ${buf1.lastMtime}`);
fs.unlinkSync(f1);

// Test: checkStale returns false when file is unchanged
const f2 = tmpFile('aaa\nbbb\n');
const buf2 = createBuffer(f2, { fs });
assert('checkStale false when unchanged', buf2.checkStale() === false, 'expected false');
assert('stale flag false when unchanged', buf2.stale === false, 'expected false');
fs.unlinkSync(f2);

// Test: checkStale returns true after external modification
const f3 = tmpFile('line1\nline2\n');
const buf3 = createBuffer(f3, { fs });
// Touch the file with a slight delay to ensure mtime changes
const origMtime = buf3.lastMtime;
// Force a different mtime by rewriting
const now = Date.now();
while (Date.now() - now < 50) {} // busy-wait to ensure mtime differs
fs.writeFileSync(f3, 'modified\n');
assert('checkStale true after external edit', buf3.checkStale() === true, 'expected true');
assert('stale flag set after checkStale', buf3.stale === true, 'expected true');
fs.unlinkSync(f3);

// Test: reload updates lines and clears stale/dirty
const f4 = tmpFile('original\n');
const buf4 = createBuffer(f4, { fs });
buf4.dirty = true;
buf4.stale = true;
const waitStart = Date.now();
while (Date.now() - waitStart < 50) {}
fs.writeFileSync(f4, 'reloaded content\n');
buf4.reload();
assert('reload updates lines', buf4.lines[0] === 'reloaded content', `got "${buf4.lines[0]}"`);
assert('reload clears dirty', buf4.dirty === false, 'expected false');
assert('reload clears stale', buf4.stale === false, 'expected false');
assert('reload updates lastMtime', buf4.lastMtime >= fs.statSync(f4).mtimeMs, 'mtime not updated');
fs.unlinkSync(f4);

// Test: save clears stale and updates lastMtime
const f5 = tmpFile('save test\n');
const buf5 = createBuffer(f5, { fs });
buf5.stale = true;
buf5.dirty = true;
buf5.save();
assert('save clears stale', buf5.stale === false, 'expected false');
assert('save clears dirty', buf5.dirty === false, 'expected false');
assert('save updates lastMtime', buf5.lastMtime > 0, 'expected >0');
// Verify file not stale after save
assert('checkStale false after save', buf5.checkStale() === false, 'expected false');
fs.unlinkSync(f5);

// Test: checkStale on nonexistent file returns false
const buf6 = createBuffer(null);
assert('checkStale no file', buf6.checkStale() === false, 'expected false');

// Test: reload on nonexistent file is safe
const buf7 = createBuffer(null);
buf7.reload(); // should not throw
assert('reload no file safe', true, '');

console.log(`\n  stale detection: ${passed} passing, ${failed} failing\n`);
if (failures.length > 0) {
  for (const f of failures) {
    console.log(`  FAIL ${f}\n`);
  }
  process.exit(1);
}
