<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format, parseISO, isToday, isPast, isFuture } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();

// Agrupar itens por data
const itemsByDate = computed(() => {
  const grouped = {};
  
  props.items.forEach(item => {
    if (!item.date) return;
    
    try {
      const date = typeof item.date === 'string' ? parseISO(item.date) : new Date(item.date);
      const dateKey = format(date, 'yyyy-MM-dd');
      
      if (!grouped[dateKey]) {
        grouped[dateKey] = {
          date,
          items: [],
        };
      }
      
      grouped[dateKey].items.push(item);
    } catch (error) {
      console.error('Error parsing date:', item.date, error);
    }
  });
  
  // Ordenar por data
  return Object.keys(grouped)
    .sort()
    .map(key => grouped[key]);
});

const getDateLabel = (date) => {
  if (isToday(date)) {
    return t('AGENDA.TODAY');
  }
  if (isPast(date) && !isToday(date)) {
    return format(date, "dd 'de' MMMM 'de' yyyy", { locale: ptBR });
  }
  if (isFuture(date)) {
    return format(date, "dd 'de' MMMM 'de' yyyy", { locale: ptBR });
  }
  return format(date, "dd 'de' MMMM 'de' yyyy", { locale: ptBR });
};
</script>

<template>
  <div class="w-full h-full p-6">
    <div v-if="!itemsByDate.length" class="py-12 text-center">
      <p class="text-n-slate-11">{{ t('AGENDA.NO_ITEMS') }}</p>
    </div>

    <div v-else class="space-y-6">
      <div
        v-for="group in itemsByDate"
        :key="format(group.date, 'yyyy-MM-dd')"
        class="space-y-3"
      >
        <!-- Date Header -->
        <div class="flex items-center gap-2 pb-2 border-b border-n-weak">
          <h3 class="text-lg font-semibold text-n-slate-12">
            {{ getDateLabel(group.date) }}
          </h3>
          <span class="text-sm text-n-slate-11">
            ({{ group.items.length }} {{ group.items.length === 1 ? t('AGENDA.ITEM') : t('AGENDA.ITEMS') }})
          </span>
        </div>

        <!-- Items -->
        <div class="space-y-2">
          <div
            v-for="item in group.items"
            :key="`${item.type}-${item.id}`"
            :class="[
              'flex items-start gap-3 p-4 rounded-lg border transition-colors',
              item.type === 'booking'
                ? 'bg-n-blue-1 border-n-blue-6 hover:border-n-blue-8'
                : 'bg-n-background border-n-weak hover:border-n-slate-6'
            ]"
          >
            <div
              :class="[
                'flex-shrink-0 w-10 h-10 rounded-lg flex items-center justify-center',
                item.type === 'booking'
                  ? 'bg-n-blue-3 text-n-blue-11'
                  : 'bg-n-slate-3 text-n-slate-11'
              ]"
            >
              <i
                :class="[
                  'w-5 h-5',
                  item.type === 'booking' ? 'i-lucide-calendar' : 'i-lucide-file-text'
                ]"
              />
            </div>
            
            <div class="flex-1 min-w-0">
              <h4 class="text-sm font-semibold text-n-slate-12 mb-1">
                {{ item.title || item.name }}
              </h4>
              
              <div class="flex flex-wrap gap-2 text-xs text-n-slate-11">
                <span v-if="item.start_time || item.date">
                  <i class="i-lucide-clock mr-1" />
                  {{ format(parseISO(item.start_time || item.date), 'HH:mm', { locale: ptBR }) }}
                </span>
                
                <span v-if="item.end_time || item.endDate">
                  - {{ format(parseISO(item.end_time || item.endDate), 'HH:mm', { locale: ptBR }) }}
                </span>
                
                <span v-if="item.kanban_location?.name" class="ml-2">
                  <i class="i-lucide-map-pin mr-1" />
                  {{ item.kanban_location.name }}
                </span>
                
                <span v-if="item.kanban_board?.name" class="ml-2">
                  <i class="i-lucide-columns mr-1" />
                  {{ item.kanban_board.name }}
                </span>
              </div>
              
              <p v-if="item.description" class="mt-2 text-xs text-n-slate-11 line-clamp-2">
                {{ item.description }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

