# REQUIRE
# NOTE: put non-production requires inside tasks
gulp          = require 'gulp'
coffee        = require 'gulp-coffee'
sass          = require 'gulp-sass'
concat        = require 'gulp-concat'
uglify        = require 'gulp-uglify' # minify and mangle js
minifyCss     = require 'gulp-minify-css'
debug 		  = require 'gulp-debug' # for biopics of piped streams
notify		  = require 'gulp-notify'
coffeex 	  = require 'gulp-coffee-react-transform'
# coffeex 	  = require 'gulp-coffee-react'
react 		  = require 'gulp-react'
babel		  = require 'gulp-babel'

# ngAnnotate    = require 'gulp-ng-annotate' # protect angular dependency injection from minify
# hashsum       = require 'gulp-hashsum-json'
# sourcemaps    = require('gulp-sourcemaps'); #todo: consider enabling source maps for easier production-side debugging
livereload    = require 'gulp-livereload' # reload the browser when files change

# todo: evaluate utility of error notifications
# notify = (message) ->
# 	notifier.notify
# 		title: "dubif-gulp"
# 		message: message
# 		wait: true
# 		sound: true

errHandle = (err) ->
	console.log err
	 # "notify#{err.name}\n#{err.message}"

	this.emit 'end'

root = 'skilltree/'
# PATHS
path =
	js:          "./#{root}src/coffee/"
	jsOut:       "./#{root}assets/js/"
	css:         "./#{root}src/sass/"
	cssOut:      "./#{root}assets/css/"
	es6:		 "./#{root}src/es6/"
	es6Out:		 "./#{root}assets/js/"

ECMAScripts   = ["./#{root}src/es6/*.js"]
coffeeScripts = ["./#{root}src/coffee/*.coffee"]
scssFiles 	  = ["./#{root}src/sass/*.scss"]
html 		  = ["./#{root}*.html"]

gulp.task 'es6', ->
	# Minify and copy all JavaScript (except vendor scripts)
	# with sourcemaps all the way down
	gulp.src ECMAScripts
		.pipe babel().on 'error', notify.onError
			title: "Babel Transpile Failed"
			message: "Error: <%= error.message %><%= console.log(error)%>"
		.pipe gulp.dest(path.es6Out)
		.pipe livereload()

gulp.task 'js', ->
	# Minify and copy all JavaScript (except vendor scripts)
	# with sourcemaps all the way down
	gulp.src coffeeScripts
		# .pipe sourcemaps.init()
		# .pipe coffee().on 'error', errHandle
		# .pipe coffeex().on 'error', notify.onError
		# 	title: "Failed to compile JSX"
		# 	message: "Error: <%= error.message %><%= console.log(error)%>"
		# .pipe coffeex().on 'error', notify.onError
		# 	title: "coffeeScript JSX compliation failed"
		# 	message: "Error: <%= error.message %><%= console.log(error)%>"
		.pipe coffee({bare: true}).on 'error', notify.onError
			title: "coffeeScript compliation failed"
			message: "Error: <%= error.message %><%= console.log(error)%>"
		# .pipe uglify()
		# .pipe concat('all.min.js') # big kahuna js file
		# .pipe sourcemaps.write()
		.pipe react().on 'error', notify.onError
			title: "JSX compilation failed"
			message: "Error: <%= error.message %><%= console.log(error)%>"
		.pipe gulp.dest(path.jsOut)
		.pipe livereload()

gulp.task 'css', ->
	gulp.src scssFiles
		# .pipe sass().on 'error', errHandle
		.pipe sass().on 'error', notify.onError
			title: "Sass compliation failed"
			message: "Error: <%= error.message %><%= console.log(error)%>"
		.pipe minifyCss()
		.pipe gulp.dest(path.cssOut)
		.pipe livereload()

# reload browser on changes to views
gulp.task 'html', ->
	gulp.src html
		.pipe livereload()

# Rerun the task when a file changes
gulp.task 'watch', ->
	livereload.listen()
	gulp.watch ECMAScripts, ['es6']
	gulp.watch coffeeScripts, ['js']
	gulp.watch scssFiles, ['css']
	gulp.watch html, ['html']

# The default task (called when you run `gulp` from cli)
gulp.task 'default', ['es6', 'js', 'css', 'html', 'watch']