{createStore, compose} = require 'redux'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
reducer		= require './reducers/planReducer.coffee'

{Plan_} 	= require './components/plan.cjsx'

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