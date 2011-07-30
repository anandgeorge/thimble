EventEmitter = require("events").EventEmitter
_ = require "underscore"
emitters = {}
fs = require "fs"
path = require "path"
lib = __dirname
jsdom = require "jsdom"
patcher = require lib + "/patcher.coffee"
parserPath = lib + "/parsers"
utils = require lib + "/utils.coffee"

# Patch jsdom to work with certain html5 tags
jsdom = patcher.patch jsdom

$ = require "jquery"

assetTypes = 
  js : "script"
  css : "link"
  images : "img"

class Builder
  
  constructor : (@file, @public, @options = {}) ->
    @directory = path.dirname file
    @emitter = new EventEmitter()
    @root = if options.root then file else false    

  build : (callback) ->
    emitter = @emitter
    
    emitter.once "read", (code) =>
      @document = jsdom code
      @flatten @document, @directory, emitter
      
    emitter.once "flattened", () =>
      @bundle emitter
    
    emitter.once "bundled", ()->
      emitter.emit "built"
    
    emitter.once "built", =>
      callback null, @document.innerHTML
      
    @read @file
  
  read : (file) ->
    fs.readFile file, "utf8", (err, code) =>
      throw err if err
      @emitter.emit "read", code
  
  # Flatten code by finding all the embeds and replacing them
  flatten : (document, directory, emitter) ->
    builder = this
    CommentParser = require(parserPath + "/comments.coffee")
    parser = new CommentParser(@document, @directory)
    
    parser.parse @document, @directory, (document) ->
      emitter.emit "flattened"
  
  # Pull in all the assets and parse them
  bundle : (emitter) ->
    document = @document
    finished = utils.countdown _.size(assetTypes)
    
    callback = (err) =>
      throw err if err
      
      if finished()
        emitter.emit "bundled"
    
    for type, tag of assetTypes
      elements = $(tag, document).get()
      
      if elements.length is 0
        if finished()
          emitter.emit "bundled"
          return
        else
          continue
      
      parser = require parserPath + "/#{type}.coffee"
      parser.build elements, @public, @directory, callback


module.exports = Builder
