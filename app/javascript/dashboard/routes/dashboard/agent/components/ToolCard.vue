<template>
  <div class="p-6 hover:bg-n-solid-1 transition-colors">
    <div class="flex items-start gap-4">
      <!-- Icon -->
      <div :class="[
        'w-12 h-12 flex-shrink-0 rounded-lg flex items-center justify-center',
        iconBgClass
      ]">
        <i :class="[iconClass, 'text-2xl']"></i>
      </div>

      <!-- Content -->
      <div class="flex-1 min-w-0">
        <div class="flex items-start justify-between mb-2">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-1">
              <h4 class="text-lg font-medium text-n-slate-12">{{ tool.name }}</h4>
              <span :class="['text-xs px-2 py-0.5 rounded font-medium', typeBadgeClass]">
                {{ typeLabel }}
              </span>
              <span v-if="!tool.enabled" class="text-xs px-2 py-0.5 rounded font-medium bg-red-100 text-red-700">
                Desativada
              </span>
            </div>
            <p class="text-sm text-n-slate-11 line-clamp-2">
              {{ tool.description }}
            </p>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-1 ml-4">
            <Button
              variant="ghost"
              size="sm"
              :icon="tool.enabled ? 'i-lucide-toggle-right' : 'i-lucide-toggle-left'"
              :class="tool.enabled ? 'text-green-600' : 'text-n-slate-10'"
              @click="$emit('toggle', tool)"
            />
            <Button
              variant="ghost"
              size="sm"
              icon="i-lucide-pencil"
              @click="$emit('edit', tool)"
            />
            <Button
              variant="ghost"
              color="ruby"
              size="sm"
              icon="i-lucide-trash-2"
              @click="$emit('delete', tool)"
            />
          </div>
        </div>

        <!-- Tool Details -->
        <div v-if="tool.tool_type === 'native' && tool.configuration" class="mt-3">
          <NativeToolDetails :configuration="tool.configuration" />
        </div>

        <div v-else-if="tool.tool_type === 'http' || tool.tool_type === 'https'" class="mt-3">
          <HttpToolDetails :configuration="tool.configuration" />
        </div>

        <div v-else-if="tool.tool_type === 'mcp'" class="mt-3">
          <McpToolDetails :configuration="tool.configuration" />
        </div>

        <!-- Conditions Summary -->
        <div v-if="hasConditions" class="mt-3 flex flex-wrap gap-1.5">
          <span class="text-xs px-2 py-1 rounded bg-amber-50 text-amber-700 flex items-center gap-1">
            <i class="i-lucide-filter"></i>
            Possui critérios de execução
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Button from 'dashboard/components-next/button/Button.vue';
import NativeToolDetails from './NativeToolDetails.vue';
import HttpToolDetails from './HttpToolDetails.vue';
import McpToolDetails from './McpToolDetails.vue';

export default {
  name: 'ToolCard',
  components: {
    Button,
    NativeToolDetails,
    HttpToolDetails,
    McpToolDetails,
  },
  props: {
    tool: {
      type: Object,
      required: true,
    },
  },
  emits: ['edit', 'delete', 'toggle'],
  computed: {
    typeLabel() {
      const labels = {
        native: 'Nativa',
        http: 'HTTP',
        https: 'HTTPS',
        mcp: 'MCP',
      };
      return labels[this.tool.tool_type] || this.tool.tool_type;
    },
    typeBadgeClass() {
      const classes = {
        native: 'bg-brand-50 text-brand-700',
        http: 'bg-blue-50 text-blue-700',
        https: 'bg-blue-50 text-blue-700',
        mcp: 'bg-purple-50 text-purple-700',
      };
      return classes[this.tool.tool_type] || 'bg-n-solid-3 text-n-slate-11';
    },
    iconClass() {
      const icons = {
        native: 'i-lucide-sparkles text-n-brand',
        http: 'i-lucide-globe text-blue-600',
        https: 'i-lucide-globe text-blue-600',
        mcp: 'i-lucide-plug text-purple-600',
      };
      return icons[this.tool.tool_type] || 'i-lucide-wrench text-n-slate-10';
    },
    iconBgClass() {
      const classes = {
        native: 'bg-brand-50',
        http: 'bg-blue-50',
        https: 'bg-blue-50',
        mcp: 'bg-purple-50',
      };
      return classes[this.tool.tool_type] || 'bg-n-solid-3';
    },
    hasConditions() {
      return this.tool.conditions && Object.keys(this.tool.conditions).length > 0;
    },
  },
};
</script>
