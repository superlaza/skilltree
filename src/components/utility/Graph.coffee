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
	constructor: (@graphElement, @graph, @dispatch, @adjList) ->
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


		# === SETUP CONTAINING SVG ELEMENT === #
		# by the way, a double click zooms...
		zoomed = => # there's a zoom pan bug when you drag graph, event picks up from point where drag started
			if d3.event.sourceEvent?.type is 'wheel'
				@svg.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
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
			.groups(graph.groups)
			.constraints(graph.constraints)

		@cola.on 'tick', @tick

		@nodeIDMap = {} # this isn't implemented everywhere yet
		for index, node of @cola.nodes()
			@nodeIDMap[node.nid] = node
		
		console.log 'cliekcen onode', @clickedNode
		@group = @updateGroups @group, @cola.groups()
		@link = @updateLinks @link, @cola.links()
		@node = @updateNodes @node, @cola.nodes()
		
		@cola.start()

	updateNodes: (selection, data) =>
		wrap = (text, width, cola) =>
			text.each () ->
				text = d3.select(this)
				datum = this.__data__
				words = text.text().split(/\s+/).reverse()
				word = undefined
				line = []
				lineNumber = 0
				# lineHeight = 1.1 # measured in ems
				lineHeight = 18
				y = text.attr('y')
				tspan = text.text(null)
							.append('tspan')
							.attr 'class', 'class-node-tspan'
							.attr('x', 0)
							.attr('y', 0)
							# .attr('dy', dy + 'em')
				while word = words.pop()
					line.push word
					tspan.text line.join(' ')
					if tspan.node().getComputedTextLength() > width
						line.pop()
						tspan.text line.join(' ')
						line = [ word ]
						tspan = text.append('tspan')
									.attr 'class', 'class-node-tspan'
									.attr('x', 0)
									.attr('y', 0)
									# .attr('dy', ++lineNumber * lineHeight + 'em')
									.attr('dy', ++lineNumber * lineHeight + 'px')
									.text(word)

				nodes = cola.nodes()
				# change in simulation
				if datum.index?
					height = nodes[datum.index].height
					nodes[datum.index].height += lineNumber*lineHeight
				else
					for _node in nodes # can't use var name `node`
						if _node.nid is datum.nid
							height = _node.height
							_node.height += lineNumber*lineHeight

				# change in render
				for child in this.parentNode.parentNode.children
					if child.nodeName is 'rect'
						height = parseInt child.getAttribute('height')
						child.setAttribute 'height', "#{height+lineNumber*lineHeight}"
				
				# cola.start()
				return
		  return


		setVisibility = =>
			eventType = d3.event.type
			datum = d3.event.target.__data__

			# hide/show links on class nodes
			if datum.type is classSpec.TYPE
				neighbors = [datum.index]
				for index, link of @cola.links()
					{source, target} = link
					if source.index is datum.index or target.index is datum.index
						link.opaque = if eventType is 'mouseenter' then true else false
						if source.index is datum.index
							neighbors.push target.index
						else
							neighbors.push source.index
				# fade classes that aren't connected
				for node in @cola.nodes()
					if node.type is classSpec.TYPE and node.index not in neighbors
						node.opaque = if eventType is 'mouseenter' then false else true
				@opacityChanged = true
				@tick() # draw changes with a flag to signifiy we're changing opacity
				@opacityChanged = false
			# set visibility of delete button
			for child in d3.event.target.children
				if child.className.animVal is btnDeleteClassSpec.CLASS
					child.setAttribute('visibility', if eventType is 'mouseenter' then 'visible' else 'hidden')
					break

		moveGhostNode = (e) =>
			[oldX, oldY] = @currentPosition
			offset = 25
			inXrange = oldX-offset < e.clientX and e.clientX < oldX+offset
			inYrange = oldY-offset < e.clientY and e.clientY < oldY+offset

			# not much of a drag
			if inXrange and inYrange
				@inRange = true
				return false
			else
				@inRange = false
				@ghost.style 'opacity', 0.3
				@cola.nodes()[@moveNode.index].hidden = true # set to true a bazillion times

				@refPoint.x = e.clientX
				@refPoint.y = e.clientY
				# convert to global screen coordinates
				{x,y} = @refPoint.matrixTransform @svg[0][0].getScreenCTM().inverse()
				
				@ghost
				.attr 'x', x
				.attr 'y', y

			false

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
						d.nid
		node
			# .call @cola.drag
			.on 'click', @onNodeClick
			.on 'mousedown', onMouseDown

		# when heights are changed for text wrapping, this
		# ensures that those heights get re-registered to the model
		node.selectAll('.class-node-text')
			.call (text, cola = @cola, nmap=@nodeIDMap) =>
				text.each () ->
					datum = this.__data__
					nodes = cola.nodes()
					# this is data from the pre-existing render being added to model
					nmap[datum.nid].height = datum.height
					return
				return


		enter = node.enter()
			.insert 'g', '.node-cont'
				.attr 'class', 'node-cont'
				.style 'opacity', (d) ->
					if d.opaque then 1 else addClassSpec.OPACITY
				# .call @cola.drag
				.on 'click', @onNodeClick
				.on 'mouseenter', setVisibility
				.on 'mouseleave', setVisibility
				.on 'mousedown', onMouseDown
		enter.append 'rect'
				.attr 'class', (d) ->
					classStem = 'cola node'
					switch d.type
						when addClassSpec.TYPE
							classStem+=" #{addClassSpec.CLASS}"
						when classSpec.TYPE
							classStem+=" #{classSpec.CLASS}"
							switch d.status
								when classSpec.status.ENROLLED
									classStem+=" #{classSpec.status.ENROLLED}"
								when classSpec.status.OPTION
									classStem+=" #{classSpec.status.OPTION}"
								when classSpec.status.PREREQ
									classStem+=" #{classSpec.status.PREREQ}"
					
				.attr 'width',
					(d) =>
						if d.hidden then 0 else d.width - (2 * @pad)
				.attr 'height',
					(d) => 
						if d.hidden then 0 else d.height - (2 * @pad)
				.attr 'rx', 5
				.attr 'ry', 5
				.style 'fill', 
					(d) => 
						switch d.type
							when classSpec.TYPE
								switch d.status
									when classSpec.status.PREREQ
										return 'rgb(255,29,25)'
							
								if d.nid.indexOf('placeholder') isnt -1
									classSpec.STYLE.PLACEHOLDER.FILL
								else
									@color @graph.groups.length

		textGroup = enter.append 'g'
				.attr 'transform', (d) ->
					"translate(#{d.width/2},#{d.height/2})"
				.attr 'class', 'cola label class-node-label'
				# .call @cola.drag
				.append 'text'
					.attr 'class', 'class-node-text'
					.style 'fill', (d) ->
						if d.nid.indexOf('placeholder') isnt -1
							'#BDBDBD'
						else
							classSpec.STYLE.PLACEHOLDER.FILL
					.text (d) =>
						d.name
						# "id: #{d.nid}, index: #{@cola.nodes().indexOf(d)}"
					.call wrap, classSpec.WIDTH, @cola

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
					targetNode = d3.event.target
					while targetNode.className.animVal isnt 'node-cont'
						targetNode = targetNode.parentNode
					datum = targetNode.__data__
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

		switch datum.type
			when classSpec.TYPE

				while targetNode.className.animVal isnt 'node-cont'
					targetNode = targetNode.parentNode
				
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

				# selected class name
				className = null
				input = @graphElement.children[0]
				input = $('#class-select', @graphElement)
				input.autocomplete {
					source: ({code: key, label:"(#{key}) #{obj.name}"} for key,obj of @adjList)
					autoFocus: true
					# focus: (e, ui) ->
					# 	console.log 'ui', ui
					# 	input.val(ui.name)
					# 	false
					select: (e, ui) =>
						className = ui.item.code
						input.val(ui.item.label)
						input.data('code', ui.item.code) # not the idiomatic way to get data
						
						addClass className
						false
				}
				input.focus()

				# input.css 'left', "#{datum.x-13}px"
				# input.css 'top', "#{datum.y+10}px"
				
				# className = window.prompt('Pick a class')
				
				# input.keypress (e) =>
				# 	if e.keyCode is 13


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