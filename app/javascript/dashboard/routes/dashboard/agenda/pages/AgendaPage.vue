<script setup>
import { onMounted, ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import BoardFilter from '../components/BoardFilter.vue';
import AgendaView from '../components/AgendaView.vue';

const store = useStore();
const { t } = useI18n();

const boards = useMapGetter('kanban/getBoards');
const agendaData = useMapGetter('agenda/getAgendaData');
const selectedBoards = useMapGetter('agenda/getSelectedBoards');
const viewMode = useMapGetter('agenda/getViewMode');
const uiFlags = useMapGetter('agenda/getUIFlags');

const isLoading = computed(() => uiFlags.value?.isFetchingAgenda || false);

// Filtrar dados baseado nos boards selecionados
const filteredData = computed(() => {
  if (!agendaData.value) {
    return { bookings: [], cards: [] };
  }

  // Agendamentos SEMPRE aparecem, independente dos boards selecionados
  const bookings = Array.isArray(agendaData.value.bookings) ? agendaData.value.bookings : [];
  
  // Cards sempre filtrados pelos boards selecionados
  const cards = (Array.isArray(agendaData.value.cards) ? agendaData.value.cards : []).filter(card => {
    const boardId = card.kanban_board?.id || card.kanban_board_id;
    if (!boardId) return false;
    return selectedBoards.value.includes(boardId);
  });

  return { bookings, cards };
});

const handleBoardFilterChange = async (boardIds) => {
  await store.dispatch('agenda/setSelectedBoards', boardIds);
  // Recarregar dados da agenda com novos filtros
  // Os bookings sempre aparecem, apenas os cards são filtrados
  await store.dispatch('agenda/fetchAgendaData');
};

const handleViewModeChange = (mode) => {
  store.dispatch('agenda/setViewMode', mode);
};

onMounted(async () => {
  // Carregar boards e selecionar todos por padrão
  await store.dispatch('kanban/fetchBoards');
  const allBoardIds = (boards.value || []).map(b => b.id);
  await store.dispatch('agenda/setSelectedBoards', allBoardIds);
  
  // Carregar dados da agenda
  await store.dispatch('agenda/fetchAgendaData');
});
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header -->
    <div class="flex items-center justify-between p-6 border-b border-n-weak">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('AGENDA.TITLE') }}
        </h1>
        <p class="mt-1 text-sm text-n-slate-11">
          {{ t('AGENDA.DESCRIPTION') }}
        </p>
      </div>
      
      <!-- View Mode Toggle -->
      <div class="flex items-center gap-2">
        <button
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
            viewMode === 'calendar'
              ? 'bg-n-blue-3 text-n-blue-11'
              : 'bg-n-solid-2 text-n-slate-11 hover:bg-n-slate-3'
          ]"
          @click="handleViewModeChange('calendar')"
        >
          <i class="i-lucide-calendar mr-2" />
          {{ t('AGENDA.CALENDAR_VIEW') }}
        </button>
        <button
          :class="[
            'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
            viewMode === 'list'
              ? 'bg-n-blue-3 text-n-blue-11'
              : 'bg-n-solid-2 text-n-slate-11 hover:bg-n-slate-3'
          ]"
          @click="handleViewModeChange('list')"
        >
          <i class="i-lucide-list mr-2" />
          {{ t('AGENDA.LIST_VIEW') }}
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex flex-1 overflow-hidden">
      <!-- Sidebar com Filtros -->
      <aside class="w-64 flex-shrink-0 p-6 border-r border-n-weak bg-n-solid-1 overflow-y-auto">
        <BoardFilter
          :boards="boards"
          :selected-boards="selectedBoards"
          @change="handleBoardFilterChange"
        />
      </aside>

      <!-- Main Content -->
      <main class="flex-1 min-w-0 overflow-y-auto w-full">
        <div v-if="isLoading" class="flex items-center justify-center h-full">
          <p class="text-n-slate-11">{{ t('AGENDA.LOADING') }}</p>
        </div>
        <AgendaView
          v-else
          :bookings="filteredData.bookings"
          :cards="filteredData.cards"
          :view-mode="viewMode"
        />
      </main>
    </div>
  </div>
</template>

