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
        var ngBooleanAttrWatchAction, setValue;
        setValue = function(value) {
          return attr.$set('disabled', !value);
        };
        setValue(attr['enabled']);
        return scope.$watch(attr['enabled'], ngBooleanAttrWatchAction = setValue);
      }
    };
  });

  App.directive('task', function() {
    return {
      restrict: 'E',
      templateUrl: '../template/task.html',
      replace: true,
      link: function(scope, element, attr) {}
    };
  });

  App.directive('process', function() {
    return function(scope, element, attr) {
      return scope.$watch(attr['process'], function(value) {
        return element.css({
          'backgroundSize': "" + value + "% 40px"
        });
      });
    };
  });

  App.directive('state', [
    'State', function(State) {
      return function(scope, element, attr) {
        return scope.$watch(attr['state'], function(value) {
          var color;
          switch (value) {
            case State.Ready:
              color = 'rgba(0,0,0,0)';
              break;
            case State.Running:
              color = 'rgba(0, 0, 255, 0.5)';
              break;
            case State.Fail:
              color = 'rgba(255, 0, 0, 0.5)';
              break;
            case State.Success:
              color = 'rgba(0, 255, 0, 0.5)';
          }
          return element.css('backgroundImage', "-webkit-linear-gradient(top, " + color + ", " + color + ")");
        });
      };
    }
  ]);

  App.directive('iframeOnload', function($parse) {
    return function(scope, element, attr) {
      var fn;
      fn = $parse(attr['iframeOnload']);
      return element.on('load', function(event) {
        return scope.$apply(function() {
          return fn(scope, {
            $event: event
          });
        });
      });
    };
  });

  App.directive('rightClick', function($parse) {
    return function(scope, element, attr) {
      var fn;
      fn = $parse(attr['rightClick']);
      return element.on('contextmenu', function(event) {
        return scope.$apply(function() {
          event.preventDefault();
          return fn(scope, {
            $event: event
          });
        });
      });
    };
  });

  App.directive('imageSize', function() {
    return function(scope, element, attr) {
      var setSize;
      setSize = function(value) {
        attr.$set('height', value);
        return attr.$set('width', value);
      };
      setSize(attr['imageSize']);
      return scope.$watch(attr['imageSize'], setSize);
    };
  });

}).call(this);
