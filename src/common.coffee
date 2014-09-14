'use strict'

path = require 'path'
fs = require 'fs'
_ = require 'underscore'
request = require 'request'
timers = require 'timers'

isArtist = /www.xiami.com\/artist\/(?:top\/id\/)?(\d+)(?:\/page\/(\d+)-?(\d+)?)?/
isSong = /www.xiami.com\/song\/(\d+)/
isCollect = /www.xiami.com\/collect\/(\d+)/
isShowcollect = /www.xiami.com\/song\/showcollect\/id\/(\d+)/
isAlbum = /www.xiami.com\/album\/(\d+)/
isUser = /www.xiami.com\/space\/lib-song\/u\/(\d+)\/page\/(\d+)-?(\d+)?/
isPlaylist = /www.xiami.com\/play/

leftTrim = (str)->
    str?.replace /^\s+/, ''

rightTrim = (str)->
    str?.replace /\s+$/, ''

setInterval = (func, delay)->
    timers.setTimeout ->
        if not func()
            setInterval func, delay
    , delay
    
execPath = path.dirname process.execPath

config = 
    jar: request.jar()
    savePath: path.resolve execPath, 'Music'
    foldernameFormat: '%NAME%'
    filenameFormat: '%NAME%'
    taskLimitMax: 3
    cookie : ''
    hasLyric: false
    hasCover: true
    hasId3: true
    useProxy: 'false'
    #useDirectory: true
    useMonitoringClipboard: false
    saveMode: 'smartClassification'
    fileExistSolution: 'coverSmallFile'
    proxy:
        host: ''
        port: 80
        username: ''
        password: ''
    id3:
        hasTitle: true
        hasArtist: true
        hasAlbumArtist: true
        hasAlbum: true
        hasYear: true
        hasTrack: true
        hasGenre: true
        hasDisc: true
        hasCover: true
        hasLyric: false
        cover:
            size: 'standard'
            maxSide: 640
    headers :
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        'Accept-Language': 'zh-CN,zh;q=0.8'
        'Cache-Control': 'max-age=0'
        'Connection': 'keep-alive'
        # 'Host': 'www.xiami.com'
        'Origin': 'http://www.xiami.com'
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36'

user = {}

mixin = (args...) ->
    result = {}
    for obj in args
        for key, value of obj
            result[key] = value
    result
    
extend = (source, args...)->
    for obj in args
        for key, value of obj
            source[key] = value
    source

parseLocation = (param1) ->
    _loc_10 = undefined
    return param1  if param1.indexOf("http://") isnt -1
    _loc_2 = Number(param1.charAt(0))
    _loc_3 = param1.substring(1)
    _loc_4 = Math.floor(_loc_3.length / _loc_2)
    _loc_5 = _loc_3.length % _loc_2
    _loc_6 = new Array()
    _loc_7 = 0
    while _loc_7 < _loc_5
        _loc_6[_loc_7] = ""    if _loc_6[_loc_7] is undefined
        _loc_6[_loc_7] = _loc_3.substr((_loc_4 + 1) * _loc_7, (_loc_4 + 1))
        _loc_7 = _loc_7 + 1
    _loc_7 = _loc_5
    while _loc_7 < _loc_2
        _loc_6[_loc_7] = _loc_3.substr(_loc_4 * (_loc_7 - _loc_5) + (_loc_4 + 1) * _loc_5, _loc_4)
        _loc_7 = _loc_7 + 1
    _loc_8 = ""
    _loc_7 = 0
    while _loc_7 < _loc_6[0].length
        _loc_10 = 0
        while _loc_10 < _loc_6.length
            _loc_8 = _loc_8 + _loc_6[_loc_10].charAt(_loc_7)
            _loc_10 = _loc_10 + 1
        _loc_7 = _loc_7 + 1
    _loc_8 = unescape(_loc_8)
    _loc_9 = ""
    _loc_7 = 0
    while _loc_7 < _loc_8.length
        if _loc_8.charAt(_loc_7) is "^"
            _loc_9 = _loc_9 + "0"
        else
            _loc_9 = _loc_9 + _loc_8.charAt(_loc_7)
        _loc_7 = _loc_7 + 1
    _loc_9 = _loc_9.replace("+", " ")
    _loc_9
    ###
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
    ###
# parseLocation

replaceLast = (search, str, newStr)->
    # console.log RegExp(str + '$')
    search?.replace RegExp(str + '$'), newStr

replaceBat = (str, args...)->
    for [sv, nv] in args 
        sv = RegExp sv, g if not sv instanceof RegExp
        str = str?.replace sv, nv
    str

toNum = (obj)->
    if isNaN obj then Number obj else obj

inStr = (obj1, obj2)->
    try
        obj1.indexOf(obj2) isnt -1
    catch e
        false

###
safeFilter = (str) ->
    removeSpan = (str)->
        str.replace('<span>', ' ').replace '</span>', ''
    safeFilename = (str)->
        # str.replace /(\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
        str.replace /(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
    safeFilename removeSpan str
###
safePath = (str)->
    str = str?.replace /(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '

getSafeFoldername = (str)->
    str = str?.replace /^\.+$/, '_'
    str = str?.replace /(\.)+$/, ''
    # str = str.replace /(\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
    str = str?.trim()
    str = str?[...229]

getSafeFilename = (str)->
    str = str?.replace /(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
    str = leftTrim str
    str = str?[...220]

getProxyString = ->
    if config.useProxy is 'true'
        options = config.proxy
        result = ''
        if options.host[...4] isnt 'http'
            result += 'http://'
        if options.username
            result += options.username + ':' + options.password +'@'
        result += options.host + ':' + options.port or '80'
        # result = "#{options.username}:#{options.password}@#{options.host}:#{options.port}"
        result
    else
        false

getValidArray = (arr)->
    ret = (i for i in arr when i)
    ret
    ###
    console.log arr
    ret = []
    for i in arr
        ret.push if i
    console.log ret
    ret
    ###

index = (arr, i)->
    if i < 0
        arr[arr.length + i]
    else
        arr[i]

module.exports = {
    leftTrim
    rightTrim
    execPath
    config
    user
    index
    mixin
    extend
    parseLocation
    replaceLast
    replaceBat
    toNum
    safePath
    getSafeFilename
    getSafeFoldername
    getProxyString
    getValidArray
    inStr
    ###
    get
    post
    ###
    isArtist
    isSong
    isCollect
    isShowcollect
    isAlbum
    isUser
    isPlaylist
    setInterval
}