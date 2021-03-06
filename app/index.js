// Generated by CoffeeScript 1.10.0
(function() {
  var Router, app, cola, db, env, express, falcorExpress, fs, graphData, host, majorData, neo4j, pw, ref, server, user;

  fs = require('fs');

  express = require('express');

  falcorExpress = require('falcor-express');

  Router = require('falcor-router');

  cola = require('webcola');

  neo4j = require('neo4j');

  graphData = require('../data/majorMap.json');

  graphData = require('../data/colatest.json');

  graphData = require('../data/courseAdjList.json');

  majorData = require('../data/majors/json/anthropology.json');

  ref = JSON.parse(fs.readFileSync('./app/config.cfg').toString()), user = ref.user, pw = ref.pw;

  env = 'docker';

  app = express();

  host = env === 'dev' ? 'localhost' : 'db';

  console.log("http://" + user + ":" + pw + "@" + host + ":7474");

  db = new neo4j.GraphDatabase("http://" + user + ":" + pw + "@" + host + ":7474");

  app.use('/model.json', function(req, res) {
    var callback, filterLink, filterNode, getCourses, getPrereqs;
    callback = function(err, results) {};
    filterNode = "where course.college='COS-MATH'";
    filterLink = "where source.college='COS-MATH' and target.college='COS-MATH'";
    getCourses = new Promise(function(resolve, reject) {
      return db.cypher({
        query: "MATCH (course:Course) " + filterNode + " RETURN course",
        params: {}
      }, (function(_this) {
        return function(err, results) {
          var result;
          if (err) {
            throw err;
          }
          result = results[0];
          if (!result) {
            return console.log('No results.');
          } else {
            results = results.map(function(res) {
              return res.course.properties;
            });
            return resolve(results);
          }
        };
      })(this));
    });
    getPrereqs = new Promise(function(resolve, reject) {
      return db.cypher({
        query: "MATCH p=(source)-[r:REQUIRES]->(target) " + filterLink + " RETURN source.code as source, target.code as target",
        params: {}
      }, (function(_this) {
        return function(err, results) {
          var result;
          if (err) {
            throw err;
          }
          result = results[0];
          if (!result) {
            return console.log('No results.');
          } else {
            console.log(results);
            return resolve(results);
          }
        };
      })(this));
    });
    return Promise.all([getCourses, getPrereqs]).then(function(data) {
      return res.end(JSON.stringify({
        'nodes': data[0],
        'links': data[1]
      }));
    });
  });

  app.use(express["static"]('static'));

  app.use(express["static"]('data'));

  server = app.listen(process.env.PORT || 3000, function() {
    var port;
    host = server.address().address;
    port = server.address().port;
    console.log('Example app listening at http://%s:%s', host, port);
  });

}).call(this);
