fs = require 'fs'
async = require 'async'
_ = require 'prelude-ls'
crypto = require 'crypto'
request = require 'request'
querystring = require 'querystring'


express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
app = express()

config = require './config'
sconfig = require './sconfig'


# Configure express
app.use cookieParser('xxx')
app.use bodyParser.json()
app.use '/',express.static(__dirname + '/client')

server = (require 'http').createServer app

######## DB Initialisation
mongo = require 'mongoskin'
ObjectID = require('mongoskin').ObjectID
db = mongo.db config.database.connectionString, {native_parser:true}
for binding in config.database.bindings
  db.bind binding

## Get the facbook access token
accessToken = ''
request "https://graph.facebook.com/oauth/access_token?client_id=#{sconfig.facebook.clientId}&client_secret=#{sconfig.facebook.clientSecret}&grant_type=client_credentials"
, (err, fbRes, body) ->
  accessToken := querystring.parse(body).access_token


server.listen config.port, ->
  console.log "server [#{config.name}] listening on port - Listening on port [#{config.port}]"

authFilter = (req,res,next) ->
  key = "fbsr_#{sconfig.facebook.clientId}"
  cookie = req.cookies[key]
  switch cookie?
  | false => res.status(401).send { message: "User not autherised"}
  | otherwise =>
    parts = cookie.split('.')
    signature = parts[0]
    jsonData = JSON.parse(new Buffer(parts[1],'base64').toString())
    computedSignature = crypto
      .createHmac('SHA256', sconfig.facebook.clientSecret)
      .update(parts[1])
      .digest('base64')
      .replace(/[=]/g,'')
      .replace(/[/]/g, '_')
      .replace(/[+]/g, '-')

    switch computedSignature == signature
    | false => res.status(401).send { message: "User not autherised"}
    | otherwise =>
      db.users.findOne { facebookId: jsonData.user_id }, (err,user) ->
        | err? => res.status(500).send err
        | user? =>
          req.user = user
          next!
        | otherwise =>
          request "https://graph.facebook.com/v2.1/#{jsonData.user_id}?access_token=#{accessToken}"
          , (err, fbRes, body) ->
            ##{"id":"10153627538842619","email":"djjordaan\u0040gmail.com","first_name":"Johan","gender":"male","last_name":"Jordaan","link":"https:\/\/www.facebook.com\/app_scoped_user_id\/10153627538842619\/","locale":"en_US","name":"Johan Jordaan"}
            details = JSON.parse(body)
            user = { facebookId: jsonData.user_id, firstName: details.first_name, surname: details.last_name, name: details.name, email: details.email }
            db.users.save user, (err) ->
              | err? => res.status(500).send err
              | otherwise =>
                db.users.findOne user, (err,user) ->
                  | err? => res.status(500).send err
                  | otherwise =>
                    req.user = user
                    next!


app.get '/api/v1/sets', (req,res) ->
  db.sets.findItems {},{_id:0, name:1, code:1}, (err,sets) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send sets

app.get '/api/v1/cards', (req,res) ->
  db.cards.findItems {}, { _id:0 , name:1, setCode:1, mid:1 }, (err,cards) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send cards

app.get '/api/v1/collections', authFilter, (req, res) ->

  db.collections.findItems { user: req.user._id }, { _id:0, user:0 } (err,cards) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send cards


app.post '/api/v1/collections/', authFilter, (req, res) ->
  mid = req.body.mid
  delta = req.body.delta
  if !delta? then delta = 0
  fdelta = req.body.fdelta
  if !fdelta? then fdelta = 0

  switch !cardMultiverseid?
    | false => res.status(400).send { message:'multiverseid must be supplied' }
    | otherwise =>

      db.collections.update { mid: mid , user: req.user._id }
      , { '$inc' : { count: delta, fcount: fdelta } }
      , { upsert: true }
      , (err,) ->
        | err? => res.status(500).send { message: err }
        | otherwise => res.status(200).send ''




app.post '/api/v1/authenticate',authFilter, (req, res) ->
  console.log req.user
  res.status(200).send req.user
