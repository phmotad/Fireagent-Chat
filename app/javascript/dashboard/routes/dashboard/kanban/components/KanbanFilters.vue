<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  boardId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const filters = useMapGetter('kanban/getFilters');
const columns = useMapGetter('kanban/getColumns');
const agents = useMapGetter('agents/getAgents');
const labels = useMapGetter('labels/getLabels');

const localFilters = ref({
  search: filters.value?.search || '',
  assignedTo: filters.value?.assignedTo || null,
  contact: filters.value?.contact || null,
  label: filters.value?.label || null,
  column: filters.value?.column || null,
});

const showFilters = ref(false);
const hasActiveFilters = computed(() => {
  return (
    localFilters.value.search ||
    localFilters.value.assignedTo ||
    localFilters.value.contact ||
    localFilters.value.label ||
    localFilters.value.column
  );
});

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('labels/get');
});

// Flag para evitar loops ao atualizar do store
const isUpdatingFromStore = ref(false);

// Sincronizar localFilters com filters do store apenas quando necessário
watch(
  () => filters.value,
  newFilters => {
    if (newFilters && !isUpdatingFromStore.value) {
      // Só atualizar se realmente mudou para evitar loops
      const newLocalFilters = {
        search: newFilters.search || '',
        assignedTo: newFilters.assignedTo || null,
        contact: newFilters.contact || null,
        label: newFilters.label || null,
        column: newFilters.column || null,
      };
      
      // Comparar se realmente mudou
      const hasChanged = 
        localFilters.value.search !== newLocalFilters.search ||
        localFilters.value.assignedTo !== newLocalFilters.assignedTo ||
        localFilters.value.contact !== newLocalFilters.contact ||
        localFilters.value.label !== newLocalFilters.label ||
        localFilters.value.column !== newLocalFilters.column;
      
      if (hasChanged) {
        localFilters.value = newLocalFilters;
      }
    }
  },
  { immediate: true }
);

const applyFilters = () => {
  isUpdatingFromStore.value = true;
  store.dispatch('kanban/setFilters', {
    search: localFilters.value.search || '',
    assignedTo: localFilters.value.assignedTo || null,
    contact: localFilters.value.contact || null,
    label: localFilters.value.label || null,
    column: localFilters.value.column || null,
  });
  // Reset flag após um pequeno delay para permitir que a mutation seja processada
  setTimeout(() => {
    isUpdatingFromStore.value = false;
  }, 100);
};

// Debounce para busca
const debouncedApplyFilters = debounce(applyFilters, 300);

const clearFilters = () => {
  localFilters.value = {
    search: '',
    assignedTo: null,
    contact: null,
    label: null,
    column: null,
  };
  store.dispatch('kanban/setFilters', {
    search: '',
    assignedTo: null,
    contact: null,
    label: null,
    column: null,
  });
};

const columnOptions = computed(() => {
  return columns.value.map(col => ({
    label: col.name,
    value: col.id,
  }));
});

const agentOptions = computed(() => {
  return agents.value.map(agent => ({
    label: agent.name,
    value: agent.id,
  }));
});

const labelOptions = computed(() => {
  return labels.value.map(label => ({
    label: label.title,
    value: label.title,
  }));
});

// Não usar watch automático - aplicar filtros apenas via eventos dos componentes
</script>

<template>
  <div class="flex flex-col gap-3 flex-shrink-0 p-4 bg-n-solid-2 border-b border-n-weak">
    <div class="flex items-center gap-3">
      <div class="relative flex-1 max-w-md">
        <Input
          :model-value="localFilters.search"
          :placeholder="t('KANBAN.SEARCH_CARDS')"
          class="w-full"
          @update:model-value="localFilters.search = $event; debouncedApplyFilters()"
        >
          <template #prefix>
            <span class="i-lucide-search size-4 text-n-slate-10" />
          </template>
        </Input>
      </div>
      <Button
        variant="ghost"
        size="sm"
        :icon="showFilters ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="showFilters = !showFilters"
      >
        {{ t('KANBAN.FILTERS') }}
        <span
          v-if="hasActiveFilters"
          class="ml-1.5 size-2 bg-n-brand rounded-full"
        />
      </Button>
      <Button
        v-if="hasActiveFilters"
        variant="ghost"
        size="sm"
        icon="i-lucide-x"
        @click="clearFilters"
      >
        {{ t('KANBAN.CLEAR_FILTERS') }}
      </Button>
    </div>

    <div
      v-if="showFilters"
      class="grid grid-cols-1 gap-3 pt-2 border-t border-n-weak sm:grid-cols-2 lg:grid-cols-4"
    >
      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.FILTER_BY_COLUMN') }}
        </label>
        <ComboBox
          :model-value="localFilters.column"
          :options="columnOptions"
          :placeholder="t('KANBAN.ALL_COLUMNS')"
          clearable
          @update:model-value="localFilters.column = $event; applyFilters()"
        />
      </div>

      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.FILTER_BY_ASSIGNED') }}
        </label>
        <ComboBox
          :model-value="localFilters.assignedTo"
          :options="agentOptions"
          :placeholder="t('KANBAN.ALL_AGENTS')"
          clearable
          @update:model-value="localFilters.assignedTo = $event; applyFilters()"
        />
      </div>

      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.FILTER_BY_LABEL') }}
        </label>
        <ComboBox
          :model-value="localFilters.label"
          :options="labelOptions"
          :placeholder="t('KANBAN.ALL_LABELS')"
          clearable
          @update:model-value="localFilters.label = $event; applyFilters()"
        />
      </div>

      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.FILTER_BY_CONTACT') }}
        </label>
        <Input
          :model-value="localFilters.contact"
          :placeholder="t('KANBAN.CONTACT_ID_PLACEHOLDER')"
          type="number"
          @update:model-value="localFilters.contact = $event ? Number($event) : null; applyFilters()"
        />
      </div>
    </div>
  </div>
</template>

