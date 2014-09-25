# This script loads data from a lagacy sqlite database and pushes them into a csv file
#
_ = require 'prelude-ls'
fs = require 'fs'

sqlite3 = require('sqlite3').verbose()
db = new sqlite3.Database('./data/collections.s3db');


rows  = ''
count = 0
db.serialize ->
  db.each "SELECT * FROM collectioncards", (err, row) ->
    count += 1

    switch row.setname
    | 'Ravnica City of Guilds' => row.setname = 'Ravnica: City of Guilds'
    | otherwise =>

    rows += "\"#{count}\",\"#{row.setname}\",\"#{row.cardname}\",\"#{row.cnt}\",\"#{row.fcnt}\"\n"

db.close ->
  fs.writeFile './data/takeon.csv',rows,'utf8',(err) ->
    console.log 'Done'
