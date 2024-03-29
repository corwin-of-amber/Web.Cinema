WebTorrent = require('webtorrent')
MemoryStream = require('memory-stream')  # I also tried memory-streams but it didn't work well
parse-torrent = require('parse-torrent')
fs = require('fs')
child_process = require('child_process')
path = require('path')
file-size = require('file-size')


client = void

get-client = ->
  client ? (client := do ->
    new WebTorrent({})
      ..on 'error' (err) -> werr (err.message || err)
      window.client = ..
      window.addEventListener 'unload' -> ..destroy!
  )


runDownload = (torrentId, options={}) ->

  client = get-client!

  client.dht?._tables.clear!  # seems needed when removing and re-adding the same torrent.
                              # bug in webtorrent?

  torrent = client.add torrentId, {path: "/tmp/Web.Cinema"}

  torrent.options = {} <<<< DEFAULT_OPTIONS <<<< options

  torrent.on 'infoHash' !->
    wlog "[torrent] infoHash"
    #torrent.on 'wire' !-> wlog "[torrent] wire"

  torrent.on 'metadata' !->
    wlog "[torrent] #{torrent.numPeers} peers"
    #for f in torrent.files
    #  wlog "[torrent] #{f.name} (#{f.length})"
    $ '#file-select'
      ..empty!
      for fn in torrent.files.map (.name) .sort!
        ..append ($ '<option>' .text fn)
      if torrent.options.selected-filename?
        ..val torrent.options.selected-filename
      else if (vid = find-video-file torrent)?
        ..val vid.name
    if torrent.options.metadata-only
      client.remove torrentId
    else if torrent.options.selected-filename != '*'
      torrent.deselect(0, torrent.pieces.length - 1, false)  # download nothing yet!
      # see https://github.com/feross/webtorrent/issues/164
      torrent.vid = find-file-by-name(torrent, torrent.options.selected-filename) || \
                    find-video-file(torrent)
      progress!
    else
      torrent.vid = void

  torrent.once 'ready' !->
    wlog "[torrent] ready (#{torrent.numPeers} peers)"
    if torrent.options.metadata-only
      client.remove torrentId
    else
      progress!
      vid = torrent.vid
      if vid?
        out = {subs: path.join(torrent.path, 'stream.srt'), \
               video: path.join(torrent.path, 'stream')}  # @@@ hard-coded

        torrent.video-filename = out.video

        #torrent.vid = vid
        if torrent.options.search-subtitles
          readFirstAndLastBlocks vid .then (result) ->
            console.log result
            #if torrent.options.first-and-last-only
            #  client.remove torrentId
            subhash = subtitles-hash-minimal result
            wlog "[torrent] subtitle hash = #{subhash}"

            OpenSubtitles.login-search-and-fetch subhash, vid.name, 'en', out.subs
            .then ->
              torrent.subtitles-filename = out.subs
            .finally ->
              torrent.subtitles-thread-done = true
              check-if-ready-to-play!

        if !torrent.options.first-and-last-only
          start!
          check-if-ready-to-play!

      #setTimeout (-> if client.get torrentId then client.remove torrentId), 10000

  torrent.on 'upload' !-> progress!
  torrent.on 'download' !-> progress!

  detect-streaming = (vid) -> !vid.name.match( /[.]mp4$/ )

  start = !->
    if (vid = torrent.vid)?
      vid.select!
      torrent.supports-streaming = detect-streaming vid
        if !..
          download-to-file vid, torrent.video-filename

  progress = !->
    if torrent.vid?
      downloaded = torrent.vid.downloaded
      progress = downloaded / torrent.vid.length
      check-if-ready-to-play!
    else
      downloaded = torrent.downloaded
      progress = downloaded / torrent.length
    $ '#statusbar' .text "downloaded: #{file-size(downloaded).human!} (#{Math.round(progress * 100)}%)  |  uploaded: #{file-size(torrent.uploaded).human!}"

  download-to-file = (vid, filename) !->
    fs.createWriteStream(filename)
      vid.createReadStream().pipe ..
      ..on 'open' -> readMoovSpeculatively vid, filename .then -> torrent.moov-thread-done = true

  check-if-ready-to-play = ->
    if !(torrent.ready && torrent.vid?) then return
    downloaded = torrent.vid.downloaded
    #console.log 'downloaded', downloaded, torrent.subtitles-thread-done
    if torrent.options.request-play && downloaded > 6000000 && torrent.subtitles-thread-done \
         && (torrent.supports-streaming || torrent.moov-thread-done)
      console.log '[torrent] ready to play'
      torrent.options.request-play = false
      play!
    
  play = ->
    try
      if torrent.vid.progress >= 1
        filename = path.join(torrent.path, torrent.vid.path)
        video-player.play filename, torrent.subtitles-filename
      else if torrent.supports-streaming && video-player.supports-streaming
        torrent.stream = stream = torrent.vid.createReadStream!
        video-player.stream stream, torrent.subtitles-filename
      else
        if torrent.supports-streaming
          download-to-file torrent.vid, torrent.video-filename
        filename = torrent.video-filename
        video-player.play filename, torrent.subtitles-filename
    catch e
      console.error e

  torrent.play = ->
    torrent.options.request-play = true
    torrent.options.first-and-last-only = false
    start!
    check-if-ready-to-play!

  window.torrent = torrent

stop-all-downloads = ->
  if client?
    client.torrents.for-each ->
      client.remove it #($ '#torrent-hash' .val!)


DEFAULT_OPTIONS =
  metadata-only: true
  first-and-last-only: true
  request-play: false
  search-subtitles: true


find-video-file = (torrent) ->
  for f in torrent.files
    if f.name == /\.mkv$/ || f.name == /\.mp4$/ || f.name == /\.avi$/
      return f

find-file-by-name = (torrent, filename) ->
  for f in torrent.files
    if f.name == filename then return f


readFirstAndLastBlocks = (torrent-file) ->
  BLOCK_SIZE = 65536
  n = torrent-file.length
  result = {size: n}
  new Promise (fulfill, reject) ->
   check = -> if result.block0? && result.blockn? then fulfill result
   rs-block0 = torrent-file.createReadStream {start: 0, end: BLOCK_SIZE - 1}
     block0 = new MemoryStream
     ..pipe block0
     ..on 'end' -> result.block0 = block0.toBuffer! ; check!
   rs-blockn = torrent-file.createReadStream {start: n - BLOCK_SIZE, end: n - 1}
     blockn = new MemoryStream
     ..pipe blockn
     ..on 'end' -> result.blockn = blockn.toBuffer! ; check!

readMoovSpeculatively = (torrent-file, out-filename) ->
  MOOV_SIZE = 6e6
  n = torrent-file.length
  start = Math.max(0, n - MOOV_SIZE)
  new Promise (fulfill, reject) ->
    torrent-file.createReadStream {start: start, end: n - 1}
      ..pipe fs.createWriteStream(out-filename, flags: 'r+', start: start) #devnull()
      ..on 'end' -> fulfill {}


$ ->
  $ '#torrent-hash' .on \input ->
    stop-all-downloads!
    runDownload ($ '#torrent-hash' .val!)

  $ '#torrent-hash' .keypress (ev) ->
    if ev.keyCode == 13
      $(this).trigger \input

  $ '#torrent-download-form #play' .click ->
    if torrent.destroyed
      stop-all-downloads!
      runDownload ($ '#torrent-hash' .val!), do
        metadata-only: false
        first-and-last-only: false
        request-play: true
        selected-filename: $ '#torrent-download-form #file-select' .val!
    else
      torrent.play!

  $ '#download' .click ->
    stop-all-downloads!
    sel = $ '#torrent-download-form #file-select' .val!
    runDownload ($ '#torrent-hash' .val!), do
      metadata-only: false
      first-and-last-only: false
      selected-filename: if sel == "(all)" then "*" else sel

  $ '#download-all' .click ->
    stop-all-downloads!
    $ '#torrent-download-form #file-select' .val '(all)'
    runDownload ($ '#torrent-hash' .val!), do
      metadata-only: false
      first-and-last-only: false
      selected-filename: "*"

  $ '#stop' .click -> stop-all-downloads!

  $ '#file-select' .change ->
    stop-all-downloads!
    wlog $('#file-select').val!
    # Better way to extract torrent data, rather than serialize+deserialize?
    runDownload parse-torrent(parse-torrent.toTorrentFile(torrent)), do #($ '#torrent-hash' .val!), do
      metadata-only: false
      first-and-last-only: true
      selected-filename: $ '#torrent-download-form #file-select' .val!

  #test = '5b8c29a1e13d409422089cf113851dec9e2f4e97'   # Big buck bunny
  #test = '3D70686921E6369124E9E09870C3C6ED5D7E5DC0'   # House of Cards S03
  test = '22ac6e1d25024583868f5f6c9aacbafd9ce59f0f'   # House of Cards S04
  #test = '0b7b5357fe664e7eeec7804708fc9665a78a685b'   # Big Bang S10E04
  #test = '0403FB4728BD788FBCB67E87D6FEB241EF38C75A'   # Ubuntu 16.10 Desktop (64-bit)
  $ '#torrent-hash' .val test
  #.trigger 'input'

  search-engines = {PirateBay, Torrentz}

  $ '#torrentz-select'
    ..empty!
    ..append ($ '<option>' .text 'thepiratebay.org' .val 'PirateBay')
    ..append ($ '<option>' .text 'torrentz2.eu' .val 'Torrentz')

  $ '#query' .keypress (ev) ->
    if ev.keyCode == 13
      $(this).parent!find('[type=submit]').click!

  $ '#search' .click ->
    search-engines[$('#torrentz-select').val!]
      ..search $('#query').val!

  $ '#log' .on 'click', 'a', (ev) ->
    ev.preventDefault!
    $ '#torrent-hash' .val $(ev.target).attr 'href'
    .trigger 'input'

  $ '#history-pane' .on 'picked' (ev, item) ->
    stop-all-downloads!
    $ '#torrent-hash' .val item.infoHash
    runDownload item.infoHash, do #($ '#torrent-hash' .val!), do
      metadata-only: false
      first-and-last-only: true
      selected-filename: item.filename ? "*"

  # test
  #$ '#query' .val "big bang s10e10"
  #$ '#search' .click!
