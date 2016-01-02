React 					= require 'react'
# drawGraph 			= require './utility/drawGraph.coffee'
# {drawGraph} 			= require './utility/colatest.coffee'
{Graph} 			= require './utility/Graph.coffee'

{connect} 				= require 'react-redux'

{actionAddSemester} = require '../actions/PlanActions.coffee'



Plan = React.createClass
	componentDidMount: ->
		{dispatch, state, graphData, majorData} = @props

		@graph = new Graph(this.refs.graph, state, dispatch, graphData)

	componentDidUpdate: ->
		{dispatch, state, graphData} = @props
		
		console.log 'newstate?', state
		@graph.update(state)

		window.dispatch = dispatch

	render: ->
		{dispatch} = @props
		addSemester = =>
			{nodes, groups, links} = @graph.getGraph()
			dispatch actionAddSemester(@graph.getPositiondata nodes, groups)

		selectorStyle = {position: 'absolute'}
		<div id='graph' ref='graph'>
			<input 	id='class-select'
					style={selectorStyle}
				/>
			<button onClick={addSemester}> add semester</button>
		</div>


mapStateToProps = (state) ->
	state: state.toJS()

Plan_ = connect(mapStateToProps)(Plan)

module.exports =
	Plan: 	Plan
	Plan_: 	Plan_