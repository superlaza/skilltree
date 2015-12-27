{ADD_CLASS} = require '../constants/ActionTypes.coffee'

actionAddClass = (classCode, semester, options, graph) ->
	type: 		ADD_CLASS
	classCode: 	classCode
	semester:	semester
	options:	options
	graph:		graph

module.exports =
	actionAddClass: actionAddClass