
TAGS = "pseudo|bdrip|dvdrip|dvdscr|bluray|1080p|720p|shaanig|h[.]265|x264|mkv|mp4|avi"

filter-tags = (name) ->
  re = //([\[\].,\s] (#TAGS) \b (|[\[\].,\s]))+[\[\].,]?//ig
  tags = []
  caption: normalize(name.replace(re, -> tags.push it; ' '))
  tags: tags


normalize = ->
  it.replace(/^\s*|\s(?=\s)|\s*$/g, "")

$ ->
  test-cases =
   * "[pseudo] Rick and Morty S01E03 Anatomy Park [BDRip] [1080p] [h.265].mkv"
   * "House.of.Cards.S04E10.720p.BluRay.x264.ShAaNiG.mkv"

  for i in test-cases
    console.log filter-tags i



Tags = {filter-tags}


export Tags
