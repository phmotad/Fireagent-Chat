<script setup>
import { onMounted, computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import KanbanCard from '../components/KanbanCard.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();

const boardId = computed(() => Number(route.params.boardId));
const archivedCards = useMapGetter('kanban/getArchivedCards');
const currentBoard = useMapGetter('kanban/getCurrentBoard');
const uiFlags = useMapGetter('kanban/getUIFlags');

const isLoading = computed(() => uiFlags.value.isFetchingArchivedCards);

onMounted(async () => {
  if (boardId.value) {
    await Promise.all([
      store.dispatch('kanban/fetchBoard', boardId.value),
      store.dispatch('kanban/fetchArchivedCards', { boardId: boardId.value }),
    ]);
  }
});

const handleBack = () => {
  router.push(frontendURL(`accounts/${accountId.value}/kanban/${boardId.value}`));
};

const handleUnarchive = async (card) => {
  try {
    await store.dispatch('kanban/unarchiveCard', {
      boardId: boardId.value,
      id: card.id,
    });
    useAlert(t('KANBAN.UNARCHIVE_CARD_SUCCESS'));
    await store.dispatch('kanban/fetchArchivedCards', { boardId: boardId.value });
  } catch (error) {
    console.error('Error unarchiving card:', error);
    useAlert(t('KANBAN.UNARCHIVE_CARD_ERROR'));
  }
};

const handleDelete = async (card) => {
  if (!window.confirm(t('KANBAN.DELETE_CARD_CONFIRM'))) return;

  try {
    await store.dispatch('kanban/deleteCard', {
      boardId: boardId.value,
      id: card.id,
    });
    useAlert(t('KANBAN.DELETE_CARD_SUCCESS'));
    await store.dispatch('kanban/fetchArchivedCards', { boardId: boardId.value });
  } catch (error) {
    console.error('Error deleting card:', error);
    useAlert(t('KANBAN.DELETE_CARD_ERROR'));
  }
};

const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const isCardOlderThan30Days = (archivedAt) => {
  if (!archivedAt) return false;
  const archivedDate = new Date(archivedAt);
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  return archivedDate < thirtyDaysAgo;
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
            {{ t('KANBAN.ARCHIVED_CARDS_TITLE') }} - {{ currentBoard?.name || t('KANBAN.LOADING') }}
          </h1>
          <p class="text-sm text-n-slate-11">
            {{ t('KANBAN.ARCHIVED_CARDS_DESCRIPTION') }}
          </p>
        </div>
      </div>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center flex-1">
      <Spinner />
    </div>

    <div v-else-if="archivedCards.length === 0" class="flex flex-col items-center justify-center flex-1 px-6">
      <div class="text-center max-w-md">
        <div class="mb-6 text-6xl">📦</div>
        <h2 class="mb-2 text-xl font-semibold text-n-slate-12">
          {{ t('KANBAN.ARCHIVED_CARDS_EMPTY_TITLE') }}
        </h2>
        <p class="mb-6 text-n-slate-11">
          {{ t('KANBAN.ARCHIVED_CARDS_EMPTY_DESCRIPTION') }}
        </p>
        <Button variant="ghost" @click="handleBack">
          {{ t('KANBAN.BACK_TO_BOARD') }}
        </Button>
      </div>
    </div>

    <div v-else class="flex-1 overflow-auto p-6">
      <div class="mb-4 text-sm text-n-slate-11">
        {{ t('KANBAN.ARCHIVED_CARDS_COUNT', { count: archivedCards.length }) }}
      </div>
      <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <div
          v-for="card in archivedCards"
          :key="card.id"
          class="flex flex-col p-4 bg-n-solid-2 border border-n-weak rounded-lg"
        >
          <div class="flex-1 mb-3">
            <h3 class="mb-2 text-base font-semibold text-n-slate-12 line-clamp-2">
              {{ card.title }}
            </h3>
            <p
              v-if="card.description"
              class="mb-2 text-sm text-n-slate-11 line-clamp-3"
            >
              {{ card.description }}
            </p>
            <div class="flex flex-col gap-1 text-xs text-n-slate-11">
              <p v-if="card.archived_at">
                <span class="font-medium">{{ t('KANBAN.ARCHIVED_AT') }}:</span>
                {{ formatDate(card.archived_at) }}
              </p>
              <p
                v-if="isCardOlderThan30Days(card.archived_at)"
                class="text-n-orange-11 font-medium"
              >
                {{ t('KANBAN.CARD_WILL_BE_DELETED_SOON') }}
              </p>
            </div>
          </div>
          <div class="flex items-center gap-2 pt-3 border-t border-n-weak">
            <Button
              color="blue"
              variant="ghost"
              size="xs"
              icon="i-lucide-rotate-ccw"
              :is-loading="uiFlags.isUnarchivingCard"
              @click="handleUnarchive(card)"
            >
              {{ t('KANBAN.UNARCHIVE') }}
            </Button>
            <Button
              v-if="isAdmin"
              color="ruby"
              variant="ghost"
              size="xs"
              icon="i-lucide-trash-2"
              :is-loading="uiFlags.isDeletingCard"
              @click="handleDelete(card)"
            >
              {{ t('KANBAN.DELETE') }}
            </Button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

