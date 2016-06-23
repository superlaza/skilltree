React = require 'react'

Course = require 'Course'

Plan = React.createClass
	componentDidMount: ->

	componentDidUpdate: ->
	

	render: ->
		
		# <button onClick={addSemester}> add semester</button>
		<div class='semester'>
			
		</div>


mapStateToProps = (state) ->
	state: state.toJS()

Plan_ = connect(mapStateToProps)(Plan)

module.exports =
	Plan: 	Plan
	Plan_: 	Plan_