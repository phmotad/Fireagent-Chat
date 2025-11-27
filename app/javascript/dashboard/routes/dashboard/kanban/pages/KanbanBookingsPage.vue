<script setup>
import { onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import KanbanBookingsList from '../components/KanbanBookingsList.vue';

const store = useStore();

onMounted(() => {
  store.dispatch('kanban/fetchBookings');
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-hidden bg-n-background">
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ $t('KANBAN.BOOKINGS_TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ $t('KANBAN.BOOKINGS_DESCRIPTION') }}
        </p>
      </div>
    </div>

    <div class="flex-1 overflow-hidden">
      <KanbanBookingsList />
    </div>
  </div>
</template>

