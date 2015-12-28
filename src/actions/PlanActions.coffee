{ADD_CLASS, DELETE_CLASS, ADD_SEMESTER} = require '../constants/ActionTypes.coffee'

actionAddClass = (nodeData, options, positionData) ->
	type: 			ADD_CLASS
	nodeData:		nodeData
	options:		options
	positionData:	positionData

actionAddSemester = ->
	type: 			ADD_SEMESTER
	positionData:	positionData

actionDeleteClass = (nodeID, positionData) ->
	type: 			DELETE_CLASS 
	nodeID:			nodeID
	positionData:	positionData

module.exports =
	actionAddClass		: actionAddClass
	actionDeleteClass	: actionDeleteClass