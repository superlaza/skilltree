d3 = require 'd3'
webcola = require 'webcola'
$ = require 'jquery'
require 'jquery-ui'

{classSpec, addClassSpec, btnDeleteClassSpec} = require '../../constants/Specs.coffee'


{actionAddClass, actionDeleteClass} = require '../../actions/PlanActions.coffee'

class Graph
	constructor: (@graphElement, @graph, @dispatch, @adjList) ->
		# event result persistence
		@clickedNode = null

		d3.select 'body'
			.on 'keydown', @moveNode

		# init graph
		@width = 960
		@height = 500
		@pad = 3
		@color = d3.scale.category20()


		# === SETUP CONTAINING SVG ELEMENT === #
		# by the way, a double click zooms...
		zoomed = => # there's a zoom pan bug when you drag graph, event picks up from point where drag started
			if d3.event.sourceEvent?.type is 'wheel'
				@svg.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
			else
				targetNode = d3.event.sourceEvent?.target.nodeName
				if (targetNode isnt node for node in ['rect','text','g','link','path']).every((e)->e)
					@svg.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
			return
		zoom = d3.behavior.zoom().on('zoom', zoomed)
		@_svg = d3.select(@graphElement)
				.append('svg')
					.attr('width', @width)
					.attr('height', @height)
				.call zoom
		@svg = @_svg.append('g')
		# ==== #

		#========= feature selections
		# add groups (in appropriate render order) for each element type
		# this shit is super unreadable
		classes = ['group', 'link', 'node']
		@svg.append('g').attr('class', cls) for cls in ("#{cls}-group" for cls in classes)
		sel = (className) -> d3.select("g.#{className}-group").selectAll ".#{className}"
		[@group, @link, @node, @label] = (sel cls for cls in classes)

		# @group = @svg.selectAll '.group'
		# @link = @svg.selectAll '.link'
		# @node = @svg.selectAll '.node'
		# @label = @svg.selectAll '.label'
		#==========

		# node count, serves as id for new node creation
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

		@group
		.attr 		'x', 		(d) ->	d.bounds.x
		.attr 		'y', 		(d) ->	d.bounds.y
		.attr 		'width',	(d) ->	d.bounds.width()
		.attr 		'height', 	(d) ->	d.bounds.height()

		return

	update: (graph = @graph, up) =>
		# if up?
		# 	@cola.stop()
		console.log 'update graph', graph
		@cola = webcola.d3adaptor()
					# .linkDistance(100)
					# .jaccardLinkLengths(20,5)
					.symmetricDiffLinkLengths(40)
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
		
		@group = @updateGroups @group, @cola.groups()
		@link = @updateLinks @link, @cola.links()
		@node = @updateNodes @node, @cola.nodes()
		

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
		
	updateNodes: (selection, data) =>
		node = selection.data data,
					(d) ->
						d.nid
		node
			.call @cola.drag
			.on 'click', @onNodeClick

		setVisibility = (vis) -> # decorator
			->
				for child in d3.event.target.children
					if child.className.animVal is btnDeleteClassSpec.CLASS
						child.setAttribute('visibility', vis)
						break
		enter = node.enter()
			.insert 'g', '.node-cont'
				.call @cola.drag
				.on 'click', @onNodeClick
				.on 'mouseenter', setVisibility('visible')
				.on 'mouseleave', setVisibility('hidden')
		enter.append 'rect'
				.attr 'class', (d) ->
					switch d.type
						when addClassSpec.TYPE
							"cola node #{addClassSpec.CLASS}"
						when classSpec.TYPE
							"cola node #{classSpec.CLASS}"
					
				.attr 'width',
					(d) =>
						if d.hidden then 0 else d.width - (2 * @pad)
				.attr 	'height',
					(d) => 
						if d.hidden then 0 else d.height - (2 * @pad)
				.attr 'rx', 5
				.attr 'ry', 5
				.style 'fill',   (d) => @color @graph.groups.length
		enter.append 'text'
				.attr 'class', 'cola label'
				.attr 'x', (d) -> d.width/2
				.attr 'y', (d) -> d.height/2
			.call @cola.drag
			.text (d) ->
				d.name
		enter.append 'title' # todo: inserts title multiple times
				.text (d) ->
					d.name

		# only add delete button to class types
		enter = enter.filter (d) -> d.type is 'class'

		# this whole button is just me being lazy
		# listen, it was late, didn't want to learn anything new
		deleteButton = enter.append 'g'
				.attr 'transform', 'scale(0.13) translate(-150, -80)'
				.attr 'class', btnDeleteClassSpec.CLASS
				.attr 'visibility', 'hidden'
				.on 'click', =>
					datum = d3.event.target.__data__
					@dispatch actionDeleteClass(
							datum.nid,
							@getPositiondata @cola.nodes(), @cola.groups()
					)

		appendButton = (path) ->
			deleteButton.append 'path'
							.attr 'd', path
							.style 'fill', '#e00'
							.style 'fill-opacity', 1
							.style 'fill-rule', 'evenodd'
							.style 'stroke', 'none'
							.style 'stroke-width', '0.25pt'
							.style 'stroke-linecap', 'butt'
							.style 'stroke-linejoin', 'miter'
							.style 'stroke-opacity', 1
		appendButton path for path in ['M 100,60 L 60,100 L 230,270 L 270,230 L 100,60 z', 'M 60,230 L 230,60 L 270,100 L 100,270 L 60,230 z']




		node.exit().remove()

		node

	updateGroups: (selection, data) =>
		group = selection.data data,
					(d) ->
						d.gid
		group.call @cola.drag
		group.enter()
			# .insert 'rect', '.group'
			.append 'rect'
			.attr 'rx', 8
			.attr 'ry', 8
			.attr 'class', 'cola group'
			.style 'fill', (d, i) =>
					@color i
			.call @cola.drag
		group.exit().remove()

		group

	updateLinks: (selection, data) =>
		link = selection.data data
		link.enter()
			.insert 'line', '.link'
			.attr 'class', 'cola link'
		link.exit().remove()

		link

	onNodeClick: =>
		return if d3.event.defaultPrevented # default is prevented on drag
		
		targetNode = d3.event.target
		datum = targetNode.__data__ 

		console.log 'd', datum.type
		switch datum.type
			when classSpec.TYPE
		
				if targetNode.nodeName is 'text'
					targetNode = targetNode.parentNode.children[0] # switch to rect

				# set previously clicked node back to default color
				if @clickedNode?
					@clickedNode.setAttribute('style', "fill: #{classSpec.COLOR.DEFAULT}")
				# set newly clicked node's color, and store it
				targetNode.setAttribute('style', "fill: #{classSpec.COLOR.SELECTED}")
				@clickedNode = targetNode
				

			when addClassSpec.TYPE
				input = @graphElement.children[0]
				input = $('#class-select', @graphElement)
				input.autocomplete {
					source: (key for key of @adjList)
					autoFocus: true
				}

				# input.css 'left', "#{datum.x-13}px"
				# input.css 'top', "#{datum.y+10}px"
				
				# className = window.prompt('Pick a class')
				className = 'dymm'
				input.keypress (e) =>
					if e.keyCode is 13
						
						className = e.target.value
						nodeData =
							className: className
							semester: datum.parent.gid # parent group
							nid: @nodeCount
							type: classSpec.TYPE
							width: classSpec.WIDTH
							height: classSpec.HEIGHT

						@nodeCount += 1

						optionsData = []
						for optionName in @adjList[className]
							optionsData.push
								className: optionName
								nid: @nodeCount
								type: classSpec.TYPE
								width: classSpec.WIDTH
								height: classSpec.HEIGHT
							@nodeCount += 1

						action = actionAddClass(
								nodeData,
								optionsData,
								@getPositiondata @cola.nodes(), @cola.groups()
							)
						@dispatch action

	moveNode: =>
		return if !@clickedNode?
		clickedNode = @clickedNode.__data__ # clicked node is stored as DOM element

		map = {}
		# make a map of index -> offset, get index of clickedNode's offset spec
		for constraint in @cola.constraints()
			if constraint.type? and constraint.group is clickedNode.parent.gid
				for index, offset of constraint.offsets
					map[index] = offset
					if clickedNode.index is offset.node
						saveIndex = parseInt(index)
		
		# move up or down
		if d3.event.keyCode is 40
			d3.event.preventDefault()
			offset = 1
		if d3.event.keyCode is 38
			d3.event.preventDefault()
			offset = -1

		swapIndex = saveIndex+offset
		maxIndex = (_ for _ of map).length
		# so long as the index of the swapping node is in bounds...
		if 0<swapIndex and swapIndex<maxIndex
			# perform swap
			[map[saveIndex],map[saveIndex+offset]] = [map[saveIndex+offset],map[saveIndex]]

			# graph the relevant live node objects for updating their positions
			for node in @cola.nodes()
				if node.index is clickedNode.index
					node1 = node
				if node.index is map[saveIndex].node # since i switched them
					node2 = node
			
			# swap their positions
			[node1.x, node2.x] = [node2.x, node2.x]
			[node1.y, node2.y] = [node2.y, node2.y]

			# update the constraints with the switch
			newConstraints = []
			for constraint in @cola.constraints()
				if constraint.type?
					newConstraint = 
						axis: constraint.axis
						group: constraint.group
						type: constraint.type

					if constraint.group is clickedNode.parent.gid
						newConstraint.offsets = (offset for _, offset of map)
					else
						newConstraint.offsets = constraint.offsets
				else
					newConstraint =
						axis: constraint.axis
						left: constraint.left
						right: constraint.right
						gap: constraint.gap

				newConstraints.push newConstraint

			# add to simulation and restart
			@cola.constraints(newConstraints)
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

	getGraph: =>
		nodes: @cola.nodes()
		groups: @cola.groups()
		links: @cola.links()

module.exports = 
	Graph: Graph