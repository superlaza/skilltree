treeData = [ {
  'name': 'Top Level'
  'parent': 'null'
  'children': [
    {
      'name': 'Level 2: A'
      'parent': 'Top Level'
      'children': [
        {
          'name': 'Son of A'
          'parent': 'Level 2: A'
        }
        {
          'name': 'Daughter of A'
          'parent': 'Level 2: A'
        }
      ]
    }
    {
      'name': 'Level 2: B'
      'parent': 'Top Level'
    }
  ]
} ]

width = 960
height = 500
i = 0
tree = d3.layout
		.tree()
		.size([
			height
			width
		])
diagonal = d3.svg
			.diagonal()
			.projection((d) ->
				[d.y, d.x]
			)
_line = d3.svg
		.line()
		.x( (d) ->
			d.x
		).y( (d) ->
			d.y
		).interpolate('basis')
line = (d) ->
	_line [
		y: d.source.x
		x: d.source.y
	,
		y: d.target.x
		x: d.target.y
	]

svg = d3.select('body')
		.append('svg')
		.attr('width', width)
		.attr('height', height)
		.append('g')
		.attr('transform', 'translate(' + 0 + ',' + 0 + ')')

root = treeData[0]

update = (source, angle) ->
	# Compute the new tree layout.
	nodes = tree.nodes(root).reverse()
	links = tree.links(nodes)
	center =
		x: height/2
		y: width/2

	[xoffset, yoffset] = [center.y-d.y, center.x-d.x] for d in nodes when d.name is "Top Level"


	# Normalize for fixed-depth.
	nodes.forEach (d) ->
		# shift everybody rightwards
		d.y += xoffset+150
		d.x += yoffset

		# a = 1*Math.PI / 8
		a = angle
		c = Math.cos(a)
		s = Math.sin(a)
		cx = center.x
		cy = center.y
		scale = 1/6
		d.y = scale * (d.y - cy) + cy
		d.x = scale * (d.x - cx) + cx
		dy = (d.y - cy) * c - ((d.x - cx) * s) + cy
		dx = (d.x - cx) * c + (d.y - cy) * s + cx
		d.y = dy
		d.x = dx
		# console.log('post', d.x, d.y);
		return

	# center node
	svg.append('g')
			.attr('transform', (d) ->
				"translate(#{center.y}, #{center.x})"
			).append('circle')
			.attr('r', 4)
			.attr('x', center.y)
			.attr('y', center.x)
			.style 'fill', '#f00'

	# Declare the nodesâ€¦
	node = svg.selectAll('g.node')
			.data(nodes, (d) ->
					d.id or (d.id = ++i)
			)

	delay = 0
	node.transition()
		.duration(delay)
		.attr('transform', (d) -> 
			"translate(#{d.y}, #{d.x})")

	# Enter the nodes.
	nodeEnter = node.enter()
					.append('g')
					.attr('class', 'node')
					.attr('transform', (d) ->
						"translate(#{d.y}, #{d.x})"
					)

	nodeEnter.append('circle')
			.attr('r', 10)
			.style 'fill', '#fff'

	nodeEnter.append('text')
			.attr('x', (d) ->
				if d.children or d._children then -13 else 13
			).attr('dy', '.35em').attr('text-anchor', (d) ->
				if d.children or d._children then 'end' else 'start'
			).text((d) ->
				d.name
			).style 'fill-opacity', 1

	# Declare the linksâ€¦
	link = svg.selectAll('path.link')
			.data(links, (d) ->
				d.target.id
			)

	link.transition()
		.duration(delay)
		.attr 'd', line

	# Enter the links.
	link.enter()
		.insert('path', 'g')
		.attr('class', 'link')
		.attr 'd', line

update root, 0

# on ready, initialize slider
$ -> $("#slider").slider
				min: 0
				max: 2*Math.PI
				step: 0.0314
				slide: (e, ui) ->
					update root, ui.value