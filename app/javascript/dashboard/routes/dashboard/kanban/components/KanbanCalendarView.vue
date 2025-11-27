<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, isSameDay, addMonths, subMonths, startOfWeek, endOfWeek } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import KanbanCard from './KanbanCard.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import KanbanCardForm from './KanbanCardForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  boardId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const cards = useMapGetter('kanban/getFilteredCards');
const columns = useMapGetter('kanban/getColumns');
const currentDate = ref(new Date());
const viewMode = ref('month'); // 'month' | 'week' | 'day'

const monthStart = computed(() => startOfMonth(currentDate.value));
const monthEnd = computed(() => endOfMonth(currentDate.value));
const weekStart = computed(() => startOfWeek(currentDate.value, { locale: ptBR }));
const weekEnd = computed(() => endOfWeek(currentDate.value, { locale: ptBR }));

const calendarDays = computed(() => {
  if (viewMode.value === 'month') {
    const start = startOfWeek(monthStart.value, { locale: ptBR });
    const end = endOfWeek(monthEnd.value, { locale: ptBR });
    return eachDayOfInterval({ start, end });
  } else if (viewMode.value === 'week') {
    return eachDayOfInterval({ start: weekStart.value, end: weekEnd.value });
  } else {
    return [currentDate.value];
  }
});

const cardsByDate = computed(() => {
  const grouped = {};
  cards.value.forEach(card => {
    if (card.due_date || card.start_date) {
      const dateKey = format(
        new Date(card.due_date || card.start_date),
        'yyyy-MM-dd'
      );
      if (!grouped[dateKey]) {
        grouped[dateKey] = [];
      }
      grouped[dateKey].push(card);
    }
  });
  return grouped;
});

const getCardsForDate = date => {
  const dateKey = format(date, 'yyyy-MM-dd');
  return cardsByDate.value[dateKey] || [];
};

const isToday = date => {
  return isSameDay(date, new Date());
};

const isCurrentMonth = date => {
  return isSameMonth(date, currentDate.value);
};

const previousPeriod = () => {
  if (viewMode.value === 'month') {
    currentDate.value = subMonths(currentDate.value, 1);
  } else if (viewMode.value === 'week') {
    currentDate.value = subMonths(currentDate.value, 0);
    currentDate.value.setDate(currentDate.value.getDate() - 7);
  } else {
    currentDate.value = subMonths(currentDate.value, 0);
    currentDate.value.setDate(currentDate.value.getDate() - 1);
  }
};

const nextPeriod = () => {
  if (viewMode.value === 'month') {
    currentDate.value = addMonths(currentDate.value, 1);
  } else if (viewMode.value === 'week') {
    currentDate.value = addMonths(currentDate.value, 0);
    currentDate.value.setDate(currentDate.value.getDate() + 7);
  } else {
    currentDate.value = addMonths(currentDate.value, 0);
    currentDate.value.setDate(currentDate.value.getDate() + 1);
  }
};

const goToToday = () => {
  currentDate.value = new Date();
};

const weekDays = computed(() => {
  return ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
});

const selectedCard = ref(null);
const showCardDialog = ref(false);
const cardDialogRef = ref(null);
const isCreatingCard = ref(false);
const initialStartDate = ref(null);

const handleCardClick = card => {
  selectedCard.value = card;
  isCreatingCard.value = false;
  showCardDialog.value = true;
  cardDialogRef.value?.open();
};

const handleQuickCreate = date => {
  selectedCard.value = null;
  isCreatingCard.value = true;
  initialStartDate.value = format(date, 'yyyy-MM-dd');
  showCardDialog.value = true;
  cardDialogRef.value?.open();
};

const handleCardCreate = async cardData => {
  try {
    await store.dispatch('kanban/createCard', {
      boardId: props.boardId,
      kanban_card: cardData,
    });
    showCardDialog.value = false;
    isCreatingCard.value = false;
    initialStartDate.value = null;
    cardDialogRef.value?.close();
  } catch (error) {
    console.error('Error creating card:', error);
  }
};

const handleCardUpdate = async cardData => {
  await store.dispatch('kanban/updateCard', {
    boardId: props.boardId,
    id: selectedCard.value.id,
    kanban_card: cardData,
  });
  showCardDialog.value = false;
  selectedCard.value = null;
  isCreatingCard.value = false;
  cardDialogRef.value?.close();
};

const handleCloseCardDialog = () => {
  showCardDialog.value = false;
  selectedCard.value = null;
  isCreatingCard.value = false;
  initialStartDate.value = null;
  cardDialogRef.value?.close();
};
</script>

<template>
  <div class="flex flex-col h-full min-h-0 bg-n-background">
    <!-- Calendar Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-4">
        <Button
          variant="ghost"
          size="sm"
          icon="i-lucide-chevron-left"
          @click="previousPeriod"
        />
        <h2 class="text-lg font-semibold text-n-slate-12">
          <span v-if="viewMode === 'month'">
            {{ format(currentDate, 'MMMM yyyy', { locale: ptBR }) }}
          </span>
          <span v-else-if="viewMode === 'week'">
            {{ format(weekStart, 'dd MMM', { locale: ptBR }) }} - 
            {{ format(weekEnd, 'dd MMM yyyy', { locale: ptBR }) }}
          </span>
          <span v-else>
            {{ format(currentDate, 'dd MMMM yyyy', { locale: ptBR }) }}
          </span>
        </h2>
        <Button
          variant="ghost"
          size="sm"
          icon="i-lucide-chevron-right"
          @click="nextPeriod"
        />
        <Button
          variant="ghost"
          size="sm"
          @click="goToToday"
        >
          {{ t('KANBAN.TODAY') }}
        </Button>
      </div>

      <div class="flex items-center gap-2">
        <Button
          :variant="viewMode === 'month' ? 'solid' : 'ghost'"
          size="sm"
          @click="viewMode = 'month'"
        >
          {{ t('KANBAN.MONTH') }}
        </Button>
        <Button
          :variant="viewMode === 'week' ? 'solid' : 'ghost'"
          size="sm"
          @click="viewMode = 'week'"
        >
          {{ t('KANBAN.WEEK') }}
        </Button>
        <Button
          :variant="viewMode === 'day' ? 'solid' : 'ghost'"
          size="sm"
          @click="viewMode = 'day'"
        >
          {{ t('KANBAN.DAY') }}
        </Button>
      </div>
    </div>

    <!-- Calendar Grid -->
    <div class="flex-1 min-h-0 overflow-hidden p-6">
      <!-- Month view -->
      <div v-if="viewMode === 'month'" class="flex flex-col h-full gap-2">
        <!-- Week day headers -->
        <div class="grid grid-cols-7 gap-2 flex-none">
          <div
            v-for="day in weekDays"
            :key="day"
            class="p-2 text-sm font-medium text-center text-n-slate-11"
          >
            {{ day }}
          </div>
        </div>
        <!-- Calendar days -->
        <div class="grid grid-cols-7 grid-rows-6 gap-2 flex-1 min-h-0 overflow-hidden">
          <div
            v-for="day in calendarDays"
            :key="day.toISOString()"
            class="p-2 border border-n-weak rounded-lg bg-n-solid-2 h-full"
            :class="{
              'bg-n-alpha-2': !isCurrentMonth(day),
              'border-n-brand': isToday(day),
            }"
          >
            <div class="mb-2 flex items-center justify-between gap-2">
              <div
                class="text-sm font-medium"
                :class="{
                  'text-n-brand': isToday(day),
                  'text-n-slate-12': isCurrentMonth(day) && !isToday(day),
                  'text-n-slate-10': !isCurrentMonth(day),
                }"
              >
                {{ format(day, 'd') }}
              </div>
              <button
                class="i-lucide-plus size-4 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded p-1"
                title="Criar card"
                @click.stop="handleQuickCreate(day)"
              />
            </div>
            <div class="space-y-1">
              <div
                v-for="card in getCardsForDate(day)"
                :key="card.id"
                class="p-1 text-xs bg-n-brand/10 text-n-brand rounded cursor-pointer hover:bg-n-brand/20 truncate"
                :title="card.title"
                @click.stop="handleCardClick(card)"
              >
                {{ card.title }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Week view -->
      <div v-else-if="viewMode === 'week'" class="grid grid-cols-7 gap-2 h-full">
        <div
          v-for="day in calendarDays"
          :key="day.toISOString()"
          class="flex flex-col h-full"
        >
          <div
            class="p-2 mb-2 text-sm font-medium border-b border-n-weak flex-none flex items-center justify-between"
            :class="{
              'text-n-brand': isToday(day),
              'text-n-slate-12': !isToday(day),
            }"
          >
            <div>
              <div>{{ format(day, 'EEE', { locale: ptBR }) }}</div>
              <div class="text-lg">{{ format(day, 'd') }}</div>
            </div>
            <button
              class="i-lucide-plus size-4 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded p-1"
              title="Criar card"
              @click.stop="handleQuickCreate(day)"
            />
          </div>
          <div class="flex-1 space-y-2 overflow-hidden">
            <KanbanCard
              v-for="card in getCardsForDate(day)"
              :key="card.id"
              :card="card"
              :board-id="boardId"
            />
          </div>
        </div>
      </div>

      <!-- Day view -->
      <div v-else class="flex flex-col h-full min-h-0 overflow-hidden">
        <div
          class="p-4 mb-4 text-lg font-semibold border-b border-n-weak text-n-slate-12 flex-none flex items-center justify-between"
        >
          <span>{{ format(currentDate, 'EEEE, dd MMMM yyyy', { locale: ptBR }) }}</span>
          <button
            class="i-lucide-plus size-5 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded p-1"
            title="Criar card"
            @click="handleQuickCreate(currentDate)"
          />
        </div>
        <div class="flex-1 space-y-2 overflow-hidden">
          <div
            v-for="card in getCardsForDate(currentDate)"
            :key="card.id"
            class="p-3 bg-n-background border border-n-weak rounded-lg cursor-pointer hover:border-n-brand transition-colors"
            @click="handleCardClick(card)"
          >
            <h4 class="font-medium text-n-slate-12">{{ card.title }}</h4>
            <p v-if="card.description" class="mt-1 text-sm text-n-slate-11 line-clamp-2">
              {{ card.description }}
            </p>
            <div v-if="card.due_date" class="mt-2 text-xs text-n-slate-10">
              <span class="i-lucide-calendar size-3 inline-block mr-1" />
              {{ format(new Date(card.due_date), 'dd/MM/yyyy HH:mm', { locale: ptBR }) }}
            </div>
          </div>
          <div
            v-if="getCardsForDate(currentDate).length === 0"
            class="flex items-center justify-center h-32 text-n-slate-11"
          >
            {{ t('KANBAN.NO_CARDS_FOR_DATE') }}
          </div>
        </div>
      </div>
    </div>

    <Dialog
      ref="cardDialogRef"
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="handleCloseCardDialog"
    >
      <KanbanCardForm
        v-if="selectedCard || isCreatingCard"
        :card="selectedCard"
        :board-id="boardId"
        :initial-start-date="initialStartDate"
        @create="handleCardCreate"
        @update="handleCardUpdate"
        @close="handleCloseCardDialog"
      />
    </Dialog>
  </div>
</template>

