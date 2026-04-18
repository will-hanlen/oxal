'use strict';

// Parse raw stdin bytes into key objects.
// Returns an array of key events (usually one, but paste can produce many).

const ARROW_KEYS = { A: 'up', B: 'down', C: 'right', D: 'left', H: 'home', F: 'end' };

function mapArrowKey(c) {
  return ARROW_KEYS[c] || null;
}

function parseKey(buf) {
  const s = buf.toString('utf8');
  const keys = [];
  let i = 0;

  while (i < s.length) {
    // ESC sequence
    if (s[i] === '\x1b') {
      // Lone ESC (no more chars or next char isn't '[' / 'O')
      if (i + 1 >= s.length) {
        keys.push({ key: 'escape', ctrl: false, shift: false });
        i++;
        continue;
      }
      if (s[i + 1] === '[') {
        // CSI sequences
        const rest = s.slice(i + 2);
        let m;
        // SGR mouse: \x1b[<btn;col;row M/m
        if ((m = rest.match(/^<(\d+);(\d+);(\d+)([Mm])/))) {
          const btn = parseInt(m[1], 10);
          const col = parseInt(m[2], 10);
          const row = parseInt(m[3], 10);
          const release = m[4] === 'm';
          i += 2 + m[0].length;
          // Only handle button press (not release, not drag, not scroll)
          if (!release && btn === 0) {
            keys.push({ key: 'mouse', ctrl: false, shift: false, col, row });
          }
          continue;
        }
        if ((m = rest.match(/^(\d+)~/))) {
          const code = parseInt(m[1], 10);
          i += 2 + m[0].length;
          switch (code) {
            case 3: keys.push({ key: 'delete', ctrl: false, shift: false }); break;
            case 5: keys.push({ key: 'pageup', ctrl: false, shift: false }); break;
            case 6: keys.push({ key: 'pagedown', ctrl: false, shift: false }); break;
            case 1: case 7: keys.push({ key: 'home', ctrl: false, shift: false }); break;
            case 4: case 8: keys.push({ key: 'end', ctrl: false, shift: false }); break;
            default: keys.push({ key: 'unknown', ctrl: false, shift: false }); break;
          }
          continue;
        }
        if (rest.length > 0) {
          const c = rest[0];
          i += 3;
          const arrow = mapArrowKey(c);
          if (arrow) {
            keys.push({ key: arrow, ctrl: false, shift: false });
          } else if (c === 'Z') {
            keys.push({ key: 'tab', ctrl: false, shift: true });
          } else {
            keys.push({ key: 'unknown', ctrl: false, shift: false });
          }
          continue;
        }
        keys.push({ key: 'escape', ctrl: false, shift: false });
        i++;
        continue;
      }
      if (s[i + 1] === 'O') {
        if (i + 2 < s.length) {
          const c = s[i + 2];
          i += 3;
          const arrow = mapArrowKey(c);
          keys.push({ key: arrow || 'unknown', ctrl: false, shift: false });
          continue;
        }
      }
      // Alt+key — treat as escape
      keys.push({ key: 'escape', ctrl: false, shift: false });
      i++;
      continue;
    }

    // Ctrl+letter (0x01-0x1a except special ones)
    const code = s.charCodeAt(i);
    if (code === 0x0d || code === 0x0a) {
      keys.push({ key: 'enter', ctrl: false, shift: false });
      i++;
      continue;
    }
    if (code === 0x09) {
      keys.push({ key: 'tab', ctrl: false, shift: false });
      i++;
      continue;
    }
    if (code === 0x7f || code === 0x08) {
      keys.push({ key: 'backspace', ctrl: false, shift: false });
      i++;
      continue;
    }
    if (code >= 0x01 && code <= 0x1a) {
      keys.push({ key: String.fromCharCode(code + 0x60), ctrl: true, shift: false });
      i++;
      continue;
    }

    // Regular character
    const ch = s[i];
    const isUpper = ch >= 'A' && ch <= 'Z';
    keys.push({ key: ch, ctrl: false, shift: isUpper });
    i++;
  }

  return keys;
}

module.exports = { parseKey };
