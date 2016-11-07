srt-fn = "/tmp/House.Of.Cards.S01E01.720p.BluRay.450MB.ShAaNiG.com.srt"
out-fn = srt-fn.replace /\.srt$/ '.shift.srt'

fs = require 'fs'
iconvlite = require 'iconv-lite'
srt-parser = require 'subtitles-parser'

dec = (l, base, amount, out-flags={underflow: no}) ->
  [...r, t] = l
  t -= amount % base
  borrow = Math.floor(amount / base)
  if t < 0
    borrow += 1
    t = t + base
  if borrow > 0
    if r.some (> 0)
      r = dec r, base, borrow, out-flags
    else
      out-flags.underflow = yes
    if out-flags.underflow
      t = 0
  return [...r, t]

pad = (s, p) -> s = (p + s).substr -p.length

dec-mins = (l, by-minutes, out-flags) ->
  pad00 = -> pad ""+it, '00'
  l[0 to 1] = dec l[0 to 1], 60, by-minutes, out-flags .map pad00
  l

dec-secs = (l, by-seconds, out-flags) ->
  pad00 = -> pad ""+it, '00'
  l[0 to 2] = dec l[0 to 2], 60, by-seconds, out-flags .map pad00
  l

parse-srt = (text) ->
  blocks =
    for block in text.split /\r?\n\s*\n/
      fl = {}
      lines =
        for line in block.split /\r?\n/
          if (mo = /^\s*(\d+):(\d+):(\d+),(\d+) --> (\d+):(\d+):(\d+),(\d+)\s*$/.exec line)
            fr = dec2min [mo.1, mo.2, mo.3, mo.4], fl
            to = dec2min [mo.5, mo.6, mo.7, mo.8], fl
            line = "#{fr.0}:#{fr.1}:#{fr.2},#{fr.3} --> #{to.0}:#{to.1}:#{to.2},#{to.3}"
          line
      if not fl.underflow
        lines

  #lines = lines[lines.indexOf('40') to]

  $ '#out' .empty!
  for block in blocks
    for line in block
      $ '<p>' .text line .append-to '#out'

  blocks.map (.join '\n') .join '\n\n'

format-timestamp = ([h, m, s, ms]) ->
  # assumes proper padding
  "#{h}:#{m}:#{s},#{ms}"

xform-shift = (srt, by-seconds) ->
  (.filter (!= void)) do
    for block in srt
      fl = {}
      block = {} <<< block
      if (mo = /^\s*(\d+):(\d+):(\d+),(\d+)$/.exec block.startTime)
        block.startTime = format-timestamp dec-secs [mo.1, mo.2, mo.3, mo.4], by-seconds, fl
      if (mo = /^\s*(\d+):(\d+):(\d+),(\d+)$/.exec block.endTime)
        block.endTime = format-timestamp dec-secs [mo.1, mo.2, mo.3, mo.4], by-seconds, fl
      if !fl.underflow then block

xform-reverse-punctuation = (srt) ->
  (.filter (!= void)) do
    for block in srt
      {} <<< block
        ..text .= replace /^([.,!?\-;:'"0-9]*)(.*?)([.,!?\-;:'"0-9]*)$/mg, (mo, pre, middle, suf) ->
          suf + middle + pre

display-srt = (srt) ->
  for block in srt
    $ '<div>' .add-class 'subtitle-block' .append-to '#out'
      $ '<p>' .append-to ..
        $ '<span>' .add-class 'id' .text block.id .append-to ..
        $ '<span>' .add-class 'start-time' .text block.startTime .append-to ..
        $ '<span>' .add-class 'end-time' .text block.endTime .append-to ..
      for line in block.text.split '\n'
        $ '<p>' .text line .append-to ..

out-text = iconvlite.decode fs.readFileSync(srt-fn), 'iso-8859-8'
out-srt = srt-parser.fromSrt out-text

console.log out-fn

out-srt = xform-shift(out-srt, 200)
out-srt = xform-reverse-punctuation(out-srt)

display-srt out-srt
export out-srt

$ ->
  files = new FileList
    ..append new File srt-fn, srt-fn
  $ 'input[type=file]' .prop 'files' files
    ..change ->
      console.log @.files
      srt-fn := @files.0.path
      out-fn := srt-fn.replace /\.srt$/ '.shift.srt'
      out-text := parse-srt fs.readFileSync srt-fn, 'utf-8'

  $ '#save' .click ->
    fs.writeFileSync out-fn, out-text
    $ @ .text "Saved!"

