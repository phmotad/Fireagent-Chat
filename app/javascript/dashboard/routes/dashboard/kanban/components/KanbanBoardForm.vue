<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  board: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['submit', 'close']);

const store = useStore();
const { t } = useI18n();
const uiFlags = useMapGetter('kanban/getUIFlags');
const inboxes = useMapGetter('inboxes/getInboxes');

const formData = ref({
  name: '',
  description: '',
  board_type: 'custom',
  card_entity_type: 'conversation',
  settings: {
    default_inbox_id: null,
    auto_capture: false,
    apply_template: true,
  },
});

const isEditing = computed(() => !!props.board);

const boardTypes = computed(() => [
  { label: t('KANBAN.BOARD_TYPES.CUSTOM'), value: 'custom' },
  { label: t('KANBAN.BOARD_TYPES.SALES_FUNNEL'), value: 'sales_funnel' },
  { label: t('KANBAN.BOARD_TYPES.SCHEDULING'), value: 'scheduling' },
  { label: t('KANBAN.BOARD_TYPES.CLASSES'), value: 'classes' },
]);

const inboxOptions = computed(() => {
  return (inboxes.value || []).map(inbox => ({
    label: inbox.name,
    value: inbox.id,
  }));
});

onMounted(() => {
  store.dispatch('inboxes/get');
  if (props.board) {
    formData.value = {
      name: props.board.name || '',
      description: props.board.description || '',
      board_type: props.board.board_type || 'custom',
      card_entity_type: props.board.card_entity_type || 'conversation',
      settings: {
        default_inbox_id: props.board.settings?.default_inbox_id || null,
        auto_capture: props.board.settings?.auto_capture || false,
      },
    };
  }
});

const handleSubmit = () => {
  if (!formData.value.name.trim()) {
    return;
  }
  emit('submit', formData.value);
};

const handleClose = () => {
  emit('close');
};
</script>

<template>
  <div class="p-6">
    <h2 class="mb-4 text-lg font-semibold text-n-slate-12">
      {{ isEditing ? t('KANBAN.EDIT_BOARD') : t('KANBAN.CREATE_BOARD') }}
    </h2>

    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.BOARD_NAME') }}
          <span class="text-n-red-11">*</span>
        </label>
        <Input
          v-model="formData.name"
          :placeholder="t('KANBAN.BOARD_NAME_PLACEHOLDER')"
          required
          autofocus
        />
      </div>

      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.BOARD_DESCRIPTION') }}
        </label>
        <TextArea
          v-model="formData.description"
          :placeholder="t('KANBAN.BOARD_DESCRIPTION_PLACEHOLDER')"
          :auto-height="true"
          :min-height="'4rem'"
        />
      </div>

      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.BOARD_TYPE') }}
        </label>
        <ComboBox
          v-model="formData.board_type"
          :options="boardTypes"
          :placeholder="t('KANBAN.SELECT_BOARD_TYPE')"
        />
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.CARD_ENTITY_TYPE') }}
          </label>
          <ComboBox
            v-model="formData.card_entity_type"
            :options="[
              { label: t('KANBAN.CARD_TYPE_CONVERSATION'), value: 'conversation' },
              { label: t('KANBAN.CARD_TYPE_CONTACT'), value: 'contact' },
            ]"
            :placeholder="t('KANBAN.SELECT_CARD_ENTITY_TYPE')"
            allow-empty
          />
        </div>

        <div v-if="formData.card_entity_type === 'conversation'">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.DEFAULT_INBOX') }}
          </label>
          <ComboBox
            v-model="formData.settings.default_inbox_id"
            :options="inboxOptions"
            :placeholder="t('KANBAN.DEFAULT_INBOX_PLACEHOLDER')"
            allow-empty
          />
          <p class="mt-1 text-xs text-n-slate-11">
            {{ t('KANBAN.DEFAULT_INBOX_HELP') }}
          </p>
        </div>
      </div>

      <div>
        <label class="flex items-start gap-2 text-sm text-n-slate-12">
          <input
            v-model="formData.settings.auto_capture"
            type="checkbox"
            class="mt-1"
          />
          <span>
            <span class="font-medium block">{{ t('KANBAN.AUTO_CAPTURE') }}</span>
            <span class="text-n-slate-11 text-xs">
              {{ t('KANBAN.AUTO_CAPTURE_HELP') }}
            </span>
          </span>
        </label>
      </div>

      <div v-if="formData.board_type !== 'custom'">
        <label class="flex items-start gap-2 text-sm text-n-slate-12">
          <input
            v-model="formData.settings.apply_template"
            type="checkbox"
            class="mt-1"
          />
          <span>
            <span class="font-medium block">{{ t('KANBAN.APPLY_TEMPLATE') }}</span>
            <span class="text-n-slate-11 text-xs">
              {{ t('KANBAN.APPLY_TEMPLATE_HELP') }}
            </span>
          </span>
        </label>
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
          :is-loading="uiFlags.isCreatingBoard"
        >
          {{ isEditing ? t('KANBAN.UPDATE') : t('KANBAN.CREATE') }}
        </Button>
      </div>
    </form>
  </div>
</template>

