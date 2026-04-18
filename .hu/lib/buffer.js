'use strict';
// Visible index vs actual line number:
// buffer.lines[] is indexed by actual line number. When folds are active,
// visibleLines() returns a filtered array [{lineNum, text}] where lineNum
// is the actual line number. The editor cursor (state.cursor.line) is a
// visible index into this filtered array. Use actualLineNum() to convert
// visible index → actual line number, and findVisibleIndex() for the reverse.

function parseFileContent(content) {
  const lines = content.split('\n');
  if (lines.length > 1 && lines[lines.length - 1] === '') {
    lines.pop();
  }
  return lines;
}

function createBuffer(filename, opts) {
  opts = opts || {};
  const _fs = opts.fs || null;
  const _onSave = opts.onSave || null;

  const buf = {
    lines: [''],
    folds: new Set(),
    filename: filename || '',
    lineComment: null,
    dirty: false,
    stale: false,
    lastMtime: 0,
    _visibleCache: null,

    invalidateCache() {
      buf._visibleCache = null;
    },

    // Shift fold line numbers when lines are inserted or removed.
    // at: line number where the change occurs
    // delta: positive = lines inserted, negative = lines removed
    // removedStart/removedEnd: range of lines being removed (folds in this range are dropped)
    _shiftFolds(at, delta, removedStart, removedEnd) {
      const updated = new Set();
      for (const ln of buf.folds) {
        if (removedStart !== undefined && ln >= removedStart && ln <= removedEnd) continue;
        if (ln >= at) {
          updated.add(ln + delta);
        } else {
          updated.add(ln);
        }
      }
      buf.folds = updated;
    },

    lineCount() {
      return buf.lines.length;
    },

    indentLevel(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return 0;
      const line = buf.lines[lineNum];
      const m = line.match(/^( *)/);
      return m ? m[1].length : 0;
    },

    isBlank(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return true;
      return buf.lines[lineNum].trim().length === 0;
    },

    foldable(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length - 1) return false;
      if (buf.isBlank(lineNum)) return false;
      const baseIndent = buf.indentLevel(lineNum);
      for (let i = lineNum + 1; i < buf.lines.length; i++) {
        if (!buf.isBlank(i)) {
          return buf.indentLevel(i) > baseIndent;
        }
      }
      return false;
    },

    foldRange(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length - 1) return null;
      if (buf.isBlank(lineNum)) return null;
      const baseIndent = buf.indentLevel(lineNum);
      const start = lineNum + 1;
      let end = start;
      while (end < buf.lines.length) {
        if (!buf.isBlank(end) && buf.indentLevel(end) <= baseIndent) break;
        end++;
      }
      if (end === start) return null;
      return [start, end - 1];
    },

    visibleLines() {
      if (buf._visibleCache) return buf._visibleCache;
      const result = [];
      let i = 0;
      while (i < buf.lines.length) {
        result.push({ lineNum: i, text: buf.lines[i] });
        if (buf.folds.has(i)) {
          const range = buf.foldRange(i);
          if (range) {
            i = range[1] + 1;
            continue;
          }
        }
        i++;
      }
      buf._visibleCache = result;
      return result;
    },

    foldedLineCount(lineNum) {
      const range = buf.foldRange(lineNum);
      if (!range) return 0;
      return range[1] - range[0] + 1;
    },

    toggleFold(lineNum) {
      if (buf.folds.has(lineNum)) {
        buf.folds.delete(lineNum);
      } else if (buf.foldable(lineNum)) {
        buf.folds.add(lineNum);
      }
      buf.invalidateCache();
    },

    indentBlock(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return null;
      if (buf.isBlank(lineNum)) return null;
      const indent = buf.indentLevel(lineNum);
      let start = lineNum;
      while (start > 0) {
        if (buf.isBlank(start - 1)) { start--; continue; }
        if (buf.indentLevel(start - 1) >= indent) { start--; } else { break; }
      }
      let end = lineNum;
      while (end < buf.lines.length - 1) {
        if (buf.isBlank(end + 1)) { end++; continue; }
        if (buf.indentLevel(end + 1) >= indent) { end++; } else { break; }
      }
      return [start, end];
    },

    section(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return null;
      if (!buf.isBlank(lineNum) && buf.foldable(lineNum)) {
        const range = buf.foldRange(lineNum);
        return range ? [lineNum, range[1]] : null;
      }
      for (let i = lineNum - 1; i >= 0; i--) {
        if (buf.isBlank(i)) continue;
        if (buf.indentLevel(i) < buf.indentLevel(lineNum)) {
          if (buf.foldable(i)) {
            const range = buf.foldRange(i);
            if (range && lineNum <= range[1]) return [i, range[1]];
          }
          return null;
        }
      }
      return null;
    },

    parentSection(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return null;
      const sec = buf.section(lineNum);
      const header = sec ? sec[0] : lineNum;
      for (let i = header - 1; i >= 0; i--) {
        if (buf.isBlank(i)) continue;
        if (buf.indentLevel(i) < buf.indentLevel(header)) {
          if (buf.foldable(i)) {
            const range = buf.foldRange(i);
            if (range && header <= range[1]) return [i, range[1]];
          }
          return null;
        }
      }
      return null;
    },

    nextSibling(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return null;
      const indent = buf.indentLevel(lineNum);
      for (let i = lineNum + 1; i < buf.lines.length; i++) {
        if (buf.isBlank(i)) continue;
        if (buf.indentLevel(i) === indent) return i;
      }
      return null;
    },

    prevSibling(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return null;
      const indent = buf.indentLevel(lineNum);
      for (let i = lineNum - 1; i >= 0; i--) {
        if (buf.isBlank(i)) continue;
        if (buf.indentLevel(i) === indent) return i;
      }
      return null;
    },

    foldAllAtIndent(indent) {
      let count = 0;
      for (let i = 0; i < buf.lines.length; i++) {
        if (buf.indentLevel(i) === indent && buf.foldable(i)) {
          buf.folds.add(i);
          count++;
        }
      }
      buf.invalidateCache();
      return count;
    },

    autoFold(lineComment) {
      if (!lineComment) return;
      buf.lineComment = lineComment;
      for (let i = 0; i < buf.lines.length; i++) {
        if (!buf.foldable(i)) continue;
        // Only auto-fold arms whose first child is a comment
        const baseIndent = buf.indentLevel(i);
        for (let j = i + 1; j < buf.lines.length; j++) {
          if (!buf.isBlank(j)) {
            if (buf.indentLevel(j) === baseIndent + 2) {
              const trimmed = buf.lines[j].trim();
              if (trimmed === lineComment || trimmed.startsWith(lineComment + ' ')) {
                buf.folds.add(i);
              }
            }
            break;
          }
        }
      }
      buf.invalidateCache();
    },

    unfoldAll() {
      buf.folds.clear();
      buf.invalidateCache();
    },

    save() {
      if (!buf.filename) return false;
      if (_onSave) {
        _onSave(buf.filename, buf.lines.join('\n') + '\n');
      } else if (_fs) {
        _fs.writeFileSync(buf.filename, buf.lines.join('\n') + '\n');
        // stat may fail if file was just written to a network mount; non-critical
        try { buf.lastMtime = _fs.statSync(buf.filename).mtimeMs; } catch (e) {}
      }
      buf.dirty = false;
      buf.stale = false;
      return true;
    },

    checkStale() {
      if (!_fs || !buf.filename) return false;
      try {
        const mtime = _fs.statSync(buf.filename).mtimeMs;
        if (mtime > buf.lastMtime) {
          buf.stale = true;
          return true;
        }
      } catch (e) { /* file may have been deleted or be inaccessible; not stale */ }
      return false;
    },

    reload() {
      if (!_fs || !buf.filename) return;
      try {
        const content = _fs.readFileSync(buf.filename, 'utf8');
        buf.lines = parseFileContent(content);
        buf.lastMtime = _fs.statSync(buf.filename).mtimeMs;
        buf.dirty = false;
        buf.stale = false;
        buf.invalidateCache();
      } catch (e) { /* file may be gone; keep current buffer contents */ }
    },

    insertLine(lineNum, text) {
      buf.lines.splice(lineNum, 0, text);
      buf._shiftFolds(lineNum, 1);
      buf.dirty = true;
      buf.invalidateCache();
    },

    deleteLine(lineNum) {
      if (buf.lines.length <= 1) {
        const removed = buf.lines[0];
        buf.lines[0] = '';
        buf.folds.clear();
        buf.dirty = true;
        buf.invalidateCache();
        return removed;
      }
      const removed = buf.lines.splice(lineNum, 1)[0];
      buf._shiftFolds(lineNum, -1, lineNum, lineNum);
      buf.dirty = true;
      buf.invalidateCache();
      return removed;
    },

    deleteLines(start, end) {
      const count = end - start + 1;
      const removed = buf.lines.splice(start, count);
      if (buf.lines.length === 0) buf.lines.push('');
      buf._shiftFolds(start, -count, start, end);
      buf.dirty = true;
      buf.invalidateCache();
      return removed;
    },

    deleteRange(startLine, startCol, endLine, endCol) {
      if (startLine === endLine) {
        const line = buf.lines[startLine];
        const removed = line.slice(startCol, endCol + 1);
        buf.lines[startLine] = line.slice(0, startCol) + line.slice(endCol + 1);
        buf.dirty = true;
      buf.invalidateCache();
        return removed;
      }
      const prefix = buf.lines[startLine].slice(0, startCol);
      const suffix = buf.lines[endLine].slice(endCol + 1);
      const removedParts = [buf.lines[startLine].slice(startCol)];
      for (let i = startLine + 1; i < endLine; i++) {
        removedParts.push(buf.lines[i]);
      }
      removedParts.push(buf.lines[endLine].slice(0, endCol + 1));
      buf.lines[startLine] = prefix + suffix;
      const removedCount = endLine - startLine;
      buf.lines.splice(startLine + 1, removedCount);
      if (buf.lines.length === 0) buf.lines.push('');
      buf._shiftFolds(startLine + 1, -removedCount, startLine + 1, endLine);
      buf.dirty = true;
      buf.invalidateCache();
      return removedParts.join('\n');
    },

    insertChar(lineNum, col, ch) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return;
      const line = buf.lines[lineNum];
      buf.lines[lineNum] = line.slice(0, col) + ch + line.slice(col);
      buf.dirty = true;
      buf.invalidateCache();
    },

    deleteChar(lineNum, col) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return;
      const line = buf.lines[lineNum];
      if (col < 0 || col >= line.length) return;
      buf.lines[lineNum] = line.slice(0, col) + line.slice(col + 1);
      buf.dirty = true;
      buf.invalidateCache();
    },

    splitLine(lineNum, col) {
      if (lineNum < 0 || lineNum >= buf.lines.length) return;
      const line = buf.lines[lineNum];
      buf.lines[lineNum] = line.slice(0, col);
      buf.lines.splice(lineNum + 1, 0, line.slice(col));
      buf._shiftFolds(lineNum + 1, 1);
      buf.dirty = true;
      buf.invalidateCache();
    },

    joinLines(lineNum) {
      if (lineNum < 0 || lineNum >= buf.lines.length - 1) return;
      buf.lines[lineNum] += buf.lines[lineNum + 1];
      buf.lines.splice(lineNum + 1, 1);
      buf._shiftFolds(lineNum + 1, -1, lineNum + 1, lineNum + 1);
      buf.dirty = true;
      buf.invalidateCache();
    },
  };

  if (opts.content != null) {
    buf.lines = parseFileContent(opts.content);
  } else if (_fs && filename) {
    try {
      const content = _fs.readFileSync(filename, 'utf8');
      buf.lines = parseFileContent(content);
      buf.lastMtime = _fs.statSync(filename).mtimeMs;
    } catch (e) {
      if (e.code !== 'ENOENT') throw e;
    }
  }

  return buf;
}

module.exports = { createBuffer, parseFileContent };
