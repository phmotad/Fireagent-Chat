<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const props = defineProps({
  card: {
    type: Object,
    default: null,
  },
  boardId: {
    type: Number,
    required: true,
  },
  columnId: {
    type: Number,
    default: null,
  },
  initialStartDate: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['update', 'create', 'close']);

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const labels = useMapGetter('labels/getLabels');
const agents = useMapGetter('agents/getAgents');
const columns = useMapGetter('kanban/getColumns');

const formData = ref({
  title: '',
  description: '',
  due_date: '',
  start_date: '',
  end_date: '',
  kanban_column_id: props.columnId || props.card?.kanban_column_id || null,
  contact_id: null,
  conversation_id: null,
  assigned_to_id: null,
  label_list: [],
});

const isEditing = computed(() => !!props.card);

onMounted(() => {
  if (props.card) {
    formData.value = {
      title: props.card.title || '',
      description: props.card.description || '',
      due_date: props.card.due_date
        ? new Date(props.card.due_date).toISOString().split('T')[0]
        : '',
      start_date: props.card.start_date
        ? new Date(props.card.start_date).toISOString().split('T')[0]
        : '',
      end_date: props.card.end_date
        ? new Date(props.card.end_date).toISOString().split('T')[0]
        : '',
      kanban_column_id: props.card.kanban_column_id,
      contact_id: props.card.contact_id,
      conversation_id: props.card.conversation_id,
      assigned_to_id: props.card.assigned_to_id,
      label_list: props.card.label_list || [],
    };
  } else {
    // Se for criação de novo card
    if (props.initialStartDate) {
      // Preencher start_date quando for criação a partir do calendário
      formData.value.start_date = props.initialStartDate;
    }
    // Se não tiver columnId definido, usar a primeira coluna
    if (!formData.value.kanban_column_id && columns.value && columns.value.length > 0) {
      formData.value.kanban_column_id = columns.value[0].id;
    }
  }
  
  store.dispatch('labels/get');
  store.dispatch('agents/get');
});

// Watch para atualizar start_date quando initialStartDate mudar
watch(() => props.initialStartDate, (newDate) => {
  if (newDate && !isEditing.value) {
    formData.value.start_date = newDate;
  }
});

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

const handleSubmit = async () => {
  const submitData = {
    title: formData.value.title,
    description: formData.value.description || null,
    due_date: formData.value.due_date || null,
    start_date: formData.value.start_date || null,
    end_date: formData.value.end_date || null,
    kanban_column_id: formData.value.kanban_column_id,
    contact_id: formData.value.contact_id || null,
    conversation_id: formData.value.conversation_id || null,
    assigned_to_id: formData.value.assigned_to_id || null,
    label_list: formData.value.label_list || [],
  };

  if (isEditing.value) {
    emit('update', submitData);
  } else {
    emit('create', submitData);
  }
};
</script>

<template>
  <div class="p-6">
    <h2 class="mb-4 text-lg font-semibold text-n-slate-12">
      {{ isEditing ? t('KANBAN.EDIT_CARD') : t('KANBAN.CREATE_CARD') }}
    </h2>

    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.CARD_TITLE') }}
        </label>
        <Input
          v-model="formData.title"
          :placeholder="t('KANBAN.CARD_TITLE_PLACEHOLDER')"
          required
        />
      </div>

      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.CARD_DESCRIPTION') }}
        </label>
        <TextArea
          v-model="formData.description"
          :placeholder="t('KANBAN.CARD_DESCRIPTION_PLACEHOLDER')"
          :auto-height="true"
          :min-height="'6rem'"
        />
      </div>

      <div v-if="!props.columnId">
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.COLUMN') }}
        </label>
        <ComboBox
          v-model="formData.kanban_column_id"
          :options="columnOptions"
          :placeholder="t('KANBAN.SELECT_COLUMN')"
        />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.DUE_DATE') }}
          </label>
          <Input v-model="formData.due_date" type="date" />
        </div>

        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.ASSIGNED_TO') }}
          </label>
          <ComboBox
            v-model="formData.assigned_to_id"
            :options="agentOptions"
            :placeholder="t('KANBAN.SELECT_AGENT')"
          />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.START_DATE') }}
          </label>
          <Input v-model="formData.start_date" type="date" />
        </div>

        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.END_DATE') }}
          </label>
          <Input v-model="formData.end_date" type="date" />
        </div>
      </div>

      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.LABELS') }}
        </label>
        <TagMultiSelectComboBox
          v-model="formData.label_list"
          :options="labelOptions"
          :placeholder="t('KANBAN.SELECT_LABELS')"
        />
      </div>

      <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
        <Button
          type="button"
          color="slate"
          variant="ghost"
          @click.stop="emit('close')"
        >
          {{ t('KANBAN.CANCEL') }}
        </Button>
        <Button type="submit" color="blue">
          {{ isEditing ? t('KANBAN.UPDATE') : t('KANBAN.CREATE') }}
        </Button>
      </div>
    </form>
  </div>
</template>

