fs = require "fs"
_ = require "underscore"
path = require "path"

# Reads an array of files and returning them in order
readFiles = exports.readFiles = (files, callback) ->

  read = (files) ->
    filesLeft = _.size files
    for file, val of files
      do (file) ->
        fs.readFile file, "utf8", (err, code) ->
          throw err if err
          files[file] = code

          filesLeft--
          if filesLeft is 0
            callback null, files
            
  if _.isArray files
    files = toKeys files  
    read files
  else if _.isString files
    dir = path.dirname files
    regex = path.basename files
    regex = regex.replace "*", ".*"
    regex = new RegExp regex

    fs.readdir dir, (err, files) ->
      throw err if err
      files = _(files)
        .filter (file) ->
          regex.test file
        .map (file) ->
          return dir + "/" + file
      files = toKeys files  
      read files

writeFiles = exports.writeFiles = (files, to, callback) ->
  finished = countdown _.size(files)

  for file, code of files
    fs.writeFiles to + file, code, "utf8", (err) ->
      throw err if err
      if finished()
        callback null

# Turns an array into an hashtable adding the array values to value
toValues = exports.toValues = (array, prefix = "") ->
  hash = {}
  for item, i in array
    hash[prefix + i] = item
  
  return hash

# Turns an array into an hashtable adding the array values to keys
toKeys = exports.toKeys = (array, prefix = "") ->
  hash = {}
  
  for item, i in array
    hash[prefix + item] = ""
    
  return hash

# Copies a file from one place to another
copy = exports.copy = (file, to, callback) ->
  fs.readFile file, (err, code) ->
    throw err if err
    filename = path.basename file

    fs.writeFile to + "/" + filename, code, (err) ->
      throw err if err
      callback null

# Pretty elegant counter
countdown = exports.countdown = (length) ->
  left = length
  return ->
    left--
    if left <= 0
      return true
    else
      return false

# Fill an array with a given value
fillArray = exports.fillArray = (length, value) ->
  value for num in [0...length]

mkdir = exports.mkdir = (path) ->
  fs.mkdir path, 0777, (err)

iterator = exports.iterator = (arr, ptr = 0) ->
  {
    array : arr
    pointer : ptr
    length : arr.length
    next : ->
      @pointer++
      if @pointer is @length 
        @pointer = 0
        @array[0]
      else
        @array[@pointer]
    curr : ->
      @array[@pointer]
    reset : ->
      @pointer = 0
  }

# trim = exports.trim =L

module.exports = exports

# console.log fillArray 5, "hi"

# files = 
#   [
#     "./plugin"
#     "./builder"
#     "./middleware"
#   ]
# 
# readFiles files, (err, files) ->
#   console.log files
  
# copy files[0], "./../public/", (err) ->
#   throw err if err
#   console.log "Copied the files"