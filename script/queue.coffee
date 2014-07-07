'use strict'

_ = require 'underscore'

###
queue = (concurrency = 1)->
	running = false
	q=
		pre: []
		run: []
		end: []
		err: []
		push: (args...)->
			q.pre.push.apply q.pre, args
			console.log 'push'
			q.preToRun()
		preToRun: ->
			console.count 'preToRun'
			free = concurrency - q.run.length
			console.log concurrency, q.run.length
			if free >= 1
				while free--
					if q.pre.length > 0
						task = q.pre.shift()
						task.run (err, data)->
							i = _.indexOf(q.run, task)
							if not err
								q.end.push task
							else
								q.err.push task
							q.run.splice i, 1
							q.preToRun()
						q.run.push task
						running = true
					else
						break
		concurrency: (value)->
			concurrency = value if value?
			concurrency

module.exports = queue
###