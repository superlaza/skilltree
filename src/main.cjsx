{createStore, compose} = require 'redux'
{ADD_CLASS, DELETE_CLASS} = require './constants/ActionTypes.coffee'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
{Plan_} 	= require './components/plan.cjsx'

im 			= require 'immutable'

initialState = {
	nodes:[
		{index: 0,name:'Add Class',type: 'menu',width:137,height:40},
		{index: 1,name:'b',width:60,height:40},
		{index: 2,name:'c',width:60,height:40},
		{index: 3,name:'Add Class',type: 'menu',width:137,height:40},
		{index: 4,name:'d',width:60,height:40},
		{index: 5,name:'e',width:60,height:40},
		{index: 6,name:'h',width:60,height:40, hidden: true}
	]
	links:[
		{source:1,target:4},
		{source:1,target:5},
		{source:2,target:5}
	]
	groups:[
		{id: 0, leaves:[0,1,2]},
		{id: 1, leaves:[3,4,5]}
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

reducer = (state = initialState, action) ->
	switch action.type
		when ADD_CLASS
			# console.log 'graph', action.graph
			newState = action.graph
			console.log 'child', newState.nodes, newState.constraints
			newClassNode =
				index: newState.nodes.length
				name: action.classCode
				width:60
				height:40
				x: newState.groups[action.semester].bounds.X
				y: newState.groups[action.semester].bounds.Y

			newState.nodes.push newClassNode
			newState.groups[action.semester].leaves.push newClassNode.index
			for constraint in newState.constraints
				if constraint.type is 'alignment' and constraint.group is action.semester
					constraint.offsets.push
						node: newClassNode.index
						offset: 50

			# add option nodes
			for optionCode in action.options
				group = newState.groups[action.semester+1]
				if group? # if there's an existing next semester
					newOptionNode =
						index: newState.nodes.length
						name: optionCode
						width:60
						height:40
						x: group.bounds.X
						y: group.bounds.Y

					newState.nodes.push newOptionNode
					group.leaves.push newOptionNode.index
					newState.links.push
						source: newClassNode.index
						target: newOptionNode.index

					# add option constraints
					for constraint in newState.constraints
						if constraint.type is 'alignment' and constraint.group is action.semester+1
							constraint.offsets.push
								node: newOptionNode.index
								offset: 50
				else
					console.log 'that semester does not exist'
			im.fromJS(newState)

		when DELETE_CLASS
			console.log 'deleting'
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