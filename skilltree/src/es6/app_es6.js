class Hello extends React.Component {
    render(){
    	return  <div>
		    		Hello {this.props.name}
		    		<div>
		    			{this.props.class}
		    		</div>
		    	</div>;
    }
}
React.render(<Hello name="World" class="test"/>, document.getElementById('react'));


class Circle extends React.Component {
	render(){
		return <circle r={this.props.r} style={this.props.style}></circle>
	}
}

class Node extends React.Component {
	render(){
		let circleProps = {
			r: '10',
			style: {
				fill: 'rgb(255,255,255)'
			}
		}
		return  <g className={this.props.className} transform={this.props.transform}>
					<Circle {...circleProps}/>
				</g>
	}
}

class Tree extends React.Component {
	render(){
		let rows = [
			<Node className='node' transform='translate(120,120)'/>,
			<Node className='node' transform='translate(80,80)'/>
		]
		rows.forEach( (e,i) => e['props']['key'] = i)
		console.log(<Node className='node' transform='translate(120,120)'/>.props)
		return  <svg width={this.props.width} height={this.props.height}>
					{rows}
				</svg>
	}
}

React.render(<Tree/>, document.getElementById('react'))