'use strict'

common = require './script/common'
_ = require 'underscore'

App.filter 'picSize', ->
    (input, size)->
        input?.replace('.jpg',"_#{size}.jpg")

App.filter 'preview', ->
    (input, type)->
        (
            song: ->
                input = common.replaceBat input,
                    ['%NAME%', '歌名'],
                    ['%ARTIST%', '歌手'],
                    ['%ALBUM%', '专辑'],
                    ['%TRACK%', '音轨号'],
                    ['%DISC%', '碟片号']
            album: ->
                input = common.replaceBat input,
                    ['%NAME%', '专辑名'],
                    ['%ARTIST%', '歌手'],
                    ['%COMPANY%', '唱片公司'],
                    ['%TIME%', '发行日期'],
                    ['%LANGUAGE%', '语言']
        )[type]() if input?

App.filter 'type2name', ->
    (type)->
        (
            song: '单曲'
            album: '专辑'
            collect: '精选集'
            artist: '艺人热门歌曲'
        )[type] if type?

###
App.filter 'group', ->
    _.memoize (arr)->
        _.throttle (arr)->
            _.groupBy arr, (obj)->
                [obj.source.type, obj.source.id]
        , 100
###