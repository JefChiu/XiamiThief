(function() {
  'use strict';
  var config, execPath, extend, fs, getCoverType, getProxyString, getSafeFilename, getSafeFoldername, getValidArray, inStr, index, isAlbum, isArtist, isCollect, isDemo, isPlaylist, isShowcollect, isSong, isUser, leftTrim, mixin, parseLocation, path, replaceBat, replaceLast, request, rightTrim, safePath, setInterval, supplement, timers, toNum, type2name, user, _,
    __slice = [].slice;

  path = require('path');

  fs = require('fs');

  _ = require('underscore');

  request = require('request');

  timers = require('timers');

  isArtist = /www.xiami.com\/artist\/(?:top\/id\/)?(\d+)(?:\/page\/(\d+)-?(\d+)?)?/;

  isSong = /www.xiami.com\/song\/(\d+)/;

  isCollect = /www.xiami.com\/collect\/(\d+)/;

  isShowcollect = /www.xiami.com\/song\/showcollect\/id\/(\d+)/;

  isAlbum = /www.xiami.com\/album\/(\d+)/;

  isUser = /www.xiami.com\/space\/lib-song\/u\/(\d+)\/page\/(\d+)-?(\d+)?/;

  isPlaylist = /www.xiami.com\/play/;

  isDemo = /i.xiami.com\/\S+\/demo\/(\d+)/;

  leftTrim = function(str) {
    return str != null ? str.replace(/^\s+/, '') : void 0;
  };

  rightTrim = function(str) {
    return str != null ? str.replace(/\s+$/, '') : void 0;
  };

  setInterval = function(func, delay) {
    return timers.setTimeout(function() {
      if (!func()) {
        return setInterval(func, delay);
      }
    }, delay);
  };

  execPath = path.dirname(process.execPath);

  config = {
    jar: request.jar(),
    savePath: path.resolve(execPath, 'Music'),
    foldernameFormat: '%NAME%',
    filenameFormat: '%NAME%',
    taskLimitMax: 3,
    cookie: '',
    hasLyric: false,
    hasCover: true,
    hasId3: true,
    useProxy: 'false',
    useMonitoringClipboard: false,
    saveMode: 'smartClassification',
    fileExistSolution: 'coverSmallFile',
    proxy: {
      host: '',
      port: 80,
      username: '',
      password: ''
    },
    id3: {
      hasTitle: true,
      hasArtist: true,
      hasAlbumArtist: true,
      hasAlbum: true,
      hasYear: true,
      hasTrack: true,
      hasGenre: true,
      hasDisc: true,
      hasCover: true,
      hasLyric: false,
      cover: {
        size: 'standard',
        maxSide: 640
      }
    },
    headers: {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.8',
      'Cache-Control': 'max-age=0',
      'Connection': 'keep-alive',
      'Origin': 'http://www.xiami.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36'
    }
  };

  user = {};

  mixin = function() {
    var args, key, obj, result, value, _i, _len;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    result = {};
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      obj = args[_i];
      for (key in obj) {
        value = obj[key];
        result[key] = value;
      }
    }
    return result;
  };

  extend = function() {
    var args, key, obj, source, value, _i, _len;
    source = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      obj = args[_i];
      for (key in obj) {
        value = obj[key];
        source[key] = value;
      }
    }
    return source;
  };

  supplement = function() {
    var args, key, obj, source, value, _i, _len;
    source = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      obj = args[_i];
      for (key in obj) {
        value = obj[key];
        if (source[key] == null) {
          source[key] = value;
        }
      }
    }
    return source;
  };

  parseLocation = function(param1) {
    var _loc_10, _loc_2, _loc_3, _loc_4, _loc_5, _loc_6, _loc_7, _loc_8, _loc_9;
    _loc_10 = void 0;
    if (param1.indexOf("http://") !== -1) {
      return param1;
    }
    _loc_2 = Number(param1.charAt(0));
    _loc_3 = param1.substring(1);
    _loc_4 = Math.floor(_loc_3.length / _loc_2);
    _loc_5 = _loc_3.length % _loc_2;
    _loc_6 = new Array();
    _loc_7 = 0;
    while (_loc_7 < _loc_5) {
      if (_loc_6[_loc_7] === void 0) {
        _loc_6[_loc_7] = "";
      }
      _loc_6[_loc_7] = _loc_3.substr((_loc_4 + 1) * _loc_7, _loc_4 + 1);
      _loc_7 = _loc_7 + 1;
    }
    _loc_7 = _loc_5;
    while (_loc_7 < _loc_2) {
      _loc_6[_loc_7] = _loc_3.substr(_loc_4 * (_loc_7 - _loc_5) + (_loc_4 + 1) * _loc_5, _loc_4);
      _loc_7 = _loc_7 + 1;
    }
    _loc_8 = "";
    _loc_7 = 0;
    while (_loc_7 < _loc_6[0].length) {
      _loc_10 = 0;
      while (_loc_10 < _loc_6.length) {
        _loc_8 = _loc_8 + _loc_6[_loc_10].charAt(_loc_7);
        _loc_10 = _loc_10 + 1;
      }
      _loc_7 = _loc_7 + 1;
    }
    _loc_8 = unescape(_loc_8);
    _loc_9 = "";
    _loc_7 = 0;
    while (_loc_7 < _loc_8.length) {
      if (_loc_8.charAt(_loc_7) === "^") {
        _loc_9 = _loc_9 + "0";
      } else {
        _loc_9 = _loc_9 + _loc_8.charAt(_loc_7);
      }
      _loc_7 = _loc_7 + 1;
    }
    _loc_9 = _loc_9.replace("+", " ");
    return _loc_9;

    /*
    try
        a1 = parseInt(str.charAt(0))
        a2 = str.substring(1)
        a3 = Math.floor(a2.length / a1)
        a4 = a2.length % a1
        a5 = []
        a6 = 0
        a7 = ""
        a8 = ""
        while a6 < a4
            a5[a6] = a2.substr((a3 + 1) * a6, (a3 + 1))
            ++a6
        while a6 < a1
            a5[a6] = a2.substr(a3 * (a6 - a4) + (a3 + 1) * a4, a3)
            ++a6
        i = 0
        a5_0_length = a5[0].length
    
        while i < a5_0_length
            j = 0
            a5_length = a5.length
    
            while j < a5_length
                a7 += a5[j].charAt(i)
                ++j
            ++i
        a7 = decodeURIComponent(a7)
        i = 0
        a7_length = a7.length
    
        while i < a7_length
            a8 += (if a7.charAt(i) is "^" then "0" else a7.charAt(i))
            ++i
        return a8
    catch e
        console.log e
        return false
     */
  };

  replaceLast = function(search, str, newStr) {
    return search != null ? search.replace(RegExp(str + '$'), newStr) : void 0;
  };

  replaceBat = function() {
    var args, nv, str, sv, _i, _len, _ref;
    str = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      _ref = args[_i], sv = _ref[0], nv = _ref[1];
      if (!sv instanceof RegExp) {
        sv = RegExp(sv, g);
      }
      str = str != null ? str.replace(sv, nv) : void 0;
    }
    return str;
  };

  toNum = function(obj) {
    if (isNaN(obj)) {
      return Number(obj);
    } else {
      return obj;
    }
  };

  inStr = function(obj1, obj2) {
    var e;
    try {
      return obj1.indexOf(obj2) !== -1;
    } catch (_error) {
      e = _error;
      return false;
    }
  };


  /*
  safeFilter = (str) ->
      removeSpan = (str)->
          str.replace('<span>', ' ').replace '</span>', ''
      safeFilename = (str)->
           * str.replace /(\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
          str.replace /(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
      safeFilename removeSpan str
   */

  safePath = function(str) {
    return str = str != null ? str.replace(/(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' ') : void 0;
  };

  getSafeFoldername = function(str) {
    str = str != null ? str.replace(/^\.+$/, '_') : void 0;
    str = str != null ? str.replace(/(\.)+$/, '') : void 0;
    str = str != null ? str.trim() : void 0;
    return str = str != null ? str.slice(0, 229) : void 0;
  };

  getSafeFilename = function(str) {
    str = str != null ? str.replace(/(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' ') : void 0;
    str = leftTrim(str);
    return str = str != null ? str.slice(0, 220) : void 0;
  };

  getProxyString = function() {
    var options, result;
    if (config.useProxy === 'true') {
      options = config.proxy;
      result = '';
      if (options.host.slice(0, 4) !== 'http') {
        result += 'http://';
      }
      if (options.username) {
        result += options.username + ':' + options.password(+'@');
      }
      result += options.host + ':' + options.port || '80';
      return result;
    } else {
      return false;
    }
  };

  getValidArray = function(arr) {
    var i, ret;
    ret = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        i = arr[_i];
        if (i) {
          _results.push(i);
        }
      }
      return _results;
    })();
    return ret;

    /*
    console.log arr
    ret = []
    for i in arr
        ret.push if i
    console.log ret
    ret
     */
  };

  getCoverType = function(url) {
    var _ref;
    return (_ref = /\.([\w\d]+)$/.exec(url)) != null ? _ref[1] : void 0;
  };

  type2name = function(type) {
    if (type != null) {
      return {
        song: '单曲',
        album: '专辑',
        collect: '精选集',
        artist: '艺人热门歌曲'
      }[type];
    }
  };

  index = function(arr, i) {
    if (i < 0) {
      return arr[arr.length + i];
    } else {
      return arr[i];
    }
  };

  module.exports = {
    leftTrim: leftTrim,
    rightTrim: rightTrim,
    execPath: execPath,
    config: config,
    user: user,
    index: index,
    mixin: mixin,
    extend: extend,
    supplement: supplement,
    parseLocation: parseLocation,
    replaceLast: replaceLast,
    replaceBat: replaceBat,
    toNum: toNum,
    safePath: safePath,
    getSafeFilename: getSafeFilename,
    getSafeFoldername: getSafeFoldername,
    getProxyString: getProxyString,
    getValidArray: getValidArray,
    getCoverType: getCoverType,
    type2name: type2name,
    inStr: inStr,

    /*
    get
    post
     */
    isArtist: isArtist,
    isSong: isSong,
    isCollect: isCollect,
    isShowcollect: isShowcollect,
    isAlbum: isAlbum,
    isUser: isUser,
    isPlaylist: isPlaylist,
    isDemo: isDemo,
    setInterval: setInterval
  };

}).call(this);
