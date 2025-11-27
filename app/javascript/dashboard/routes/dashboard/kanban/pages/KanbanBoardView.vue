<script setup>
import { onMounted, computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import KanbanColumn from '../components/KanbanColumn.vue';
import KanbanFilters from '../components/KanbanFilters.vue';
import KanbanCalendarView from '../components/KanbanCalendarView.vue';
import KanbanColumnForm from '../components/KanbanColumnForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();

const boardId = computed(() => Number(route.params.boardId));
const currentBoard = useMapGetter('kanban/getCurrentBoard');
const columns = useMapGetter('kanban/getColumns');
const cards = useMapGetter('kanban/getFilteredCards');
const uiFlags = useMapGetter('kanban/getUIFlags');

const viewMode = ref('kanban'); // 'kanban' | 'calendar'
const showColumnForm = ref(false);
const columnFormDialogRef = ref(null);
const editingColumn = ref(null);

onMounted(() => {
  if (boardId.value) {
    store.dispatch('kanban/fetchBoard', boardId.value);
  }
});

// Watch columns para debug
watch(() => columns.value, (newColumns) => {
  console.log('Columns updated in KanbanBoardView:', newColumns);
  console.log('Columns length:', newColumns?.length);
}, { immediate: true, deep: true });

const isLoading = computed(() => uiFlags.value.isFetchingBoard);

const handleBack = () => {
  router.push(frontendURL(`accounts/${accountId.value}/kanban`));
};

const handleCreateColumn = () => {
  editingColumn.value = null;
  showColumnForm.value = true;
  columnFormDialogRef.value?.open();
};

const handleEditColumn = (column) => {
  editingColumn.value = column;
  showColumnForm.value = true;
  columnFormDialogRef.value?.open();
};

const handleColumnSubmit = async (columnData) => {
  try {
    if (editingColumn.value) {
      await store.dispatch('kanban/updateColumn', {
        boardId: boardId.value,
        id: editingColumn.value.id,
        ...columnData,
      });
      // Aguardar um pouco para garantir que o estado seja atualizado
      await new Promise(resolve => setTimeout(resolve, 100));
      useAlert(t('KANBAN.UPDATE_COLUMN_SUCCESS'));
    } else {
      await store.dispatch('kanban/createColumn', {
        boardId: boardId.value,
        ...columnData,
      });
      // Aguardar um pouco para garantir que o estado seja atualizado
      await new Promise(resolve => setTimeout(resolve, 100));
      useAlert(t('KANBAN.CREATE_COLUMN_SUCCESS'));
    }
    showColumnForm.value = false;
    editingColumn.value = null;
    // Fechar o dialog após submissão bem-sucedida
    if (columnFormDialogRef.value) {
      try {
        columnFormDialogRef.value.close();
      } catch (e) {
        // Dialog já está fechado, ignorar
      }
    }
  } catch (error) {
    console.error('Error saving column:', error);
    useAlert(t('KANBAN.CREATE_COLUMN_ERROR'));
  }
};

const handleCloseColumnForm = () => {
  showColumnForm.value = false;
  editingColumn.value = null;
  // Não chamar close() aqui pois o Dialog já emite @close quando é fechado
  // e isso causaria um loop infinito
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-hidden bg-n-background">
    <div class="flex items-center justify-between flex-shrink-0 px-6 py-4 border-b border-n-weak bg-n-background">
      <div class="flex items-center gap-4 min-w-0 flex-1">
        <button
          class="flex-shrink-0 p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg transition-colors"
          @click="handleBack"
        >
          <span class="i-lucide-arrow-left size-5" />
        </button>
        <div class="min-w-0 flex-1">
          <h1 class="text-xl font-semibold text-n-slate-12 truncate">
            {{ currentBoard?.name || t('KANBAN.LOADING') }}
          </h1>
          <p
            v-if="currentBoard?.description"
            class="text-sm text-n-slate-11 truncate"
          >
            {{ currentBoard.description }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-2 flex-shrink-0">
        <Button
          :variant="viewMode === 'kanban' ? 'solid' : 'ghost'"
          size="sm"
          icon="i-lucide-layout-grid"
          @click="viewMode = 'kanban'"
        >
          {{ t('KANBAN.KANBAN_VIEW') }}
        </Button>
        <Button
          :variant="viewMode === 'calendar' ? 'solid' : 'ghost'"
          size="sm"
          icon="i-lucide-calendar"
          @click="viewMode = 'calendar'"
        >
          {{ t('KANBAN.CALENDAR_VIEW') }}
        </Button>
        <Button
          variant="ghost"
          size="sm"
          icon="i-lucide-archive"
          @click="router.push(frontendURL(`accounts/${accountId}/kanban/${boardId}/archived`))"
        >
          {{ t('KANBAN.ARCHIVED_CARDS') }}
        </Button>
      </div>
    </div>

    <KanbanFilters
      v-if="!isLoading"
      :board-id="boardId"
      class="flex-shrink-0"
    />

    <div v-if="isLoading" class="flex items-center justify-center flex-1">
      <Spinner />
    </div>

    <div
      v-else-if="viewMode === 'kanban'"
      class="flex-1 overflow-x-auto overflow-y-hidden min-h-0"
    >
      <div class="flex gap-4 h-full px-6 py-4 min-w-max">
        <KanbanColumn
          v-for="column in columns"
          :key="column.id"
          :column="column"
          :cards="cards.filter(c => c.kanban_column_id === column.id)"
          :board-id="boardId"
          @edit-column="handleEditColumn"
        />
        <div v-if="isAdmin" class="flex-shrink-0 w-80">
          <button
            class="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-n-weak rounded-lg hover:border-n-brand hover:bg-n-alpha-2 transition-colors"
            @click="handleCreateColumn"
          >
            <span class="i-lucide-plus size-6 text-n-slate-11 mb-2" />
            <span class="text-sm font-medium text-n-slate-11">
              {{ t('KANBAN.ADD_COLUMN') }}
            </span>
          </button>
        </div>
      </div>
    </div>

    <KanbanCalendarView
      v-else
      :board-id="boardId"
      class="flex-1 min-h-0"
    />

    <Dialog
      ref="columnFormDialogRef"
      width="md"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="handleCloseColumnForm"
    >
      <KanbanColumnForm
        :column="editingColumn"
        :board-id="boardId"
        :current-board="currentBoard"
        @submit="handleColumnSubmit"
        @close="handleCloseColumnForm"
      />
    </Dialog>
  </div>
</template>

