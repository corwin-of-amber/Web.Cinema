import fs from 'fs';
import { EventEmitter } from 'events';
import WebTorrent from 'webtorrent';  /** @kremlin.native */
import fileSize from 'file-size';
// @ts-ignore
import { wlog, werr } from './logging.ls';


class TorrentClient extends EventEmitter {
    wt: WebTorrent.Instance
    torrent: any

    options = {moovSize: 6e6}
    wtOptions = {path: "/tmp/Web.Cinema", announce: TorrentClient.TRACKERS}

    constructor() {
        super();
        this.wt = new WebTorrent();
        this.wt.on('error', err => werr (err instanceof Error ? err.message : err));
        window.addEventListener('beforeunload', () => this.wt.destroy());
    }

    open(torrentId: string, options: TorrentClient.OpenOptions = {}) {
        let torrent = this.wt.add(torrentId, this.wtOptions);
        torrent.on('infoHash', () => wlog('[torrent] infoHash'));
        torrent.on('metadata', () => {
            wlog(`[torrent] ${torrent.numPeers} peers`);
            this.emit('metadata', {torrentId, filenames: torrent.files.map(f => f.name)});
        });
        torrent.once('ready', () => {
            wlog(`[torrent] ready; ${torrent.numPeers} peers`)
            this.emit('ready', {torrentId});
            this.pause();
        });
        torrent.on('upload', () => this.progress());
        torrent.on('download', () => this.progress());

        this.torrent = torrent;
    }

    progress() {
        if (this.torrent) {
            this.emit('progress', {
                downloaded: this._downloadProgress(this.torrent),
                uploaded: this._uploadProgress(this.torrent)
            });      
        }
    }

    fileProgress(file: {length: number, downloaded: number}) {
        return this._downloadProgress(file);
    }

    _downloadProgress(thing: {length: number, downloaded: number}) {
        return {
            bytes: thing.downloaded,
            human: fileSize(thing.downloaded).human(),
            percentage: thing.downloaded / thing.length
        };
    }

    _uploadProgress(thing: {uploaded: number}) {
        return {
            bytes: thing.uploaded,
            human: fileSize(thing.uploaded).human()
        };
    }

    pause() {
        if (this.torrent)
            this.torrent.deselect(0, this.torrent.pieces.length - 1);
    }

    stop() {
        for (let torrent of this.wt.torrents) {
            this.wt.remove(torrent);
        }
    }

    getFile(filename: string) {
        return this.torrent.files.find(f => f.name === filename);
    }

    download(torrentFile: any) {
        torrentFile.select();
    }

    downloadStream(torrentFile: any, filename: string) {
        try { fs.unlinkSync(filename); } catch { }
        let out = fs.createWriteStream(filename),
            pipe = torrentFile.createReadStream().pipe(out),
            readMoov = new Promise(resolve =>
                pipe.on('open', () => resolve(this.readMoov(torrentFile, filename))));
        return {
            ready: readMoov /* @todo also wait for sufficient data from the beginning */
        };
    }

    readMoov(torrentFile: any, outFilename: string) {
        let n = torrentFile.length,
            start = Math.max(0, n - this.options.moovSize);

        let pipe =
          torrentFile.createReadStream({start: start, end: n - 1})
            .pipe(fs.createWriteStream(outFilename, {flags: 'r+', start: start}));

        return new Promise((resolve, reject) =>
            pipe.on('finish', () => { console.log('readMoov: done'); resolve({}); }));      
    }
}


namespace TorrentClient {

    export type OpenOptions = {
    }

    // From trackerlist
    export const TRACKERS = [
        'udp://tracker.opentrackr.org:1337/announce',
        'udp://open.tracker.cl:1337/announce',
        'udp://open.demonii.com:1337/announce',
        'udp://open.stealth.si:80/announce',
        'udp://tracker.torrent.eu.org:451/announce',
        'udp://exodus.desync.com:6969/announce',
        'udp://tracker.tiny-vps.com:6969/announce',
        'udp://explodie.org:6969/announce',
        'udp://tracker1.bt.moack.co.kr:80/announce',
        'udp://tracker.theoks.net:6969/announce',
        'udp://tracker.dler.org:6969/announce',
        'udp://tracker.0x7c0.com:6969/announce',
        'udp://tracker-udp.gbitt.info:80/announce',
        'udp://run.publictracker.xyz:6969/announce',
        'udp://retracker01-msk-virt.corbina.net:80/announce',
        'udp://opentracker.io:6969/announce',
        'udp://oh.fuuuuuck.com:6969/announce',
        'https://tracker.tamersunion.org:443/announce',
        'udp://wepzone.net:6969/announce',
        'udp://ttk2.nbaonlineservice.com:6969/announce'
    ]
}


export { TorrentClient }