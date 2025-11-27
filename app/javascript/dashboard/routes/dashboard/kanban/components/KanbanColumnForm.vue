<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const props = defineProps({
  column: {
    type: Object,
    default: null,
  },
  boardId: {
    type: Number,
    required: true,
  },
  currentBoard: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['submit', 'close']);

const store = useStore();
const { t } = useI18n();
const uiFlags = useMapGetter('kanban/getUIFlags');
const labels = useMapGetter('labels/getLabels');
const agents = useMapGetter('agents/getAgents');

const initialState = () => ({
  name: '',
  color: '#3B82F6',
  wip_limit: null,
  criteria_labels: [],
  auto_message: '',
  on_enter_add_labels: [],
  on_enter_remove_labels: [],
  on_enter_close_conversation: false,
  on_enter_assign_to_id: null,
  on_exit_add_labels: [],
  on_exit_remove_labels: [],
  on_exit_close_conversation: false,
  on_exit_assign_to_id: null,
});
const formData = ref(initialState());

const isEditing = computed(() => !!props.column);
const isConversationBoard = computed(() => props.currentBoard?.card_entity_type === 'conversation');

const colorOptions = [
  { label: 'Azul', value: '#3B82F6' },
  { label: 'Roxo', value: '#8B5CF6' },
  { label: 'Rosa', value: '#EC4899' },
  { label: 'Laranja', value: '#F59E0B' },
  { label: 'Verde', value: '#10B981' },
  { label: 'Vermelho', value: '#EF4444' },
  { label: 'Cinza', value: '#6B7280' },
];

onMounted(() => {
  if (props.column) {
    formData.value = {
      name: props.column.name || '',
      color: props.column.color || '#3B82F6',
      wip_limit: props.column.wip_limit || null,
      criteria_labels: props.column.settings?.criteria_labels || [],
      auto_message: props.column.settings?.auto_message || '',
      // map actions into simple fields (best-effort)
      on_enter_add_labels: extractLabelsFromActions(props.column.settings?.on_enter, 'add_labels'),
      on_enter_remove_labels: extractLabelsFromActions(props.column.settings?.on_enter, 'remove_labels'),
      on_enter_close_conversation: hasActionType(props.column.settings?.on_enter, 'close_conversation'),
      on_enter_assign_to_id: extractAssignToId(props.column.settings?.on_enter),
      on_exit_add_labels: extractLabelsFromActions(props.column.settings?.on_exit, 'add_labels'),
      on_exit_remove_labels: extractLabelsFromActions(props.column.settings?.on_exit, 'remove_labels'),
      on_exit_close_conversation: hasActionType(props.column.settings?.on_exit, 'close_conversation'),
      on_exit_assign_to_id: extractAssignToId(props.column.settings?.on_exit),
    };
  }
  
  store.dispatch('labels/get');
  store.dispatch('agents/get');
});

const handleSubmit = () => {
  if (!formData.value.name.trim()) {
    return;
  }
  
  const buildActions = (prefix) => {
    const actions = [];
    const addLabels = formData.value[`${prefix}_add_labels`] || [];
    const removeLabels = formData.value[`${prefix}_remove_labels`] || [];
    const closeConversation = formData.value[`${prefix}_close_conversation`];
    const assignToId = formData.value[`${prefix}_assign_to_id`];

    if (addLabels.length) {
      actions.push({ type: 'add_labels', values: addLabels });
    }
    if (removeLabels.length) {
      actions.push({ type: 'remove_labels', values: removeLabels });
    }
    if (closeConversation) {
      actions.push({ type: 'close_conversation' });
    }
    if (assignToId) {
      actions.push({ type: 'assign_to', user_id: Number(assignToId) });
    }
    return actions;
  };

  const submitData = {
    ...formData.value,
    settings: {
      criteria_labels: formData.value.criteria_labels,
      auto_message: formData.value.auto_message,
      on_enter: buildActions('on_enter'),
      on_exit: buildActions('on_exit'),
    },
  };
  
  emit('submit', submitData);
};

const handleClose = () => {
  formData.value = initialState();
  emit('close');
};

const labelOptions = computed(() => {
  return (labels.value || []).map(label => ({
    label: label.title || label.name,
    value: label.title || label.name,
  }));
});

const agentOptions = computed(() => {
  return (agents.value || []).map(agent => ({
    label: agent.name || agent.email || `Agente #${agent.id}`,
    value: agent.id,
  }));
});

function extractLabelsFromActions(actions, type) {
  const arr = Array.isArray(actions) ? actions : [];
  const action = arr.find(a => a?.type === type);
  if (!action) return [];
  return Array(action.values || []).filter(Boolean);
}

function hasActionType(actions, type) {
  const arr = Array.isArray(actions) ? actions : [];
  return arr.some(a => a?.type === type);
}

function extractAssignToId(actions) {
  const arr = Array.isArray(actions) ? actions : [];
  const action = arr.find(a => a?.type === 'assign_to');
  return action?.user_id || null;
}
</script>

<template>
  <div class="flex flex-col h-full max-h-[90vh]">
    <div class="flex-shrink-0 px-6 pt-6 pb-4 border-b border-n-weak">
      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ isEditing ? t('KANBAN.EDIT_COLUMN') : t('KANBAN.CREATE_COLUMN') }}
      </h2>
    </div>

    <div class="flex-1 overflow-y-auto px-6 py-4">
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <!-- Informações Básicas -->
        <div class="space-y-4">
          <h3 class="text-sm font-semibold text-n-slate-12 border-b border-n-weak pb-2">
            Informações Básicas
          </h3>
          
          <div>
            <label class="block mb-2 text-sm font-medium text-n-slate-12">
              {{ t('KANBAN.COLUMN_NAME') }}
              <span class="text-n-red-11">*</span>
            </label>
            <Input
              v-model="formData.name"
              :placeholder="t('KANBAN.COLUMN_NAME_PLACEHOLDER')"
              required
              autofocus
            />
          </div>

          <div>
            <label class="block mb-2 text-sm font-medium text-n-slate-12">
              {{ t('KANBAN.COLUMN_COLOR') }}
            </label>
            <div class="flex gap-2 flex-wrap">
              <button
                v-for="colorOption in colorOptions"
                :key="colorOption.value"
                type="button"
                class="w-10 h-10 rounded-lg border-2 transition-all"
                :class="formData.color === colorOption.value ? 'border-n-slate-12 scale-110' : 'border-n-weak hover:border-n-slate-8'"
                :style="{ backgroundColor: colorOption.value }"
                @click="formData.color = colorOption.value"
              />
            </div>
          </div>

          <div>
            <label class="block mb-2 text-sm font-medium text-n-slate-12">
              {{ t('KANBAN.CARD_LIMIT') }}
            </label>
            <Input
              v-model.number="formData.wip_limit"
              type="number"
              :placeholder="t('KANBAN.CARD_LIMIT_PLACEHOLDER')"
              min="1"
            />
          </div>
        </div>

        <!-- Direcionamento Automático -->
        <div class="space-y-4 pt-2 border-t border-n-weak">
          <h3 class="text-sm font-semibold text-n-slate-12 border-b border-n-weak pb-2">
            Direcionamento Automático
          </h3>
          
          <div>
            <label class="block mb-2 text-sm font-medium text-n-slate-12">
              {{ t('KANBAN.CRITERIA_LABELS') }}
            </label>
            <TagMultiSelectComboBox
              v-model="formData.criteria_labels"
              :options="labelOptions"
              :placeholder="t('KANBAN.SELECT_LABELS')"
            />
          </div>
        </div>

        <!-- Mensagem Automática (apenas para contatos) -->
        <div v-if="!isConversationBoard" class="space-y-4 pt-2 border-t border-n-weak">
          <h3 class="text-sm font-semibold text-n-slate-12 border-b border-n-weak pb-2">
            Mensagem Automática
          </h3>
          
          <div>
            <label class="block mb-2 text-sm font-medium text-n-slate-12">
              {{ t('KANBAN.AUTO_MESSAGE') }}
            </label>
            <Input
              v-model="formData.auto_message"
              :placeholder="t('KANBAN.AUTO_MESSAGE_PLACEHOLDER')"
            />
          </div>
        </div>

        <!-- Ações ao entrar na coluna -->
        <div class="space-y-4 pt-2 border-t border-n-weak">
          <h3 class="text-sm font-semibold text-n-slate-12 border-b border-n-weak pb-2">
            {{ t('KANBAN.ACTIONS_ON_ENTER') }}
          </h3>
          <div class="space-y-3">
            <div>
              <label class="block mb-1 text-xs font-medium text-n-slate-11">
                {{ t('KANBAN.ACTION_ADD_LABELS') }}
              </label>
              <TagMultiSelectComboBox
                v-model="formData.on_enter_add_labels"
                :options="labelOptions"
                :placeholder="t('KANBAN.SELECT_LABELS')"
              />
            </div>
            <div>
              <label class="block mb-1 text-xs font-medium text-n-slate-11">
                {{ t('KANBAN.ACTION_REMOVE_LABELS') }}
              </label>
              <TagMultiSelectComboBox
                v-model="formData.on_enter_remove_labels"
                :options="labelOptions"
                :placeholder="t('KANBAN.SELECT_LABELS')"
              />
            </div>
            <div v-if="isConversationBoard" class="flex items-center gap-2">
              <input
                v-model="formData.on_enter_close_conversation"
                type="checkbox"
                class="h-4 w-4"
              />
              <span class="text-xs text-n-slate-11">
                {{ t('KANBAN.ACTION_CLOSE_CONVERSATION') }}
              </span>
            </div>
            <div v-if="isConversationBoard">
              <label class="block mb-1 text-xs font-medium text-n-slate-11">
                {{ t('KANBAN.ACTION_ASSIGN_TO') }}
              </label>
              <ComboBox
                v-model="formData.on_enter_assign_to_id"
                :options="agentOptions"
                :placeholder="t('KANBAN.SELECT_AGENT')"
              />
            </div>
          </div>
        </div>

        <!-- Ações ao sair da coluna -->
        <div class="space-y-4 pt-2 border-t border-n-weak">
          <h3 class="text-sm font-semibold text-n-slate-12 border-b border-n-weak pb-2">
            {{ t('KANBAN.ACTIONS_ON_EXIT') }}
          </h3>
          <div class="space-y-3">
            <div>
              <label class="block mb-1 text-xs font-medium text-n-slate-11">
                {{ t('KANBAN.ACTION_ADD_LABELS') }}
              </label>
              <TagMultiSelectComboBox
                v-model="formData.on_exit_add_labels"
                :options="labelOptions"
                :placeholder="t('KANBAN.SELECT_LABELS')"
              />
            </div>
            <div>
              <label class="block mb-1 text-xs font-medium text-n-slate-11">
                {{ t('KANBAN.ACTION_REMOVE_LABELS') }}
              </label>
              <TagMultiSelectComboBox
                v-model="formData.on_exit_remove_labels"
                :options="labelOptions"
                :placeholder="t('KANBAN.SELECT_LABELS')"
              />
            </div>
            <div v-if="isConversationBoard" class="flex items-center gap-2">
              <input
                v-model="formData.on_exit_close_conversation"
                type="checkbox"
                class="h-4 w-4"
              />
              <span class="text-xs text-n-slate-11">
                {{ t('KANBAN.ACTION_CLOSE_CONVERSATION') }}
              </span>
            </div>
            <div v-if="isConversationBoard">
              <label class="block mb-1 text-xs font-medium text-n-slate-11">
                {{ t('KANBAN.ACTION_ASSIGN_TO') }}
              </label>
              <ComboBox
                v-model="formData.on_exit_assign_to_id"
                :options="agentOptions"
                :placeholder="t('KANBAN.SELECT_AGENT')"
              />
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
          <Button
            type="button"
            color="slate"
            variant="ghost"
            @click="handleClose"
          >
            {{ t('KANBAN.CANCEL') }}
          </Button>
          <Button
            type="submit"
            color="blue"
            :is-loading="uiFlags.isCreatingColumn || uiFlags.isUpdatingColumn"
          >
            {{ isEditing ? t('KANBAN.UPDATE') : t('KANBAN.CREATE') }}
          </Button>
        </div>
      </form>
    </div>
  </div>
</template>
