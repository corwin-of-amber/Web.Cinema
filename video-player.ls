require! path
require! child_process



class MPVVideoPlayer

  EXE: '/opt/local/bin/mpv'
  supports-streaming: true

  play: (vid-filename, subtitles-filename) ->
    args = []
    if subtitles-filename?
      args.push "--sub-file=#{path.resolve(subtitles-filename)}"
    args.unshift vid-filename
    child_process.spawn @EXE, args, {stdio: 'ignore'}
      ..on 'error' -> werr it

  stream: (vid-stream, subtitles-filename) ->
    args = ['--force-seekable=yes']
    if subtitles-filename?
      args.push "--sub-file=#{path.resolve(subtitles-filename)}"
    args.unshift '-'
    child_process.spawn @EXE, args, {stdio: ['pipe', 'inherit', 'inherit']}
      ..on 'error' -> werr it
      vid-stream.pipe ..stdin


class IINAVideoPlayer

  EXE: '/Applications/IINA.app/Contents/MacOS/iina-cli'

  play: (vid-filename, subtitles-filename) ->
    args = ['--mpv-resume-playback=no', '--mpv-pause']
    if subtitles-filename?
      args.push "--mpv-sub-file=#{path.resolve(subtitles-filename)}"
    args.unshift vid-filename
    console.log @EXE, args
    child_process.spawn @EXE, args
      ..on 'error' -> werr it


class VLCVideoPlayer

  play: (vid-filename, subtitles-filename) ->
    args = []
    if subtitles-filename?
      args.push '--sub-file' "'#{path.resolve(subtitles-filename)}'"
    cmd = "open -a vlc '#{vid-filename}' --args #{args.join ' '}"
    child_process.exec cmd
      ..on 'error' -> werr it


video-player = new IINAVideoPlayer


export MPVVideoPlayer, IINAVideoPlayer, VLCVideoPlayer, video-player
