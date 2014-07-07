(function() {
  'use strict';
  var async, bin, dec2bin, fs, hex, id3v23, isArray, prefixInteger, split;

  fs = require('fs');

  async = require('async');

  String.prototype.times = function(n) {
    return Array.prototype.join.call({
      length: n + 1
    }, this);
  };

  split = function(str, len) {
    var chunks, pos, temp;
    chunks = [];
    pos = str.length;
    while (pos > 0) {
      temp = pos - len > 0 ? pos - len : 0;
      chunks.unshift(str.slice(temp, pos));
      pos = temp;
    }
    return chunks;
  };

  prefixInteger = function(num, length) {
    return (num / Math.pow(10, length)).toFixed(length).substr(2);
  };

  isArray = function(input) {
    return typeof input === 'object' && input instanceof Array;
  };

  hex = function(input) {
    if (isArray(input)) {
      return String.fromCharCode.apply(this, input);
    } else {
      return String.fromCharCode(input);
    }
  };

  bin = function(input) {
    var i;
    if (isArray(input)) {
      return String.fromCharCode.apply(this, (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = input.length; _i < _len; _i++) {
          i = input[_i];
          _results.push(parseInt(i, 2));
        }
        return _results;
      })());
    } else {
      return String.fromCharCode(parseInt(input, 2));
    }
  };

  dec2bin = function(input, len) {
    var i;
    if (len == null) {
      len = 8;
    }
    return bin((function() {
      var _i, _len, _ref, _results;
      _ref = split(input.toString(2), len);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        _results.push(prefixInteger(i, 8));
      }
      return _results;
    })());
  };

  id3v23 = (function() {
    function id3v23(filename, tags) {
      this.filename = filename;
      this.tags = tags != null ? tags : {};
    }

    id3v23.prototype.setTag = function(key, value) {
      return this.tags[key] = value;
    };

    id3v23.prototype.getFrames = function() {
      /*
          帧
          顺序 Id(4) Size(4) Flags(2) Data(?)
          Id + Size + Flags 共10个字节
          Size为帧的总大小-10, 即Data的大小
      */

      var blankLength, bom, frame, frameData, frameFlags, frameId, frameSize, frames, isBuf, isLrc, isNum, isPic, tag, type, value, _ref;
      frames = [];
      _ref = this.tags;
      for (tag in _ref) {
        value = _ref[tag];
        isNum = !isNaN(value);
        isBuf = Buffer.isBuffer(value);
        isPic = tag === 'APIC';
        isLrc = tag === 'USLT';
        frameId = tag;
        frameFlags = bin(['00000000', '00000000']);
        if (isBuf) {
          if (isPic) {
            type = 'image/jpeg' + hex([0x00, 0x00, 0x00]);
            frameData = new Buffer(type.length + value.length);
            frameData.write(type, 0, type.length);
            value.copy(frameData, type.length);
          } else {
            frameData = new Buffer(value.length);
            value.copy(frameData, 0);
          }
        } else {
          frameData = value;
        }
        if (isNum || isLrc || isPic) {
          if (isLrc) {
            bom = hex([0x01, 0x00, 0x00, 0x00, 0xFF, 0xFE, 0x00, 0x00, 0xFF, 0xFE]);
            frameSize = dec2bin(frameData.length * 2 + bom.length);
            frame = new Buffer(10 + frameData.length * 2 + bom.length);
          } else {
            bom = hex([0x00]);
            frameSize = dec2bin(frameData.length + bom.length);
            frame = new Buffer(10 + frameData.length + bom.length);
          }
        } else {
          bom = hex([0x01, 0xFF, 0xFE]);
          frameSize = dec2bin(frameData.length * 2 + bom.length);
          frame = new Buffer(10 + frameData.length * 2 + bom.length);
        }
        frame.write(frameId, 0, 4, 'utf8');
        blankLength = 4 - frameSize.length;
        if (blankLength > 0) {
          frame.write(hex([0x00]).times(blankLength), 4, blankLength, 'utf8');
        }
        frame.write(frameSize, 4 + blankLength, frameSize.length, 'ascii');
        frame.write(frameFlags, 8, 2, 'utf8');
        if (isNum || isBuf) {
          if (isLrc) {
            frame.writeInt16LE(0x01, 10);
            frame.writeInt16LE(0x00, 11);
            frame.writeInt16LE(0x00, 12);
            frame.writeInt16LE(0x00, 13);
            frame.writeInt16LE(0xFF, 14);
            frame.writeInt16LE(0xFE, 15);
            frame.writeInt16LE(0x00, 16);
            frame.writeInt16LE(0x00, 17);
            frame.writeInt16LE(0xFF, 18);
            frame.writeInt16LE(0xFE, 19);
          } else {
            frame.write(bom, 10, bom.length, 'utf8');
          }
          if (isBuf) {
            if (isLrc) {
              frame.write(frameData, 10 + bom.length, frameData.length * 2, 'ucs2');
            } else {
              frameData.copy(frame, 10 + bom.length);
            }
          } else {
            frame.write(frameData, 10 + bom.length, frameData.length, 'ascii');
          }
        } else {
          if (isLrc) {
            frame.writeInt16LE(0x01, 10);
            frame.writeInt16LE(0x00, 11);
            frame.writeInt16LE(0x00, 12);
            frame.writeInt16LE(0x00, 13);
            frame.writeInt16LE(0xFF, 14);
            frame.writeInt16LE(0xFE, 15);
            frame.writeInt16LE(0x00, 16);
            frame.writeInt16LE(0x00, 17);
            frame.writeInt16LE(0xFF, 18);
            frame.writeInt16LE(0xFE, 19);
            frame.write(frameData, 10 + bom.length, frameData.length * 2, 'ucs2');
          } else {
            frame.write(bom, 10, bom.length, 'ascii');
            frame.write(frameData, 10 + bom.length, frameData.length * 2, 'ucs2');
          }
        }
        frames.push(frame);
      }
      return frames;
    };

    id3v23.prototype.getSize = function(cb) {
      var frame, frames, framesLength, _i, _len;
      frames = this.getFrames();
      framesLength = 0;
      for (_i = 0, _len = frames.length; _i < _len; _i++) {
        frame = frames[_i];
        framesLength += frame.length;
      }
      return framesLength + 10 + 800;
    };

    id3v23.prototype.write = function(cb) {
      var filename,
        _this = this;
      filename = this.filename;
      return fs.readFile(filename, function(err, oldData) {
        return fs.open(filename, 'w+', function(err, fd) {
          /*
              标签头 固定为10个字节
              顺序 Identifier(3) Version(2) Flags(1) Size(4)
          */

          var blankLength, frame, frames, framesLength, header, headerFileIdentifier, headerFlags, headerSize, headerVersion, _i, _len;
          header = new Buffer(10);
          headerFileIdentifier = 'ID3';
          headerVersion = hex([0x03, 0x00]);
          headerFlags = bin('00000000');
          frames = _this.getFrames();
          framesLength = 0;
          for (_i = 0, _len = frames.length; _i < _len; _i++) {
            frame = frames[_i];
            framesLength += frame.length;
          }
          headerSize = dec2bin(framesLength + 10 - 1, 7);
          header.write(headerFileIdentifier + headerVersion + headerFlags);
          blankLength = 4 - headerSize.length;
          if (blankLength > 0) {
            header.write(hex([0x00]).times(blankLength), 6, blankLength, 'utf8');
          }
          header.write(headerSize, 6 + blankLength, 10, 'ascii');
          console.log(_this.tags, filename);
          return fs.write(fd, header, 0, header.length, null, function(err, written, buffer) {
            return async.forEach(frames, function(frame, cb) {
              return fs.write(fd, frame, 0, frame.length, null, function(err, written, buffer) {
                return cb(err);
              });
            }, function(err) {
              if (!err) {
                return fs.write(fd, new Buffer(new Array(800)), 0, 800, null, function(err, written, buffer) {
                  if (oldData) {
                    return fs.write(fd, oldData, 0, oldData.length, null, function(err, written, buffer) {
                      return fs.close(fd, function() {
                        return cb(null, filename);
                      });
                    });
                  } else {
                    return fs.close(fd, function() {
                      return cb(null, filename);
                    });
                  }
                });
              } else {
                return cb(err, filename);
              }
            });
          });
        });
      });
    };

    return id3v23;

  })();

  exports.id3v23 = id3v23;

}).call(this);
