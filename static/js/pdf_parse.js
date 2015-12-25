var currPage;
var numPages = 0;
var _pdf = null;

var flag = false;
var majors = {}
var currMajor = null;

function processPage(page){
	page.getTextContent().then(
		function(content){
			for(var i in content.items){
				var line = content.items[i];
				if(line.str.indexOf('GEP') != -1) flag = true;
				if(line.str.indexOf('Plan of Study') != -1) flag = false;
				
				console.log(line.str)
				if(flag){
					var matches = line.str.match(/([A-Z]){3}\s\d{4}([A-Z])*/g);
					if(matches){
						for(var j in matches){
							if(majors[currMajor].indexOf(matches[j]) == -1){
								majors[currMajor].push(matches[j].replace(' ', ''));
							}
						}
					}
				}
			}

			++currPage;
			if(_pdf !== null && currPage <= numPages){
				_pdf.getPage(currPage).then(processPage);
			}
		}
	);
}

function getPDFContents(fileName){
	PDFJS.getDocument(fileName).then(
		function(pdf){

			_pdf = pdf;
			numPages = pdf.numPages;
			currPage = 1;

			// strip subdirs and degree type
			currMajor = fileName.split('/').slice(-1)[0].split('_').slice(0,-1).join(' ');
			majors[currMajor] = [];

			flag = false;
			pdf.getPage(currPage).then(processPage);
		}
	);
}

getPDFContents('Majors/Accounting_BSBA.pdf');
