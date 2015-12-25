React 		= require 'react'
ReactDOM 	= require 'react-dom'
Graph 		= require './components/graph.cjsx'

model = new falcor.Model
	source: new falcor.HttpDataSource 'model.json'

model.
  get("graph").
  then (response) ->
    graphData = JSON.parse response.json.graph
    ReactDOM.render(
    	React.createElement(
    		Graph,
    		{'graphData': graphData}
    	),
    	document.getElementById('react')
    )