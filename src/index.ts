import * as Vue from 'vue';
import { TorrentClient } from './torrent-client';
// @ts-ignore
import { PirateBay } from './search/piratebay.ls';

// @ts-ignore
import MainPanel from './components/main-panel.vue';

import './index.css';

Object.assign(window, {PirateBay});


function main() {
    let c = new TorrentClient;

    Object.assign(window, {c});

    let panel = Vue.createApp(MainPanel, {
        onSearch(ev: {query: string}) { PirateBay.search(ev.query); }
    }).mount('body') as any;

    Object.assign(window, {panel});

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

    document.body.addEventListener('click', ev => {
        let el = ev.target as HTMLElement;
        if (el.tagName === 'A' && el.classList.contains('hash')) {
            console.log(el.getAttribute('href'));
            c.runDownload(el.getAttribute('href'));
            ev.preventDefault();
        }
    }, {capture: true});
}



document.addEventListener('DOMContentLoaded', main);