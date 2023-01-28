
TAGS = "pseudo|bdrip|dvdrip|dvdscr|bluray|1080p|720p|shaanig|h[.]26[45]|x26[45]|mkv|mp4|avi|" + \
       "dimension|hdtv|ettv|lol|eztv|web-dl|webrip|tbs|aac|kylar|newstudio[.]tv|xvid|w4f|avs|nf|" + \
       "dd5[.]1|sneaky|brrip|titler|playweb|hmax|amzn|repack|re|megusta|torrentgalaxy|kogi|" + \
       "WEB[.](h264|x264)|glhf|bae|hevc|rarbg|sugoi|horriblesubs|t3nzin|galaxytv|silence[)]"

filter-tags = (name) ->
  re = //([\[\]().,-\s] (#TAGS) \b (|[\[\]().,-\s]))+[\[\]().,-]?//ig
  tags = []
  caption: normalize(name.replace(re, -> tags.push it; ' '))
  tags: tags


normalize = ->
  it.replace(/[.]/g, ' ').replace(/^\s*|\s(?=\s)|\s*$/g, "")




Tags = {filter-tags}


export Tags
