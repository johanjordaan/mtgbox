config = {}
config.name = 'mtgbox'
config.port = 4010

config.database = {}
config.database.connectionString = 'mongodb://localhost/mtgbox'
config.database.bindings = ['cards','sets','collections']

if module?
  module.exports = config
