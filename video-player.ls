require! path
require! child_process



class MPVVideoPlayer

  EXE: '/opt/local/bin/mpv'

  play: (vid-filename, subtitles-filename) ->
    args = []
    if subtitles-filename?
      args.push "--sub-file=#{path.resolve(subtitles-filename)}"
    args.unshift vid-filename
    child_process.spawn @EXE, args, {stdio: 'ignore'}
      ..on 'error' -> werr it


class IINAVideoPlayer

  EXE: '/Applications/IINA.app/Contents/MacOS/iina-cli'

  play: (vid-filename, subtitles-filename) ->
    args = ['--mpv-resume-playback=no', '--mpv-pause']
    if subtitles-filename?
      args.push "--mpv-sub-file=#{path.resolve(subtitles-filename)}"
    args.unshift vid-filename
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


video-player = new MPVVideoPlayer


export video-player
