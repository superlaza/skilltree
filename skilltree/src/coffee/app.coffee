class TreeRender
	@create = (el, props, state) ->
		# the containing svg of the tree
		console.log 'props', props
		{width, height} = props.dims
		console.log height
		margin = props.margin
		svg = d3.select(el)
				.append("svg")
		 		.attr("width", width+margin.right+margin.left)
		 		.attr("height", height+margin.top+margin.bottom)
		 		.append("g")
		 		.attr("transform", "translate(#{margin.left},#{margin.top})")
		 		.attr("class", "d3-skilltree")
		
		@update svg.node(), state

	@update = (el, state) ->
		# Re-compute the scales, and render the data points
		# scales = @_scales(el, state.domain)
		@draw el, state.data

	@destroy = (el) ->
		# Any clean-up would go here
		# in this example there is nothing to do

	@draw = (el, data) ->
		console.log 'drawing points'

		tree = d3.layout
				 .tree()
		 		 .size [height, width]

		# handles drawing of links
		diagonal = d3.svg
					 .diagonal()
		 			 .projection (d) -> [d.y, d.x]

		# Compute the new tree layout.
		nodes = tree.nodes(data[0]).reverse()
		links = tree.links(nodes)

		# Normalize for fixed-depth.
		nodes.forEach (d) -> d.y = d.depth * 180

		svg = d3.select(el)
		node = svg.selectAll("g.node")
				 .data(nodes, (d) -> d.id)

		nodeEnter = node.enter()
					    .append("g")
					    .attr("class", "node")
					    .attr("transform", (d) -> "translate(#{d.y},#{d.x})")

		nodeEnter.append("circle")
				 .attr("r", 10)
				 .style("fill", "#fff")

		nodeEnter.append("text")
			     .attr("x", (d) -> if d.children? then -70 else 20)
			     .attr("dy", ".35em")
			     .attr("text-anchor", (d) -> if d.children? then (if d._children? then 'end' else 'start') else null)
			     .text( (d) -> d.name)
			     .style("fill-opacity", 1);

		# Declare the links
		link = svg.selectAll("path.link")
				  .data(links, (d) -> d.target.id)

		# Enter the links.
		link.enter()
			.insert("path", "g")
			.attr("class", "link")
			.attr("d", diagonal)
		# g = d3.select(el).selectAll('.d3-points')
		# point = g.selectAll('.d3-point').data(data, (d) -> d.id)
		# # ENTER
		# point.enter()
		# 	 .append('circle')
		# 	 .attr('class', 'd3-point')
		# ENTER & UPDATE
		# point.attr('cx', (d) -> scales.x d.x)
		# 	 .attr('cy', (d) -> scales.y d.y)
		# 	 .attr('r', (d) -> scales.z d.z)
		# EXIT
		# point.exit().remove()


class Tree extends React.Component
	@propTypes =
		data: React.PropTypes.array
		nodeCount: React.PropTypes.number
	@defaultProps =
		nodeCount: 0

	componentDidMount: ->
		console.log 'mounted', @getTreeState()
		el = React.findDOMNode this
		TreeRender.create el, @props, @getTreeState()

	componentDidUpdate: ->
		console.log 'updated'
	# el = this.getDOMNode()
	# TreeRender.update(el, this.getChartState())

	getTreeState: ->
	 	data: this.props.data

	componentWillUnmount: ->
		console.log 'will unmount'
	# el = this.getDOMNode()
	# TreeRender.destroy(el)

	render: ->
		return  `<div className={this.props.className}></div>`

treeData = [
    "name": "Top Level"
    "parent": "null"
    "children": [
        "name": "Level 2: A"
        "parent": "Top Level"
        "children": [
            "name": "Son of A"
            "parent": "Level 2: A"
          ,
            "name": "Daughter of A"
            "parent": "Level 2: A"
        ]
      ,
        "name": "Level 2: B"
        "parent": "Top Level"
    ]
]

margin =
	top: 20
	right: 120
	bottom: 20
	left: 120
dims =
	width: 960 - margin.right - margin.left
	height: 500 - margin.top - margin.bottom

class App extends React.Component
	constructor: (props) ->
		super props
		@state =
			data: props.data
			dims: props.dims

	render: () ->
		`<div className="App">
	        <Tree {...this.props}/>
	    </div>`

appProps =
	data: treeData
	dims: dims
	margin: margin

React.render `<App {...appProps}/>`, document.getElementById 'react'