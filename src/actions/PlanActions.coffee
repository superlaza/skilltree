{ADD_CLASS, DELETE_CLASS} = require '../constants/ActionTypes.coffee'

actionAddClass = (nodeData, options, graph) ->
	type: 		ADD_CLASS
	nodeData:	nodeData
	options:	options
	graph:		graph

actionDeleteClass = (nodeID, graph) ->
	type: 		DELETE_CLASS 
	nodeID:		nodeID
	graph:		graph

module.exports =
	actionAddClass		: actionAddClass
	actionDeleteClass	: actionDeleteClass