fs = require 'fs'
osapi = require('opensubtitles-api')
libhash = require('opensubtitles-api/lib/hash')
subtitles-parser = require('subtitles-parser')


o = new osapi({useragent: 'Popcorn time v1', username: '', password: '', ssl: false})


subtitles-hash-minimal = ({size, block0, blockn}) ->
  achk = [size.toString(16), hashBuffer(block0), hashBuffer(blockn)]

  checksum = achk.reduce ((x, y) -> libhash.sumHex64bits x, y) .substr(-16)
  checksum = libhash.padLeft(checksum, '0', 16)

  checksum


login-and-search = (hash) ->
  o.login!
  .catch -> werr "error: #{it}"
  .then ->
    wlog "[opensubtitles] logged in [token='#{it.token}']"
    search hash

hash = 'c91f84bd348be402'# '494fe6666f7424f0'

search = (hash) ->
  o.search {hash}
  .then ->
    if [k for k of it].length == 0
      wlog "[opensubtitles] no subtitles"
      void
    else
      wlog "[opensubtitles] got subtitles #{[k for k of it]}"
      console.log it
      it

fetch = (subtitles-record) ->
  $.ajax subtitles-record.url
  .always (res, status) ->
    wlog "[opensubtitles] ajax #{status}"
    if status == 'success'
      res = postprocess res
      fs.writeFileSync('./tmp/subs.srt', res)

postprocess = (res) ->
  srt = subtitles-parser.fromSrt res
  srt = apply-filters srt
  subtitles-parser.toSrt srt


_filters = fs.readFileSync("filters.txt", 'utf-8').split("\n")\
           .filter(-> !/^\s*$/.exec(it)).map(-> new RegExp(it))

apply-filters = (srt) ->
  srt.filter (entry) ->
    ! _filters.some (rexp) -> rexp.exec entry.text


OpenSubtitles = {search, login-and-search, fetch}

export OpenSubtitles, o, subtitles-hash-minimal, search, login-and-search
