// Generated by CoffeeScript 1.10.0
(function() {
  var Router, app, cola, express, falcorExpress, graphData, server;

  express = require('express');

  falcorExpress = require('falcor-express');

  Router = require('falcor-router');

  cola = require('webcola');

  graphData = require('../../data/courseAdjList.json');

  console.log(typeof (JSON.stringify(graphData)));

  app = express();

  app.use('/model.json', falcorExpress.dataSourceRoute(function(req, res) {
    return new Router([
      {
        route: "graph",
        get: function() {
          return {
            path: ['graph'],
            value: JSON.stringify(graphData)
          };
        }
      }
    ]);
  }));

  app.use(express["static"]('static'));

  app.use(express["static"]('data'));

  server = app.listen(process.env.PORT || 3000, function() {
    var host, port;
    host = server.address().address;
    port = server.address().port;
    console.log('Example app listening at http://%s:%s', host, port);
  });

}).call(this);
