<script setup>
import { onMounted, computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const store = useStore();
const { t } = useI18n();

const locations = useMapGetter('kanban/getLocations');
const uiFlags = useMapGetter('kanban/getUIFlags');

const editingLocation = ref(false);
const showLocationFormModal = ref(false);
const locationFormDialogRef = ref(null);
const locationForm = ref({
  id: null,
  name: '',
  description: '',
  max_capacity: null,
});

const isLoading = computed(
  () =>
    uiFlags.value.isFetchingLocations ||
    uiFlags.value.isCreatingLocation ||
    uiFlags.value.isUpdatingLocation,
);

const resetLocationForm = () => {
  editingLocation.value = false;
  locationForm.value = {
    id: null,
    name: '',
    description: '',
    max_capacity: null,
  };
  showLocationFormModal.value = false;
};

const handleNewLocation = async () => {
  editingLocation.value = false;
  locationForm.value = {
    id: null,
    name: '',
    description: '',
    max_capacity: null,
  };
  showLocationFormModal.value = true;
  await nextTick();
  await nextTick();
  if (locationFormDialogRef.value) {
    locationFormDialogRef.value.open();
  } else {
    console.error('[KanbanLocations] Dialog ref not available');
  }
};

const handleLocationSubmit = async () => {
  try {
    const payload = {
      name: locationForm.value.name,
      description: locationForm.value.description,
      max_capacity: locationForm.value.max_capacity,
    };

    if (editingLocation.value && locationForm.value.id) {
      await store.dispatch('kanban/updateLocation', {
        id: locationForm.value.id,
        ...payload,
      });
      useAlert(t('KANBAN.LOCATION_UPDATE_SUCCESS'));
    } else {
      await store.dispatch('kanban/createLocation', payload);
      useAlert(t('KANBAN.LOCATION_CREATE_SUCCESS'));
    }

    resetLocationForm();
    locationFormDialogRef.value?.close();
  } catch (error) {
    console.error('Error saving location', error);
    useAlert(t('KANBAN.LOCATION_SAVE_ERROR'));
  }
};

const handleEditLocation = async location => {
  editingLocation.value = true;
  locationForm.value = {
    id: location.id,
    name: location.name,
    description: location.description,
    max_capacity: location.max_capacity,
  };
  showLocationFormModal.value = true;
  await nextTick();
  await nextTick();
  if (locationFormDialogRef.value) {
    locationFormDialogRef.value.open();
  } else {
    console.error('[KanbanLocations] Dialog ref not available');
  }
};

const handleDeleteLocation = async location => {
  if (!window.confirm(t('KANBAN.LOCATION_DELETE_CONFIRM'))) return;

  try {
    await store.dispatch('kanban/deleteLocation', location.id);
    useAlert(t('KANBAN.LOCATION_DELETE_SUCCESS'));
    if (editingLocation.value && locationForm.value.id === location.id) {
      resetLocationForm();
    }
  } catch (error) {
    console.error('Error deleting location', error);
    useAlert(t('KANBAN.LOCATION_DELETE_ERROR'));
  }
};

onMounted(() => {
  store.dispatch('kanban/fetchLocations');
});

defineExpose({
  handleNewLocation,
});
</script>

<template>
  <div class="grid gap-6">
    <!-- List -->
    <div class="p-6 bg-n-solid-2 border border-n-weak rounded-lg">
      <h3 class="mb-4 text-base font-semibold text-n-slate-12">
        {{ t('KANBAN.LOCATIONS_LIST_TITLE') }}
      </h3>

      <div v-if="!locations.length && !isLoading" class="py-8 text-sm text-center text-n-slate-11">
        {{ t('KANBAN.LOCATIONS_EMPTY') }}
      </div>

      <div v-else-if="isLoading" class="py-8 text-sm text-center text-n-slate-11">
        {{ t('KANBAN.LOADING') }}
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="location in locations"
          :key="location.id"
          class="flex items-start justify-between gap-4 p-4 bg-n-background border border-n-weak rounded-lg hover:border-n-slate-6 transition-colors"
        >
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h4 class="text-sm font-semibold text-n-slate-12">
                {{ location.name }}
              </h4>
              <span
                v-if="location.max_capacity"
                class="px-2 py-0.5 text-[11px] font-medium rounded-full bg-n-brand/10 text-n-brand"
              >
                {{ t('KANBAN.LOCATION_CAPACITY_BADGE', { value: location.max_capacity }) }}
              </span>
            </div>
            <div class="space-y-1">
              <p
                v-if="location.description"
                class="text-xs text-n-slate-11 line-clamp-2"
              >
                {{ location.description }}
              </p>
            </div>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <Button
              size="sm"
              variant="ghost"
              @click="handleEditLocation(location)"
            >
              {{ t('KANBAN.EDIT') }}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              color="ruby"
              @click="handleDeleteLocation(location)"
            >
              {{ t('KANBAN.DELETE') }}
            </Button>
          </div>
        </div>
      </div>
    </div>

    <Dialog
      ref="locationFormDialogRef"
      :title="editingLocation ? t('KANBAN.EDIT_LOCATION') : t('KANBAN.NEW_LOCATION')"
      width="lg"
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="resetLocationForm"
    >
      <div v-if="showLocationFormModal" class="p-6 space-y-4">
        <Input
          v-model="locationForm.name"
          :label="t('KANBAN.LOCATION_NAME')"
          :placeholder="t('KANBAN.LOCATION_NAME_PLACEHOLDER')"
          size="md"
        />

        <TextArea
          v-model="locationForm.description"
          :label="t('KANBAN.LOCATION_DESCRIPTION')"
          :placeholder="t('KANBAN.LOCATION_DESCRIPTION_PLACEHOLDER')"
          :autosize="true"
        />

        <Input
          v-model="locationForm.max_capacity"
          type="number"
          :label="t('KANBAN.LOCATION_MAX_CAPACITY')"
          :placeholder="t('KANBAN.LOCATION_MAX_CAPACITY_PLACEHOLDER')"
          size="md"
        />

        <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
          <Button
            type="button"
            variant="ghost"
            size="sm"
            @click="resetLocationForm"
          >
            {{ t('KANBAN.CANCEL') }}
          </Button>
          <Button
            type="button"
            color="blue"
            size="sm"
            :is-loading="uiFlags.isCreatingLocation || uiFlags.isUpdatingLocation"
            @click="handleLocationSubmit"
          >
            {{
              editingLocation
                ? t('KANBAN.LOCATION_SAVE')
                : t('KANBAN.LOCATION_CREATE')
            }}
          </Button>
        </div>
      </div>
    </Dialog>
  </div>
</template>

