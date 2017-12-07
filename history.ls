
class Hist

  ->
    if localStorage.history
      @items = JSON.parse that
    else
      @items = []

  save: !->
    localStorage.history = JSON.stringify @items

  add: (item /* {infoHash, name, filename}*/) !->
    @items = @items.filter ->
      !(it.infoHash == item.infoHash && it.filename == item.filename)  /* overwrite name though */
    @items.unshift item
    @save!

  render: ->
    $ '<ul>' .append @items.map (item) ~>
      $ '<li>'
        ..text @get-caption(item)
        ..attr 'title' @get-tags(item).join(" ")
        ..data 'item' item

  get-caption: (item) ->
    item.caption ? Tags.filter-tags(item.filename).caption

  get-tags: (item) ->
    item.tags ? Tags.filter-tags(item.filename).tags


class HistoryPane

  (@$el, @hist) ->

  refresh: !->
    @$el
      ..empty!
      ..append @hist.render!

  position-below: ($el) !->
    @$el.offset top: $el.0.getBoundingClientRect!bottom

  is-visible: -> @$el.is(':visible')
  hide: !-> @$el.hide!

  toggle: (below) !->
    if below? then @position-below below
    @$el.toggle!



$ ->
  hist = new Hist

  hist-pane = new HistoryPane $('#history-pane'), hist

  $ '#history-show' .click ->
    hist-pane
      ..refresh!
      ..toggle /*below:*/ $(@)
    false  # to prevent the $('body').click that follows
  $ '#history-add' .click ->
    hist
      ..add {torrent.name, torrent.infoHash, \
             filename: torrent.options.selectedFilename ? torrent.vid.name}
    hist-pane
      ..refresh!

  $ '#history-pane' .on 'click', 'li' (ev) ->
    infoHash = $(ev.target).data('item').infoHash
    $ '#torrent-hash' .val infoHash
      ..trigger 'input'

  $ 'body' .click (ev) ->
    if hist-pane.is-visible! && $(ev.target).closest('#history-pane').length == 0
      hist-pane.hide!

  window <<< {hist}
  /*
  indexedDB.open('wcHistory', 2)
    ..onerror ->
      werr "[history] #{JSON.stringify it}"
    ..onupgradeneeded ->
      env = it.target.result
      env.createObjectStore("historyItems")
  */
