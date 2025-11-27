<script setup>
import { onMounted, computed, ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

const store = useStore();
const { t } = useI18n();

const rules = useMapGetter('kanban/getRules');
const locations = useMapGetter('kanban/getLocations');
const boards = useMapGetter('kanban/getBoards');
const storeColumns = useMapGetter('kanban/getColumns');
const uiFlags = useMapGetter('kanban/getUIFlags');

const editingRule = ref(false);
const boardColumns = ref([]);
const isLoadingColumns = ref(false);
const showRuleFormModal = ref(false);
const ruleFormDialogRef = ref(null);
const isDialogClosing = ref(false);

const defaultRuleForm = () => ({
  id: null,
  title: '',
  description: '',
  kanban_board_id: null,
  kanban_column_id: null,
  kanban_location_id: null,
  rule_type: 'once',
  active: true,
});

const ruleForm = ref(defaultRuleForm());

const isLoading = computed(
  () =>
    uiFlags.value.isFetchingRules ||
    uiFlags.value.isFetchingBoards ||
    uiFlags.value.isFetchingLocations ||
    uiFlags.value.isCreatingRule ||
    uiFlags.value.isUpdatingRule ||
    isLoadingColumns.value,
);

const boardOptions = computed(() =>
  (boards.value || []).map(board => ({
    value: board.id,
    label: board.name,
  })),
);

const locationOptions = computed(() =>
  (locations.value || []).map(location => ({
    value: location.id,
    label: location.name,
  })),
);

const columnOptions = computed(() =>
  (boardColumns.value || []).map(column => ({
    value: column.id,
    label: column.name,
  })),
);

watch(
  () => ruleForm.value.kanban_board_id,
  async (newBoardId) => {
    if (isDialogClosing.value) return;
    
    ruleForm.value.kanban_column_id = null;
    
    if (!newBoardId) {
      boardColumns.value = [];
      isLoadingColumns.value = false;
      return;
    }
    
    isLoadingColumns.value = true;
    try {
      console.log('[KanbanRules] Fetching board columns for board:', newBoardId);
      await store.dispatch('kanban/fetchBoard', newBoardId);
      boardColumns.value = storeColumns.value || [];
      console.log('[KanbanRules] Board columns loaded:', boardColumns.value.length);
    } catch (error) {
      console.error('[KanbanRules] Error fetching board columns:', error);
      boardColumns.value = [];
    } finally {
      isLoadingColumns.value = false;
    }
  },
);

const handleDialogClose = () => {
  if (isDialogClosing.value || isLoadingColumns.value) {
    return;
  }
  
  isDialogClosing.value = true;
  resetRuleForm();
  setTimeout(() => {
    isDialogClosing.value = false;
  }, 200);
};

const resetRuleForm = () => {
  editingRule.value = false;
  ruleForm.value = defaultRuleForm();
  boardColumns.value = [];
  showRuleFormModal.value = false;
};

const handleNewRule = async () => {
  editingRule.value = false;
  ruleForm.value = defaultRuleForm();
  boardColumns.value = [];
  showRuleFormModal.value = true;
  await nextTick();
  await nextTick();
  if (ruleFormDialogRef.value) {
    ruleFormDialogRef.value.open();
  } else {
    console.error('[KanbanRules] Dialog ref not available');
  }
};

const handleRuleSubmit = async () => {
  try {
    if (!ruleForm.value.title || !ruleForm.value.title.trim()) {
      useAlert(t('KANBAN.RULE_TITLE_REQUIRED'));
      return;
    }

    if (!ruleForm.value.kanban_board_id) {
      useAlert(t('KANBAN.RULE_BOARD_REQUIRED'));
      return;
    }

    if (!ruleForm.value.kanban_location_id) {
      useAlert(t('KANBAN.RULE_LOCATION_REQUIRED'));
      return;
    }
    
    const payload = {
      title: ruleForm.value.title.trim(),
      description: ruleForm.value.description || '',
      kanban_board_id: ruleForm.value.kanban_board_id,
      kanban_column_id: ruleForm.value.kanban_column_id || null,
      kanban_location_id: ruleForm.value.kanban_location_id,
      rule_type: ruleForm.value.rule_type || 'once',
      active: ruleForm.value.active,
    };

    console.log('[KanbanRules] Submitting payload:', payload);

    if (editingRule.value && ruleForm.value.id) {
      await store.dispatch('kanban/updateRule', {
        id: ruleForm.value.id,
        ...payload,
      });
      useAlert(t('KANBAN.RULE_UPDATE_SUCCESS'));
    } else {
      await store.dispatch('kanban/createRule', payload);
      useAlert(t('KANBAN.RULE_CREATE_SUCCESS'));
    }

    resetRuleForm();
    ruleFormDialogRef.value?.close();
  } catch (error) {
    console.error('Error saving rule', error);
    const errorMessage = error?.response?.data?.error || error?.message || t('KANBAN.RULE_SAVE_ERROR');
    useAlert(errorMessage);
  }
};

const handleEditRule = async rule => {
  editingRule.value = true;
  ruleForm.value = {
    id: rule.id,
    title: rule.title,
    description: rule.description,
    kanban_board_id: rule.kanban_board_id,
    kanban_column_id: rule.kanban_column_id,
    kanban_location_id: rule.kanban_location_id,
    rule_type: rule.rule_type,
    active: rule.active ?? true,
  };
  
  if (rule.kanban_board_id) {
    isLoadingColumns.value = true;
    try {
      await store.dispatch('kanban/fetchBoard', rule.kanban_board_id);
      boardColumns.value = storeColumns.value || [];
    } catch (error) {
      console.error('Error fetching board columns for edit:', error);
      boardColumns.value = [];
    } finally {
      isLoadingColumns.value = false;
    }
  } else {
    boardColumns.value = [];
  }
  showRuleFormModal.value = true;
  await nextTick();
  await nextTick();
  if (ruleFormDialogRef.value) {
    ruleFormDialogRef.value.open();
  } else {
    console.error('[KanbanRules] Dialog ref not available');
  }
};

const handleDeleteRule = async rule => {
  if (!window.confirm(t('KANBAN.RULE_DELETE_CONFIRM'))) return;

  try {
    await store.dispatch('kanban/deleteRule', rule.id);
    useAlert(t('KANBAN.RULE_DELETE_SUCCESS'));
    if (editingRule.value && ruleForm.value.id === rule.id) {
      resetRuleForm();
    }
  } catch (error) {
    console.error('Error deleting rule', error);
    useAlert(t('KANBAN.RULE_DELETE_ERROR'));
  }
};

onMounted(async () => {
  await Promise.all([
    store.dispatch('kanban/fetchBoards'),
    store.dispatch('kanban/fetchLocations'),
    store.dispatch('kanban/fetchRules'),
  ]);
});

defineExpose({
  handleNewRule,
});
</script>

<template>
  <div class="grid gap-6">
    <!-- List -->
    <div class="p-6 bg-n-solid-2 border border-n-weak rounded-lg">
      <h3 class="mb-4 text-base font-semibold text-n-slate-12">
        {{ t('KANBAN.RULES_LIST_TITLE') }}
      </h3>

      <div v-if="!rules.length && !isLoading" class="py-8 text-sm text-center text-n-slate-11">
        {{ t('KANBAN.RULES_EMPTY') }}
      </div>

      <div v-else-if="isLoading" class="py-8 text-sm text-center text-n-slate-11">
        {{ t('KANBAN.LOADING') }}
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="rule in rules"
          :key="rule.id"
          class="flex items-start justify-between gap-4 p-4 bg-n-background border border-n-weak rounded-lg hover:border-n-slate-6 transition-colors"
        >
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h4 class="text-sm font-semibold text-n-slate-12">
                {{ rule.title }}
              </h4>
              <span
                class="px-2 py-0.5 text-[11px] font-medium rounded-full bg-n-brand/10 text-n-brand capitalize"
              >
                {{ rule.rule_type }}
              </span>
              <span
                v-if="!rule.active"
                class="px-2 py-0.5 text-[11px] font-semibold tracking-wide uppercase rounded-full bg-n-ruby-50 text-n-ruby-11"
              >
                {{ t('KANBAN.RULE_INACTIVE_BADGE') }}
              </span>
            </div>
            <div class="space-y-1">
              <p
                v-if="rule.description"
                class="text-xs text-n-slate-11 line-clamp-2"
              >
                {{ rule.description }}
              </p>
              <p
                v-if="!rule.active"
                class="text-[11px] text-n-ruby-10"
              >
                {{ t('KANBAN.RULE_INACTIVE_BOOKING_FORBIDDEN') }}
              </p>
            </div>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <Button
              size="sm"
              variant="ghost"
              @click="handleEditRule(rule)"
            >
              {{ t('KANBAN.EDIT') }}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              color="ruby"
              @click="handleDeleteRule(rule)"
            >
              {{ t('KANBAN.DELETE') }}
            </Button>
          </div>
        </div>
      </div>
    </div>

    <Dialog
      ref="ruleFormDialogRef"
      :title="editingRule ? t('KANBAN.EDIT_RULE') : t('KANBAN.NEW_RULE')"
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="handleDialogClose"
    >
      <div v-if="showRuleFormModal" class="p-6 space-y-4" data-dialog-content @click.stop @mousedown.stop>
        <Input
          v-model="ruleForm.title"
          :label="t('KANBAN.RULE_TITLE')"
          :placeholder="t('KANBAN.RULE_TITLE_PLACEHOLDER')"
          size="md"
        />

        <TextArea
          v-model="ruleForm.description"
          :label="t('KANBAN.RULE_DESCRIPTION')"
          :placeholder="t('KANBAN.RULE_DESCRIPTION_PLACEHOLDER')"
          :autosize="true"
        />

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div @click.stop>
            <label class="block mb-2 text-sm font-medium text-n-slate-11">
              {{ t('KANBAN.RULE_BOARD') }}
            </label>
            <ComboBox
              v-model="ruleForm.kanban_board_id"
              :options="boardOptions"
              :placeholder="t('KANBAN.SELECT_BOARD_TYPE')"
            />
          </div>

          <div @click.stop>
            <label class="block mb-2 text-sm font-medium text-n-slate-11">
              {{ t('KANBAN.RULE_COLUMN') }}
            </label>
            <ComboBox
              v-model="ruleForm.kanban_column_id"
              :options="columnOptions"
              :placeholder="
                isLoadingColumns
                  ? t('KANBAN.LOADING_COLUMNS')
                  : !ruleForm.kanban_board_id
                    ? t('KANBAN.SELECT_BOARD_FIRST')
                    : t('KANBAN.SELECT_COLUMN')
              "
              :disabled="isLoadingColumns || !ruleForm.kanban_board_id"
            />
          </div>
        </div>

        <div @click.stop>
          <label class="block mb-2 text-sm font-medium text-n-slate-11">
            {{ t('KANBAN.RULE_LOCATION') }}
          </label>
          <ComboBox
            v-model="ruleForm.kanban_location_id"
            :options="locationOptions"
            :placeholder="t('KANBAN.SELECT_LOCATION')"
          />
        </div>

        <div>
          <label class="block mb-2 text-sm font-medium text-n-slate-11">
            {{ t('KANBAN.RULE_TYPE') }}
          </label>
          <select
            v-model="ruleForm.rule_type"
            class="w-full px-3 py-2 text-sm border rounded-md bg-n-background border-n-weak text-n-slate-12"
          >
            <option value="once">
              {{ t('KANBAN.RULE_TYPE_ONCE') }}
            </option>
            <option value="weekly">
              {{ t('KANBAN.RULE_TYPE_WEEKLY') }}
            </option>
          </select>
        </div>

        <div class="flex items-center justify-between p-4 border rounded-lg bg-n-solid-2 border-n-weak">
          <div class="flex-1 pr-4">
            <p class="text-sm font-semibold text-n-slate-12">
              {{ t('KANBAN.RULE_ACTIVE_LABEL') }}
            </p>
            <p class="mt-1 text-xs text-n-slate-11">
              {{ t('KANBAN.RULE_ACTIVE_HINT') }}
            </p>
          </div>
          <ToggleSwitch v-model="ruleForm.active">
            <template #label>
              <span class="text-sm font-medium text-n-slate-12">
                {{ ruleForm.active ? t('KANBAN.RULE_STATUS_ACTIVE') : t('KANBAN.RULE_STATUS_INACTIVE') }}
              </span>
            </template>
          </ToggleSwitch>
        </div>

        <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
          <Button
            type="button"
            variant="ghost"
            size="sm"
            @click="resetRuleForm"
          >
            {{ t('KANBAN.CANCEL') }}
          </Button>
          <Button
            type="button"
            color="blue"
            size="sm"
            :is-loading="uiFlags.isCreatingRule || uiFlags.isUpdatingRule"
            @click="handleRuleSubmit"
          >
            {{
              editingRule ? t('KANBAN.RULE_SAVE') : t('KANBAN.RULE_CREATE')
            }}
          </Button>
        </div>
      </div>
    </Dialog>
  </div>
</template>

