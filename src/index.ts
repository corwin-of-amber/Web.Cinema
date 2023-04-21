import * as Vue from 'vue';
import dexie from 'dexie';
import { TorrentClient } from './torrent-client';
// @ts-ignore
import { PirateBay } from './search/piratebay.ls';

// @ts-ignore
import MainPanel from './components/main-panel.vue';

import './index.css';
import { LocalStore } from './infra/store';

Object.assign(window, {PirateBay, dexie});


function main() {
    let c = new TorrentClient;

    let uiState: any = {};

    Object.assign(window, {c});

    let panel = Vue.createApp(MainPanel, {
        onSearch(ev: {query: string}) { PirateBay.search(ev.query); },
        'onHistory:select': (action) => { uiState.openAction = action; c.open(action.entry.infoHash) },
        'onNav:action': (action) => {
            console.log('nav:action', action);
            switch (action.type) {
                case 'download':
                    c.download(selectedFile(), '/tmp/Web.Cinema/stream');
                    break;
                case 'history-add':
                    let entry = selectedEntry();
                    if (entry)
                        panel.history.entries.unshift(entry);
                    break;
            }
        }
    }).mount('body') as any;

    function selectedFile() {
        if (c.torrent && panel.selectedFile)
            return c.getFile(panel.selectedFile);
    }

    function selectedEntry() {
        if (c.torrent && panel.selectedFile)
            return {
                infoHash: c.torrent.infoHash,
                name: c.torrent.name,
                filename: panel.selectedFile
            };
    }

    Object.assign(window, {panel, selectedFile});

    c.on('metadata', ev => {
        panel.files = ev.filenames;
        if (uiState.openAction) {
            panel.gotoFile(uiState.openAction.entry.filename);
        }
    });
    c.on('progress', ev => {
        panel.numPeers = c.torrent?.numPeers;
        let file = selectedFile();
        panel.progress = file ? {...ev, downloaded: c.fileProgress(file)} : ev;
        
    });

    let historyStore = new LocalStore('history');
    panel.history.entries = historyStore.load();

    Object.assign(window, {historyStore});

    document.body.addEventListener('click', ev => {
        let el = ev.target as HTMLElement;
        if (el.tagName === 'A' && el.classList.contains('hash')) {
            console.log(el.getAttribute('href'));
            c.open(el.getAttribute('href'));
            ev.preventDefault();
        }
    }, {capture: true});
}



document.addEventListener('DOMContentLoaded', main);