(function() {
  'use strict';
  var async, common, dir, gui, path, pkg, queue,
    __slice = [].slice;

  gui = require('nw.gui');

  pkg = require('../package.json');

  path = require('path');

  async = require('async');

  queue = require('../script/queue');

  common = require('../script/common');

  process.on('uncaughtException', function(err) {
    console.error(err);
    return console.error(err.stack);
  });

  dir = {
    template: '../template'
  };

  window.win = gui.Window.get();

  window.dialog = function(element) {
    if (_.isString(element)) {
      element = document.querySelectorAll(element);
    }
    if (!(element.length || element.length === 0)) {
      element = [element];
    }
    if (element.length > 0) {
      return {
        show: function() {
          var i, _i, _len, _results;
          $('body>header').addClass('no-drag');
          $('.dialog').css({
            'z-index': 1,
            display: 'flex'
          });
          _results = [];
          for (_i = 0, _len = element.length; _i < _len; _i++) {
            i = element[_i];
            _results.push(i.style.display = 'flex');
          }
          return _results;
        },
        hide: function() {
          var i, _i, _len, _results;
          $('body>header').removeClass('no-drag');
          $('.dialog').css({
            'z-index': -1,
            display: 'none'
          });
          _results = [];
          for (_i = 0, _len = element.length; _i < _len; _i++) {
            i = element[_i];
            _results.push(i.style.display = 'none');
          }
          return _results;
        }
      };
    } else {
      return {
        show: function() {
          return console.error('show', element);
        },
        hide: function() {
          return console.error('hide', element);
        }
      };
    }
  };

  window.menu = (function() {
    var menu, menuItem;
    menu = new gui.Menu();
    menuItem = function(options) {
      return new gui.MenuItem(options);
    };
    menu.append(menuItem({
      type: 'normal',
      label: '新建下载',
      click: function() {
        return dialog('.dialog .create').show();
      }
    }));
    menu.append(menuItem({
      type: 'separator'
    }));
    menu.append(menuItem({
      type: 'normal',
      label: '软件设置',
      click: function() {
        return dialog('.dialog .setup').show();
      }
    }));
    /*
    	menu.append menuItem
    		type:'separator'
    
    	menu.append menuItem
    		type:'normal'
    		label:'反馈'
    		click:->
    			dialog('.dialog .feedback').show()
    
    	menu.append menuItem
    		type:'normal'
    		label:'检查更新'
    		click:->
    			dialog('.dialog .update').show()
    
    	menu.append menuItem
    		type:'normal'
    		label:'关于XiamiThief'
    		click:->
    			dialog('.dialog .about').show()
    */

    menu.append(menuItem({
      type: 'separator'
    }));
    menu.append(menuItem({
      type: 'normal',
      label: '退出',
      click: function() {
        if (window.tray != null) {
          return win.close();
        } else {
          return dialog('.dialog .exit').show();
        }
      }
    }));
    return menu;
  })();

  win.on('close', function() {
    this.hide();
    return this.close(true);
  });

  /*
  win.on 'resize',->
  	width = if win.width > 800 then win.width else 800
  	height = if win.height > 600 then win.height else 600
  	win.resizeTo width, height
  */


  win.on('minimize', function() {
    window.tray = new gui.Tray({
      title: "" + pkg.name + " " + pkg.version,
      icon: 'resource/image/logo16.png'
    });
    tray.menu = menu;
    tray.on('click', function() {
      win.show();
      win.setAlwaysOnTop(true);
      win.setAlwaysOnTop(false);
      this.remove();
      return window.tray = null;
    });
    return this.hide();
  });

  /*
  win.on 'new-win-policy', (frame, url, policy)->
  	console.log frame, url, policy
  */


  App.factory('User', function() {
    return common.user;
  });

  App.factory('TaskQueue', [
    '$rootScope', 'Config', 'quickRepeatList', function($rootScope, Config, quickRepeatList) {
      var q;
      queue = function(concurrency) {
        var q;
        if (concurrency == null) {
          concurrency = 1;
        }
        return q = {
          pre: [],
          run: [],
          end: [],
          err: [],
          push: function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            q.pre.push.apply(q.pre, args);
            return q.preToRun();
          },
          preToRun: function() {
            var free;
            console.log('preToRun');
            free = concurrency - q.run.length;
            if (free > 0) {
              while (free--) {
                if (q.pre.length > 0) {
                  (function(task) {
                    task.run(function(err, data) {
                      var i;
                      i = _.indexOf(q.run, task);
                      if (!err) {
                        q.end.push(task);
                      } else {
                        q.err.push(task);
                      }
                      q.run.splice(i, 1);
                      _.defer(quickRepeatList.pre, _.groupBy(q.pre, function(obj) {
                        return [obj.source.type, obj.source.id];
                      }));
                      _.defer(quickRepeatList.err, _.groupBy(q.err, function(obj) {
                        return [obj.source.type, obj.source.id];
                      }));
                      _.defer(quickRepeatList.run, _.groupBy(q.run, function(obj) {
                        return [obj.source.type, obj.source.id];
                      }));
                      _.defer(quickRepeatList.end, _.groupBy(q.end, function(obj) {
                        return [obj.source.type, obj.source.id];
                      }));
                      /*
                      										try
                      											$rootScope.$apply()
                      										catch e
                      											console.log e
                      */

                      return q.preToRun();
                    });
                    return q.run.push(task);
                  })(q.pre.shift());
                } else {
                  break;
                }
              }
            }
            _.defer(quickRepeatList.pre, _.groupBy(q.pre, function(obj) {
              return [obj.source.type, obj.source.id];
            }));
            _.defer(quickRepeatList.err, _.groupBy(q.err, function(obj) {
              return [obj.source.type, obj.source.id];
            }));
            _.defer(quickRepeatList.run, _.groupBy(q.run, function(obj) {
              return [obj.source.type, obj.source.id];
            }));
            return _.defer(quickRepeatList.end, _.groupBy(q.end, function(obj) {
              return [obj.source.type, obj.source.id];
            }));
          },
          concurrency: function(value) {
            if (value != null) {
              concurrency = value;
            }
            return concurrency;
          }
        };
      };
      return q = queue(Config.taskLimitMax);
    }
  ]);

  App.controller('TaskCtrl', function($scope, TaskQueue, quickRepeatList) {
    $scope.pre = TaskQueue.pre;
    $scope.err = TaskQueue.err;
    $scope.run = TaskQueue.run;
    return $scope.end = TaskQueue.end;
  });

  App.controller('InfoCtrl', function($scope, User) {
    return $scope.user = User;
  });

  $(function() {
    var dialogAllHide;
    dialogAllHide = function() {
      return dialog('.dialog>*').hide();
    };
    $('.dialog').click(dialogAllHide);
    document.body.addEventListener('contextmenu', function(ev) {
      ev.preventDefault();
      return false;
    });
    $(document).keyup(function(e) {
      if (e.keyCode === 27) {
        return dialogAllHide();
      }
    });
    $(document).keydown(function(e) {
      var left, top, _ref;
      if (e.keyCode === 93) {
        _ref = document.querySelector('.button-menu').getBoundingClientRect(), left = _ref.left, top = _ref.top;
        return menu.popup(left, top);
      }
    });
    $('.dialog>*').click(function(e) {
      return e.stopPropagation();
    });
    return win.show();
  });

}).call(this);
