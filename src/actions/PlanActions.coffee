{ADD_CLASS} = require '../constants/ActionTypes.coffee'

actionAddClass = (classCode, semester, graph) ->
	type: 		ADD_CLASS
	classCode: 	classCode
	semester:	semester
	graph:		graph

module.exports =
	actionAddClass: actionAddClass