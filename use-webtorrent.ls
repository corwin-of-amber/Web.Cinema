WebTorrent = require('webtorrent')
MemoryStream = require('memory-stream')  # I also tried memory-streams but it didn't work well
parse-torrent = require('parse-torrent')
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

  configureOptions torrent, options

  torrent.on 'infoHash' !->
    wlog "[torrent] infoHash"
    #torrent.on 'wire' !-> wlog "[torrent] wire"

  torrent.on 'metadata' !->
    wlog "[torrent] #{torrent.numPeers} peers"
    #for f in torrent.files
    #  wlog "[torrent] #{f.name} (#{f.length})"
    $ '#file-select'
      ..empty!
      for f in torrent.files
        ..append ($ '<option>' .text f.name)
      if options.selected-filename?
        ..val options.selected-filename
      else if (vid = find-video-file torrent)?
        ..val vid.name
    if torrent.options.metadata-only
      client.remove torrentId
    else
      torrent.deselect(0, torrent.pieces.length - 1, false)  # download nothing yet!
      # see https://github.com/feross/webtorrent/issues/164

  torrent.once 'ready' !->
    wlog "[torrent] ready (#{torrent.numPeers} peers)"
    if torrent.options.metadata-only
      client.remove torrentId
    else
      $ '#statusbar' .text "downloaded: 0   progress: 0%"
      vid = find-file-by-name(torrent, torrent.options.selected-filename) || \
            find-video-file(torrent)
      if vid?
        torrent.vid = vid
        readFirstAndLastBlocks vid .then (result) ->
          console.log result
          if torrent.options.first-and-last-only
            client.remove torrentId
          subhash = subtitles-hash-minimal result
          wlog "[torrent] subtitle hash = #{subhash}"
          OpenSubtitles.login-and-search subhash
          .then ->
            wlog "[torrent] #{vid.name}: subtitles['en'] = #{JSON.stringify it?.en}"
            if it?.en?
              OpenSubtitles.fetch it.en
              .then ->
                torrent.subtitles-filename = './tmp/subs.srt'  # @@@ hard-coded
                torrent.subtitles-thread-done = true
            else
              torrent.subtitles-thread-done = true
          .catch ->
            torrent.subtitles-thread-done = true
        if !torrent.options.first-and-last-only
          vid.select!
          vid.createReadStream().pipe fs.createWriteStream('./tmp/stream')
          torrent.request-play = true

      #setTimeout (-> if client.get torrentId then client.remove torrentId), 10000

  torrent.on 'upload' !->
    $ '#statusbar' .text "uploaded: #{torrent.uploaded}"

  torrent.on 'download' !->
    if torrent.vid?
      downloaded = torrent.vid.downloaded
      progress = downloaded / torrent.vid.length
      $ '#statusbar' .text "downloaded: #{file-size(downloaded).human!} (#{Math.round(progress * 100)}%)   uploaded: #{torrent.uploaded}" ##progress: #{progress}"
      if torrent.request-play && downloaded > 6000000 && torrent.subtitles-thread-done
        torrent.request-play = false
        args = []
        if torrent.subtitles-filename?
          args.push '--sub-file' path.resolve(torrent.subtitles-filename)
        try
          cmd = "open -a vlc ./tmp/stream --args #{args.join ' '}"
          child_process.exec cmd
        catch e
          werr e

  window.torrent = torrent

stop-all-downloads = ->
  if client?
    client.torrents.for-each ->
      client.remove it #($ '#torrent-hash' .val!)


# auxiliary function
configureOptions = (torrent, options) ->
  torrent.options =
    first-and-last-only: options.first-and-last-only ? true
    metadata-only: options.metadata-only ? false
    selected-filename: options.selected-filename
  torrent.request-play = false


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
     ..on 'end' -> result.block0 = block0.toBuffer! ; console.log block0.toBuffer!length ; check!
   rs-blockn = torrent-file.createReadStream {start: n - BLOCK_SIZE, end: n - 1}
     blockn = new MemoryStream
     ..pipe blockn
     ..on 'end' -> result.blockn = blockn.toBuffer! ; console.log blockn.toBuffer!length ; check!

$ ->
  $ '<div>' .attr('id', 'statusbar') .insert-after '#torrent-download-form'

$ ->
  $ '#torrent-hash' .on \input ->
    stop-all-downloads!
    runDownload ($ '#torrent-hash' .val!)

  $ '#torrent-hash' .keypress (ev) ->
    if ev.keyCode == 13
      $(this).trigger \input

  $ '#resume' .click ->
    stop-all-downloads!
    runDownload ($ '#torrent-hash' .val!), do
      metadata-only: false
      first-and-last-only: false
      selected-filename: $ '#torrent-download-form #file-select' .val!

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

  $ '#torrentz-select'
    ..empty!
    for url in Torrentz.BASE_URL_ALTS
      ..append ($ '<option>' .text url)
    ..change ->
      Torrentz.BASE_URL = $('#torrentz-select').val!

  $ '#query' .keypress (ev) ->
    if ev.keyCode == 13
      $(this).parent!find('[type=submit]').click!

  $ '#search' .click ->
    Torrentz.search $('#query').val!

  $ '#log' .on 'click', 'a', (ev) ->
    ev.preventDefault!
    $ '#torrent-hash' .val $(ev.target).attr 'href'
    .trigger 'input'

  # test
  #$ '#query' .val "big bang s10e10"
  #$ '#search' .click!


  # Download history

  $ '#show-history' .click ->
    $ '#history-pane'
      ..empty!
      ..append ($ '<ul>' .append hist.items.map -> $ '<li>' .text it.filename .click (ev) -> wlog it.infoHash)
      ..offset top: $(@).0.getBoundingClientRect!bottom
      ..toggle!
