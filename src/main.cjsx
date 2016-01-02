{createStore, compose} = require 'redux'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
reducer	= require './reducers/planReducer.coffee'

{Plan_} 	= require './components/plan.cjsx'

# initialize devtools
DevTools 	= require './dev/DevTools.cjsx'

im              = require 'immutable'

{classSpec, addClassSpec, constraintSpec} = require '../src/constants/Specs.coffee'

# create a liftedCreateStore with devtools func added
finalCreateStore = compose(
	DevTools.instrument(),
	# if window.devToolsExtension then window.devToolsExtension() else f => f
	)(createStore)

store = finalCreateStore reducer

# store = createStore reducer
# store.subscribe ->
# 	console.log 'state is', store.getState().toJS()

model = new falcor.Model
	source: new falcor.HttpDataSource 'model.json'

graphProm = model.get("graph")
majorProm = model.get("major")

Promise.all([graphProm, majorProm]).then (res) ->
	[graph, major] = res

	majorData = JSON.parse major.json.major
	graphData = JSON.parse graph.json.graph # used as a map from code to name below

	initialState = {
		nodes:[]
		links:[]
		groups:[]
		constraints: []
	}


	# initialState = {
	# 	nodes:[
	# 		{nid: -1,name:addClassSpec.TEXT,opaque:true,type: addClassSpec.TYPE,width:addClassSpec.WIDTH,height:addClassSpec.HEIGHT},
	# 		{nid: -2,name:'POS3733',opaque:true, type: classSpec.TYPE, width:classSpec.WIDTH,height:classSpec.HEIGHT}
	# 		]
	# 	links:[
	# 		{source:1,target:4, visible: false},

	# 	]
	# 	groups:[
	# 		{gid: 0, leaves:[0,1,2]},
	# 	]
	# 	constraints: [
	# 		{
	# 			type: 'alignment'
	# 			axis: 'x'
	# 			offsets: [
	# 				{node: 0, offset: 50},
	# 				{node: 1, offset: 50},
	# 				{node: 2, offset: 50}
	# 			]
	# 			group: 0
	# 		},
	# 		{
	# 			axis: 'x'
	# 			left: 0
	# 			right: 3
	# 			gap: constraintSpec.displacement.GAP
	# 		}
	# 	]
	# }
	# initialize with major data

	# to avoid conflict with nodeID gen (which is by node count) when adding nodes
	nodeCount = -1 
	for semester in majorData.POS
		group = []
		groupIndex = initialState.groups.length

		btnAddClass = 
			name: addClassSpec.TEXT
			nid: "#{addClassSpec.TYPE}#{groupIndex}"
			opaque: true
			type: addClassSpec.TYPE
			width: addClassSpec.WIDTH
			height: addClassSpec.HEIGHT
			x: 0 + constraintSpec.displacement.GAP*groupIndex
			y: 0
		nodeCount -= 1

		# alignment and displacement constraints are per group
		displacementConstraint =
			type: 'alignment'
			axis: 'x'
			offsets: []
			group: groupIndex

		# only applicable on > 1 semesters
		if initialState.groups.length > 0
			alignmentConstraint  =
				axis: 'x'
				left: groupAnchorIndex # old anchor index
				right: initialState.nodes.length # new anchor index
				gap: constraintSpec.displacement.GAP

			# link addclassbuttons to enforce a max separation constraint
			initialState.links.push
				source: groupAnchorIndex
				target: initialState.nodes.length
				opaque: false

		groupAnchorIndex = initialState.nodes.length
		group.push groupAnchorIndex
		displacementConstraint.offsets.push {
			node: groupAnchorIndex
			offset: constraintSpec.alignment.OFFSET.x
		}
		initialState.nodes.push btnAddClass

		for course in semester.courses
			# an array signifies a list of non-class placeholders
			if Array.isArray course
				for placeholder in course
					newNode =
						opaque: true
						type: classSpec.TYPE
						width: classSpec.WIDTH
						height: classSpec.HEIGHT
						status: classSpec.status.ENROLLED
					newNode.name = placeholder
					newNode.nid = "placeholder#{nodeCount}"
					nodeCount -= 1

					newNodeIndex = initialState.nodes.length
					group.push newNodeIndex
					displacementConstraint.offsets.push {
						node: newNodeIndex
						offset: constraintSpec.alignment.OFFSET.x
					}

					initialState.nodes.push newNode

			else
				newNode =
					opaque: true
					type: classSpec.TYPE
					width: classSpec.WIDTH
					height: classSpec.HEIGHT
					status: classSpec.status.ENROLLED
				if course of graphData
					newNode.name = graphData[course].name
					newNode.nid = course
				else
					console.log "#{course} is not in graphData"
					newNode.name = course
					newNode.nid = course

				newNodeIndex = initialState.nodes.length
				group.push newNodeIndex
				displacementConstraint.offsets.push {
					node: newNodeIndex
					offset: constraintSpec.alignment.OFFSET.x
				}
				
				initialState.nodes.push newNode

		nodeIndexMap = {}
		for index, node of initialState.nodes
			nodeIndexMap[node.nid] = parseInt index
		for index, node of initialState.nodes
			if node.nid of graphData
				for option in graphData[node.nid].prereqs
					initialState.links.push {
						source: parseInt index
						target: nodeIndexMap[option]
						opaque: false
					}

		initialState.groups.push {
			'leaves': group
			'gid': groupIndex
		}

		if alignmentConstraint?
			initialState.constraints.push alignmentConstraint

		initialState.constraints.unshift displacementConstraint
	
	# for index, node of initialState.nodes
	# 	console.log index, node.name

	# console.log 'init stae', JSON.stringify initialState, null, 4

	store.dispatch {
		type:'INIT'
		initialState: im.fromJS initialState
	}

	ReactDOM.render(
		<Provider store={store}>
			<div>
				<Plan_  graphData={graphData}
						majorData={majorData}/>
				<DevTools />
			</div>
		</Provider>
		,
		document.getElementById('react')
	)
