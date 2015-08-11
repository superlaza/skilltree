var App, Tree, TreeRender, appProps, dims, margin, treeData,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

TreeRender = (function() {
  function TreeRender() {}

  TreeRender.create = function(el, props, state) {
    var height, margin, ref, svg, width;
    console.log('props', props);
    ref = props.dims, width = ref.width, height = ref.height;
    console.log(height);
    margin = props.margin;
    svg = d3.select(el).append("svg").attr("width", width + margin.right + margin.left).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")").attr("class", "d3-skilltree");
    return this.update(svg.node(), state);
  };

  TreeRender.update = function(el, state) {
    return this.draw(el, state.data);
  };

  TreeRender.destroy = function(el) {};

  TreeRender.draw = function(el, data) {
    var diagonal, link, links, node, nodeEnter, nodes, svg, tree;
    console.log('drawing points');
    tree = d3.layout.tree().size([height, width]);
    diagonal = d3.svg.diagonal().projection(function(d) {
      return [d.y, d.x];
    });
    nodes = tree.nodes(data[0]).reverse();
    links = tree.links(nodes);
    nodes.forEach(function(d) {
      return d.y = d.depth * 180;
    });
    svg = d3.select(el);
    node = svg.selectAll("g.node").data(nodes, function(d) {
      return d.id;
    });
    nodeEnter = node.enter().append("g").attr("class", "node").attr("transform", function(d) {
      return "translate(" + d.y + "," + d.x + ")";
    });
    nodeEnter.append("circle").attr("r", 10).style("fill", "#fff");
    nodeEnter.append("text").attr("x", function(d) {
      if (d.children != null) {
        return -70;
      } else {
        return 20;
      }
    }).attr("dy", ".35em").attr("text-anchor", function(d) {
      if (d.children != null) {
        if (d._children != null) {
          return 'end';
        } else {
          return 'start';
        }
      } else {
        return null;
      }
    }).text(function(d) {
      return d.name;
    }).style("fill-opacity", 1);
    link = svg.selectAll("path.link").data(links, function(d) {
      return d.target.id;
    });
    return link.enter().insert("path", "g").attr("class", "link").attr("d", diagonal);
  };

  return TreeRender;

})();

Tree = (function(superClass) {
  extend(Tree, superClass);

  function Tree() {
    return Tree.__super__.constructor.apply(this, arguments);
  }

  Tree.propTypes = {
    data: React.PropTypes.array,
    nodeCount: React.PropTypes.number
  };

  Tree.defaultProps = {
    nodeCount: 0
  };

  Tree.prototype.componentDidMount = function() {
    var el;
    console.log('mounted', this.getTreeState());
    el = React.findDOMNode(this);
    return TreeRender.create(el, this.props, this.getTreeState());
  };

  Tree.prototype.componentDidUpdate = function() {
    return console.log('updated');
  };

  Tree.prototype.getTreeState = function() {
    return {
      data: this.props.data
    };
  };

  Tree.prototype.componentWillUnmount = function() {
    return console.log('will unmount');
  };

  Tree.prototype.render = function() {
    return React.createElement("div", {className: this.props.className});
  };

  return Tree;

})(React.Component);

treeData = [
  {
    "name": "Top Level",
    "parent": "null",
    "children": [
      {
        "name": "Level 2: A",
        "parent": "Top Level",
        "children": [
          {
            "name": "Son of A",
            "parent": "Level 2: A"
          }, {
            "name": "Daughter of A",
            "parent": "Level 2: A"
          }
        ]
      }, {
        "name": "Level 2: B",
        "parent": "Top Level"
      }
    ]
  }
];

margin = {
  top: 20,
  right: 120,
  bottom: 20,
  left: 120
};

dims = {
  width: 960 - margin.right - margin.left,
  height: 500 - margin.top - margin.bottom
};

App = (function(superClass) {
  extend(App, superClass);

  function App(props) {
    App.__super__.constructor.call(this, props);
    this.state = {
      data: props.data,
      dims: props.dims
    };
  }

  App.prototype.render = function() {
    return React.createElement("div", {className: "App"}, 
	        React.createElement(Tree, React.__spread({},  this.props))
	    );
  };

  return App;

})(React.Component);

appProps = {
  data: treeData,
  dims: dims,
  margin: margin
};

React.render(React.createElement(App, React.__spread({},  appProps)), document.getElementById('react'));
