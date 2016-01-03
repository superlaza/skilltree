{createStore, compose} = require 'redux'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
reducer	= require './reducers/planReducer.coffee'

{Plan_} 				= require './components/Plan.cjsx'
{MajorRequirements_}	= require './components/MajorRequirements.cjsx'

# initialize devtools
DevTools 	= require './dev/DevTools.cjsx'

im              = require 'immutable'

{classSpec, addClassSpec, constraintSpec} = require '../src/constants/Specs.coffee'

POS2State = require './adapters/posAdapter.coffee'

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


	initialState = POS2State majorData.POS, graphData

	store.dispatch {
		type:'INIT'
		initialState: im.fromJS initialState
	}

	ReactDOM.render(
		<Provider store={store}>
			<div style={{display: 'flex'}}>
				<MajorRequirements_ majorData={majorData}/>
				<Plan_  graphData={graphData}
						majorData={majorData}/>
				<DevTools />
			</div>
		</Provider>
		,
		document.getElementById('react')
	)
