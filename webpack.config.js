path = require('path');
LiveReloadPlugin = require('webpack-livereload-plugin');
wp = require('webpack');

module.exports = {
    context: path.join(__dirname, 'src'),
    entry: {
        app: "./main.coffee",
        vendor: ['react', 'd3']
    },
    output: {
        path: path.join(__dirname, 'static'),
        filename: "bundle.js"
    },
    module: {
        loaders: [
            {test: /\.jsx$/, loader: "jsx-loader?insertPragma=React.DOM"},
            {test: /\.cjsx$/, loaders: ["coffee", "cjsx"]},
            {test: /\.coffee$/, loader: "coffee"}
        ]
    },
    plugins: [
        new wp.optimize.CommonsChunkPlugin(
            "vendor", 
            "vendor.bundle.js"
        ),
        new LiveReloadPlugin(
            {
                'appendScriptTag': true
            }
        )
    ]
};