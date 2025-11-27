<script setup>
import { onMounted, computed, ref, watch, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import KanbanBoardForm from '../components/KanbanBoardForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();

const boards = useMapGetter('kanban/getBoards');
const uiFlags = useMapGetter('kanban/getUIFlags');

const showCreateBoardModal = ref(false);
const createBoardDialogRef = ref(null);
const showArchived = ref(false);
const editingBoard = ref(null);

onMounted(() => {
  store.dispatch('kanban/fetchBoards', { includeArchived: showArchived.value });
});

const toggleArchived = () => {
  showArchived.value = !showArchived.value;
  store.dispatch('kanban/fetchBoards', { includeArchived: showArchived.value });
};

const isLoading = computed(() => uiFlags.value.isFetchingBoards);

// Watch para abrir o Dialog quando showCreateBoardModal mudar para true
watch(
  () => showCreateBoardModal.value,
  async (isOpen) => {
    if (isOpen) {
      await nextTick();
      await nextTick(); // Double nextTick para garantir que o conteúdo foi renderizado
      if (createBoardDialogRef.value) {
        createBoardDialogRef.value.open();
      }
    }
  },
);

const handleCreateBoard = () => {
  editingBoard.value = null;
  showCreateBoardModal.value = true;
  // O watch vai abrir o Dialog automaticamente
};

const handleEditBoard = (board) => {
  editingBoard.value = board;
  showCreateBoardModal.value = true;
  // O watch vai abrir o Dialog automaticamente
};

const handleBoardSubmit = async (boardData) => {
  try {
    if (editingBoard.value) {
      await store.dispatch('kanban/updateBoard', {
        id: editingBoard.value.id,
        ...boardData,
      });
      useAlert(t('KANBAN.UPDATE_BOARD_SUCCESS'));
    } else {
      const createdBoard = await store.dispatch('kanban/createBoard', boardData);
      useAlert(t('KANBAN.CREATE_BOARD_SUCCESS'));
      showCreateBoardModal.value = false;
      createBoardDialogRef.value?.close();
      router.push(frontendURL(`accounts/${accountId.value}/kanban/${createdBoard.id}`));
      return;
    }
    showCreateBoardModal.value = false;
    createBoardDialogRef.value?.close();
    editingBoard.value = null;
    await store.dispatch('kanban/fetchBoards', { includeArchived: showArchived.value });
  } catch (error) {
    console.error('Error saving board:', error);
    useAlert(editingBoard.value ? t('KANBAN.UPDATE_BOARD_ERROR') : t('KANBAN.CREATE_BOARD_ERROR'));
  }
};

const handleCloseDialog = () => {
  showCreateBoardModal.value = false;
  createBoardDialogRef.value?.close();
  editingBoard.value = null;
};

const handleBoardClick = boardId => {
  router.push(frontendURL(`accounts/${accountId.value}/kanban/${boardId}`));
};

const onArchive = async id => {
  try {
    await store.dispatch('kanban/archiveBoard', id);
    useAlert(t('KANBAN.ARCHIVE_SUCCESS'));
    await store.dispatch('kanban/fetchBoards', { includeArchived: showArchived.value });
  } catch (e) {
    useAlert(t('KANBAN.ARCHIVE_ERROR'));
  }
};

const onUnarchive = async id => {
  try {
    await store.dispatch('kanban/unarchiveBoard', id);
    useAlert(t('KANBAN.UNARCHIVE_SUCCESS'));
    await store.dispatch('kanban/fetchBoards', { includeArchived: showArchived.value });
  } catch (e) {
    useAlert(t('KANBAN.UNARCHIVE_ERROR'));
  }
};

const onDelete = async id => {
  if (!window.confirm(t('KANBAN.DELETE_BOARD_CONFIRM'))) return;
  
  try {
    await store.dispatch('kanban/deleteBoard', id);
    useAlert(t('KANBAN.DELETE_BOARD_SUCCESS'));
    await store.dispatch('kanban/fetchBoards', { includeArchived: showArchived.value });
  } catch (e) {
    useAlert(t('KANBAN.DELETE_BOARD_ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <div class="flex items-center justify-between flex-shrink-0 px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-4">
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ t('KANBAN.TITLE') }}
        </h1>
        <Button
          v-if="isAdmin"
          :variant="showArchived ? 'solid' : 'ghost'"
          size="sm"
          icon="i-lucide-archive"
          @click="toggleArchived"
        >
          {{ showArchived ? t('KANBAN.SHOW_ACTIVE') : t('KANBAN.SHOW_ARCHIVED') }}
        </Button>
      </div>
      <Button
        v-if="isAdmin"
        color="blue"
        size="md"
        icon="i-lucide-plus"
        :is-loading="uiFlags.isCreatingBoard"
        @click="handleCreateBoard"
      >
        {{ t('KANBAN.CREATE_BOARD') }}
      </Button>
    </div>

    <div class="flex flex-col flex-1 overflow-hidden">
      <div class="flex-1 w-full overflow-auto">
        <div v-if="isLoading" class="flex items-center justify-center h-full">
          <Spinner />
        </div>

        <div
          v-else-if="boards.length === 0"
          class="flex flex-col items-center justify-center h-full w-full px-6"
        >
        <div class="text-center max-w-md">
          <div class="mb-6 text-6xl">📋</div>
          <h2 class="mb-2 text-xl font-semibold text-n-slate-12">
            {{ t('KANBAN.EMPTY_STATE.TITLE') }}
          </h2>
          <p class="mb-6 text-n-slate-11">
            {{ t('KANBAN.EMPTY_STATE.DESCRIPTION') }}
          </p>
          <Button
            color="blue"
            size="md"
            icon="i-lucide-plus"
            :is-loading="uiFlags.isCreatingBoard"
            @click="handleCreateBoard"
          >
            {{ t('KANBAN.CREATE_FIRST_BOARD') }}
          </Button>
        </div>
        </div>

        <div v-else class="w-full p-6">
        <div class="grid grid-cols-1 gap-4 w-full md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
          <div
            v-for="board in boards"
            :key="board.id"
            class="flex flex-col p-5 bg-n-solid-2 border border-n-weak rounded-lg cursor-pointer transition-all hover:border-n-brand hover:shadow-md"
                   @click="handleBoardClick(board.id)"
          >
            <h3 class="mb-2 text-lg font-semibold text-n-slate-12 line-clamp-2">
              {{ board.name }}
            </h3>
            <p
              v-if="board.description"
              class="mb-4 text-sm text-n-slate-11 line-clamp-3 flex-1"
            >
              {{ board.description }}
            </p>
            <div class="flex items-center gap-2 mt-auto">
              <span
                class="px-2 py-1 text-xs font-medium rounded bg-n-solid-3 text-n-slate-11 capitalize"
              >
                {{ board.board_type?.replace('_', ' ') }}
              </span>
                     <span
                       v-if="board.archived_at"
                       class="px-2 py-1 text-xs font-medium rounded bg-n-red-3 text-n-red-11"
                     >
                       {{ t('KANBAN.ARCHIVED') }}
                     </span>
            </div>
                   <div v-if="isAdmin" class="flex items-center gap-2 mt-3">
                     <Button
                       v-if="!board.archived_at"
                       color="slate"
                       variant="ghost"
                       size="xs"
                       icon="i-lucide-edit"
                       @click.stop="handleEditBoard(board)"
                     >
                       {{ t('KANBAN.EDIT') }}
                     </Button>
                     <Button
                       v-if="!board.archived_at"
                       color="slate"
                       variant="ghost"
                       size="xs"
                       icon="i-lucide-archive"
                       @click.stop="onArchive(board.id)"
                     >
                       {{ t('KANBAN.ARCHIVE') }}
                     </Button>
                     <Button
                       v-else
                       color="blue"
                       variant="ghost"
                       size="xs"
                       icon="i-lucide-rotate-ccw"
                       @click.stop="onUnarchive(board.id)"
                     >
                       {{ t('KANBAN.UNARCHIVE') }}
                     </Button>
                     <Button
                       v-if="board.archived_at"
                       color="ruby"
                       variant="ghost"
                       size="xs"
                       icon="i-lucide-trash-2"
                       @click.stop="onDelete(board.id)"
                     >
                       {{ t('KANBAN.DELETE') }}
                     </Button>
                   </div>
          </div>
        </div>
      </div>
      </div>
    </div>

    <Dialog
      v-if="showCreateBoardModal"
      ref="createBoardDialogRef"
      width="md"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="handleCloseDialog"
    >
      <KanbanBoardForm
        :board="editingBoard"
        @submit="handleBoardSubmit"
        @close="handleCloseDialog"
      />
    </Dialog>
  </div>
</template>

