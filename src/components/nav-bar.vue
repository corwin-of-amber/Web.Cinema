<template>
    <div class="nav-bar">
        <div>
            <select class="file-select" v-model="selectedFile">
                <option v-for="fn in files">{{ fn }}</option>
            </select>
        </div>
        <button @click="action($event, 'play')" class="btn play">▶︎</button>
        <button @click="action($event, 'download')" class="btn download">▼</button>
        <button @click="action($event, 'download-all')" class="btn download-all">▼<sup>*</sup></button>
        <button @click="action($event, 'stop')" class="btn stop">■</button>
        <span class="sep"></span>
        <button @click="action($event, 'history-show')" class="history-show">History</button>
        <button @click="action($event, 'history-add')" class="history-add">+</button>
    </div>
</template>

<style scoped>
button.btn { padding: 0; width: 2em; height: 2em; vertical-align: bottom; }
span.sep { display: inline-block; width: .5em; }
</style>

<script lang="ts">
export default {
    props: ['files'],
    data: () => ({selectedFile: undefined}),
    methods: {
        action(ev: MouseEvent, type: string) {
            this.$emit('action', {type, $ev: ev});
        }
    }
}
</script>