{ADD_CLASS, DELETE_CLASS} = require '../constants/ActionTypes.coffee'

actionAddClass = (nodeData, options, positionData) ->
	type: 			ADD_CLASS
	nodeData:		nodeData
	options:		options
	positionData:	positionData

actionDeleteClass = (nodeID, positionData) ->
	type: 			DELETE_CLASS 
	nodeID:			nodeID
	positionData:	positionData

module.exports =
	actionAddClass		: actionAddClass
	actionDeleteClass	: actionDeleteClass