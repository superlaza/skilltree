###
ISSUES
	- think of changing Node class into Tree class, where the old
		Tree class would be called Root and it extends the Tree class.
		That way, every "node" is just an instance of a tree, and we have one
		root node

	- apparently, NO CALLING this.state DIRECTLY! FIX IT
###

# globals
i = 0
diagonal = d3.svg
			 .diagonal()
 			 .projection (d) -> [d.y, d.x]

class Node extends React.Component
	constructor: (props) ->
		super props
		@state =
			children: @props.children
			links: @props.links
			hideChildren: false
			parent: @props.parent

	handleClick: (e) => # honor context in which this was defined
		console.log 'named of clickee', @props.textElement.text
		@setState hideChildren : !@state.hideChildren #super's method

	render: ->
		circleStyle =
			fill: "rgb(255,255,255)"
		textStyle =
			fillOpacity: "1"


		# incoming links
		if @state.links.into?
			renderLinks = []
			for link in @state.links.into
				console.log 'link', link
				linkProps =
					className: 'link'
					d: diagonal link

				renderLinks.push `<Link {...linkProps} key={this.state.links.into.indexOf(link)}/>`


		renderChildren = []
		if @state.children? and !@state.hideChildren # render only if node has children
			children = (child for child in @state.children when child.depth is @props.depth)
			for child in children
				childProps =
					gNode:
						className: 'node'
						transform: "translate(#{child.y}, #{child.x})"
					textElement:
						x: '13'
						dy: '0.35em'
						anchor: "start"
						text: child.name
					parent: if child.parent is "null" then null else child.parent
					children: child.children ? null # children if exists, null if not
					links: child.links
					depth: @props.depth+1

				renderChildren.push `<Node {...childProps} key={children.indexOf(child)}/>`

				if @state.links.outof?
					for link in @state.links.outof
						console.log 'outlink', link
						linkProps =
							className: 'link'
							d: diagonal link

						renderLinks.push `<Link {...linkProps} key={this.state.links.outof.indexOf(link)}/>`
		`<g>
			{renderLinks}
			<g onClick={this.handleClick} className={this.props.gNode.className}
				transform={this.props.gNode.transform}>
				<circle r="10"
						style={circleStyle}>
				</circle>
				<text x={this.props.textElement.x}
					  dy={this.props.textElement.dy}
					  textAnchor={this.props.textElement.anchor}
					  style={textStyle}>{this.props.textElement.text}
				</text>
			</g>
			{renderChildren}
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
	@propTypes:
		treeRecord: React.PropTypes.array
		nodeCount: React.PropTypes.number

	nodeCount: 0
	depth: 0

	constructor: (props) ->
		super props # assign instance props

		# COMPUTE TREE STATE
		# ==================
		# Compute the new tree layout
		{width, height} = @props.dim
		tree = d3.layout
			 	.tree()
				.size [height, width]

		nodes = tree.nodes(@props.treeRecord[0]).reverse()
		links = tree.links(nodes)

		# Normalize for fixed-depth.
		nodes.forEach (d) -> d.y = d.depth * 180

		@state =
			tree:
				nodes: nodes
				links: links

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
		{nodes, links} = @state.tree

		# this might be an overly expensive filter, check here first for perf bottlenecks
		nodes = (node for node in nodes when node.depth is @depth)

		# should be done by popping from links list
		attachLinks = (nodeList)->
			for node in nodeList
				node.links = 
					into: (link for link in links when link.target is node)
					outof: (link for link in links when link.source is node)
				attachLinks node.children if node.children?

		attachLinks nodes
		console.log 'new nodes', nodes

		# todo: check for children, just to cover bases
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
				parent: if node.parent is "null" then null else node.parent
				children: node.children ? null # children if exists, null if not
				links: node.links
				depth: @depth+1
				

			renderNodes.push `<Node {...nodeProps} key={nodes.indexOf(node)}/>`

		`<div className="Skilltree">
			<svg width={winWidth}
				 height={winHeight}>
				 <g transform={this.props.gtree.transform}
				 	className={this.props.gtree.class}>
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