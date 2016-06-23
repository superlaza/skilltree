{createStore, compose} = require 'redux'

request = require 'browser-request'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
reducer	= require './reducers/planReducer.coffee'

# {Plan_} 				= require './components/Plan.cjsx'
{Skilltree} 				= require './components/Skilltree.cjsx'
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

request '/model.json', (er, response, body) ->
	if(er)
		throw er;
	course_data = JSON.parse(body)

	store.dispatch {
		type:'INIT'
		initialState: im.fromJS {}
	}

	ReactDOM.render(
		<Provider store={store}>
			<div style={{display: 'flex'}}>
				<Skilltree course_data={course_data}/>
				<DevTools />
			</div>
		</Provider>
		,
		document.getElementById('react')
	)


# store = createStore reducer
# store.subscribe ->
# 	console.log 'state is', store.getState().toJS()

# model = new falcor.Model
# 	source: new falcor.HttpDataSource 'model.json'

# graphProm = model.get("graph")
# majorProm = model.get("major")

# Promise.all([graphProm, majorProm]).then (res) ->
# 	[graph, major] = res

# 	majorData = JSON.parse major.json.major
# 	graphData = JSON.parse graph.json.graph # used as a map from code to name below


# 	initialState = POS2State majorData.POS, graphData

# 	store.dispatch {
# 		type:'INIT'
# 		initialState: im.fromJS initialState
# 	}

# 	ReactDOM.render(
# 		<Provider store={store}>
# 			<div style={{display: 'flex'}}>
# 				<MajorRequirements_ majorData={majorData}/>
# 				<Plan_  graphData={graphData}
# 						majorData={majorData}/>
# 				<DevTools />
# 			</div>
# 		</Provider>
# 		,
# 		document.getElementById('react')
# 	)
