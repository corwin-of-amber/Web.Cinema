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

    Object.assign(window, {c});

    let panel = Vue.createApp(MainPanel, {
        onSearch(ev: {query: string}) { PirateBay.search(ev.query); },
        'onHistory:select': (action) => c.open(action.entry.infoHash),
        'onNav:action': (action) => console.log('nav:action', action)
    }).mount('body') as any;

    function selectedFile() {
        return c.getFile(panel.selectedFile);
    }

    Object.assign(window, {panel, selectedFile});

    c.on('metadata', ev => {
        panel.files = ev.filenames;
    });
    c.on('progress', ev => {
        panel.numPeers = c.torrent?.numPeers;
        panel.progress = ev;
    });
    /* ({dowloaded: d, uploaded: u}) => {
        document.querySelector('#statusbar')
            .textContent = `downloaded: ${d.human} (${Math.round(d.progress * 100)}%)  |  uploaded: ${u.human}`;
    });*/

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