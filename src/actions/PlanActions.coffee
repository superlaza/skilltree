{ADD_CLASS, DELETE_CLASS} = require '../constants/ActionTypes.coffee'

actionAddClass = (classCode, semester, options, graph) ->
	type: 		ADD_CLASS
	classCode: 	classCode
	semester:	semester
	options:	options
	graph:		graph

actionDeleteClass = (nodeIndex) ->
	type: 		DELETE_CLASS 
	nodeIndex:	nodeIndex
	graph:		graph

module.exports =
	actionAddClass		: actionAddClass
	actionDeleteClass	: actionDeleteClass