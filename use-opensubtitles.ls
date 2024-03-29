fs = require 'fs'
osapi = require('opensubtitles-api')
libhash = require('opensubtitles-api/lib/hash')
subtitles-parser = require('subtitles-parser')
MemoryStream = require('memory-stream')


o = new osapi({useragent: 'Popcorn time v1', username: '', password: '', ssl: false})


subtitles-hash-minimal = ({size, block0, blockn}) ->
  achk = [size.toString(16), hashBuffer(block0), hashBuffer(blockn)]

  checksum = achk.reduce ((x, y) -> libhash.sumHex64bits x, y) .substr(-16)
  checksum = libhash.padLeft(checksum, '0', 16)

  checksum


cached = {}


login-and-search = (hash, filename) ->
  if (v = cached[hash]) then return Promise.resolve(v)
  o.login!
  .catch -> werr "error: #{it}"
  .then ->
    wlog "[opensubtitles] logged in [token='#{it.token}']"
    search hash, filename

search = (hash, filename) ->
  if (v = cached[hash]) then return Promise.resolve(v)
  o.search {hash, filename}
  .catch -> werr "error: #{it}"
  .then -> cached[hash] =
    if [k for k of it].length == 0
      wlog "[opensubtitles] no subtitles"
      void
    else
      wlog "[opensubtitles] got subtitles #{[k for k of it]}"
      console.log it
      it

search-freetext = (query) ->>
  if !o.credentials.status.token then await o.login!
  o.api.SearchSubtitles(o.credentials.status.token, [{query}])

fetch = (subtitles-record, save-as-filename) ->
  $.ajax subtitles-record.url
  .always (res, status) ->
    wlog "[opensubtitles] ajax #{status}"
    if status == 'success'
      res = postprocess res
      fs.writeFileSync(save-as-filename, res)
      wlog "[opensubtitles] fetched as '#{save-as-filename}'"

login-search-and-fetch = (hash, filename, langcode='en', save-as-filename) ->
  login-and-search hash, filename
  .then ->
    if (record = it?[langcode])?
      wlog "[opensubtitles] subtitles['#{langcode}'] = #{JSON.stringify record}"
      fetch record, save-as-filename
    else
      throw new Error("not found")

postprocess = (res) ->
  srt = subtitles-parser.fromSrt res
  srt = apply-filters srt
  subtitles-parser.toSrt srt


_filters = fs.readFileSync("filters.txt", 'utf-8').split("\n")\
           .filter(-> !/^\s*$/.exec(it)).map(-> new RegExp(it))

apply-filters = (srt) ->
  srt.filter (entry) ->
    ! _filters.some (rexp) -> rexp.exec entry.text


readFirstAndLast = (fn) ->
  BLOCK_SIZE = 65536
  result = {}
  new Promise (fulfill, reject) ->
    check = -> if result.block0? && result.blockn? then fulfill result
    rs-block0 = fs.createReadStream(fn, start: 0, end: BLOCK_SIZE - 1)
      block0 = new MemoryStream
      ..pipe block0
      ..on 'end' -> result.block0 = block0.toBuffer! ; console.log result.block0.length ; check!
    fs.stat fn, (err, stat) ->
      console.log err, stat
      if err then werr err ; reject err
      else
        result.size = stat.size
        rs-blockn = fs.createReadStream(fn, start: stat.size - BLOCK_SIZE, end: stat.size - 1)
          blockn = new MemoryStream
          ..pipe blockn
          ..on 'end' -> result.blockn = blockn.toBuffer! ; console.log result.blockn.length ; check!


$ ->
  $ '#local-form #open'
    ..change ->
      fn = @files.0.path
      console.log "[opensubtitles] filename = '#{fn}'"
      readFirstAndLast(fn).then (result) ->
        console.log result
        subhash = OpenSubtitles.hash-minimal result
        wlog "[opensubtitles] subtitle hash = #{subhash}"
        srt = './tmp/subs.srt'
        OpenSubtitles.login-search-and-fetch subhash, fn, 'en', srt
        .catch ->
          console.log "[opensubtitles] #{it}"
    #..prop 'files' files
  $ '#local-form #play' .click ->
    fn = $('#local-form #open').0.files.0.path
    srt = './tmp/subs.srt'
    video-player.play fn, srt


OpenSubtitles = {hash-minimal: subtitles-hash-minimal, search, search-freetext, login-and-search, fetch, login-search-and-fetch}

export OpenSubtitles, o, subtitles-hash-minimal, search, login-and-search
