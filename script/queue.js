(function() {
  'use strict';
  var queue, _,
    __slice = [].slice;

  _ = require('underscore');

  queue = function(concurrency) {
    var q, running;
    if (concurrency == null) {
      concurrency = 1;
    }
    running = false;
    return q = {
      pre: [],
      run: [],
      end: [],
      err: [],
      push: function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        q.pre.push.apply(q.pre, args);
        console.log('push');
        return q.preToRun();
      },
      preToRun: function() {
        var free, task, _results;
        console.count('preToRun');
        free = concurrency - q.run.length;
        console.log(concurrency, q.run.length);
        if (free >= 1) {
          _results = [];
          while (free--) {
            if (q.pre.length > 0) {
              task = q.pre.shift();
              console.log(task);
              task.run(function(err, data) {
                var i;
                i = _.indexOf(q.run, task);
                if (!err) {
                  q.end.push(task);
                } else {
                  q.err.push(task);
                }
                q.run.splice(i, 1);
                return q.preToRun();
              });
              q.run.push(task);
              _results.push(running = true);
            } else {
              break;
            }
          }
          return _results;
        }
      },
      concurrency: function(value) {
        if (value != null) {
          concurrency = value;
        }
        return concurrency;
      }
    };
  };

  module.exports = queue;

}).call(this);
