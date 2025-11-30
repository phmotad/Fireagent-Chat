<template>
  <div class="text-sm space-y-1">
    <div class="flex items-center gap-2 text-n-slate-11">
      <i class="i-lucide-info"></i>
      <span v-if="configuration.native_type === 'macro'">
        <strong>Tipo:</strong> Macro do Chatwoot
        <span v-if="configuration.macro_id" class="ml-2">
          (ID: {{ configuration.macro_id }})
        </span>
      </span>
      <span v-else-if="configuration.native_type === 'schedule'">
        <strong>Tipo:</strong> Agendamento
      </span>
      <span v-else-if="configuration.native_type === 'handover'">
        <strong>Tipo:</strong> Transfer�ncia para humano
      </span>
      <span v-else>
        <strong>Tipo:</strong> {{ configuration.native_type }}
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'NativeToolDetails',
  props: {
    configuration: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>
