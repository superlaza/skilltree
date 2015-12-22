// http://bl.ocks.org/mbostock/1804919 multi-foci FL
// cluster bundling! http://bl.ocks.org/GerHobbelt/3071239
// http://www.coppelia.io/2014/07/an-a-to-z-of-extra-features-for-the-d3-force-layout/
var force;
function drawGraph(){
	var width = 2000,
		height = 2000;
	var color = d3.scale.category20();

	// node constants
	var maxRadius = 13;
	var padding = 1.5;

	var zoom = d3.behavior
				.zoom()
				.on('zoom', zoomed);

	var drag = d3.behavior.drag()
				.origin(function(d) {return d;})
				.on('dragstart', dragstarted)
				.on('drag', dragged)
				.on('dragend', dragended);

	// init svg
	var svg = d3.select("#graph") // get container element
		.append("svg") // svg namespace
			.attr("width", width)
			.attr("height", height)
		.append('g')
			.call(zoom);

	// set arrow def
	defs = svg.append("defs")
	defs.append("marker")
			.attr({
				"id":"arrow",
				"viewBox":"0 -5 10 10",
				"refX":30,
				"refY":0,
				"markerWidth":4,
				"markerHeight":4,
				"orient":"auto"
			})
			.append("path")
				.attr("d", "M0,-5L10,0L0,5")
				.attr("class","arrowHead");

	// view pane for zoom and pan
	var vis = svg
	  .append('rect')
		.attr('width', width)
		.attr('height', height)
		.style('fill', 'none')
		.style('pointer-events', 'all')

	container = svg.append('g');

	var nodes, links, node, link;
	d3.json("majorMap.json", function(graph) {
	  // if (error) throw error;

	  // init force layout
		force = d3.layout.force()
			.size([width, height])
			.charge(-4000)
			// .charge(-1)
			// .charge(function(d, i) { return i ? 0 : -1; })
			// .charge(function(d, i){
			// 	var charge = i ? 0 : 1;
			// 	if (d.type == 'major') charge = -1000;
			// 	return charge;
			// })
			// .linkStrength(0.1)
			// .gravity(0.002)
			// .linkDistance(30)
			// .linkDistance(function(d){
			// 	if(d.stre){
			// 		return d.stre;
			// 	}
			// 	// return 20;
			// })
			.on("tick", tick); //todo on tock

		  // feed data
		force
			.nodes(graph.nodes)
			.links(graph.links)
			.start();

		  // get layout properties
		nodes = force.nodes(),
		links = force.links(),
		node = container.selectAll(".node"),
		link = container.selectAll(".link");

		link = container.selectAll(".link")
			.data(graph.links)
			.enter().append("line")
			// .attr("class", "link")
			.attr({
				"class":"arrow link",
				"marker-end":"url(#arrow)"})
			.style("stroke-width", function(d) { return Math.sqrt(d.value); }); 

		node = container.selectAll(".node")
			.data(graph.nodes)
			.enter().append("circle")
			.attr("class", "node")
			// .attr("r", 5)
			.attr("r", function(d){
				if(d.type == 'major') return 13;
				if(d.type == 'course'){
					return 4
					return d.size;
				}
			})
			.style("fill", function(d) {
				if(d.type == 'major')return '#e6550d';
				if(d.type == 'course') return '#31a354';
				return color(d.group);
				// if(majors.Accounting.indexOf(d.code) != -1){
				// 	return '#e6550d';
				// }
				// else{
				// 	return '#31a354';
				// }
			})
			.call(drag);

		node.append("title")
			.text(function(d) { return d.name; });

		function collide(node) {
			var r = maxRadius+2,
			nx1 = node.x - r,
			nx2 = node.x + r,
			ny1 = node.y - r,
			ny2 = node.y + r;
			return function(quad, x1, y1, x2, y2) {
				if (quad.point && (quad.point !== node)) {
					var x = node.x - quad.point.x,
					y = node.y - quad.point.y,
					l = Math.sqrt(x * x + y * y),
					r = maxRadius+2;
					if (l < r) {
						l = (l - r) / l * .5;
						node.x -= x *= l;
						node.y -= y *= l;
						quad.point.x += x;
						quad.point.y += y;
					}
				}
				return x1 > nx2
					|| x2 < nx1
					|| y1 > ny2
					|| y2 < ny1;
			};
		}

		function tick() {
			var q = d3.geom.quadtree(nodes),
				i = 0,
				n = nodes.length;
			while (++i < n) {
				q.visit(collide(nodes[i]));
			}

			link.attr("x1", function(d) { return d.source.x; })
				.attr("y1", function(d) { return d.source.y; })
				.attr("x2", function(d) { return d.target.x; })
				.attr("y2", function(d) { return d.target.y; });

			node.attr("cx", function(d) { return d.x; })
				.attr("cy", function(d) { return d.y; });
		}

	}); // end data load


	function zoomed() { container.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")"); }

	function dragstarted(d) {
	  d3.event.sourceEvent.stopPropagation();
	  d3.select(this).classed("dragging", true);
	}

	function dragged(d) {
		d3.select(this).attr("cx", d.x = d3.event.x).attr("cy", d.y = d3.event.y); 
		force.alpha(0.02);
	}

	function dragended(d) {
		d3.select(this).classed("dragging", false); 
	}
}