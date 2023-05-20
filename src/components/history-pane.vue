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
        this.$el.focus();
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