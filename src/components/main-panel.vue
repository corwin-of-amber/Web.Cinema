<template>
    <div class="main-panel">
        <search-bar ref="search" @search="$emit('search', $event)"/>
        <nav-bar ref="nav" :files="files" @action="navAction"/>
        <status-bar ref="status" :num-peers="numPeers" :progress="progress"/>
        <history-pane ref="history" v-if="history.show" :entries="history.entries" :style="pos(history.pos)"
            @select="histSelect"/>
    </div>
</template>

<script lang="ts">
import SearchBar from './search-bar.vue';
import NavBar from './nav-bar.vue';
import StatusBar from './status-bar.vue';
import HistoryPane from './history-pane.vue';

export default {
    data: () => ({files: [], numPeers: 0, progress: {downloaded: {}, uploaded: {}},
                  history: {entries: [], show: false, pos: {x: 0, y: 0}}}),
    computed: {
        selectedFile() {
            return this.$refs.nav.selectedFile;
        }
    },
    methods: {
        pos(p: {x: number, y: number}) { return `left: ${p.x}px; top: ${p.y}px`},
        navAction(action: any) {
            switch (action.type) {
            case 'history-show':
                let r = action.$ev.target.getBoundingClientRect();
                this.history.pos = {x: r.left, y: r.bottom};
                this.history.show = !this.history.show;
                break;
            }
            this.$emit('nav:action', action);
        },
        histSelect(action: any) {
            this.history.show = false;
            console.log(action);
            this.$emit('history:select', action);
        },
        gotoFile(filename: string) {
            this.$refs.nav.selectedFile = filename;
        }
    },
    components: { StatusBar, NavBar, SearchBar, HistoryPane }
}
</script>