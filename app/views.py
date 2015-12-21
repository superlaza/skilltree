from django.http import HttpResponse
from django.template import RequestContext, loader, Context
import json

def index(request):
	template = loader.get_template('app/index.html')
	return HttpResponse(template.render(Context({})))

def data(request, filename):
	json_data = open(r'C:\Projects\skilltree\skilltree\app\templates\app\data.json')
	return HttpResponse(json.dumps(json.load(json_data)))