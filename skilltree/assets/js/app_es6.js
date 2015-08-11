"use strict";

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var _get = function get(_x, _x2, _x3) { var _again = true; _function: while (_again) { var object = _x, property = _x2, receiver = _x3; desc = parent = getter = undefined; _again = false; if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { _x = parent; _x2 = property; _x3 = receiver; _again = true; continue _function; } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } } };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Hello = (function (_React$Component) {
	_inherits(Hello, _React$Component);

	function Hello() {
		_classCallCheck(this, Hello);

		_get(Object.getPrototypeOf(Hello.prototype), "constructor", this).apply(this, arguments);
	}

	_createClass(Hello, [{
		key: "render",
		value: function render() {
			return React.createElement(
				"div",
				null,
				"Hello ",
				this.props.name,
				React.createElement(
					"div",
					null,
					this.props["class"]
				)
			);
		}
	}]);

	return Hello;
})(React.Component);

React.render(React.createElement(Hello, { name: "World", "class": "test" }), document.getElementById('react'));

var Circle = (function (_React$Component2) {
	_inherits(Circle, _React$Component2);

	function Circle() {
		_classCallCheck(this, Circle);

		_get(Object.getPrototypeOf(Circle.prototype), "constructor", this).apply(this, arguments);
	}

	_createClass(Circle, [{
		key: "render",
		value: function render() {
			return React.createElement("circle", { r: this.props.r, style: this.props.style });
		}
	}]);

	return Circle;
})(React.Component);

var Node = (function (_React$Component3) {
	_inherits(Node, _React$Component3);

	function Node() {
		_classCallCheck(this, Node);

		_get(Object.getPrototypeOf(Node.prototype), "constructor", this).apply(this, arguments);
	}

	_createClass(Node, [{
		key: "render",
		value: function render() {
			var circleProps = {
				r: '10',
				style: {
					fill: 'rgb(255,255,255)'
				}
			};
			return React.createElement(
				"g",
				{ className: this.props.className, transform: this.props.transform },
				React.createElement(Circle, circleProps)
			);
		}
	}]);

	return Node;
})(React.Component);

var Tree = (function (_React$Component4) {
	_inherits(Tree, _React$Component4);

	function Tree() {
		_classCallCheck(this, Tree);

		_get(Object.getPrototypeOf(Tree.prototype), "constructor", this).apply(this, arguments);
	}

	_createClass(Tree, [{
		key: "render",
		value: function render() {
			var rows = [React.createElement(Node, { className: "node", transform: "translate(120,120)" }), React.createElement(Node, { className: "node", transform: "translate(80,80)" })];
			rows.forEach(function (e, i) {
				return e['props']['key'] = i;
			});
			console.log(React.createElement(Node, { className: "node", transform: "translate(120,120)" }).props);
			return React.createElement(
				"svg",
				{ width: this.props.width, height: this.props.height },
				rows
			);
		}
	}]);

	return Tree;
})(React.Component);

React.render(React.createElement(Tree, null), document.getElementById('react'));