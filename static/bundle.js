webpackJsonp([0],{

/***/ 0:
/***/ function(module, exports, __webpack_require__) {

	var Graph, React, ReactDOM, model;

	React = __webpack_require__(148);

	ReactDOM = __webpack_require__(1);

	Graph = __webpack_require__(147);

	model = new falcor.Model({
	  source: new falcor.HttpDataSource('model.json')
	});

	model.get("graph").then(function(response) {
	  var graphData;
	  graphData = JSON.parse(response.json.graph);
	  return ReactDOM.render(React.createElement(Graph, {
	    'graphData': graphData
	  }), document.getElementById('react'));
	});


/***/ },

/***/ 1:
/***/ function(module, exports, __webpack_require__) {

	'use strict';

	module.exports = __webpack_require__(2);


/***/ },

/***/ 147:
/***/ function(module, exports, __webpack_require__) {

	var Graph, React, drawGraph;

	React = __webpack_require__(148);

	drawGraph = __webpack_require__(163);

	__webpack_require__(162);

	Graph = React.createClass({
	  componentDidMount: function() {
	    return drawGraph(this.refs.graph, this.props.graphData);
	  },
	  render: function() {
	    return React.createElement("div", {
	      "id": 'graph',
	      "ref": 'graph'
	    }, "\t\t\tHey");
	  }
	});

	module.exports = Graph;


/***/ },

/***/ 162:
/***/ function(module, exports, __webpack_require__) {

	var React, ReactDOM;

	React = __webpack_require__(148);

	ReactDOM = __webpack_require__(1);

	console.log('test', React);


/***/ },

/***/ 163:
/***/ function(module, exports, __webpack_require__) {

	var d3, drawGraph;

	d3 = __webpack_require__(161);

	drawGraph = function(graphElement, graph) {
	  var collide, color, container, defs, drag, dragended, dragged, dragstarted, force, height, link, links, maxRadius, node, nodes, padding, svg, tick, vis, width, zoom, zoomed;
	  width = 2000;
	  height = 2000;
	  color = d3.scale.category20();
	  maxRadius = 13;
	  padding = 1.5;
	  zoomed = function() {
	    container.attr('transform', 'translate(' + d3.event.translate + ')scale(' + d3.event.scale + ')');
	  };
	  dragstarted = function(d) {
	    d3.event.sourceEvent.stopPropagation();
	    d3.select(this).classed('dragging', true);
	  };
	  dragged = function(d) {
	    d3.select(this).attr('cx', d.x = d3.event.x).attr('cy', d.y = d3.event.y);
	    force.alpha(0.02);
	  };
	  dragended = function(d) {
	    d3.select(this).classed('dragging', false);
	  };
	  collide = function(node) {
	    var nx1, nx2, ny1, ny2, r;
	    r = maxRadius + 2;
	    nx1 = node.x - r;
	    nx2 = node.x + r;
	    ny1 = node.y - r;
	    ny2 = node.y + r;
	    return function(quad, x1, y1, x2, y2) {
	      var r;
	      var l, x, y;
	      if (quad.point && quad.point !== node) {
	        x = node.x - quad.point.x;
	        y = node.y - quad.point.y;
	        l = Math.sqrt(x * x + y * y);
	        r = maxRadius + 2;
	        if (l < r) {
	          l = (l - r) / l * .5;
	          node.x -= x *= l;
	          node.y -= y *= l;
	          quad.point.x += x;
	          quad.point.y += y;
	        }
	      }
	      return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
	    };
	  };
	  tick = function() {
	    var i, n, q;
	    q = d3.geom.quadtree(nodes);
	    i = 0;
	    n = nodes.length;
	    while (++i < n) {
	      q.visit(collide(nodes[i]));
	    }
	    link.attr('x1', function(d) {
	      return d.source.x;
	    }).attr('y1', function(d) {
	      return d.source.y;
	    }).attr('x2', function(d) {
	      return d.target.x;
	    }).attr('y2', function(d) {
	      return d.target.y;
	    });
	    node.attr('cx', function(d) {
	      return d.x;
	    }).attr('cy', function(d) {
	      return d.y;
	    });
	  };
	  zoom = d3.behavior.zoom().on('zoom', zoomed);
	  drag = d3.behavior.drag().origin(function(d) {
	    return d;
	  }).on('dragstart', dragstarted).on('drag', dragged).on('dragend', dragended);
	  svg = d3.select(graphElement).append('svg').attr('width', width).attr('height', height).append('g').call(zoom);
	  defs = svg.append('defs');
	  defs.append('marker').attr({
	    'id': 'arrow',
	    'viewBox': '0 -5 10 10',
	    'refX': 30,
	    'refY': 0,
	    'markerWidth': 4,
	    'markerHeight': 4,
	    'orient': 'auto'
	  }).append('path').attr('d', 'M0,-5L10,0L0,5').attr('class', 'arrowHead');
	  vis = svg.append('rect').attr('width', width).attr('height', height).style('fill', 'none').style('pointer-events', 'all');
	  container = svg.append('g');
	  nodes = void 0;
	  links = void 0;
	  node = void 0;
	  link = void 0;
	  force = d3.layout.force().size([width, height]).charge(-4000).on('tick', tick);
	  force.nodes(graph.nodes).links(graph.links).start();
	  nodes = force.nodes();
	  links = force.links();
	  node = container.selectAll('.node');
	  link = container.selectAll('.link');
	  link = container.selectAll('.link').data(graph.links).enter().append('line').attr({
	    'class': 'arrow link',
	    'marker-end': 'url(#arrow)'
	  }).style('stroke-width', function(d) {
	    return Math.sqrt(d.value);
	  });
	  node = container.selectAll('.node').data(graph.nodes).enter().append('circle').attr('class', 'node').attr('r', function(d) {
	    if (d.type === 'major') {
	      return 13;
	    }
	    if (d.type === 'course') {
	      return 4;
	      return d.size;
	    }
	  }).style('fill', function(d) {
	    if (d.type === 'major') {
	      return '#e6550d';
	    }
	    if (d.type === 'course') {
	      return '#31a354';
	    }
	    return color(d.group);
	  }).call(drag);
	  node.append('title').text(function(d) {
	    return d.name;
	  });
	};

	module.exports = drawGraph;


/***/ }

});