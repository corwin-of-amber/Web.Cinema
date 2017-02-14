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
  vid = '/Users/corwin/Downloads/Mr.Robot.Season.1.720p.BluRay.x264.ShAaNiG/Mr.Robot.S01E01.720p.BluRay.x264.ShAaNiG.mkv'
  files = new FileList
    ..append new File vid, vid
  $ '#upload-form #open'
    ..change ->
      fn = @files.0.path
      console.log "[opensubtitles] filename = '#{fn}'"
      readFirstAndLast(fn).then (result) ->
        console.log result
        subhash = OpenSubtitles.hash-minimal result
        wlog "[opensubtitles] subtitle hash = #{subhash}"
        OpenSubtitles.login-and-search subhash
        .then ->
          wlog "[opensubtitles] #{vid.name}: subtitles['en'] = #{JSON.stringify it?.en}"
          if it?.en?
            OpenSubtitles.fetch it.en
            .then ->
              srt = './tmp/subs.srt'
              wlog "[opensubtitles] downloaded '#srt'"
    #..prop 'files' files


OpenSubtitles = {hash-minimal: subtitles-hash-minimal, search, login-and-search, fetch}

export OpenSubtitles, o, subtitles-hash-minimal, search, login-and-search
