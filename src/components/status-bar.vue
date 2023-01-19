<template>
    <div class="status-bar">
        {{ numPeers }} peers
        |
        downloaded: {{d.human}} ({{Math.round(d.percentage * 100)}}%)  
        |
        uploaded: {{u.human}}
    </div>
</template>

<script lang="ts">
export default {
    props: ['numPeers', 'progress'],
    computed: {
        d() { return this.progress.downloaded; },
        u() { return this.progress.uploaded; }
    }
}
</script>