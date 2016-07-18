# docker run -ti --rm -v ~/projects/skilltree/data:/pdf bwits/pdf2htmlex pdf2htmlEX courses.pdf
from pyquery import PyQuery as pq
import lxml

d = pq(filename='major.html')

p = d('body')
q = d('div.t')

print len(q)
for r in q:
	# print r.text
	# print dir(r)
	# print type(r.text_content())
	# if type(r.text_content())== lxml.etree._ElementStringResult:
	print r.text_content()