React 					= require 'react'
# drawGraph 			= require './utility/drawGraph.coffee'
# {drawGraph} 			= require './utility/colatest.coffee'
{Graph} 			= require './utility/Graph.coffee'

{connect} 				= require 'react-redux'

{actionAddSemester} = require '../actions/PlanActions.coffee'



Skilltree = React.createClass
	componentDidMount: ->

		# {dispatch, state, graphData, majorData} = @props
		graph = @props.course_data

		# @graph = new Graph(this.refs.graph, graph)

		width = 960
		height = 500
		color = d3.scale.category20()

		zoomed = ->
			console.log 'con', container
			container.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
			return

		dragstarted = (d) ->
			d3.event.sourceEvent.stopPropagation()
			d3.select(this).classed 'dragging', true
			return

		dragged = (d) ->
			d3.select(this)
				.attr('cx', d.x = d3.event.x)
				.attr 'cy', d.y = d3.event.y
			return

		dragended = (d) ->
			d3.select(this).classed 'dragging', false
			return

		zoom = d3.behavior.zoom()
						  .scaleExtent([0,100])
						  .on('zoom', zoomed)
		
		drag = d3.behavior.drag()
						  .origin((d) -> d)
						  .on('dragstart', dragstarted)
						  .on('drag', dragged)
						  .on('dragend', dragended)

		# svg = d3.select('body')
		# 		.append('svg')
		# 		.attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom)
		# 		.append('g')
		# 		.attr('transform', 'translate(' + margin.left + ',' + margin.right + ')')
		# 		.call(zoom)

		svg = d3.select(this.refs.graph)
				.append('svg')
				.attr('width', width)
				.attr('height', height)
				.call(zoom)

		# build the arrow.
		svg.append("svg:defs").selectAll("marker")
		    .data(["end"])     # Different link/path types can be defined here
		  .enter().append("svg:marker")   # This section adds in the arrows
		    .attr("id", String)
		    .attr("viewBox", "0 -5 10 10")
		    .attr("refX", 30)
		    .attr("refY", 0)
		    .attr("markerWidth", 3)
		    .attr("markerHeight", 3)
		    .attr("orient", "auto")
		  .append("svg:path")
		    .attr("d", "M0,-5L10,0L0,5");

		# gradient = svg.append("svg:defs")
		# 				  .append("svg:linearGradient")
		# 				    .attr("id", "gradient")
		# 				    .attr("x1", "0%")
		# 				    .attr("y1", "0%")
		# 				    .attr("x2", "100%")
		# 				    .attr("y2", "0%")

		# gradient.append("svg:stop")
		#     .attr("offset", "0%")
		#     .attr("stop-color", "rgb(31, 119, 180)")
		#     .attr("stop-opacity", 1)

		# gradient.append("svg:stop")
		#     .attr("offset", "50%")
		#     .attr("stop-color", "rgb(31, 119, 180)")
		#     .attr("stop-opacity", 1)

		# gradient.append("svg:stop")
		#     .attr("offset", "50%")
		#     .attr("stop-color", "red")
		#     .attr("stop-opacity", 1)

		# gradient.append("svg:stop")
		#     .attr("offset", "100%")
		#     .attr("stop-color", "red")
		#     .attr("stop-opacity", 1)

		rect = svg.append('rect')
				  .attr('width', width)
				  .attr('height', height)
				  .style('fill', 'none')
				  .style('pointer-events', 'all')

		container = svg.append 'g'

		nodeById = d3.map()

		graph.nodes.forEach (node) ->
			nodeById.set(node.code, node)
		graph.links.forEach (link) ->
			link.source = nodeById.get(link.source)
			link.target = nodeById.get(link.target)

		force = d3.layout
				  .force()
				  .charge(-120)
				  .linkDistance(30)
				  .size([width,height])

		svg = container

		force.nodes(graph.nodes)
			 .links(graph.links)
			 .start()
		
		link = svg.selectAll('.link')
				  .data(graph.links)
				  .enter()
				  .append('line')
				  	.attr('class', 'link')
				  	.attr("marker-end", "url(#end)")
				  	.style("stroke-width", 3)
				  	.style("stroke", "grey")
				  	# .style("stroke", "url(#gradient)")

		node = svg.selectAll('.node')
				  .data(graph.nodes)
				  .enter()
					.append('circle')
						.attr('class', 'node')
						.attr('r', 5)
						.style('fill', (d) ->
							color d.group
						).call(force.drag)

		node.append('title').text (d) ->
			d.name
		
		force.on 'tick', ->
			link.attr('x1', (d) ->
			  d.source.x
			).attr('y1', (d) ->
			  d.source.y
			).attr('x2', (d) ->
			  d.target.x
			).attr 'y2', (d) ->
			  d.target.y
			node.attr('cx', (d) ->
			  d.x
			).attr 'cy', (d) ->
			  d.y

	componentDidUpdate: ->
		{dispatch, state, graphData} = @props
		
		console.log 'newstate?', state
		@graph.update(state)

		window.dispatch = dispatch

	render: ->
		console.log 'getst', @props

		# {dispatch} = @props


		<div id='graph' ref='graph'>
			<div> test</div>
		</div>


# mapStateToProps = (state) ->
# 	state: state.toJS()

# Plan_ = connect(mapStateToProps)(Plan)

module.exports =
	Skilltree: 	Skilltree
