fs = require "fs"
path = require "path"

_ = require 'underscore'

thimble = require "./thimble"

###
  Public: starts thimble and configures our server
  
  app - the server we created in express -- ie. app = express.createServer()
###
start = exports.start = (app) ->
  server = require "./server"
  server.boot.call this, app

###
  Public: configure the application for zero or more callbacks.
  When there is no environment present, it will be invoked for
  all the environments. Any combination can be used multiple
  times and in any order.
  
  env, ... - a splat of String environments to run this configuration on
  fn - configuration Function to invoke when environment is
  
  Examples
  
    t.configure(function(){
      // executed for all envs
    });

    t.configure('stage', function(){
      // executed staging env
    });

    t.configure('stage', 'production', function(){
      // executed for stage and production
    });
  
  Returns an instance of the thimble Object
###

configure = exports.configure = (env, fn) ->
  envs = "all"
  args = [].slice.call(arguments)
  fn = args.pop()
  
  envs = args if args.length
  if "all" is envs or ~envs.indexOf(this.settings.env)
    fn.call this
  
  return this

###
  Public: Get and set setting variables
###
set = exports.set = (setting, value) ->
  if !value
    return this.settings[setting]
  else
    this.settings[setting] = value
    return this
    
###
  Public: plug in the plugins that will be called as the content moves
    through the layers. Can be chained.
  
  fn - a plugin Function
  
  Examples
  
    t.use(thimble.focus());
    
    t.use(thimble.bundle('./public'))
  
  Returns an instance of the thimble Object
###
use = exports.use = (fn) ->
  this.stack.push fn
  return this

###
  Public: renders the application
  
  file - a String that is the main entry point into our application
  locals - a local variable Object containing parameters to pass through
    to the templates. Locals may contain a `layout` key, which will use the 
    value as a base layout
  fn - a callback Function invoked when render completes. First parameter is
    an `err` variable, second is the content. 
    
  Examples
    
    t.render("app.html", { planet : "world" }, function(err, content) {
      if(err) throw err;
      // Content is here.
    });
    
  
###
render = exports.render = (file, locals = {}, fn) ->
  self = this

  # Allow fn to be passed as the 2nd param
  if('function' is typeof locals)
    fn = locals
    locals = {}

  # Add settings and other params to options object
  options = _.extend self.settings,
    source : file
    locals : locals

  # If theres a layout, add the layout plugin
  if locals.layout
    # Instantiate plugin-specific options
    options.layout = 
      source : locals.layout
    # Add to the top of the stack
    self.stack.unshift thimble.layout(locals.layout)
  
    
  fs.readFile file, "utf8", (err, content) ->
    return fn(err) if err
    
    handle.call self, content, options, (err, output) ->
      return fn(err, output)
  
###
  Private: Handle the plugin layers
  
###
handle = (content, options, out) ->
  stack = this.stack
  index = 0
  
  next = (err, content) ->
    # Next callback
    layer = stack[index++]

    # all done
    if (!layer)
      if out then return out(err, content)

    # Plugin punting
    try
      arity = layer.length
      if err
        # Give the middleware a chance to catch it
        if arity is 4
          layer(err, content, options, next)
        else
          next(err)
      else if arity < 4
        layer(content, options, next)
      else
        next()
    catch e
      next(e)
      
  next(null, content)

module.exports = exports