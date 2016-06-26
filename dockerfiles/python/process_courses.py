import re, json, operator, os
from py2neo import authenticate, Graph as NeoGraph, Node, Relationship

from collections import defaultdict
from pprint import pprint


from db_settings import config


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

		props = {
			'code': self.prefix+self.number,
			'name': self.name,
			'college': self.college,
			'credits': self.credits,
			'desc': self.body
		}
		self.node = Node("Course", **props)

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

	def addEdge(self, source, target):
		self.adjList[source.id]['children'].append(target)

	def upload(self):
		# url = config['url']
		url = 'http://db:7474'
		user = config['user']
		password = config['password']

		# authenticate(url, user, password)
		graph = NeoGraph("http://{}:{}@db:7474/db/data/".format(user, password))
		# graph = NeoGraph()

		for node_id, props in self.adjList.items():
			course = props['node']
			prereqs  = props['children']

			for prereq in prereqs:
				# print course.node, prereq.node
				try:
					graph.create(Relationship(course.node, 'REQUIRES', prereq.node))
					# graph.create_unique(Relationship(course.node, 'REQUIRES', prereq.node))
				except Exception as e:
					print 'error', e
					print 'could not add', course.name, prereq.name
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
	    }, open(os.path.realpath(os.getcwd()+'/data.json'), 'wb'), indent=4)

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

	def repr(self):
		adjList = {}
		for id, nodeList in self.adjList.items():
			node, children = nodeList['node'], nodeList['children']
			adjList[node.prefix+node.number] = {
				'name': node.name,
				'prereqs': [child.prefix+child.number for child in children]
			}

		return adjList

# returns graph object
def extract_courses():
	courses = {}
	# to match stuff like this ZOO 5748C COM-BSBS 5(3,2)
	regex = re.compile('(\w{3}) ([0-9]{4}[A-Z]?) (.*(?:\s.*)?) (\d\(\d,\d\))\n?')

	def get_init_props(line):
		match = regex.match(line)
		if match:
			try:
				(prefix, number, college, credits) = match.group(1,2,3,4)
				
				return {
					'id': prefix+number,
					'prefix': prefix,
					'number': number,
					'college': college,
					'credits': credits
				}

			except ValueError:
				print 'error line', line
				print match.group()
				return {}

	def get_body(file):
		body = ''
		line = courses_file.readline()
		while(not regex.match(line) and line != ''):
			if not regex.match(line):
				body += line
			line = courses_file.readline()
		return body, line

	def separate_body(_body):
		# split into name, prereqs, and description
		res = re.split(':(?:\s)?|\.\s(?=[A-Z])', _body)
		if 'PR' in _body:
			[name, _, _prereqs] = res[0:3]
			body = res[3:]
		else:
			# print res[0:2], _body
			[name, body] = res[0:2]
			_prereqs = 'none'

		_prereqs = _prereqs.replace('\n', ' ')
		# regex match the course prefx and number
		prereq_matches =  re.compile('(\w{3})\s(?:\s)?([0-9]{4}[A-Z]?)').findall(_prereqs)
		prereqs = map(lambda t: ''.join(list(t)), prereq_matches)

		return body, name, prereqs
	
	with open(os.path.realpath(os.getcwd()+'/course_list.txt'), 'r') as courses_file:
		line = courses_file.readline()
		# print line
		while(line!=''):
			props= {}
			props = get_init_props(line)
			if props:
				
				body, line = get_body(file)

				# print props
				body, name, prereqs = separate_body(body)

				props['name'] = name.replace('\n', ' ')
				props['prereqs'] = prereqs
				props['body']= body

				# courseNodes[props['id']]['name'] = props['name']

				courses[props['id']] = Course(props)

				
			else:
				line = courses_file.readline()

		return courses

def build_graph(courses):
	missing_prereqs= 0
	g =	Graph()
	for course in courses.values():
		g.addNode(course)
		for prereq_id in course.prereqs:
			if prereq_id in courses:
				g.addEdge(course, courses[prereq_id])
			else:
				missing_prereqs += 1
	print 'missing prereqs:', missing_prereqs
	return g

print 'extracting courses...'
courses = extract_courses()
print 'building graph...'
graph = build_graph(courses)
print 'uploading graph...'
graph.upload()

def major_data():
	majors = json.load(open(os.path.realpath(os.getcwd()+'/majors.json'), 'rb'))

	maj_similarity = defaultdict(dict)
	majorList = sorted(majors.keys())
	max_sim = 0
	for i in range(len(majorList)):
		maj1 = set(majors[majorList[i]])
		for j in range(i, len(majorList)):
			maj2 = set(majors[majorList[j]])

			simil = len(maj1.intersection(maj2))
			if simil > max_sim:
				max_sim = simil
			maj_similarity[majorList[i]][majorList[j]] = simil
			maj_similarity[majorList[j]][majorList[i]] = simil

	for maj1, majs in maj_similarity.items():
		for maj2 in majs:
			majs[maj2] = (majs[maj2]+1)/float(max_sim)

	pprint(dict(maj_similarity), indent=4)


	majors = {k:majors[k] for k in majors.keys()[:int(len(majors.keys())/1)]}

	courseMap = defaultdict(set)

	for major, courses in majors.items():
		for course in courses:
			courseMap[course].add(major)

	# sort course by number of majors it appears in
	# for k in sorted(courseMap, key=lambda k: len(courseMap[k]), reverse=True):
	# 	print k, len(courseMap[k])

	nodes = []
	links = []
	nodes += [{'name': major, 'type': 'major'} for major in majorList]
	# nodes += [{'name': course, 'type': 'course', 'size': len(courseMap[course])} for course in courseMap]
	# for major, courses in majors.items():
	# 	for course in courses:
	# 		links.append({
	# 			'source': majorList.index(major),
	# 			'target': courseMap.keys().index(course)+len(majorList),
	# 		})

	for i in range(len(majorList)):
		maj1 = majorList[i]
		for j in range(i, len(majorList)):
			maj2 = majorList[j]
			if not (maj1 == maj2):
				if maj_similarity[maj1][maj2] > 0.1:
					links.append({
						'source': majorList.index(maj1),
						'target': majorList.index(maj2),
						'strength': maj_similarity[maj1][maj2]
					})

	json.dump({'nodes': nodes, 'links': links}, open(os.path.realpath(os.getcwd()+'/majorMap.json'), 'wb'), indent=4)


	# print [(i, nodes[i]['name']) for i in range(len(nodes))]
	print links

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