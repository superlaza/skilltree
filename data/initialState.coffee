{classConfig, addClassConfig} = require '../src/constants/NodeConfig.coffee'

{width, height} = classConfig
{btnWidth, btnHeight} = addClassConfig

initialState = {
	nodes:[
		{nid: -1,name:addClassConfig.text,type: addClassConfig.type,width:btnWidth,height:btnHeight},
		{nid: -2,name:'POS3733',width:width,height:height},
		{nid: -3,name:'COT4500',width:width,height:height},
		{nid: -4,name:addClassConfig.text,type: addClassConfig.type,width:btnWidth,height:btnHeight},
		{nid: -5,name:'POS2041',width:width,height:height},
		{nid: -6,name:'INR2002',width:width,height:height},
		{nid: -7,name:'COP3223C',width:width,height:height, hidden: false}
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
			gap: 200
		}
	]
}

module.exports = initialState