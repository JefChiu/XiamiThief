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
		scope.$watch attr['enabled'], ngBooleanAttrWatchAction = (value)->
			attr.$set 'disabled', not value

App.directive 'task', ->
	restrict: 'E'
	templateUrl: '../template/task.html'
	replace: true
	link: (scope, element, attrs)->

App.directive 'process', ->
	(scope, element, attr)->
		scope.$watch ->
				scope.task.process
			,(newValue, oldValue)->
				if newValue
					if newValue >= 0
						element.css('backgroundSize': "#{newValue}% 40px")
					else
						element.css('backgroundSize': '100% 40px')
						element.css('backgroundImage': '-webkit-linear-gradient(top, #e74c3c, #e74c3c)')

App.directive 'iframeOnload', ($parse)->
	(scope, element, attrs)->
		fn = $parse attrs['iframeOnload']
		element.on 'load', (event)->
			scope.$apply ->
				fn scope, $event:event