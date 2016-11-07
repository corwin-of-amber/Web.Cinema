fs = require 'fs'
osapi = require('opensubtitles-api')
libhash = require('opensubtitles-api/lib/hash')

o = new osapi({useragent: 'Popcorn time v1', username: '', password: '', ssl: false})

#n = parseInt(fs.readFileSync("/tmp/n"))
#block0 = fs.readFileSync("/tmp/block0")
#blockn = fs.readFileSync("/tmp/blockn")

subtitles-hash-minimal = ({size, block0, blockn}) ->
  achk = [size.toString(16), hashBuffer(block0), hashBuffer(blockn)]

  checksum = achk.reduce ((x, y) -> libhash.sumHex64bits x, y) .substr(-16)
  checksum = libhash.padLeft(checksum, '0', 16)

  checksum

#$ ->
#  wlog "hash: #{subtitles-hash-minimal {size: n, block0, blockn}}"


  #checksum = self.sumHex64bits(array_checksum[0], array_checksum[1]);
  #              checksum = self.sumHex64bits(checksum, array_checksum[2]);
  #              checksum = checksum.substr(-16);

login-and-search = (hash) ->
  o.login!
  .catch -> werr "error: #{it}"
  .then ->
    wlog "logged in [token='#{it.token}']"
    search!

hash = 'c91f84bd348be402'# '494fe6666f7424f0'

search = (hash) ->
  o.search {hash}
  .then ->
    wlog "got subtitles #{[k for k of it]}"
    console.log it


export osapi, o, subtitles-hash-minimal, search, login-and-search
