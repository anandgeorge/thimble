lib = "#{__dirname}/.."
EventEmitter = require("events").EventEmitter
emitter = new EventEmitter()

build = exports.build = (assets, public, callback) ->
  
  emitter.once "read", (files) ->
    

read = exports.read = (files, emitter)
  
module.exports = exports
