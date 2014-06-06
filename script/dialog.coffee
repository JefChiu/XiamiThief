'use strict'

gui = require 'nw.gui'
pkg = require '../package.json'
async = require 'async'
http = require 'http'
https = require 'https'
common = require '../script/common'
request = (require 'request').defaults
	jar: true
	headers: common.config.headers
	followAllRedirects: false
	strictSSL: false
	proxy: false
cheerio = require 'cheerio'
cookie = require 'cookie'
tunnel = require 'tunnel'
fs = require 'fs'
url = require 'url'
path = require 'path'
mkdirp = require 'mkdirp'
ent = require 'ent'
{id3v23} = require '../script/id3v2'
genre = require '../script/genre'

App.factory 'Config',->
	common.config

App.controller 'CreateCtrl',($scope, TaskQueue, Config, User)->
	type =
		song: 0
		album: 1
		artist: 2
		showcollect: 3

	cache = {}

	$scope.type = type
	$scope.step = 1
	$scope.links = ''
	$scope.data = []

	getLocation = (sid, cb)->
		if true or user.logged
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
					if not error and response.statusCode is 200
						console.log body
						result = common.parseLocation body.location
						if result
							cb null, result.trim()
						else
							cb result
					else
						cb error, ''
		else
			console.log 'not login'

	requestFile = (cb)->
		info = this
		getLocation this.song.id, (err, location)->
			if location
				filename = common.replaceBat Config.filenameFormat,
							['%NAME%', info.song.name]
							['%ARTIST%', info.artist.name]
							['%ALBUM%', info.album.name]
							['%TRACK%', if info.track.id? then (if info.track.id.length is 1 then "0#{info.track.id}" else info.track.id) else '']
							['%DISC%', info.track.disc ? '']
				filename = common.getSafeFilename filename
				switch info.source.type
					when 'album'
						foldername = common.replaceBat Config.foldernameFormat,
									['%NAME%', info.source.name ? '']
									['%ARTIST%', info.source.artist ? '']
									['%COMPANY%', info.source.company ? '']
									['%TIME%', info.source.time ? '']
									['%LANGUAGE%', info.source.language ? '']
					when 'artist'
						foldername = info.source.artist
					else
						foldername = ''
				foldername = common.getSafeFoldername foldername
				if info.source.type is 'album' and info.track.cd is '2'
					pathFolder = path.resolve Config.savePath, "disc #{info.track.disc}", foldername
				else
					pathFolder = path.resolve Config.savePath, foldername
				mkdirp pathFolder, (err)->
					if not err
						savePath = path.resolve Config.savePath, foldername, filename
						async.auto
							coverDownload: (cb)->

								coverPath = path.resolve Config.savePath, foldername, "#{info.album.id}.jpg"

								resizeImage = (imagePath)->
									maxSide = if Config.id3.size is 'standard' then 640 else Config.id3.cover.maxSide
									id3CoverPath = path.resolve Config.savePath, foldername, "#{info.album.id}_#{maxSide}.jpg"
									fs.exists id3CoverPath, (exists)->
										if exists
											fs.readFile id3CoverPath, cb
										else
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
														f.on 'error', (err)->
															cb err
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
										
								console.log 'coverDownload'
								if Config.hasCover or (Config.hasId3 and Config.id3.hasCover)
									console.log 'coverDownload is true'
									fs.exists coverPath, (exists)->
										if exists
											if Config.hasId3 and Config.id3.hasCover
												if Config.id3.cover.size is 'original'
													fs.readFile coverPath
												else
													resizeImage coverPath
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
															resizeImage coverPath
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
							lyricDownload: (cb)->
								console.log 'lyricDownload'
								if (Config.hasLyric or (Config.hasId3 and Config.id3.hasLyric)) and info.lyric.url
									console.log 'lyricDownload is true'
									if Config.hasLyric
										f = fs.createWriteStream "#{savePath}.lrc"
										f.on 'finish', ->
											if Config.hasId3 and Config.id3.hasLyric
												fs.readFile "#{savePath}.lrc", (err, data)->
													cb err, data.toString()
											else
												cb null
										f.on 'error', (err)->
											cb err
										request(info.lyric.url, 
											jar: false
											headers: {}
											proxy: common.getProxyString()
										).pipe f
									else
										request info.lyric.url,
											jar: false
											headers: {}
											proxy: common.getProxyString()
											, (error, response, body)->
												cb error, body
								else
									cb null
							writeId3Info: ['coverDownload' if Config.id3.hasCover, 'lyricDownload' if Config.id3.hasLyric, (cb, result)->
								console.log result
								console.log 'writeId3Info'
								if Config.hasId3
									console.log 'writeId3Info is true'
									id3Writer = new id3v23("#{savePath}.download")
									# TALB 专辑名
									if Config.id3.hasAlbum and info.album.name
										id3Writer.setTag 'TALB', info.album.name

									# TPE1 艺术家/主唱
									if Config.id3.hasArtist and info.artist.name
										id3Writer.setTag 'TPE1', info.artist.name

									# TPE2 专辑艺术家/乐队
									if Config.id3.hasAlbumArtist and info.album.artist
										id3Writer.setTag 'TPE2', info.album.artist

									# TIT2 歌名
									if Config.id3.hasTitle and info.song.name
										id3Writer.setTag 'TIT2', info.song.name

									# TRCK 音轨号
									if Config.id3.hasTrack and info.track.id
									    id3Writer.setTag 'TRCK', info.track.id

									# TYER 灌录年份
									if Config.id3.hasYear and info.year
									    id3Writer.setTag 'TYER', info.year

									# APIC 专辑封面
									if Config.id3.hasCover and image = result.coverDownload
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
							]
							fileDownload: ['writeId3Info', fileDownload = (cb)->
								req = http.get (->
										if Config.useProxy is 'true'
											common.mixin url.parse(location),
												agent: tunnel.httpsOverHttp
													proxy:
														host: Config.proxy.host
														port: Config.proxy.port
														proxyAuth: "#{Config.proxy.username}:#{Config.proxy.password}"
										else
											location
									)(), (res)->
										switch res.statusCode
											when 200
												f = fs.createWriteStream "#{savePath}.download",
													flags: 'a'
													encoding: null
													mode: 0o666

												f.on 'finish',->
													fs.rename "#{savePath}.download", "#{savePath}.mp3", ->
														cb null

												f.on 'error',(err)->
													console.log err
													cb err
												res.pipe f
											when 302
												res.resume()
												location = res.headers.location
												fileDownload cb
											else
												cb '无法下载'

								req.on 'error',(err)->
									cb err
							]
							, (err, result)->
								cb err

					else
						cb err

	getInfo = (item, cb)->
		console.log common.getProxyString()
		async.parallel [
				(cb)->
					# "http://www.xiami.com/app/xiating/album?id=#{item.id}" HTML
					if item.type is 'album'
						uri = "http://www.xiami.com/app/android/album?id=#{item.id}" # android api only for track
					else
						uri = "http://www.xiami.com/song/playlist/id/#{item.id}/type/#{type[item.type]}/cat/json"
					request
						url: uri
						json: true
						proxy: common.getProxyString()
						, (error, response, body)->
							if not error and response.statusCode is 200
								result = 
									type: item.type
									id: item.id
									list: (->
											result = []
											console.log body
											for song in body.data?.trackList ? body.album?.songs # web: trackList  android: songs
												songId = song.song_id
												songName = ent.decode song.name ? song.title # web: title  android: name
												albumId = song.albumId ? song.album_id
												albumName = ent.decode song.album_name ? song.title # web: album_name  android: album.title
												albumArtist = song.artist_name # android only
												artistName = ent.decode song.artist ? song.singers # web: artist  android: singers
												artistId = song.artist_id
												lyricUrl = song.lyric if song.lyric?.indexOf('.lrc') isnt -1
												pictureUrl = (song.pic ? song.album_logo).replace /_\d/, ''# 从小图Url获得大图Url web: pic  android: album_logo
												trackId = song.track # android only
												discNum = song.cd_serial # android only
												cdCount = song.cd_count # android only
												result.push
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
											result
										)()
								if item.type isnt 'album' and Config.filenameFormat.indexOf('%TRACK%') isnt -1
									async.map result.list,
										(item, cb)->
											handle = (list)->
												for song in list
													songId = song.song_id
													trackId = song.track
													discNum = song.cd_serial

													if songId is item.song.id
														item.track.disc = discNum
														item.track.id = trackId
														break
											if "album#{item.album.id}" in cache
												handle cache["album#{item.album.id}"]
												cb error, item
											else
												uri = "http://www.xiami.com/app/android/album?id=#{item.album.id}"
												request
													url: uri,
													json: true
													proxy: common.getProxyString()
													,(error, response, body)->
														if not error and response.statusCode is 200
															if body.album
																cache["album#{item.album.id}"] = body.album.songs
															else
																error = '遭到屏蔽, 暂时无法使用'
															handle cache["album#{item.album.id}"]
														cb error, item
										, (err, ret)->
											cb err, result
								else
									cb null, result
							else
								cb error, {}
				(cb)->
					switch item.type
						when 'album'
							request "http://www.xiami.com/album/#{item.id}", proxy: common.getProxyString(), (error, response, body) ->
								if not error and response.statusCode is 200
									$ = cheerio.load body, ignoreWhitespace:true
									name = common.replaceLast $('#title h1').text(), $('#title h1').children().text(), ''
									#pictureUrl = $('#album_cover a img').attr('src')?.replace(/_\d/, '')# 从小图Url获得大图Url
									info = $('#album_info table tr').toArray()# 专辑信息
									artistInfo = $(info[0]).children().last().text()# 艺人
									languageInfo = $(info[1]).children().last().text()# 语种
									companyInfo = $(info[2]).children().last().text()# 唱片公司
									timeInfo = $(info[3]).children().last().text()# 发行时间
									typeInfo = $(info[4]).children().last().text()# 专辑类别
									styleInfo = $(info[5]).children().last().text()# 专辑风格
									cb null,
										name:name
										artist:artistInfo
										language:languageInfo
										company:companyInfo
										time:timeInfo
										style:styleInfo
										year:timeInfo.substring(0,4)
										#picture:list[0].picture
						when 'showcollect'
							request "http://www.xiami.com/song/showcollect/id/#{item.id}", proxy: common.getProxyString(), (error, response, body)->
								if not error and response.statusCode is 200
									$ = cheerio.load body, ignoreWhitespace:true
									name = $('#xiami-content h1').text()
									#pictureUrl = $('#cover_logo a img').attr('src')?.replace(/_\d/, '')# 从小图Url获得大图Url
									cb null,
										name:name
										#pictureUrl:pictureUrl
						when 'artist'
							request "http://www.xiami.com/artist/#{item.id}", proxy: common.getProxyString(), (error, response, body)->
								if not error and response.statusCode is 200
									$ = cheerio.load body, ignoreWhitespace:true
									name = common.replaceLast $('#title h1').text(), $('#title h1').children().text(), ''
									cb null,
										name:name
						else
							cb null, {}
			], (err, result)->
				if not err
					result = _.extend.apply this, result
					for song, id in result.list
						song.trackId = id + 1 if result.type is 'album'
						song.year = result.year if result.year
					console.log result
					result.name = result.list[0].song.name if result.type is 'song'
				cb err, result
	# getInfo End

	$scope.checkAll = (i)->
		task = $scope.data[i]
		if task.checkAll
			for track in $scope.data[i].list
				$scope.data[i].checked = []
		else
			for track in $scope.data[i].list
				$scope.data[i].checked = angular.copy task.list
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
				#delete data[i].checked
				for track in task.list
					track.source = task
					track.run = requestFile
					result.push track
		dialog('.dialog .create').hide()
		$scope.step = 1
		TaskQueue.push.apply null, result

	$scope.check = (i1, i2)->
		task = $scope.data[i1]
		if not task.list[i2].check
			$scope.data[i1].checkAll = false

	$scope.analyze = ->
		urls = $scope.links.split '\n'
		targets = (->
			isArtist = /www.xiami.com\/artist\/(\d+)/
			isSong = /www.xiami.com\/song\/(\d+)/
			isShowcollect = /www.xiami.com\/song\/showcollect\/id\/(\d+)/
			isAlbum = /www.xiami.com\/album\/(\d+)/
			result = _.map urls, (url)->
				artist = isArtist.exec url
				song = isSong.exec url
				showcollect = isShowcollect.exec url
				album = isAlbum.exec url
				if song
					type: 'song'
					id: song[1]
				else if album
					type: 'album'
					id: album[1]
				else if showcollect
					type: 'showcollect'
					id: showcollect[1]
				else if artist
					type: 'artist'
					id: artist[1]
			result = _.filter result, (item)->
				item
			result = _.uniq result, (item)->
				JSON.stringify item # 低效率, 要求严格的对象格式
		)()
		if targets.length > 0
			async.map targets, getInfo ,(err, result)->
				if not err
					$scope.$apply ->
						$scope.step = 2
						$scope.links = ''
						$scope.data = result
				else
					console.log err, result, targets
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

App.controller 'SetupCtrl',($scope)->
	$scope.toggle = (element)->
		content = document.querySelectorAll('.dialog .setup ul.content>*')
		for i in content
			i.style.display = 'none'
		document.querySelector(element).style.display = 'flex'
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
				$scope.config.localSavePath = fileDialog.val()
		fileDialog.click()
		return

App.controller 'LoginCtrl', ($scope, Config, User, $localForage, $sce)->
	$localForage.get('account').then (data)->
		if data
			$scope.email = data.email
			$scope.password = data.password
			$scope.remember = data.remember
	$scope.logged = false
	$scope.user = User
	formData = []

	getForm = ->
		async.waterfall [
				(cb)->
					request 'https://login.xiami.com/member/login' ? 'http://www.xiami.com/member/login', proxy: common.getProxyString(), cb
				(response, body, cb) ->
					if response.statusCode is 200
						$ = cheerio.load(body, ignoreWhitespace:true)
						$scope.$apply ->
							$scope.taobaoLoginPage = $sce.trustAsResourceUrl url.resolve response.request.href, $('iframe').attr('src') # taobao login
						fields= $('form input').toArray()
						data = {}
						for field in fields
							name = $(field).attr('name') ? ''
							value = $(field).attr('value') ? ''
							data[name] = value
						if data.validate?
							img = fs.createWriteStream 'validate.png'
							img.on 'finish',->
								cb null, data
							request("https://login.xiami.com/coop/checkcode?forlogin=1&t=#{Math.random()}", proxy: common.getProxyString()).pipe img
						else
							cb null, data
					else
						cb null, {}
				(data, cb)->
					if data.validate?
						$scope.$apply ->
							$scope.validateUrl = "validate.png?#{Math.random()}"
					formData = data
					cb null, data
			], (err, result)->
				if err
					console.log err, result
	getForm()

	$scope.logout = ->
		Config.cookie = ''
		for i in Object.keys User
			delete User[i]
		$scope.logged = false
		getForm()

	$scope.sign = ->
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
					console.log error

	$scope.taobaoPageLoad = ->
		iframe = document.querySelector 'iframe'
		iframeUrl = url.parse iframe.contentDocument.URL
		#console.log iframeUrl, iframe.contentDocument.cookie
		if iframeUrl.href is 'http://www.xiami.com/'
			require('nw.gui').Window.get().cookies.getAll
					domain: '.xiami.com'
				,(cookies)->
					Config.cookie = (->
						ret = ''
						for i in cookies
							ret += "#{i.name}=#{i.value}; "
						ret
					)()
					$scope.$apply ->
						$scope.logged = true
						# 重复 Begin
						async.waterfall [
								(cb)->
									request.post 'http://www.xiami.com/index/home',
										proxy: common.getProxyString()
										headers: common.mixin(Config.headers,
											Cookie: Config.cookie
										),cb
								(response, body, cb)->
									cb null, JSON.parse body
							],(err, result)->
								if err
									console.log err, result
								else
									$scope.$apply ->
										console.log result
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
											request.post 'http://www.xiami.com/vip/update-tone',
												proxy: common.getProxyString()
												headers:
													common.mixin Config.headers,
														Cookie: Config.cookie
														Referer: 'http://www.xiami.com/vip/myvip'
												form:
													user_id: User.id
													tone_type: 1
						# 重复 End

	$scope.login = ->
		formData['email'] = $scope.email
		formData['password'] = $scope.password
		formData['validate'] = $scope.validate if $scope.validateUrl
		if $scope.remember
			$localForage.setItem('account',
				email: $scope.email
				password: $scope.password
				remember: $scope.remember
			).then()
		else
			$scope.email = $scope.password = ''
			$localForage.removeItem('account').then()
		$scope.validate = ''

		async.series [
			(cb)->
				async.waterfall [
						(cb)->
							request.post 'http://www.xiami.com/member/login' ? 'https://login.xiami.com/member/login',
								form: formData
								proxy: common.getProxyString()
								headers: common.mixin(Config.headers,
									'Referer': 'http://www.xiami.com/member/login' ? 'https://login.xiami.com/member/login'
									'Host': 'www.xiami.com' ? 'login.xiami.com'
									'Origin': 'http://www.xiami.com' ? 'https://login.xiami.com'
								), cb
						(response, body, cb) ->
							fs.unlinkSync 'validate.png' if fs.existsSync 'validate.png'
							cb null, response.headers['set-cookie']?.toString()
					],(err, result)->
						if err
							console.log err, result
							cb()
						else
							Config.cookie = result
							$scope.$apply ->
								$scope.logged = true
								cb()
			(cb)->
				async.waterfall [
						(cb)->
							request.post 'http://www.xiami.com/index/home',
								proxy: common.getProxyString()
								headers: common.mixin(Config.headers,
									Cookie: Config.cookie
								),cb
						(response, body, cb)->
							cb null, JSON.parse body
					],(err, result)->
						if err
							console.log err, result
							cb()
						else
							$scope.$apply ->
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
								cb()
		], (err, result)->
			if User.isVip
				# open hq
				request.post 'http://www.xiami.com/vip/update-tone',
					proxy: common.getProxyString()
					headers:
						common.mixin Config.headers,
							Cookie: Config.cookie
							Referer: 'http://www.xiami.com/vip/myvip'
					form:
						user_id: User.id
						tone_type: 1
	# $scope.login End