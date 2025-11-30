<template>
  <div class="text-sm space-y-1">
    <div class="flex items-center gap-2 text-n-slate-11">
      <i class="i-lucide-link"></i>
      <span v-if="configuration.url">
        <strong>URL:</strong>
        <code class="px-1.5 py-0.5 bg-n-solid-3 rounded text-xs">{{ configuration.url }}</code>
      </span>
    </div>
    <div v-if="configuration.method" class="flex items-center gap-2 text-n-slate-11">
      <i class="i-lucide-arrow-right"></i>
      <span>
        <strong>Método:</strong> {{ configuration.method.toUpperCase() }}
      </span>
    </div>
    <div v-if="configuration.auth_type" class="flex items-center gap-2 text-n-slate-11">
      <i class="i-lucide-shield"></i>
      <span>
        <strong>Autenticação:</strong> {{ configuration.auth_type }}
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HttpToolDetails',
  props: {
    configuration: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>
