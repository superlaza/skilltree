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
		
		reqList = []
		for req, details of @props.majorData.requirements
			reqList.push(
				<div key={reqList.length}>
					{req}
				</div>
			)

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