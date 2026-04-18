'use strict';

const fs = require('fs');
const path = require('path');

const configs = [];
const extMap = new Map();

// Load all *.js files in this directory (except index.js)
const dir = __dirname;
for (const file of fs.readdirSync(dir)) {
  if (file === 'index.js' || !file.endsWith('.js')) continue;
  const cfg = require(path.join(dir, file));
  if (cfg.lineComment && !cfg.onOpen) {
    const lc = cfg.lineComment;
    cfg.onOpen = (buffer) => { buffer.autoFold(lc); };
  }
  configs.push(cfg);
  for (const ext of cfg.extensions) {
    extMap.set(ext, cfg);
  }
}

const DEFAULT = {
  type: 'editable',
  name: 'default',
  lineComment: null,
  selectionUnits: ['line', 'section', 'indent', 'parent'],
  onOpen: null,
};

function getLang(filename) {
  if (!filename) return DEFAULT;
  const lower = filename.toLowerCase();
  for (const [ext, cfg] of extMap) {
    if (lower.endsWith(ext)) return cfg;
  }
  return DEFAULT;
}

module.exports = { getLang };
