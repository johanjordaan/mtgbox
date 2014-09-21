fs = require 'fs'
async = require 'async'
_ = require 'prelude-ls'

express = require 'express'
bodyParser = require 'body-parser'
app = express()

config = require './config'


# Configure express
app.use bodyParser.json()
app.use '/',express.static(__dirname + '/client')

server = (require 'http').createServer app

######## DB Initialisation
mongo = require 'mongoskin'
ObjectID = require('mongoskin').ObjectID
db = mongo.db config.database.connectionString, {native_parser:true}
for binding in config.database.bindings
  db.bind binding


server.listen config.port, ->
  console.log "server [#{config.name}] listening on port - Listening on port [#{config.port}]"


app.get '/api/v1/cards', (req,res) ->
  db.cards.findItems {}, { _id:0 , name:1, setCode:1, setName:1, multiverseid:1 }, (err,cards) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send cards

app.get '/api/v1/sets', (req,res) ->
  db.sets.findItems {},{_id:0, name:1, code:1}, (err,sets) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send sets

app.get '/api/v1/collections', (req, res) ->
  user = 'johan'

  db.collections.findItems { user:user }, { _id:0, user:0 } (err,cards) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send cards


app.post '/api/v1/collections/', (req, res) ->
  user = 'johan'
  multiverseid = req.body.multiverseid
  delta = req.body.delta
  if !delta? then delta = 0
  fdelta = req.body.fdelta
  if !fdelta? then fdelta = 0


  console.log req.body

  switch !cardMultiverseid?
    | false => res.status(400).send { message:'multiverseid must be supplied' }
    | otherwise =>

      db.collections.update { multiverseid: multiverseid , user: user }
      , { '$inc' : { count: delta, fcount: fdelta } }
      , { upsert: true }
      , (err,) ->
        | err? => res.status(500).send { message: err }
        | otherwise => res.status(200).send ''
