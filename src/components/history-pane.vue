<template>
    <div class="history-pane" tabindex="0">
        <ul>
            <li v-for="entry in entries" @click="select(entry)">{{ formatName(entry.filename) }}</li>
        </ul>
    </div>
</template>

<script lang="ts">
// @ts-ignore
import { Tags } from '../filename-tags.ls';

export default {
    props: ['entries'],
    mounted() {
        /* focus in order to trigger `blur` when clicking outside */
        requestAnimationFrame(() => this.$el.focus());
    },
    methods: {
        formatName(s: string) {
            return Tags.filterTags(s).caption;
        },
        select(entry: any) {
            this.$emit('select', {entry});
        }
    }
}
</script>