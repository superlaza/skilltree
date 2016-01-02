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
		@clickedNodeID = null

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
		.attr 'x1', (d) -> d.source.x
		.attr 'y1', (d) -> d.source.y
		.attr 'x2', (d) -> d.target.x
		.attr 'y2', (d) -> d.target.y

		@node
		.attr 'transform', (d) =>
			x = d.x - (d.width/2)
			y = d.y - (d.height / 2) + @pad
			"translate(#{x}, #{y})"
		
		if @opacityChanged
			@link.transition()
				.delay (d) ->
					console.log 'umm..', d.opaque
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

	update: (graph = @graph, up) =>
		# if @clickedNodeID?
		# 	console.log 'fucking hell', @clickedNodeID
		# 	for node in @graph.nodes
		# 		if node.nid is @clickedNodeID
		# 			@clickedNode = node

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

		# console.log 'wtf cola'
		# for cons in @cola.nodes()
		# 	console.log cons.name
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

		node = selection.data data,
					(d) ->
						d.nid
		node
			.call @cola.drag
			.on 'click', @onNodeClick

		# when heights are changed for text wrapping, this
		# ensures that those heights get re-registered to the model
		node.selectAll('.node-text')
			.call (text, cola = @cola) =>
				nodeIndexMap = {}
				for index, _node of cola.nodes()
					nodeIndexMap[_node.nid] = parseInt index
				text.each () ->
					datum = this.__data__
					nodes = cola.nodes()
					# this is data from the pre-existing render being added to model
					nodes[nodeIndexMap[datum.nid]].height = datum.height
					return
				return


		enter = node.enter()
			.insert 'g', '.node-cont'
				.attr 'class', 'node-cont'
				.style 'opacity', (d) ->
					if d.opaque then 1 else addClassSpec.OPACITY
				.call @cola.drag
				.on 'click', @onNodeClick
				.on 'mouseenter', setVisibility
				.on 'mouseleave', setVisibility
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
				.attr 'class', 'cola label'
				.call @cola.drag
				.append 'text'
					.attr 'class', 'node-text'
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
					parent = targetNode
					while parent.className.animVal isnt 'node-cont'
						parent = parent.parentNode
					datum = parent.__data__
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
		return if d3.event.defaultPrevented # default is prevented on drag
		
		targetNode = d3.event.target
		datum = targetNode.__data__ 

		switch datum.type
			when classSpec.TYPE

				parent = targetNode
				while parent.className.animVal isnt 'node-cont'
					parent = parent.parentNode
				
				# only one rect in group
				for child in parent.children
					if child.nodeName is 'rect'
						targetNode = child

				# set previously clicked node back to default color
				if @clickedNode?
					console.log 'iold', @clickedNode.oldStyle
					@clickedNode.setAttribute('style', @clickedNode.oldStyle)
				
				@clickedNode = targetNode
				oldStyle = targetNode.getAttribute('style')
				@clickedNode.oldStyle = oldStyle
				
				style = "stroke: #{classSpec.STYLE.SELECTED.BORDER.COLOR}; "
				style += "stroke-width: #{classSpec.STYLE.SELECTED.BORDER.WIDTH}"
				if oldStyle.indexOf('stroke') isnt -1
					oldStyle = oldStyle.replace /stroke: rgb\(.*\); stroke-width: rgb\(.*\)/, style
				else
					oldStyle += "; #{style}"

				targetNode.setAttribute('style', oldStyle)

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
				if constraint.type?
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
		console.log 'which node clicked', @clickedNode.nid
		clickedNode = @clickedNode.__data__ # clicked node is stored as DOM element
		clickedSemester = clickedNode.parent

		map = {}
		# make a map of index -> offset, get index of clickedNode's offset object
		for constraint in @cola.constraints()
			if constraint.type? and constraint.group is clickedSemester.gid
				for index, offset of constraint.offsets
					map[index] = offset
					if clickedNode.index is offset.node
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
						if node.index is clickedNode.index
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

			if key in [LEFT, RIGHT]
				semesters = @cola.groups()
				for index, semester of semesters
					if semester.gid is clickedSemester.gid
						clickedSemesterIndex = parseInt index

				moveOffset = if key is LEFT then -1 else 1

				# todo: handle empty semeseters case
				newSemesterIndex = clickedSemesterIndex+moveOffset
				newSemester = semesters[newSemesterIndex]
				# if 0 <= newSemesterIndex and newSemesterIndex < semesters.length
					# @dispatch actionDeleteClass(
					# 		clickedNode.nid,
					# 		@getPositiondata @cola.nodes(), @cola.groups()
					# )

					# className = clickedNode.name

					# nodeData =
					# 	className: className
					# 	semester: newSemester.gid # parent group
					# 	nid: clickedNode.nid
					# 	type: classSpec.TYPE
					# 	width: classSpec.WIDTH
					# 	height: classSpec.HEIGHT
					# @nodeCount += 1

					# action = actionAddClass(
					# 		nodeData,
					# 		[],
					# 		@getPositiondata @cola.nodes(), @cola.groups()
					# 	)
					# @dispatch action

					# console.log 'id', clickedNode.nid
					# @clickedNodeID = @clickedNode.nid
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