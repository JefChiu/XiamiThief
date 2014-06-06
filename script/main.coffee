'use strict'

gui = require 'nw.gui'
pkg = require '../package.json'
path = require 'path'
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

#win.showDevTools()

#window.addEventListener 'load', ->win.show()

#window.openBrowser = gui.Shell.openExternal

window.dialog = (element)->
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
		type:'normal'
		label:'新建下载'
		click:->
			dialog('.dialog .create').show()

	menu.append menuItem
		type:'separator'

	menu.append menuItem
		type:'normal'
		label:'软件设置'
		click:->
			dialog('.dialog .setup').show()
	###
	menu.append menuItem
		type:'separator'

	menu.append menuItem
		type:'normal'
		label:'反馈'
		click:->
			dialog('.dialog .feedback').show()

	menu.append menuItem
		type:'normal'
		label:'检查更新'
		click:->
			dialog('.dialog .update').show()

	menu.append menuItem
		type:'normal'
		label:'关于XiamiThief'
		click:->
			dialog('.dialog .about').show()
	###
	menu.append menuItem
		type:'separator'

	menu.append menuItem
		type:'normal'
		label:'退出'
		click:->
			if window.tray?
				win.close()
			else
				dialog('.dialog .exit').show()

	menu
)()

win.on 'close',->
	@hide()
	@close true

###
win.on 'resize',->
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
		@remove()
		window.tray = null
	@hide()

###
win.on 'new-win-policy', (frame, url, policy)->
	console.log frame, url, policy
###

#window.clipboard = gui.Clipboard.get()

App.factory 'User',->
	common.user

App.factory 'TaskQueue',['$rootScope', 'Config', 'quickRepeatList', ($rootScope, Config, quickRepeatList)->
		queue = (concurrency = 1)->
			q=
				pre: []
				run: []
				end: []
				err: []
				push: (args...)->
					q.pre.push.apply q.pre, args
					q.preToRun()
				preToRun: ->
					console.log 'preToRun'
					#console.log q.pre.length, q.run.length, q.end.length, q.err.length, q.pre.length + q.run.length + q.end.length + q.err.length
					free = concurrency - q.run.length
					#console.log "#{concurrency} - #{q.run.length} = #{free}"
					#console.log _.clone(q.pre), _.clone(q.run), _.clone(q.end), _.clone(q.err)
					if free > 0
						while free--
						#loop
							if q.pre.length > 0
								((task)->
									task.run (err, data)->
										i = _.indexOf(q.run, task)
										if not err
											q.end.push task
										else
											q.err.push task
										q.run.splice i, 1
										_.defer quickRepeatList.pre, _.groupBy q.pre, (obj)->
											[obj.source.type, obj.source.id]
										_.defer quickRepeatList.err, _.groupBy q.err, (obj)->
											[obj.source.type, obj.source.id]
										_.defer quickRepeatList.run, _.groupBy q.run, (obj)->
											[obj.source.type, obj.source.id]
										_.defer quickRepeatList.end, _.groupBy q.end, (obj)->
											[obj.source.type, obj.source.id]
										###
										try
											$rootScope.$apply()
										catch e
											console.log e
										###
										q.preToRun()
									q.run.push task
								)(q.pre.shift()) # 对task闭包
							else
								break
							#break unless free--
					_.defer quickRepeatList.pre, _.groupBy q.pre, (obj)->
						[obj.source.type, obj.source.id]
					_.defer quickRepeatList.err, _.groupBy q.err, (obj)->
						[obj.source.type, obj.source.id]
					_.defer quickRepeatList.run, _.groupBy q.run, (obj)->
						[obj.source.type, obj.source.id]
					_.defer quickRepeatList.end, _.groupBy q.end, (obj)->
						[obj.source.type, obj.source.id]
				concurrency: (value)->
					concurrency = value if value?
					concurrency
		q = queue Config.taskLimitMax
	]

App.controller 'TaskCtrl',($scope, TaskQueue, quickRepeatList)->
	$scope.pre = TaskQueue.pre
	$scope.err = TaskQueue.err
	$scope.run = TaskQueue.run
	$scope.end = TaskQueue.end

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
		if e.keyCode is 27 # esc key
			dialogAllHide()

	$(document).keydown (e)->
		if e.keyCode is 93 # menu key
			{left, top} = document.querySelector('.button-menu').getBoundingClientRect()
			menu.popup left, top

	$('.dialog>*').click (e)->
		e.stopPropagation()

	win.show()