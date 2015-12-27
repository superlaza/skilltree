{createStore, compose} = require 'redux'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
{Plan_} 	= require './components/plan.cjsx'

im 			= require 'immutable'

initialState = {
	nodes:[
		{index: 0,name:'a',type: 'menu',width:60,height:40},
		{index: 1,name:'b',width:60,height:40},
		{index: 2,name:'c',width:60,height:40},
		{index: 3,name:'d',type: 'menu',width:60,height:40},
		{index: 4,name:'e',width:60,height:40},
		{index: 5,name:'h',width:60,height:40, hidden: true}
	]
	links:[
		# {source:1,target:2},
		# {source:2,target:3},
		# {source:3,target:4},
		# {source:0,target:1},
		# {source:2,target:0},
		# {source:3,target:5},
		# {source:0,target:5}
	]
	groups:[
		{id: 0, leaves:[0,1,2]},
		{id: 1, leaves:[3,4]}
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
				{node: 4, offset: 50}
			]
			group: 1
		}
	]
}
initialState = im.fromJS(initialState)

reducer = (state = initialState, action) ->
	switch action.type
		when 'ADD_CLASS'
			console.log 'graph', action.graph
			newState = action.graph
			newNode =
				index: newState.nodes.length-1
				name: action.classCode
				width:60
				height:40
				x: newState.groups[action.semester].bounds.X
				y: newState.groups[action.semester].bounds.Y

			newState.nodes.push newNode
			newState.groups[action.semester].leaves.push newState.nodes.length-1
			for constraint in newState.constraints
				if constraint.group is action.semester
					constraint.offsets.push
						node: newState.nodes.length-1
						offset: 50
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