module.exports =
	classSpec:
		WIDTH: 150
		HEIGHT: 40
		TYPE: 'class'
		status:
			ENROLLED: 'enrolled'
			OPTION: 'option'
			PREREQ: 'prereq'
		CLASS: 'class-node'
		STYLE:
			DEFAULT:
				FILL: 'rgb(255, 127, 14)'
			PLACEHOLDER:
				FILL: 'white'
			SELECTED:
				BORDER:
					COLOR: 'rgb(255,197,0)'
					WIDTH: 4
		OPACITY: 0.3
	addClassSpec:
		TEXT: "Add Class"
		TYPE: 'btnAddClass'
		CLASS: 'btn-add-class'
		WIDTH: 210
		HEIGHT: 40
	btnDeleteClassSpec:
		CLASS: 'btn-delete-class'
		COLOR: '#e00'
	groupSpec:
		STYLE:
			FILL: 'rgb(214,214,214)'
	constraintSpec:
		displacement:
			GAP: 220
		alignment:
			OFFSET:
				x: 0