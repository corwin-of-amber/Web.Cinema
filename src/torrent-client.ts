import fs from 'fs';
import { EventEmitter } from 'events';
import webtorrent from 'webtorrent';  /** @kremlin.native */
import fileSize from 'file-size';
// @ts-ignore
import { wlog, werr } from './logging.ls';


class TorrentClient extends EventEmitter {
    wt: any /* WebTorrent */
    torrent: any

    options = {moovSize: 6e6}
    wtOptions = {path: "/tmp/Web.Cinema"}

    constructor() {
        super();
        this.wt = new webtorrent();
        this.wt.on('error', err => werr (err.message || err));
        window.addEventListener('beforeunload', () => this.wt.destroy());
    }

    runDownload(torrentId: string, options={}) {
        let torrent = this.wt.add(torrentId, this.wtOptions);
        torrent.on('infoHash', () => wlog('[torrent] infoHash'));
        torrent.on('metadata', () => {
            wlog(`[torrent] ${torrent.numPeers} peers`);
            this.emit('metadata', {filenames: torrent.files.map(f => f.name)})
        });
        torrent.once('ready', () => {
            wlog(`[torrent] ready; ${torrent.numPeers} peers`)
        });
        torrent.on('upload', () => this.progress());
        torrent.on('download', () => this.progress());

        this.torrent = torrent;
    }

    progress() {
        if (this.torrent) {
            let downloaded = this.torrent.downloaded,
                percentage = downloaded / this.torrent.length
            this.emit('progress', {
                downloaded: {
                    bytes: downloaded,
                    human: fileSize(downloaded).human(),
                    percentage
                },
                uploaded: {
                    bytes: this.torrent.uploaded,
                    human: fileSize(this.torrent.uploaded).human()
                }
            });      
        }
    }

    stop() {
        for (let torrent of this.wt.torrents) {
            this.wt.remove(torrent);
        }
    }

    download(torrentFile: any, filename: string) {
        let out = fs.createWriteStream(filename);
        torrentFile.createReadStream().pipe(out)
            .on('open', () => this.readMoov(torrentFile, filename));
    }

    readMoov(torrentFile: any, outFilename: string) {
        let n = torrentFile.length,
            start = Math.max(0, n - this.options.moovSize);
        
        let pipe =
          torrentFile.createReadStream({start: start, end: n - 1})
            .pipe(fs.createWriteStream(outFilename, {flags: 'r+', start: start}));

        return new Promise((resolve, reject) =>
            pipe.on('end', () => resolve({})));      
    }
}


export { TorrentClient }