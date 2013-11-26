'use strict'

path = require 'path'
fs = require 'fs'
gui = require 'nw.gui'
url = require 'url'
child_process = require 'child_process'
mkdirp = require 'mkdirp'
pkg = require './package.json'
core = require './js/core'

process.on('uncaughtException',(err)->
    console.error err
    console.error err.stack
    core.log err
)

window.win = gui.Window.get()

win.on 'close',->
    @hide()
    core.log "退出 #{pkg.name} #{pkg.version}",=>
        @close true

win.on 'minimize',->
    window.tray = new gui.Tray({ title: "#{pkg.name} #{pkg.version}", icon: 'logo16.png'})
    window.menu = new gui.Menu()
    menu.append(new gui.MenuItem(
        type:'normal'
        label:'退出'
        click:->win.close()
    ))
    tray.menu = menu
    tray.on 'click', ->
        core.log "启动 #{pkg.name} #{pkg.version}",=>
            win.show()
            win.restore()
            win.setAlwaysOnTop true
            win.setAlwaysOnTop false
            @remove()
            tray = null
    @hide()

window.clipboard = gui.Clipboard.get()
window.addEventListener('load', ->win.show())

safeFilter = (str) ->
    removeSpan = (str)->
        str.replace('<span>', ' ').replace('</span>', '')
    safeFilename = (str)->
        str.replace(/(\/|\\|\:|\*|\?|\"|\<|\>|\||\s+)/g, ' ')
    safeFilename removeSpan(str)

isArray = (input)->
    typeof(input) is 'object' and input instanceof Array

isBool = (obj)->
    obj is true or obj is false

str2bool = core.str2bool

batchReplace = (data, table)->
    for name,value of table
        data = data.replace name, value if value
    data

setSavePath = (info)->
    localSavePath = localStorage['xt.localSavePath']
    filenameTrackId = str2bool localStorage['xt.filenameTrackId']
    artistFolder = str2bool localStorage['xt.artistFolder']

    folderFormat = localStorage['xt.foldernameFormat']
    fileFormat = localStorage['xt.filenameFormat']

    switch info.type
        when 'album'
            foldername = batchReplace folderFormat,
                '%NAME%': info.name
                '%ARTIST%': info.artist
                '%COMPANY%': info.company
                '%TIME%': info.time
                '%LANGUAGE%': info.language
            foldername = path.join safeFilter(info.artist), safeFilter(foldername) if artistFolder
            foldername = path.resolve localSavePath, foldername
            getTrackId = (data)->
                trackId = data.trackId
                if trackId < 10 then "0#{trackId}" else "#{trackId}"
            for data, i in info.data
                filename = batchReplace fileFormat,
                    '%NAME%': data.song.name
                    '%ARTIST%': data.artist.name
                    '%ALBUM%': data.album.name
                filename = "#{getTrackId(data)} - #{filename}" if filenameTrackId
                savePath = safeFilter "#{filename}.mp3" # 文件名过滤
                info.data[i].savePath = path.resolve foldername, savePath
            info.savePath = foldername
        when 'showcollect'
            foldername = path.resolve localSavePath, safeFilter(info.name)
            for data, i in info.data
                filename = batchReplace fileFormat,
                    '%NAME%': data.song.name
                    '%ARTIST%': data.artist.name
                    '%ALBUM%': data.album.name
                savePath = safeFilter "#{filename}.mp3" # 文件名过滤
                info.data[i].savePath = path.resolve foldername, savePath
            info.savePath = foldername
        else
            filename = batchReplace fileFormat,
                '%NAME%': info.song.name
                '%ARTIST%': info.artist.name
                '%ALBUM%': info.album.name
            savePath = safeFilter "#{filename}.mp3" # 文件名过滤
            info.savePath = path.resolve localSavePath, savePath
    info

XiamiThief=angular.module('XiamiThief',[])

XiamiThief.config(($routeProvider)->
    $routeProvider
    .when('/download',{
        templateUrl:'views/download.html'
        controller:'DownloadCtrl'
    })
    .when('/option',{
        templateUrl:'views/option.html'
        controller:'OptionCtrl'
    })
    .when('/help',{
        templateUrl:'views/help.html'
        controller:'HelpCtrl'
    })
    .otherwise({
        redirectTo:'/download'
    })
)

XiamiThief.directive('xtProcess',->
    (scope, element, attr)->
        scope.$watch(
            ->scope.task.process,
            (newValue, oldValue)->
                if newValue
                    if newValue >= 0
                        element.css('backgroundSize': "#{newValue}% 40px")
                    else
                        element.css('backgroundSize': '100% 40px')
                        element.css('backgroundImage': '-webkit-linear-gradient(top, #e74c3c, #e74c3c)')

        )
)

XiamiThief.factory('DataService',->
    data = {}
    'set':(key,value)->
        data[key] = value
    'get':(key,def)->
        data[key] or def
    'rm':(key)->
        delete data[key]
)
.factory('TaskManager',['DataService',(DataService)->
    class TaskManager
        constructor: (@limit = 3)->
            @taskList = []
            @downloading = 0
            @undone = 0
        setLimit: (value)->
            @limit = value
            @check()
        check: ->
            # 正在下载任务数少于同时下载任务上限, 且未完成任务数多于正在下载数
            if @downloading < @limit and @undone > @downloading
                for task, i in @taskList
                    if task and not task.download
                        task.download = true
                        @downloading++
                        (=>
                            index = i
                            ###
                            sameAlbumNumber = (obj for obj in @taskList when not obj.download and obj.album.id and obj.album.id is task.album.id and obj isnt task).length
                            if sameAlbumNumber is 0
                                task.last = true
                            ###
                            cb = (result)=>
                                    ele = document.querySelector("#list li[data-index='#{index}']")
                                    if isBool result
                                        if scope = angular.element(document.querySelector('#list'))?.scope()
                                            scope.$apply ->
                                                task.process = if result then 100 else -1
                                        else
                                            task.process = if result then 100 else -1
                                        core.log "下载#{if result then '成功' else '失败'} #{task.savePath}"
                                        @undone--
                                        @downloading--
                                        @check()
                                    else
                                        if scope = angular.element(document.querySelector('#list'))?.scope()
                                            scope.$apply ->
                                                task.process = result * 100
                                        else
                                            task.process = result *100
                            core.downloadMusic task,
                                cb,
                                str2bool(localStorage['xt.id3v23']),
                                str2bool(localStorage['xt.lyric']),
                                DataService.get('client',null)
                            core.log "开始下载 #{task.savePath}"
                        )()
                        @check()
                        break
        push: (info) ->
            if info.type
                index = []
                for song, id in info.data
                    i = @taskList.push(song)-1
                    @taskList[i].index = i
                    @undone++
                    index.push i
            else
                i = @taskList.push(info) - 1
                @taskList[i].index = i
                @undone++
                index = i
            # 如果没有下载任务则开始下载
            @check() if @downloading is 0
            index
        changeLimit: (@limit) ->

    downloadManager = new TaskManager(parseInt localStorage['xt.taskLimit'])
    return downloadManager
])

XiamiThief.filter('picSize', ->
    (input, size)->
        input?.replace('.jpg',"_#{size}.jpg")
)
.filter('preview', ->
    (input, type)->
        if type is 'song'
            input = input?.replace('%NAME%','歌名')
            input = input.replace('%ARTIST%','歌手')
            input = input.replace('%ALBUM%','专辑')
            input = input.replace('%TRACKID%','音轨号(仅专辑有效, 其他下载不显示)')
            "#{input}.mp3"
        else if type is 'album'
            input = input?.replace('%NAME%','专辑名')
            input = input.replace('%ARTIST%','歌手')
            input = input.replace('%COMPANY%','唱片公司')
            input = input.replace('%TIME%','发行日期')
            input = input.replace('%LANGUAGE%','语言')
            input
)

XiamiThief.controller('ControlCtrl',($scope, $location)->
    $scope.isMaximize=false

    $scope.close=->
        win.close()

    $scope.zoom=->
        if $scope.isMaximize
            win.unmaximize()
            $scope.isMaximize=false
        else
            win.maximize()
            $scope.isMaximize=true

    $scope.minimize=->
        win.minimize()

    $scope.changeView = (view)->
        $location.path view

    $scope.title = "#{pkg.name} #{pkg.version}"
)

XiamiThief.controller('DownloadCtrl',($scope, $timeout, DataService, TaskManager)->
    $scope.url = DataService.get('url') ? ''
    $scope.selected = DataService.get('selected') ? false
    $scope.taskList = TaskManager.taskList
    $scope.createTask = ->
        cb = (info)->
            addTask = (info)->
                $scope.$apply ->
                    index = TaskManager.push info
            if info
                info = setSavePath info

                if info.type
                    # 创建文件夹
                    mkdirp.sync info.savePath
                    if info.type is 'album'
                        # 下载专辑
                        core.downloadAlbumCover info,(cb)->
                            if cb
                                addTask(info)
                        , str2bool(localStorage['xt.picture'])
                        , str2bool(localStorage['xt.id3v23'])
                    else
                        addTask(info)
                else
                    addTask(info)
            else if str2bool localStorage['xt.newTaskRetry']
                $timeout ->
                    core.getInfo $scope.url, cb
                ,5*1000
        core.getInfo($scope.url, cb)
        $scope.url = ''
        $scope.urlChange()
    $scope.urlChange = ->
        DataService.set('url',$scope.url)
    $scope.select = (task)->
        $scope.selected = task
        DataService.set('selected', task)
    $scope.getUrlFromClip = ->
        text = clipboard.get('text')
        if DataService.get('clip') isnt text
            $scope.url = text
            DataService.set('clip',text)
            $scope.urlChange()
)

XiamiThief.controller('OptionCtrl',($scope)->
    $scope.advancedShow = false
    $scope.accountShow = true
    $scope.downloadShow = false
    $scope.account = ->
        $scope.advancedShow = false
        $scope.downloadShow = false
        $scope.accountShow = true
    $scope.download = ->
        $scope.advancedShow = false
        $scope.accountShow = false
        $scope.downloadShow = true
    $scope.advanced = ->
        $scope.accountShow = false
        $scope.downloadShow = false
        $scope.advancedShow = true
)

XiamiThief.controller('OptionAccountCtrl', ($scope, DataService)->
    $scope.errorInfo = false
    $scope.logged = DataService.get('logged') ? false
    $scope.info = DataService.get('info') ? {}
    formData = {}
    getForm = ->
        $scope.validateUrl = ''
        core.getLoginForm (data)->
            formData = data
            if data.validate?
                $scope.$apply ->
                    $scope.validateUrl = 'validate.png'
    getForm() unless $scope.logged
    $scope.rememberAccount = str2bool(localStorage['xt.rememberAccount'])
    $scope.email = if $scope.rememberAccount then localStorage['xt.email']
    $scope.password = if $scope.rememberAccount then localStorage['xt.password']
    $scope.login = ->
        formData['email'] = $scope.email
        formData['password'] = $scope.password
        if $scope.validateUrl
            formData['validate'] = $scope.validate
        core.getCookie(formData, (result)->
            if result
                if $scope.rememberAccount
                    localStorage['xt.email'] = $scope.email
                    localStorage['xt.password'] = $scope.password
                else
                    localStorage['xt.email'] = ''
                    localStorage['xt.password'] = ''
                core.getAccountInfo((info)->
                    $scope.$apply ->
                        $scope.info = info
                        $scope.logged = true
                        DataService.set('info', $scope.info)
                        DataService.set('logged', $scope.logged)
                )
                $scope.errorInfo = false
            else
                getForm()
                $scope.errorInfo = '登录失败, 请重试'
        )
        localStorage['xt.rememberAccount'] = $scope.rememberAccount
    $scope.logout = ->
        if $scope.rememberAccount
            $scope.email = localStorage['xt.email']
            $scope.password = localStorage['xt.password']
        else
            $scope.email = ''
            $scope.password = ''
        core.accountLogout()
        getForm()
        $scope.logged = false
        $scope.info = {}
        DataService.set('info', $scope.info)
        DataService.set('logged',$scope.logged)
)

XiamiThief.controller('OptionDownloadCtrl', ($scope, TaskManager)->
    $scope.localSavePath = localStorage['xt.localSavePath']
    $scope.lyric = str2bool localStorage['xt.lyric']
    $scope.picture = str2bool localStorage['xt.picture']
    $scope.filenameFormat = localStorage['xt.filenameFormat']
    $scope.foldernameFormat = localStorage['xt.foldernameFormat']
    $scope.id3v23 = str2bool localStorage['xt.id3v23']
    $scope.filenameTrackId = str2bool localStorage['xt.filenameTrackId']
    $scope.artistFolder = str2bool localStorage['xt.artistFolder']
    $scope.taskLimit = parseInt(localStorage['xt.taskLimit'])
    $scope.newTaskRetry = str2bool localStorage['xt.newTaskRetry']

    $scope.chooseLocalSavePath=(localSavePath)->
        fileDialog=document.createElement('input')
        fileDialog.setAttribute('type','file')
        fileDialog.setAttribute('nwdirectory','')
        fileDialog.setAttribute('nwworkingdir',localSavePath)
        fileDialog.addEventListener('change',(e)->
            $scope.$apply(->
                $scope.localSavePath=fileDialog.value
            )
        )
        fileDialog.click()

    $scope.save=->
        localStorage['xt.localSavePath'] = $scope.localSavePath
        localStorage['xt.lyric'] = $scope.lyric
        localStorage['xt.picture'] = $scope.picture
        localStorage['xt.filenameFormat'] = $scope.filenameFormat
        localStorage['xt.foldernameFormat'] = $scope.foldernameFormat
        localStorage['xt.id3v23'] = $scope.id3v23
        localStorage['xt.filenameTrackId'] = $scope.filenameTrackId
        localStorage['xt.artistFolder'] = $scope.artistFolder
        if $scope.taskLimit isnt localStorage['xt.taskLimit']
            localStorage['xt.taskLimit'] = $scope.taskLimit
            TaskManager.setLimit parseInt($scope.taskLimit)
        localStorage['xt.newTaskRetry'] = $scope.newTaskRetry
)

XiamiThief.controller('OptionAdvancedCtrl', ($scope, DataService)->
    $scope.nonVipHq = DataService.get 'nonVipHq', false
    $scope.showDevTools = ->
        win.showDevTools()
    $scope.showLog = ->
        child_process.exec 'XiamiThief.log'
    nonVipHqChange = ->
        DataService.set 'nonVipHq',$scope.nonVipHq
        if $scope.nonVipHq
            client = new PHPRPC_Client('http://blackglory.uhosti.com/server.php')
            DataService.set 'client',client
        else
            DataService.rm 'client'
)

XiamiThief.controller('HelpCtrl',($scope)->
)

localStorage['xt.rememberAccount'] = str2bool localStorage['xt.rememberAccount'], false
localStorage['xt.email'] = if localStorage['xt.rememberAccount'] then localStorage['xt.email'] ? '' else ''
localStorage['xt.password'] = if localStorage['xt.rememberAccount'] then localStorage['xt.password'] ? '' else ''
localStorage['xt.localSavePath'] = localStorage['xt.localSavePath'] ? core.execPath
localStorage['xt.lyric'] = str2bool localStorage['xt.lyric'], false
localStorage['xt.picture'] = str2bool localStorage['xt.picture'], true
localStorage['xt.filenameFormat'] = localStorage['xt.filenameFormat'] ? '%NAME%'
localStorage['xt.foldernameFormat'] = localStorage['xt.foldernameFormat'] ? '%NAME% - %TIME%'
localStorage['xt.id3v23'] = str2bool localStorage['xt.id3v23'], false
localStorage['xt.filenameTrackId'] = str2bool localStorage['xt.filenameTrackId'], false
localStorage['xt.artistFolder'] = str2bool localStorage['xt.artistFolder'], false
localStorage['xt.taskLimit'] = localStorage['xt.taskLimit'] ? 3
localStorage['xt.newTaskRetry'] = str2bool localStorage['xt.newTaskRetry'], true