

Torrentz =
  BASE_URL_ALTS: ['http://torrentz2.eu', 'http://torrentz.ht']
  BASE_URL: 'http://torrentz2.eu'
  uri: (query) ->
    "#{@BASE_URL}/search?f=#{encodeURI(query.replace(/ /g,'+'))}"
  search: (query) ->
    wlog "[torrentz] Searching '#{query}'"
    $.ajax @uri(query)
    .always (res, status) ~>
      if res.status == 503   # CloudFlare nonsense
        nw.Window.open @BASE_URL, {inject_js_start: 'inject.js'}
        return
      wlog "[torrentz] ajax #{status}"
      h = $ '<body>' .append $.parseHTML(res)
      items =
        for dl in h.find('div.results dl')
          #console.log dl
          a = $(dl).find('a[href]').first!
          if a.length > 0
            info-hash = a.attr('href').split('/')[*-1]
            s = $(dl).find('span').filter((i,x) -> $(x).text! == /^[\d.]+\s*[MG]B/).first!
            $('<li>').append do
              $ '<a>' .add-class 'hash' .text "#{a.text!}" .attr 'href', info-hash
              if s.length > 0
                document.createTextNode " "
                $ '<span>' .add-class 'size' .text "[#{s.text!}]"
      wlog [$('<span>').text("[torrentz] Search results"), $('<ul>').append(items)]


CloudFlare =
  remove-cookies: ->
    chrome.cookies.getAll {}, (cs) ->
      for cookie in cs
        chrome.cookies.remove url: "http://#{cookie.domain}", name: cookie.name


window.onmessage = -> console.log "window message: #{it}"

export Torrentz, CloudFlare
