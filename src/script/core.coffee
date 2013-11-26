'use strict'

http = require 'http'
fs = require 'fs'
path = require 'path'
timers = require 'timers'
request = require 'request'
{parseString} = require 'xml2js'
cheerio = require 'cheerio'
{id3v23} = require './id3v2'

execPath = path.dirname process.execPath

Headers =
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    'Accept-Language': 'zh-CN,zh;q=0.8'
    'Cache-Control': 'max-age=0'
    'Connection': 'keep-alive'
    'Host': 'www.xiami.com'
    'Origin': 'http://www.xiami.com'
    'User-Agent': 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36 AlexaToolbar/alxg-3.1'

safeFilter = (str) ->
    removeSpan = (str)->
        str.replace('<span>', ' ').replace('</span>', '')
    safeFilename = (str)->
        str.replace(/(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' ')
    safeFilename removeSpan(str)

Cookie = ''

log = (data,cb)->
    fs.appendFile 'XiamiThief.log', "[#{Date()}]#{data}", ->
        cb() if typeof(cb) is 'function'

request = request.defaults {jar: true, headers: Headers, followAllRedirects: true, strictSSL: false, proxy:false}

mixins = (args...) ->
    result = {}
    for obj in args
        for key, value of obj
            result[key] = value
    result

str2bool = (str, def)->
    if str is 'true'
       true
    else if str is 'false'
       false
    else
       def ? false

# 添加ID3V2.3信息
addId3v23 = (info)->
    writer = new id3v23(info.savePath)
    #TALB 专辑名
    writer.setTag 'TALB', info.album.name
    #TPE1 主唱
    writer.setTag 'TPE1', info.artist.name
    #TIT2 歌名
    writer.setTag 'TIT2', info.song.name
    #TRCK 音轨号
    if info.trackId
        writer.setTag 'TRCK', info.trackId.toString()
    #TYER 灌录年份
    if info.year
        writer.setTag 'TYER', info.year
    #APIC 专辑封面
    picture = path.resolve(path.dirname(info.savePath),'small.jpg')
    if fs.existsSync(picture)
        writer.setTag 'APIC', fs.readFileSync(picture)
    writer

# 下载地址解码
getLocation = (str) ->
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
        return false

# XML API解析
parseXMLData = (rawXML, cb)->
    # ignoreAttrs:true 忽略XML属性, explicitArray:false 只有单个子节点的不会被转化为数组
    parseString rawXML, {ignoreAttrs:true, explicitArray:false}, (err, result) ->
        if not err
            trackList = result.playlist.trackList.track
            # 如果只有一个对象, 则将将单个对象转换为数组
            trackList = [trackList] unless trackList.push
            data = []
            for track in trackList
                songId = track.song_id
                songName = track.title
                albumId = track.albumId ? track.album_id
                albumName = track.album_name
                artistName = track.artist
                artistId = track.artist_id
                lyricUrl = track.lyric
                pictureUrl = track.pic?.replace(/_\d/, '')# 从小图Url获得大图Url
                data.push
                        'song':
                            'name':songName,
                            'id':songId
                        'album':
                            'name':albumName,
                            'id':albumId
                        'artist':
                            'name':artistName,
                            'id':artistId
                        'lyric':
                            'url':lyricUrl
                        'picture':
                            'url':pictureUrl
            cb data
        else
            throw new Error(err)

# 获取单曲信息, 不需要cookie
getSongInfo = (id, cb) ->
    request("http://www.xiami.com/song/playlist/id/#{id}/type/0", (error, response, body) ->
        if not error and response.statusCode is 200
            parseXMLData(body, (data)->
                cb if data.length is 1 then data[0] else data
            )
        else
            cb false
    )

# 获取专辑信息, 不需要cookie
getAlbumInfo = (id, cb) ->
    request("http://www.xiami.com/album/#{id}", (error, response, body) ->
        if not error and response.statusCode is 200
            $ = cheerio.load(body, ignoreWhitespace:true)
            name = $('#title h1').text()
            pictureUrl = $('#album_cover a img').attr('src')?.replace(/_\d/, '')# 从小图Url获得大图Url
            info = $('#album_info table tr').toArray()# 专辑信息
            artistInfo = $(info[0]).children().last().text()# 艺人
            languageInfo = $(info[1]).children().last().text()# 语种
            companyInfo = $(info[2]).children().last().text()# 唱片公司
            timeInfo = $(info[3]).children().last().text()#发行时间
            typeInfo = $(info[4]).children().last().text()#专辑类别
            styleInfo = $(info[5]).children().last().text()#专辑风格
            request("http://www.xiami.com/song/playlist/id/#{id}/type/1", (error, response, body) ->
                if not error and response.statusCode is 200
                    parseXMLData(body, (data)->
                        if not data[0].album.id?
                            for i in data
                                i.album.id = id
                        info =
                            'data':data
                            'name':name
                            'artist':artistInfo
                            'language':languageInfo
                            'company':companyInfo
                            'time':timeInfo
                            'style':styleInfo
                            'type':'album'
                            'year':timeInfo.substring(0,4)
                            'picture':data[0].picture
                        for song, id in info.data
                            song.trackId = id + 1
                            song.year = info.year if info.year
                        cb info
                    )
                else
                    cb false
            )
        else
            cb false
    )

# 获取精选集信息, 不需要cookie
getShowcollectInfo = (id, cb) ->
    request("http://www.xiami.com/song/showcollect/id/#{id}", (error, response, body) ->
        if not error and response.statusCode is 200
            $ = cheerio.load(body, ignoreWhitespace:true)
            name = $('#xiami-content h1').text()
            pictureUrl = $('#cover_logo a img').attr('src')?.replace(/_\d/, '')# 从小图Url获得大图Url
            request("http://www.xiami.com/song/playlist/id/#{id}/type/3", (error, response, body) ->
                if not error and response.statusCode is 200
                    parseXMLData(body, (data)->
                        cb
                            'data':data
                            'name':name
                            'pictureUrl':pictureUrl
                            'type':'showcollect'
                    )
                else
                    cb false
            )
        else
            cb false
    )

# 单曲下载
downloadMusic = (info, cb, useId3, useLyric, client) ->
    filename =
        music: info.savePath
        lyric: info.savePath.replace('.mp3','.lrc')
        picture: path.resolve(path.dirname(info.savePath),info.album.name+'.jpg')

    download = (location)->
        if location
            fs.exists(filename.music, (exists) ->
                req = http.get(location, (res) ->
                    if res.statusCode is 302
                        download res.headers.location
                        return
                    writer = addId3v23(info)
                    save = ->
                        f = fs.createWriteStream filename.music
                        f.on('finish',->
                            if f.bytesWritten is contentLength
                                if useId3 and writer
                                    writer.write(->
                                        ###
                                        if info.last
                                            fs.unlinkSync(picture) # 最后一个音乐时清除small.jpg
                                        ###
                                        cb true
                                    )
                                else
                                    cb true
                            else
                                cb false
                        )
                        f.on('error',(err)->
                            f.end()
                            cb false
                            throw err
                        )
                        res.pipe f

                        lastBytes = 0
                        count = 0
                        check = (timeout)->
                            nowBytes = f.bytesWritten
                            downloadProgress = nowBytes/contentLength
                            if downloadProgress >= 1
                                f.end()
                            else
                                if lastBytes is nowBytes
                                    count++
                                else
                                    count=0
                                if count > 60
                                    f.end()
                                else
                                    cb downloadProgress
                                    timers.setTimeout(check,timeout*1000)
                        check(1)
                    contentLength = parseInt res.headers['content-length']
                    if exists
                        size = fs.statSync(filename.music).size
                        if useId3
                            size -= writer.getSize()
                        if size >= contentLength
                            cb true
                            req.abort()
                        else
                            save()
                    else
                        save()
                ).on('error',(err)->
                    cb false
                    throw err
                )
            )
        else
            cb false

    if not client
        request(
            url: "http://www.xiami.com/song/gethqsong/sid/#{info.song.id}"
            json: 'body'
            jar: true
            headers:
                'Content-Type': 'application/json',
                'Cookie': Cookie
            , (error, response, body) ->
                if not error and response.statusCode is 200
                    download getLocation(body.location)
                else
                    cb false
        )
    else
        client.getUrl info.song.id, (result, args, output, warning)->
            if isNaN(result)
                download result
            else
                cb false

    fs.exists(filename.lyric, (exists) ->
        if not exists
            f = fs.createWriteStream filename.lyric
            request(info.lyric.url, {jar: false, headers:{}}).pipe f
    ) if useLyric and info.lyric.url.indexOf('.lrc')>=0



# 封面下载
downloadAlbumCover = (info, cb, useCover, useId3)->
    total = 0
    total++ if useCover
    total++ if useId3
    if total is 0
        cb true
    else
        count = 0
        if useCover
            savePath = path.resolve(info.savePath, safeFilter "#{info.name}.jpg")
            fs.exists(savePath, (exists)->
                if not exists
                    f = fs.createWriteStream savePath
                    f.on('finish',->
                        count++
                        if count is total
                            cb true
                    )
                    request(info.picture.url, {jar: false, headers: {}}).pipe f
                else
                    count++
                    if count is total
                        cb true
            )
        if useId3
            tempSavePath = path.resolve(info.savePath, safeFilter 'small.jpg')
            # ID3的temp下载
            fs.exists(tempSavePath, (exists)->
                if not exists
                    f = fs.createWriteStream tempSavePath
                    f.on('finish',->
                        count++
                        if count is total
                            cb true
                    )
                    request(info.picture.url.replace('.jpg','_5.jpg'), {jar: false, headers: {}}).pipe  f
                else
                    count++
                    if count is total
                        cb true
            )

# 获取登录页面信息
getLoginForm = (cb) ->
    request('http://www.xiami.com/member/login', (error, response, body) ->
        if not error and response.statusCode is 200
            $ = cheerio.load(body, ignoreWhitespace:true)
            fields= $('form input').toArray()
            data = {}
            for field in fields
                name = $(field).attr('name') ? ''
                value = $(field).attr('value') ? ''
                data[name] = value
            if data.validate?
                img = fs.createWriteStream 'validate.png'
                img.on 'finish',->
                    cb data
                request("https://login.xiami.com/coop/checkcode?forlogin=1&t=#{Math.random()}").pipe img
            else
                cb(data)
    )

# 取得Cookie
getCookie = (data, cb) ->
    request.post('http://www.xiami.com/member/login',
        form: data
        headers: mixins(Headers,
            'Referer': 'http://www.xiami.com/member/login'
            'Host': 'www.xiami.com'
            'Origin': 'http://www.xiami.com'
        ),
        (error, response, body) ->
            fs.unlinkSync 'validate.png' if fs.existsSync 'validate.png'
            if not error
                cookie = response.headers['set-cookie']?.toString()
                if cookie
                    Cookie = cookie
                    cb Cookie
                else
                    cb false
            else
                cb false
    )

# 获得帐户信息
getAccountInfo = (cb) ->
    request("http://www.xiami.com/song/playlist/id/1/type/0",
        headers:
            'Cookie':Cookie,
        (error, response, body) ->
            if not error and response.statusCode is 200
                parseString body, {ignoreAttrs:true, explicitArray:false}, (err, result) ->
                    if not err
                        delete result.playlist.trackList
                        cb result.playlist
    )

# 登出
accountLogout = (cb) ->
    request('http://www.xiami.com/member/logout',
        headers:
            'Cookie':Cookie,
        (error, response, body) ->
            Cookie = ''
            cb? true
    )

# 综合获得信息
getInfo = (url, cb) ->
    isSong = /www.xiami.com\/song\/(\d+)/
    isShowcollect = /www.xiami.com\/song\/showcollect\/id\/(\d+)/
    isAlbum = /www.xiami.com\/album\/(\d+)/

    song = isSong.exec url
    showcollect = isShowcollect.exec url
    album = isAlbum.exec url

    if song
        getSongInfo(song[1], cb)
    else if showcollect
        getShowcollectInfo(showcollect[1], cb)
    else if album
        getAlbumInfo(album[1], cb)

exports.getShowcollectInfo = getShowcollectInfo
exports.getAlbumInfo = getAlbumInfo
exports.getSongInfo = getSongInfo
exports.getAccountInfo = getAccountInfo
exports.downloadMusic = downloadMusic
exports.downloadAlbumCover = downloadAlbumCover
exports.getCookie = getCookie
exports.getLoginForm = getLoginForm
exports.accountLogout = accountLogout
exports.getInfo = getInfo
exports.execPath = execPath
exports.id3v23 = id3v23
exports.log = log
exports.str2bool = str2bool
