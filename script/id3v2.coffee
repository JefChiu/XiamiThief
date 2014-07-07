'use strict'

fs = require 'fs'
async = require 'async'

String::times = (n)->Array::join.call length:n+1, @

split = (str, len)->
    chunks = []
    pos = str.length
    while pos > 0
        temp = if pos - len > 0 then pos - len else 0
        chunks.unshift str.slice(temp, pos)
        pos = temp
    chunks

prefixInteger = (num, length)->
    (num / Math.pow(10, length)).toFixed(length).substr(2);

isArray = (input)->
    typeof(input) is 'object' and input instanceof Array

hex = (input)->
    if isArray(input)
        String.fromCharCode.apply @, input
    else
        String.fromCharCode input

bin = (input)->
    if isArray(input)
        String.fromCharCode.apply @, (parseInt(i,2) for i in input)
    else
        String.fromCharCode parseInt(input,2)

dec2bin = (input, len=8)->
    bin (prefixInteger(i,8) for i in split(input.toString(2), len) )

class id3v23
    constructor: (@filename,@tags={})->
    setTag:(key,value)->
        @tags[key] = value
    getFrames:->
        ###
            帧
            顺序 Id(4) Size(4) Flags(2) Data(?)
            Id + Size + Flags 共10个字节
            Size为帧的总大小-10, 即Data的大小
        ###
        frames = []
        for tag, value of @tags
            isNum = not isNaN value # 区分全数字字符串
            isBuf = Buffer.isBuffer value # 区分Buffer数据
            isPic = tag is 'APIC'
            isLrc = tag is 'USLT'
            frameId = tag
            frameFlags = bin ['00000000','00000000']
            if isBuf
                if isPic
                    type = 'image/jpeg' + hex([0x00, 0x00, 0x00])
                    frameData = new Buffer(type.length + value.length)
                    frameData.write type, 0 , type.length
                    value.copy frameData, type.length
                else
                    frameData = new Buffer(value.length)
                    value.copy frameData, 0
            else
                frameData = value
            if isNum or isLrc or isPic
                if isLrc
                    bom = hex [0x01, 0x00, 0x00, 0x00, 0xFF, 0xFE, 0x00, 0x00, 0xFF, 0xFE]
                    frameSize = dec2bin frameData.length * 2 + bom.length
                    frame = new Buffer(10 + frameData.length * 2 + bom.length)
                else
                    bom = hex [0x00]
                    frameSize = dec2bin frameData.length + bom.length
                    frame = new Buffer(10 + frameData.length + bom.length)
            else
                bom = hex [0x01, 0xFF, 0xFE]
                frameSize = dec2bin frameData.length * 2 + bom.length
                frame = new Buffer(10 + frameData.length * 2 + bom.length)
            frame.write frameId, 0, 4, 'utf8'
            blankLength = 4 - frameSize.length
            frame.write hex([0x00]).times(blankLength), 4, blankLength,'utf8' if blankLength > 0
            frame.write frameSize, 4 + blankLength, frameSize.length, 'ascii'
            frame.write frameFlags, 8, 2, 'utf8'
            if isNum or isBuf
                if isLrc
                    frame.writeInt16LE 0x01, 10
                    frame.writeInt16LE 0x00, 11
                    frame.writeInt16LE 0x00, 12
                    frame.writeInt16LE 0x00, 13
                    frame.writeInt16LE 0xFF, 14
                    frame.writeInt16LE 0xFE, 15
                    frame.writeInt16LE 0x00, 16
                    frame.writeInt16LE 0x00, 17
                    frame.writeInt16LE 0xFF, 18
                    frame.writeInt16LE 0xFE, 19
                else
                    frame.write bom, 10, bom.length, 'utf8'
                if isBuf
                    if isLrc
                        frame.write frameData, 10 + bom.length, frameData.length * 2, 'ucs2'
                    else
                        frameData.copy frame, 10 + bom.length
                else
                    frame.write frameData, 10 + bom.length, frameData.length, 'ascii'
            else
                if isLrc
                    frame.writeInt16LE 0x01, 10
                    frame.writeInt16LE 0x00, 11
                    frame.writeInt16LE 0x00, 12
                    frame.writeInt16LE 0x00, 13
                    frame.writeInt16LE 0xFF, 14
                    frame.writeInt16LE 0xFE, 15
                    frame.writeInt16LE 0x00, 16
                    frame.writeInt16LE 0x00, 17
                    frame.writeInt16LE 0xFF, 18
                    frame.writeInt16LE 0xFE, 19
                    #frame.write bom, 10, bom.length, 'ascii'
                    frame.write frameData, 10 + bom.length, frameData.length * 2, 'ucs2'
                    #frameData.copy frame, 10 + bom.length
                else
                    frame.write bom, 10, bom.length, 'ascii'
                    frame.write frameData, 10 + bom.length, frameData.length * 2, 'ucs2'
            frames.push(frame)
        frames
    getSize:(cb)->
        frames = @getFrames()
        framesLength = 0
        for frame in frames
            framesLength += frame.length
        framesLength + 10 + 800
    write:(cb)->
        filename = @filename
        fs.readFile filename, (err, oldData)=>
            fs.open filename,'w+', (err, fd)=>
                ###
                    标签头 固定为10个字节
                    顺序 Identifier(3) Version(2) Flags(1) Size(4)
                ###
                header = new Buffer(10)
                headerFileIdentifier = 'ID3'
                headerVersion = hex [0x03,0x00]
                headerFlags = bin '00000000'

                frames = @getFrames()

                framesLength = 0
                for frame in frames
                    framesLength += frame.length

                headerSize = dec2bin framesLength + 10 -1, 7 # 补码
                header.write headerFileIdentifier + headerVersion + headerFlags
                blankLength = 4 - headerSize.length
                header.write hex([0x00]).times(blankLength),6,blankLength,'utf8' if blankLength > 0
                header.write headerSize,6 + blankLength,10,'ascii'

                console.log @tags, filename
                # 写入标签头
                fs.write fd,header,0,header.length,null,(err, written, buffer)->
                    async.forEach frames, (frame, cb)->
                        # 写入帧
                        fs.write fd, frame, 0, frame.length, null, (err, written, buffer)->
                            cb err
                    , (err)->
                        if not err
                            fs.write fd,new Buffer(new Array(800)),0,800,null, (err, written, buffer)->
                                # 写入原数据
                                if oldData
                                    fs.write fd,oldData,0,oldData.length,null,(err, written, buffer)->
                                        fs.close fd, ->
                                            cb null, filename
                                else
                                    fs.close fd, ->
                                        cb null, filename
                        else
                            cb err, filename

exports.id3v23 = id3v23