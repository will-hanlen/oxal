'use strict';

const { getLang } = require('../lang');
const { createEditor: createSharedEditor } = require('./engine');

function createEditor() {
  const { state, handleKey: sharedHandleKey, clampCursor, km } = createSharedEditor({
    getLang,
  });

  function handleKey(key, buffer) {
    state.message = '';
    sharedHandleKey(key, buffer);
  }

  return { state, handleKey, clampCursor: km.clampCursor };
}

module.exports = { createEditor };
