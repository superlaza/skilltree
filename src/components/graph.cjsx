React 		= require 'react'
drawGraph 	= require './utility/drawGraph.coffee'

require './sub.cjsx'

Graph = React.createClass
	componentDidMount: ->
		drawGraph this.refs.graph, this.props.graphData

	render: ->
		<div id='graph' ref='graph'>
			Hey
		</div>

module.exports = Graph