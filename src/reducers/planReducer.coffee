{ADD_CLASS, DELETE_CLASS, ADD_SEMESTER} = require '../constants/ActionTypes.coffee'

im 				= require 'immutable'
initialState 	= require '../../data/initialState.coffee'
console.log 'init', initialState
initialState 	= im.fromJS(initialState)

console.log 'init', initialState

# UTILITY
# impure
addPositionData = (newState, data) ->
	{nodePositions, groupPositions} = data
	# infuse location data			
	for index, node of newState.nodes
		positions = nodePositions[index]
		# only update position if node exists
		if node? and positions?
			node.x = positions.x
			node.y = positions.y

	for index, group of newState.groups
		positions = groupPositions[index]
		# only update position if group position data exists
		if positions?
			group.bounds = 
				x: positions.bounds.x
				y: positions.bounds.y
				X: positions.bounds.X
				Y: positions.bounds.Y

# add node, delete all in group 1, undo add node
reducer = (state = initialState, action) ->
	switch action.type
		when ADD_CLASS
			console.log 'laksdf'
			# console.log 'graph', action.graph
			newState = state.toJS()
			{nodePositions, groupPositions} = action.positionData
			{className, semester, nid} = action.nodeData

			addPositionData newState, {
				nodePositions: nodePositions
				groupPositions: groupPositions
			}

			newClassNode =
				nid: nid
				name: className
				width:60
				height:40
				x: groupPositions[semester].bounds.X
				y: groupPositions[semester].bounds.Y
			nodeIndex = newState.nodes.length
			newState.nodes.push newClassNode
			newState.groups[semester].leaves.push nodeIndex
			for constraint in newState.constraints
				if constraint.type is 'alignment' and constraint.group is semester
					constraint.offsets.push
						node: nodeIndex
						offset: 50

			# add option nodes
			for optionData in action.options
				{className, nid} = optionData
				group = newState.groups[semester+1]
				if group? # if there's an existing next semester
					newOptionNode =
						nid: nid
						name: className
						width:60
						height:40
						x: groupPositions[semester+1].bounds.X #here
						y: groupPositions[semester+1].bounds.Y #here
					optionIndex = newState.nodes.length
					newState.nodes.push newOptionNode
					group.leaves.push optionIndex
					newState.links.push
						source: nodeIndex
						target: optionIndex

					# add option constraints
					for constraint in newState.constraints
						if constraint.type is 'alignment' and constraint.group is semester+1
							constraint.offsets.push
								node: optionIndex
								offset: 50
				else
					console.log 'that semester does not exist'

			im.fromJS(newState)

		when ADD_SEMESTER
			newState = state.toJS()

			addClassNode =
				nid: -1
				name:'Add Class'
				type: 'menu'
				width:menuWidth
				height:menuHeight


		when DELETE_CLASS
			# newState = action.graph
			newState = state.toJS() # todo: shouldn't need to convert to js, fix later
			{nodePositions, groupPositions} = action.positionData

			addPositionData newState, {
				nodePositions: nodePositions
				groupPositions: groupPositions
			}

			# get index by node id
			for index, node of newState.nodes
				delNodeIndex = parseInt index
				if node.nid is action.nodeID
					break

			# the deletion
			newState.nodes.splice(delNodeIndex, 1)

			# remap index refs
			# these lines are too long, this is not Disney.
			remap = (i) -> if i>delNodeIndex then i-1 else i
			for group in newState.groups
				group.leaves = (remap leaf for leaf in group.leaves when leaf isnt delNodeIndex)
			for constraint in newState.constraints
				if constraint.type is 'alignment'					# yo dawg...
					constraint.offsets = ({node:(remap offset.node), offset:offset.offset} for offset in constraint.offsets when offset.node isnt delNodeIndex)
			
			# delete all links attached to node
			# maybe later we might want to delte the nodes it points to as well
			newState.links = ({source:(remap link.source), target:(remap link.target)} for link in newState.links when (link.source isnt delNodeIndex and link.target isnt delNodeIndex))

			im.fromJS(newState)
		else state

module.exports = reducer