<template>
    <div class="main-panel">
        <search-bar @search="$emit('search', $event)"/>
        <nav-bar :files="files"/>
        <status-bar :num-peers="numPeers" :progress="progress"/>
    </div>
</template>

<script lang="ts">
import SearchBar from './search-bar.vue';
import NavBar from './nav-bar.vue';
import StatusBar from './status-bar.vue';

export default {
    data: () => ({files: [], numPeers: 0, progress: {downloaded: {}, uploaded: {}}}),
    components: { StatusBar, NavBar, SearchBar }
}
</script>