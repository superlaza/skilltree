(function getPDF(){
	var evt = new MouseEvent('click', {
	    'view': window,
	    'bubbles': true,
	    'cancelable': false
	});

	function savePDF(fileURL, fileName) {
	    var save = document.createElement('a');
	    save.href = fileURL;
	    save.target = '_blank';
	    save.download = fileName;
	    save.dispatchEvent(evt);
	    window.URL.revokeObjectURL(save.href);
	}

	var majorTable = document.getElementsByClassName('table')[0].children[1].children;

	for(var i in majorTable){
		var majorRow = majorTable[i];
		if(majorRow.children){
			var pdfURL = majorRow.children[0].children[0].href;
			console.log(pdfURL)
			savePDF(pdfURL, pdfURL.split('/').slice(-1))
		}
	}
})();