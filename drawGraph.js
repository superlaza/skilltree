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

	// mouse event vars
	var selected_node = null,
		selected_link = null,
		mousedown_link = null,
		mousedown_node = null,
		mouseup_node = null;

	// init svg
	var svg = d3.select("#graph")
		.append("svg:svg")
		.attr("width", width)
		.attr("height", height)
		.attr("pointer-events", "all");

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


	var vis = svg
	  .append('svg:g')
		.call(d3.behavior.zoom().on("zoom", rescale))
		.on("dblclick.zoom", null)
	  .append('svg:g')
		.on("mousemove", mousemove)
		.on("mousedown", mousedown)
		.on("mouseup", mouseup);

	vis.append('svg:rect')
		.attr('width', width)
		.attr('height', height)
		.attr('fill', 'white');




	var nodes, links, node, link;
	d3.json("majorMap.json", function(graph) {
	  // if (error) throw error;

	  force = d3.layout.force()
	  	.size([width, height])
	  	// .charge(-40)
	  	.charge(0)
	  	// .charge(function(d){
	  	// 	var charge = -1;
	  	// 	if (d.type == 'major') charge = -4000;
	  	// 	return charge;
	  	// })
	  	// .linkStrength(0.1)
	  	// .gravity(0.02)
	  	// .linkDistance(30)
	  	.on("tick", tick); //todo on tock

	  force
		  .nodes(graph.nodes)
		  .links(graph.links)
		  .start();

	  // get layout properties
	  nodes = force.nodes(),
	  links = force.links(),
	  node = vis.selectAll(".node"),
	  link = vis.selectAll(".link");

	  link = vis.selectAll(".link")
		  .data(graph.links)
		.enter().append("line")
		  // .attr("class", "link")
		    .attr({
		    	"class":"arrow link",
		  	"marker-end":"url(#arrow)"})
		  .style("stroke-width", function(d) { return Math.sqrt(d.value); }); 

	  node = vis.selectAll(".node")
		  .data(graph.nodes)
		.enter().append("circle")
		  .attr("class", "node")
		  // .attr("r", 5)
		  .attr("r", function(d){
		  	if(d.type == 'major') return 13;
		  	if(d.type == 'course') return 5;
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
		  .call(force.drag);

	  node.append("title")
		  .text(function(d) { return d.name; });

	  function collide(alpha) {
	  	var quadtree = d3.geom.quadtree(nodes);
	    return function(d) {
	      var rb = Math.min(d.radius, maxRadius),
	          nx1 = d.x - rb,
	          nx2 = d.x + rb,
	          ny1 = d.y - rb,
	          ny2 = d.y + rb;
	      quadtree.visit(function(quad, x1, y1, x2, y2) {
	        if (quad.point && (quad.point !== d)) {
	          var x = d.x - quad.point.x,
	              y = d.y - quad.point.y,
	              l = Math.sqrt(x * x + y * y);
	            if (l < rb) {
	            l = (l - rb) / l * alpha;
	            d.x -= x *= l;
	            d.y -= y *= l;
	            quad.point.x += x;
	            quad.point.y += y;
	          }
	        }
	        return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
	      });
	    };
	  }

	  function tick() {
	    link.attr("x1", function(d) { return d.source.x; })
	  	  .attr("y1", function(d) { return d.source.y; })
	  	  .attr("x2", function(d) { return d.target.x; })
	  	  .attr("y2", function(d) { return d.target.y; });

	    node.attr("cx", function(d) { return d.x; })
	  	  .attr("cy", function(d) { return d.y; });

	    node.each(collide(1));
	  }

	  redraw();
	}); // end data load

	function mousedown() {
	  if (!mousedown_node && !mousedown_link) {
		// allow panning if nothing is selected
		// debugger;
		vis.call(d3.behavior.zoom().on("zoom"), rescale);
		return;
	  }
	}

	function mousemove() {
	  if (!mousedown_node) return;

	  // update drag line
	  drag_line
		  .attr("x1", mousedown_node.x)
		  .attr("y1", mousedown_node.y)
		  .attr("x2", d3.svg.mouse(this)[0])
		  .attr("y2", d3.svg.mouse(this)[1]);

	}

	function mouseup() {
	  if (mousedown_node) {
		// hide drag line
		drag_line
		  .attr("class", "drag_line_hidden")

		if (!mouseup_node) {
		  // add node
		  var point = d3.mouse(this),
			node = {x: point[0], y: point[1]},
			n = nodes.push(node);

		  // select new node
		  selected_node = node;
		  selected_link = null;
		  
		  // add link to mousedown node
		  links.push({source: mousedown_node, target: node});
		}

		redraw();
	  }
	  // clear mouse event vars
	  resetMouseVars();
	}

	function resetMouseVars() {
	  mousedown_node = null;
	  mouseup_node = null;
	  mousedown_link = null;
	}

	// tick went here

	// rescale g
	function rescale() {
	  trans=d3.event.translate;
	  scale=d3.event.scale;
	  vis.attr("transform",
		  "translate(" + trans + ")"
		  + " scale(" + scale + ")");
	}

	// redraw force layout
	function redraw() {

	  link = link.data(links);

	  link.enter().insert("line", ".node")
		  .attr("class", "link")
		  .on("mousedown", 
			function(d) { 
			  mousedown_link = d; 
			  if (mousedown_link == selected_link) selected_link = null;
			  else selected_link = mousedown_link; 
			  selected_node = null; 
			  redraw(); 
			})

	  link.exit().remove();

	  link
		.classed("link_selected", function(d) { return d === selected_link; });

	  node = node.data(nodes);

	  node.enter().insert("circle")
		  .attr("class", "node")
		  .attr("r", 5)
		  .on("mousedown", 
			function(d) { 
			  // disable zoom
			  vis.call(d3.behavior.zoom().on("zoom"), null);

			  mousedown_node = d;
			  if (mousedown_node == selected_node) selected_node = null;
			  else selected_node = mousedown_node; 
			  selected_link = null; 

			  // reposition drag line
			  drag_line
				  .attr("class", "link")
				  .attr("x1", mousedown_node.x)
				  .attr("y1", mousedown_node.y)
				  .attr("x2", mousedown_node.x)
				  .attr("y2", mousedown_node.y);

			  redraw(); 
			})
		  .on("mousedrag",
			function(d) {
			  // redraw();
			})
		  .on("mouseup", 
			function(d) { 
			  if (mousedown_node) {
				mouseup_node = d; 
				if (mouseup_node == mousedown_node) { resetMouseVars(); return; }

				// add link
				var link = {source: mousedown_node, target: mouseup_node};
				links.push(link);

				// select new link
				selected_link = link;
				selected_node = null;

				// enable zoom
				vis.call(d3.behavior.zoom().on("zoom"), rescale);
				redraw();
			  } 
			})
		.transition()
		  .duration(750)
		  .ease("elastic")
		  .attr("r", 6.5);

	  node.exit().transition()
		  .attr("r", 0)
		.remove();

	  node
		.classed("node_selected", function(d) { return d === selected_node; });

	  

	  if (d3.event) {
		// prevent browser's default behavior
		d3.event.preventDefault();
	  }

	  force.start();

	}

	function spliceLinksForNode(node) {
	  toSplice = links.filter(
		function(l) { 
		  return (l.source === node) || (l.target === node); });
	  toSplice.map(
		function(l) {
		  links.splice(links.indexOf(l), 1); });
	}
}