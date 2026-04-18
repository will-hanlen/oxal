'use strict';

module.exports = {
  type: 'editable',
  name: 'Hoon',
  extensions: ['.hoon'],
  lineComment: '::',
  selectionUnits: ['line', 'section', 'indent', 'parent'],
  onOpen(buffer) { buffer.autoFold('::'); },
};
