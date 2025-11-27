<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  boards: {
    type: Array,
    default: () => [],
  },
  selectedBoards: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['change']);

const { t } = useI18n();

const handleToggleBoard = (boardId) => {
  const newSelection = props.selectedBoards.includes(boardId)
    ? props.selectedBoards.filter(id => id !== boardId)
    : [...props.selectedBoards, boardId];
  
  emit('change', newSelection);
};

const handleSelectAll = () => {
  const allBoardIds = props.boards.map(b => b.id);
  emit('change', allBoardIds);
};

const handleDeselectAll = () => {
  emit('change', []);
};

const allSelected = computed(() => {
  return props.boards.length > 0 && 
         props.boards.every(board => props.selectedBoards.includes(board.id));
});
</script>

<template>
  <div class="space-y-4">
    <div>
      <h3 class="text-sm font-semibold text-n-slate-12 mb-2">
        {{ t('AGENDA.FILTER_BOARDS') }}
      </h3>
      <p class="text-xs text-n-slate-11 mb-4">
        {{ t('AGENDA.FILTER_BOARDS_DESCRIPTION') }}
      </p>
      
      <div class="flex gap-2 mb-4">
        <Button
          size="sm"
          variant="ghost"
          @click="handleSelectAll"
        >
          {{ t('AGENDA.SELECT_ALL') }}
        </Button>
        <Button
          size="sm"
          variant="ghost"
          @click="handleDeselectAll"
        >
          {{ t('AGENDA.DESELECT_ALL') }}
        </Button>
      </div>
    </div>

    <div class="space-y-2">
      <div
        v-for="board in boards"
        :key="board.id"
        class="flex items-center gap-2 p-2 rounded-lg hover:bg-n-slate-3 transition-colors cursor-pointer"
        @click="handleToggleBoard(board.id)"
      >
        <input
          type="checkbox"
          :checked="selectedBoards.includes(board.id)"
          @click.stop="handleToggleBoard(board.id)"
          class="w-4 h-4 rounded border-n-weak text-n-blue-9 focus:ring-n-blue-9"
        />
        <label class="flex-1 text-sm text-n-slate-12 cursor-pointer">
          {{ board.name }}
        </label>
      </div>
      
      <div v-if="!boards.length" class="text-xs text-n-slate-11 py-4 text-center">
        {{ t('AGENDA.NO_BOARDS') }}
      </div>
    </div>
  </div>
</template>

