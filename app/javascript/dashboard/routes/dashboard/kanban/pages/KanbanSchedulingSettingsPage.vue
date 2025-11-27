<script setup>
import { onMounted, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();
const { value: accountIdValue } = accountId;

const locations = useMapGetter('kanban/getLocations');
const rules = useMapGetter('kanban/getRules');
const uiFlags = useMapGetter('kanban/getUIFlags');
const boards = useMapGetter('kanban/getBoards');
const storeColumns = useMapGetter('kanban/getColumns');

// Colunas locais do board selecionado no formulário de regras
const boardColumns = ref([]);
const isLoadingColumns = ref(false);

const isLoading = computed(
  () =>
    uiFlags.value.isFetchingLocations ||
    uiFlags.value.isFetchingRules ||
    uiFlags.value.isFetchingBoards,
);

const locationForm = ref({
  id: null,
  name: '',
  description: '',
  max_capacity: null,
  kanban_board_id: null,
});

const ruleForm = ref({
  id: null,
  title: '',
  description: '',
  kanban_board_id: null,
  kanban_column_id: null,
  kanban_location_id: null,
  rule_type: 'once',
  starts_at: '',
  ends_at: '',
  time_start: '',
  time_end: '',
});

const editingLocation = ref(false);
const editingRule = ref(false);

onMounted(async () => {
  await Promise.all([
    store.dispatch('kanban/fetchBoards'),
    store.dispatch('kanban/fetchLocations'),
    store.dispatch('kanban/fetchRules'),
  ]);
});

// Watch para carregar colunas quando o board selecionado mudar
watch(
  () => ruleForm.value.kanban_board_id,
  async (newBoardId) => {
    // Limpar coluna selecionada quando o board mudar
    ruleForm.value.kanban_column_id = null;
    
    if (!newBoardId) {
      boardColumns.value = [];
      isLoadingColumns.value = false;
      return;
    }
    
    isLoadingColumns.value = true;
    try {
      // Carregar o board completo (inclui colunas)
      await store.dispatch('kanban/fetchBoard', newBoardId);
      // Atualizar colunas locais com as colunas do board carregado
      boardColumns.value = storeColumns.value || [];
    } catch (error) {
      console.error('Error fetching board columns:', error);
      boardColumns.value = [];
    } finally {
      isLoadingColumns.value = false;
    }
  },
);

const resetLocationForm = () => {
  editingLocation.value = false;
  locationForm.value = {
    id: null,
    name: '',
    description: '',
    max_capacity: null,
    kanban_board_id: null,
  };
};

const resetRuleForm = () => {
  editingRule.value = false;
  ruleForm.value = {
    id: null,
    title: '',
    description: '',
    kanban_board_id: null,
    kanban_column_id: null,
    kanban_location_id: null,
    rule_type: 'once',
    starts_at: '',
    ends_at: '',
    time_start: '',
    time_end: '',
  };
  // Limpar colunas quando resetar o formulário
  boardColumns.value = [];
};

const handleLocationSubmit = async () => {
  try {
    const payload = {
      name: locationForm.value.name,
      description: locationForm.value.description,
      max_capacity: locationForm.value.max_capacity,
      kanban_board_id: locationForm.value.kanban_board_id,
    };

    if (editingLocation.value && locationForm.value.id) {
      await store.dispatch('kanban/updateLocation', {
        id: locationForm.value.id,
        ...payload,
      });
      useAlert(t('KANBAN.LOCATION_UPDATE_SUCCESS'));
    } else {
      await store.dispatch('kanban/createLocation', payload);
      useAlert(t('KANBAN.LOCATION_CREATE_SUCCESS'));
    }

    resetLocationForm();
  } catch (error) {
    console.error('Error saving location', error);
    useAlert(t('KANBAN.LOCATION_SAVE_ERROR'));
  }
};

const handleEditLocation = location => {
  editingLocation.value = true;
  locationForm.value = {
    id: location.id,
    name: location.name,
    description: location.description,
    max_capacity: location.max_capacity,
    kanban_board_id: location.kanban_board_id,
  };
};

const handleDeleteLocation = async location => {
  if (!window.confirm(t('KANBAN.LOCATION_DELETE_CONFIRM'))) return;

  try {
    await store.dispatch('kanban/deleteLocation', location.id);
    useAlert(t('KANBAN.LOCATION_DELETE_SUCCESS'));
    if (editingLocation.value && locationForm.value.id === location.id) {
      resetLocationForm();
    }
  } catch (error) {
    console.error('Error deleting location', error);
    useAlert(t('KANBAN.LOCATION_DELETE_ERROR'));
  }
};

const handleRuleSubmit = async () => {
  try {
    const payload = {
      title: ruleForm.value.title,
      description: ruleForm.value.description,
      kanban_board_id: ruleForm.value.kanban_board_id,
      kanban_column_id: ruleForm.value.kanban_column_id,
      kanban_location_id: ruleForm.value.kanban_location_id,
      rule_type: ruleForm.value.rule_type,
      starts_at: ruleForm.value.starts_at,
      ends_at: ruleForm.value.ends_at || null,
      time_start: ruleForm.value.time_start,
      time_end: ruleForm.value.time_end,
    };

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
  } catch (error) {
    console.error('Error saving rule', error);
    useAlert(t('KANBAN.RULE_SAVE_ERROR'));
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
    starts_at: rule.starts_at,
    ends_at: rule.ends_at,
    time_start: rule.time_start,
    time_end: rule.time_end,
  };
  
  // Carregar colunas do board quando editar uma regra
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

const boardOptions = computed(() =>
  (boards.value || []).map(board => ({
    id: board.id,
    name: board.name,
  })),
);

const columnOptions = computed(() =>
  (boardColumns.value || []).map(column => ({
    id: column.id,
    name: column.name,
  })),
);
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-hidden bg-n-background">
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ t('KANBAN.SCHEDULING_SETTINGS_TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('KANBAN.SCHEDULING_SETTINGS_DESCRIPTION') }}
        </p>
      </div>
    </div>

    <div class="flex-1 overflow-auto p-6">
      <div v-if="isLoading" class="flex items-center justify-center h-full">
        <Spinner />
      </div>

      <div v-else class="grid gap-6 md:grid-cols-2">
        <!-- Locations -->
        <div class="flex flex-col gap-4">
          <div>
            <h2 class="text-lg font-semibold text-n-slate-12">
              {{ t('KANBAN.LOCATIONS_TITLE') }}
            </h2>
            <p class="text-sm text-n-slate-11">
              {{ t('KANBAN.LOCATIONS_DESCRIPTION') }}
            </p>
          </div>

          <div class="p-4 bg-n-solid-2 border border-n-weak rounded-lg">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-sm font-semibold text-n-slate-12">
                {{ editingLocation ? t('KANBAN.EDIT_LOCATION') : t('KANBAN.NEW_LOCATION') }}
              </h3>
              <Button
                v-if="editingLocation"
                size="xs"
                variant="ghost"
                @click="resetLocationForm"
              >
                {{ t('KANBAN.CANCEL') }}
              </Button>
            </div>

            <div class="space-y-3">
              <Input
                v-model="locationForm.name"
                :label="t('KANBAN.LOCATION_NAME')"
                :placeholder="t('KANBAN.LOCATION_NAME_PLACEHOLDER')"
                size="md"
              />

              <TextArea
                v-model="locationForm.description"
                :label="t('KANBAN.LOCATION_DESCRIPTION')"
                :placeholder="t('KANBAN.LOCATION_DESCRIPTION_PLACEHOLDER')"
                size="md"
                :autosize="true"
              />

              <Input
                v-model="locationForm.max_capacity"
                type="number"
                :label="t('KANBAN.LOCATION_MAX_CAPACITY')"
                :placeholder="t('KANBAN.LOCATION_MAX_CAPACITY_PLACEHOLDER')"
                size="md"
              />

              <div>
                <label class="block mb-1 text-xs font-medium text-n-slate-11">
                  {{ t('KANBAN.LOCATION_BOARD') }}
                </label>
                <select
                  v-model="locationForm.kanban_board_id"
                  class="w-full px-3 py-2 text-sm border rounded-md bg-n-background border-n-weak text-n-slate-12"
                >
                  <option :value="null">
                    {{ t('KANBAN.SELECT_BOARD_TYPE') }}
                  </option>
                  <option
                    v-for="board in boardOptions"
                    :key="board.id"
                    :value="board.id"
                  >
                    {{ board.name }}
                  </option>
                </select>
              </div>

              <div class="flex justify-end pt-2">
                <Button
                  color="blue"
                  size="sm"
                  :is-loading="uiFlags.isCreatingLocation || uiFlags.isUpdatingLocation"
                  @click="handleLocationSubmit"
                >
                  {{
                    editingLocation
                      ? t('KANBAN.LOCATION_SAVE')
                      : t('KANBAN.LOCATION_CREATE')
                  }}
                </Button>
              </div>
            </div>
          </div>

          <div class="p-4 bg-n-solid-2 border border-n-weak rounded-lg">
            <h3 class="mb-3 text-sm font-semibold text-n-slate-12">
              {{ t('KANBAN.LOCATIONS_LIST_TITLE') }}
            </h3>

            <div v-if="!locations.length" class="text-sm text-n-slate-11">
              {{ t('KANBAN.LOCATIONS_EMPTY') }}
            </div>

            <ul v-else class="space-y-2">
              <li
                v-for="location in locations"
                :key="location.id"
                class="flex items-start justify-between gap-3 p-3 bg-n-background border border-n-weak rounded-md"
              >
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ location.name }}
                    </span>
                    <span
                      v-if="location.max_capacity"
                      class="px-2 py-0.5 text-[11px] rounded-full bg-n-solid-3 text-n-slate-11"
                    >
                      {{ t('KANBAN.LOCATION_CAPACITY_BADGE', { value: location.max_capacity }) }}
                    </span>
                  </div>
                  <p
                    v-if="location.description"
                    class="mt-1 text-xs text-n-slate-11 line-clamp-2"
                  >
                    {{ location.description }}
                  </p>
                </div>
                <div class="flex flex-col items-end gap-1">
                  <Button size="xs" variant="ghost" @click="handleEditLocation(location)">
                    {{ t('KANBAN.EDIT') }}
                  </Button>
                  <Button
                    size="xs"
                    variant="ghost"
                    color="red"
                    @click="handleDeleteLocation(location)"
                  >
                    {{ t('KANBAN.DELETE') }}
                  </Button>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <!-- Rules -->
        <div class="flex flex-col gap-4">
          <div>
            <h2 class="text-lg font-semibold text-n-slate-12">
              {{ t('KANBAN.RULES_TITLE') }}
            </h2>
            <p class="text-sm text-n-slate-11">
              {{ t('KANBAN.RULES_DESCRIPTION') }}
            </p>
          </div>

          <div class="p-4 bg-n-solid-2 border border-n-weak rounded-lg">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-sm font-semibold text-n-slate-12">
                {{ editingRule ? t('KANBAN.EDIT_RULE') : t('KANBAN.NEW_RULE') }}
              </h3>
              <Button
                v-if="editingRule"
                size="xs"
                variant="ghost"
                @click="resetRuleForm"
              >
                {{ t('KANBAN.CANCEL') }}
              </Button>
            </div>

            <div class="space-y-3">
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
                size="md"
                :autosize="true"
              />

              <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
                <div>
                  <label class="block mb-1 text-xs font-medium text-n-slate-11">
                    {{ t('KANBAN.RULE_BOARD') }}
                  </label>
                  <select
                    v-model="ruleForm.kanban_board_id"
                    class="w-full px-3 py-2 text-sm border rounded-md bg-n-background border-n-weak text-n-slate-12"
                  >
                    <option :value="null">
                      {{ t('KANBAN.SELECT_BOARD_TYPE') }}
                    </option>
                    <option
                      v-for="board in boardOptions"
                      :key="board.id"
                      :value="board.id"
                    >
                      {{ board.name }}
                    </option>
                  </select>
                </div>

                <div>
                  <label class="block mb-1 text-xs font-medium text-n-slate-11">
                    {{ t('KANBAN.RULE_COLUMN') }}
                  </label>
                  <select
                    v-model="ruleForm.kanban_column_id"
                    :disabled="isLoadingColumns || !ruleForm.kanban_board_id"
                    class="w-full px-3 py-2 text-sm border rounded-md bg-n-background border-n-weak text-n-slate-12 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <option :value="null">
                      {{
                        isLoadingColumns
                          ? t('KANBAN.LOADING_COLUMNS')
                          : !ruleForm.kanban_board_id
                            ? t('KANBAN.SELECT_BOARD_FIRST')
                            : t('KANBAN.SELECT_COLUMN')
                      }}
                    </option>
                    <option
                      v-for="column in columnOptions"
                      :key="column.id"
                      :value="column.id"
                    >
                      {{ column.name }}
                    </option>
                  </select>
                </div>
              </div>

              <div>
                <label class="block mb-1 text-xs font-medium text-n-slate-11">
                  {{ t('KANBAN.RULE_LOCATION') }}
                </label>
                <select
                  v-model="ruleForm.kanban_location_id"
                  class="w-full px-3 py-2 text-sm border rounded-md bg-n-background border-n-weak text-n-slate-12"
                >
                  <option :value="null">
                    {{ t('KANBAN.SELECT_LOCATION') }}
                  </option>
                  <option
                    v-for="location in locations"
                    :key="location.id"
                    :value="location.id"
                  >
                    {{ location.name }}
                  </option>
                </select>
              </div>

              <div>
                <label class="block mb-1 text-xs font-medium text-n-slate-11">
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

              <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
                <Input
                  v-model="ruleForm.starts_at"
                  type="datetime-local"
                  :label="t('KANBAN.RULE_STARTS_AT')"
                  size="md"
                />
                <Input
                  v-model="ruleForm.ends_at"
                  type="datetime-local"
                  :label="t('KANBAN.RULE_ENDS_AT')"
                  size="md"
                />
              </div>

              <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
                <Input
                  v-model="ruleForm.time_start"
                  type="time"
                  :label="t('KANBAN.RULE_TIME_START')"
                  size="md"
                />
                <Input
                  v-model="ruleForm.time_end"
                  type="time"
                  :label="t('KANBAN.RULE_TIME_END')"
                  size="md"
                />
              </div>

              <div class="flex justify-end pt-2">
                <Button
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
          </div>

          <div class="p-4 bg-n-solid-2 border border-n-weak rounded-lg">
            <h3 class="mb-3 text-sm font-semibold text-n-slate-12">
              {{ t('KANBAN.RULES_LIST_TITLE') }}
            </h3>

            <div v-if="!rules.length" class="text-sm text-n-slate-11">
              {{ t('KANBAN.RULES_EMPTY') }}
            </div>

            <ul v-else class="space-y-2">
              <li
                v-for="rule in rules"
                :key="rule.id"
                class="flex items-start justify-between gap-3 p-3 bg-n-background border border-n-weak rounded-md"
              >
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium text-n-slate-12">
                      {{ rule.title }}
                    </span>
                    <span
                      class="px-2 py-0.5 text-[11px] rounded-full bg-n-solid-3 text-n-slate-11 capitalize"
                    >
                      {{ rule.rule_type }}
                    </span>
                  </div>
                  <p
                    v-if="rule.description"
                    class="mt-1 text-xs text-n-slate-11 line-clamp-2"
                  >
                    {{ rule.description }}
                  </p>
                </div>
                <div class="flex flex-col items-end gap-1">
                  <Button size="xs" variant="ghost" @click="handleEditRule(rule)">
                    {{ t('KANBAN.EDIT') }}
                  </Button>
                  <Button
                    size="xs"
                    variant="ghost"
                    color="red"
                    @click="handleDeleteRule(rule)"
                  >
                    {{ t('KANBAN.DELETE') }}
                  </Button>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


