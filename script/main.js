// Generated by CoffeeScript 1.7.1
(function() {
  'use strict';
  var async, bgImg, common, dir, gui, path, pkg, queue, timers,
    __slice = [].slice;

  gui = require('nw.gui');

  pkg = require('../package.json');

  path = require('path');

  timers = require('timers');

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

  common.loadLoginPage = function() {
    var cookies, iframe, removeCookie;
    if (!common.user.logged) {
      iframe = document.querySelector('iframe.loginPage');
      cookies = require('nw.gui').Window.get().cookies;
      removeCookie = function() {
        var args, i, _i, _len, _results;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _results = [];
        for (_i = 0, _len = args.length; _i < _len; _i++) {
          i = args[_i];
          cookies.remove({
            url: 'http://www.xiami.com',
            name: i
          });
          cookies.remove({
            url: 'http://xiami.com',
            name: i
          });
          cookies.remove({
            url: 'https://www.xiami.com',
            name: i
          });
          _results.push(cookies.remove({
            url: 'https://xiami.com',
            name: i
          }));
        }
        return _results;
      };
      removeCookie('_xiamitoken', '_unsign_token', 'member_auth', 'user', 'isg', 't_sign_auth', 'ahtena_is_show');
      iframe.src = '';
      return iframe.src = 'https://login.xiami.com/member/login';
    }
  };

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
        dialog('.dialog .setup').show();
        return common.loadLoginPage();
      }
    }));

    /*
    	menu.append menuItem
    		type: 'separator'
    
    	menu.append menuItem
    		type: 'normal'
    		label: '反馈'
    		click: ->
    			dialog('.dialog .feedback').show()
    
    	menu.append menuItem
    		type: 'normal'
    		label: '检查更新'
    		click: ->
    			dialog('.dialog .update').show()
    
    	menu.append menuItem
    		type: 'normal'
    		label: '关于XiamiThief'
    		click: ->
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

  bgImg = new Image();

  bgImg.addEventListener('load', function() {
    var bgCanvas;
    bgCanvas = document.querySelector('canvas#bg');
    bgCanvas.width = win.width;
    bgCanvas.height = win.height;
    stackBlurImage(bgImg, bgCanvas, 100);
    return win.show();
  });

  win.on('resize', function() {

    /*
    	bgCanvas = document.querySelector('canvas#bg')
    	bgCanvas.width = win.width
    	bgCanvas.height = win.height
    	stackBlurImage bgImg, bgCanvas, 100
     */

    /*
    	width = if win.width > 800 then win.width else 800
    	height = if win.height > 600 then win.height else 600
    	win.resizeTo width, height
     */
  });

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

  App.factory('State', function() {
    return {
      Ready: 0,
      Running: 1,
      Fail: 2,
      Success: 3
    };
  });

  App.factory('TaskQueue', [
    '$rootScope', 'Config', 'quickRepeatList', 'State', function($rootScope, Config, quickRepeatList, State) {
      var q;
      queue = function(concurrency) {
        var q, refresh, running;
        if (concurrency == null) {
          concurrency = Config.taskLimitMax;
        }
        running = 0;
        refresh = function() {
          return _.defer(quickRepeatList.task, q.list);
        };
        return q = {
          list: [],
          push: function() {
            var args, i, j, _i, _j, _len, _len1, _ref;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            for (_i = 0, _len = args.length; _i < _len; _i++) {
              i = args[_i];
              i.state = State.Ready;
              i.process = 0;
              _ref = i.list;
              for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                j = _ref[_j];
                j.state = State.Ready;
                i.process = 0;
              }
            }
            Array.prototype.push.apply(q.list, args);
            return q.dirtyCheck();
          },
          dirtyCheck: function() {
            var c, count, i, total, _i, _j, _len, _len1, _ref, _ref1;
            console.log('list:', q.list);
            if (running < concurrency) {
              _ref = q.list;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                c = _ref[_i];
                switch (c.state) {
                  case State.Ready:
                  case State.Running:
                    total = c.list.length;
                    count = 0;
                    _ref1 = c.list;
                    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                      i = _ref1[_j];
                      switch (i.state) {
                        case State.Ready:
                          i.state = State.Running;
                          i.run((function(i) {
                            return function(err, data) {
                              console.log('info: ', i);
                              console.log('err:', err);
                              i.state = err ? State.Fail : State.Success;
                              i.process = 100;
                              running--;
                              refresh();
                              return q.dirtyCheck();
                            };
                          })(i));
                          running++;
                          refresh();
                          if (running >= concurrency) {
                            return;
                          }
                          break;
                        case State.Fail:
                        case State.Success:
                          count++;
                      }
                    }
                    if (count === total) {
                      c.state = State.Success;
                    }
                }
              }
            }
            return refresh();
          },
          refresh: refresh,
          concurrency: function() {
            if (typeof value !== "undefined" && value !== null) {
              concurrency = value;
            }
            return concurrency;
          }
        };
      };
      q = queue();
      timers.setInterval(q.refresh, 1000);
      return q;
    }
  ]);

  App.controller('TaskCtrl', function($scope, TaskQueue, quickRepeatList) {
    $scope.showCreateDialog = function() {
      return dialog('.dialog .create').show();
    };
    $scope.showSetupDialog = function() {
      dialog('.dialog .setup').show();
      return common.loadLoginPage();
    };
    return $scope.list = TaskQueue.list;

    /*
    	$scope.pre = TaskQueue.pre
    	$scope.err = TaskQueue.err
    	$scope.run = TaskQueue.run
    	$scope.end = TaskQueue.end
     */
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
      switch (e.keyCode) {
        case 27:
          return dialogAllHide();
        case 123:
          return win.showDevTools();
        case 13:
          return dialog('.dialog .create').show();
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
    return bgImg.src = path.resolve(common.execPath, 'bg');
  });

}).call(this);

//# sourceMappingURL=main.map
