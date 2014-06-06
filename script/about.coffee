'use strict'

gui = require 'nw.gui'
win = gui.Window.get()

#win.setMinimumSize 0,0
#win.resizeTo 400,300
win.setResizable false

$ ->
    win.show()
    win.focus()