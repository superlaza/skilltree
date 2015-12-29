fs = require 'fs'

{spawn} = require 'child_process'

isWin = process.platform is 'win32' # even on win64
coffeeEXE = 'coffee'+(if isWin then '.cmd' else '')

build = (callback) ->
	
	coffee = spawn coffeeEXE, ['-c', '-o', './app/build', './app/src']
	coffee.stderr.on 'data', (data) ->
		process.stderr.write data.toString()
	coffee.stdout.on 'data', (data) ->
		console.log data.toString()
	coffee.on 'exit', (code) ->
		callback?() if code is 0

watch = ->
	coffee = spawn coffeeEXE, ['-w', '-c', '-o', './app/build', './app/src']
	coffee.stderr.on 'data', (data) ->
		process.stderr.write data.toString()
	coffee.stdout.on 'data', (data) ->
		console.log data.toString()

task 'build', 'Build lib/ from src/', ->
  build()
  watch()