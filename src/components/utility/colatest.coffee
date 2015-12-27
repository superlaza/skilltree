d3 = require 'd3'
webcola = require 'webcola'

class Graph
	constructor: (@graphElement, @graph) ->
		@width = 960
		@height = 500
		@pad = 3
		@color = d3.scale.category20()
		@cola = webcola.d3adaptor()
					.linkDistance(100)
					.avoidOverlaps(true)
					.handleDisconnected(false)
					.size([
						@width
						@height
					])

		@svg = d3.select(@graphElement)
				.append('svg')
					.attr('width', @width)
					.attr('height', @height)

		# add groups (in appropriate render order) for each element type
		# this shit is super unreadable
		classes = ['group', 'link', 'node', 'label']
		@svg.append('g').attr('class', cls) for cls in ("#{cls}-group" for cls in classes)
		sel = (className) -> d3.select("g.#{className}-group").selectAll ".#{className}"
		[@group, @link, @node, @label] = (sel cls for cls in classes)

		# @group = @svg.selectAll '.group'
		# @link = @svg.selectAll '.link'
		# @node = @svg.selectAll '.node'
		# @label = @svg.selectAll '.label'

		@cola.nodes(@graph.nodes)
			.links(@graph.links)
			.groups(@graph.groups)
			.constraints(@graph.constraints)

		@cola.on 'tick', @tick
	
		@update()

	tick: =>
		@link
		.attr 		'x1', (d) -> d.source.x
		.attr 		'y1', (d) -> d.source.y
		.attr 		'x2', (d) -> d.target.x
		.attr 		'y2', (d) -> d.target.y

		@node
		.attr 		'x', (d) -> d.x - (d.width / 2)
		.attr 		'y', (d) => d.y - (d.height / 2) + @pad

		@group
		.attr 		'x', 		(d) ->	d.bounds.x
		.attr 		'y', 		(d) ->	d.bounds.y
		.attr 		'width',	(d) ->	d.bounds.width()
		.attr 		'height', 	(d) ->	d.bounds.height()

		@label
		.attr 		'x', (d) -> d.x
		.attr 		'y', (d) ->
			h = @getBBox().height
			d.y + h / 2
		return

	update: (graph = @graph) =>
		console.log 'group', graph, graph.constraints
		console.log 'colacontraints', @cola.constraints()
		@group = @group.data @cola.groups(),
					(d) ->
						d.id
		@group.enter()
			# .insert 'rect', '.group'
			.append 'rect'
			.attr 'rx', 8
			.attr 'ry', 8
			.attr 'class', 'cola group'
			.style 'fill', (d, i) =>
					@color i
			.call @cola.drag
		@group.exit().remove()

		@link = @link.data @cola.links()
		@link.enter()
			.insert 'line', '.link'
			.attr 'class', 'cola link'
		@link.exit().remove()

		@node = @node.data @cola.nodes(),
					(d) ->
						d.name
		@node.enter()
			.insert	'rect', '.node'
				.attr 	'class', 'cola node'
				.attr 	'width',
					(d) =>
						console.log 'd', typeof d.hidden
						if d.hidden then 0 else d.width - (2 * @pad)
				.attr 	'height',
					(d) => 
						if d.hidden then 0 else d.height - (2 * @pad)
				.attr 	'rx', 5
				.attr 	'ry', 5
				.style	'fill',   (d) => @color @graph.groups.length
				.call @cola.drag
			.insert('title')
				.text (d) ->
					d.name
				.call @cola.drag
		@link.exit().remove()

		@label = @label.data @graph.nodes
		@label.enter()
			.insert 'text', '.label'
			.attr 'class', 'cola label'
			.text (d) ->
				d.name
			.call @cola.drag
		@label.exit().remove()

		@cola.start()

	addNode: (name, semester) =>
		newNode =
			name:	name
			width:	60
			height:	40

		@graph.nodes.push newNode
			

		@graph.groups[semester].leaves.push newNode

		# for index, node of @graph.nodes
		# 	groups[semester].leaves.push index

		# console.log 'l;askdfj', @graph.groups, semester
		# if @graph.groups[semester]?
		# 	console.log 'yes', @graph.nodes, @graph.groups[semester]
		# 	@graph.groups[semester].leaves.push @graph.nodes.length-1
		# else
		# 	@graph.groups.push
		# 		'leaves': [@graph.nodes.length-1]

		# @graph.groups = groups
		# @cola.groups(groups)
		# @cola.groups(groups)

		@update()
		# graph.links.push
		# 	source:	graph.nodes.length-1
		# 	target: target

		# map[name] =
		# 	index: graph.nodes.length-1
		# 	links: [graph.links.length-1]

		# map[graph.nodes[target].name].links.push(graph.links.length-1)

		# console.log map
	
	addSemester: =>
		@graph.nodes.push
			name: 'dummy'
			width: 40
			height: 40
			hidden: true

		@update()
		


drawGraph = (graphElement, graph) ->
	width = 960
	height = 500
	pad = 3
	color = d3.scale.category20()
	cola = webcola.d3adaptor()
				.linkDistance(100)
				.avoidOverlaps(true)
				.handleDisconnected(false)
				.size([
					width
					height
				])

	svg = d3.select(graphElement)
			.append('svg')
				.attr('width', width)
				.attr('height', height)

	# add groups (in appropriate render order) for each element type
	# this shit is super unreadable
	classes = ['group', 'link', 'node', 'label']
	svg.append('g').attr('class', cls) for cls in ("#{cls}-group" for cls in classes)
	sel = (className) -> d3.select("g.#{className}-group").selectAll ".#{className}"
	[group, link, node, label] = (sel cls for cls in classes)

	cola.nodes(graph.nodes)
		.links(graph.links)
		.groups(graph.groups)
		# .constraints(graph.constraints)

	update = (graph) ->
		group = group.data graph.groups
		group.enter()
			.insert 'rect'
			.attr 'rx', 8
			.attr 'ry', 8
			.attr 'class', 'group'
			.style 'fill', (d, i) ->
					console.log 'group el', d, i
					color i
			.call cola.drag
		group.exit().remove()

		link = link.data cola.links()
		link.enter()
			.insert 'line'
			.attr 'class', 'cola link'
		link.exit().remove()

		node = node.data cola.nodes(), (d) ->
			d.name
		node.enter()
			.insert	'rect'
				.attr 	'class', 'cola node'
				.attr 	'width',  (d) -> d.width - (2 * pad)
				.attr 	'height', (d) -> d.height - (2 * pad)
				.attr 	'rx', 5
				.attr 	'ry', 5
				.style	'fill',   (d) -> color graph.groups.length
				.call cola.drag
			.insert('title')
				.text (d) ->
					d.name
				.call cola.drag
		link.exit().remove()

		label = label.data graph.nodes
		label.enter()
			.insert 'text'
			.attr 'class', 'label'
			.text (d) ->
				d.name
			.call cola.drag
		label.exit().remove()

		cola.start()

	update graph

	tick = ->
		link
		.attr 		'x1', (d) -> d.source.x
		.attr 		'y1', (d) -> d.source.y
		.attr 		'x2', (d) -> d.target.x
		.attr 		'y2', (d) -> d.target.y

		node
		.attr 		'x', (d) -> d.x - (d.width / 2)
		.attr 		'y', (d) -> d.y - (d.height / 2) + pad

		group
		.attr 		'x', 		(d) ->	d.bounds.x
		.attr 		'y', 		(d) ->	d.bounds.y
		.attr 		'width',	(d) ->	d.bounds.width()
		.attr 		'height', 	(d) ->	d.bounds.height()

		label
		.attr 		'x', (d) -> d.x
		.attr 		'y', (d) ->
			h = @getBBox().height
			d.y + h / 2
		return

	cola.on 'tick', tick

	return

module.exports = 
	Graph: Graph