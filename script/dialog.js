(function() {
  'use strict';
  var async, cheerio, common, cookie, ent, fs, genre, gui, http, https, id3v23, mkdirp, path, pkg, request, tunnel, url,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  gui = require('nw.gui');

  pkg = require('../package.json');

  async = require('async');

  http = require('http');

  https = require('https');

  common = require('../script/common');

  request = (require('request')).defaults({
    jar: true,
    headers: common.config.headers,
    followAllRedirects: false,
    strictSSL: false,
    proxy: false
  });

  cheerio = require('cheerio');

  cookie = require('cookie');

  tunnel = require('tunnel');

  fs = require('fs');

  url = require('url');

  path = require('path');

  mkdirp = require('mkdirp');

  ent = require('ent');

  id3v23 = require('../script/id3v2').id3v23;

  genre = require('../script/genre');

  App.factory('Config', function() {
    return common.config;
  });

  App.controller('CreateCtrl', function($scope, TaskQueue, Config, User) {
    var cache, getInfo, getLocation, requestFile, type;
    type = {
      song: 0,
      album: 1,
      artist: 2,
      showcollect: 3
    };
    cache = {};
    $scope.type = type;
    $scope.step = 1;
    $scope.links = '';
    $scope.data = [];
    getLocation = function(sid, cb) {
      if (true || user.logged) {
        return request({
          url: "http://www.xiami.com/song/gethqsong/sid/" + sid,
          json: 'body',
          jar: true,
          headers: common.mixin(Config.headers, {
            'Content-Type': 'application/json',
            'Cookie': Config.cookie,
            'Referer': 'http://www.xiami.com'
          }),
          proxy: common.getProxyString()
        }, function(error, response, body) {
          var result;
          if (!error && response.statusCode === 200) {
            console.log(body);
            result = common.parseLocation(body.location);
            if (result) {
              return cb(null, result.trim());
            } else {
              return cb(result);
            }
          } else {
            return cb(error, '');
          }
        });
      } else {
        return console.log('not login');
      }
    };
    requestFile = function(cb) {
      var info;
      info = this;
      return getLocation(this.song.id, function(err, location) {
        var filename, foldername, pathFolder, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
        if (location) {
          filename = common.replaceBat(Config.filenameFormat, ['%NAME%', info.song.name], ['%ARTIST%', info.artist.name], ['%ALBUM%', info.album.name], ['%TRACK%', info.track.id != null ? (info.track.id.length === 1 ? "0" + info.track.id : info.track.id) : ''], ['%DISC%', (_ref = info.track.disc) != null ? _ref : '']);
          filename = common.getSafeFilename(filename);
          switch (info.source.type) {
            case 'album':
              foldername = common.replaceBat(Config.foldernameFormat, ['%NAME%', (_ref1 = info.source.name) != null ? _ref1 : ''], ['%ARTIST%', (_ref2 = info.source.artist) != null ? _ref2 : ''], ['%COMPANY%', (_ref3 = info.source.company) != null ? _ref3 : ''], ['%TIME%', (_ref4 = info.source.time) != null ? _ref4 : ''], ['%LANGUAGE%', (_ref5 = info.source.language) != null ? _ref5 : '']);
              break;
            case 'artist':
              foldername = info.source.artist;
              break;
            default:
              foldername = info.source.name;
          }
          foldername = common.getSafeFoldername(foldername);
          if (info.source.type === 'album' && info.track.cd === '2') {
            pathFolder = path.resolve(Config.savePath, foldername, "disc " + info.track.disc);
          } else {
            pathFolder = path.resolve(Config.savePath, foldername);
          }
          return mkdirp(pathFolder, function(err) {
            var fileDownload, savePath;
            if (!err) {
              savePath = path.resolve(pathFolder, filename);
              return async.auto({
                coverDownload: function(cb) {
                  var coverPath, resizeImage;
                  coverPath = path.resolve(pathFolder, "" + info.album.id + ".jpg");
                  console.log('coverPath', coverPath);
                  resizeImage = function(imagePath) {
                    var image, maxSide;
                    console.log('resizeImage', imagePath);
                    maxSide = Config.id3.size === 'standard' ? 640 : Config.id3.cover.maxSide;
                    image = new Image();
                    image.addEventListener('load', function(e) {
                      var canvas, ctx, data, f, height, width;
                      console.log('load');
                      canvas = document.createElement('canvas');
                      ctx = canvas.getContext('2d');
                      width = image.width;
                      height = image.height;
                      if (height < maxSide && width < maxSide) {
                        if (imagePath.slice(0, 4) === 'http') {
                          f = fs.createWriteStream(coverPath);
                          f.on('finish', function() {
                            return fs.readFile(coverPath, cb);
                          });
                          f.on('error', cb);
                          request(info.cover.url, {
                            jar: false,
                            headers: {},
                            proxy: common.getProxyString()
                          }).pipe(f);
                        } else {
                          fs.readFile(imagePath, cb);
                        }
                        return;
                      }
                      if (height > width) {
                        canvas.height = maxSide;
                        canvas.width = maxSide / height * width;
                      } else {
                        canvas.width = maxSide;
                        canvas.height = maxSide / width * height;
                      }
                      ctx.drawImage(image, 0, 0, image.width, image.height, 0, 0, canvas.width, canvas.height);
                      data = canvas.toDataURL('image/jpeg').replace('data:image/jpeg;base64,', '');
                      return cb(err, new Buffer(data, 'base64'));
                    });
                    return image.src = imagePath.slice(0, 4) === 'http' ? imagePath : "file:///" + imagePath;
                    /*
                    									id3CoverPath = path.resolve pathFolder, "#{info.album.id}_#{maxSide}.jpg"
                    									console.log 'id3CoverPath', id3CoverPath
                    									fs.exists id3CoverPath, (exists)->
                    										if exists
                    											console.log 'exists'
                    											fs.readFile id3CoverPath, cb
                    										else
                    											console.log 'no-exists'
                    											image = new Image()
                    											image.addEventListener 'load', (e)->
                    												canvas = document.createElement 'canvas'
                    												ctx = canvas.getContext '2d'
                    												width = image.width
                    												height = image.height
                    												if height < maxSide and width < maxSide
                    													if imagePath[...4] is 'http'
                    														f = fs.createWriteStream coverPath
                    														f.on 'finish', ->
                    															fs.readFile coverPath, cb
                    														f.on 'error', cb
                    														request(info.cover.url,
                    															jar: false
                    															headers: {}
                    															proxy: common.getProxyString()
                    														).pipe f
                    													else
                    														fs.readFile imagePath, cb
                    													return
                    												if height > width
                    													canvas.height = maxSide
                    													canvas.width = maxSide / height * width
                    												else
                    													canvas.width = maxSide
                    													canvas.height = maxSide / width * height
                    												ctx.drawImage image,
                    													0, 0,
                    													image.width, image.height,
                    													0, 0,
                    													canvas.width, canvas.height
                    												data = canvas.toDataURL('image/jpeg').replace 'data:image/jpeg;base64,', ''
                    												fs.writeFile id3CoverPath, data, encoding: 'base64', (err)->
                    													cb err, new Buffer(data, 'base64')
                    											image.src = if imagePath[...4] is 'http' then imagePath else "file:///#{imagePath}"
                    */

                  };
                  console.log('coverDownload');
                  if (Config.hasCover || (Config.hasId3 && Config.id3.hasCover)) {
                    console.log('coverDownload is true');
                    return fs.exists(coverPath, function(exists) {
                      var f;
                      if (exists) {
                        if (Config.hasId3 && Config.id3.hasCover) {
                          if (Config.id3.cover.size === 'original') {
                            return fs.readFile(coverPath, cb);
                          } else {
                            return resizeImage(info.cover.url);
                          }
                        } else {
                          return cb(null);
                        }
                      } else {
                        if (Config.hasCover) {
                          f = fs.createWriteStream(coverPath);
                          f.on('finish', function() {
                            if (Config.hasId3 && Config.id3.hasCover) {
                              if (Config.id3.cover.size === 'original') {
                                return fs.readFile(coverPath, cb);
                              } else {
                                return resizeImage(info.cover.url);
                              }
                            } else {
                              return cb(null);
                            }
                          });
                          f.on('error', function(err) {
                            return cb(err);
                          });
                          return request(info.cover.url, {
                            jar: false,
                            headers: {},
                            proxy: common.getProxyString()
                          }).pipe(f);
                        } else {
                          return resizeImage(info.cover.url);
                        }
                      }
                    });
                  } else {
                    return cb(null);
                  }
                },
                lyricDownload: function(cb) {
                  var f;
                  console.log('lyricDownload');
                  if ((Config.hasLyric || (Config.hasId3 && Config.id3.hasLyric)) && info.lyric.url) {
                    console.log('lyricDownload is true');
                    if (Config.hasLyric) {
                      f = fs.createWriteStream("" + savePath + ".lrc");
                      f.on('finish', function() {
                        if (Config.hasId3 && Config.id3.hasLyric) {
                          return fs.readFile("" + savePath + ".lrc", function(err, data) {
                            return cb(err, data.toString());
                          });
                        } else {
                          return cb(null);
                        }
                      });
                      f.on('error', function(err) {
                        return cb(err);
                      });
                      return request(info.lyric.url, {
                        jar: false,
                        headers: {},
                        proxy: common.getProxyString()
                      }).pipe(f);
                    } else {
                      return request(info.lyric.url, {
                        jar: false,
                        headers: {},
                        proxy: common.getProxyString()
                      }, function(error, response, body) {
                        return cb(error, body);
                      });
                    }
                  } else {
                    console.log('noLyric');
                    return cb(null);
                  }
                },
                writeId3Info: common.getValidArray([
                  Config.id3.hasCover ? 'coverDownload' : void 0, Config.id3.hasLyric ? 'lyricDownload' : void 0, function(cb, result) {
                    var g, id3Writer, image, lyric;
                    console.log(result);
                    console.log('writeId3Info');
                    if (Config.hasId3) {
                      console.log('writeId3Info is true');
                      id3Writer = new id3v23("" + savePath + ".download");
                      if (Config.id3.hasAlbum && info.album.name) {
                        id3Writer.setTag('TALB', info.album.name);
                      }
                      if (Config.id3.hasArtist && info.artist.name) {
                        id3Writer.setTag('TPE1', info.artist.name);
                      }
                      if (Config.id3.hasAlbumArtist && info.album.artist) {
                        id3Writer.setTag('TPE2', info.album.artist);
                      }
                      if (Config.id3.hasTitle && info.song.name) {
                        id3Writer.setTag('TIT2', info.song.name);
                      }
                      if (Config.id3.hasTrack && info.track.id) {
                        id3Writer.setTag('TRCK', info.track.id);
                      }
                      if (Config.id3.hasYear && info.year) {
                        id3Writer.setTag('TYER', info.year);
                      }
                      if (Config.id3.hasCover && (image = result.coverDownload)) {
                        id3Writer.setTag('APIC', image);
                      }
                      if (Config.id3.hasGenre && info.source.style) {
                        g = genre(info.source.style.split(','));
                        if (g) {
                          id3Writer.setTag('TCON', g);
                        }
                      }
                      if (Config.id3.hasDisc && info.track.disc) {
                        id3Writer.setTag('TPOS', info.track.disc);
                      }
                      if (Config.id3.hasLyric && info.lyric.url) {
                        if (lyric = result.lyricDownload) {
                          id3Writer.setTag('USLT', lyric);
                        }
                        /*
                        										else
                        											fs.exists "#{savePath}.lrc", (exists)->
                        												if exists
                        													fs.readFile "#{savePath}.lrc", (err, lyric)->
                        														if not err
                        															id3Writer.setTag 'USLT', lyric.toString()
                        														id3Writer.write ->
                        															cb err
                        												else
                        													id3Writer.write cb
                        									else
                        										id3Writer.write cb
                        */

                      }
                      return id3Writer.write(cb);
                    } else {
                      return cb(null);
                    }
                  }
                ]),
                fileDownload: common.getValidArray([
                  Config.hasId3 ? 'writeId3Info' : void 0, fileDownload = function(cb) {
                    var req;
                    console.log('fileDownload');
                    req = http.get((function() {
                      if (Config.useProxy === 'true') {
                        return common.mixin(url.parse(location), {
                          agent: tunnel.httpsOverHttp({
                            proxy: {
                              host: Config.proxy.host,
                              port: Config.proxy.port,
                              proxyAuth: "" + Config.proxy.username + ":" + Config.proxy.password
                            }
                          })
                        });
                      } else {
                        return location;
                      }
                    })(), function(res) {
                      var f;
                      switch (res.statusCode) {
                        case 200:
                          f = fs.createWriteStream("" + savePath + ".download", {
                            flags: 'a',
                            encoding: null,
                            mode: 0x1b6
                          });
                          f.on('finish', function() {
                            return fs.rename("" + savePath + ".download", "" + savePath + ".mp3", function() {
                              return cb(null);
                            });
                          });
                          f.on('error', function(err) {
                            console.log(err);
                            return cb(err);
                          });
                          return res.pipe(f);
                        case 302:
                          res.resume();
                          location = res.headers.location;
                          return fileDownload(cb);
                        default:
                          return cb('无法下载');
                      }
                    });
                    return req.on('error', function(err) {
                      return cb(err);
                    });
                  }
                ])
              }, function(err, result) {
                console.log(err, result);
                return cb(err);
              });
            } else {
              return cb(err);
            }
          });
        }
      });
    };
    getInfo = function(item, cb) {
      return async.parallel([
        function(cb) {
          var uri;
          if (item.type === 'album') {
            uri = "http://www.xiami.com/app/android/album?id=" + item.id;
          } else {
            uri = "http://www.xiami.com/song/playlist/id/" + item.id + "/type/" + type[item.type] + "/cat/json";
          }
          return request({
            url: uri,
            json: true,
            proxy: common.getProxyString()
          }, function(error, response, body) {
            var result;
            if (!error && response.statusCode === 200) {
              result = {
                type: item.type,
                id: item.id,
                list: (function() {
                  var albumArtist, albumId, albumName, artistId, artistName, cdCount, discNum, lyricUrl, pictureUrl, song, songId, songName, trackId, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
                  result = [];
                  console.log(body);
                  _ref3 = (_ref = (_ref1 = body.data) != null ? _ref1.trackList : void 0) != null ? _ref : (_ref2 = body.album) != null ? _ref2.songs : void 0;
                  for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
                    song = _ref3[_i];
                    songId = song.song_id;
                    songName = ent.decode((_ref4 = song.name) != null ? _ref4 : song.title);
                    albumId = (_ref5 = song.albumId) != null ? _ref5 : song.album_id;
                    albumName = ent.decode((_ref6 = song.album_name) != null ? _ref6 : song.title);
                    albumArtist = song.artist_name;
                    artistName = ent.decode((_ref7 = song.artist) != null ? _ref7 : song.singers);
                    artistId = song.artist_id;
                    if (((_ref8 = song.lyric) != null ? _ref8.indexOf('.lrc') : void 0) !== -1) {
                      lyricUrl = song.lyric;
                    }
                    pictureUrl = ((_ref9 = song.pic) != null ? _ref9 : song.album_logo).replace(/_\d/, '');
                    trackId = song.track;
                    discNum = song.cd_serial;
                    cdCount = song.cd_count;
                    result.push({
                      'song': {
                        'name': songName,
                        'id': songId
                      },
                      'album': {
                        'name': albumName,
                        'id': albumId,
                        'artist': albumArtist
                      },
                      'artist': {
                        'name': artistName,
                        'id': artistId
                      },
                      'lyric': {
                        'url': lyricUrl
                      },
                      'cover': {
                        'url': pictureUrl
                      },
                      'track': {
                        'disc': discNum,
                        'id': trackId,
                        'cd': cdCount
                      }
                    });
                  }
                  return result;
                })()
              };
              if (item.type !== 'album' && Config.filenameFormat.indexOf('%TRACK%') !== -1) {
                return async.map(result.list, function(item, cb) {
                  var handle, _ref;
                  handle = function(list) {
                    var discNum, song, songId, trackId, _i, _len, _results;
                    _results = [];
                    for (_i = 0, _len = list.length; _i < _len; _i++) {
                      song = list[_i];
                      songId = song.song_id;
                      trackId = song.track;
                      discNum = song.cd_serial;
                      if (songId === item.song.id) {
                        item.track.disc = discNum;
                        item.track.id = trackId;
                        break;
                      } else {
                        _results.push(void 0);
                      }
                    }
                    return _results;
                  };
                  if (_ref = "album" + item.album.id, __indexOf.call(cache, _ref) >= 0) {
                    handle(cache["album" + item.album.id]);
                    return cb(error, item);
                  } else {
                    uri = "http://www.xiami.com/app/android/album?id=" + item.album.id;
                    return request({
                      url: uri,
                      json: true,
                      proxy: common.getProxyString()
                    }, function(error, response, body) {
                      if (!error && response.statusCode === 200) {
                        if (body.album) {
                          cache["album" + item.album.id] = body.album.songs;
                        } else {
                          error = '遭到屏蔽, 暂时无法使用';
                        }
                        handle(cache["album" + item.album.id]);
                      }
                      return cb(error, item);
                    });
                  }
                }, function(err, ret) {
                  return cb(err, result);
                });
              } else {
                return cb(null, result);
              }
            } else {
              return cb(error, {});
            }
          });
        }, function(cb) {
          switch (item.type) {
            case 'album':
              return request("http://www.xiami.com/album/" + item.id, {
                proxy: common.getProxyString()
              }, function(error, response, body) {
                var $, artistInfo, companyInfo, info, languageInfo, name, styleInfo, timeInfo, typeInfo;
                if (!error && response.statusCode === 200) {
                  $ = cheerio.load(body, {
                    ignoreWhitespace: true
                  });
                  name = common.replaceLast($('#title h1').text(), $('#title h1').children().text(), '');
                  info = $('#album_info table tr').toArray();
                  artistInfo = $(info[0]).children().last().text();
                  languageInfo = $(info[1]).children().last().text();
                  companyInfo = $(info[2]).children().last().text();
                  timeInfo = $(info[3]).children().last().text();
                  typeInfo = $(info[4]).children().last().text();
                  styleInfo = $(info[5]).children().last().text();
                  return cb(null, {
                    name: name,
                    artist: artistInfo,
                    language: languageInfo,
                    company: companyInfo,
                    time: timeInfo,
                    style: styleInfo,
                    year: timeInfo.substring(0, 4)
                  });
                }
              });
            case 'showcollect':
              return request("http://www.xiami.com/song/showcollect/id/" + item.id, {
                proxy: common.getProxyString()
              }, function(error, response, body) {
                var $, name;
                if (!error && response.statusCode === 200) {
                  $ = cheerio.load(body, {
                    ignoreWhitespace: true
                  });
                  name = $('#xiami-content h1').text();
                  return cb(null, {
                    name: name
                  });
                }
              });
            case 'artist':
              return request("http://www.xiami.com/artist/" + item.id, {
                proxy: common.getProxyString()
              }, function(error, response, body) {
                var $, name;
                if (!error && response.statusCode === 200) {
                  $ = cheerio.load(body, {
                    ignoreWhitespace: true
                  });
                  name = common.replaceLast($('#title h1').text(), $('#title h1').children().text(), '');
                  return cb(null, {
                    name: name
                  });
                }
              });
            default:
              return cb(null, {});
          }
        }
      ], function(err, result) {
        var id, song, _i, _len, _ref;
        if (!err) {
          result = _.extend.apply(this, result);
          _ref = result.list;
          for (id = _i = 0, _len = _ref.length; _i < _len; id = ++_i) {
            song = _ref[id];
            if (result.type === 'album') {
              song.trackId = id + 1;
            }
            if (result.year) {
              song.year = result.year;
            }
          }
          console.log(result);
          if (result.type === 'song') {
            result.name = result.list[0].song.name;
          }
        }
        return cb(err, result);
      });
    };
    $scope.checkAll = function(i) {
      var task, track, _i, _j, _len, _len1, _ref, _ref1, _results, _results1;
      task = $scope.data[i];
      if (task.checkAll) {
        _ref = $scope.data[i].list;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          track = _ref[_i];
          _results.push($scope.data[i].checked = []);
        }
        return _results;
      } else {
        _ref1 = $scope.data[i].list;
        _results1 = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          track = _ref1[_j];
          _results1.push($scope.data[i].checked = angular.copy(task.list));
        }
        return _results1;
      }
      /*
      		if task.checkAll
      			for track in task.list
      				task.checked = []
      		else
      			for track in task.list
      				task.checked = angular.copy task.list
      */

    };
    $scope.createTask = function() {
      var data, i, result, task, track, _i, _j, _len, _len1, _ref;
      data = angular.copy($scope.data);
      result = [];
      for (i = _i = 0, _len = data.length; _i < _len; i = ++_i) {
        task = data[i];
        if (task.checked && task.checked.length > 0) {
          task.list = task.checked;
          _ref = task.list;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            track = _ref[_j];
            track.source = task;
            track.run = requestFile;
            result.push(track);
          }
        }
      }
      dialog('.dialog .create').hide();
      $scope.step = 1;
      return TaskQueue.push.apply(null, result);
    };
    $scope.check = function(i1, i2) {
      var task;
      task = $scope.data[i1];
      if (!task.list[i2].check) {
        return $scope.data[i1].checkAll = false;
      }
    };
    return $scope.analyze = function() {
      var targets, urls;
      urls = $scope.links.split('\n');
      targets = (function() {
        var isAlbum, isArtist, isShowcollect, isSong, result;
        isArtist = /www.xiami.com\/artist\/(\d+)/;
        isSong = /www.xiami.com\/song\/(\d+)/;
        isShowcollect = /www.xiami.com\/song\/showcollect\/id\/(\d+)/;
        isAlbum = /www.xiami.com\/album\/(\d+)/;
        result = _.map(urls, function(url) {
          var album, artist, showcollect, song;
          artist = isArtist.exec(url);
          song = isSong.exec(url);
          showcollect = isShowcollect.exec(url);
          album = isAlbum.exec(url);
          if (song) {
            return {
              type: 'song',
              id: song[1]
            };
          } else if (album) {
            return {
              type: 'album',
              id: album[1]
            };
          } else if (showcollect) {
            return {
              type: 'showcollect',
              id: showcollect[1]
            };
          } else if (artist) {
            return {
              type: 'artist',
              id: artist[1]
            };
          }
        });
        result = _.filter(result, function(item) {
          return item;
        });
        return result = _.uniq(result, function(item) {
          return JSON.stringify(item);
        });
      })();
      if (targets.length > 0) {
        return async.map(targets, getInfo, function(err, result) {
          if (!err) {
            return $scope.$apply(function() {
              $scope.step = 2;
              $scope.links = '';
              return $scope.data = result;
            });
          } else {
            return console.log(err, result, targets);
          }
        });
      } else {
        return alert('未输入有效的链接');
      }
    };
  });

  App.controller('ExitCtrl', function($scope) {
    $scope.exit = function() {
      var win, _ref;
      win = (_ref = window.win) != null ? _ref : window.win = gui.Window.get();
      return win.close();
    };
    return $scope.hide = function() {
      return dialog('.dialog .exit').hide();
    };
  });

  App.controller('AboutCtrl', function($scope) {
    return $scope.version = pkg.version;
  });

  App.controller('UpdateCtrl', function($scope) {
    return $scope.version = pkg.version;
  });

  App.controller('SetupCtrl', function($scope) {
    return $scope.toggle = function(element) {
      var content, i, _i, _len;
      content = document.querySelectorAll('.dialog .setup ul.content>*');
      for (_i = 0, _len = content.length; _i < _len; _i++) {
        i = content[_i];
        i.style.display = 'none';
      }
      document.querySelector(element).style.display = 'flex';
    };
  });

  App.controller('NetworkCtrl', function($scope, Config) {
    return $scope.config = Config;
  });

  App.controller('Id3Ctrl', function($scope, Config) {
    return $scope.config = Config;
  });

  App.controller('ConfigCtrl', function($scope, Config) {
    $scope.config = Config;
    return $scope.openFolderChooseDialog = function() {
      var fileDialog;
      fileDialog = $("<input type='file' nwdirectory='' nwworkingdir='" + $scope.config.localSavePath + "'/>");
      fileDialog.change(function(e) {
        return $scope.$apply(function() {
          return $scope.config.localSavePath = fileDialog.val();
        });
      });
      fileDialog.click();
    };
  });

  App.controller('LoginCtrl', function($scope, Config, User, $localForage, $sce) {
    var formData, getForm;
    $localForage.get('account').then(function(data) {
      if (data) {
        $scope.email = data.email;
        $scope.password = data.password;
        return $scope.remember = data.remember;
      }
    });
    $scope.logged = false;
    $scope.user = User;
    formData = [];
    getForm = function() {
      return async.waterfall([
        function(cb) {
          return request('https://login.xiami.com/member/login' != null ? 'https://login.xiami.com/member/login' : 'http://www.xiami.com/member/login', {
            proxy: common.getProxyString()
          }, cb);
        }, function(response, body, cb) {
          var $, data, field, fields, img, name, value, _i, _len, _ref, _ref1;
          if (response.statusCode === 200) {
            $ = cheerio.load(body, {
              ignoreWhitespace: true
            });
            $scope.$apply(function() {
              return $scope.taobaoLoginPage = $sce.trustAsResourceUrl(url.resolve(response.request.href, $('iframe').attr('src')));
            });
            fields = $('form input').toArray();
            data = {};
            for (_i = 0, _len = fields.length; _i < _len; _i++) {
              field = fields[_i];
              name = (_ref = $(field).attr('name')) != null ? _ref : '';
              value = (_ref1 = $(field).attr('value')) != null ? _ref1 : '';
              data[name] = value;
            }
            if (data.validate != null) {
              img = fs.createWriteStream('validate.png');
              img.on('finish', function() {
                return cb(null, data);
              });
              return request("https://login.xiami.com/coop/checkcode?forlogin=1&t=" + (Math.random()), {
                proxy: common.getProxyString()
              }).pipe(img);
            } else {
              return cb(null, data);
            }
          } else {
            return cb(null, {});
          }
        }, function(data, cb) {
          if (data.validate != null) {
            $scope.$apply(function() {
              return $scope.validateUrl = "validate.png?" + (Math.random());
            });
          }
          formData = data;
          return cb(null, data);
        }
      ], function(err, result) {
        if (err) {
          return console.log(err, result);
        }
      });
    };
    getForm();
    $scope.logout = function() {
      var i, _i, _len, _ref;
      Config.cookie = '';
      _ref = Object.keys(User);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        delete User[i];
      }
      $scope.logged = false;
      return getForm();
    };
    $scope.sign = function() {
      return request.post('http://www.xiami.com/task/signin', {
        headers: common.mixin(Config.headers, {
          Cookie: Config.cookie,
          Referer: 'http://www.xiami.com/'
        }),
        proxy: common.getProxyString()
      }, function(error, response, body, cb) {
        if (!error) {
          return $scope.$apply(function() {
            User.sign.hasCheck = true;
            return User.sign.num = parseInt(body);
          });
        } else {
          return console.log(error);
        }
      });
    };
    $scope.taobaoPageLoad = function() {
      var iframe, iframeUrl;
      iframe = document.querySelector('iframe');
      iframeUrl = url.parse(iframe.contentDocument.URL);
      if (iframeUrl.href === 'http://www.xiami.com/') {
        return require('nw.gui').Window.get().cookies.getAll({
          domain: '.xiami.com'
        }, function(cookies) {
          Config.cookie = (function() {
            var i, ret, _i, _len;
            ret = '';
            for (_i = 0, _len = cookies.length; _i < _len; _i++) {
              i = cookies[_i];
              ret += "" + i.name + "=" + i.value + "; ";
            }
            return ret;
          })();
          return $scope.$apply(function() {
            $scope.logged = true;
            return async.waterfall([
              function(cb) {
                return request.post('http://www.xiami.com/index/home', {
                  proxy: common.getProxyString(),
                  headers: common.mixin(Config.headers, {
                    Cookie: Config.cookie
                  })
                }, cb);
              }, function(response, body, cb) {
                return cb(null, JSON.parse(body));
              }
            ], function(err, result) {
              if (err) {
                return console.log(err, result);
              } else {
                return $scope.$apply(function() {
                  console.log(result);
                  User.name = result.data.userInfo.nick_name;
                  User.avatar = "http://img.xiami.net/" + result.data.userInfo.avatar;
                  User.id = result.data.userInfo.user_id;
                  User.isVip = !!result.data.userInfo.isVip;
                  User.isMusician = !!result.data.userInfo.isMusician;
                  User.sign = {
                    hasCheck: !!result.data.userInfo.is,
                    num: result.data.userInfo.sign.persist_num
                  };
                  User.level = {
                    name: result.data.userInfo.level,
                    num: result.data.userInfo.numlevel,
                    credit: result.data.userInfo.credits,
                    creditLimit: result.data.userInfo.creditslimit.high
                  };
                  User.pyramid = result.data.pyramid;
                  if (User.isVip) {
                    return request.post('http://www.xiami.com/vip/update-tone', {
                      proxy: common.getProxyString(),
                      headers: common.mixin(Config.headers, {
                        Cookie: Config.cookie,
                        Referer: 'http://www.xiami.com/vip/myvip'
                      }),
                      form: {
                        user_id: User.id,
                        tone_type: 1
                      }
                    });
                  }
                });
              }
            });
          });
        });
      }
    };
    return $scope.login = function() {
      formData['email'] = $scope.email;
      formData['password'] = $scope.password;
      if ($scope.validateUrl) {
        formData['validate'] = $scope.validate;
      }
      if ($scope.remember) {
        $localForage.setItem('account', {
          email: $scope.email,
          password: $scope.password,
          remember: $scope.remember
        }).then();
      } else {
        $scope.email = $scope.password = '';
        $localForage.removeItem('account').then();
      }
      $scope.validate = '';
      return async.series([
        function(cb) {
          return async.waterfall([
            function(cb) {
              return request.post('http://www.xiami.com/member/login' != null ? 'http://www.xiami.com/member/login' : 'https://login.xiami.com/member/login', {
                form: formData,
                proxy: common.getProxyString(),
                headers: common.mixin(Config.headers, {
                  'Referer': 'http://www.xiami.com/member/login' != null ? 'http://www.xiami.com/member/login' : 'https://login.xiami.com/member/login',
                  'Host': 'www.xiami.com' != null ? 'www.xiami.com' : 'login.xiami.com',
                  'Origin': 'http://www.xiami.com' != null ? 'http://www.xiami.com' : 'https://login.xiami.com'
                })
              }, cb);
            }, function(response, body, cb) {
              var _ref;
              if (fs.existsSync('validate.png')) {
                fs.unlinkSync('validate.png');
              }
              return cb(null, (_ref = response.headers['set-cookie']) != null ? _ref.toString() : void 0);
            }
          ], function(err, result) {
            if (err) {
              console.log(err, result);
              return cb();
            } else {
              Config.cookie = result;
              return $scope.$apply(function() {
                $scope.logged = true;
                return cb();
              });
            }
          });
        }, function(cb) {
          return async.waterfall([
            function(cb) {
              return request.post('http://www.xiami.com/index/home', {
                proxy: common.getProxyString(),
                headers: common.mixin(Config.headers, {
                  Cookie: Config.cookie
                })
              }, cb);
            }, function(response, body, cb) {
              return cb(null, JSON.parse(body));
            }
          ], function(err, result) {
            if (err) {
              console.log(err, result);
              return cb();
            } else {
              return $scope.$apply(function() {
                User.name = result.data.userInfo.nick_name;
                User.avatar = "http://img.xiami.net/" + result.data.userInfo.avatar;
                User.id = result.data.userInfo.user_id;
                User.isVip = !!result.data.userInfo.isVip;
                User.isMusician = !!result.data.userInfo.isMusician;
                User.sign = {
                  hasCheck: !!result.data.userInfo.is,
                  num: result.data.userInfo.sign.persist_num
                };
                User.level = {
                  name: result.data.userInfo.level,
                  num: result.data.userInfo.numlevel,
                  credit: result.data.userInfo.credits,
                  creditLimit: result.data.userInfo.creditslimit.high
                };
                User.pyramid = result.data.pyramid;
                return cb();
              });
            }
          });
        }
      ], function(err, result) {
        if (User.isVip) {
          return request.post('http://www.xiami.com/vip/update-tone', {
            proxy: common.getProxyString(),
            headers: common.mixin(Config.headers, {
              Cookie: Config.cookie,
              Referer: 'http://www.xiami.com/vip/myvip'
            }),
            form: {
              user_id: User.id,
              tone_type: 1
            }
          });
        }
      });
    };
  });

}).call(this);
