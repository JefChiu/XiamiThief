'use strict'

gui = require 'nw.gui'

App.controller 'ControlCtrl',($scope,$rootScope)->
    win = window.win ? window.win = gui.Window.get()
    $scope.isMaximize = false

    win.on 'maximize',->
        $scope.$apply ->
            $scope.isMaximize = true

    win.on 'unmaximize',->
        $scope.$apply ->
            $scope.isMaximize = false

    $scope.menu=($event)->
        menu.popup $event.clientX, $event.clientY

    $scope.close=->
        dialog('.dialog .exit').show()

    $scope.zoom=->
        if $scope.isMaximize
            win.unmaximize()
            $scope.isMaximize=false
        else
            win.maximize()
            $scope.isMaximize=true

    $scope.minimize=->
        win.minimize()