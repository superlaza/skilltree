d3 = require 'd3'
webcola = require 'webcola'

{actionAddClass} = require '../../actions/PlanActions.coffee'

class Graph
	constructor: (@graphElement, @graph, @dispatch, @adjList) ->
		@width = 960
		@height = 500
		@pad = 3
		@color = d3.scale.category20()


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


		@count = 0 # delete eventually
		@update()

	tick: =>
		@link
		.attr 		'x1', (d) -> d.source.x
		.attr 		'y1', (d) -> d.source.y
		.attr 		'x2', (d) -> d.target.x
		.attr 		'y2', (d) -> d.target.y

		@node
		.attr 		'x', (d) ->
			# console.log d.name, d.x
			d.x - (d.width / 2)
		.attr 		'y', (d) =>
			# console.log d.name, d.y
			d.y - (d.height / 2) + @pad

		@group
		.attr 		'x', 		(d) ->	d.bounds.x
		.attr 		'y', 		(d) ->	d.bounds.y
		.attr 		'width',	(d) ->
			# console.log 'd in tick', d
			d.bounds.width()
		.attr 		'height', 	(d) ->	d.bounds.height()

		@label
		.attr 		'x', (d) -> d.x
		.attr 		'y', (d) ->
			h = @getBBox().height
			d.y + h / 2
		return

	update: (graph = @graph, up) =>
		if up?
			@cola.stop()
		console.log 'update graph', graph
		@cola = webcola.d3adaptor()
					.linkDistance(100)
					.avoidOverlaps(true)
					.handleDisconnected(false)
					.size([
						@width
						@height
					])

		# g = @stripRefs graph
		# console.log 'g is ', g
		# console.log 'stripped', JSON.stringify g, null, 4
		@cola.nodes(graph.nodes)
			.links(graph.links)
			.groups(graph.groups)
			.constraints(graph.constraints)

		@cola.on 'tick', @tick
		
		# if @c
		# 	@cola.groups(graph.groups)
		# 	@c += 1
		# console.log 'e',@cola.nodes().length, e.length, n.length
		# for group in @cola.groups()
		# 	for leaf in group.leaves
		# 		for node in e
		# 			if leaf.name is node.name
		# 				console.log 'fuck me'
		# 				group.leaves = (_leaf for _leaf in group.leaves when leaf isnt _leaf)

		@group = @group.data @cola.groups(),
					(d) ->
						d.id
		@group.call @cola.drag
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

		onclick = =>
			datum = d3.event.target.__data__
			
			if datum.type is 'menu'
				semester = datum.parent.id # parent group
				className = window.prompt('Pick a class')
				action = actionAddClass(
						className,
						semester,
						@adjList[className],
						@stripRefs @getGraph()
					)
				@dispatch action
			@count += 1

		@node = @node.data @cola.nodes(),
					(d) ->
						d.index
		@node
			.call @cola.drag
			.on 'click', onclick
		@node.enter()
			.insert	'rect', '.node'
				.attr 	'class', 'cola node'
				.attr 	'width',
					(d) =>
						# console.log 'd', typeof d.hidden
						if d.hidden then 0 else d.width - (2 * @pad)
				.attr 	'height',
					(d) => 
						if d.hidden then 0 else d.height - (2 * @pad)
				.attr 	'rx', 5
				.attr 	'ry', 5
				.style	'fill',   (d) => @color @graph.groups.length
				@node.call @cola.drag
				.on('click', onclick)
			.insert('title')
				.text (d) ->
					d.name
				.call @cola.drag
		@node.exit().remove()

		# console.log 'lencheck', n.length, @cola.nodes().length
		# if n.length isnt @cola.nodes().length
		# 	console.log 'pass1'
		# 	if @cola.groups()[0].bounds?
		# 		console.log 'pass2'
		# 		for group in @cola.groups()
		# 			console.log 'before', group.bounds
		# 			group.bounds = webcola.vpsc.computeGroupBounds(group)
		# 			console.log 'after', group.bounds

		@label = @label.data @cola.nodes(), (d) ->
			d.index
		@label
			.call @cola.drag
			.on 'click', onclick
		@label.enter()
			.insert 'text', '.label'
			.attr 'class', 'cola label'
			.call @cola.drag
			.on('click', onclick)
			.text (d) ->
				d.name
		@label.exit().remove()


		# if up?
		# 	duration = 2000
		# 	start = =>
		# 		@cola.start()
		# 	@group.transition().duration(duration)
		# 	.attr 		'x', 		(d) ->
		# 		# console.log 'in first d', d
		# 		# console.log 'bounds', webcola.vpsc.computeGroupBounds(d)
		# 		d.bounds.x
		# 	.attr 		'y', 		(d) ->	d.bounds.y
		# 	.attr 		'width',	(d) ->
		# 		# console.log 'd', d.bounds, d.bounds.X-d.bounds.x
		# 		d.bounds.X-d.bounds.x
		# 	.attr 		'height', 	(d) ->	d.bounds.Y-d.bounds.y

		# 	@node.transition().duration(duration)
		# 	.attr 		'x', (d) ->
		# 		# console.log 'nodedx', d.name, d.x, d.width
		# 		d.x = if d.x? then d.x else 0
		# 		d.x - (d.width / 2)
		# 	.attr 		'y', (d) =>
		# 		# console.log 'nodedy', d.name, d.y, @pad
		# 		d.y = if d.y? then d.y else 0
		# 		d.y - (d.height / 2) + @pad

		# 	@label.transition().duration(duration)
		# 	.attr 		'x', (d) ->
		# 		# console.log 'nodedx', d.name, d.x
		# 		d.x = if d.x? then d.x else 0
		# 	.attr 		'y', (d) ->
		# 		h = @getBBox().height
		# 		# console.log 'labeld', d.name, d.y, h
		# 		d.y = if d.y? then d.y else 0
		# 		d.y + h / 2
		# 	.each 'end', start

		# else
		# 	@cola.start()

		@cola.start()

	getGraph: =>
		return {
			nodes: @cola.nodes()
			links: @cola.links()
			groups: @cola.groups()
			constraints: @cola.constraints()
		}

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
	
	stripRefs: (graph) ->
		# for node in graph.nodes
		nodes = []
		for node in graph.nodes
			newNode = {}
			for key,value of node
				unless key in ['bounds','parent', 'variable']
					newNode[key] = value
			nodes.push newNode

		groups = []
		for group in graph.groups
			leaves = []
			for leaf in group.leaves
				leaves.push(if typeof(leaf) is 'number' then leaf else leaf.index)

			console.log 'my love'
			groups.push
				id: group.id
				leaves: leaves
				bounds:
					x: group.bounds.x
					y: group.bounds.y
					X: group.bounds.X
					Y: group.bounds.Y
		graph.groups = groups

		links = []
		for link in graph.links
			links.push
				source: link.source.index
				target: link.target.index

		nodes: nodes
		groups: groups
		links: links
		constraints: graph.constraints


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