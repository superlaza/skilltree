# http://bl.ocks.org/mbostock/1804919 multi-foci FL
# cluster bundling! http://bl.ocks.org/GerHobbelt/3071239
# http://www.coppelia.io/2014/07/an-a-to-z-of-extra-features-for-the-d3-force-layout/
d3 = require 'd3'

drawGraph = (graphElement, graph) ->
  width = 2000
  height = 2000
  color = d3.scale.category20()
  # node constants
  maxRadius = 13
  padding = 1.5
  
  zoomed = ->
    container.attr 'transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')'
    return

  dragstarted = (d) ->
    d3.event.sourceEvent.stopPropagation()
    d3.select(this).classed 'dragging', true
    return

  dragged = (d) ->
    d3.select(this).attr('cx', d.x = d3.event.x).attr 'cy', d.y = d3.event.y
    force.alpha 0.02
    return

  dragended = (d) ->
    d3.select(this).classed 'dragging', false
    return

  collide = (node) ->
    r = maxRadius + 2
    nx1 = node.x - r
    nx2 = node.x + r
    ny1 = node.y - r
    ny2 = node.y + r
    (quad, x1, y1, x2, y2) ->
      `var r`
      if quad.point and quad.point != node
        x = node.x - (quad.point.x)
        y = node.y - (quad.point.y)
        l = Math.sqrt(x * x + y * y)
        r = maxRadius + 2
        if l < r
          l = (l - r) / l * .5
          node.x -= x *= l
          node.y -= y *= l
          quad.point.x += x
          quad.point.y += y
      x1 > nx2 or x2 < nx1 or y1 > ny2 or y2 < ny1

  tick = ->
    q = d3.geom.quadtree(nodes)
    i = 0
    n = nodes.length
    while ++i < n
      q.visit collide(nodes[i])
    link.attr('x1', (d) ->
      d.source.x
    ).attr('y1', (d) ->
      d.source.y
    ).attr('x2', (d) ->
      d.target.x
    ).attr 'y2', (d) ->
      d.target.y
    node.attr('cx', (d) ->
      d.x
    ).attr 'cy', (d) ->
      d.y
    return

  zoom = d3.behavior.zoom().on('zoom', zoomed)
  drag = d3.behavior.drag()
    .origin(
      (d) -> d
    )
    .on('dragstart', dragstarted)
    .on('drag', dragged)
    .on('dragend', dragended)
  # init svg
  svg = d3.select(graphElement)
        .append('svg')
        .attr('width', width)
        .attr('height', height)
        .append('g')
        .call(zoom)

  defs = svg.append('defs')
  defs.append('marker').attr(
    'id': 'arrow'
    'viewBox': '0 -5 10 10'
    'refX': 30
    'refY': 0
    'markerWidth': 4
    'markerHeight': 4
    'orient': 'auto').append('path').attr('d', 'M0,-5L10,0L0,5').attr 'class', 'arrowHead'
  # view pane for zoom and pan
  vis = svg.append('rect').attr('width', width).attr('height', height).style('fill', 'none').style('pointer-events', 'all')
  container = svg.append('g')
  nodes = undefined
  links = undefined
  node = undefined
  link = undefined

  force = d3.layout.force().size([
    width
    height
  ]).charge(-4000).on('tick', tick)
  #todo on tock
  # feed data
  force.nodes(graph.nodes).links(graph.links).start()
  # get layout properties
  nodes = force.nodes()
  links = force.links()
  node = container.selectAll('.node')
  link = container.selectAll('.link')
  link = container.selectAll('.link').data(graph.links).enter().append('line').attr(
    'class': 'arrow link'
    'marker-end': 'url(#arrow)').style('stroke-width', (d) ->
    Math.sqrt d.value
  )
  node = container.selectAll('.node').data(graph.nodes).enter().append('circle').attr('class', 'node').attr('r', (d) ->
    if d.type == 'major'
      return 13
    if d.type == 'course'
      return 4
      return d.size
    return
  ).style('fill', (d) ->
    if d.type == 'major'
      return '#e6550d'
    if d.type == 'course'
      return '#31a354'
    color d.group
    # if(majors.Accounting.indexOf(d.code) != -1){
    #   return '#e6550d';
    # }
    # else{
    #   return '#31a354';
    # }
  ).call(drag)
  node.append('title').text (d) ->
    d.name

  return

module.exports = drawGraph