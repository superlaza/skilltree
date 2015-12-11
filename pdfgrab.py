import re, json
from py2neo import authenticate, Graph, Node, Relationship

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

	precursors = []
	precedes = []

	def __init__(self, properties):
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

# to match stuff like this ZOO 5748C COM-BSBS 5(3,2)
regex = re.compile('(\w{3}) ([0-9]{4}[A-Z]?) (.*(?:\s.*)?) (\d\(\d,\d\))\n?')

count = 0
with open('courses.txt', 'r') as f:
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

				courseNodes[prefix+number] = Node("Course", name=(prefix+number))
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
			# print name, len(prereqs), prereqs
			# if len(prereqs) == 0:
			# 	print repr(_prereqs)

			# if 'Calculus' in name:
			# 	# print repr(_prereqs)
			# 	# print prereq_matches

			properties['prereqs'] = prereqs
			properties['name'] = name.replace('\n', ' ')

			courses.append(Course(properties))
			if college == "COS-MATH":
				math_courses.append(Course(properties))

		else:
			line = f.readline()

authenticate("localhost:7474", 'neo4j', 'admin')
graph = Graph()

for course in courses:
	name = course.prefix+course.number

	for pre in course.prereqs:
		print 'adding rel', name, pre
		try:
			graph.create(Relationship(courseNodes[name], 'REQUIRES', courseNodes[pre]))
		except:
			print 'could not add', name, pre


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

print 'BREAK!'
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