React 					= require 'react'
# drawGraph 			= require './utility/drawGraph.coffee'
# {drawGraph} 			= require './utility/colatest.coffee'
{Graph} 			= require './utility/colatest.coffee'

{connect} 				= require 'react-redux'

require './sub.cjsx'

count = 0

getGraphData = (data) ->
	{graph, semesters} = data

	nodes 		= []
	links 		= []
	groups 		= []
	constraints = []

	for index, sem of semesters
		if graph? then group = graph.groups[index] else group = {'leaves': []}
		constraint = {
			"type": "alignment",
			"axis": "x",
			"offsets": []
		}
		
		# menu for adding
		nodes.push {
			name: 'menu'+index
			type: 'menu'
			semester: parseInt index
			width:60
			height:40
		}
		group.leaves.push nodes.length-1
		constraint.offsets.push(
			{
				node: nodes.length-1
				offset: 50
			}
		)

		{classes} = sem
		for cls in classes
			nodes.push {
				name: cls
				type: 'course'
				semester: parseInt index
				width: 60
				height: 40
			}
			group.leaves.push nodes.length-1
			constraint.offsets.push(
				{
					node: nodes.length-1
					offset: 50
				}
			)

		groups.push group if classes.length
		constraints.push(constraint)

	graph = 
		nodes: nodes
		links: links
		groups: groups
		constraints: constraints

	# console.log 'graph', JSON.stringify graph, null, 4
	# console.log graph.nodes.length

	graph


Plan = React.createClass
	componentDidMount: ->
		console.log 'p', @props
		{dispatch, state, graphData} = @props
		# dispatch {type: 'ADD_CLASS', semester: 0, classCode: 'cool'}
		# this.refs.graph.innerHTML = 'Hoy'

		# drawGraph(this.refs.graph,
		# 		getGraphData(state.toJS()),
		# 		dispatch)
		# console.log 'see', state, graphData
		@graph = new Graph(this.refs.graph, state, dispatch, graphData)
		# @graph.addNode('newnode', 0)
		window.an = @graph.addNode

	componentDidUpdate: ->
		{dispatch, state, graphData} = this.props
		
		# console.log 'state', state
		# @graph.setGraph(state)
		# new Graph(this.refs.graph, state, dispatch)
		console.log 'newstate?', state
		@graph.update(state, 'up')
		# drawGraph(this.refs.graph,
		# 		getGraphData(state.toJS()),
		# 		dispatch)

	render: ->
		<div id='graph' ref='graph'>
			Hey
		</div>


mapStateToProps = (state) ->
	state: state.toJS()

Plan_ = connect(mapStateToProps)(Plan)

module.exports =
	Plan: 	Plan
	Plan_: 	Plan_