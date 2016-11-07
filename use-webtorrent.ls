WebTorrent = require('webtorrent')
MemoryStream = require('memory-stream')  # I also tried memory-streams but it didn't work well


runDownload = (torrentId) ->

  client = new WebTorrent({})
  client.on 'error' (err) -> werr (err.message || err)

  torrent = client.add(torrentId, {path: "/tmp"}, -> wlog "[torrent]")

  torrent.on 'infoHash' !->
    wlog "[torrent] infoHash"
    #torrent.on 'wire' !-> wlog "[torrent] wire"
  torrent.on 'metadata' !->
    wlog "[torrent] #{torrent.numPeers} peers"
    for f in torrent.files
      wlog "[torrent] #{f.name} (#{f.length})"
  torrent.once 'ready' !->
    wlog "[torrent] ready (#{torrent.numPeers} peers)"
    $ '#statusbar' .text "0%"
    #client.remove torrentId
    readFirstAndLastBlocks torrent.files[0] .then (result) ->
      console.log result
      client.remove torrentId
      subhash = subtitles-hash-minimal result
      wlog "[torrent] subtitle hash = #{subhash}"
      login-and-search subhash
    setTimeout (-> if client.get torrentId then client.remove torrentId), 10000

  torrent.on 'download' !->
    $ '#statusbar' .text "downloaded: #{torrent.downloaded}   progress: #{torrent.progress}"

  window.addEventListener 'unload' -> client.destroy!

  window.torrent = torrent


readFirstAndLastBlocks = (torrent-file) ->
  BLOCK_SIZE = 65536
  n = torrent-file.length
  result = {size: n}
  new Promise (fulfill, reject) ->
   check = -> if result.block0? && result.blockn?? then fulfill result
   rs-block0 = torrent-file.createReadStream {start: 0, end: BLOCK_SIZE - 1}
     block0 = new MemoryStream
     ..pipe block0
     ..on 'end' -> result.block0 = block0.toBuffer! ; console.log block0.toBuffer!length ; check!
   rs-blockn = torrent-file.createReadStream {start: n - BLOCK_SIZE, end: n - 1}
     blockn = new MemoryStream
     ..pipe blockn
     ..on 'end' -> result.blockn = blockn.toBuffer! ; console.log blockn.toBuffer!length ; check!

$ ->
  $ '<div>' .attr('id', 'statusbar') .append-to 'body'
  # runDownload '5676c36f50ae9a59967da76093ad95b6c5f1fe4d'  # Bee Movie
  runDownload '0b7b5357fe664e7eeec7804708fc9665a78a685b'   # Big Bang S10E04
