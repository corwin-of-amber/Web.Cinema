

PirateBay =
  search: (query) ->>
    wlog "[thepiratebay] Searching '#{query}'"
    try
      await (await fetch("https://apibay.org/q.php?q=#{query}")).json!
        if ..0.id == '0' then throw ..0.name
        items = for result in ..slice(0, 25)
          $ '<li>' .append do
            $ '<a>' .add-class 'hash' .text result.name .attr 'href' result.info_hash
            document.createTextNode " "
            $ '<span>' .add-class 'size' .text "[#{result.size}]"
      wlog [$('<span>').text("[thepiratebay] Search results"), $('<ul>').append(items)]
    catch
      werr "[thepiratebay] #{e}"

  extract-hash: (magnet-link) ->
    /btih:(.*?)&/.exec(magnet-link)?.1
      if !.. then werr "invalid link #{magnet-link}"


export PirateBay
