{classSpec, addClassSpec, constraintSpec} = require '../constants/Specs.coffee'

POS2State = (planOfStudy, graphData) ->
	initialState = {
		nodes:[]
		links:[]
		groups:[]
		constraints: []
	}

	nodeCount = -1 
	for semester in planOfStudy
		group = []
		groupIndex = initialState.groups.length

		btnAddClass = 
			name: addClassSpec.TEXT
			nid: "#{addClassSpec.TYPE}#{groupIndex}"
			opaque: true
			type: addClassSpec.TYPE
			width: addClassSpec.WIDTH
			height: addClassSpec.HEIGHT
			x: 50 + constraintSpec.displacement.GAP*groupIndex
			y: 80
		nodeCount -= 1

		# alignment and displacement constraints are per group
		alignmentConstraint =
			type: 'alignment'
			axis: 'x'
			offsets: []
			group: groupIndex

		# only applicable on > 1 semesters
		if initialState.groups.length > 0
			displacementConstraint  =
				axis: 'x'
				_type: 'displacement' # can't override type attr
				left: groupAnchorIndex # old anchor index
				right: initialState.nodes.length # new anchor index
				gap: constraintSpec.displacement.GAP

			# link addclassbuttons to enforce a max separation constraint
			initialState.links.push
				source: groupAnchorIndex
				target: initialState.nodes.length
				opaque: false

		groupAnchorIndex = initialState.nodes.length
		group.push groupAnchorIndex
		alignmentConstraint.offsets.push {
			node: groupAnchorIndex
			offset: constraintSpec.alignment.OFFSET.x
		}
		initialState.nodes.push btnAddClass

		for course in semester.courses
			# an array signifies a list of non-class placeholders
			if Array.isArray course
				for placeholder in course
					newNode =
						opaque: true
						type: classSpec.TYPE
						width: classSpec.WIDTH
						height: classSpec.HEIGHT
						status: classSpec.status.ENROLLED
					newNode.name = placeholder
					newNode.nid = "placeholder#{nodeCount}"
					nodeCount -= 1

					newNodeIndex = initialState.nodes.length
					group.push newNodeIndex
					alignmentConstraint.offsets.push {
						node: newNodeIndex
						offset: constraintSpec.alignment.OFFSET.x
					}
					# initialState.constraints.unshift
					# 	axis: 'y'
					# 	_type: 'displacement'
					# 	left: groupAnchorIndex # root node of group
					# 	right: newNodeIndex# new anchor index
					# 	gap: 20
					# 	equality: 'true'

					initialState.nodes.push newNode

			else
				newNode =
					opaque: true
					type: classSpec.TYPE
					width: classSpec.WIDTH
					height: classSpec.HEIGHT
					status: classSpec.status.ENROLLED
				if course of graphData
					newNode.name = graphData[course].name
					newNode.nid = course
				else
					console.log "#{course} is not in graphData"
					newNode.name = course
					newNode.nid = course

				newNodeIndex = initialState.nodes.length
				group.push newNodeIndex
				alignmentConstraint.offsets.push {
					node: newNodeIndex
					offset: constraintSpec.alignment.OFFSET.x
				}
				# initialState.constraints.unshift
				# 	axis: 'y'
				# 	_type: 'displacement'
				# 	left: groupAnchorIndex # root node of group
				# 	right: newNodeIndex# new anchor index
				# 	gap: 20
				# 	equality: 'true'
				
				initialState.nodes.push newNode

		nodeIndexMap = {}
		for index, node of initialState.nodes
			nodeIndexMap[node.nid] = parseInt index
		for index, node of initialState.nodes
			if node.nid of graphData
				for option in graphData[node.nid].prereqs
					initialState.links.push {
						source: parseInt index
						target: nodeIndexMap[option]
						opaque: false
					}

		initialState.groups.push {
			'leaves': group
			'gid': groupIndex
		}

		if displacementConstraint?
			initialState.constraints.push displacementConstraint

		initialState.constraints.unshift alignmentConstraint

	initialState

module.exports = POS2State