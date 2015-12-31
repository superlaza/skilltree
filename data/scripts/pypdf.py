from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfpage import PDFPage
from cStringIO import StringIO

import re, json, os
from collections import defaultdict

def convert_pdf2txt(path):
    rsrcmgr = PDFResourceManager()
    retstr = StringIO()
    codec = 'utf-8'
    laparams = LAParams()
    device = TextConverter(rsrcmgr, retstr, codec=codec, laparams=laparams)
    fp = file(path, 'rb')
    interpreter = PDFPageInterpreter(rsrcmgr, device)
    maxpages = 0
    caching = True
    pagenos=set()

    for page in PDFPage.get_pages(fp, pagenos, maxpages=maxpages,caching=caching, check_extractable=True):
        interpreter.process_page(page)

    text = retstr.getvalue()

    fp.close()
    device.close()
    retstr.close()
    return text


majors = {}

def getMajor(fileName):
    majorName = ' '.join(fileName[:-4].split('/')[-1].split('_')[:-1])
    majors[majorName] = set()

    s = convert_pdf2txt(fileName)

    flag = False
    for line in s.split('\n'):
        if 'GEP' in line:
            flag = True
        if 'Plan of Study' in line:
            flag = False

        if flag:
            matches = re.findall('([A-Z]{3}\s\d{4}[A-Z]*)', line)

            if matches:
                for match in matches:
                    majors[majorName].add(match.replace(' ', ''))

for subdir, dirs, files in os.walk('./../majors/pdf'):
    for pdf in files:
        getMajor('{}/{}'.format(subdir, pdf))

json.dump({k:list(v) for k,v in majors.items()}, open('../majors.json', 'wb'), indent=4)