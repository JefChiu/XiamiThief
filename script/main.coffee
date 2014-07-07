'use strict'

gui = require 'nw.gui'
pkg = require '../package.json'
path = require 'path'
timers = require 'timers'
async = require 'async'
queue = require '../script/queue'
common = require '../script/common'

process.on('uncaughtException',(err)->
	console.error err
	console.error err.stack
)

dir = 
	template:'../template'

window.win = gui.Window.get()

#window.addEventListener 'load', ->win.show()

#window.openBrowser = gui.Shell.openExternal

common.loadLoginPage = ->
	if not common.user.logged
    iframe = document.querySelector 'iframe.loginPage'
    cookies = require('nw.gui').Window.get().cookies
    removeCookie = (args...)->
      for i in args
        cookies.remove url: 'http://www.xiami.com', name: i
        cookies.remove url: 'http://xiami.com', name: i
        cookies.remove url: 'https://www.xiami.com', name: i
        cookies.remove url: 'https://xiami.com', name: i
    removeCookie '_xiamitoken', '_unsign_token', 'member_auth', 'user', 'isg', 't_sign_auth', 'ahtena_is_show'
    iframe.src = ''
    iframe.src = 'https://login.xiami.com/member/login'
		
window.dialog = (element)->
	window.tray?._events.click()
	element = document.querySelectorAll element if _.isString element
	if not (element.length or element.length is 0) #Not NodeList or Array
		element = [element]
	if element.length > 0
		show:->
			$('body>header').addClass 'no-drag'
			$('.dialog').css
				'z-index':1
				display:'flex'
			for i in element
				i.style.display = 'flex'
		hide:->
			$('body>header').removeClass 'no-drag'
			$('.dialog').css
				'z-index':-1
				display:'none'
			for i in element
				i.style.display = 'none'
	else
		show:->console.error 'show',element
		hide:->console.error 'hide',element

window.menu = (->
	menu = new gui.Menu()

	menuItem = (options)->
		new gui.MenuItem options

	menu.append menuItem
		type: 'normal'
		label: '新建下载'
		click: ->
			dialog('.dialog .create').show()
	menu.append menuItem
		type: 'separator'

	menu.append menuItem
		type: 'normal'
		label: '软件设置'
		click: ->
			dialog('.dialog .setup').show()
			common.loadLoginPage()
	###
	menu.append menuItem
		type: 'separator'

	menu.append menuItem
		type: 'normal'
		label: '反馈'
		click: ->
			dialog('.dialog .feedback').show()

	menu.append menuItem
		type: 'normal'
		label: '检查更新'
		click: ->
			dialog('.dialog .update').show()

	menu.append menuItem
		type: 'normal'
		label: '关于XiamiThief'
		click: ->
			dialog('.dialog .about').show()
	###
	menu.append menuItem
		type: 'separator'

	menu.append menuItem
		type: 'normal'
		label: '退出'
		click: ->
			if window.tray?
				win.close()
			else
				dialog('.dialog .exit').show()

	menu
)()

win.on 'close',->
	@hide()
	@close true

bgImg = new Image()

bgImg.addEventListener 'load', ->
	bgCanvas = document.querySelector('canvas#bg')
	bgCanvas.width = win.width
	bgCanvas.height = win.height
	stackBlurImage bgImg, bgCanvas, 100
	win.show()

win.on 'resize',->
	###
	bgCanvas = document.querySelector('canvas#bg')
	bgCanvas.width = win.width
	bgCanvas.height = win.height
	stackBlurImage bgImg, bgCanvas, 100
	###
	###
	width = if win.width > 800 then win.width else 800
	height = if win.height > 600 then win.height else 600
	win.resizeTo width, height
	###

win.on 'minimize', ->
	window.tray = new gui.Tray
		title: "#{pkg.name} #{pkg.version}"
		icon: 'resource/image/logo16.png'
	tray.menu = menu
	tray.on 'click', ->
		win.show()
		#win.restore()
		win.setAlwaysOnTop true
		win.setAlwaysOnTop false
		tray.remove()
		window.tray = null
	tray.hide()

###
win.on 'new-win-policy', (frame, url, policy)->
	console.log frame, url, policy
###

#window.clipboard = gui.Clipboard.get()

App.factory 'User', ->
	common.user
	
App.factory 'State', ->
	Ready: 0
	Running: 1
	Fail: 2
	Success: 3

App.factory 'TaskQueue', ['$rootScope', 'Config', 'quickRepeatList', 'State', ($rootScope, Config, quickRepeatList, State)->
	queue = (concurrency = Config.taskLimitMax)->
		running = 0
		refresh = ->
			_.defer quickRepeatList.task, q.list
		q = 
			list: []
			push: (args...)->
				for i in args
					i.state = State.Ready
					i.process = 0
					for j in i.list
						j.state = State.Ready
						i.process = 0
				Array::push.apply q.list, args
				q.dirtyCheck()
			dirtyCheck: ->
				console.log 'list:', q.list
				if running < concurrency
					for c in q.list
						switch c.state
							when State.Ready, State.Running
								total = c.list.length
								count = 0
								for i in c.list
									switch i.state
										when State.Ready
											i.state = State.Running
											i.run ((i)->
												(err, data)->
													console.log 'info: ', i
													console.log 'err:', err
													i.state = if err then State.Fail else State.Success
													i.process = 100
													running--
													refresh()
													q.dirtyCheck()
											)(i)
											running++
											refresh()
											return if running >= concurrency
										when State.Fail, State.Success
											count++
								if count is total
									c.state = State.Success
				refresh()
			refresh: refresh
			concurrency: ->
				concurrency = value if value?
				concurrency
	q = queue()

	timers.setInterval q.refresh, 1000

	q
]

App.controller 'TaskCtrl',($scope, TaskQueue, quickRepeatList)->
	$scope.showCreateDialog = ->
		dialog('.dialog .create').show()
	$scope.showSetupDialog = ->
		dialog('.dialog .setup').show()
		common.loadLoginPage()
		
	$scope.list = TaskQueue.list

	###
	$scope.pre = TaskQueue.pre
	$scope.err = TaskQueue.err
	$scope.run = TaskQueue.run
	$scope.end = TaskQueue.end
	###

App.controller 'InfoCtrl',($scope,User)->
	$scope.user = User

#win.setMinimumSize 800,600
#win.setResizable true

$ ->
	dialogAllHide = ->
		dialog('.dialog>*').hide()

	$('.dialog').click dialogAllHide

	document.body.addEventListener 'contextmenu',(ev)->
		ev.preventDefault()
		# menu.popup(ev.x, ev.y)
		false

	$(document).keyup (e)->
		switch e.keyCode
			when 27 # Esc
				dialogAllHide()
			when 123 # F12
				win.showDevTools()
			when 13 # Enter
				dialog('.dialog .create').show()

	$(document).keydown (e)->
		if e.keyCode is 93 # menu key
			{left, top} = document.querySelector('.button-menu').getBoundingClientRect()
			menu.popup left, top

	$('.dialog>*').click (e)->
		e.stopPropagation()

	bgImg.src = path.resolve common.execPath, 'bg' #'../resource/image/111.jpg'