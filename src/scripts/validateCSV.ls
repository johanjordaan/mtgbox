_ = require 'prelude-ls'
fs  = require 'fs'
config = require '../config'

mongo = require('mongoskin')
ObjectID = require('mongoskin').ObjectID

db = mongo.db config.database.connectionString, {native_parser:true}
for binding in config.database.bindings
  db.bind binding

async = require 'async'

validateItem = (setName,cardName,cb) ->
  db.sets.findOne { name:setName }, (err,set) ->
    | err? => console.log err
    | !set? =>
      console.log "Cannot find set : [#{setName}]"
      cb(true,null)
    | otherwise =>
      db.cards.findItems { name:cardName, setName:setName}, (err,cards) ->
        | err? => console.log err
        | !cards? =>
          console.log "Cannot find card : [#{cardName}]"
          cb(true,null)
        | otherwise =>
          if cards.length>1
            console.log "[#{cardName}]-[#{setName}] has [#{cards.length}] versions..."
          cb(null,null)

validations = []
fs.readFile "./data/takeon.csv",'utf8',(err,data) ->
  | err? => console.log err
  | otherwise =>
    lines = data.split('\n')

    lines |> _.each (line) ->
      if line.length>0
        tokens = line.split(',')
        validations.push (cb) ->
          validateItem tokens[1], tokens[2], cb

    async.parallel validations, (err,results) ->
      | err? => console.log err
      | otherwise =>
      db.close!
