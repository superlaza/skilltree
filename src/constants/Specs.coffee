module.exports =
	classSpec:
		WIDTH: 150
		HEIGHT: 40
		TYPE: 'class'
		status:
			ENROLLED: 'enrolled'
			OPTION: 'option'
			PREREQ: 'prereq'
		CLASS: 'classNode'
		COLOR:
			DEFAULT: 'rgb(255, 127, 14)'
			SELECTED: 'rgb(0, 153, 0)'
		OPACITY: 0.3
	addClassSpec:
		TEXT: "Add Class"
		TYPE: 'btnAddClass'
		CLASS: 'btn-add-class'
		WIDTH: 160
		HEIGHT: 40
	btnDeleteClassSpec:
		CLASS: 'btn-delete-class'
		COLOR: '#e00'
	constraintSpec:
		displacement:
			GAP: 220
		alignment:
			OFFSET:
				x: 50