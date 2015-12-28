{createStore, compose} = require 'redux'
{ADD_CLASS, DELETE_CLASS} = require './constants/ActionTypes.coffee'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
{Plan_} 	= require './components/plan.cjsx'

im 			= require 'immutable'

initialState = {
	nodes:[
		{nid: -1,name:'Add Class',type: 'menu',width:137,height:40},
		{nid: -2,name:'b',width:60,height:40},
		{nid: -3,name:'c',width:60,height:40},
		{nid: -4,name:'Add Class',type: 'menu',width:137,height:40},
		{nid: -5,name:'d',width:60,height:40},
		{nid: -6,name:'e',width:60,height:40},
		{nid: -7,name:'h',width:60,height:40, hidden: false}
	]
	links:[
		{source:1,target:4},
		{source:1,target:5},
		{source:2,target:5}
	]
	groups:[
		{gid: 0, leaves:[0,1,2]},
		{gid: 1, leaves:[3,4,5]}
	]
	constraints: [
		{
			type: 'alignment'
			axis: 'x'
			offsets: [
				{node: 0, offset: 50},
				{node: 1, offset: 50},
				{node: 2, offset: 50}
			]
			group: 0
		},
		{
			type: 'alignment'
			axis: 'x'
			offsets: [
				{node: 3, offset: 50},
				{node: 4, offset: 50},
				{node: 5, offset: 50}
			]
			group: 1
		},
		{
			axis: 'x'
			left: 0
			right: 3
			gap: 200
		}
	]
}
initialState = im.fromJS(initialState)

# add node, delete all in group 1, undo add node
reducer = (state = initialState, action) ->
	switch action.type
		when ADD_CLASS
			# console.log 'graph', action.graph
			newState = state.toJS()
			{nodePositions, groupPositions} = action.positionData
			{className, semester, nid} = action.nodeData

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

		when DELETE_CLASS
			# newState = action.graph
			newState = state.toJS() # todo: shouldn't need to convert to js, fix later
			{nodePositions, groupPositions} = action.positionData

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

# initialize devtools
DevTools 	= require './dev/DevTools.cjsx'
# create a liftedCreateStore with devtools func added
finalCreateStore = compose(
	DevTools.instrument(),
	# if window.devToolsExtension then window.devToolsExtension() else f => f
	)(createStore)

store = finalCreateStore reducer
# store = createStore reducer

# store.subscribe ->
# 	console.log 'state is', store.getState().toJS()

# store.dispatch {
# 	type: 'ADD_CLASS'
# 	classCode: 'TEST0000'
# 	semester: 0
# }
window.store = store

model = new falcor.Model
	source: new falcor.HttpDataSource 'model.json'

model.
  get("graph").
  then (response) ->
    graphData = JSON.parse response.json.graph
    ReactDOM.render(
    	<Provider store={store}>
    		<div>
    			<Plan_ graphData={graphData}/>
    			<DevTools />
    		</div>
    	</Provider>
    	,
    	document.getElementById('react')
    )