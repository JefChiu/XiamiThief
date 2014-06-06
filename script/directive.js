(function() {
  'use strict';
  /*
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
  */

  App.directive('enabled', function() {
    return {
      priority: 100,
      link: function(scope, element, attr) {
        var ngBooleanAttrWatchAction;
        return scope.$watch(attr['enabled'], ngBooleanAttrWatchAction = function(value) {
          return attr.$set('disabled', !value);
        });
      }
    };
  });

  App.directive('task', function() {
    return {
      restrict: 'E',
      templateUrl: '../template/task.html',
      replace: true,
      link: function(scope, element, attrs) {}
    };
  });

  App.directive('process', function() {
    return function(scope, element, attr) {
      return scope.$watch(function() {
        return scope.task.process;
      }, function(newValue, oldValue) {
        if (newValue) {
          if (newValue >= 0) {
            return element.css({
              'backgroundSize': "" + newValue + "% 40px"
            });
          } else {
            element.css({
              'backgroundSize': '100% 40px'
            });
            return element.css({
              'backgroundImage': '-webkit-linear-gradient(top, #e74c3c, #e74c3c)'
            });
          }
        }
      });
    };
  });

  App.directive('iframeOnload', function($parse) {
    return function(scope, element, attrs) {
      var fn;
      fn = $parse(attrs['iframeOnload']);
      return element.on('load', function(event) {
        return scope.$apply(function() {
          return fn(scope, {
            $event: event
          });
        });
      });
    };
  });

}).call(this);
