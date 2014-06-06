(function() {
  'use strict';
  var common, _;

  common = require('../script/common');

  _ = require('underscore');

  App.filter('picSize', function() {
    return function(input, size) {
      return input != null ? input.replace('.jpg', "_" + size + ".jpg") : void 0;
    };
  });

  App.filter('preview', function() {
    return function(input, type) {
      if (input != null) {
        return {
          song: function() {
            input = common.replaceBat(input, ['%NAME%', '歌名'], ['%ARTIST%', '歌手'], ['%ALBUM%', '专辑'], ['%TRACK%', '音轨号'], ['%DISC%', '碟片号']);
            return "" + input + ".mp3";
          },
          album: function() {
            return input = common.replaceBat(input, ['%NAME%', '专辑名'], ['%ARTIST%', '歌手'], ['%COMPANY%', '唱片公司'], ['%TIME%', '发行日期'], ['%LANGUAGE%', '语言']);
          }
        }[type]();
      }
    };
  });

  App.filter('type2name', function() {
    return function(type) {
      if (type != null) {
        return {
          song: '单曲',
          album: '专辑',
          showcollect: '精选集',
          artist: '艺人热门歌曲'
        }[type];
      }
    };
  });

  /*
  App.filter 'group', ->
  	_.memoize (arr)->
  		_.throttle (arr)->
  			_.groupBy arr, (obj)->
  				[obj.source.type, obj.source.id]
  		, 100
  */


}).call(this);
