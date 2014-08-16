(function() {
  'use strict';
  var async, bgImg, common, dir, gui, i, originWhitelist, os, path, pkg, queue, timers, url, _i, _len,
    __slice = [].slice;

  window.version = (function() {
    var _i, _len, _ref, _results;
    _ref = process.versions['node-webkit'].split('.');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      i = _ref[_i];
      _results.push(Number(i));
    }
    return _results;
  })();

  window.require = (function() {
    var originRequire;
    originRequire = require;
    return function(path) {
      if ((version[1] === 8 || (version[1] === 10 && version[2] >= 1)) && path[0] === '.') {
        path = '.' + path;
      }
      return originRequire(path);
    };
  })();

  gui = require('nw.gui');

  pkg = require('./package');

  os = require('os');

  path = require('path');

  timers = require('timers');

  async = require('async');

  url = require('url');

  queue = require('./script/queue');

  common = require('./script/common');


  /*
  if process.env.NODE_ENV isnt 'production'
      require 'longjohn'
   */

  process.on('uncaughtException', function(err) {
    console.error(err);
    return console.error(err.stack);
  });

  (function() {
    var newWindow, request;
    newWindow = null;
    request = (require('request')).defaults({
      headers: common.config.headers,
      followAllRedirects: false,
      strictSSL: false,
      proxy: false
    });

    /*
    resProcess = (error, response, body, cb)->
        console.log response
        hasCheckcode = common.inStr(body, 'regcheckcode.taobao.com') or common.inStr(body, '<div class="msg e needcode">')
        if hasCheckcode
            alert '请在弹出的页面中输入验证码, 提交完毕后关闭页面'
            new_win = gui.Window.open response?.request?.href?,
                'frame': true
                'toolbar': false
            new_win.on 'closed', ->
                
        else
             * console.log response
            if common.inStr response?.headers?['content-type'], 'json'
                try
                    body = JSON.parse body
                catch e
                    console.error e, body
            else if common.inStr(response?.request?.headers?['Content-Type'], 'json')
                try
                    body = JSON.parse body
                catch e
                    console.error e, body
            cb? error, response, body
     */
    common.getReq = function(url, headers, cb) {
      var args, req;
      args = arguments;
      console.log(url, '"' + common.getProxyString() + '"', common.config.cookie);
      switch (arguments.length) {
        case 3:
          url = arguments[0], headers = arguments[1], cb = arguments[2];
          break;
        case 2:
          url = arguments[0], cb = arguments[1];
          break;
        case 1:
          url = arguments[0];
          break;
        default:
          throw new Error('arguments error.');
      }
      headers = common.mixin({
        Cookie: common.config.cookie,
        Referer: 'http://www.xiami.com/'
      }, headers);
      return req = request({
        'url': url,
        'method': 'GET',
        'headers': headers,
        'jar': common.config.jar,
        'proxy': common.getProxyString()
      });
    };
    common.get = function(url, headers, cb) {
      var args, req;
      args = arguments;
      console.log(url, '"' + common.getProxyString() + '"', common.config.cookie);
      switch (arguments.length) {
        case 3:
          url = arguments[0], headers = arguments[1], cb = arguments[2];
          break;
        case 2:
          url = arguments[0], cb = arguments[1];
          break;
        case 1:
          url = arguments[0];
          break;
        default:
          throw new Error('arguments error.');
      }
      headers = common.mixin({
        Cookie: common.config.cookie,
        Referer: 'http://www.xiami.com/'
      }, headers);
      req = request({
        'url': url,
        'method': 'GET',
        'headers': headers,
        'jar': common.config.jar,
        'proxy': common.getProxyString()
      }, function(error, response, body) {
        var e, hasCheckcode, _ref, _ref1, _ref2, _ref3;
        hasCheckcode = common.inStr(body, 'regcheckcode.taobao.com') || common.inStr(body, '<div class="msg e needcode">');
        console.log(url, 'hasCheckcode:' + hasCheckcode);
        if (hasCheckcode) {
          if (newWindow != null) {
            return common.setInterval(function() {
              if (newWindow == null) {
                common.get.apply(null, args);
              }
              return newWindow == null;
            }, 1000);
          } else {
            alert('请在弹出的页面中输入验证码, 提交完毕后关闭页面');
            newWindow = gui.Window.open((response != null ? (_ref = response.request) != null ? _ref.href : void 0 : void 0) != null, {
              'frame': true,
              'toolbar': false
            });
            return newWindow.on('closed', function() {
              common.get.apply(null, args);
              return newWindow = null;
            });
          }
        } else {
          if (common.inStr(response != null ? (_ref1 = response.headers) != null ? _ref1['content-type'] : void 0 : void 0, 'json')) {
            try {
              body = JSON.parse(body);
            } catch (_error) {
              e = _error;
              console.error(e, body);
            }
          } else if (common.inStr(response != null ? (_ref2 = response.request) != null ? (_ref3 = _ref2.headers) != null ? _ref3['Content-Type'] : void 0 : void 0 : void 0, 'json')) {
            try {
              body = JSON.parse(body);
            } catch (_error) {
              e = _error;
              console.error(e, body);
            }
          }
          if (cb) {
            return cb(error, response, body);
          }
        }
      });
      return req;
    };
    common.postReq = function(url, data, headers, cb) {
      var args, req;
      args = arguments;
      console.log(url, '"' + common.getProxyString() + '"', common.config.cookie);
      switch (arguments.length) {
        case 4:
          url = arguments[0], data = arguments[1], headers = arguments[2], cb = arguments[3];
          break;
        case 3:
          url = arguments[0], data = arguments[1], cb = arguments[2];
          break;
        case 2:
          url = arguments[0], cb = arguments[1];
          break;
        case 1:
          url = arguments[0];
          break;
        default:
          throw new Error('arguments error.');
      }
      headers = common.mixin({
        Cookie: common.config.cookie,
        Referer: 'http://www.xiami.com/'
      }, headers);
      return req = request({
        'url': url,
        'method': 'POST',
        'headers': headers,
        'jar': common.config.jar,
        'proxy': common.getProxyString(),
        'form': data
      });
    };
    return common.post = function(url, data, headers, cb) {
      var args, req;
      args = arguments;
      console.log(url, '"' + common.getProxyString() + '"', common.config.cookie);
      switch (arguments.length) {
        case 4:
          url = arguments[0], data = arguments[1], headers = arguments[2], cb = arguments[3];
          break;
        case 3:
          url = arguments[0], data = arguments[1], cb = arguments[2];
          break;
        case 2:
          url = arguments[0], cb = arguments[1];
          break;
        case 1:
          url = arguments[0];
          break;
        default:
          throw new Error('arguments error.');
      }
      headers = common.mixin({
        Cookie: common.config.cookie,
        Referer: 'http://www.xiami.com/'
      }, headers);
      req = request({
        'url': url,
        'method': 'POST',
        'headers': headers,
        'jar': common.config.jar,
        'proxy': common.getProxyString(),
        'form': data
      }, function(error, response, body) {
        var e, hasCheckcode, _ref, _ref1, _ref2, _ref3;
        hasCheckcode = common.inStr(body, 'regcheckcode.taobao.com') || common.inStr(body, '<div class="msg e needcode">');
        if (hasCheckcode) {
          if (newWindow != null) {
            return common.setInterval(function() {
              if (newWindow == null) {
                common.post.apply(null, args);
              }
              return newWindow == null;
            }, 1000);
          } else {
            alert('请在弹出的页面中输入验证码, 提交完毕后关闭页面');
            newWindow = gui.Window.open((response != null ? (_ref = response.request) != null ? _ref.href : void 0 : void 0) != null, {
              'frame': true,
              'toolbar': false
            });
            return newWindow.on('closed', function() {
              common.post.apply(null, args);
              return newWindow = null;
            });
          }
        } else {
          if (common.inStr(response != null ? (_ref1 = response.headers) != null ? _ref1['content-type'] : void 0 : void 0, 'json')) {
            try {
              body = JSON.parse(body);
            } catch (_error) {
              e = _error;
              console.error(e, body);
            }
          } else if (common.inStr(response != null ? (_ref2 = response.request) != null ? (_ref3 = _ref2.headers) != null ? _ref3['Content-Type'] : void 0 : void 0 : void 0, 'json')) {
            try {
              body = JSON.parse(body);
            } catch (_error) {
              e = _error;
              console.error(e, body);
            }
          }
          return typeof cb === "function" ? cb(error, response, body) : void 0;
        }
      });
      return req;
    };
  })();

  if (gui.App.addOriginAccessWhitelistEntry != null) {
    originWhitelist = ['https://xiami.com', 'https://login.xiami.com', 'https://taobao.com', 'https://login.taobao.com', 'https://h.alipayobjects.com', 'https://passport.alipay.com', 'https://ynuf.alipay.com', 'https://s.tbcdn.cn', 'https://acjs.aliyun.com'];
    for (_i = 0, _len = originWhitelist.length; _i < _len; _i++) {
      i = originWhitelist[_i];
      gui.App.addOriginAccessWhitelistEntry(i, 'app', 'xiamithief', true);
    }
  }

  dir = {
    template: '../template'
  };

  window.win = gui.Window.get();

  window.count = 0;


  /*
  window.addEventListener 'load', ->
      win.show()
   */

  common.loadLoginPage = function() {
    var cookies, iframe, removeCookie;
    if (!common.user.logged) {
      iframe = document.querySelector('iframe.loginPage');
      cookies = require('nw.gui').Window.get().cookies;
      removeCookie = function() {
        var args, _j, _len1, _results;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _results = [];
        for (_j = 0, _len1 = args.length; _j < _len1; _j++) {
          i = args[_j];
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
      if (iframe != null) {
        iframe.src = '';
      }
      return iframe != null ? iframe.src = 'https://login.xiami.com/member/login' : void 0;
    }
  };

  window.dialog = function(element) {
    var _ref;
    if ((_ref = window.tray) != null) {
      _ref._events.click();
    }
    if (_.isString(element)) {
      element = document.querySelectorAll(element);
    }
    if (!(element.length || element.length === 0)) {
      element = [element];
    }
    if (element.length > 0) {
      return {
        show: function() {
          var _j, _len1, _results;
          $('body>header').addClass('no-drag');
          $('.dialog').css({
            'z-index': 1,
            display: 'block'
          });
          _results = [];
          for (_j = 0, _len1 = element.length; _j < _len1; _j++) {
            i = element[_j];
            _results.push(i.style.display = 'flex');
          }
          return _results;
        },
        hide: function() {
          var _j, _len1, _results;
          $('body>header').removeClass('no-drag');
          $('.dialog').css({
            'z-index': -1,
            display: 'none'
          });
          _results = [];
          for (_j = 0, _len1 = element.length; _j < _len1; _j++) {
            i = element[_j];
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

  window.menuStart = (function() {
    var menu, menuItem;
    menu = new gui.Menu;
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
    if (os.platform() === 'drawin' && version[1] >= 10) {
      menu.createMacBuiltin('xiami-thief');
    }
    return menu;
  })();

  win.on('close', function() {
    this.hide();
    return this.close(true);
  });

  bgImg = new Image;

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
    tray.menu = menuStart;
    tray.on('click', function() {
      win.show();
      win.setAlwaysOnTop(true);
      win.setAlwaysOnTop(false);
      tray.remove();
      return window.tray = null;
    });
    return win.hide();
  });


  /*
  win.on 'new-win-policy', (frame, url, policy)->
      console.log frame, url, policy
   */

  window.clipboard = gui.Clipboard.get();

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
          return _.defer(quickRepeatList.tasks, q.list);
        };
        return q = {
          list: [],
          remove: function(index) {
            q.list[index].state = State.Fail;
            q.list[index].hide = true;
            return refresh();
          },
          push: function() {
            var args, j, _j, _k, _len1, _len2, _ref;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            for (_j = 0, _len1 = args.length; _j < _len1; _j++) {
              i = args[_j];
              i.state = State.Ready;
              i.process = 0;
              _ref = i.list;
              for (_k = 0, _len2 = _ref.length; _k < _len2; _k++) {
                j = _ref[_k];
                j.state = State.Ready;
                i.process = 0;
              }
            }
            Array.prototype.push.apply(q.list, args);
            return q.dirtyCheck();
          },
          dirtyCheck: function() {
            var c, count, total, _j, _k, _len1, _len2, _ref, _ref1;
            if (running < concurrency) {
              _ref = q.list;
              for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                c = _ref[_j];
                switch (c.state) {
                  case State.Ready:
                  case State.Running:
                    total = c.list.length;
                    count = 0;
                    _ref1 = c.list;
                    for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
                      i = _ref1[_k];
                      switch (i.state) {
                        case State.Ready:
                          i.state = State.Running;
                          i.run((function(i) {
                            return function(err, data) {
                              if (err) {
                                console.error(err, q.list);
                                i.state = State.Fail;
                              } else {
                                i.state = State.Success;
                              }
                              i.state = err != null ? State.Fail : State.Success;
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

  App.controller('TaskCtrl', function($scope, TaskQueue, State, quickRepeatList) {
    var createMenuTask, createMenuTrack;
    createMenuTask = function(info) {
      var menu, menuItem;
      menu = new gui.Menu;
      menuItem = function(options) {
        return new gui.MenuItem(options);
      };
      menu.append(menuItem({
        type: 'normal',
        label: '在虾米音乐网打开',
        click: function() {
          var link;
          switch (info.type) {
            case 'song':
              link = "http://www.xiami.com/song/" + info.list[0].id;
              break;
            case 'album':
              link = "http://www.xiami.com/album/" + info.id;
              break;
            case 'collect':
              link = "http://www.xiami.com/collect/" + info.id;
              break;
            case 'artist':
              link = "http://www.xiami.com/artist/" + info.id;
              break;
            case 'user':
              link = "http://www.xiami.com/space/lib-song/u/" + info.id + "/page/" + info.start;
              break;
            default:
              link = "http://www.xiami.com/";
          }
          return gui.Shell.openExternal(link);
        }
      }));
      if (os.platform() === 'drawin' && version[1] >= 10) {
        menu.createMacBuiltin('xiami-thief');
      }
      return menu;
    };
    createMenuTrack = function(info) {
      var menu, menuItem;
      menu = new gui.Menu;
      menuItem = function(options) {
        return new gui.MenuItem(options);
      };
      menu.append(menuItem({
        type: 'normal',
        label: '打开文件',
        click: function() {
          var _ref, _ref1;
          console.log(info, path.resolve(info != null ? (_ref = info.save) != null ? _ref.path : void 0 : void 0, info != null ? (_ref1 = info.save) != null ? _ref1.name : void 0 : void 0) + '.mp3');
          return gui.Shell.openExternal('"' + path.resolve(info.save.path, info.save.name) + '.mp3' + '"');
        }
      }));
      menu.append(menuItem({
        type: 'normal',
        label: '打开文件存放目录',
        click: function() {
          var _ref;
          console.log(info, info != null ? (_ref = info.save) != null ? _ref.path : void 0 : void 0);
          return gui.Shell.openExternal('"' + info.save.path + '"');
        }
      }));
      menu.append(menuItem({
        type: 'separator'
      }));
      menu.append(menuItem({
        type: 'normal',
        label: '在虾米音乐网打开',
        click: function() {
          return gui.Shell.openExternal("http://www.xiami.com/song/" + info.song.id);
        }
      }));
      menu.append(menuItem({
        type: 'separator'
      }));
      menu.append(menuItem({
        type: 'normal',
        label: '复制[低音质]下载链接',
        click: function() {
          if (info.url.lq) {
            return clipboard.set(info.url.lq);
          }
        }
      }));
      menu.append(menuItem({
        type: 'normal',
        label: '复制[高音质]下载链接',
        click: function() {
          var hq, lq;
          if (info.url.hq) {
            return clipboard.set(info.url.hq);
          } else {
            lq = info.url.lq;
            hq = common.replaceBat(lq, ['m1.file.xiami.com', 'm3.file.xiami.com'], ['m5.file.xiami.com', 'm6.file.xiami.com'], ['l.mp3', 'h.mp3']);
            return clipboard.set(hq);
          }
        }
      }));
      if (os.platform() === 'drawin' && version[1] >= 10) {
        menu.createMacBuiltin('xiami-thief');
      }
      return menu;
    };
    $scope.showCreateDialog = function() {
      return dialog('.dialog .create').show();
    };
    $scope.showSetupDialog = function() {
      dialog('.dialog .setup').show();
      return common.loadLoginPage();
    };
    $scope.list = TaskQueue.list;
    $scope.State = State;
    $scope.check = TaskQueue.dirtyCheck;
    $scope.removeTask = TaskQueue.remove;
    $scope.isHq = function(info) {
      if (info.url.hq) {
        return url.parse(info.url.hq).hostname.split('.')[0] === 'm6';
      } else {
        return false;
      }
    };
    $scope.popupMenuTask = function($event, info) {
      var menuTask;
      menuTask = createMenuTask(info);
      return menuTask.popup($event.clientX, $event.clientY);
    };
    return $scope.popupMenuTrack = function($event, info) {
      var menuTrack;
      menuTrack = createMenuTrack(info);
      return menuTrack.popup($event.clientX, $event.clientY);
    };

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

    /*
    document.body.addEventListener 'contextmenu', (ev)->
        ev.preventDefault()
         * menu.popup(ev.x, ev.y)
        false
     */
    $(document).keyup(function(e) {
      switch (e.keyCode) {
        case 27:
          return dialogAllHide();
        case 13:
          return dialog('.dialog .create').show();
      }
    });
    $(document).keydown(function(e) {
      var left, top, _ref;
      if (e.keyCode === 93) {
        _ref = document.querySelector('.button-menu').getBoundingClientRect(), left = _ref.left, top = _ref.top;
        return menuStart.popup(left, top);
      }
    });
    $('.dialog>*').click(function(e) {
      return e.stopPropagation();
    });
    if (os.platform() === 'win32' && os.release().split('.') === '5') {
      return $('body').addClass('.xp-font');
    }
  });

}).call(this);
