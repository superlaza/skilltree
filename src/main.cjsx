{createStore, compose} = require 'redux'

React 		= require 'react'
ReactDOM 	= require 'react-dom'

{Provider}	= require 'react-redux'
{Plan_} 	= require './components/plan.cjsx'

im 			= require 'immutable'

initialState = {
	semesters: [
		{
			classes: ['a', 'b', 'c']
		},
		{
			classes: ['d', 'e']
		}
	]
}
initialState = im.fromJS(initialState)

reducer = (state = initialState, action) ->
	switch action.type
		when 'ADD_CLASS'
			newState = state.updateIn ['semesters', action.semester, 'classes'], 
				(classList) ->
					classList.push(action.classCode)
			newState.set('graph', action.graph)
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
# 	console.log 'state is', JSON.stringify store.getState().toJS(), null, 4

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