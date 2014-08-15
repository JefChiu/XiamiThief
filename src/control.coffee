'use strict'

gui = require 'nw.gui'
os = require 'os'

App.controller 'ControlCtrl',($scope,$rootScope)->
    win = window.win ? window.win = gui.Window.get()
    $scope.isMaximize = false

    win.on 'maximize', ->
        $scope.$apply ->
            $scope.isMaximize = true

    win.on 'unmaximize', ->
        $scope.$apply ->
            $scope.isMaximize = false

    $scope.popupMenuStart = ($event)->
        menuStart.popup $event.clientX, $event.clientY
        # work in node-webkit 8.x:
        # menu.popup $event.clientX, $event.clientY

    $scope.close = ->
        dialog('.dialog .exit').show()

    $scope.zoom = ->
        if $scope.isMaximize
            win.unmaximize()
        else
            win.maximize()
        $scope.isMaximize = not $scope.isMaximize

    $scope.minimize = ->
        win.minimize()