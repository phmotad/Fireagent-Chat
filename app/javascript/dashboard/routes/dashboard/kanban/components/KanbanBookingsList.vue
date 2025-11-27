<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { format, parseISO, isToday, isTomorrow, isPast } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import KanbanBookingForm from './KanbanBookingForm.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  ruleId: {
    type: Number,
    default: null,
  },
  locationId: {
    type: Number,
    default: null,
  },
  dateFrom: {
    type: String,
    default: null,
  },
  dateTo: {
    type: String,
    default: null,
  },
});

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const bookings = useMapGetter('kanban/getBookings');
const uiFlags = useMapGetter('kanban/getUIFlags');

const selectedBooking = ref(null);
const bookingFormDialogRef = ref(null);
const filters = ref({
  rule_id: props.ruleId,
  location_id: props.locationId,
  date_from: props.dateFrom,
  date_to: props.dateTo,
  status: 'booked',
});

const isLoading = computed(() => uiFlags.value.isFetchingBookings);

const filteredBookings = computed(() => {
  let filtered = [...(bookings.value || [])];

  if (filters.value.status) {
    filtered = filtered.filter(b => b.status === filters.value.status);
  }

  return filtered.sort((a, b) => {
    const dateA = new Date(a.start_time);
    const dateB = new Date(b.start_time);
    return dateA - dateB;
  });
});

const formatBookingDate = (dateString) => {
  if (!dateString) return '';
  const date = parseISO(dateString);
  
  if (isToday(date)) {
    return t('KANBAN.TODAY') + ', ' + format(date, 'HH:mm', { locale: ptBR });
  } else if (isTomorrow(date)) {
    return t('KANBAN.TOMORROW') + ', ' + format(date, 'HH:mm', { locale: ptBR });
  } else {
    return format(date, "dd 'de' MMMM 'às' HH:mm", { locale: ptBR });
  }
};

const isBookingPast = (booking) => {
  if (!booking.start_time) return false;
  return isPast(parseISO(booking.start_time));
};

const handleCreateBooking = () => {
  selectedBooking.value = null;
  bookingFormDialogRef.value?.open();
};

const handleBookingCreated = (booking) => {
  bookingFormDialogRef.value?.close();
  loadBookings();
};

const handleCancelBooking = async (booking) => {
  if (!window.confirm(t('KANBAN.BOOKING_CANCEL_CONFIRM'))) return;

  try {
    await store.dispatch('kanban/cancelBooking', booking.id);
    useAlert(t('KANBAN.BOOKING_CANCEL_SUCCESS'));
    loadBookings();
  } catch (error) {
    console.error('Error cancelling booking:', error);
    useAlert(t('KANBAN.BOOKING_CANCEL_ERROR'));
  }
};

const loadBookings = async () => {
  const params = {};
  if (filters.value.rule_id) params.rule_id = filters.value.rule_id;
  if (filters.value.location_id) params.location_id = filters.value.location_id;
  if (filters.value.date_from) params.date_from = filters.value.date_from;
  if (filters.value.date_to) params.date_to = filters.value.date_to;
  if (filters.value.status) params.status = filters.value.status;

  await store.dispatch('kanban/fetchBookings', params);
};

onMounted(() => {
  loadBookings();
});

watch(
  () => [props.ruleId, props.locationId, props.dateFrom, props.dateTo],
  () => {
    filters.value = {
      rule_id: props.ruleId,
      location_id: props.locationId,
      date_from: props.dateFrom,
      date_to: props.dateTo,
      status: filters.value.status,
    };
    loadBookings();
  },
);
</script>

<template>
  <div class="flex flex-col h-full bg-n-background">
    <div class="flex items-center justify-end px-6 py-4 border-b border-n-weak">
      <Button color="blue" size="sm" @click="handleCreateBooking">
        <Icon icon="i-lucide-plus" class="size-4 mr-2" />
        {{ t('KANBAN.NEW_BOOKING') }}
      </Button>
    </div>

    <div class="flex-1 overflow-auto p-6">
      <div v-if="isLoading" class="flex items-center justify-center py-8">
        <Spinner />
      </div>

      <div v-else-if="!filteredBookings.length" class="text-center py-12">
        <p class="text-sm text-n-slate-11">
          {{ t('KANBAN.BOOKINGS_EMPTY') }}
        </p>
        <Button
          color="blue"
          variant="ghost"
          size="sm"
          class="mt-4"
          @click="handleCreateBooking"
        >
          {{ t('KANBAN.CREATE_FIRST_BOOKING') }}
        </Button>
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="booking in filteredBookings"
          :key="booking.id"
          class="p-4 bg-n-solid-2 border border-n-weak rounded-lg hover:border-n-slate-6 transition-colors"
          :class="{
            'opacity-60': isBookingPast(booking),
          }"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-2">
                <h3 class="text-sm font-semibold text-n-slate-12">
                  {{ booking.contact?.name || booking.contact?.email || t('KANBAN.UNNAMED_CONTACT') }}
                </h3>
                <span
                  class="px-2 py-0.5 text-[11px] rounded-full"
                  :class="{
                    'bg-n-green-3 text-n-green-11': booking.status === 'booked',
                    'bg-n-ruby-3 text-n-ruby-11': booking.status === 'cancelled',
                  }"
                >
                  {{ booking.status === 'booked' ? t('KANBAN.BOOKING_STATUS_BOOKED') : t('KANBAN.BOOKING_STATUS_CANCELLED') }}
                </span>
              </div>

              <div class="space-y-1 text-xs text-n-slate-11">
                <div class="flex items-center gap-2">
                  <Icon icon="i-lucide-calendar" class="size-3" />
                  <span>{{ formatBookingDate(booking.start_time) }}</span>
                </div>
                <div v-if="booking.end_time" class="flex items-center gap-2">
                  <Icon icon="i-lucide-clock" class="size-3" />
                  <span>{{ t('KANBAN.ENDS_AT') }}: {{ formatBookingDate(booking.end_time) }}</span>
                </div>
                <div v-if="booking.kanban_location" class="flex items-center gap-2">
                  <Icon icon="i-lucide-map-pin" class="size-3" />
                  <span>{{ booking.kanban_location.name }}</span>
                </div>
                <div v-if="booking.kanban_schedule_rule" class="flex items-center gap-2">
                  <Icon icon="i-lucide-calendar-days" class="size-3" />
                  <span>{{ booking.kanban_schedule_rule.title }}</span>
                </div>
              </div>
            </div>

            <div v-if="booking.status === 'booked'" class="flex items-center gap-2">
              <Button
                size="xs"
                variant="ghost"
                color="ruby"
                @click="handleCancelBooking(booking)"
              >
                {{ t('KANBAN.CANCEL_BOOKING') }}
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <Dialog
      ref="bookingFormDialogRef"
      :title="selectedBooking ? t('KANBAN.EDIT_BOOKING') : t('KANBAN.NEW_BOOKING')"
      width="md"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="selectedBooking = null"
    >
      <KanbanBookingForm
        :booking="selectedBooking"
        @created="handleBookingCreated"
        @close="bookingFormDialogRef?.close()"
      />
    </Dialog>
  </div>
</template>

