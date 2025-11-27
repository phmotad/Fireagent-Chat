<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactsAPI from 'dashboard/api/contacts';

const props = defineProps({
  booking: {
    type: Object,
    default: null,
  },
  onClose: {
    type: Function,
    default: () => {},
  },
});

const emit = defineEmits(['created', 'updated', 'close']);

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();

const weekDays = [
  { key: 'monday', label: t('KANBAN.DAY_MONDAY') },
  { key: 'tuesday', label: t('KANBAN.DAY_TUESDAY') },
  { key: 'wednesday', label: t('KANBAN.DAY_WEDNESDAY') },
  { key: 'thursday', label: t('KANBAN.DAY_THURSDAY') },
  { key: 'friday', label: t('KANBAN.DAY_FRIDAY') },
  { key: 'saturday', label: t('KANBAN.DAY_SATURDAY') },
  { key: 'sunday', label: t('KANBAN.DAY_SUNDAY') },
];

const dayOfWeekMap = {
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
  sunday: 0,
};

const createEmptyWeeklySchedule = () => ({
  monday: { enabled: false, start_time: '', end_time: '' },
  tuesday: { enabled: false, start_time: '', end_time: '' },
  wednesday: { enabled: false, start_time: '', end_time: '' },
  thursday: { enabled: false, start_time: '', end_time: '' },
  friday: { enabled: false, start_time: '', end_time: '' },
  saturday: { enabled: false, start_time: '', end_time: '' },
  sunday: { enabled: false, start_time: '', end_time: '' },
});

const rules = useMapGetter('kanban/getRules');
const locations = useMapGetter('kanban/getLocations');
const uiFlags = useMapGetter('kanban/getUIFlags');

const contacts = ref([]);
const isSearchingContacts = ref(false);
const contactSearchQuery = ref('');

const formData = ref({
  kanban_schedule_rule_id: null,
  contact_ids: [], // Múltiplos participantes
  start_time: '',
  end_time: '',
  metadata: {},
  // Para regras semanais
  weekly_schedule: createEmptyWeeklySchedule(),
  weekly_range_start: '',
  weekly_range_end: '',
});

const selectedContactId = computed(
  () => formData.value.contact_ids?.[0] || null,
);

const resetWeeklySchedule = () => {
  formData.value.weekly_schedule = createEmptyWeeklySchedule();
  formData.value.weekly_range_start = '';
  formData.value.weekly_range_end = '';
};

const applyWeeklyDefaultsFromRule = rule => {
  resetWeeklySchedule();

  if (!rule || rule.rule_type !== 'weekly') {
    return;
  }

  const weekdays = Array.isArray(rule.weekdays) ? rule.weekdays : [];

  weekDays.forEach(day => {
    const schedule = formData.value.weekly_schedule[day.key];
    if (weekdays.length) {
      schedule.enabled = weekdays.includes(dayOfWeekMap[day.key]);
    }
  });
};

const isEditing = computed(() => !!props.booking);

const isLoading = computed(
  () =>
    uiFlags.value.isCreatingBooking ||
    uiFlags.value.isFetchingRules ||
    uiFlags.value.isFetchingLocations,
);

const ruleOptions = computed(() =>
  (rules.value || []).map(rule => ({
    label: rule.title,
    value: rule.id,
  })),
);

const locationOptions = computed(() =>
  (locations.value || []).map(location => ({
    label: location.name,
    value: location.id,
  })),
);

const selectedRule = computed(() => {
  if (!formData.value.kanban_schedule_rule_id) return null;
  return rules.value.find(r => r.id === formData.value.kanban_schedule_rule_id);
});

const isWeeklyRule = computed(() => {
  return selectedRule.value?.rule_type === 'weekly';
});

const isRuleInactive = computed(() => {
  if (!selectedRule.value) return false;
  return selectedRule.value.active === false;
});

const isRuleDisabledForCreation = computed(() => !isEditing.value && isRuleInactive.value);

const submitLoading = computed(() =>
  isEditing.value
    ? uiFlags.value.isUpdatingBooking
    : uiFlags.value.isCreatingBooking,
);

// Watch para atualizar location quando rule mudar e preencher horários da regra
watch(
  () => formData.value.kanban_schedule_rule_id,
  newRuleId => {
    if (!newRuleId) {
      resetWeeklySchedule();
      return;
    }

    const rule = rules.value.find(r => r.id === newRuleId);
    applyWeeklyDefaultsFromRule(rule);

    if (rule?.rule_type === 'weekly' && !formData.value.weekly_range_start) {
      const today = new Date();
      const isoDate = today.toISOString().slice(0, 10);
      formData.value.weekly_range_start = isoDate;
      formData.value.weekly_range_end = '';
    }
  },
);

watch(
  () => [...formData.value.contact_ids],
  newValues => {
    if (!isEditing.value || newValues.length <= 1) return;
    formData.value.contact_ids = [newValues[newValues.length - 1]];
  },
);

// Buscar contatos
const searchContacts = async (query) => {
  if (!query || query.length < 2) {
    contacts.value = [];
    return;
  }

  isSearchingContacts.value = true;
  contactSearchQuery.value = query;

  try {
    const response = await ContactsAPI.search(query, 1, 'name', '');
    contacts.value = response?.data?.payload || response?.data || [];
  } catch (error) {
    console.error('Error searching contacts:', error);
    contacts.value = [];
  } finally {
    isSearchingContacts.value = false;
  }
};

// Debounce para busca
let searchTimeout = null;
const handleSearch = (query) => {
  contactSearchQuery.value = query;
  if (searchTimeout) {
    clearTimeout(searchTimeout);
  }
  searchTimeout = setTimeout(() => {
    searchContacts(query);
  }, 300);
};

const contactOptions = computed(() =>
  contacts.value.map(contact => ({
    label: contact.name || contact.email || contact.phone_number || `Contact #${contact.id}`,
    value: contact.id,
  })),
);

onMounted(async () => {
  await Promise.all([
    store.dispatch('kanban/fetchRules'),
    store.dispatch('kanban/fetchLocations'),
  ]);

  if (props.booking) {
    formData.value = {
      kanban_schedule_rule_id: props.booking.kanban_schedule_rule_id,
      contact_ids: props.booking.contact_id ? [props.booking.contact_id] : [],
      start_time: props.booking.start_time
        ? new Date(props.booking.start_time).toISOString().slice(0, 16)
        : '',
      end_time: props.booking.end_time
        ? new Date(props.booking.end_time).toISOString().slice(0, 16)
        : '',
      metadata: props.booking.metadata || {},
    };
    
    // Carregar contato se já estiver selecionado
    if (props.booking.contact_id) {
      try {
        const contactResponse = await ContactsAPI.show(props.booking.contact_id);
        if (contactResponse?.data) {
          contacts.value = [contactResponse.data];
        }
      } catch (error) {
        console.error('Error loading contact:', error);
      }
    }
  }
});


const handleSubmit = async () => {
  if (!formData.value.kanban_schedule_rule_id) {
    useAlert(t('KANBAN.BOOKING_RULE_REQUIRED'));
    return;
  }

  if (!formData.value.contact_ids || formData.value.contact_ids.length === 0) {
    useAlert(t('KANBAN.BOOKING_CONTACT_REQUIRED'));
    return;
  }

  if (isRuleDisabledForCreation.value) {
    useAlert(t('KANBAN.RULE_INACTIVE_ALERT'));
    return;
  }

  if (isEditing.value && props.booking?.id) {
    await handleUpdateBooking();
    return;
  }

  // Verificar capacidade do local
  const selectedRule = rules.value.find(r => r.id === formData.value.kanban_schedule_rule_id);
  const location = selectedRule?.kanban_location;
  const maxCapacity = location?.max_capacity;
  
  if (maxCapacity && formData.value.contact_ids.length > maxCapacity) {
    useAlert(t('KANBAN.BOOKING_CAPACITY_EXCEEDED', { max: maxCapacity }));
    return;
  }

  try {
    const bookings = [];

    if (isWeeklyRule.value) {
      if (!formData.value.weekly_range_start) {
        useAlert(t('KANBAN.BOOKING_WEEKLY_RANGE_START'));
        return;
      }

      const rangeStart = new Date(formData.value.weekly_range_start);
      if (Number.isNaN(rangeStart.getTime())) {
        useAlert(t('KANBAN.WEEKLY_RULE_RANGE_REQUIRED'));
        return;
      }
      rangeStart.setHours(0, 0, 0, 0);

      let rangeEnd;
      if (formData.value.weekly_range_end) {
        rangeEnd = new Date(formData.value.weekly_range_end);
      } else {
        rangeEnd = new Date(rangeStart);
      }

      if (Number.isNaN(rangeEnd.getTime())) {
        rangeEnd = new Date(rangeStart);
      }
      rangeEnd.setHours(23, 59, 59, 999);

      if (rangeEnd < rangeStart) {
        useAlert(t('KANBAN.WEEKLY_RULE_RANGE_REQUIRED'));
        return;
      }
      const enabledDays = weekDays.filter(day => formData.value.weekly_schedule[day.key].enabled);

      if (enabledDays.length === 0) {
        useAlert(t('KANBAN.WEEKLY_RULE_SELECT_DAY'));
        return;
      }

      // Validar horários dos dias selecionados
      for (const day of enabledDays) {
        const daySchedule = formData.value.weekly_schedule[day.key];
        if (!daySchedule.start_time || !daySchedule.end_time) {
          useAlert(t('KANBAN.WEEKLY_RULE_FILL_TIMES', { day: day.label }));
          return;
        }
      }

      // Criar bookings para cada semana até o fim da vigência
      // Mapear dias da semana: JavaScript usa 0=domingo, 1=segunda, etc.
      
      // Começar da data de início da regra
      const currentWeekStart = new Date(rangeStart);
      currentWeekStart.setHours(0, 0, 0, 0);
      
      // Iterar semana por semana
      while (currentWeekStart <= rangeEnd) {
        for (const day of enabledDays) {
          const targetDayOfWeek = dayOfWeekMap[day.key];
          const daySchedule = formData.value.weekly_schedule[day.key];
          
          // Calcular a data deste dia da semana na semana atual
          const dayDate = new Date(currentWeekStart);
          const currentDayOfWeek = dayDate.getDay();
          const daysToAdd = (targetDayOfWeek - currentDayOfWeek + 7) % 7;
          dayDate.setDate(dayDate.getDate() + daysToAdd);

          // Verificar se a data está dentro do intervalo solicitado
          if (dayDate < rangeStart || dayDate > rangeEnd) continue;

          // Criar booking para cada contato neste dia
          for (const contactId of formData.value.contact_ids) {
            const [hours, minutes] = daySchedule.start_time.split(':');
            const startDateTime = new Date(dayDate);
            startDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

            const [endHours, endMinutes] = daySchedule.end_time.split(':');
            const endDateTime = new Date(dayDate);
            endDateTime.setHours(parseInt(endHours), parseInt(endMinutes), 0, 0);

            const payload = {
              kanban_schedule_rule_id: formData.value.kanban_schedule_rule_id,
              contact_id: contactId,
              start_time: startDateTime.toISOString(),
              end_time: endDateTime.toISOString(),
              source: 'manual',
              metadata: { ...formData.value.metadata, day_of_week: day.key },
            };

            const booking = await store.dispatch('kanban/createBooking', payload);
            bookings.push(booking);
          }
        }

        // Avançar para a próxima semana (7 dias)
        currentWeekStart.setDate(currentWeekStart.getDate() + 7);
      }
    } else {
      // Agendamento único
      if (!formData.value.start_time) {
        useAlert(t('KANBAN.BOOKING_START_TIME_REQUIRED'));
        return;
      }

      // Criar um booking para cada contato
      for (const contactId of formData.value.contact_ids) {
        const payload = {
          kanban_schedule_rule_id: formData.value.kanban_schedule_rule_id,
          contact_id: contactId,
          start_time: new Date(formData.value.start_time).toISOString(),
          end_time: formData.value.end_time
            ? new Date(formData.value.end_time).toISOString()
            : null,
          source: 'manual',
          metadata: formData.value.metadata,
        };

        const booking = await store.dispatch('kanban/createBooking', payload);
        bookings.push(booking);
      }
    }

    useAlert(t('KANBAN.BOOKING_CREATE_SUCCESS'));
    emit('created', bookings[0]); // Emitir o primeiro booking
    emit('close');
  } catch (error) {
    console.error('Error creating booking:', error);
    const errorMessage =
      error?.response?.data?.error ||
      error?.message ||
      t('KANBAN.BOOKING_CREATE_ERROR');
    useAlert(errorMessage);
  }
};

const handleCancel = () => {
  emit('close');
  if (props.onClose) {
    props.onClose();
  }
};

const handleUpdateBooking = async () => {
  if (!selectedContactId.value) {
    useAlert(t('KANBAN.BOOKING_CONTACT_REQUIRED'));
    return;
  }

  if (!formData.value.start_time) {
    useAlert(t('KANBAN.BOOKING_START_TIME_REQUIRED'));
    return;
  }

  try {
    const payload = {
      kanban_schedule_rule_id: formData.value.kanban_schedule_rule_id,
      contact_id: selectedContactId.value,
      start_time: new Date(formData.value.start_time).toISOString(),
      end_time: formData.value.end_time
        ? new Date(formData.value.end_time).toISOString()
        : null,
      metadata: formData.value.metadata,
    };

    const updatedBooking = await store.dispatch('kanban/updateBooking', {
      id: props.booking.id,
      payload,
    });

    useAlert(t('KANBAN.BOOKING_UPDATE_SUCCESS'));
    emit('updated', updatedBooking);
    emit('close');
  } catch (error) {
    console.error('Error updating booking:', error);
    const errorMessage =
      error?.response?.data?.error ||
      error?.message ||
      t('KANBAN.BOOKING_UPDATE_ERROR');
    useAlert(errorMessage);
  }
};
</script>

<template>
  <div class="p-6 bg-n-background max-h-[80vh] overflow-y-auto">
    <div class="mb-4">
      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ isEditing ? t('KANBAN.EDIT_BOOKING') : t('KANBAN.NEW_BOOKING') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('KANBAN.BOOKING_FORM_DESCRIPTION') }}
      </p>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <Spinner />
    </div>

    <form v-else @submit.prevent="handleSubmit" class="space-y-4">
      <div>
        <label class="block mb-1 text-xs font-medium text-n-slate-11">
          {{ t('KANBAN.BOOKING_RULE') }} *
        </label>
        <ComboBox
          v-model="formData.kanban_schedule_rule_id"
          :options="ruleOptions"
          :placeholder="t('KANBAN.SELECT_RULE')"
          size="md"
        />
        <p v-if="selectedRule" class="mt-1 text-xs text-n-slate-11">
          {{ t('KANBAN.RULE_LOCATION') }}:
          {{ selectedRule.kanban_location?.name || t('KANBAN.NO_LOCATION') }}
        </p>
        <p
          v-if="isRuleInactive"
          class="mt-1 text-xs text-n-ruby-10"
        >
          {{ t('KANBAN.RULE_INACTIVE_BOOKING_FORBIDDEN') }}
        </p>
      </div>

      <div>
        <label class="block mb-1 text-xs font-medium text-n-slate-11">
          {{ t('KANBAN.BOOKING_CONTACT') }} *
        </label>
        <TagMultiSelectComboBox
          v-model="formData.contact_ids"
          :options="contactOptions"
          :placeholder="t('KANBAN.SELECT_CONTACT')"
          :search-placeholder="t('KANBAN.SEARCH_CONTACT_PLACEHOLDER')"
          :empty-state="isSearchingContacts ? t('KANBAN.SEARCHING_CONTACTS') : (contactSearchQuery && contactOptions.length === 0 ? t('KANBAN.NO_CONTACTS_FOUND') : '')"
          @search="handleSearch"
        />
        <p v-if="selectedRule?.kanban_location?.max_capacity" class="mt-1 text-xs text-n-slate-11">
          {{ t('KANBAN.MAX_CAPACITY', { max: selectedRule.kanban_location.max_capacity }) }}
        </p>
      </div>

      <!-- Agendamento único ou edição de agendamento -->
      <div v-if="!isWeeklyRule || isEditing" class="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Input
          v-model="formData.start_time"
          type="datetime-local"
          :label="t('KANBAN.BOOKING_START_TIME')"
          size="md"
          required
        />
        <Input
          v-model="formData.end_time"
          type="datetime-local"
          :label="t('KANBAN.BOOKING_END_TIME')"
          size="md"
        />
      </div>

      <!-- Agendamento semanal -->
      <div v-else class="space-y-4">
        <div class="p-4 bg-n-solid-2 border border-n-weak rounded-lg">
          <h3 class="mb-4 text-sm font-semibold text-n-slate-12">
            {{ t('KANBAN.WEEKLY_SCHEDULE') }}
          </h3>
          <p class="mb-4 text-xs text-n-slate-11">
            {{ t('KANBAN.WEEKLY_SCHEDULE_DESCRIPTION') }}
          </p>

          <div class="grid grid-cols-1 gap-4 mb-4 md:grid-cols-2">
            <Input
              v-model="formData.weekly_range_start"
              type="date"
              :label="t('KANBAN.BOOKING_WEEKLY_RANGE_START')"
              size="md"
              required
            />
            <Input
              v-model="formData.weekly_range_end"
              type="date"
              :label="t('KANBAN.BOOKING_WEEKLY_RANGE_END')"
              size="md"
            />
          </div>
          
          <div class="space-y-3">
            <div
              v-for="day in weekDays"
              :key="day.key"
              class="p-3 bg-n-background border border-n-weak rounded-lg"
            >
              <div class="flex items-center gap-3 mb-2">
                <input
                  :id="`day-${day.key}`"
                  v-model="formData.weekly_schedule[day.key].enabled"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak text-n-brand focus:ring-n-brand"
                />
                <label :for="`day-${day.key}`" class="text-sm font-medium text-n-slate-12 cursor-pointer">
                  {{ day.label }}
                </label>
              </div>
              
              <div v-if="formData.weekly_schedule[day.key].enabled" class="grid grid-cols-2 gap-3 mt-2">
                <Input
                  v-model="formData.weekly_schedule[day.key].start_time"
                  type="time"
                  :label="t('KANBAN.START_TIME')"
                  size="sm"
                  required
                />
                <Input
                  v-model="formData.weekly_schedule[day.key].end_time"
                  type="time"
                  :label="t('KANBAN.END_TIME')"
                  size="sm"
                  required
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
        <Button type="button" variant="ghost" size="sm" @click="handleCancel">
          {{ t('KANBAN.CANCEL') }}
        </Button>
        <Button
          type="button"
          color="blue"
          size="sm"
          :is-loading="submitLoading"
          :disabled="isRuleDisabledForCreation"
          @click="handleSubmit"
        >
          {{ isEditing ? t('KANBAN.BOOKING_UPDATE') : t('KANBAN.BOOKING_CREATE') }}
        </Button>
      </div>
    </form>
  </div>
</template>

