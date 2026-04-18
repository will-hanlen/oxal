'use strict';

module.exports = {
  type: 'viewer',
  name: 'hu',
  extensions: ['.hu'],
  renderView(data, contentWidth) {
    const { renderLeafView } = require('../lib/mockup');
    return renderLeafView(data, contentWidth);
  },
};
