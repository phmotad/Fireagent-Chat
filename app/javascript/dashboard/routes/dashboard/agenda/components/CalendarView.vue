<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, isToday, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();
const currentDate = ref(new Date());

const monthStart = computed(() => startOfMonth(currentDate.value));
const monthEnd = computed(() => endOfMonth(currentDate.value));
const daysInMonth = computed(() => eachDayOfInterval({ start: monthStart.value, end: monthEnd.value }));

const itemsByDate = computed(() => {
  const grouped = {};
  
  props.items.forEach(item => {
    if (!item.date) return;
    
    try {
      const date = typeof item.date === 'string' ? parseISO(item.date) : new Date(item.date);
      const dateKey = format(date, 'yyyy-MM-dd');
      if (!grouped[dateKey]) {
        grouped[dateKey] = [];
      }
      grouped[dateKey].push(item);
    } catch (error) {
      console.error('Error parsing date:', item.date, error);
    }
  });
  
  return grouped;
});

const getItemsForDate = (date) => {
  const dateKey = format(date, 'yyyy-MM-dd');
  return itemsByDate.value[dateKey] || [];
};

const previousMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1);
};

const nextMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1);
};

const goToToday = () => {
  currentDate.value = new Date();
};
</script>

<template>
  <div class="w-full h-full p-6">
    <!-- Calendar Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-4">
        <button
          @click="previousMonth"
          class="p-2 rounded-lg hover:bg-n-slate-3 transition-colors"
        >
          <i class="i-lucide-chevron-left w-5 h-5 text-n-slate-11" />
        </button>
        <h2 class="text-xl font-semibold text-n-slate-12">
          {{ format(currentDate, 'MMMM yyyy', { locale: ptBR }) }}
        </h2>
        <button
          @click="nextMonth"
          class="p-2 rounded-lg hover:bg-n-slate-3 transition-colors"
        >
          <i class="i-lucide-chevron-right w-5 h-5 text-n-slate-11" />
        </button>
      </div>
      <button
        @click="goToToday"
        class="px-4 py-2 text-sm font-medium rounded-lg bg-n-blue-3 text-n-blue-11 hover:bg-n-blue-4 transition-colors"
      >
        {{ t('AGENDA.TODAY') }}
      </button>
    </div>

    <!-- Calendar Grid -->
    <div class="grid grid-cols-7 gap-2 w-full">
      <!-- Day Headers -->
      <div
        v-for="day in ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']"
        :key="day"
        class="p-2 text-center text-xs font-semibold text-n-slate-11"
      >
        {{ day }}
      </div>

      <!-- Calendar Days -->
      <div
        v-for="day in daysInMonth"
        :key="day.toISOString()"
        :class="[
          'min-h-[120px] p-2 border border-n-weak rounded-lg',
          isSameMonth(day, currentDate) ? 'bg-n-background' : 'bg-n-solid-1 opacity-50',
          isToday(day) && 'ring-2 ring-n-blue-9'
        ]"
      >
        <div class="flex items-center justify-between mb-1">
          <span
            :class="[
              'text-sm font-medium',
              isToday(day) ? 'text-n-blue-11' : 'text-n-slate-12'
            ]"
          >
            {{ format(day, 'd') }}
          </span>
        </div>
        
        <div class="space-y-1 mt-1">
          <div
            v-for="item in getItemsForDate(day)"
            :key="`${item.type}-${item.id}`"
            :class="[
              'text-xs p-1 rounded truncate cursor-pointer',
              item.type === 'booking'
                ? 'bg-n-blue-3 text-n-blue-11'
                : 'bg-n-slate-3 text-n-slate-11'
            ]"
            :title="item.title || item.name"
          >
            <i
              :class="[
                'mr-1',
                item.type === 'booking' ? 'i-lucide-calendar' : 'i-lucide-file-text'
              ]"
            />
            {{ item.title || item.name }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

