d3 = require 'd3'
webcola = require 'webcola'
$ = require 'jquery'
require 'jquery-ui'

Specs = require '../../constants/Specs.coffee'
classSpec 			= Specs.classSpec
addClassSpec 		= Specs.addClassSpec
btnDeleteClassSpec 	= Specs.btnDeleteClassSpec
constraintSpec 		= Specs.constraintSpec
groupSpec			= Specs.groupSpec

{actionAddClass, actionDeleteClass} = require '../../actions/PlanActions.coffee'

class Graph
	constructor: (@graphElement, @graph) ->
		# event result persistence
		@clickedNode = null

		# flags
		@opacityChanged = false

		d3.select 'body'
			.on 'keydown', @moveNode

		# init graph
		@width = 1800
		@height = 1000
		@pad = 3
		@color = d3.scale.category20()
		@defaultScale = 0.6


		# === SETUP CONTAINING SVG ELEMENT === #
		# by the way, a double click zooms...
		zoomed = => # there's a zoom pan bug when you drag graph, event picks up from point where drag started
			if d3.event.sourceEvent?.type is 'wheel'
				if @zoomDisabled?
					return

				# doesn't fix the issue that when scale is 
				# restored after input, d3.event.translate keeps changing value
				# if @oldTransform?
				# 	[tx, ty, scale] = @oldTransform.match(/translate\((.*?),(.*?)\)scale\((.*?)\)/)[1..3]
				# 	d3.event.translate = [tx, ty]
				# 	d3.event.scale = scale
				# 	@oldTransform = undefined

				@svg.attr 'transform', "translate(#{d3.event.translate})scale(#{d3.event.scale})"
				
			# else
			# 	targetNode = d3.event.sourceEvent?.target.nodeName
			# 	if (targetNode isnt node for node in ['rect','text','g','link','path']).every((e)->e)
			# 		@svg.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
			return
		zoom = d3.behavior.zoom().on('zoom', zoomed)
		@_svg = d3.select(@graphElement)
				.append('svg')
					.attr('width', @width)
					.attr('height', @height)
				.call zoom
		@svg = @_svg.append('g')
					.attr 'transform', "translate(5,110)scale(#{@defaultScale})"
		# ==== #

		#========= feature selections
		@svg.append('g').attr('class', 'group-group')
		@svg.append('g').attr('class', 'link-group')
		@svg.append('g').attr('class', 'node-group')

		@group = d3.select("g.group-group").selectAll ".group"
		@link = d3.select("g.link-group").selectAll ".link"
		@node = d3.select("g.node-group").selectAll ".node"

		# node count, serves as id for new node creation
		@nodeCount = 0

		# for mapping global mouse coords to svg loc
		@refPoint = @_svg[0][0].createSVGPoint()

		@update()

	tick: =>
		@link
		.attr 'x1', (d) -> d.source.x
		.attr 'y1', (d) -> d.source.y
		.attr 'x2', (d) -> d.target.x
		.attr 'y2', (d) -> d.target.y

		@node
		.attr 'transform', (d) =>
			x = d.x - (d.width/2)
			y = d.y - (d.height / 2) + @pad
			"translate(#{x}, #{y})"
		.attr 'visibility', (d) ->
			if d.hidden?
				'hidden'
			else
				'visible'
		
		if @opacityChanged
			@link.transition()
				.delay (d) ->
					if d.opaque then 400 else 0
				# .ease('exp')
				.style 'opacity', (d) ->
					if d.opaque then 1 else 0
			@node.transition()
				.delay(250)
				# .ease('linear')
				.style 'opacity', (d) ->
					if d.opaque then 1 else classSpec.OPACITY

		@group
		.attr 		'x', 		(d) ->	d.bounds.x
		.attr 		'y', 		(d) ->	d.bounds.y
		.attr 		'width',	(d) ->	d.bounds.width()
		.attr 		'height', 	(d) ->	d.bounds.height()

		return

	update: (graph = @graph) =>
		# DEBUGGING
		# console.log 'update graph', graph
		# console.log 'new graph', JSON.stringify graph, null, 4 if !@cola?
		# console.log 'update graph', JSON.stringify @stripRefs(graph), null, 4 if @cola?
		
		@cola.stop() if @cola
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
			# .groups(graph.groups)
			# .constraints(graph.constraints)

		# @cola.on 'tick', @tick

		# @group = @updateGroups @group, @cola.groups()
		@link = @updateLinks @link, @cola.links()
		@node = @updateNodes @node, @cola.nodes()
		
		@cola.start()

	updateNodes: (selection, data) =>
		onMouseDown = =>
			# get coordinates to filter simple click
			@currentPosition = [d3.event.clientX, d3.event.clientY]

			targetNode = d3.event.target
			@moveNode = targetNode.__data__

			# don't move add class buttons
			if @moveNode.type is addClassSpec.TYPE
				return

			# get container
			while targetNode.className.animVal isnt 'node-cont'
				targetNode = targetNode.parentNode

			# convert from global coordinates
			[@refPoint.x, @refPoint.y] = @currentPosition
			{x,y} = @refPoint.matrixTransform @svg[0][0].getScreenCTM().inverse()
			

			# STYLE CHANGES

			# get relevant svg rect element
			for child in targetNode.children
				if child.nodeName is 'rect'
					rect = child
					break

			# style the ghost node
			ghostFill = rect.getAttribute('style').match(/fill: (.*?);/)[1]
			# attach ghost node, then grab it, storing in global
			@svg.append 'rect'
					.attr 'class', 'move-node-ghost'
					.attr 'width', classSpec.WIDTH
					.attr 'height', classSpec.HEIGHT
					.attr 'rx', 5
					.attr 'ry', 5
					.attr 'x', x
					.attr 'y', y
					.style 'opacity', 0
					.style 'fill', ghostFill ? 'grey'
			@ghost = @svg.select('.move-node-ghost')

			# @cola.nodes()[@moveNode.index].hidden = true
			# ============

			# add listeners to be removed later
			@graphElement.addEventListener 'mousemove', moveGhostNode
			@graphElement.addEventListener 'mouseup', onMouseUp
			return true

		onMouseUp = (e) =>
			if @inRange
				@ghost.remove()
				@graphElement.removeEventListener 'mousemove', moveGhostNode
				return

			targetNode = e.target

			# if we landed in anything within a node container
			if targetNode.className.animVal.indexOf('class-node') isnt -1
				# get top level node container
				while targetNode.className.animVal isnt 'node-cont'
					targetNode = targetNode.parentNode
				datum = targetNode.__data__

				# create node to be added from old, using the
				# target node's semester id
				nodeData =
					className: @moveNode.name
					semester: datum.parent.gid # parent group
					nid: @moveNode.nid
					type: classSpec.TYPE
					width: classSpec.WIDTH
					height: classSpec.HEIGHT
				@nodeCount += 1

				# optionsData = []
				# for optionName in @adjList[classCode].prereqs
				# 	optionsData.push
				# 		className: @adjList[optionName].name
				# 		nid: optionName
				# 		type: classSpec.TYPE
				# 		width: classSpec.WIDTH
				# 		height: classSpec.HEIGHT
				# 	@nodeCount += 1

				@dispatch {
					type: 			'MOVE_CLASS'
					nodeData:		nodeData
					options:		[]
					nodeID:			nodeData.nid
					positionData:	@getPositiondata @cola.nodes(), @cola.groups()
				}

			else
				@nodeIDMap[@moveNode.nid].hidden = undefined
				@tick()
				console.log 'did not land on element', targetNode.className.animVal


			# clean up
			@ghost.remove()
			@graphElement.removeEventListener 'mousemove', moveGhostNode


		node = selection.data data,
					(d) ->
						d.code
		node
			# .call @cola.drag
			.on 'click', @onNodeClick
			.on 'mousedown', onMouseDown

		enter = node.enter()
			.insert 'g', '.node-cont'
				.attr 'class', 'node-cont'
				.style 'opacity', (d) ->
					if d.opaque then 1 else addClassSpec.OPACITY
				# .call @cola.drag
				.on 'click', @onNodeClick
				.on 'mousedown', onMouseDown

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
					# @color i
					groupSpec.STYLE.FILL
			.call @cola.drag
		group.exit().remove()

		group

	updateLinks: (selection, data) =>
		link = selection.data data
		link.enter()
			.insert 'line', '.link'
				.attr 'class', 'cola link'
				.style 'opacity', (d) ->
					if d.opaque then 1 else 0
		link.exit().remove()

		link

	onNodeClick: =>
		console.log 'click'
		return if d3.event.defaultPrevented # default is prevented on drag
		
		targetNode = d3.event.target
		datum = targetNode.__data__ 
		while targetNode.className.animVal isnt 'node-cont'
			targetNode = targetNode.parentNode

		switch datum.type
			when classSpec.TYPE

				
				# only one rect in group
				for child in targetNode.children
					if child.nodeName is 'rect'
						targetNode = child

				# set previously clicked node back to default color
				if @clickedNode?
					@clickedNode.setAttribute('style', @clickedNode.oldStyle)
				
				@clickedNode = targetNode
				oldStyle = targetNode.getAttribute('style')
				@clickedNode.oldStyle = oldStyle
				
				style = "stroke: #{classSpec.STYLE.SELECTED.BORDER.COLOR}; "
				style += "stroke-width: #{classSpec.STYLE.SELECTED.BORDER.WIDTH}"
				if oldStyle.indexOf('stroke') isnt -1
					newStyle = oldStyle.replace /stroke: rgb\(.*\); stroke-width: rgb\(.*\)/, style
				else
					newStyle = oldStyle + "; #{style}"

				targetNode.setAttribute('style', newStyle)

			when addClassSpec.TYPE
				addClass = (classCode) =>
					className = @adjList[classCode].name

					nodeData =
						className: className
						semester: datum.parent.gid # parent group
						nid: classCode
						type: classSpec.TYPE
						width: classSpec.WIDTH
						height: classSpec.HEIGHT

					@nodeCount += 1

					optionsData = []
					for optionName in @adjList[classCode].prereqs
						optionsData.push
							className: @adjList[optionName].name
							nid: optionName
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

				# stop simulation for a moment
				@cola.stop()
				# disable zooming while entering class
				@zoomDisabled = true
				@oldTransform = @svg.attr 'transform' # used in zoom

				showInput = =>
					# selected class name
					className = null
					input = $('#class-select', @graphElement)
					input.show()
					input.autocomplete {
						source: ({code: key, label:"(#{key}) #{obj.name}"} for key,obj of @adjList)
						autoFocus: true
						select: (e, ui) =>
							className = ui.item.code
							input.val(ui.item.label)
							input.data('code', ui.item.code) # not the idiomatic way to get data
							
							addClass className

							@zoomDisabled = undefined
							@svg.transition()
								.attr('transform', @oldTransform)
							input.hide()
							input.val('')
							false
					}
					input.keyup (e) =>
						if e.keyCode is 27
							@zoomDisabled = undefined
							@svg.transition()
								.attr('transform', @oldTransform)
							input.hide()
					input.focus()

					liveDatum = @nodeIDMap[datum.nid]
					@refPoint.x = liveDatum.x
					@refPoint.y = liveDatum.y
					# convert to global screen coordinates
					{x,y} = @refPoint.matrixTransform @svg[0][0].getScreenCTM()
					input.css 'left', "#{x-addClassSpec.WIDTH/2+2*@pad + 25}px" # using hackish offsets
					input.css 'top', "#{y-addClassSpec.HEIGHT/2+2*@pad - 5}px"
					input.css 'width', "#{liveDatum.width*@defaultScale}"

				@svg.transition()
					.attr('transform', "scale(#{@defaultScale})")
					.each('end', showInput)


	moveNode: =>
		# update constraints for a semester
		updateConstraints = (semesterID, modifyConstraint) =>
			newConstraints = []
			for constraint in @cola.constraints()
				if constraint.type is 'alignment'
					newConstraint = 
						axis: constraint.axis
						group: constraint.group
						type: constraint.type

					if constraint.group is semesterID
						newConstraint.offsets = modifyConstraint constraint.offsets
					else
						newConstraint.offsets = constraint.offsets
				else
					newConstraint =
						axis: constraint.axis
						left: constraint.left
						right: constraint.right
						gap: constraint.gap

				newConstraints.push newConstraint
			newConstraints

		return if !@clickedNode?
		clickedNode = @nodeIDMap[@clickedNode.__data__.nid] # clicked node is stored as DOM element
		clickedNodeIndex = clickedNode.index
		clickedSemester = clickedNode.parent

		map = {}
		# make a map of index -> offset, get index of clickedNode's offset object
		for constraint in @cola.constraints()
			if constraint.type is 'alignment' and constraint.group is clickedSemester.gid
				for index, offset of constraint.offsets
					map[index] = offset
					if clickedNodeIndex is offset.node
						saveIndex = parseInt(index)
		
		directionals = [LEFT, UP, RIGHT, DOWN] = [37..40]
		key 	= d3.event.keyCode

		if key in directionals
			d3.event.preventDefault()

			# INTRA-GROUP MOVEMENT
			if key in [UP, DOWN]
				# move up or down
				moveOffset = if key is DOWN then 1 else -1

				swapIndex = saveIndex+moveOffset
				maxIndex = (_ for _ of map).length
				# so long as the index of the swapping node is in bounds...
				if 0<swapIndex and swapIndex<maxIndex
					# perform swap
					[map[saveIndex],map[saveIndex+moveOffset]] = [map[saveIndex+moveOffset],map[saveIndex]]

					# graph the relevant live node objects for updating their positions
					for node in @cola.nodes()
						if node.index is clickedNodeIndex
							node1 = node
						if node.index is map[saveIndex].node # since i switched them
							node2 = node
					
					# swap their positions
					[node1.x, node2.x] = [node2.x, node2.x]
					[node1.y, node2.y] = [node2.y, node2.y]

					newConstraints = updateConstraints clickedSemester.gid, (offsets) =>
						(offset for _, offset of map)

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

	# for debugging
	stripRefs: (graph) ->
		# for node in graph.nodes
		nodes = []
		for node in graph.nodes
			newNode = {}
			for key,value of node
				unless key in ['bounds','parent', 'variable', 'index']
					newNode[key] = value
			nodes.push newNode

		groups = []
		for group in graph.groups
			leaves = []
			for leaf in group.leaves
				leaves.push(if typeof(leaf) is 'number' then leaf else leaf.index)

			groups.push
				id: group.id
				leaves: leaves

		nodes: nodes
		groups: groups
		links: graph.links
		constraints: graph.constraints

module.exports = 
	Graph: Graph