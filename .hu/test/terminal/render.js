'use strict';

const { createBuffer } = require('../../lib/buffer');
const { createEditor } = require('../../lib/editor');
const { render } = require('../../lib/render');

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

function mockStdout(rows, cols) {
  return { rows, columns: cols, output: '', write(s) { this.output += s; } };
}

function stripAnsi(s) {
  return s.replace(/\x1b\[[^m]*m|\x1b\][^\x07]*\x07|\x1b\[\??[^a-zA-Z]*[a-zA-Z]/g, '');
}

function setup(lines, opts) {
  const { state, handleKey } = createEditor();
  const buf = createBuffer(null);
  buf.filename = (opts && opts.filename) || 'test.txt';
  buf.lines = lines.slice();
  if (opts && opts.dirty) buf.dirty = true;
  if (opts && opts.folds) {
    for (const f of opts.folds) buf.folds.add(f);
  }
  return { state, handleKey, buf };
}

function playKeys(handleKey, buf, keys) {
  for (const k of keys) {
    let ctrl = false;
    let shift = false;
    let actualKey = k;
    if (k.startsWith('C-')) { ctrl = true; actualKey = k.slice(2); }
    if (k.startsWith('S-')) { shift = true; actualKey = k.slice(2); }
    if (!shift) shift = actualKey.length === 1 && actualKey >= 'A' && actualKey <= 'Z';
    handleKey({ key: actualKey, ctrl, shift }, buf);
  }
}

// 1. Basic content — buffer lines appear in rendered output
{
  const { state, buf } = setup(['hello world', 'second line', 'third line']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('basic content - line 1', plain.includes('hello world'), 'expected "hello world" in output');
  assert('basic content - line 2', plain.includes('second line'), 'expected "second line" in output');
  assert('basic content - line 3', plain.includes('third line'), 'expected "third line" in output');
}

// 2. Metadata line — filename shown, [+] dirty flag
{
  const { state, buf } = setup(['test']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('metadata - filename', plain.includes('test.txt'), 'expected filename in output');
  assert('metadata - no dirty flag', !plain.includes('[+]'), 'expected no [+] when clean');
}
{
  const { state, buf } = setup(['test'], { dirty: true });
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('metadata - dirty flag', plain.includes('[+]'), 'expected [+] when dirty');
}

// 3. Gutter — line numbers appear
{
  const { state, buf } = setup(['aaa', 'bbb', 'ccc']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('gutter - line 1', plain.includes('1'), 'expected line number 1');
  assert('gutter - line 2', plain.includes('2'), 'expected line number 2');
  assert('gutter - line 3', plain.includes('3'), 'expected line number 3');
}

// 4. Fold indicators — ▸ for folded, ▾ for foldable
{
  const { state, buf } = setup(['parent', '  :: child', '  child2']);
  buf.lineComment = '::';
  // Line 0 is foldable (first child is a comment line) but not folded
  const out1 = mockStdout(24, 80);
  render(state, buf, out1);
  assert('fold indicator - foldable', out1.output.includes('▾'), 'expected ▾ for foldable line');

  // Now fold it
  buf.folds.add(0);
  buf._visibleCache = null;
  const out2 = mockStdout(24, 80);
  render(state, buf, out2);
  assert('fold indicator - folded', out2.output.includes('▸'), 'expected ▸ for folded line');
}

// 5. Fold hiding — folded children don't appear, [N lines] suffix does
{
  const { state, buf } = setup(['parent', '  child1', '  child2', 'sibling']);
  buf.folds.add(0);
  buf._visibleCache = null;
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('fold hiding - children hidden', !plain.includes('child1'), 'expected child1 hidden');
  assert('fold hiding - line count', plain.includes('[2 lines]'), 'expected [2 lines] suffix');
  assert('fold hiding - sibling visible', plain.includes('sibling'), 'expected sibling visible');
}

// 6. Cursor position — cursor escape sequence matches expected row/col
{
  const { state, handleKey, buf } = setup(['hello', 'world', 'test']);
  // Cursor starts at 0,0 — should be at row 2 (metadata is row 1), col 7 (4 gutter + 1 fold + 1 space + 1-based)
  const out = mockStdout(24, 80);
  render(state, buf, out);
  // After render, cursor should be positioned. The cursor.line=0 means row = 0 - scroll + 2
  // With 24 rows, editorRows = 21, half = 10, scroll = 0 - 10 = -10 → clamped behavior
  // cursorScreenRow = 0 - scroll + 2, cursorScreenCol = 0 + 7
  // Let's check the escape has the right col
  assert('cursor position - col 7 at origin', out.output.includes('\x1b[') && out.output.includes(';7H'), 'expected cursor col 7');
}

// 7. Insert mode cursor color — green cursor color escape
{
  const { state, handleKey, buf } = setup(['hello']);
  playKeys(handleKey, buf, ['i']); // enter insert mode
  const out = mockStdout(24, 80);
  render(state, buf, out);
  assert('insert cursor color', out.output.includes('\x1b]12;#00cc00\x07'), 'expected green cursor in insert mode');
}

// 8. Selection background — selection ANSI codes appear
{
  const { state, handleKey, buf } = setup(['line1', 'line2', 'line3']);
  playKeys(handleKey, buf, [' ']); // enter line select mode
  const out = mockStdout(24, 80);
  render(state, buf, out);
  // Selection is line mode, BG_BLUE = \x1b[44m
  assert('selection background', out.output.includes('\x1b[44m'), 'expected BG_BLUE for line selection');
}

// 9. Command prompt — : prefix and command buffer appear on status line
{
  const { state, handleKey, buf } = setup(['hello']);
  playKeys(handleKey, buf, [':']); // enter command mode
  state.commandBuf = 'w';
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('command prompt', plain.includes(':w'), 'expected :w on status line');
}

// 10. Search prompt — / prefix and search buffer appear on status line
{
  const { state, handleKey, buf } = setup(['hello']);
  playKeys(handleKey, buf, ['/']); // enter search mode
  state.searchBuf = 'foo';
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('search prompt', plain.includes('/foo'), 'expected /foo on status line');
}

// 11. Cheat bar — mode label appears
{
  const { state, buf } = setup(['hello']);
  const out1 = mockStdout(24, 80);
  render(state, buf, out1);
  const plain1 = stripAnsi(out1.output);
  assert('cheat bar - normal', plain1.includes('NORMAL'), 'expected NORMAL mode label');
}
{
  const { state, handleKey, buf } = setup(['hello']);
  playKeys(handleKey, buf, ['i']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('cheat bar - insert', plain.includes('INSERT'), 'expected INSERT mode label');
}
{
  const { state, handleKey, buf } = setup(['hello', 'world']);
  playKeys(handleKey, buf, [' ']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('cheat bar - select', plain.includes('SELECT:LINE'), 'expected SELECT:LINE mode label');
}

// 12. Message display — state.message appears on status line
{
  const { state, buf } = setup(['hello']);
  state.message = 'saved test.txt';
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('message display', plain.includes('saved test.txt'), 'expected message on status line');
}

// 13. Search next — multiple matches on the same line
{
  const { state, handleKey, buf } = setup(['aa bb aa cc aa']);
  // Search for 'aa'
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['a', 'a', 'enter']);
  // onDone sets searchQuery and calls searchNext(buffer, 1)
  // Should land on first 'aa' at col 0
  assert('search first match', state.cursor.col === 0, `expected col 0, got ${state.cursor.col}`);
  assert('search first match line', state.cursor.line === 0, `expected line 0, got ${state.cursor.line}`);

  // Press n — should find next 'aa' on same line at col 6
  playKeys(handleKey, buf, ['n']);
  assert('search next same line', state.cursor.col === 6, `expected col 6, got ${state.cursor.col}`);
  assert('search next same line line', state.cursor.line === 0, `expected line 0, got ${state.cursor.line}`);

  // Press n — should find next 'aa' on same line at col 12
  playKeys(handleKey, buf, ['n']);
  assert('search next same line 2', state.cursor.col === 12, `expected col 12, got ${state.cursor.col}`);

  // Press n — should wrap back to col 0
  playKeys(handleKey, buf, ['n']);
  assert('search wrap', state.cursor.col === 0, `expected col 0 (wrap), got ${state.cursor.col}`);
}

// 14. Search next — multiple matches across lines, then same line
{
  const { state, handleKey, buf } = setup(['foo bar foo', 'baz', 'foo qux']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['f', 'o', 'o', 'enter']);
  // First match: line 0 col 0
  assert('multi-line first', state.cursor.line === 0 && state.cursor.col === 0, 'expected 0:0');

  // n — same line col 8
  playKeys(handleKey, buf, ['n']);
  assert('multi-line same line', state.cursor.line === 0 && state.cursor.col === 8,
    `expected 0:8, got ${state.cursor.line}:${state.cursor.col}`);

  // n — next line with match: line 2 col 0
  playKeys(handleKey, buf, ['n']);
  assert('multi-line next line', state.cursor.line === 2 && state.cursor.col === 0,
    `expected 2:0, got ${state.cursor.line}:${state.cursor.col}`);

  // n — wrap to line 0 col 0
  playKeys(handleKey, buf, ['n']);
  assert('multi-line wrap', state.cursor.line === 0 && state.cursor.col === 0,
    `expected 0:0, got ${state.cursor.line}:${state.cursor.col}`);
}

// 15. Search prev (N) — backward through same-line matches
{
  const { state, handleKey, buf } = setup(['aa bb aa cc aa']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['a', 'a', 'enter']);
  // At col 0. Press N — should wrap backward to last match at col 12
  playKeys(handleKey, buf, ['N']);
  assert('search prev wrap', state.cursor.col === 12, `expected col 12, got ${state.cursor.col}`);

  // Press N — should go to col 6
  playKeys(handleKey, buf, ['N']);
  assert('search prev same line', state.cursor.col === 6, `expected col 6, got ${state.cursor.col}`);

  // Press N — should go to col 0
  playKeys(handleKey, buf, ['N']);
  assert('search prev same line 2', state.cursor.col === 0, `expected col 0, got ${state.cursor.col}`);
}

// 16. Search persists on status line after search completes
{
  const { state, handleKey, buf } = setup(['hello world']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['w', 'o', 'r', 'l', 'd', 'enter']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  const plain = stripAnsi(out.output);
  assert('search persists status', plain.includes('/world'), 'expected /world on status line after search');
}

// 17. Search highlighting — matches appear in render output with yellow bg
{
  const { state, handleKey, buf } = setup(['hello world hello']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['h', 'e', 'l', 'l', 'o', 'enter']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  // Yellow bg escape sequence should appear in output for matches
  assert('search highlight', out.output.includes('\x1b[43m'), 'expected yellow bg for search matches');
}

// 18. Search into folded region — unfolds and jumps to match
{
  const { state, handleKey, buf } = setup([
    'top',
    '  hidden target',
    '  another line',
    'bottom',
  ]);
  // Line 0 is foldable (next non-blank line has greater indent)
  buf.folds.add(0);
  buf.invalidateCache();
  // Verify lines 1-2 are hidden
  const visBefore = buf.visibleLines();
  assert('fold hides lines', visBefore.length === 2, `expected 2 visible, got ${visBefore.length}`);

  // Search for text only present in folded region
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['t', 'a', 'r', 'g', 'e', 't', 'enter']);

  // Should have unfolded and jumped to line 1
  const visAfter = buf.visibleLines();
  assert('fold unfolds on search', visAfter.length === 4, `expected 4 visible after unfold, got ${visAfter.length}`);
  assert('search finds folded line', visAfter[state.cursor.line].lineNum === 1,
    `expected actual line 1, got ${visAfter[state.cursor.line].lineNum}`);
  assert('search folded col', state.cursor.col === 9, `expected col 9, got ${state.cursor.col}`);
}

// 19. Search skips folded region when match exists in visible lines
{
  const { state, handleKey, buf } = setup([
    'aaa',
    '  hidden aaa',
    '  more hidden',
    'bbb aaa',
  ]);
  buf.folds.add(0);
  buf.invalidateCache();
  // Visible: line 0 ("aaa") and line 3 ("bbb aaa")
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['a', 'a', 'a', 'enter']);
  // Should find "aaa" on line 0 first (cursor starts there)
  const vis = buf.visibleLines();
  assert('visible match first', vis[state.cursor.line].lineNum === 0, `expected line 0, got ${vis[state.cursor.line].lineNum}`);

  // Press n — should go to line 3 (next visible match), NOT unfold line 1
  playKeys(handleKey, buf, ['n']);
  // Line 1 has "aaa" but searching all lines means it could find line 1 first.
  // Actually with the fix, search goes through ALL lines including folded.
  // From line 0, next line with "aaa" is line 1 (folded). It should unfold and go there.
  const vis2 = buf.visibleLines();
  const foundLine = vis2[state.cursor.line].lineNum;
  assert('next search finds folded', foundLine === 1, `expected line 1 (folded match), got ${foundLine}`);
}

// 20. Search backward into folded region
{
  const { state, handleKey, buf } = setup([
    'bottom',
    'mid',
    '  hidden goal',
    '  also hidden',
    'top',
  ]);
  buf.folds.add(1);
  buf.invalidateCache();
  // Move cursor to last visible line
  state.cursor.line = buf.visibleLines().length - 1; // "top"

  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['g', 'o', 'a', 'l', 'enter']);
  // Should unfold and find "goal" on line 2
  const vis = buf.visibleLines();
  assert('backward fold search', vis[state.cursor.line].lineNum === 2,
    `expected line 2, got ${vis[state.cursor.line].lineNum}`);
}

// 21. Smart case — lowercase query matches case-insensitively
{
  const { state, handleKey, buf } = setup(['Hello World', 'hello again', 'HELLO CAPS']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['h', 'e', 'l', 'l', 'o', 'enter']);
  // Lowercase query "hello" should match "Hello" on line 0
  const vis = buf.visibleLines();
  assert('smart case insensitive', vis[state.cursor.line].lineNum === 0,
    `expected line 0, got ${vis[state.cursor.line].lineNum}`);

  // n should find "hello" on line 1
  playKeys(handleKey, buf, ['n']);
  assert('smart case next', vis[state.cursor.line].lineNum === 1,
    `expected line 1, got ${vis[state.cursor.line].lineNum}`);

  // n should find "HELLO" on line 2
  playKeys(handleKey, buf, ['n']);
  assert('smart case caps', vis[state.cursor.line].lineNum === 2,
    `expected line 2, got ${vis[state.cursor.line].lineNum}`);
}

// 22. Smart case — uppercase in query forces case-sensitive
{
  const { state, handleKey, buf } = setup(['Hello World', 'hello again', 'HELLO CAPS']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['H', 'e', 'l', 'l', 'o', 'enter']);
  // "Hello" (with capital H) should only match line 0
  const vis = buf.visibleLines();
  assert('smart case sensitive match', vis[state.cursor.line].lineNum === 0,
    `expected line 0, got ${vis[state.cursor.line].lineNum}`);

  // n should skip line 1 ("hello") and wrap back to line 0
  playKeys(handleKey, buf, ['n']);
  assert('smart case sensitive skip', vis[state.cursor.line].lineNum === 0,
    `expected line 0 (wrap), got ${vis[state.cursor.line].lineNum}`);
}

// 23. Smart case — highlight rendering matches case-insensitively
{
  const { state, handleKey, buf } = setup(['Hello world']);
  playKeys(handleKey, buf, ['/']);
  playKeys(handleKey, buf, ['h', 'e', 'l', 'l', 'o', 'enter']);
  const out = mockStdout(24, 80);
  render(state, buf, out);
  // Yellow bg should appear (case-insensitive match of "hello" against "Hello")
  assert('smart case highlight', out.output.includes('\x1b[43m'), 'expected yellow bg for case-insensitive match');
}

console.log(`\n  terminal render: ${passed} passing, ${failed} failing\n`);
if (failures.length > 0) {
  for (const f of failures) {
    console.log(`  FAIL ${f}\n`);
  }
  process.exit(1);
}
