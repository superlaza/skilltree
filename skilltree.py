import flask
from flask import Flask


app = Flask(__name__)

@app.route("/")
def root():
	return flask.render_template("index.html")

@app.route("/<path:path>")
def send_data(path):
	print path
	return flask.send_from_directory('static', path)

if __name__ == "__main__":
	app.debug = True
	app.run()