
i = 0

class Node extends React.Component
	constructor: (props) ->
		super props
		@state =
			children: @props.children

	render: ->
		circleStyle =
			fill: "rgb(255,255,255)"
		textStyle =
			fillOpacity: "1"

		`<g className={this.props.gNode.className}
			transform={this.props.gNode.transform}
			onClick={this.props.onClick}>
			<circle r="10"
					style={circleStyle}>
			</circle>
			<text x={this.props.textElement.x}
				  dy={this.props.textElement.dy}
				  textAnchor={this.props.textElement.anchor}
				  style={textStyle}>{this.props.textElement.text}
			</text>
		</g>
		`

class Link extends React.Component
	constructor: (props) ->
		super props

	render: ->
		`<path className={this.props.className}
			   d={this.props.d}></path>
		`
class Tree extends React.Component
	@propTypes =
		treeRecord: React.PropTypes.array
		nodeCount: React.PropTypes.number
	@defaultProps =
		nodeCount: 0

	constructor: (props) ->
		super props # assign instance props
		@state =
			treeRecord: props.treeRecord

	# exposed to instances
	getTreeState: ->
	 	@state

	# COMPONENT LIFECYCLE
	# ===================
	componentDidMount: ->
		console.log 'mounted'

		# TreeElement = React.findDOMNode this

		# createData =
		# 	treeRecord: @getTreeState().treeRecord
		# 	dim: @props.dim
		# 	margin: @props.margin

		# TreeRender.create TreeElement, createData

	componentDidUpdate: ->
		console.log 'updated'
	# el = this.getDOMNode()
	# TreeRender.update(el, this.getChartState())

	componentWillUnmount: ->
		console.log 'will unmount'
		# el = this.getDOMNode()
		# TreeRender.destroy(el)
	# ===================

	handleClick: (thing) => # honor context in which this was defined
		console.log 'clicked'
		console.log 'heres the thing', thing

	render: ->
		# STATIC PROPS COMPUTATION
		#=========================
		# calculate window dimensions
		margin = this.props.margin
		{width, height} = this.props.dim
		winWidth = width+margin.right+margin.left
		winHeight = height+margin.top+margin.bottom

		# STATE-BASED MANIPULATIONS
		#=========================
		tree = d3.layout
			 	.tree()
				.size [height, width]
		
		diagonal = d3.svg
					 .diagonal()
		 			 .projection (d) -> [d.y, d.x]

		# Compute the new tree layout.
		nodes = tree.nodes(@state.treeRecord[0]).reverse()
		links = tree.links(nodes)

		# Normalize for fixed-depth.
		nodes.forEach (d) -> d.y = d.depth * 180

		console.log 'nodes', nodes
		renderNodes = []
		for node in nodes
			nodeProps =
				gNode:
					className: 'node'
					transform: "translate(#{node.y}, #{node.x})"
				textElement:
					x: '13'
					dy: '0.35em'
					anchor: "start"
					text: node.name
				children: node.children ? null # children if exists, null if not
				onClick: @handleClick

			renderNodes.push `<Node {...nodeProps} key={nodes.indexOf(node)}/>`

		renderLinks = []
		for link in links
			linkProps =
				className: 'link'
				d: diagonal link

			renderLinks.push `<Link {...linkProps} key={links.indexOf(link)}/>`
			console.log 'link something', diagonal(link)

		console.log 'links', links

		`<div className="Skilltree">
			<svg width={winWidth}
				 height={winHeight}>
				 <g transform={this.props.gtree.transform}
				 	className={this.props.gtree.class}>
				 	{renderLinks}
				 	{renderNodes}
				 </g>
			</svg>
		</div>
		`

class App extends React.Component
	constructor: (props) ->
		super props
		@state =
			treeRecord: props.treeRecord

	render: () ->
		`<div className="App">
	        <Tree
	        	{...this.props}/>
	    </div>`

treeData = [
    "name": "Top Level"
    "parent": "null"
    "test": 'whatever'
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
dim =
	width: 600-margin.right-margin.left
	height: 500-margin.top-margin.bottom

treeProps = 
	treeRecord    : treeData
	dim			  : dim
	margin  	  : margin
	gtree 		  :
					transform: "translate(120,20)"
					class: "d3-skilltree"

React.render `<App {...treeProps}/>`, document.getElementById 'react'