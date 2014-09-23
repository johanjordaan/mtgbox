# Copy this file to sconfig.ls and replace the relavent fields with their
# actual values
#

sconfig = {}

sconfig.facebook = {}
sconfig.facebook.clientId = 'YOUR FACEBOOK APP CLIENT ID'
sconfig.facebook.clientSecret = 'YOUR FACEBOOK APP SECRET'

if module?
  module.exports = sconfig
