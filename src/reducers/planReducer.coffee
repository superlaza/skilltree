# CONSTANTS
{ADD_CLASS, DELETE_CLASS, ADD_SEMESTER} = require '../constants/ActionTypes.coffee'
{classSpec, addClassSpec, constraintSpec} = require '../constants/Specs.coffee'

im 				= require 'immutable'
initialState 	= require '../../data/initialState.coffee'
initialState 	= im.fromJS(initialState)

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

	# for index, group of newState.groups
	# 	positions = groupPositions[index]
	# 	# only update position if group position data exists
	# 	if positions?
	# 		group.bounds = 
	# 			x: positions.bounds.x
	# 			y: positions.bounds.y
	# 			X: positions.bounds.X
	# 			Y: positions.bounds.Y
				
# impure
createNode = (attrsList...) ->
	nodeAttrs = {}
	for attrs in attrsList
		for key, attr of attrs
			nodeAttrs[key] = attr	

	newNode = { # all nodes will have a name and id
		name:		nodeAttrs.className
		nid:			nodeAttrs.nid
	}

	newNode.type = nodeAttrs.type if nodeAttrs.type?
	newNode.semester = nodeAttrs.semester if nodeAttrs.semester?
	newNode.width  = nodeAttrs.width
	newNode.height = nodeAttrs.height
	if nodeAttrs.groupBounds?
		newNode.x = nodeAttrs.groupBounds.X
		newNode.y = nodeAttrs.groupBounds.Y

	newNode

addNode = (state, index, node) ->
	state.nodes.push node
	state.groups[node.semester].leaves.push index
	console.log 'node constraints', node
	for constraint in state.constraints
		if constraint.type is 'alignment' and constraint.group is node.semester
			constraint.offsets.push
				node: index
				offset: constraintSpec.alignment.OFFSET.x
	console.log state.constraints

# add node, delete all in group 1, undo add node
reducer = (state = initialState, action) ->
	switch action.type
		when ADD_CLASS
			newState = state.toJS()
			{nodePositions, groupPositions} = action.positionData

			addPositionData newState, {
				nodePositions: nodePositions
				groupPositions: groupPositions
			}


			nodeIndex = newState.nodes.length
			nodeSemester = action.nodeData.semester

			groupBounds = groupPositions[nodeSemester]?.bounds
			group = newState.groups[nodeSemester+1]
			newNode = createNode action.nodeData, {
				groupBounds: groupBounds
				width: classSpec.WIDTH
				height: classSpec.HEIGHT
			}
			addNode newState, nodeIndex, newNode

			nextGroupBounds = groupPositions[nodeSemester+1]?.bounds
			nextGroup = newState.groups[nodeSemester+1]

			# add option nodes only if the next semester exists
			if nextGroup? and nextGroupBounds
				for optionData in action.options
					optionIndex = newState.nodes.length

					newOption = createNode optionData, {
						semester: 		nodeSemester+1
						groupBounds:	nextGroupBounds
						width: classSpec.WIDTH
						height: classSpec.HEIGHT
					}
					addNode newState, optionIndex, newOption

					newState.links.push
						source: nodeIndex
						target: optionIndex

			im.fromJS newState

		when ADD_SEMESTER
			newState = state.toJS()
			{nodePositions, groupPositions} = action.positionData

			addPositionData newState, {
				nodePositions: nodePositions
				groupPositions: groupPositions
			}

			addClassNodeIndex = newState.nodes.length
			semesterIndex = newState.groups.length
			
			newState.groups.push 
				gid: semesterIndex # todo: better id generation
				leaves:[] # add node will push node index
			
			addClassNodeData = {
				name:			addClassSpec.TEXT
				semester: 		semesterIndex
				type: 			addClassSpec.TYPE
				nid: 			"s#{semesterIndex}"
				width:			addClassSpec.WIDTH
				height:			addClassSpec.HEIGHT
			}

			addNode newState, addClassNodeIndex, addClassNodeData

			# new group constraint based on old one
			# displacements constraints don't have type yet, todo: add them
			displacementConstraints = newState.constraints.filter( (c) -> !c.type?)
			lastConstraint = displacementConstraints[displacementConstraints.length-1]
			newDisplacementConstraint =
				axis: 'x'
				gap: constraintSpec.displacement.GAP
				left: lastConstraint.right
				right: addClassNodeIndex
			newState.constraints.push newDisplacementConstraint

			newAlignmentConstraint =
				axis: 'x'
				type: 'alignment'
				group: semesterIndex
				offsets: [
					node: addClassNodeIndex
					offset: constraintSpec.alignment.OFFSET.x
				]
			newState.constraints.unshift newAlignmentConstraint

			im.fromJS newState

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

			im.fromJS newState
		else state

module.exports = reducer