'use strict'

window.version = (Number i for i in process.versions['node-webkit'].split '.')

###
window.require = do ->
    originRequire = require
    (path)->
        # console.log version[1] is 8, (version[1] is 10 and version[2] >= 1), path[0] is '.'
        if (version[1] is 8 or
        (version[1] is 10 and version[2] >= 1)) and
        path[0] is '.'
            path = '.' + path
        originRequire path
###

gui = require 'nw.gui'
pkg = require '../package'
os = require 'os'
path = require 'path'
timers = require 'timers'
async = require 'async'
url = require 'url'
queue = require '../script/queue'
common = require '../script/common'

process.on('uncaughtException',(err)->
    console.error err
    console.error err.stack
)

do ->
    newWindow = null
    
    request = (require 'request').defaults
        # jar: config.jar
        headers: common.config.headers
        followAllRedirects: false
        strictSSL: false
        proxy: false
    
    ###
    resProcess = (error, response, body, cb)->
        console.log response
        hasCheckcode = common.inStr(body, 'regcheckcode.taobao.com') or common.inStr(body, '<div class="msg e needcode">')
        if hasCheckcode
            alert '请在弹出的页面中输入验证码, 提交完毕后关闭页面'
            new_win = gui.Window.open response?.request?.href?,
                'frame': true
                'toolbar': false
            new_win.on 'closed', ->
                
        else
            # console.log response
            if common.inStr response?.headers?['content-type'], 'json'
                try
                    body = JSON.parse body
                catch e
                    console.error e, body
            else if common.inStr(response?.request?.headers?['Content-Type'], 'json')
                try
                    body = JSON.parse body
                catch e
                    console.error e, body
            cb? error, response, body
    ###
    
    common.getReq = (url, headers, cb)->
        args = arguments
        #console.log url, '"' + common.getProxyString() + '"', common.config.cookie
        switch arguments.length
            when 3
                [url, headers, cb] = arguments
            when 2
                [url, cb] = arguments
            when 1
                [url] = arguments
            else
                throw new Error 'arguments error.'
        console.log 'GET', common.config.cookie, angular.copy common.config.jar
        headers = common.mixin
            Cookie: common.config.cookie
            Referer: 'http://www.xiami.com/'
        , headers
        
        req = request 
            'url': url
            'method': 'GET'
            'headers': headers
            'jar': common.config.jar
            'proxy': common.getProxyString()

    common.get = (url, headers, cb)->
        args = arguments
        #console.log url, '"' + common.getProxyString() + '"', common.config.cookie
        switch arguments.length
            when 3
                [url, headers, cb] = arguments
            when 2
                [url, cb] = arguments
            when 1
                [url] = arguments
            else
                throw new Error 'arguments error.'
        console.log 'GET', common.config.cookie, angular.copy common.config.jar
        headers = common.mixin
            Cookie: common.config.cookie
            Referer: 'http://www.xiami.com/'
        , headers
        
        req = request 
            'url': url
            'method': 'GET'
            'headers': headers
            'jar': common.config.jar
            'proxy': common.getProxyString()
        , (error, response, body)->
            # resProcess error, response, body, cb
            hasCheckcode = common.inStr(body, 'regcheckcode.taobao.com') or common.inStr(body, '<div class="msg e needcode">')
            #console.log url, 'hasCheckcode:' + hasCheckcode
            if hasCheckcode
                if newWindow?
                    common.setInterval ->
                        unless newWindow?
                            common.get.apply null, args
                        not newWindow?
                    , 1000
                else
                    alert '请在弹出的页面中输入验证码, 提交完毕后关闭页面'
                    newWindow = gui.Window.open response?.request?.href?,
                        'frame': true
                        'toolbar': false
                    newWindow.on 'closed', ->
                        common.get.apply null, args
                        newWindow = null
            else
                if common.inStr response?.headers?['content-type'], 'json'
                    try
                        body = JSON.parse body
                    catch e
                        console.error e, body
                else if common.inStr response?.request?.headers?['Content-Type'], 'json'
                    try
                        body = JSON.parse body
                    catch e
                        console.error e, body
                cb error, response, body if cb
        req

    common.postReq = (url, data, headers, cb)->
        args = arguments
        #console.log url, '"' + common.getProxyString() + '"', common.config.cookie
        switch arguments.length
            when 4
                [url, data, headers, cb] = arguments
            when 3
                [url, data, cb] = arguments
            when 2
                [url, cb] = arguments
            when 1
                [url] = arguments
            else
                throw new Error 'arguments error.'

        console.log 'POST', common.config.cookie, angular.copy common.config.jar
        headers = common.mixin
                Cookie: common.config.cookie
                Referer: 'http://www.xiami.com/'
            , headers

        req = request
            'url': url
            'method': 'POST'
            'headers': headers
            'jar': common.config.jar
            'proxy': common.getProxyString()
            'form': data
        
    common.post = (url, data, headers, cb)->
        args = arguments
        #console.log url, '"' + common.getProxyString() + '"', common.config.cookie
        switch arguments.length
            when 4
                [url, data, headers, cb] = arguments
            when 3
                [url, data, cb] = arguments
            when 2
                [url, cb] = arguments
            when 1
                [url] = arguments
            else
                throw new Error 'arguments error.'

        console.log 'POST', common.config.cookie, angular.copy common.config.jar
        headers = common.mixin
                Cookie: common.config.cookie
                Referer: 'http://www.xiami.com/'
            , headers

        req = request
            'url': url
            'method': 'POST'
            'headers': headers
            'jar': common.config.jar
            'proxy': common.getProxyString()
            'form': data
        , (error, response, body)->
            # resProcess error, response, body, cb
            hasCheckcode = common.inStr(body, 'regcheckcode.taobao.com') or common.inStr(body, '<div class="msg e needcode">')
            if hasCheckcode
                if newWindow?
                    common.setInterval ->
                        unless newWindow?
                            common.post.apply null, args
                        not newWindow?
                    , 1000
                else
                    alert '请在弹出的页面中输入验证码, 提交完毕后关闭页面'
                    newWindow = gui.Window.open response?.request?.href?,
                        'frame': true
                        'toolbar': false
                    newWindow.on 'closed', ->
                        common.post.apply null, args
                        newWindow = null
            else
                # console.log response
                if common.inStr response?.headers?['content-type'], 'json'
                    try
                        body = JSON.parse body
                    catch e
                        console.error e, body
                else if common.inStr(response?.request?.headers?['Content-Type'], 'json')
                    try
                        body = JSON.parse body
                    catch e
                        console.error e, body
                cb? error, response, body
        req

if gui.App.addOriginAccessWhitelistEntry?
    originWhitelist = [
        'https://xiami.com'
        'https://login.xiami.com'
        'https://taobao.com'
        'https://login.taobao.com'
        'https://h.alipayobjects.com'
        'https://passport.alipay.com'
        'https://ynuf.alipay.com'
        'https://s.tbcdn.cn'
        'https://acjs.aliyun.com'
    ]
    for i in originWhitelist
        gui.App.addOriginAccessWhitelistEntry i, 'app', 'xiamithief', true

    #gui.App.addOriginAccessWhitelistEntry 'app://xiamithief', 'https', 'xiamithief', true

dir = 
    template:'../template'

window.win = gui.Window.get()

window.count = 0

###
window.addEventListener 'load', ->
    win.show()
###

#window.openBrowser = gui.Shell.openItem

common.loadLoginPage = ->
    unless common.user.logged
        iframe = document.querySelector 'iframe.loginPage'
        cookies = require('nw.gui').Window.get().cookies
        removeCookie = (args...)->
            for i in args
                cookies.remove url: 'http://www.xiami.com', name: i
                cookies.remove url: 'http://xiami.com', name: i
                cookies.remove url: 'https://www.xiami.com', name: i
                cookies.remove url: 'https://xiami.com', name: i
        removeCookie '_xiamitoken', '_unsign_token', 'member_auth', 'user', 'isg', 't_sign_auth', 'ahtena_is_show'
        iframe?.src = ''
        iframe?.src = 'https://login.xiami.com/member/login'
        
window.dialog = (element)->
    window.tray?._events.click()
    element = document.querySelectorAll element if _.isString element
    unless (element.length or element.length is 0) #Not NodeList or Array
        element = [element]
    if element.length > 0
        show:->
            $('body>header').addClass 'no-drag'
            $('.dialog').css
                'z-index': 1
                display: 'block'
            for i in element
                i.style.display = 'flex'
        hide:->
            $('body>header').removeClass 'no-drag'
            $('.dialog').css
                'z-index': -1
                display: 'none'
            for i in element
                i.style.display = 'none'
    else
        show:->console.error 'show',element
        hide:->console.error 'hide',element

window.menuStart = do ->
    menu = new gui.Menu

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

    if os.platform() is 'drawin' and version[1] >= 10
        menu.createMacBuiltin 'xiami-thief'

    menu

win.on 'close',->
    @hide()
    @close true

bgImg = new Image

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
    tray.menu = menuStart
    tray.on 'click', ->
        win.show()
        #win.restore()
        win.setAlwaysOnTop true
        win.setAlwaysOnTop false
        tray.remove()
        window.tray = null
    win.hide()

###
win.on 'new-win-policy', (frame, url, policy)->
    console.log frame, url, policy
###

window.clipboard = gui.Clipboard.get()

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
            _.defer quickRepeatList.tasks, q.list
        q = 
            list: []
            remove: (index)->
                q.list[index].state = State.Fail
                q.list[index].hide = true
                refresh()
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
                # console.log 'list:', q.list
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
                                                    $rootScope.$apply ->
                                                        i.process = 100
                                                        i.state = if err then State.Fail else State.Success
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

App.controller 'TaskCtrl', ($scope, TaskQueue, State, quickRepeatList)->
    createMenuTask = (info, taskIndex)->
        menu = new gui.Menu
        
        menuItem = (options)->
            new gui.MenuItem options

        menu.append menuItem
            type: 'normal'
            label: '在虾米音乐网打开'
            click: ->
                switch info.type
                    when 'song'
                        link = "http://www.xiami.com/song/#{info.list[0].id}"
                    when 'album'
                        link = "http://www.xiami.com/album/top/id/#{info.id}/page/#{info.start}"
                    when 'collect'
                        link = "http://www.xiami.com/collect/#{info.id}"
                    when 'artist'
                        link = "http://www.xiami.com/artist/#{info.id}"
                    when 'user'
                        link = "http://www.xiami.com/space/lib-song/u/#{info.id}/page/#{info.start}"
                    else
                        link = "http://www.xiami.com/"
                gui.Shell.openItem link
                
        menu.append menuItem
            type: 'normal'
            label: '移除此项'
            click: ->
                $scope.removeTask(taskIndex)

        if os.platform() is 'drawin' and version[1] >= 10
            menu.createMacBuiltin 'xiami-thief'

        menu

    createMenuTrack = (info)->
        menu = new gui.Menu

        menuItem = (options)->
            new gui.MenuItem options

        menu.append menuItem
            type: 'normal'
            label: '打开文件'
            click: ->
                console.log info, path.resolve(info?.save?.path, info?.save?.name) + '.mp3'
                gui.Shell.openItem '"' + path.resolve(info.save.path, info.save.name) + '.mp3' + '"'

        menu.append menuItem
            type: 'normal'
            label: '打开文件存放目录'
            click: ->
                console.log info, info?.save?.path
                gui.Shell.openItem '"' + info.save.path + '"'

        menu.append menuItem
            type: 'separator'

        menu.append menuItem
            type: 'normal'
            label: '在虾米音乐网打开'
            click: ->
                gui.Shell.openItem "http://www.xiami.com/song/#{info.song.id}"

        menu.append menuItem
            type: 'separator'

        menu.append menuItem
            type: 'normal'
            label: '复制[低音质]下载链接'
            click: ->
                if info.url.lq
                    clipboard.set info.url.lq

        menu.append menuItem
            type: 'normal'
            label: '复制[高音质]下载链接'
            click: ->
                if info.url.hq
                    clipboard.set info.url.hq
                else
                    lq = info.url.lq
                    hq = common.replaceBat lq,
                        ['m1.file.xiami.com', 'm3.file.xiami.com'],
                        ['m5.file.xiami.com', 'm6.file.xiami.com'],
                        ['l.mp3', 'h.mp3']
                    clipboard.set hq

        if os.platform() is 'drawin' and version[1] >= 10
            menu.createMacBuiltin 'xiami-thief'

        menu

    $scope.showCreateDialog = ->
        dialog('.dialog .create').show()
    $scope.showSetupDialog = ->
        dialog('.dialog .setup').show()
        common.loadLoginPage()
        
    $scope.list = TaskQueue.list
    $scope.State = State
    $scope.check = TaskQueue.dirtyCheck
    $scope.removeTask = TaskQueue.remove

    $scope.isHq = (info)->
        if info.url.hq
            url.parse(info.url.hq).hostname.split('.')[0] is 'm6'
        else
            false

    $scope.popupMenuTask = ($event, info, taskIndex)->
        menuTask = createMenuTask info, taskIndex
        menuTask.popup $event.clientX, $event.clientY

    $scope.popupMenuTrack = ($event, info)->
        menuTrack = createMenuTrack info
        menuTrack.popup $event.clientX, $event.clientY

    ###
    $scope.pre = TaskQueue.pre
    $scope.err = TaskQueue.err
    $scope.run = TaskQueue.run
    $scope.end = TaskQueue.end
    ###

App.controller 'InfoCtrl', ($scope,User)->
    $scope.user = User

#win.setMinimumSize 800,600
#win.setResizable true

$ ->
    dialogAllHide = ->
        dialog('.dialog>*').hide()

    $('.dialog').click dialogAllHide

    ###
    document.body.addEventListener 'contextmenu', (ev)->
        ev.preventDefault()
        # menu.popup(ev.x, ev.y)
        false
    ###

    $(document).keyup (e)->
        switch e.keyCode
            when 27 # Esc
                dialogAllHide()

    $(document).keydown (e)->
        if e.keyCode is 93 # menu key
            {left, top} = document.querySelector('.button-menu').getBoundingClientRect()
            menuStart.popup left, top

    $('.dialog>*').click (e)->
        e.stopPropagation()
        
    if os.platform() is 'win32' and os.release().split('.') is '5'
        $('body').addClass('.xp-font')

    # bgImg.src = path.resolve common.execPath, 'bg'