

Torrentz =
  BASE_URL_ALTS: ['http://torrentz.ht', 'http://torrentz2.eu']
  BASE_URL: 'http://torrentz.ht'
  uri: (query) ->
    "#{@BASE_URL}/search?f=#{encodeURI(query.replace(/ /g,'+'))}"
  search: (query) ->
    wlog "[torrentz] Searching '#{query}'"
    $.ajax @uri(query)
    .always (res, status) ->
      wlog "[torrentz] ajax #{status}"
      window.tz = h = $ '<body>' .append $.parseHTML(res)
      console.log h.find('div.results')
      items =
        for dl in h.find('div.results dl')
          a = $(dl).find('a[href]').first!
          s = $(dl).find('span').filter((i,x) -> $(x).text! == /^\d+\s*[MG]B/).first!
          $('<li>').append do
            $ '<a>' .add-class 'hash' .text "#{a.text!}" .attr 'href', "#{a.attr('href').split('/')[*-1]}"
            document.createTextNode " "
            $ '<span>' .add-class 'size' .text "[#{s.text!}]"
      wlog [$('<span>').text("[torrentz] Search results"), $('<ul>').append(items)]


export Torrentz
