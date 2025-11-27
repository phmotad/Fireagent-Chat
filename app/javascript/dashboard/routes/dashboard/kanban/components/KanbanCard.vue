<script setup>
import { computed, ref, onMounted, onUnmounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import kanbanAPI from 'dashboard/api/kanban';
import KanbanCardForm from './KanbanCardForm.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
  boardId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const labels = useMapGetter('labels/getLabels');

const isOverdue = computed(() => {
  if (!props.card.due_date) return false;
  return new Date(props.card.due_date) < new Date();
});

const dueDateText = computed(() => {
  if (!props.card.due_date) return null;
  return formatDistanceToNow(new Date(props.card.due_date), {
    addSuffix: true,
    locale: ptBR,
  });
});

const showCardForm = ref(false);
const cardFormDialogRef = ref(null);

let wasDragged = ref(false);
let isMouseDown = ref(false);
let mouseDownTime = ref(null);
let mouseDownPosition = ref(null);

// Escutar eventos globais de drag
onMounted(() => {
  const handleDragStart = (e) => {
    if (e.detail.cardId === props.card.id) {
      wasDragged.value = true;
    }
  };
  
  const handleDragEnd = () => {
    // Resetar após um pequeno delay para evitar cliques acidentais
    setTimeout(() => {
      wasDragged.value = false;
    }, 200);
  };
  
  window.addEventListener('kanban-drag-start', handleDragStart);
  window.addEventListener('kanban-drag-end', handleDragEnd);
  
  // Cleanup
  onUnmounted(() => {
    window.removeEventListener('kanban-drag-start', handleDragStart);
    window.removeEventListener('kanban-drag-end', handleDragEnd);
  });
});

const handleMouseDown = (e) => {
  // Ignorar se for no drag handle ou em qualquer elemento filho do drag handle
  if (e.target.closest('.drag-handle') || e.target.classList.contains('drag-handle')) {
    return;
  }
  isMouseDown.value = true;
  mouseDownTime.value = Date.now();
  mouseDownPosition.value = {
    x: e.clientX,
    y: e.clientY
  };
};

const handleDragStart = event => {
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.dropEffect = 'move';
  event.dataTransfer.setData('kanban-card-id', props.card.id);
  event.dataTransfer.setData(
    'kanban-source-column-id',
    props.card.kanban_column_id
  );
  window.dispatchEvent(
    new CustomEvent('kanban-drag-start', {
      detail: { cardId: props.card.id },
    })
  );
};

const handleDragEnd = () => {
  window.dispatchEvent(
    new CustomEvent('kanban-drag-end', { detail: { cardId: props.card.id } })
  );
};

const openCardForm = () => {
  showCardForm.value = true;
  nextTick(() => {
    cardFormDialogRef.value?.open();
  });
};

const handleMouseUp = (e) => {
  if (!isMouseDown.value) return;
  
  // Se foi um drag recente, não abrir o formulário
  if (wasDragged.value) {
    wasDragged.value = false;
    isMouseDown.value = false;
    mouseDownTime.value = null;
    mouseDownPosition.value = null;
    return;
  }
  
  // Verificar se foi um clique (não um drag)
  const now = Date.now();
  const timeDiff = mouseDownTime.value ? (now - mouseDownTime.value) : 0;
  const positionDiff = mouseDownPosition.value ? {
    x: Math.abs(e.clientX - mouseDownPosition.value.x),
    y: Math.abs(e.clientY - mouseDownPosition.value.y)
  } : { x: 0, y: 0 };
  
  // Se foi um clique rápido e sem movimento significativo, abrir o formulário
  if (timeDiff < 300 && positionDiff.x < 5 && positionDiff.y < 5) {
    openCardForm();
  }
  
  // Resetar
  isMouseDown.value = false;
  mouseDownTime.value = null;
  mouseDownPosition.value = null;
};

const handleCardUpdate = async cardData => {
  await store.dispatch('kanban/updateCard', {
    boardId: props.boardId,
    id: props.card.id,
    kanban_card: cardData,
  });
  showCardForm.value = false;
  // Fechar o dialog após atualização bem-sucedida
  if (cardFormDialogRef.value) {
    try {
      cardFormDialogRef.value.close();
    } catch (e) {
      // Dialog já está fechado, ignorar
    }
  }
};

const handleCloseCardForm = () => {
  showCardForm.value = false;
  // Não chamar close() aqui pois o Dialog já emite @close quando é fechado
  // e isso causaria um loop infinito
};

const handleContactClick = e => {
  e.stopPropagation();
  if (props.card.contact_id) {
    router.push(
      frontendURL(`accounts/${accountId.value}/contacts/${props.card.contact_id}`)
    );
  }
};

const handleConversationClick = e => {
  e.stopPropagation();
  if (props.card.conversation_id) {
    router.push(
      frontendURL(
        `accounts/${accountId.value}/conversations/${props.card.conversation_id}`
      )
    );
  }
};

const isBooking = computed(() => {
  return props.card.custom_attributes?.is_booking === true;
});

const bookingLocationName = computed(() => {
  return props.card.custom_attributes?.booking_location_name || null;
});

// Buscar etiquetas completas com cores
const getLabelColor = (labelName) => {
  const label = labels.value.find(l => l.title === labelName);
  return label?.color || '#6B7280'; // Cor padrão se não encontrar
};

const handleArchive = async (e) => {
  e.stopPropagation();
  try {
    await kanbanAPI.archiveCard(props.boardId, props.card.id);
    await store.dispatch('kanban/fetchCards', { boardId: props.boardId });
    useAlert(t('KANBAN.CARD_ARCHIVED_SUCCESS'));
  } catch (error) {
    console.error('Error archiving card:', error);
    useAlert(t('KANBAN.CARD_ARCHIVE_ERROR'));
  }
};
</script>

<template>
  <div
    :data-card-id="card.id"
    class="p-3 bg-n-background border border-n-weak rounded-lg hover:border-n-brand transition-colors"
    draggable="true"
    @dragstart="handleDragStart"
    @dragend="handleDragEnd"
  >
      <div class="flex items-start justify-between gap-2 mb-1">
      <div class="flex items-center gap-2 flex-1 min-w-0">
        <span 
          class="i-lucide-grip-vertical text-n-slate-9 flex-shrink-0 cursor-move drag-handle"
          style="pointer-events: auto;"
        />
        <div 
          class="flex flex-col flex-1 min-w-0 cursor-pointer"
          @mousedown="handleMouseDown"
          @mouseup="handleMouseUp"
        >
          <div class="flex items-center gap-2">
            <h4 class="flex-1 font-medium text-n-slate-12 truncate">
              {{ card.title }}
            </h4>
            <span
              v-if="isBooking"
              class="px-2 py-0.5 text-[11px] font-semibold rounded-full bg-n-brand/10 text-n-brand flex-shrink-0"
            >
              {{ t('KANBAN.BOOKING_BADGE') }}
            </span>
          </div>
          <p
            v-if="isBooking && bookingLocationName"
            class="text-[11px] text-n-slate-10 truncate"
          >
            {{ bookingLocationName }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-2 flex-shrink-0">
        <Button
          type="button"
          variant="ghost"
          size="xs"
          icon="i-lucide-pencil"
          class="!p-1"
          @click.stop="openCardForm"
        />
        <Button
          v-if="!card.archived_at"
          type="button"
          variant="ghost"
          size="xs"
          icon="i-lucide-archive"
          class="!p-1"
          @click="handleArchive"
        />
        <span
          v-if="isOverdue"
          class="px-2 py-0.5 text-xs font-medium rounded bg-n-red-2 text-n-red-11"
        >
          {{ t('KANBAN.OVERDUE') }}
        </span>
      </div>
    </div>

    <div 
      class="cursor-pointer"
      @mousedown="handleMouseDown"
      @mouseup="handleMouseUp"
    >
      <p
        v-if="card.description"
        class="mb-2 text-sm text-n-slate-11 line-clamp-2"
      >
        {{ card.description }}
      </p>

      <div v-if="card.due_date" class="mb-2 text-xs text-n-slate-10">
        <span class="i-lucide-calendar size-3 inline-block mr-1" />
        {{ dueDateText }}
      </div>

      <div v-if="card.assigned_to" class="mb-2 text-xs text-n-slate-10">
        <span class="i-lucide-user size-3 inline-block mr-1" />
        {{ card.assigned_to?.name }}
      </div>

      <div v-if="card.contact || card.conversation" class="flex gap-2 mb-2">
        <button
          v-if="card.contact"
          class="text-xs text-n-brand hover:underline"
          @click="handleContactClick"
        >
          {{ t('KANBAN.VIEW_CONTACT') }}
        </button>
        <button
          v-if="card.conversation"
          class="text-xs text-n-brand hover:underline"
          @click="handleConversationClick"
        >
          {{ t('KANBAN.VIEW_CONVERSATION') }}
        </button>
      </div>

      <div v-if="card.label_list && card.label_list.length > 0" class="flex flex-wrap gap-1">
        <span
          v-for="label in card.label_list"
          :key="label"
          class="px-2 py-0.5 text-xs rounded"
          :style="{ 
            backgroundColor: `${getLabelColor(label)}20`,
            color: getLabelColor(label),
            border: `1px solid ${getLabelColor(label)}40`
          }"
        >
          {{ label }}
        </span>
      </div>
    </div>
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
      :card="card"
      :board-id="boardId"
      @update="handleCardUpdate"
      @close="handleCloseCardForm"
    />
  </Dialog>
</template>

