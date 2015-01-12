'use strict'

gui = require 'nw.gui'
pkg = require '../package'
async = require 'async'
os = require 'os'
http = require 'http'
https = require 'https'
common = require '../script/common'
###
request = (require 'request').defaults
    jar: true
    headers: common.config.headers
    followAllRedirects: false
    strictSSL: false
    proxy: false
###
cheerio = require 'cheerio'
cookie = require 'cookie'
tunnel = require 'tunnel'
fs = require 'fs'
url = require 'url'
path = require 'path'
timers = require 'timers'
mkdirp = require 'mkdirp'
ent = require 'ent'
{id3v23} = require '../script/id3v2'
genre = require '../script/genre'
validator = require 'validator'

http.globalAgent.maxSockets = Infinity

App.factory 'Config',->
    common.config

App.controller 'CreateCtrl',($scope, $interval, State, TaskQueue, Config, User)->
    type =
        song: 0
        album: 1
        artist: 2
        collect: 3

    cache = {}

    $scope.type = type
    $scope.step = 1
    $scope.links = ''
    $scope.data = []

    monitoringClipboard = null
    clipboardText = clipboard.get 'text'

    startMonitoringClipboard = ->
        monitoringClipboard = $interval ->
            text = clipboard.get 'text'
            if text is clipboardText
                return
            else
                clipboardText = text
            if validator.isURL(text) and url.parse(text).hostname is 'www.xiami.com'
                artist = common.isArtist.exec text
                song = common.isSong.exec text
                collect = common.isCollect.exec text
                showcollect = common.isShowcollect.exec text
                album = common.isAlbum.exec text
                if artist or song or collect or showcollect or album
                    lastChar = common.index($scope.links, -1)
                    if (lastChar is '\n') or (not lastChar)
                        $scope.links += text + '\n'
                    else
                        $scope.links += '\n' + text
        , 1000

    startMonitoringClipboard() if Config.useMonitoringClipboard

    $scope.$watch ->
        Config.useMonitoringClipboard
    , (newValue, oldValue)->
        # console.log newValue, oldValue
        if newValue isnt oldValue
            # if angular.isDefined monitoringClipboard
            if newValue
                startMonitoringClipboard()
            else
                $interval.cancel monitoringClipboard

    $scope.pasteHandle = ->
        _.defer ->
            editor = document.querySelector('textarea.links')
            selStart = editor.selectionStart
            selEnd = editor.selectionEnd
            part1 = editor.value[...selStart]
            part2 = editor.value[selEnd...]
            editor.value = part1 + '\n' + part2
            editor.setSelectionRange selEnd + 1, selEnd + 1

    $scope.popupMenuEditor = ($event)->
        menu = new gui.Menu

        menuItem = (options)->
            new gui.MenuItem options

        menu.append menuItem
            type: 'normal'
            label: '剪切'
            click: ->
                document.execCommand 'cut'

        menu.append menuItem
            type: 'normal'
            label: '复制'
            click: ->
                document.execCommand 'copy'

        menu.append menuItem
            type: 'normal'
            label: '粘贴'
            click: ->
                document.execCommand 'paste'

        if os.platform() is 'drawin' and version[1] >= 10
            menu.createMacBuiltin 'xiami-thief'

        menu.popup $event.clientX, $event.clientY

    getLocation = (sid, cb)->
        if true or User.logged
            common.get "http://www.xiami.com/song/gethqsong/sid/#{sid}", 'Content-Type': 'application/json'
            , (error, response, body)->
                # console.log response, body
                if not error and response.statusCode is 200
                    if body.location?
                        location = common.parseLocation body.location
                        if location
                            # console.log location
                            cb null, location.trim()
                        else
                            cb location
                    else
                        cb body
                else
                    cb error, ''
            ###
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
                    # console.log response
                    if not error and response.statusCode is 200
                        if body.location?
                            location = common.parseLocation body.location
                            if location
                                # console.log location
                                cb null, location.trim()
                            else
                                cb location
                        else
                            cb body
                    else
                        cb error, ''
            ###
        else
            console.error 'not login'

    requestFile = (cb)->
        info = this

        pathFolder = info.save.path
        filename = info.save.name

        mkdirp pathFolder, (err)->
            unless err
                savePath = path.resolve pathFolder, filename

                timestamp = new Date().getTime()

                coverDownload = (cb)->
                    coverPath = path.resolve pathFolder, "#{info.album.id}.#{info.cover.type ? 'jpg'}"
                    # console.log 'coverPath', coverPath

                    # console.log 'coverDownload'
                    if Config.hasCover
                        # console.log 'coverDownload is true'
                        fs.exists coverPath, (exists)->
                            if exists
                                cb null
                            else
                                f = fs.createWriteStream coverPath
                                f.on 'finish', ->
                                    cb null
                                f.on 'error', (err)->
                                    cb err
                                req = common.getReq info.cover.url,
                                    'Host': 'img.xiami.net',
                                    'Origin': 'http://img.xiami.net'
                                , ->
                                ###
                                req = request info.cover.url,
                                    jar: false
                                    headers: {}
                                    proxy: common.getProxyString()
                                ###
                                req.pipe f
                    else
                        cb null

                resizeImage = (cb)->
                    console.log Config.hasId3 and  Config.id3.hasCover
                    if Config.hasId3 and  Config.id3.hasCover
                        imagePath = info.cover.url
                        # console.log 'resizeImage', imagePath
                        maxSide = if Config.id3.size is 'standard' then 640 else Config.id3.cover.maxSide

                        image = new Image

                        image.addEventListener 'load', (e)->
                            console.log 'load'
                            canvas = document.createElement 'canvas'
                            ctx = canvas.getContext '2d'
                            width = image.width
                            height = image.height
                            if height < maxSide and width < maxSide
                                canvas.height = image.height
                                canvas.width = image.width
                            else if height > width
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
                            data = canvas.toDataURL('image/jpeg')?.replace 'data:image/jpeg;base64,', ''
                            console.log data
                            cb err, new Buffer data, 'base64'

                        image.addEventListener 'error', (e)->
                            console.error e
                            cb e ? 'Image Load: Error'
                        image.addEventListener 'abort', (e)->
                            console.error e
                            cb e ? 'Image Load: Abort'

                        image.src = if imagePath[...4] is 'http' then imagePath else "file:///#{imagePath}"
                        console.log image.src
                    else
                        cb null

                lyricDownload = (cb)->
                    # console.log 'lyricDownload'
                    if (Config.hasLyric or (Config.hasId3 and Config.id3.hasLyric)) and info.lyric.url
                        # console.log 'lyricDownload is true'
                        if Config.hasLyric

                            fs.exists "#{savePath}.lrc", (exist)->
                                transportStream = (suffix)->
                                    lrcFilename = "#{savePath + if suffix then ' ' + suffix else ''}.lrc"
                                    f = fs.createWriteStream lrcFilename

                                    f.on 'finish', ->
                                        if Config.hasId3 and Config.id3.hasLyric
                                            fs.readFile lrcFilename, (err, data)->
                                                cb err, data.toString()
                                        else
                                            cb null
                                    f.on 'error', (err)->
                                        cb err
                                    req = common.get info.lyric.url
                                    req.pipe f

                                if exist
                                    fs.stat "#{savePath}.lrc", (stat)->
                                        switch Config.fileExistSolution
                                            when 'alwaysCover'
                                                transportStream()
                                            when 'alwaysSkip'
                                                return cb null
                                            when 'coverSmallFile'
                                                if stat.size >= contentLength + id3Size
                                                    return cb null
                                                else
                                                    transportStream()
                                            when 'filenameTimestamp'
                                                transportStream(timestamp)
                                else
                                    transportStream()
                        else
                            common.get info.lyric.url, (error, response, body)->
                                cb error, body
                    else
                        # console.log 'noLyric'
                        cb null

                writeId3Info = (cb, result)->
                    console.log result
                    # console.log 'writeId3Info'
                    if Config.hasId3
                        # console.log 'writeId3Info is true'

                        id3Writer = new id3v23 path.resolve pathFolder, "#{info.song.id}.download"

                        # TALB 专辑名
                        if Config.id3.hasAlbum and info.album.name
                            id3Writer.setTag 'TALB', info.album.name

                        # TPE1 艺术家/主唱
                        if Config.id3.hasArtist and info.artist.name
                            id3Writer.setTag 'TPE1', info.artist.name

                        # TPE2 专辑艺术家/乐队
                        if Config.id3.hasAlbumArtist and info.album.artist
                            id3Writer.setTag 'TPE2', info.album.artist

                        console.log info.artist.name, info.album.artist

                        # TIT2 歌名
                        if Config.id3.hasTitle and info.song.name
                            ###
                            iconv = require 'iconv-lite'
                            t = iconv.decode info.song.name, 'utf8'
                            t = iconv.encode info.song.name, 'ucs2'
                            console.log t, t.toString()
                            ###
                            id3Writer.setTag 'TIT2', info.song.name #info.song.name

                        # TRCK 音轨号
                        if Config.id3.hasTrack and info.track.id
                            id3Writer.setTag 'TRCK', info.track.id

                        # TYER 灌录年份
                        if Config.id3.hasYear and info.source.year
                            id3Writer.setTag 'TYER', info.source.year

                        # APIC 专辑封面
                        if Config.id3.hasCover and image = result.resizeImage
                            id3Writer.setTag 'APIC', image

                        # TCON 音乐类型(流派)
                        if Config.id3.hasGenre and info.source.style
                            g = genre info.source.style.split(',')
                            if g
                                id3Writer.setTag 'TCON', g

                        # TPOS 碟片号
                        if Config.id3.hasDisc and info.track.disc
                            id3Writer.setTag 'TPOS', info.track.disc

                        # USLT 歌词
                        if Config.id3.hasLyric and info.lyric.url
                            if lyric = result.lyricDownload
                                id3Writer.setTag 'USLT', lyric
                                #id3Writer.write cb
                            ###
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
                            ###

                        id3Writer.write cb
                    else
                        cb null

                fileDownload = (cb, result)->
                    getLocation info.song.id, (err, location)->
                        if not err and location
                            # console.log 'fileDownload'
                            # console.log result, info
                            id3Size = result.writeId3Info ? 0

                            fs.exists "#{savePath}.mp3", (exists)->
                                download = ->
                                    info.url.hq = location
                                    req = http.get do ->
                                        if Config.useProxy is 'true'
                                            common.mixin url.parse(location),
                                                agent: tunnel.httpsOverHttp
                                                    proxy:
                                                        host: Config.proxy.host
                                                        port: Config.proxy.port
                                                        proxyAuth: "#{Config.proxy.username}:#{Config.proxy.password}"
                                        else
                                            location
                                    , (res)->
                                        switch res.statusCode
                                            when 200
                                                contentLength = Number res.headers['content-length']
                                                transportStream = (suffix)->
                                                    f = fs.createWriteStream path.resolve(pathFolder, "#{info.song.id}.download"),
                                                        flags: 'a'
                                                        encoding: null
                                                        mode: 0o666

                                                    f.on 'finish', ->
                                                        fs.rename path.resolve(pathFolder, "#{info.song.id}.download"), "#{savePath + if suffix then ' ' + suffix else ''}.mp3", (err)->
                                                            unless err
                                                                window.count++
                                                                window.win.setBadgeLabel? window.count # only OSX and Windows, 0.10.0-rc1 new feature
                                                            $scope.$apply ->
                                                                info.process = 100
                                                                cb err

                                                    f.on 'error', (err)->
                                                        console.error err
                                                        $scope.$apply ->
                                                            info.process = 100
                                                            cb err

                                                    check = ((timeout)->
                                                        count = 0
                                                        lastBytes = 0

                                                        ->
                                                            nowBytes = f.bytesWritten
                                                            if info.state is State.Running
                                                                $scope.$apply ->
                                                                    info.process = nowBytes / contentLength * 100

                                                            if info.process >= 100
                                                                f.end()
                                                            else
                                                                if lastBytes is nowBytes
                                                                    count++
                                                                else
                                                                    count = 0

                                                                if count > 60
                                                                    f.emit 'error', new Error '下载被阻断'
                                                                else
                                                                    timers.setTimeout(check, timeout)
                                                    )(1000)

                                                    check()

                                                    res.pipe f

                                                if exists
                                                    fs.stat "#{savePath}.mp3", (err, stat)->
                                                        if err
                                                            cb err
                                                        else
                                                            switch Config.fileExistSolution
                                                                when 'alwaysCover'
                                                                    transportStream()
                                                                when 'alwaysSkip'
                                                                    fs.unlink path.resolve(pathFolder, "#{info.song.id}.download"), (err)->
                                                                        if err
                                                                            cb err
                                                                        else
                                                                            cb new Error '文件已存在'
                                                                when 'coverSmallFile'
                                                                    if stat.size >= contentLength + id3Size
                                                                        fs.unlink path.resolve(pathFolder, "#{info.song.id}.download"), (err)->
                                                                            if err
                                                                                cb err
                                                                            else
                                                                                cb new Error '文件已存在'
                                                                    else
                                                                        transportStream()
                                                                when 'filenameTimestamp'
                                                                    transportStream(timestamp)
                                                else
                                                    transportStream()
                                            when 302
                                                res.resume()
                                                location = res.headers.location
                                                download()
                                            else
                                                # console.log res.statusCode
                                                cb '无法下载'

                                    req.on 'error',(err)->
                                        cb err

                                download()
                        else
                            cb err, location

                async.auto
                    'coverDownload': coverDownload
                    'resizeImage': resizeImage
                    'lyricDownload': lyricDownload
                    'writeId3Info': common.getValidArray ['resizeImage' if Config.id3.hasCover, 'lyricDownload' if Config.id3.hasLyric, writeId3Info]
                    'fileDownload': common.getValidArray ['writeId3Info' if Config.hasId3, fileDownload]
                , (err, result)->
                    console.error err, result if err
                    cb err
            else
                cb err

    logProgressText = (text)->
        $scope.progressText = "#{text}\n"

    getInfo = (item, cb)->
        logProgressText "开始获取#{common.type2name item.type}#{item.id}的信息"

        parseInfoFromAPI = (song)->
            songId = song.song_id
            songName = ent.decode song.name ? song.title # web: title    android: name
            albumId = song.albumId ? song.album_id
            albumName = ent.decode song.album_name ? song.title # web: album_name    android: album.title
            albumArtist = song.artist_name # android only
            artistName = ent.decode song.artist ? song.singers # web: artist    android: singers
            artistId = song.artist_id
            lyricUrl = song.lyric if song.lyric?.indexOf('.lrc') isnt -1
            pictureUrl = (song.pic ? song.album_logo)?.replace /_\d.([\w\d]+)$/, '.$1'# 从小图Url获得大图Url web: pic    android: album_logo
            trackId = song.track # android only
            discNum = song.cd_serial # android only
            cdCount = song.cd_count # android only
            lqUrl = common.parseLocation song.location if song.location?
            'song':
                'name': songName
                'id': songId
            'album':
                'name': albumName
                'id': albumId
                'artist': albumArtist
            'artist':
                'name': artistName
                'id': artistId
            'lyric':
                'url': lyricUrl
            'cover':
                'url':pictureUrl
            'track':
                'disc': discNum
                'id': trackId
                'cd': cdCount
            'url':
                'lq': lqUrl
                'hq': lqUrl

        getInfoFromAPI = (cb)->
            # "http://www.xiami.com/app/xiating/album?id=#{item.id}" HTML
            switch item.type
                when 'user', 'artist'
                    return cb null, {}
                when 'playlist'
                    uri = 'http://www.xiami.com/song/playlist-default/cat/json'
                    ###
                when 'album'
                    uri = "http://www.xiami.com/app/android/album?id=#{item.id}" # android api only for track
                    ###
                    ###
                when 'collect'
                    uri = "http://www.xiami.com/app/android/collect?id=#{item.id}" # android api only for title
                  ###
                else
                    uri = "http://www.xiami.com/song/playlist/id/#{item.id}/type/#{type[item.type]}/cat/json"
            ###
            request
                url: uri
                json: true
                proxy: common.getProxyString()
                , (error, response, body)->
            ###
            common.get uri, (error, response, body)->
                if not error and response.statusCode is 200
                    result =
                        type: item.type
                        id: item.id
                        list: do ->
                            result = []
                            if trackList = body?.data?.trackList ? body?.album?.songs # web: trackList    android: songs
                                for song in trackList
                                    result.push parseInfoFromAPI song
                            result
                    cb null, result
                else
                    cb error ? response.statusCode, {}

        parseAlbumFromHTML = (html)->
            $ = cheerio.load html, ignoreWhitespace: true
            name = common.replaceLast $('#title h1').text(), $('#title h1').children().text(), ''
            pictureUrl = $('#album_cover a img').attr('src')?.replace(/_\d\.jpg/, '.jpg')# 从小图Url获得大图Url
            infoEle = $('#album_info table tr').toArray()# 专辑信息
            info = {}
            for i in infoEle
                children = $(i).children()
                key = $(children[0]).text()[...-1]
                value = $(children[1]).text()
                info[key] = value
            'name': name
            'artist': info['艺人']
            'language': info['语种']
            'company': info['唱片公司']
            'time': info['发行时间']
            'style': info['专辑风格']
            'year': info['发行时间']?[...4]
            'cover':
                'url': pictureUrl

        parseTrackFromHTML = (html)->
            $ = cheerio.load html, ignoreWhitespace: true
            result = []
            trackList = $ '.chapter .track_list'
            cdCount = trackList.length
            cdSerial = 0
            for table in trackList
                cdSerial++
                for tr in $(table).find 'tr'
                    trackId = $(tr).find('.trackid')?.text()
                    songId = $(tr).find('.song_name a')?.attr('href')?.match(/song\/(\d+)/)?[1]
                    result.push
                        'song_id': songId
                        'track': Number(trackId).toString() # remove the fill char
                        'cd_serial': cdSerial.toString()
                        'cd_count': cdCount.toString()
            result

        getTrackFromHTML = (result, cb)->
            if common.inStr(Config.filenameFormat, '%TRACK%') or
            (Config.saveMode isnt 'direct') or
            (Config.hasId3 and (Config.id3.hasTrack or Config.id3.hasDisc))
                async.mapSeries result.list, (item, cb)->
                        return cb null, item if +item.album.id is 0 # demo music no album id

                        handle = (info)->
                            if result.type in ['song', 'album']
                                common.supplement result, info
                            for song in info.list
                                songId = song.song_id
                                trackId = song.track
                                discNum = song.cd_serial
                                cdCount = song.cd_count

                                if songId is item.song.id
                                    item.album.artist = info.artist unless item.album.artist
                                    item.track.disc = discNum
                                    item.track.id = trackId
                                    item.track.cd = cdCount
                                    break

                        if cache["album#{item.album.id}"]?
                            handle cache["album#{item.album.id}"]
                            cb null, item
                        else
                            uri = "http://www.xiami.com/album/#{item.album.id}"
                            # uri = "http://www.xiami.com/app/android/album?id=#{item.album.id}"
                            ###
                            request
                                url: uri,
                                json: true
                                proxy: common.getProxyString()
                                ,(error, response, body)->
                            ###
                            getTrack = ->
                                getTrack.count++

                                if getTrack.count > 3
                                    cb new Error '遭到屏蔽, 暂时无法使用'
                                    return

                                console.log uri, cache

                                common.get uri, (error, response, body)->
                                    console.log error, response.statusCode
                                    if not error and response.statusCode is 200
                                        albumInfo = parseAlbumFromHTML body
                                        cache["album#{item.album.id}"] = 'list': parseTrackFromHTML body
                                        common.extend cache["album#{item.album.id}"], albumInfo
                                        handle cache["album#{item.album.id}"]
                                        cb error, item
                                    else if response.statusCode is 403
                                        console.log 403
                                        tokenCookie = /cookie="(\S+)"/.exec body
                                        if tokenCookie
                                            request = require('request')
                                            tokenCookie = tokenCookie[1]
                                            tokenCookie = request.cookie tokenCookie
                                            console.log Config.jar
                                            Config.jar.setCookie tokenCookie, 'http://www.xiami.com'
                                            # console.log tokenCookie, cookie.parse tokenCookie
                                            ###
                                            Config.cookie = cookie.serialize common.mixin cookie.parse(Config.cookie), cookie.parse(tokenCookie)
                                            ###
                                        getTrack()
                                    else
                                        getTrack()
                            getTrack.count = 0
                            getTrack()
                , (err, ret)->
                    cb err, result
            else
                cb null, result

        getInfoFromHTML = (cb)->
            cb = do ->
                rawCb = cb
                (args...)->
                    rawCb args...
            switch item.type
                when 'user'
                    urls = ("http://www.xiami.com/space/lib-song/u/#{item.id}/page/#{i}" for i in [item.start..item.end])
                    async.map urls, (uri, cb)->
                        console.log uri
                        common.get uri, (error, response, body)->
                            if not error and response.statusCode is 200
                                $ = cheerio.load body, ignoreWhitespace: true
                                songs = ($(i).attr('href').match(/song\/(\d+)/)[1] for i in $('a[href*="/song/"]'))
                                console.log songs, body
                                cb null, songs
                            else
                                cb error ? response.statusCode
                    , (err, songs)->
                        console.log songs
                        if _.isArray songs[0]
                            songs = _.union.apply null, songs
                        songs = _.uniq songs
                        common.get "http://www.xiami.com/song/playlist/id/#{songs.join ','}/type/#{type['song']}/cat/json", (error, response, body)->
                            if not error and response.statusCode is 200
                                list = []
                                if trackList = body?.data?.trackList ? body?.album?.songs # web: trackList    android: songs
                                    for song in trackList
                                        list.push parseInfoFromAPI song
                                    result =
                                        'name': "用户UID#{item.id}的第#{ item.start + if item.end and item.end isnt item.start then '至' + item.end else '' }页收藏"
                                        'type': item.type
                                        'id': item.id
                                        'start': item.start
                                        'end': item.end
                                        'list': list
                                    cb null, result
                                else
                                    cb null, undefined
                            else
                                cb error ? response.statusCode, response
                    ###
                when 'album'
                    common.get "http://www.xiami.com/album/#{item.id}", (error, response, body) ->
                        if not error and response.statusCode is 200
                            cb null, parseAlbumFromHTML body
                        else
                            cb error, response.statusCode, response
                    ###
                when 'collect'
                    # equest "http://www.xiami.com/song/collect/id/#{item.id}", proxy: common.getProxyString(), (error, response, body)->

                    common.get "http://www.xiami.com/collect/#{item.id}", (error, response, body)->
                        if not error and response.statusCode is 200
                            $ = cheerio.load body, ignoreWhitespace:true
                            name = $('.info_collect_main h2').text()
                            pictureUrl = $('#cover_logo a img').attr('src')?.replace(/_\d\.jpg/, '.jpg')# 从小图Url获得大图Url
                            cb null,
                                'name': name
                                'cover':
                                    'url': pictureUrl
                        else
                            cb error ? response.statusCode, response
                    ###
                    common.get "http://www.xiami.com/app/android/collect?id=#{item.id}", (error, response, body)->
                        name = body.collect.name
                        pictureUrl = body.collect.logo.replace /_\d\.jpg/, '.jpg'
                        cb null,
                            'name': name
                            'cover':
                                'url': pictureUrl
                    ###
                when 'artist'
                        common.get "http://www.xiami.com/artist/#{item.id}", (error, response, body)->
                            if not error and response.statusCode is 200
                                $ = cheerio.load body, ignoreWhitespace:true
                                artistName = common.replaceLast $('#title h1').text(), $('#title h1').children().text(), ''
                                pictureUrl = $('#artist_photo a img').attr('src')?.replace(/_\d\.jpg/, '.jpg')# 从小图Url获得大图Url

                                urls = ("http://www.xiami.com/artist/top/id/#{item.id}/page/#{i}" for i in [item.start..item.end])
                                async.map urls, (uri, cb)->
                                    console.log uri
                                    common.get uri, (error, response, body)->
                                        if not error and response.statusCode is 200
                                            $ = cheerio.load body, ignoreWhitespace: true
                                            songs = ($(i).attr('href').match(/song\/(\d+)/)[1] for i in $('a[href*="/song/"]'))
                                            cb null, songs
                                        else
                                            cb error
                                , (err, songs)->
                                    console.log songs, urls
                                    if _.isArray songs[0]
                                        songs = _.union.apply null, songs
                                    songs = _.uniq songs
                                    common.get "http://www.xiami.com/song/playlist/id/#{songs.join ','}/type/#{type['song']}/cat/json", (error, response, body)->
                                        if not error and response.statusCode is 200
                                            list = []
                                            if trackList = body?.data?.trackList ? body?.album?.songs # web: trackList    android: songs
                                                for song in trackList
                                                    list.push parseInfoFromAPI song
                                                result = common.mixin result,
                                                    'name': "艺人#{artistName}的第#{ item.start + if item.end and item.end isnt item.start then '至' + item.end else '' }页热门歌曲"
                                                    'type': item.type
                                                    'id': item.id
                                                    'start': item.start
                                                    'end': item.end
                                                    'list': list
                                                    'cover':
                                                        'url': pictureUrl
                                                cb null, result
                                            else
                                                cb null, undefined
                                        else
                                            cb error, response
                            else
                                cb error ? response.statusCode, response
                when 'playlist'
                    cb null, 'name': '播放列表' + item.id
                else
                    cb null, {}

        async.parallel [
            getInfoFromAPI
            getInfoFromHTML
        ], (err, result)->
            unless err
                $scope.$apply ->
                    logProgressText "#{common.type2name item.type}#{item.id}解析完毕"
                    result = _.extend.apply this, result
                    for song, id in result.list
                        #song.trackId = id + 1 if result.type is 'album'
                        song.year = result.year if result.year
                        song.cover.type = common.getCoverType song.cover.url
                    if result.type is 'song'
                        result.name = result.list[0].song.name
                        result.cover = result.list[0].cover
                        result.year = result.list[0].year
                    getTrackFromHTML result, cb
            else
                $scope.$apply ->
                    logProgressText "获取#{common.type2name item.type}#{item.id}的信息失败"
                    cb err, result
    # getInfo End

    $scope.checkAll = (i)->
        task = $scope.data[i]
        if task.checkAll
            for track in $scope.data[i].list
                $scope.data[i].checked = []
        else
            list = angular.copy task.list
            for track in $scope.data[i].list
                $scope.data[i].checked = list
                # $scope.data[i].checked = angular.copy task.list
        ###
        if task.checkAll
            for track in task.list
                task.checked = []
        else
            for track in task.list
                task.checked = angular.copy task.list
        ###

    $scope.createTask = ->
        data = angular.copy $scope.data
        result = []
        for task, i in data
            if task.checked and task.checked.length > 0
                task.list = task.checked
                delete task.checked
                for track in task.list
                    track.source = task
                    track.run = requestFile
                    track.save = ((info)->
                        console.log 'info', info
                        filename = common.replaceBat Config.filenameFormat,
                            ['%NAME%', info.song.name],
                            ['%ARTIST%', info.artist.name],
                            ['%ALBUM%', info.album.name],
                            ['%TRACK%', if info.track.id? then (if info.track.id.length is 1 then "0#{info.track.id}" else info.track.id) else ''],
                            ['%DISC%', info.track.disc ? '']
                        filename = common.getSafeFilename filename
                        switch Config.saveMode
                            when 'smartClassification'
                                switch info.source.type
                                    when 'album'
                                        foldername = common.replaceBat Config.foldernameFormat,
                                            ['%NAME%', common.safePath info.source.name ? ''],
                                            ['%ARTIST%', common.safePath info.source.artist ? ''],
                                            ['%COMPANY%', common.safePath info.source.company ? ''],
                                            ['%TIME%', common.safePath info.source.time ? ''],
                                            ['%LANGUAGE%', common.safePath info.source.language ? '']
                                    when 'artist'
                                        foldername = common.safePath info.source.name
                                    when 'collect'
                                        foldername = common.safePath info.source.name
                                    when 'user'
                                        foldername = common.safePath info.source.name
                                    when ''
                                    else
                                        foldername = ''
                                foldername = common.getSafeFoldername foldername
                            when 'alwaysClassification'
                                foldername = common.replaceBat '%ARTIST%/%NAME%',
                                    ['%NAME%', common.safePath info.album.name ? ''],
                                    ['%ARTIST%', common.safePath info.artist.name ? '']
                            when 'direct'
                            else
                                foldername = ''
                        if (info.source.type is 'album' or Config.saveMode is 'alwaysClassification') and
                        Number(info.track.cd) > 1
                            pathFolder = path.resolve Config.savePath, foldername, "disc #{info.track.disc}"
                        else
                            pathFolder = path.resolve Config.savePath, foldername
                        'path': pathFolder
                        'name': filename
                    )(track)
                result.push task
        dialog('.dialog .create').hide()
        $scope.step = 1
        TaskQueue.push.apply null, result

    $scope.check = (i1, i2)->
        task = $scope.data[i1]
        if not task.list[i2].check
            $scope.data[i1].checkAll = false

    $scope.analyze = ->
        links = $scope.links.split '\n'
        targets = do ->
            result = _.map links, (text)->
                if validator.isURL text
                    artist = common.isArtist.exec text
                    song = common.isSong.exec text
                    collect = common.isCollect.exec text
                    showcollect = common.isShowcollect.exec text
                    album = common.isAlbum.exec text
                    user = common.isUser.exec text
                    demo = common.isDemo.exec text
                    playlist = common.isPlaylist.exec text
                    if song
                        type: 'song'
                        id: song[1]
                    else if album
                        type: 'album'
                        id: album[1]
                    else if collect
                        type: 'collect'
                        id: collect[1]
                    else if showcollect
                        type: 'collect'
                        id: showcollect[1]
                    else if artist
                        type: 'artist'
                        id: artist[1]
                        start: Number artist[2] ? 1
                        end: Number artist[3] ? artist[2] ? 1
                    else if user
                        type: 'user'
                        id: user[1]
                        start: Number user[2]
                        end: Number user[3] ? user[2]
                    else if demo
                        type: 'song'
                        id: demo[1]
                    else if playlist and User.logged
                        type: 'playlist'
                        id: new Date().getTime()
            result = _.filter result, (item)->
                item
            result = _.uniq result, (item)->
                JSON.stringify item # 低效率, 要求严格的对象格式
        if targets.length > 0
            $scope.progressText = ''
            $scope.step = 2
            async.map targets, getInfo, (err, result)->
                unless err
                    $scope.$apply ->
                        $scope.links = ''
                        $scope.data = result

                        # 全选
                        i = $scope.data.length
                        console.log $scope.data, i
                        while i--
                            $scope.checkAll i
                            $scope.data[i].checkAll = true

                        $scope.step = 3
                else
                    console.error err, result, targets
        else
            alert '未输入有效的链接'

App.controller 'ExitCtrl',($scope)->
    $scope.exit = ->
        win = window.win ? window.win = gui.Window.get()
        win.close()
    $scope.hide = ->
        dialog('.dialog .exit').hide()

App.controller 'AboutCtrl',($scope)->
    $scope.version = pkg.version

App.controller 'UpdateCtrl',($scope)->
    $scope.version = pkg.version

App.controller 'SetupCtrl',($scope, User)->
    $scope.toggle = (element)->
        content = document.querySelectorAll('.dialog .setup ul.content>*')
        for i in content
            i.style.display = 'none'
        document.querySelector(element).style.display = 'flex'
        ###
        if element is 'li.login' and not User.logged
            $scope.loginPageLoad()
        ###
        return

App.controller 'NetworkCtrl', ($scope, Config)->
    $scope.config = Config

App.controller 'Id3Ctrl', ($scope, Config)->
    $scope.config = Config

App.controller 'ConfigCtrl', ($scope, Config)->
    $scope.config = Config

    $scope.openFolderChooseDialog = ->
        fileDialog = $ "<input type='file' nwdirectory='' nwworkingdir='#{$scope.config.localSavePath}'/>"
        fileDialog.change (e)->
            $scope.$apply ->
                $scope.config.savePath = fileDialog.val()
        fileDialog.click()
        return

App.controller 'LoginCtrl', ($scope, Config, User, $localForage, $sce)->
    $localForage.getItem('account').then (data)->
        if data
            $scope.email = data.email
            $scope.password = data.password
            $scope.remember = data.remember
    $scope.user = User
    $scope.user.logged = false

    formData = []

    setLogged = (cb)->
        pCookieSaved = Promise.all [$localForage.setItem('config.jar', Config.jar), $localForage.setItem('config.cookie', Config.cookie)]
        console.log Config.jar, Config.cookie
        pCookieSaved.then ->
            async.waterfall [
                (cb)->
                    common.post 'http://www.xiami.com/index/home', cb
                (response, body, cb)->
                    console.log response
                    cb null, body
            ],(err, result)->
                if err
                    console.error err, result
                else
                    $scope.$apply ->
                        console.log result
                        if result.data?.userInfo?.user_id?
                            console.log result
                            User.logged = true
                            User.name = result.data.userInfo.nick_name
                            User.avatar = "http://img.xiami.net/#{result.data.userInfo.avatar}"
                            User.id = result.data.userInfo.user_id
                            User.isVip = not not result.data.userInfo.isVip
                            User.isMusician = not not result.data.userInfo.isMusician
                            User.sign =
                                hasCheck: not not result.data.userInfo.is # 是否已签到
                                num: result.data.userInfo.sign.persist_num # 签到天数
                            User.level =
                                name: result.data.userInfo.level
                                num: result.data.userInfo.numlevel
                                credit: result.data.userInfo.credits # 当前等级分数
                                creditLimit: result.data.userInfo.creditslimit.high # 当前等级分数上限
                            User.pyramid = result.data.pyramid # 成就

                            if User.isVip
                                # open hq
                                common.post 'http://www.xiami.com/vip/update-tone',
                                    user_id: User.id
                                    tone_type: 1
                                , Referer: 'http://www.xiami.com/vip/myvip', null
                        else
                            console.log '登录失败, 你所在的国家或地区可能无法使用虾米音乐网, 请开通VIP后再试.'
                            console.error result
            ###
            request.post 'http://www.xiami.com/vip/update-tone',
                proxy: common.getProxyString()
                headers:
                    common.mixin Config.headers,
                        Cookie: Config.cookie
                        Referer: 'http://www.xiami.com/vip/myvip'
                form:
                    user_id: User.id
                    tone_type: 1
            ###

    $scope.logout = ->
        Config.cookie = ''
        pCookieRemoved = Promise.all [$localForage.removeItem('config.cookie'), $localForage.removeItem('config.jar')]
        pCookieRemoved.then (values)->
            $scope.$apply ->
                for i in Object.keys User
                    delete User[i]
                User.logged = false
                # $scope.loginPageLoad()
                common.loadLoginPage()

    $scope.sign = ->
        common.post 'http://www.xiami.com/task/signin'
            ,(error, response, body, cb)->
                unless error
                    $scope.$apply ->
                        User.sign.hasCheck = true
                        User.sign.num = +body
                else
                    console.error error
        ###
        request.post 'http://www.xiami.com/task/signin',
            headers: common.mixin Config.headers,
                Cookie: Config.cookie
                Referer: 'http://www.xiami.com/'
            proxy: common.getProxyString()
            ,(error, response, body, cb)->
                if not error
                    $scope.$apply ->
                        User.sign.hasCheck = true
                        User.sign.num = +body
                else
                    console.error error
        ###

    $scope.loginByWeb = ->
        newWindow = gui.Window.open 'https://login.xiami.com/member/login',
            'frame': true
            'toolbar': false
        newWindow.on 'closed', ->
            require('nw.gui').Window.get().cookies.getAll
                    domain: '.xiami.com'
                ,(cookies)->
                    console.log cookies
                    Config.cookie = do ->
                        ret = ''
                        for i in cookies
                            ret += "#{i.name}=#{i.value}; "
                        ret
                    $scope.$apply setLogged

                    newWindow = null

    $scope.loginByCookie = ->
        Config.cookie = $scope.cookie
        setLogged()

    $scope.refreshVerification = ->
        img = fs.createWriteStream 'validate.png'
        img.on 'finish',->
            $scope.$apply ->
                $scope.validateUrl = "app://XiamiThief/validate.png?#{Math.random()}"
        common.getReq("https://login.xiami.com/coop/checkcode?forlogin=1&t=#{Math.random()}").pipe img

    _.defer ->
        window.setLogged = setLogged

        ###
        pCookie = Promise.all [$localForage.getItem('config.jar'), $localForage.getItem('config.cookie')]
        pCookie.then ([jar, cookie])->
            console.log jar, cookie
            # Config.jar = jar if _.isObject jar
            Config.cookie = cookie if _.isString cookie
            consolo.log Config.jar, Config.cookie
            setLogged()
        ###

    # $scope.login End
