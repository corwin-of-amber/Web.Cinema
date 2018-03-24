
log-container = 'body'

$ ->
  if (out = $ '#log').length
    log-container := out
    out.dblclick -> out.empty!

with_ = ($el, contents) ->
  if $.isArray(contents) || contents instanceof $
    $el.append contents
  else
    /* Make browser allow breaks after punctuations */
    contents = contents.toString!replace /[.,:;]/g, (+ "\u200B")
    $el.text contents

wlog = -> (with_($('<p>').add-class('info'), it)  .append-to log-container).0.scrollIntoView!
werr = -> (with_($('<p>').add-class('error'), it) .append-to log-container).0.scrollIntoView!

export wlog, werr
