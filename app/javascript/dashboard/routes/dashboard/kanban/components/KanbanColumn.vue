<script setup>
import { computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import KanbanCard from './KanbanCard.vue';
import KanbanCardForm from './KanbanCardForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  column: {
    type: Object,
    required: true,
  },
  cards: {
    type: Array,
    default: () => [],
  },
  boardId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['create-card', 'edit-column']);

const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const isDragOver = ref(false);

const handleDragOver = event => {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
};

const handleDragEnter = event => {
  event.preventDefault();
  isDragOver.value = true;
};

const handleDragLeave = event => {
  // Evitar falsos positivos quando saímos para elementos internos
  if (event.currentTarget.contains(event.relatedTarget)) {
    return;
  }
  isDragOver.value = false;
};

const handleDrop = async event => {
  try {
    const cardId = Number(event.dataTransfer.getData('kanban-card-id'));
    if (!cardId) {
      return;
    }

    const payload = {
      boardId: props.boardId,
      id: cardId,
      kanban_card: {
        kanban_column_id: props.column.id,
        position: props.cards.length,
      },
    };

    await store.dispatch('kanban/moveCard', payload);
    await store.dispatch('kanban/fetchCards', { boardId: props.boardId });
  } catch (error) {
    console.error('[KanbanColumn] Error dropping card:', error);
    useAlert(t('KANBAN.MOVE_CARD_ERROR'));
  } finally {
    isDragOver.value = false;
  }
};

const wipLimitReached = computed(() => {
  if (!props.column.wip_limit) return false;
  return props.cards.length >= props.column.wip_limit;
});

const showCardForm = ref(false);
const cardFormDialogRef = ref(null);

const handleCreateCard = async () => {
  showCardForm.value = true;
  // Aguardar o próximo tick para garantir que o Dialog foi renderizado
  await nextTick();
  cardFormDialogRef.value?.open();
};

const handleCardCreate = async cardData => {
  try {
    await store.dispatch('kanban/createCard', {
      boardId: props.boardId,
      kanban_card: {
        ...cardData,
        kanban_column_id: props.column.id,
      },
    });
    // Fechar o dialog após criação bem-sucedida
    showCardForm.value = false;
    if (cardFormDialogRef.value) {
      try {
        cardFormDialogRef.value.close();
      } catch (e) {
        // Dialog já está fechado, ignorar
      }
    }
  } catch (error) {
    console.error('Error creating card:', error);
    useAlert(t('KANBAN.CREATE_CARD_ERROR'));
  }
};

const handleCloseCardForm = () => {
  showCardForm.value = false;
  if (cardFormDialogRef.value) {
    try {
      cardFormDialogRef.value.close();
    } catch (e) {
      // Dialog já está fechado, ignorar
    }
  }
};
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-80 h-full bg-n-solid-2 rounded-lg border border-n-weak shadow-sm"
    :style="{ borderTopColor: column.color, borderTopWidth: '3px' }"
  >
    <div class="flex items-center justify-between flex-shrink-0 p-4 border-b border-n-weak">
      <div class="flex items-center gap-2 min-w-0 flex-1">
        <h3 class="font-semibold text-n-slate-12 truncate">{{ column.name }}</h3>
        <span
          class="flex-shrink-0 px-2 py-0.5 text-xs font-medium rounded-full bg-n-solid-3 text-n-slate-11"
        >
          {{ cards.length }}
          <span v-if="column.wip_limit">/ {{ column.wip_limit }}</span>
        </span>
      </div>
      <button
        v-if="isAdmin"
        class="flex-shrink-0 p-1 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded transition-colors"
        @click="emit('edit-column', column)"
      >
        <span class="i-lucide-settings size-4" />
      </button>
    </div>

    <div
      v-if="wipLimitReached"
      class="flex-shrink-0 px-4 py-2 text-xs font-medium text-n-orange-11 bg-n-orange-2 border-b border-n-orange-4"
    >
      {{ t('KANBAN.WIP_LIMIT_REACHED') }}
    </div>

    <div
      class="flex-1 overflow-y-auto p-4 space-y-3 min-h-0 transition-colors duration-150"
      :class="{
        'bg-n-alpha-black1 border border-n-brand/40 rounded-lg':
          isDragOver,
      }"
      @dragover.prevent="handleDragOver"
      @dragenter.prevent="handleDragEnter"
      @dragleave="handleDragLeave"
      @drop="handleDrop"
    >
      <div class="space-y-3 min-h-[40px]">
        <KanbanCard
          v-for="card in cards"
          :key="card.id"
          :card="card"
          :board-id="boardId"
        />
      </div>

      <Button
        v-if="!wipLimitReached"
        color="slate"
        variant="ghost"
        size="sm"
        icon="i-lucide-plus"
        class="w-full mt-2"
        @click="handleCreateCard"
      >
        {{ t('KANBAN.ADD_CARD') }}
      </Button>
    </div>

    <Dialog
      v-if="showCardForm"
      ref="cardFormDialogRef"
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="handleCloseCardForm"
    >
      <KanbanCardForm
        :board-id="boardId"
        :column-id="column.id"
        @create="handleCardCreate"
        @close="handleCloseCardForm"
      />
    </Dialog>
  </div>
</template>

