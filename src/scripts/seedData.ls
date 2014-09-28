_ = require 'prelude-ls'
fs  = require 'fs'
zlib  = require 'zlib'
exec = require('child_process').exec
async = require 'async'

mongo = require('mongoskin')
ObjectID = require('mongoskin').ObjectID
db_name = "mongodb://localhost/mtgbox"
db = mongo.db db_name, {native_parser:true}
db.bind 'cards'
db.bind 'sets'

saveSet = (set,cb) ->
  newSet =
    name: set.name
    code: set.code
    releaseDate: set.releaseDate
    border: set.border
    type: set.type
    numCards: set.cards.length

  db.sets.save newSet, (err) ->
    | err? => cb(err,newSet.name)
    | otherwise => cb(null,newSet.name)


saveCard = (card,set,cb) ->
  if card.power? then card.pt = "#{card.power}/#{card.toughness}"
  if card.colors? then card.color = _.join " ",card.colors
  card.setCode = set.code
  card.setName = set.name
  # If the mid does not exist then create one
  #
  switch card.multiverseid?
  | true => card.mid = card.multiverseid
  | otherwise => card.mid = "#{card.setCode}_#{card.number}"

  db.cards.save card, (err) ->
    | err? => cb(err,card.name)
    | otherwise => cb(null,card.name)


console.log 'Unzipping ...'
exec "unzip -o data/AllSets.json.zip -d data < /dev/tty",(err,stdout,stderr) ->
  | err? => console.log err
  | otherwise =>
    console.log 'Unzipping [Done]'
    console.log 'Reading sets ...'
    fs.readFile 'data/AllSets.json', 'utf8', (err, data) ->
      | err? => console.log err
      | otherwise =>
        sets = JSON.parse(data)
        setCount = _.keys(sets).length
        console.log "Reading sets [Done]"

        # Clean the db
        #
        db.cards.remove { },(err,writeResult) ->
          | err? => console.log err
          | otherwise =>

            db.sets.remove { },(err,writeResult) ->
              | err? => console.log err
              | otherwise =>


                inserts = []
                cardCount = 0
                # Import the sets and cards
                #
                sets |> _.values |> _.each (set) ->
                  inserts.push (cb) ->
                    saveSet(set,cb)
                  set.cards |> _.each (card) ->
                    cardCount += 1
                    inserts.push (cb) ->
                      saveCard(card,set,cb)


                console.log "Writing [#{setCount}] sets and [#{cardCount}] cards ..."
                async.parallel inserts, (err,results) ->
                  | err? => console.log err
                  | otherwise => #console.log results
                  console.log "Writing sets and cards [Done]"
                  db.close!


                console.log 'Cleaning up ...'
                exec 'rm data/AllSets.json < /dev/tty', (err,stdout,stderr) ->
                  console.log 'Cleanup [Done]',err
