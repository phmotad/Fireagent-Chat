<template>
  <div class="text-sm space-y-1">
    <div class="flex items-center gap-2 text-n-slate-11">
      <i class="i-lucide-server"></i>
      <span v-if="configuration.server_url">
        <strong>Servidor:</strong>
        <code class="px-1.5 py-0.5 bg-n-solid-3 rounded text-xs">{{ configuration.server_url }}</code>
      </span>
    </div>
    <div v-if="configuration.protocol" class="flex items-center gap-2 text-n-slate-11">
      <i class="i-lucide-radio"></i>
      <span>
        <strong>Protocolo:</strong> {{ configuration.protocol }}
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'McpToolDetails',
  props: {
    configuration: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>
