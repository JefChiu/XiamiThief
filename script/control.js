// Generated by CoffeeScript 1.7.1
(function() {
  'use strict';
  var gui;

  gui = require('nw.gui');

  App.controller('ControlCtrl', function($scope, $rootScope) {
    var win, _ref;
    win = (_ref = window.win) != null ? _ref : window.win = gui.Window.get();
    $scope.isMaximize = false;
    win.on('maximize', function() {
      return $scope.$apply(function() {
        return $scope.isMaximize = true;
      });
    });
    win.on('unmaximize', function() {
      return $scope.$apply(function() {
        return $scope.isMaximize = false;
      });
    });
    $scope.menu = function($event) {
      return menu.popup($event.clientX, $event.clientY);
    };
    $scope.close = function() {
      return dialog('.dialog .exit').show();
    };
    $scope.zoom = function() {
      if ($scope.isMaximize) {
        win.unmaximize();
        return $scope.isMaximize = false;
      } else {
        win.maximize();
        return $scope.isMaximize = true;
      }
    };
    return $scope.minimize = function() {
      return win.minimize();
    };
  });

}).call(this);

//# sourceMappingURL=control.map
