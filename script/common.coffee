'use strict'

path = require 'path'
fs = require 'fs'

execPath = path.dirname process.execPath

config = 
	savePath: execPath
	foldernameFormat: '%NAME%'
	filenameFormat: '%NAME%'
	taskLimitMax: 3
	cookie : ''
	hasLyric: false
	hasCover: true
	hasId3: true
	useProxy: 'false'
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
		'Host': 'www.xiami.com'
		'Origin': 'http://www.xiami.com'
		'User-Agent': 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.22 Safari/537.36'

user = {}

mixin = (args...) ->
	result = {}
	for obj in args
		for key, value of obj
			result[key] = value
	result

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
		_loc_6[_loc_7] = ""	if _loc_6[_loc_7] is undefined
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
	console.log RegExp(str + '$')
	search.replace RegExp(str + '$'), newStr

replaceBat = (str, args...)->
	for [sv, nv] in args 
		sv = RegExp sv, g if not sv instanceof RegExp
		str = str.replace sv, nv
	str

toNum = (obj)->
	if isNaN obj then Number obj else obj

safeFilter = (str) ->
    removeSpan = (str)->
        str.replace('<span>', ' ').replace '</span>', ''
    safeFilename = (str)->
        str.replace /(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' '
    safeFilename removeSpan str

getSafeFoldername = (str)->
	str = str.replace /^\.+$/, '_'
	str = str.replace /(\.)+$/, ''
	str = safeFilter str
	str = str[...229]

getSafeFilename = (str)->
	str = safeFilter str
	str = str[...220]

getProxyString = ->
	if config.useProxy is 'true'
		options = config.proxy
		"#{options.username}:#{options.password}@#{options.host}:#{options.port}"
	else
		false

module.exports = {
	execPath
	config
	user
	mixin
	parseLocation
	replaceLast
	replaceBat
	toNum
	safeFilter
	getSafeFilename
	getSafeFoldername
	getProxyString
}