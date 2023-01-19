<template>
    <div class="nav-bar">
        <div>
            <select class="file-select">
                <option v-for="fn in files">{{ fn }}</option>
            </select>
        </div>
        <button class="btn play">▶︎</button>
        <button class="btn download">▼</button>
        <button class="btn download-all">▼<sup>*</sup></button>
        <button class="btn stop">■</button>
        <span class="sep"></span>
        <button class="history-show">History</button>
        <button class="history-add">+</button>
    </div>
</template>

<style scoped>
button.btn { padding: 0; width: 2em; height: 2em; vertical-align: bottom; }
span.sep { display: inline-block; width: .5em; }
</style>

<script lang="ts">
export default {
    props: ['files']
}
</script>