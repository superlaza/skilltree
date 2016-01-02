# CONSTANTS
{ADD_CLASS, DELETE_CLASS, ADD_SEMESTER} = require '../constants/ActionTypes.coffee'
{classSpec, addClassSpec, constraintSpec} = require '../constants/Specs.coffee'

im 				= require 'immutable'
# initialState 	= require '../../data/initialState.coffee'
# initialState 	= im.fromJS(initialState)

initialState = im.fromJS {
	nodes:[]
	links:[]
	groups:[]
	constraints: []
}

# UTILITY
# impure
addPositionData = (newState, data) ->
	{nodePositions} = data
	# infuse location data			
	for index, node of newState.nodes
		positions = nodePositions[index]
		# only update position if node exists
		if node? and positions?
			node.x = positions.x
			node.y = positions.y
				
# impure
createNode = (attrsList...) ->
	nodeAttrs = {}
	for attrs in attrsList
		for key, attr of attrs
			nodeAttrs[key] = attr	

	# DATA
	# ====
	newNode = { # all nodes will have a name and id
		name:		nodeAttrs.className
		nid:			nodeAttrs.nid
	}

	newNode.type = nodeAttrs.type if nodeAttrs.type?
	newNode.status = if nodeAttrs.status? then nodeAttrs.status else classSpec.status.ENROLLED
	newNode.semester = nodeAttrs.semester if nodeAttrs.semester?
	
	# STYLE
	# ====
	newNode.width  = nodeAttrs.width
	newNode.height = nodeAttrs.height
	if nodeAttrs.groupBounds?
		newNode.x = nodeAttrs.groupBounds.X
		newNode.y = nodeAttrs.groupBounds.Y
	newNode.opaque	= true

	newNode

addNode = (state, index, node) ->
	state.nodes.push node
	state.groups[node.semester].leaves.push index
	for constraint in state.constraints
		if constraint.type is 'alignment' and constraint.group is node.semester
			constraint.offsets.push
				node: index
				offset: constraintSpec.alignment.OFFSET.x

	# state.constraints.unshift {
	# 	axis: 'y'
	# 	left: state.groups[node.semester].leaves[0] # root node of group
	# 	right: index # new anchor index
	# 	gap: 20
	# 	equality: 'true'
	# }

fn_ADD_CLASS = (newState, action) ->
	{nodePositions, groupPositions} = action.positionData

	nodeIndex = if action.nodeData.index? then action.nodeData else newState.nodes.length
	nodeSemester = action.nodeData.semester

	groupBounds = groupPositions[nodeSemester]?.bounds
	newNode = createNode action.nodeData, {
		groupBounds: groupBounds
	}
	addNode newState, nodeIndex, newNode

	prevGroupBounds = groupPositions[nodeSemester-1]?.bounds
	prevGroup = newState.groups[nodeSemester-1]

	# === ADD OPTIONS COURSES
	# add option nodes only if the prev semester exists
	if prevGroup? and prevGroupBounds
		for optionData in action.options
			optionIndex = newState.nodes.length

			newOption = createNode optionData, {
				semester: 		nodeSemester-1
				groupBounds:	prevGroupBounds
				status:			classSpec.status.PREREQ
			}
			addNode newState, optionIndex, newOption

			# add new links
			newState.links.push
				source: nodeIndex
				target: optionIndex
				opaque: false

	newState

fn_DELETE_CLASS = (newState, action) ->
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
	
	newState.contraints = newState.constraints.filter (c) ->
		if !c.type?
			# nodes that can be deleted only appear on right for now
			if c.left is delNodeIndex or c.right is delNodeIndex
				return false
		true
	for constraint in newState.constraints
		if constraint.type is 'alignment'					# yo dawg...
			constraint.offsets = ({node:(remap offset.node), offset:offset.offset} for offset in constraint.offsets when offset.node isnt delNodeIndex)
		else
			constraint.left = remap	constraint.left
			constraint.right = remap constraint.right
	# delete all links attached to node
	# maybe later we might want to delete the nodes it points to as well
	newState.links = ({source:(remap link.source), target:(remap link.target)} for link in newState.links when (link.source isnt delNodeIndex and link.target isnt delNodeIndex))

	newState


# add node, delete all in group 1, undo add node
reducer = (state = initialState, action) ->
	switch action.type
		when 'INIT'
			console.log 'state', typeof state, state
			newState = state.toJS()

			im.fromJS action.initialState

		when ADD_CLASS
			newState = state.toJS()

			{nodePositions, groupPositions} = action.positionData
			addPositionData newState, {
				nodePositions: nodePositions
				groupPositions: groupPositions
			}

			im.fromJS fn_ADD_CLASS(newState, action)

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
				nid: 			"#{addClassSpec.TYPE}#{semesterIndex}"
				width:			addClassSpec.WIDTH
				height:			addClassSpec.HEIGHT
				opaque:			true
			}

			addNode newState, addClassNodeIndex, addClassNodeData

			# new group constraint based on old one
			# displacements constraints don't have type yet, todo: add them
			displacementConstraints = newState.constraints.filter( (c) -> c.type isnt 'alignment')
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

			im.fromJS fn_DELETE_CLASS(newState, action)

		when 'MOVE_CLASS'
			console.log 'state', typeof state, state
			newState = state.toJS() # todo: shouldn't need to convert to js, fix later

			{nodePositions, groupPositions} = action.positionData
			addPositionData newState, {
				nodePositions: nodePositions
				groupPositions: groupPositions
			}

			im.fromJS (fn_ADD_CLASS fn_DELETE_CLASS(newState, action), action)
			# im.fromJS fn_DELETE_CLASS(newState, action)
			# im.fromJS fn_ADD_CLASS newState, action
		else state

init = (init) ->
	initialState = im.fromJS(init)	

module.exports = reducer
