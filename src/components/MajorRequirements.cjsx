React 					= require 'react'
{connect} 				= require 'react-redux'

MajorRequirements = React.createClass
	# componentDidMount: ->
	# 	{dispatch, state, graphData, majorData} = @props

	# 	@graph = new Graph(this.refs.graph, state, dispatch, graphData)

	# componentDidUpdate: ->
	# 	{dispatch, state, graphData} = @props
		
	# 	console.log 'newstate?', state
	# 	@graph.update(state)

	# 	window.dispatch = dispatch

	render: ->
		console.log 'reqs props', (_ for _ of @props.courses).length
		
		courseList = []
		reqList = []
		for req, details of @props.majorData.requirements
			reqSat = true
			if 'subgroups' of details
				for sub, subDetails of details.subgroups
					# remember that in GEP, some courses
					# are references to other groups,
					# prefixed with _
					if 'subgroups' of subDetails
						console.log subDetails.subgroups
					else
						for course in subDetails.required
							if Array.isArray course # this means there are options
								reqSat = reqSat and (option of @props.courses for option in course).some (v)->v
								# for option in course
								# 	console.log option, option of @props.courses
								# for option in course
								# 	courseList.push option
							else
								reqSat = reqSat and course of @props.courses
								# courseList.push course
			else
				for course in details.required
					if Array.isArray course # options
						reqSat = reqSat and (option of @props.courses for option in course).some (v)->v
						# for option in course
						# 	courseList.push option
					else
						reqSat = reqSat and course of @props.courses
						# courseList.push course

			console.log req, reqSat
			reqList.push(
				<div key={reqList.length}>
					<span style={{color: (if reqSat then 'green' else 'red'), fontSize: 'small'}}>
						{req}
					</span>
				</div>
			)

		# console.log 'hmm', @props.courses
		# for course of @props.courses
		# 	if course in courseList
		# 		console.log "#{course} in reqs"
		# 	else
		# 		console.log "#{course} NOT in reqs"

		<div id='major-requirements'
			 ref='major_requirements'>
			{reqList}
		</div>


mapStateToProps = (state) ->
	courses = {}
	for course in state.toJS().nodes
		if course.type isnt 'btnAddClass' # don't hard code! use specs
			courses[course.nid] = {
				status: course.status
				name: course.name
			}

	courses: courses

MajorRequirements_ = connect(mapStateToProps)(MajorRequirements)

module.exports =
	MajorRequirements_: MajorRequirements_ 
	MajorRequirements: MajorRequirements 