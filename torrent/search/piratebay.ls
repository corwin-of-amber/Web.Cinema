

PirateBay =
  search: (query) ->
    api = require 'thepiratebay'
    wlog "[thepiratebay] Searching '#{query}'"
    api.search query, category: ['audio','video']
    .then ~>
      items =
        for result in it
          info-hash = @extract-hash result.magnetLink
          $ '<li>' .append do
            $ '<a>' .add-class 'hash' .text result.name .attr 'href' info-hash
            document.createTextNode " "
            $ '<span>' .add-class 'size' .text "[#{result.size}]"
      wlog [$('<span>').text("[thepiratebay] Search results"), $('<ul>').append(items)]
    .catch ->
      werr "[thepiratebay] #{it}"

  extract-hash: (magnet-link) ->
    /btih:(.*?)&/.exec(magnet-link)?.1
      if !.. then werr "invalid link #{magnet-link}"


export PirateBay
