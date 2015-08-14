###
ISSUES
	- think of changing Node class into Tree class, where the old
		Tree class would be called Root and it extends the Tree class.
		That way, every "node" is just an instance of a tree, and we have one
		root node

	- consider outsourcing showDialog so that it doesn't force a rerender of <App>

	- use flux to fix this bullshit event listening interweave
###

# globals
i = 0
diagonal = d3.svg
			 .diagonal()
 			 .projection (d) -> [d.y, d.x]

###
@props:
	nodeId
	margin:
	coords:
		x:
		y:
	_showDialog
	_delete
###
class Dialog extends React.Component
	id: 'dialog-box'
	width: 100
	height: 30

	constructor: (props) ->
		super props
	
	# continuous showing of dialog, even when mouse has left node area
	onMouseEvent: (e) =>
		@props._showDialog e.type is 'mouseenter', {
				coords: @props.coords
				nodeId: @props.nodeId
		}

	handleClick: (e) =>
		console.log e.target.text # check if delete
		@props._delete(@props.nodeId)

	render: ->
		console.log @props
		dialogStyle =
			width: @width
			height: @height
			position: 'absolute'
			left: "#{@props.coords.y+@props.margin.left-(@width/2)}px" # move the dialog to the invoking node
			top: "#{@props.coords.x+@props.margin.top-30}px"
		
		`<div id={this.id}
			  style={dialogStyle}
			  onMouseEnter={this.onMouseEvent}
			  onMouseLeave={this.onMouseEvent}>
			  <a onClick={this.handleClick}
			  	 href="#">test</a>
		</div>`
###
@props:
	id:
	coords:
		x
		y
	gNode:
		className: 
		transform: 
	textElement:
		x: 
		dy: 
		anchor: 
		text: 
	parent: 
	children: 
	links: 
	depth: 
	_delete: <Tree> function used to delete node
	_showDialog: <App> function used to toggle the node dialog
###
class Node extends React.Component
	radius: 13
	className: 'node-circle'

	constructor: (props) ->
		super props
		@state =
			children: @props.children
			links: @props.links
			hideChildren: false
			parent: @props.parent

	onMouseEvent: (e) =>
		@props._showDialog e.type is 'mouseenter', {
				coords: @props.coords
				nodeId: @props.id
		}

	handleClick: (e) => # honor context in which this was defined
		console.log 'named of clickee', @props.textElement.text
		@setState hideChildren : !@state.hideChildren #super's method

	render: ->
		circleStyle =
			fill: "rgb(255,255,255)"
		textStyle =
			fillOpacity: "1"

		# STATIC PROPS COMPU
		translation = "translate(#{@props.coords.y}, #{@props.coords.x})"

		renderLinks = []
		renderChildren = []
		if @state.children? and !@state.hideChildren # render only if node has children
			children = (child for child in @state.children when child.depth is @props.depth)
			for child in children
				childProps =
					id: child.id
					coords:
						x: child.x
						y: child.y
					gNode:
						className: 'node'
					textElement:
						x: '13'
						dy: '0.35em'
						anchor: "start"
						text: child.name
					parent: if child.parent is "null" then null else child.parent
					children: child.children ? null # children if exists, null if not
					links: child.links
					depth: @props.depth+1
					_delete: @props._delete
					_showDialog: @props._showDialog

				++Tree.nodeCount

				renderChildren.push `<Node {...childProps} key={child.id}/>`

				if @state.links.outof?
					for link in @state.links.outof
						linkProps =
							className: 'link'
							d: diagonal link

						renderLinks.push `<Link {...linkProps} key={Tree.linkCount}/>`

						++Tree.linkCount

		`<g>
			{renderLinks}
			<g  onClick={this.handleClick}
				id={this.props.id}
				className={this.props.gNode.className}
				transform={translation}>

				{/* MAIN NODE */}
				<circle r={this.radius}
						style={circleStyle}
						className={this.className}
						onMouseEnter={this.onMouseEvent}
						onMouseLeave={this.onMouseEvent}>
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

###
@props:
	treeRecord    :
	dim			  :
	margin  	  :
	gtree 		  :
					transform: "translate(120,20)"
					class: "d3-skilltree"
	_showDialog:
###
class Tree extends React.Component
	@propTypes:
		treeRecord: React.PropTypes.array
		nodeCount: React.PropTypes.number

	@nodeCount: 0
	@linkCount: 0
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

		# Normalize for fixed-depth and set ids
		nodes.forEach (node, index) -> 
			node.y = node.depth * 180
			node.id = index
		links.forEach (link, index) ->
			link.id = index

		# initialize state
		@state =
			tree:
				nodes: nodes
				links: links
			dialogState:
				show: false
				coords:
					x: 0
					y: 0
				id: -1

	# exposed to instances
	@getTreeState: ->
	 	@state

	delete: (nodeId) =>
		node = @state.tree.nodes[nodeId]
		parent = node.parent
		parentLink = parent.links
		console.log 'nodes', @state.tree.nodes[2..]
		sel = d3.select('#skilltree-canvas').selectAll('g.node')

		console.log 'sel1', sel[0]
		sel[0].sort (a,b) ->
			Number(a.id)-Number(b.id)

		res = sel.data [1,2]
		res.enter().append('g')
		console.log 'res', res.exit().remove()

	# COMPONENT LIFECYCLE
	# ===================
	componentDidMount: ->
		console.log 'mounted'
		console.log @state

	componentDidUpdate: ->
		console.log 'updated'

	componentWillUnmount: ->
		console.log 'will unmount'

	# ===================

	utils:
		deleteNode: (id) =>
			console.log 'delete requested', id


	handleClick: (thing) => # honor context in which this was defined
		console.log 'clicked'
		console.log 'heres the thing', thing

	showDialog: (show, nodeData) =>
		console.log 'still calling showDialog', nodeData
		@setState dialogState : {show: show, coords: nodeData.coords, id: nodeData.nodeId}

	render: ->
		# STATIC PROPS COMPU
		#=========================
		# calculate window dimensions
		margin = this.props.margin
		{width, height} = this.props.dim
		winWidth = width+margin.right+margin.left
		winHeight = height+margin.top+margin.bottom

		# STATE-BASED COMPU
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

		console.log nodes

		# todo: check for children, just to cover bases
		renderNodes = []
		for node in nodes
			nodeProps =
				id: node.id
				coords:
					x: node.x
					y: node.y
				gNode:
					className: 'node'
				textElement:
					x: '13'
					dy: '0.35em'
					anchor: "start"
					text: node.name
				parent: if node.parent is "null" then null else node.parent
				children: node.children ? null # children if exists, null if not
				links: node.links
				depth: @depth+1
				_delete: @delete
				_showDialog: @showDialog

			++Tree.nodeCount
				

			renderNodes.push `<Node {...nodeProps} key={node.id}/>`

		# setup dialog
		dialogJSX = `<Dialog 
						nodeId={this.state.dialogState.id}
						coords={this.state.dialogState.coords}
						margin={this.props.margin}
						_showDialog={this.showDialog}
						_delete={this.delete}/>`
		dialog = if @state.dialogState.show then [dialogJSX] else [] 

		`<div className="Skilltree">
			{dialog}
			<svg id="skilltree-canvas"
				 width={winWidth}
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
			dialogState:
				show: false
				coords:
					x: 0
					y: 0
				id: -1

	showDialog: (show, nodeData) =>
		@setState dialogState : {show: show, coords: nodeData.coords, id: nodeData.nodeId}

	render: ->
		dialogProps = null
		dialogJSX = `<Dialog 
						nodeId={this.state.dialogState.id}
						coords={this.state.dialogState.coords}
						margin={this.props.margin}
						_showDialog={this.showDialog}/>`
		dialog = if @state.dialogState.show then [dialogJSX] else [] 

		`<div className="App">
			{dialog}
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