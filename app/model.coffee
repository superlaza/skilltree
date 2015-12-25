{createStore} = require 'redux'

l = console.log

reducer = (state = 0, action) ->
	switch action.type
		when 'DELETE'
			state + 1

store = createStore reducer

store.subscribe ->
	console.log 'state is', store.getState()

store.dispatch {type: 'DELETE'}