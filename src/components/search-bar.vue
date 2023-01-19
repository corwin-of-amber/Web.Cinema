<template>
    <div class="search-bar">
        <input v-model="query" @keydown="onKey">
        <button @click="doSearch">🔍</button>
    </div>
</template>

<script lang="ts">
export default {
    data: () => ({query: 'ted lasso'}),
    methods: {
        doSearch() {
            if (this.query)
                this.$emit('search', {query: this.query});
        },
        onKey(ev: KeyboardEvent) {
            if (ev.key === 'Enter') this.doSearch();
        }
    }
}
</script>