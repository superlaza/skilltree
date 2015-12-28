d3 = require 'd3'
webcola = require 'webcola'

{actionAddClass, actionDeleteClass} = require '../../actions/PlanActions.coffee'

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


		#========= feature selections
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
		#==========

		# map node id to its index in node list
		@indexMap = {}
		for index, node of @graph.nodes
			@indexMap[node.nid] = parseInt index

		# node count, serves as idea for new node creation
		@nodeCount = 0

		@update()

	tick: =>
		@link
		.attr 		'x1', (d) -> d.source.x
		.attr 		'y1', (d) -> d.source.y
		.attr 		'x2', (d) -> d.target.x
		.attr 		'y2', (d) -> d.target.y

		@node
		.attr 'transform', (d) =>
			x = d.x - (d.width/2)
			y = d.y - (d.height / 2) + @pad
			"translate(#{x}, #{y})"
		# .attr 		'x', (d) ->
		# 	# console.log d.name, d.x
		# 	d.x - (d.width / 2)
		# .attr 		'y', (d) =>
		# 	# console.log d.name, d.y
		# 	d.y - (d.height / 2) + @pad

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
		.text (d)->d.nid  # only for testing
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

		@cola.nodes(graph.nodes)
			.links(graph.links)
			.groups(graph.groups)
			.constraints(graph.constraints)

		@cola.on 'tick', @tick
		
		@group = @group.data @cola.groups(),
					(d) ->
						d.gid
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
				className = window.prompt('Pick a class')
				nodeData =
					className: className
					semester: datum.parent.gid # parent group
					nid: @nodeCount

				@nodeCount += 1

				optionsData = []
				for optionName in @adjList[className]
					optionsData.push
						className: optionName
						nid: @nodeCount
					@nodeCount += 1

				action = actionAddClass(
						nodeData,
						optionsData,
						@getPositiondata @cola.nodes(), @cola.groups()
					)
				@dispatch action

		@node = @node.data @cola.nodes(),
					(d) ->
						d.nid
		@node
			.call @cola.drag
			.on 'click', onclick
		enter = @node.enter()
			# .insert	'rect', '.node'
			.insert 'g', '.node-cont'
				.call @cola.drag
				.on 'click', onclick
				.on 'mouseenter', ->
					# assumes target is always class rect element
					# and that the circle will always be at position 1
					cir = d3.event.target.children[1]
					cir.setAttribute('visibility', 'visible')
				.on 'mouseleave', ->
					cir = d3.event.target.children[1]
					cir.setAttribute('visibility', 'hidden')
		enter.append 'rect'
				.attr 'class', 'cola node'
				.attr 'width',
					(d) =>
						# console.log 'd', typeof d.hidden
						if d.hidden then 0 else d.width - (2 * @pad)
				.attr 	'height',
					(d) => 
						if d.hidden then 0 else d.height - (2 * @pad)
				.attr 'rx', 5
				.attr 'ry', 5
				.style 'fill',   (d) => @color @graph.groups.length
		enter.append 'circle'
				.attr 'r', 10
				.attr 'cx', 0
				.attr 'cy', 0
				.attr 'visibility', 'hidden'
				.on 'click', =>
					datum = d3.event.target.__data__
					@dispatch actionDeleteClass(
							datum.nid,
							@getPositiondata @cola.nodes(), @cola.groups()
					)

		enter.append 'title' # todo: inserts title multiple times
				.text (d) ->
					d.name

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
			d.nid
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

	# pure
	getPositiondata: (_nodes, _groups) =>
		nodes = []
		groups = []
		for node in _nodes
			nodes.push
				nid: node.nid
				bounds:
					x: node.bounds.x
					X: node.bounds.X
					y: node.bounds.y
					Y: node.bounds.Y
				x: node.x
				y: node.y

		for group in _groups
			groups.push
				gid: group.gid
				bounds:
					x: group.bounds.x
					y: group.bounds.y
					X: group.bounds.X
					Y: group.bounds.Y

		nodePositions: 	nodes
		groupPositions: groups

module.exports = 
	Graph: Graph