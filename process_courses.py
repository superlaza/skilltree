import re, json, operator
from py2neo import authenticate, Graph, Node, Relationship
import matplotlib.pyplot as plt

from collections import defaultdict

#notes
# not matching 0-5(0,1-5) 

# need to handle case when PR is followed by newline
# e.g. Introduction to Gender Studies: PR: ENC 1101.
#His....

#fucking taboo theatre: sex & vioence on stage
# What a Drag: The Art of Transgender in
# Entertainment: 

# prereq regex doesn't capture this
# Musical Theatre Acting I: PR: B.F.A. Musical
# Theatre major, and C (2.0) or better required in TPP
# 2110C. Practical acting techniques with solo musical theatre
# repertoire. Fall. 

# some courses have PR and CR
# Logic and Proof in Mathematics:

courses = []
courseNodes = {}
math_courses= []

class Course:
	def __init__(self, properties):
		self.id 	 = properties['id']
		self.prefix  = properties['prefix']
		self.number  = properties['number']
		self.college = properties['college']
		self.credits = properties['credits']
		self.body  	 = properties['body']
		self.name 	 = properties['name']
		self.prereqs = properties['prereqs']

	@property
	def json(self):	
		if len(self.precedes) == 0:
			# print {"name": course.name}
			return {"name": self.name}

		children = []
		for course in self.precedes:
			children.append(course.json)

		# print {'name': course.name, 'children': children}
		return {'name': self.name, 'children': children}

	@property
	def string(self):
		s = "{}{} - {}".format(self.prefix, self.number, self.name)+'\n'
		print self.prereqs
		for pc in self.prereqs:
			s += '\t'+pc+'\n'
		return s

class Graph:
	def __init__(self, adjList={}):
		self.adjList = adjList

	def addNode(self, Node):
		self.adjList[Node.id] = {
			'node': Node,
			'children': []
		}

	def addEdge(self, edge):
		source, target = edge
		if source in self.adjList and target in self.adjList:
			self.adjList[source]['children'].append(self.adjList[target]['node'])
		else:
			# at the point of entry of some prereqs, those prqs don't exist in the nodelist
			pass

	@property
	def d3_json(self):
	    _ = self.adjList.keys()
	    nodeMap = { _[index]:index for index in range(len(_)) }
	    nodes = []
	    for node in self.adjList.values():
	    	nodeObj = node['node']
	    	nodes.append({
	    		'name': nodeObj.name,
	    		'code': nodeObj.prefix+nodeObj.number
	    	})
	    links = []
	    for nodeList in self.adjList.values():
	    	for node in nodeList['children']:
				links.append({
					"source": nodeMap[nodeList['node'].id],
					"target": nodeMap[node.id]
				})

	    json.dump({
	    	"nodes": nodes,
	    	"links": links
	    }, open('data.json', 'wb'), indent=4)


	def filterCollege(self, college):
		adjList = {}
		for id, nodeList in self.adjList.items():
			node, children = nodeList['node'], nodeList['children']
			if college in node.college:
				adjList[id] = {
					'node': node,
					'children' : [child for child in children if college in child.college]
				}

		return Graph(adjList)

	def bfs(self, start):
	    visited, queue = set(), [start]
	    while queue:
	        vertex = queue.pop(0)
	        if vertex not in visited:
	            visited.add(vertex)
	            queue.extend(graph[vertex] - visited)
	    return visited

def process_courses():
	# to match stuff like this ZOO 5748C COM-BSBS 5(3,2)
	regex = re.compile('(\w{3}) ([0-9]{4}[A-Z]?) (.*(?:\s.*)?) (\d\(\d,\d\))\n?')

	count = 0
	id = 0
	g = Graph()
	with open('course_list.txt', 'r') as f:
		line = f.readline()
		# print line
		while(line is not ''):
			count += 1
			# print count
			properties= {}
			match = regex.match(line)
			if match:
				try:
					(prefix, number, college, credits) = match.group(1,2,3,4)
					properties.update({
						'prefix': prefix,
						'number': number,
						'college': college,
						'credits': credits
						})

					if (prefix+number) not in courseNodes:
						courseNodes[prefix+number] = {
							'id': id,
							'node': Node("Course", name=(prefix+number)),
							'name': prefix+number
						}

						id += 1
				except ValueError:
					print 'error line', line
					print match.group()
					raise Error

				body = ''
				line = f.readline()
				while(not regex.match(line) and line is not ''):
					count +=1
					# print count
					# print line
					if not regex.match(line):
						body += line
					line = f.readline()

				# split into name, prereqs, and description
				res = re.split(':(?:\s)?|\.\s(?=[A-Z])', body)
				if 'PR' in body:
					[name, _, _prereqs] = res[0:3]
					properties['body'] = res[3:]
				else:
					[name, body] = res[0:2]
					_prereqs = 'none'
					properties['body'] = body

				_prereqs = _prereqs.replace('\n', ' ')
				# regex match the course prefx and number
				prereq_matches =  re.compile('(\w{3})\s(?:\s)?([0-9]{4}[A-Z]?)').findall(_prereqs)
				prereqs = map(lambda t: ''.join(list(t)), prereq_matches)

				properties['prereqs'] = prereqs
				properties['name'] = name.replace('\n', ' ')

				properties['id'] = prefix+number

				courseNodes[prefix+number]['name'] = properties['name']

				course = Course(properties)
				courses.append(course)
				g.addNode(course)
				for prq in prereqs:
					g.addEdge([course.id, prq])

				if college == "COS-MATH":
					courseNodes[prefix+number]['group'] = 16
					math_courses.append(Course(properties))
				if "ECS" in college:
					courseNodes[prefix+number]['group'] = 2

			else:
				line = f.readline()

def add2neo(courses):
	authenticate("localhost:7474", 'neo4j', 'admin')
	graph = Graph()
	for course in courses:
		name = course.prefix+course.number

		for pre in course.prereqs:
			print 'adding rel', name, pre
			try:
				graph.create(Relationship(courseNodes[name]['node'], 'REQUIRES', courseNodes[pre]['node']))
			except:
				print 'could not add', name, pre

majors = json.load(open('majors.json', 'rb'))

courseMap = defaultdict(set)

for major, courses in majors.items():
	for course in courses:
		courseMap[course].add(major)

# for k in sorted(courseMap, key=lambda k: len(courseMap[k]), reverse=True):
#         print k, len(courseMap[k])


nodes = []
links = []
majorList = sorted(majors.keys())
nodes += [{'name': major, 'type': 'major'} for major in majorList]
nodes += [{'name': course, 'type': 'course'} for course in courseMap]
for major, courses in majors.items():
	for course in courses:
		links.append({
			'source': majorList.index(major),
			'target': courseMap.keys().index(course)+len(majorList)
		})

json.dump({'nodes': nodes, 'links': links}, open("majorMap.json", 'wb'))

# for course in sorted(math_courses, key=lambda c: c.name):
# 	check = lambda c: c.prefix+c.number in course.prereqs
# 	course.precursors = [c for c in math_courses if check(c)]
# 	# print course.name
# 	# for c in course.precursors:
# 	# 	print "\t"+c.name

# 	check = lambda c: course.prefix+course.number in c.prereqs
# 	course.precedes = [c for c in math_courses if check(c)]
# 	print course.name
# 	for c in course.precedes:
# 		print "\t"+c.name

# COLLECT ZERO TIER COURSES
# these are courses that have no prerequisites
# zero_tier = []
# for course in sorted(math_courses, key=lambda c: c.name):
# 	if len(course.precursors) == 0:
# 		zero_tier.append(course)
# 		# print course.name

# output = []
# for course in zero_tier:
# 	output.append({
# 		"name": course.name,
# 		"children": [course.json]
# 		})

# outputs = json.dumps(output, sort_keys=True, indent=4, separators=(',', ': '))
# print outputs
# with open('output.json', 'w') as out:
# 	out.write(outputs)