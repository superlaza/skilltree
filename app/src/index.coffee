express 		= require 'express'
falcorExpress 	= require 'falcor-express'
Router 			= require 'falcor-router'

cola = require 'webcola'

# graphData 		= require '../../data/majorMap.json'
# graphData 		= require '../../data/colatest.json'
graphData 		= require '../../data/courseAdjList.json'

console.log typeof(JSON.stringify(graphData))

app = express()

app.use '/model.json', falcorExpress.dataSourceRoute (req, res) ->
  # create a Virtual JSON resource with single key ("greeting")
  new Router [
    {
      # match a request for the key "greeting"    
      route: "graph",
      # respond with a PathValue with the value of "Hello World."
      get: ->
        # return {path:["greeting"], value: "Hello World"}
        path: ['graph']
        value: JSON.stringify(graphData)
    }
  ]


app.use express.static('static')
app.use express.static('data')


server = app.listen(process.env.PORT || 3000, ->
	host = server.address().address
	port = server.address().port
	console.log 'Example app listening at http://%s:%s', host, port
	return
)
