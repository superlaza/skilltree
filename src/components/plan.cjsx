React 					= require 'react'
# drawGraph 			= require './utility/drawGraph.coffee'
# {drawGraph} 			= require './utility/colatest.coffee'
{Graph} 			= require './utility/Graph.coffee'

{connect} 				= require 'react-redux'

require './sub.cjsx'

Plan = React.createClass
	componentDidMount: ->
		{dispatch, state, graphData} = @props

		@graph = new Graph(this.refs.graph, state, dispatch, graphData)

	componentDidUpdate: ->
		{dispatch, state, graphData} = this.props
		
		console.log 'newstate?', state
		@graph.update(state, 'up')

		window.dispatch = dispatch

	render: ->
		selectorStyle = {position: 'absolute'}
		<div id='graph' ref='graph'>
			<input 	id='class-select'
					style={selectorStyle}
				/>
		</div>


mapStateToProps = (state) ->
	state: state.toJS()

Plan_ = connect(mapStateToProps)(Plan)

module.exports =
	Plan: 	Plan
	Plan_: 	Plan_