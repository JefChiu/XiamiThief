(function() {
  'use strict';
  var gui, os;

  gui = require('nw.gui');

  os = require('os');

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
    $scope.popupMenuStart = function($event) {
      return menuStart.popup($event.clientX, $event.clientY);
    };
    $scope.close = function() {
      return dialog('.dialog .exit').show();
    };
    $scope.zoom = function() {
      if ($scope.isMaximize) {
        win.unmaximize();
      } else {
        win.maximize();
      }
      return $scope.isMaximize = !$scope.isMaximize;
    };
    return $scope.minimize = function() {
      return win.minimize();
    };
  });

}).call(this);
