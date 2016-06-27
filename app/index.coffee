fs = require('fs');
express 		= require 'express'
falcorExpress 	= require 'falcor-express'
Router 			= require 'falcor-router'

cola = require 'webcola'
neo4j = require('neo4j');

graphData 		= require '../data/majorMap.json'
graphData 		= require '../data/colatest.json'
graphData     = require '../data/courseAdjList.json'
majorData 		= require '../data/majors/json/anthropology.json'


{user, pw} = JSON.parse(fs.readFileSync('./config.cfg').toString())


env = 'dev'

app = express()

host = if env=='dev' then 'localhost' else 'db'
db = new neo4j.GraphDatabase("http://#{user}:#{pw}@#{host}:7474");


app.use '/model.json', (req, res) ->
	callback = (err, results) ->
	
	# filterNode = ''
	filterNode = "where course.college='COS-MATH'"
	filterLink = "where source.college='COS-MATH' and target.college='COS-MATH'"

	getCourses = new Promise(
		(resolve, reject) ->
			db.cypher({
					query: "MATCH (course:Course) #{filterNode} RETURN course",
					params: {},
			}, (err, results)=>
					throw err if err
					result = results[0]
					if !result
						console.log('No results.')
					else
						results = results.map (res) ->
							res.course.properties

						resolve(results)
			)
	)
	getPrereqs = new Promise(
		(resolve, reject) ->
			db.cypher({
					query: "MATCH p=(source)-[r:REQUIRES]->(target) #{filterLink} RETURN source.code as source, target.code as target",
					params: {},
			}, (err, results)=>
					throw err if err
					result = results[0]
					if !result
						console.log('No results.')
					else
						console.log results

						resolve(results)
			)
	)

	Promise.all([getCourses, getPrereqs]).then (data)->
		# res.end(JSON.stringify(results))
		res.end JSON.stringify {
		 	'nodes': data[0]
		 	'links': data[1]
		 }
	

# app.use '/model.json', falcorExpress.dataSourceRoute (req, res) ->
# 	# create a Virtual JSON resource with single key ("greeting")
# 	new Router [
# 		{
# 			# match a request for the key "greeting"
# 			route: "graph",
# 			# respond with a PathValue with the value of "Hello World."
# 			get: ->
# 				# return {path:["greeting"], value: "Hello World"}
# 				path: ['graph']
# 				value: JSON.stringify(graphData)
# 		},
# 		{
# 			# match a request for the key "greeting"    
# 			route: "major",
# 			# respond with a PathValue with the value of "Hello World."
# 			get: ->
# 				# return {path:["greeting"], value: "Hello World"}
# 				


# 				path: ['major']
# 				value: JSON.stringify(majorData)
# 		}
# 	]


app.use express.static('static')
app.use express.static('data')

server = app.listen(process.env.PORT || 3000, ->
	host = server.address().address
	port = server.address().port
	console.log 'Example app listening at http://%s:%s', host, port
	return
)
