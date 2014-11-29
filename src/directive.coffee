'use strict'

###
App.directive 'dialog',->
    restrict: 'E'
    templateUrl: '../template/dialog.html'
    replace: true
    link: (scope, element, attrs)->
        scope

App.directive 'autoHeight',($parse)->
    (scope, element, attrs)->
        min = if attrs['autoHeight'] and not isNaN attrs['autoHeight'] then attrs['autoHeight'] else element[0].scrollHeight
        borderWidth = element.outerHeight() - element.innerHeight()
        element.on 'input', (event)->
            element.height(0)
            element.height borderWidth + Math.max(element[0].scrollHeight, min)
###

App.directive 'enabled', ->
    priority: 100,
    link: (scope, element, attr)->
        setValue = (value)->
            attr.$set 'disabled', not value
        setValue attr['enabled']
        scope.$watch attr['enabled'], ngBooleanAttrWatchAction = setValue

App.directive 'task', ->
    restrict: 'E'
    templateUrl: '../template/task.html'
    replace: true
    link: (scope, element, attr)->

App.directive 'process', ->
    (scope, element, attr)->
        scope.$watch attr['process'], (value)->
            element.css 'backgroundSize': "#{value}% 40px"

App.directive 'state', ['State', (State)->
    (scope, element, attr)->
        scope.$watch attr['state'], (value)->
            switch value
                when State.Ready
                    color = 'rgba(0,0,0,0)'
                when State.Running
                    color = 'rgba(0, 0, 255, 0.5)'
                when State.Fail
                    color = 'rgba(255, 0, 0, 0.5)'
                when State.Success
                    color = 'rgba(0, 255, 0, 0.5)'
            element.css 'backgroundImage', "-webkit-linear-gradient(top, #{color}, #{color})"
]

###
App.directive 'input', ->
    restrict: 'E'
    link: (scope, element, attr)->
        element.on 'keydown', (event)->
            false if event.keyCode is 13
###

App.directive 'iframeOnload', ($parse)->
    (scope, element, attr)->
        fn = $parse attr['iframeOnload']
        element.on 'load', (event)->
            scope.$apply ->
                fn scope, $event: event

App.directive 'rightClick', ($parse)->
    (scope, element, attr)->
        fn = $parse attr['rightClick']
        element.on 'contextmenu', (event)->
            scope.$apply ->
                event.preventDefault()
                fn scope, $event: event

App.directive 'imageSize', ->
    (scope, element, attr)->
        setSize = (value)->
            attr.$set 'height', value
            attr.$set 'width', value
        setSize attr['imageSize']
        scope.$watch attr['imageSize'], setSize