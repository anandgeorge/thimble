
###
  Thimble.coffee boots the middleware
###
_ = require "../node_modules/underscore"
flatten = require "./flatten"
middleware = require "./middleware"
path = require "path"
express = require "express"
fs = require "fs"


exports.boot = (server, options) ->
  root = options.root || './views'
  env = process.env.NODE_ENV || "development"
  
  # Support files
  options.support = options.support || root + '/support'

  # We're rolling our own layout, express's is not necessary
  server.set "view options", layout : false
  server.set "views", options.root

  server.configure "development", ->
      server.use middleware root, options
      server.use (req, res, next) ->
        _render = res.render
        res.render = (view, opts = {}, fn) ->
          res.render = _render
          
          # Add .html if no view extension given
          if !path.extname(view)
            view += ".html"
          
          view = path.join root, view

          if opts.layout
            opts.layout = false

          fs.readFile view, 'utf8', (err, contents) ->
            throw err if err

            flatten.flatten contents, path.dirname(view), options, (err, flattened) ->
              throw err if err
              res.send flattened

        if path.extname req.url is ".html"
          return next()
        else
          server.use express.static root
          return next()
