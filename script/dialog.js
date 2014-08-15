(function() {
  'use strict';
  var async, cheerio, common, cookie, ent, fs, genre, gui, http, https, id3v23, mkdirp, os, path, pkg, timers, tunnel, url, validator,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  gui = require('nw.gui');

  pkg = require('./package');

  async = require('async');

  os = require('os');

  http = require('http');

  https = require('https');

  common = require('./script/common');


  /*
  request = (require 'request').defaults
      jar: true
      headers: common.config.headers
      followAllRedirects: false
      strictSSL: false
      proxy: false
   */

  cheerio = require('cheerio');

  cookie = require('cookie');

  tunnel = require('tunnel');

  fs = require('fs');

  url = require('url');

  path = require('path');

  timers = require('timers');

  mkdirp = require('mkdirp');

  ent = require('ent');

  id3v23 = require('./script/id3v2').id3v23;

  genre = require('./script/genre');

  validator = require('validator');

  http.globalAgent.maxSockets = Infinity;

  App.factory('Config', function() {
    return common.config;
  });

  App.controller('CreateCtrl', function($scope, $interval, TaskQueue, Config, User) {
    var cache, clipboardText, getInfo, getLocation, monitoringClipboard, requestFile, startMonitoringClipboard, type;
    type = {
      song: 0,
      album: 1,
      artist: 2,
      collect: 3
    };
    cache = {};
    $scope.type = type;
    $scope.step = 1;
    $scope.links = '';
    $scope.data = [];
    monitoringClipboard = null;
    clipboardText = clipboard.get('text');
    startMonitoringClipboard = function() {
      return monitoringClipboard = $interval(function() {
        var album, artist, collect, lastChar, showcollect, song, text;
        text = clipboard.get('text');
        if (text === clipboardText) {
          return;
        } else {
          clipboardText = text;
        }
        if (validator.isURL(text) && url.parse(text).hostname === 'www.xiami.com') {
          artist = common.isArtist.exec(text);
          song = common.isSong.exec(text);
          collect = common.isCollect.exec(text);
          showcollect = common.isShowcollect.exec(text);
          album = common.isAlbum.exec(text);
          if (artist || song || collect || showcollect || album) {
            lastChar = common.index($scope.links, -1);
            if ((lastChar === '\n') || (!lastChar)) {
              return $scope.links += text + '\n';
            } else {
              return $scope.links += '\n' + text;
            }
          }
        }
      }, 1000);
    };
    if (Config.useMonitoringClipboard) {
      startMonitoringClipboard();
    }
    $scope.$watch(function() {
      return Config.useMonitoringClipboard;
    }, function(newValue, oldValue) {
      if (newValue !== oldValue) {
        if (newValue) {
          return startMonitoringClipboard();
        } else {
          return $interval.cancel(monitoringClipboard);
        }
      }
    });
    $scope.pasteHandle = function() {
      return _.defer(function() {
        var editor, part1, part2, selEnd, selStart;
        editor = document.querySelector('textarea.links');
        selStart = editor.selectionStart;
        selEnd = editor.selectionEnd;
        part1 = editor.value.slice(0, selStart);
        part2 = editor.value.slice(selEnd);
        editor.value = part1 + '\n' + part2;
        return editor.setSelectionRange(selEnd + 1, selEnd + 1);
      });
    };
    $scope.popupMenuEditor = function($event) {
      var menu, menuItem;
      menu = new gui.Menu;
      menuItem = function(options) {
        return new gui.MenuItem(options);
      };
      menu.append(menuItem({
        type: 'normal',
        label: '剪切',
        click: function() {
          return document.execCommand('cut');
        }
      }));
      menu.append(menuItem({
        type: 'normal',
        label: '复制',
        click: function() {
          return document.execCommand('copy');
        }
      }));
      menu.append(menuItem({
        type: 'normal',
        label: '粘贴',
        click: function() {
          return document.execCommand('paste');
        }
      }));
      if (os.platform() === 'drawin' && version[1] >= 10) {
        menu.createMacBuiltin('xiami-thief');
      }
      return menu.popup($event.clientX, $event.clientY);
    };
    getLocation = function(sid, cb) {
      if (true || User.logged) {
        return common.get("http://www.xiami.com/song/gethqsong/sid/" + sid, {
          'Content-Type': 'application/json'
        }, function(error, response, body) {
          var location;
          if (!error && response.statusCode === 200) {
            if (body.location != null) {
              location = common.parseLocation(body.location);
              if (location) {
                return cb(null, location.trim());
              } else {
                return cb(location);
              }
            } else {
              return cb(body);
            }
          } else {
            return cb(error, '');
          }
        });

        /*
        request
            url: "http://www.xiami.com/song/gethqsong/sid/#{sid}"
            json: 'body'
            jar: true
            headers:
                common.mixin Config.headers,
                    'Content-Type': 'application/json'
                    'Cookie': Config.cookie
                    'Referer': 'http://www.xiami.com'
            proxy: common.getProxyString()
            , (error, response, body)->
                 * console.log response
                if not error and response.statusCode is 200
                    if body.location?
                        location = common.parseLocation body.location
                        if location
                             * console.log location
                            cb null, location.trim()
                        else
                            cb location
                    else
                        cb body
                else
                    cb error, ''
         */
      } else {
        return console.error('not login');
      }
    };
    requestFile = function(cb) {
      var filename, info, pathFolder;
      info = this;
      pathFolder = info.save.path;
      filename = info.save.name;
      return mkdirp(pathFolder, function(err) {
        var coverDownload, fileDownload, lyricDownload, resizeImage, savePath, writeId3Info;
        if (!err) {
          savePath = path.resolve(pathFolder, filename);
          coverDownload = function(cb) {
            var coverPath;
            coverPath = path.resolve(pathFolder, "" + info.album.id + ".jpg");
            if (Config.hasCover) {
              return fs.exists(coverPath, function(exists) {
                var f, req;
                if (exists) {
                  return cb(null);
                } else {
                  f = fs.createWriteStream(coverPath);
                  f.on('finish', function() {
                    return cb(null);
                  });
                  f.on('error', function(err) {
                    return cb(err);
                  });
                  req = common.getReq(info.cover.url, {
                    'Host': 'img.xiami.net',
                    'Origin': 'http://img.xiami.net'
                  }, function() {});

                  /*
                  req = request info.cover.url,
                      jar: false
                      headers: {}
                      proxy: common.getProxyString()
                   */
                  return req.pipe(f);
                }
              });
            } else {
              return cb(null);
            }

            /*
            if Config.hasCover or (Config.hasId3 and Config.id3.hasCover)
                console.log 'coverDownload is true'
                fs.exists coverPath, (exists)->
                    if exists
                        if Config.hasId3 and Config.id3.hasCover
                            if Config.id3.cover.size is 'original'
                                fs.readFile coverPath, cb
                            else
                                resizeImage info.cover.url
                                 *resizeImage coverPath
                        else
                            cb null
                    else
                        if Config.hasCover
                            f = fs.createWriteStream coverPath
                            f.on 'finish', ->
                                if Config.hasId3 and Config.id3.hasCover
                                    if Config.id3.cover.size is 'original'
                                        fs.readFile coverPath, cb
                                    else
                                        resizeImage info.cover.url
                                         *resizeImage coverPath
                                else
                                    cb null
                            f.on 'error', (err)->
                                cb err
                            request(info.cover.url,
                                jar: false
                                headers: {}
                                proxy: common.getProxyString()
                            ).pipe f
                        else
                            resizeImage info.cover.url
            else
                cb null
             */
          };
          resizeImage = function(cb) {
            var image, imagePath, maxSide;
            console.log(Config.hasId3 && Config.id3.hasCover);
            if (Config.hasId3 && Config.id3.hasCover) {
              imagePath = info.cover.url;
              maxSide = Config.id3.size === 'standard' ? 640 : Config.id3.cover.maxSide;
              image = new Image;
              image.addEventListener('load', function(e) {
                var canvas, ctx, data, height, width, _ref;
                console.log('load');
                canvas = document.createElement('canvas');
                ctx = canvas.getContext('2d');
                width = image.width;
                height = image.height;
                if (height < maxSide && width < maxSide) {

                  /*
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
                   */
                  canvas.height = image.height;
                  canvas.width = image.width;
                } else if (height > width) {
                  canvas.height = maxSide;
                  canvas.width = maxSide / height * width;
                } else {
                  canvas.width = maxSide;
                  canvas.height = maxSide / width * height;
                }
                ctx.drawImage(image, 0, 0, image.width, image.height, 0, 0, canvas.width, canvas.height);
                data = (_ref = canvas.toDataURL('image/jpeg')) != null ? _ref.replace('data:image/jpeg;base64,', '') : void 0;
                console.log(data);
                return cb(err, new Buffer(data, 'base64'));
              });
              image.addEventListener('error', function(e) {
                console.error(e);
                return cb(e != null ? e : 'Image Load: Error');
              });
              image.addEventListener('abort', function(e) {
                console.error(e);
                return cb(e != null ? e : 'Image Load: Abort');
              });
              image.src = imagePath.slice(0, 4) === 'http' ? imagePath : "file:///" + imagePath;
              return console.log(image.src);
            } else {
              return cb(null);
            }
          };

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
          lyricDownload = function(cb) {
            var f, req;
            if ((Config.hasLyric || (Config.hasId3 && Config.id3.hasLyric)) && info.lyric.url) {
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
                req = common.get(info.lyric.url);
                return req.pipe(f);

                /*
                request(info.lyric.url,
                    jar: false
                    headers: {}
                    proxy: common.getProxyString()
                ).pipe f
                 */
              } else {
                return common.get(info.lyric.url, function(error, response, body) {
                  return cb(error, body);
                });

                /*
                request info.lyric.url,
                    jar: false
                    headers: {}
                    proxy: common.getProxyString()
                    , (error, response, body)->
                        cb error, body
                 */
              }
            } else {
              return cb(null);
            }
          };
          writeId3Info = function(cb, result) {
            var g, id3Writer, image, lyric;
            console.log(result);
            if (Config.hasId3) {
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
                console.log(info.song.name, new Buffer(info.song.name));

                /*
                iconv = require 'iconv-lite'
                t = iconv.decode info.song.name, 'utf8'
                t = iconv.encode info.song.name, 'ucs2'
                console.log t, t.toString()
                 */
                id3Writer.setTag('TIT2', info.song.name);
              }
              console.log(info);
              console.log(info.track.id, Config.id3.hasTrack);
              if (Config.id3.hasTrack && info.track.id) {
                id3Writer.setTag('TRCK', info.track.id);
              }
              if (Config.id3.hasYear && info.source.year) {
                id3Writer.setTag('TYER', info.source.year);
              }
              console.log(Config.id3.hasCover, result.resizeImage);
              if (Config.id3.hasCover && (image = result.resizeImage)) {
                console.log('APIC', image);
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
          };
          fileDownload = function(cb, result) {
            return getLocation(info.song.id, function(err, location) {
              var id3Size, _ref;
              if (!err && location) {
                id3Size = (_ref = result.writeId3Info) != null ? _ref : 0;
                return fs.exists("" + savePath + ".mp3", function(exists) {
                  var download;
                  download = function() {
                    var req;
                    info.url.hq = location;
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
                      var contentLength, transportStream;
                      switch (res.statusCode) {
                        case 200:
                          contentLength = Number(res.headers['content-length']);
                          transportStream = function() {
                            var check, f;
                            f = fs.createWriteStream("" + savePath + ".download", {
                              flags: 'a',
                              encoding: null,
                              mode: 0x1b6
                            });
                            f.on('finish', function() {
                              return fs.rename("" + savePath + ".download", "" + savePath + ".mp3", function() {
                                var _base;
                                window.count++;
                                if (typeof (_base = window.win).setBadgeLabel === "function") {
                                  _base.setBadgeLabel(window.count);
                                }
                                return $scope.$apply(function() {
                                  return cb(null);
                                });
                              });
                            });
                            f.on('error', function(err) {
                              console.error(err);
                              return cb(err);
                            });
                            check = (function(timeout) {
                              var count, lastBytes;
                              count = 0;
                              lastBytes = 0;
                              return function() {
                                var nowBytes;
                                nowBytes = f.bytesWritten;
                                $scope.$apply(function() {
                                  return info.process = nowBytes / contentLength * 100;
                                });
                                if (info.process >= 100) {
                                  return f.end();
                                } else {
                                  if (lastBytes === nowBytes) {
                                    count++;
                                  } else {
                                    count = 0;
                                  }
                                  if (count > 60) {
                                    return f.emit('error', new Error('下载被阻断'));
                                  } else {
                                    return timers.setTimeout(check, timeout);
                                  }
                                }
                              };
                            })(1000);
                            check();
                            return res.pipe(f);
                          };
                          if (exists) {
                            return fs.stat("" + savePath + ".mp3", function(err, stat) {
                              if (err) {
                                return cb(err);
                              } else {
                                if (stat.size >= contentLength + id3Size) {
                                  return fs.unlink("" + savePath + ".download", function(err) {
                                    if (err) {
                                      return cb(err);
                                    } else {
                                      return cb(new Error('文件已存在'));
                                    }
                                  });
                                } else {
                                  return transportStream();
                                }
                              }
                            });
                          } else {
                            return transportStream();
                          }
                          break;
                        case 302:
                          res.resume();
                          location = res.headers.location;
                          return download();
                        default:
                          return cb('无法下载');
                      }
                    });
                    return req.on('error', function(err) {
                      return cb(err);
                    });
                  };
                  return download();
                });
              } else {
                return cb(err, location);
              }
            });
          };
          return async.auto({
            'coverDownload': coverDownload,
            'resizeImage': resizeImage,
            'lyricDownload': lyricDownload,
            'writeId3Info': common.getValidArray([Config.id3.hasCover ? 'resizeImage' : void 0, Config.id3.hasLyric ? 'lyricDownload' : void 0, writeId3Info]),
            'fileDownload': common.getValidArray([Config.hasId3 ? 'writeId3Info' : void 0, fileDownload])
          }, function(err, result) {
            if (err) {
              console.error(err, result);
            }
            return cb(err);
          });
        } else {
          return cb(err);
        }
      });
    };
    getInfo = function(item, cb) {
      var getInfoFromAPI, getInfoFromHTML, getTrackFromHTML, parseAlbumFromHTML, parseInfoFromAPI, parseTrackFromHTML;
      parseInfoFromAPI = function(song) {
        var albumArtist, albumId, albumName, artistId, artistName, cdCount, discNum, lqUrl, lyricUrl, pictureUrl, songId, songName, trackId, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
        songId = song.song_id;
        songName = ent.decode((_ref = song.name) != null ? _ref : song.title);
        albumId = (_ref1 = song.albumId) != null ? _ref1 : song.album_id;
        albumName = ent.decode((_ref2 = song.album_name) != null ? _ref2 : song.title);
        albumArtist = song.artist_name;
        artistName = ent.decode((_ref3 = song.artist) != null ? _ref3 : song.singers);
        artistId = song.artist_id;
        if (((_ref4 = song.lyric) != null ? _ref4.indexOf('.lrc') : void 0) !== -1) {
          lyricUrl = song.lyric;
        }
        pictureUrl = (_ref5 = (_ref6 = song.pic) != null ? _ref6 : song.album_logo) != null ? _ref5.replace(/_\d.jpg/, '.jpg') : void 0;
        trackId = song.track;
        discNum = song.cd_serial;
        cdCount = song.cd_count;
        if (song.location != null) {
          lqUrl = common.parseLocation(song.location);
        }
        return {
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
          },
          'url': {
            'lq': lqUrl,
            'hq': lqUrl
          }
        };
      };
      getInfoFromAPI = function(cb) {
        var uri;
        switch (item.type) {
          case 'user':
            return cb(null, {});
          case 'playlist':
            uri = 'http://www.xiami.com/song/playlist-default/cat/json';

            /*
                            when 'album'
            uri = "http://www.xiami.com/app/android/album?id=#{item.id}" # android api only for track
             */

            /*
                            when 'collect'
            uri = "http://www.xiami.com/app/android/collect?id=#{item.id}" # android api only for title
             */
            break;
          default:
            uri = "http://www.xiami.com/song/playlist/id/" + item.id + "/type/" + type[item.type] + "/cat/json";
        }

        /*
        request
            url: uri
            json: true
            proxy: common.getProxyString()
            , (error, response, body)->
         */
        return common.get(uri, function(error, response, body) {
          var result;
          if (!error && response.statusCode === 200) {
            result = {
              type: item.type,
              id: item.id,
              list: (function() {
                var song, trackList, _i, _len, _ref, _ref1, _ref2;
                result = [];
                if (trackList = (_ref = body != null ? (_ref1 = body.data) != null ? _ref1.trackList : void 0 : void 0) != null ? _ref : body != null ? (_ref2 = body.album) != null ? _ref2.songs : void 0 : void 0) {
                  for (_i = 0, _len = trackList.length; _i < _len; _i++) {
                    song = trackList[_i];
                    result.push(parseInfoFromAPI(song));
                  }
                }
                return result;
              })()
            };

            /*
            if item.type isnt 'album' and
                (
                    common.inStr(Config.filenameFormat, '%TRACK%') or
                    (Config.saveMode isnt 'direct') or
                    (Config.hasId3 and (Config.id3.hasTrack or Config.id3.hasDisc))
                )
             */
            return cb(null, result);
          } else {
            return cb(error, {});
          }
        });
      };
      parseAlbumFromHTML = function(html) {
        var $, children, i, info, infoEle, key, name, pictureUrl, value, _i, _len, _ref, _ref1;
        $ = cheerio.load(html, {
          ignoreWhitespace: true
        });
        name = common.replaceLast($('#title h1').text(), $('#title h1').children().text(), '');
        pictureUrl = (_ref = $('#album_cover a img').attr('src')) != null ? _ref.replace(/_\d\.jpg/, '.jpg') : void 0;
        infoEle = $('#album_info table tr').toArray();
        info = {};
        for (_i = 0, _len = infoEle.length; _i < _len; _i++) {
          i = infoEle[_i];
          children = $(i).children();
          key = $(children[0]).text().slice(0, -1);
          value = $(children[1]).text();
          info[key] = value;
        }
        return {
          'name': name,
          'artist': info['艺人'],
          'language': info['语种'],
          'company': info['唱片公司'],
          'time': info['发行时间'],
          'style': info['专辑风格'],
          'year': (_ref1 = info['发行时间']) != null ? _ref1.slice(0, 4) : void 0,
          'cover': {
            'url': pictureUrl
          }
        };
      };
      parseTrackFromHTML = function(html) {
        var $, cdCount, cdSerial, result, songId, table, tr, trackId, trackList, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3, _ref4;
        $ = cheerio.load(html, {
          ignoreWhitespace: true
        });
        result = [];
        trackList = $('.chapter .track_list');
        cdCount = trackList.length;
        cdSerial = 1;
        for (_i = 0, _len = trackList.length; _i < _len; _i++) {
          table = trackList[_i];
          _ref = $(table).find('tr');
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            tr = _ref[_j];
            trackId = (_ref1 = $(tr).find('.trackid')) != null ? _ref1.text() : void 0;
            songId = (_ref2 = $(tr).find('.song_name a')) != null ? (_ref3 = _ref2.attr('href')) != null ? (_ref4 = _ref3.match(/song\/(\d+)/)) != null ? _ref4[1] : void 0 : void 0 : void 0;
            result.push({
              'song_id': songId,
              'track': Number(trackId).toString(),
              'cd_serial': cdSerial.toString(),
              'cd_count': cdCount.toString()
            });
          }
        }
        return result;
      };
      getTrackFromHTML = function(result, cb) {
        if (common.inStr(Config.filenameFormat, '%TRACK%') || (Config.saveMode !== 'direct') || (Config.hasId3 && (Config.id3.hasTrack || Config.id3.hasDisc))) {
          return async.map(result.list, function(item, cb) {
            var getTrack, handle, uri, _ref;
            handle = function(info) {
              var cdCount, discNum, song, songId, trackId, _i, _len, _ref, _results;
              _ref = info.list;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                song = _ref[_i];
                songId = song.song_id;
                trackId = song.track;
                discNum = song.cd_serial;
                cdCount = song.cd_count;
                if (songId === item.song.id) {
                  if (!item.album.artist) {
                    item.album.artist = info.artist;
                  }
                  item.track.disc = discNum;
                  item.track.id = trackId;
                  item.track.cd = cdCount;
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
              uri = "http://www.xiami.com/album/" + item.album.id;

              /*
              request
                  url: uri,
                  json: true
                  proxy: common.getProxyString()
                  ,(error, response, body)->
               */
              getTrack = function() {
                getTrack.count++;
                if (getTrack.count > 3) {
                  cb(new Error('遭到屏蔽, 暂时无法使用'));
                  return;
                }
                return common.get(uri, function(error, response, body) {
                  var albumInfo;
                  if (!error && response.statusCode === 200) {
                    albumInfo = parseAlbumFromHTML(body);
                    cache["album" + item.album.id] = {
                      'list': parseTrackFromHTML(body)
                    };
                    common.extend(cache["album" + item.album.id], albumInfo);
                    console.log(cache["album" + item.album.id]);
                    handle(cache["album" + item.album.id]);
                    return cb(error, item);
                  } else {
                    return getTrack();
                  }
                });
              };
              getTrack.count = 0;
              return getTrack();
            }
          }, function(err, ret) {
            return cb(err, result);
          });
        } else {
          return cb(null, result);
        }
      };
      getInfoFromHTML = function(cb) {
        var i, urls;
        switch (item.type) {
          case 'user':
            urls = (function() {
              var _i, _ref, _ref1, _results;
              _results = [];
              for (i = _i = _ref = item.start, _ref1 = item.end; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; i = _ref <= _ref1 ? ++_i : --_i) {
                _results.push("http://www.xiami.com/space/lib-song/u/" + item.id + "/page/" + i);
              }
              return _results;
            })();
            console.log(urls);
            return async.map(urls, function(uri, cb) {
              console.log(uri);
              return common.get(uri, function(error, response, body) {
                var $, songs;
                if (!error && response.statusCode === 200) {
                  $ = cheerio.load(body, {
                    ignoreWhitespace: true
                  });
                  songs = (function() {
                    var _i, _len, _ref, _results;
                    _ref = $('a[href^="http://www.xiami.com/song/"]');
                    _results = [];
                    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                      i = _ref[_i];
                      _results.push($(i).attr('href').match(/song\/(\d+)/)[1]);
                    }
                    return _results;
                  })();
                  return cb(null, songs);
                } else {
                  return cb(error);
                }
              });
            }, function(err, songs) {
              if (_.isArray(songs[0])) {
                songs = _.extend.apply(this, songs);
              }
              return async.map(songs, function(songId, cb) {
                return common.get("http://www.xiami.com/song/playlist/id/" + songId + "/type/" + type['song'] + "/cat/json", function(error, response, body) {
                  var song, trackList, _i, _len, _ref, _ref1, _ref2, _results;
                  if (!error && response.statusCode === 200) {
                    console.log(body);
                    if (trackList = (_ref = body != null ? (_ref1 = body.data) != null ? _ref1.trackList : void 0 : void 0) != null ? _ref : body != null ? (_ref2 = body.album) != null ? _ref2.songs : void 0 : void 0) {
                      _results = [];
                      for (_i = 0, _len = trackList.length; _i < _len; _i++) {
                        song = trackList[_i];
                        _results.push(cb(null, parseInfoFromAPI(song)));
                      }
                      return _results;
                    } else {
                      return cb(null, void 0);
                    }
                  } else {
                    return cb(error);
                  }
                });
              }, function(err, list) {
                var result;
                result = {
                  'name': "用户" + item.id + "的第" + item.start + "到" + item.end + "页收藏",
                  'type': item.type,
                  'id': item.id,
                  'start': item.start,
                  'end': item.end,
                  'list': list
                };
                console.log(result, err, 'when user');
                return cb(err, result);
              });
            });
          case 'album':

            /*
            request "http://www.xiami.com/album/#{item.id}", proxy: common.getProxyString(), (error, response, body) ->
             */

            /*
            if item.language or item.company or item.time or item.style or item.year
                return cb null, {}
             */
            return common.get("http://www.xiami.com/album/" + item.id, function(error, response, body) {
              if (!error && response.statusCode === 200) {
                return cb(null, parseAlbumFromHTML(body));
              }
            });
          case 'collect':

            /*
            //request "http://www.xiami.com/song/collect/id/#{item.id}", proxy: common.getProxyString(), (error, response, body)->
            
            common.get "http://www.xiami.com/collect/#{item.id}", (error, response, body)->
                if not error and response.statusCode is 200
                    $ = cheerio.load body, ignoreWhitespace:true
                    name = $('#xiami-content h1').text()
                    pictureUrl = $('#cover_logo a img').attr('src')?.replace(/_\d\.jpg/, '.jpg')# 从小图Url获得大图Url
                    cb null,
                        'name': name
                        'cover': 
                            'url': pictureUrl
             */
            return common.get("http://www.xiami.com/app/android/collect?id=" + item.id, function(error, response, body) {
              var name, pictureUrl;
              name = body.collect.name;
              pictureUrl = body.collect.logo.replace(/_\d\.jpg/, '.jpg');
              return cb(null, {
                'name': name,
                'cover': {
                  'url': pictureUrl
                }
              });
            });
          case 'artist':

            /*
            request "http://www.xiami.com/artist/#{item.id}", proxy: common.getProxyString(), (error, response, body)->
             */
            return common.get("http://www.xiami.com/artist/" + item.id, function(error, response, body) {
              var $, name, pictureUrl, _ref;
              if (!error && response.statusCode === 200) {
                $ = cheerio.load(body, {
                  ignoreWhitespace: true
                });
                name = common.replaceLast($('#title h1').text(), $('#title h1').children().text(), '');
                pictureUrl = (_ref = $('#artist_photo a img').attr('src')) != null ? _ref.replace(/_\d\.jpg/, '.jpg') : void 0;
                return cb(null, {
                  'name': name,
                  'cover': {
                    'url': pictureUrl
                  }
                });
              }
            });
          case 'playlist':
            return cb(null, {
              'name': '播放列表' + item.id
            });
          default:
            return cb(null, {});
        }
      };
      return async.parallel([getInfoFromAPI, getInfoFromHTML], function(err, result) {
        var id, song, _i, _len, _ref;
        if (!err) {
          result = _.extend.apply(this, result);
          _ref = result.list;
          for (id = _i = 0, _len = _ref.length; _i < _len; id = ++_i) {
            song = _ref[id];
            if (result.year) {
              song.year = result.year;
            }
          }
          if (result.type === 'song') {
            result.name = result.list[0].song.name;
            result.cover = result.list[0].cover;
          }
          return getTrackFromHTML(result, cb);
        } else {
          return cb(err, result);
        }
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
          delete task.checked;
          _ref = task.list;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            track = _ref[_j];
            track.source = task;
            track.run = requestFile;
            track.save = (function(info) {
              var filename, foldername, pathFolder, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
              filename = common.replaceBat(Config.filenameFormat, ['%NAME%', info.song.name], ['%ARTIST%', info.artist.name], ['%ALBUM%', info.album.name], ['%TRACK%', info.track.id != null ? (info.track.id.length === 1 ? "0" + info.track.id : info.track.id) : ''], ['%DISC%', (_ref1 = info.track.disc) != null ? _ref1 : '']);
              filename = common.getSafeFilename(filename);
              switch (Config.saveMode) {
                case 'smartClassification':
                  switch (info.source.type) {
                    case 'album':
                      foldername = common.replaceBat(Config.foldernameFormat, ['%NAME%', common.safePath((_ref2 = info.source.name) != null ? _ref2 : '')], ['%ARTIST%', common.safePath((_ref3 = info.source.artist) != null ? _ref3 : '')], ['%COMPANY%', common.safePath((_ref4 = info.source.company) != null ? _ref4 : '')], ['%TIME%', common.safePath((_ref5 = info.source.time) != null ? _ref5 : '')], ['%LANGUAGE%', common.safePath((_ref6 = info.source.language) != null ? _ref6 : '')]);
                      break;
                    case 'artist':
                      foldername = common.safePath(info.source.name);
                      break;
                    case 'collect':
                      foldername = common.safePath(info.source.name);
                      break;
                    case 'user':
                      foldername = common.safePath(info.source.name);
                      break;
                    case '':
                      break;
                    default:
                      foldername = '';
                  }
                  foldername = common.getSafeFoldername(foldername);
                  break;
                case 'alwaysClassification':
                  foldername = common.replaceBat('%ARTIST%/%NAME%', ['%NAME%', common.safePath((_ref7 = info.album.name) != null ? _ref7 : '')], ['%ARTIST%', common.safePath((_ref8 = info.artist.name) != null ? _ref8 : '')]);
                  break;
                case 'direct':
                  break;
                default:
                  foldername = '';
              }
              if ((info.source.type === 'album' || Config.saveMode === 'alwaysClassification') && Number(info.track.cd) > 1) {
                pathFolder = path.resolve(Config.savePath, foldername, "disc " + info.track.disc);
              } else {
                pathFolder = path.resolve(Config.savePath, foldername);
              }
              return {
                'path': pathFolder,
                'name': filename
              };
            })(track);
          }
          result.push(task);
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
      var links, targets;
      console.log('analyze1');
      links = $scope.links.split('\n');
      targets = (function() {
        var result;
        console.log('analyze2');
        result = _.map(links, function(text) {
          var album, artist, collect, playlist, showcollect, song, user, _ref;
          if (validator.isURL(text)) {
            artist = common.isArtist.exec(text);
            song = common.isSong.exec(text);
            collect = common.isCollect.exec(text);
            showcollect = common.isShowcollect.exec(text);
            album = common.isAlbum.exec(text);
            user = common.isUser.exec(text);
            playlist = common.isPlaylist.exec(text);
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
            } else if (collect) {
              return {
                type: 'collect',
                id: collect[1]
              };
            } else if (showcollect) {
              return {
                type: 'collect',
                id: showcollect[1]
              };
            } else if (artist) {
              return {
                type: 'artist',
                id: artist[1]
              };
            } else if (user) {
              return {
                type: 'user',
                id: user[1],
                start: Number(user[2]),
                end: Number((_ref = user[3]) != null ? _ref : user[2])
              };
            } else if (playlist && User.logged) {
              return {
                type: 'playlist',
                id: new Date().getTime()
              };
            }
          }
        });
        result = _.filter(result, function(item) {
          return item;
        });
        return result = _.uniq(result, function(item) {
          return JSON.stringify(item);
        });
      })();
      console.log('analyze3', targets);
      if (targets.length > 0) {
        return async.map(targets, getInfo, function(err, result) {
          if (!err) {
            return $scope.$apply(function() {
              var i, _results;
              $scope.step = 2;
              $scope.links = '';
              $scope.data = result;
              i = $scope.data.length;
              console.log($scope.data, i);
              _results = [];
              while (i--) {
                $scope.checkAll(i);
                _results.push($scope.data[i].checkAll = true);
              }
              return _results;
            });
          } else {
            return console.error(err, result, targets);
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

  App.controller('SetupCtrl', function($scope, User) {
    return $scope.toggle = function(element) {
      var content, i, _i, _len;
      content = document.querySelectorAll('.dialog .setup ul.content>*');
      for (_i = 0, _len = content.length; _i < _len; _i++) {
        i = content[_i];
        i.style.display = 'none';
      }
      document.querySelector(element).style.display = 'flex';

      /*
      if element is 'li.login' and not User.logged
          $scope.loginPageLoad()
       */
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
          return $scope.config.savePath = fileDialog.val();
        });
      });
      fileDialog.click();
    };
  });

  App.controller('LoginCtrl', function($scope, Config, User, $localForage, $sce) {
    var formData, setLogged;
    $localForage.get('account').then(function(data) {
      if (data) {
        $scope.email = data.email;
        $scope.password = data.password;
        return $scope.remember = data.remember;
      }
    });
    $scope.user = User;
    $scope.user.logged = false;
    formData = [];
    setLogged = function(cb) {
      var pCookieSaved;
      pCookieSaved = Promise.all([$localForage.setItem('config.jar', Config.jar), $localForage.setItem('config.cookie', Config.cookie)]);
      console.log(Config.jar, Config.cookie);
      return pCookieSaved.then(function() {
        return async.waterfall([
          function(cb) {
            return common.post('http://www.xiami.com/index/home', cb);
          }, function(response, body, cb) {
            console.log(response);
            return cb(null, body);
          }
        ], function(err, result) {
          if (err) {
            return console.error(err, result);
          } else {
            return $scope.$apply(function() {
              var _ref, _ref1;
              if (((_ref = result.data) != null ? (_ref1 = _ref.userInfo) != null ? _ref1.user_id : void 0 : void 0) != null) {
                console.log(result);
                User.logged = true;
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
                  return common.post('http://www.xiami.com/vip/update-tone', {
                    user_id: User.id,
                    tone_type: 1
                  }, {
                    Referer: 'http://www.xiami.com/vip/myvip'
                  }, null);
                }
              } else {
                console.log('登录失败, 你所在的国家或地区可能无法使用虾米音乐网, 请开通VIP后再试.');
                return console.error(result);
              }
            });
          }
        });

        /*
        request.post 'http://www.xiami.com/vip/update-tone',
            proxy: common.getProxyString()
            headers:
                common.mixin Config.headers,
                    Cookie: Config.cookie
                    Referer: 'http://www.xiami.com/vip/myvip'
            form:
                user_id: User.id
                tone_type: 1
         */
      });
    };
    $scope.loginFormInit = function() {
      return async.waterfall([
        function(cb) {
          return common.get('https://login.xiami.com/member/login' != null ? 'https://login.xiami.com/member/login' : 'http://www.xiami.com/member/login', cb);
        }, function(response, body, cb) {
          var $, data, field, fields, img, name, value, _i, _len, _ref, _ref1;
          if (response.statusCode === 200) {
            $ = cheerio.load(body, {
              ignoreWhitespace: true
            });

            /*
            $scope.$apply ->
                $scope.taobaoLoginPage = $sce.trustAsResourceUrl url.resolve response.request.href, $('iframe').attr('src') # taobao login
                console.log url.resolve response.request.href, $('iframe').attr('src')
             */
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
              return common.get("https://login.xiami.com/coop/checkcode?forlogin=1&t=" + (Math.random())).pipe(img);
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
    $scope.logout = function() {
      var pCookieRemoved;
      Config.cookie = '';
      pCookieRemoved = Promise.all([$localForage.removeItem('config.cookie'), $localForage.removeItem('config.jar')]);
      return pCookieRemoved.then(function(values) {
        return $scope.$apply(function() {
          var i, _i, _len, _ref;
          _ref = Object.keys(User);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            i = _ref[_i];
            delete User[i];
          }
          User.logged = false;
          $scope.loginPageLoad();
          return $scope.loginFormInit();
        });
      });
    };
    $scope.sign = function() {
      return common.post('http://www.xiami.com/task/signin', function(error, response, body, cb) {
        if (!error) {
          return $scope.$apply(function() {
            User.sign.hasCheck = true;
            return User.sign.num = parseInt(body);
          });
        } else {
          return console.error(error);
        }
      });

      /*
      request.post 'http://www.xiami.com/task/signin',
          headers: common.mixin Config.headers,
              Cookie: Config.cookie
              Referer: 'http://www.xiami.com/'
          proxy: common.getProxyString()
          ,(error, response, body, cb)->
              if not error
                  $scope.$apply ->
                      User.sign.hasCheck = true
                      User.sign.num = parseInt body
              else
                  console.error error
       */
    };
    $scope.loginByWeb = function() {
      var newWindow;
      newWindow = gui.Window.open('https://login.xiami.com/member/login', {
        'frame': true,
        'toolbar': false
      });
      return newWindow.on('closed', function() {
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
          $scope.$apply(setLogged);
          return newWindow = null;
        });
      });
    };
    $scope.loginPageLoad = function() {
      var iframe, iframeUrl;
      iframe = document.querySelector('iframe.loginPage');
      iframe.nwUserAgent = Config.headers['User-Agent'];
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
          return $scope.$apply(setLogged);
        });
      }
    };
    $scope.loginByCookie = function() {
      Config.cookie = $scope.cookie;
      return $scope.$apply(setLogged);
    };
    $scope.loginByUserData = function() {
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
              return common.post('http://www.xiami.com/member/login' != null ? 'http://www.xiami.com/member/login' : 'https://login.xiami.com/member/login', formData, {
                'Referer': 'http://www.xiami.com/member/login' != null ? 'http://www.xiami.com/member/login' : 'https://login.xiami.com/member/login',
                'Host': 'www.xiami.com' != null ? 'www.xiami.com' : 'login.xiami.com',
                'Origin': 'http://www.xiami.com' != null ? 'http://www.xiami.com' : 'https://login.xiami.com'
              }, cb);

              /*
              request.post 'http://www.xiami.com/member/login' ? 'https://login.xiami.com/member/login',
                  form: formData
                  proxy: common.getProxyString()
                  headers: common.mixin(Config.headers,
                      'Referer': 'http://www.xiami.com/member/login' ? 'https://login.xiami.com/member/login'
                      'Host': 'www.xiami.com' ? 'login.xiami.com'
                      'Origin': 'http://www.xiami.com' ? 'https://login.xiami.com'
                  ), cb
               */
            }, function(response, body, cb) {
              if (fs.existsSync('validate.png')) {
                fs.unlink('validate.png');
              }
              cookie = response.headers['set-cookie'];
              if (_.isArray(cookie)) {
                cookie = cookie.join(';');
              }
              return cb(null, cookie);
            }
          ], function(err, result) {
            if (err) {
              console.error(err, result);
              return cb();
            } else {
              Config.cookie = result;
              return $scope.$apply(function() {
                return cb();
              });
            }
          });
        }, function(cb) {
          return setLogged(cb);
        }
      ], function(err, result) {
        if (err) {
          throw err;
        }
        if (User.isVip) {
          return common.post('http://www.xiami.com/vip/update-tone', null, {
            user_id: User.id,
            tone_type: 1
          }, null);

          /*
          request.post 'http://www.xiami.com/vip/update-tone',
              proxy: common.getProxyString()
              headers:
                  common.mixin Config.headers,
                      Cookie: Config.cookie
                      Referer: 'http://www.xiami.com/vip/myvip'
              form:
                  user_id: User.id
                  tone_type: 1
           */
        }
      });
    };
    return _.defer(function() {
      var pCookie;
      $scope.loginFormInit();
      window.setLogged = setLogged;
      pCookie = Promise.all([$localForage.getItem('config.jar'), $localForage.getItem('config.cookie')]);
      return pCookie.then(function(_arg) {
        var cookie, jar;
        jar = _arg[0], cookie = _arg[1];
        console.log(jar, cookie);
        if (_.isObject(jar)) {
          Config.jar = jar;
        }
        if (_.isString(cookie)) {
          Config.cookie = cookie;
        }
        consolo.log(Config.jar, Config.cookie);
        return setLogged();
      });
    });
  });

}).call(this);
