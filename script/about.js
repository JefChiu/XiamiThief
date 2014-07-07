(function() {
  'use strict';
  var gui, win;

  gui = require('nw.gui');

  win = gui.Window.get();

  win.setResizable(false);

  $(function() {
    win.show();
    return win.focus();
  });

}).call(this);
