path    = require "path"
args    = require("optimist").argv
action  = args._[0]
param = args._[1]
delete args._
delete args.$0
options = args

build   = require "./builder"
fs      = require "fs"

# Command line options
switch action
  when "server", "serve"
    if !options[0]
      console.error "Need to specify a directory to serve from (eg. /ui)"
      process.exit 1
    serverDir = path.resolve param
    serverPort = options[1] or 8080
    server = require "./server"
    server.serve(serverDir, serverPort)
  
  when "build"
    appPath = path.resolve param or "."
    publicDir = options.public or "./public"

    builder = new build(appPath, publicDir, options)
    builder.build (err, html) ->
      throw err if err
      fs.writeFile publicDir + "/build.html", html, "utf8", (err) ->
        throw err if err
        console.log "Successfully built #{appPath}"
