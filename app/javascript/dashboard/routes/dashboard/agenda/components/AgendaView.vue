<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CalendarView from './CalendarView.vue';
import ListView from './ListView.vue';

const props = defineProps({
  bookings: {
    type: Array,
    default: () => [],
  },
  cards: {
    type: Array,
    default: () => [],
  },
  viewMode: {
    type: String,
    default: 'calendar',
    validator: (value) => ['calendar', 'list'].includes(value),
  },
});

const { t } = useI18n();

// Combinar bookings e cards em uma lista unificada para processamento
const allItems = computed(() => {
  const items = [];
  
  // Adicionar bookings (sempre aparecem)
  props.bookings.forEach(booking => {
    if (booking.start_time) {
      items.push({
        ...booking,
        type: 'booking',
        date: booking.start_time,
        endDate: booking.end_time,
      });
    }
  });
  
  // Adicionar cards (apenas com data)
  props.cards.forEach(card => {
    const cardDate = card.due_date || card.start_date;
    if (cardDate) {
      items.push({
        ...card,
        type: 'card',
        date: cardDate,
        endDate: card.end_date,
      });
    }
  });
  
  return items;
});
</script>

<template>
  <div class="w-full h-full">
    <CalendarView
      v-if="viewMode === 'calendar'"
      :items="allItems"
    />
    <ListView
      v-else
      :items="allItems"
    />
  </div>
</template>

