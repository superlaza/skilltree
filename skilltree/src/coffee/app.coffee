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
# debug flags
lifecycles = false


diagonal = d3.svg
			 .diagonal()
 			 .projection (d) -> [d.y, d.x]

lg = (_string...) ->
		args = arguments
		clr = args[args.length-1]
		if clr is 'blue' or clr is 'red' or clr is 'green'
			switch clr
				when 'blue'
					args[args.length-1] = 'color: #2175d9'
				when 'red'
					args[args.length-1] = 'color: #ff3232'
				when 'green'
					args[args.length-1] = 'color: #00d27f'
			args[0] = '%c '+args[0]
		console.log.apply console, (arg for index,arg of args)

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
	treeRecord    : treeData
	dim			  : dim
	margin  	  : margin
	gtree 		  :
					transform: "translate(120,20)"
					class: "d3-skilltree"
	depth 		  : 0 # initialize depth
###
class Root extends React.Component
	@propTypes:
		treeRecord: React.PropTypes.array
		nodeCount: React.PropTypes.number

	@nodeCount: 0
	@linkCount: 0

	constructor: (props) ->
		super props # assign instance props


		# initialize state
		@state =
			treeRecord: @props.treeRecord
			dialogState:
				show: false
				coords:
					x: 0
					y: 0
				id: -1

	# exposed to instances
	getTreeState: ->
	 	@state

	_delete: (nodeId) =>
		
		tree = @state.treeRecord

		findNode = (tree, id) ->
			# root node
			if tree.id == id then return tree
			# leaf node
			if !tree.children then return null
			for child in tree.children
				if child.id == id
					return child
				else
					node = findNode child, id
					if node isnt null then return node
			null

		node = findNode tree[0], nodeId

		# might be silly to lookup index when we could've pulled it from findnode
		nodeIndex = node.parent.children.indexOf(node)

		node.parent.links.outof = null # all outgoing links must be redrawn

		# remove selected node and insert its children in its placing, respecting order
		spliceArgs = [nodeIndex, 1]
		spliceArgs = spliceArgs.concat node.children if node.children?
		node.parent.children.splice.apply node.parent.children, spliceArgs

		# update state, fire re-render
		@setState {treeRecord: tree}

	# COMPONENT LIFECYCLE
	# ===================
	componentDidMount: ->
		if lifecycles
			lg 'mounted', 'green'
			console.log "\t#{@constructor.name} #{@props.id}"

	componentDidUpdate: ->
		if lifecycles
			lg 'update', 'blue'
			console.log "\t#{@constructor.name} #{@props.id}"

	componentWillUnmount: ->
		if lifecycles
			lg 'will unmount', 'red'
			console.log "\t#{@constructor.name} #{@props.id}"

	# ===================

	utils:
		deleteNode: (id) =>
			console.log 'delete requested', id


	handleClick: (thing) => # honor context in which this was defined
		console.log 'clicked'
		console.log 'heres the thing', thing

	showDialog: (show, nodeData) =>
		@setState dialogState : {show: show, coords: nodeData.coords, id: nodeData.nodeId}
	
	# given a tree (a subtree of childreen and links), build corresponding react components
	# this will be called in the context of Node and Root classes, so be mindful of using @props and @state
	_buildComponents: (tree, customProps) ->
		[nodes, links] = tree
		renderLinks = []
		renderNodes = []
		for node in nodes
			nodeProps =
				id: node.id
				name: node.name
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

			renderNodes.push `<Node {...nodeProps} {...customProps} key={node.id}/>`
			++Root.nodeCount

			if node.links?.outof?
				for link in node.links.outof
					linkProps =
						id: link.id
						className: 'link'
						d: diagonal link
						_link: link # for debuggin' only, remove

					renderLinks.push `<Link {...linkProps} key={link.id}/>`
					++Root.linkCount


		renderNodes: renderNodes
		renderLinks: renderLinks

	render: ->
		# COMPUTE TREE STATE
		# ==================
		# Compute the new tree layout
		{width, height} = @props.dim
		tree = d3.layout
			 	.tree()
				.size [height, width]

		nodes = tree.nodes(@state.treeRecord[0]).reverse()
		links = tree.links(nodes)

		# Normalize for fixed-depth and set ids
		nodes.forEach (node, index) -> 
			node.y = node.depth * 180
		links.forEach (link, index) ->
			link.id = index

		# STATIC PROPS COMPU
		#=========================
		# calculate window dimensions
		margin = @props.margin
		{width, height} = @props.dim
		winWidth = width+margin.right+margin.left
		winHeight = height+margin.top+margin.bottom

		# STATE-BASED COMPU
		#=========================

		# should be done by popping from links list
		attachLinks = (nodeList)->
			for node in nodeList
				node.links = 
					into: (link for link in links when link.target is node)
					outof: (link for link in links when link.source is node)
				if node.id is 0
					lg 'node 0 links', 'red'
					console.log node.links
				attachLinks node.children if node.children?

		attachLinks nodes


		# this might be an overly expensive filter, check here first for perf bottlenecks
		nodes = (node for node in nodes when node.depth is @props.depth)

		console.log 'nodes', nodes

		customProps =
			depth: @props.depth+1
			_delete: @_delete
		{renderNodes, renderLinks} = @_buildComponents [nodes, null], customProps

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
				 	{renderLinks}
				 	{renderNodes}
				 </g>
			</svg>
		</div>
		`
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
class Node extends Root
	radius: 13
	className: 'node-circle'

	constructor: (props) ->
		@props = props
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
		# console.log 'named of clickee', @props.textElement.text
		# @setState hideChildren : !@state.hideChildren #inherited method

		@props._delete @props.id

	delete: =>
		console.log 'node delete'
		console.log 'state check', @state
		super @props.id

	render: ->
		# exports = @_render(@props, @state)

		# static styles
		circleStyle =
			fill: "rgb(255,255,255)"
		textStyle =
			fillOpacity: "1"

		# props computations
		translation = "translate(#{@props.coords.y}, #{@props.coords.x})"

		customProps =
			depth: @props.depth+1
			_delete: @props._delete

		# state computations
		if @state.children? and !@state.hideChildren # render only if node has children
			{renderNodes, renderLinks} = @_buildComponents [@state.children, @state.links], customProps

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
			{renderNodes}
		</g>
		`
###
@props:
	id: link.id
	className: 'link'
	d: diagonal link
	_link: link # for debuggin' only, remove
###
class Link extends React.Component
	constructor: (props) ->
		super props

	# COMPONENT LIFECYCLE
	# ===================
	componentDidMount: ->
		if lifecycles
			lg 'mounted', 'green'
			console.log "\t#{@constructor.name} #{@props.id}"

	componentDidUpdate: ->
		if lifecycles
			lg 'update', 'blue'
			console.log "\t#{@constructor.name} #{@props.id}"

	componentWillUnmount: ->
		if lifecycles
			lg 'will unmount', 'red'
			console.log "\t#{@constructor.name} #{@props.id}"

	# ===================

	render: ->
		# only for debugging
		textStyle =
			fillOpacity: "1"
		src = @props._link.source
		trg = @props._link.target
		[aX, aY] = [src.x, src.y]
		[bX, bY] = [trg.x, trg.y]
		midX = Math.abs(aX+bX)/2
		midY = Math.abs(aY+bY)/2
		# only for debugging

		`<g>
			{/*TEXT (AND WRAPPING GROUP) FOR DEBUGGING ONLY*/}
			{/*WRAPPING GROUP ABOUT AS NECESSARY AS D12*/}
			<text style={textStyle}
				x={midY}
				dy={midX}>{this.props.id}
			</text>

			<path className={this.props.className}
			   d={this.props.d}></path>
		</g>
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
	        <Root
	        	{...this.props}/>
	    </div>`

treeData = [
    name: "Top Level"
    id: 0
    parent: "null"
    children: [
        name: "Level 2: A"
        id: 1
        parent: "Top Level"
        children: [
            name: "Son of A"
            id: 2
            parent: "Level 2: A"
          ,
            name: "Daughter of A"
            id: 3
            parent: "Level 2: A"
        ]
      ,
        name: "Level 2: B"
        id: 4
        parent: "Top Level"
        children: [
            name: "Son of B"
            id: 5
            parent: "Level 2: B"
          ,
            name: "Daughter of B"
            id: 6
            parent: "Level 2: B"
        ]
      ,
        name: "Level 3: C"
        id: 7
        parent: "Top Level"
        children: [
            name: "Son of C"
            id: 8
            parent: "Level 3: C"
          ,
            name: "Daughter of C"
            id: 9
            parent: "Level 3: C"
        ]
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
	depth 		  : 0 # initialize depth

React.render `<App {...treeProps}/>`, document.getElementById 'react'