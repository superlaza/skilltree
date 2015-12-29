{classSpec, addClassSpec, constraintSpec} = require '../src/constants/Specs.coffee'


initialState = {
	nodes:[
		{nid: -1,name:addClassSpec.TEXT,type: addClassSpec.TYPE,width:addClassSpec.WIDTH,height:addClassSpec.HEIGHT},
		{nid: -2,name:'POS3733',type: classSpec.TYPE, width:classSpec.WIDTH,height:classSpec.HEIGHT},
		{nid: -3,name:'COT4500',type: classSpec.TYPE, width:classSpec.WIDTH,height:classSpec.HEIGHT},
		{nid: -4,name:addClassSpec.TEXT,type: addClassSpec.TYPE,width:addClassSpec.WIDTH,height:addClassSpec.HEIGHT},
		{nid: -5,name:'POS2041',type: classSpec.TYPE, width:classSpec.WIDTH,height:classSpec.HEIGHT},
		{nid: -6,name:'INR2002',type: classSpec.TYPE, width:classSpec.WIDTH,height:classSpec.HEIGHT},
		{nid: -7,name:'COP3223C',type: classSpec.TYPE, width:classSpec.WIDTH,height:classSpec.HEIGHT, hidden: false}
	]
	links:[
		{source:1,target:4},
		{source:1,target:5},
		{source:2,target:5}
	]
	groups:[
		{gid: 0, leaves:[0,1,2]},
		{gid: 1, leaves:[3,4,5]}
	]
	constraints: [
		{
			type: 'alignment'
			axis: 'x'
			offsets: [
				{node: 0, offset: 50},
				{node: 1, offset: 50},
				{node: 2, offset: 50}
			]
			group: 0
		},
		{
			type: 'alignment'
			axis: 'x'
			offsets: [
				{node: 3, offset: 50},
				{node: 4, offset: 50},
				{node: 5, offset: 50}
			]
			group: 1
		},
		{
			axis: 'x'
			left: 0
			right: 3
			gap: constraintSpec.displacement.GAP
		}
	]
}

module.exports = initialState