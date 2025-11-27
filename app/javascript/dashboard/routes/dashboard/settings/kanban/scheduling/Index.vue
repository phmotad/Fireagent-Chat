<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsLayout from '../../SettingsLayout.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import LocationsContent from '../locations/LocationsContent.vue';
import RulesContent from '../rules/RulesContent.vue';

const { t } = useI18n();
const activeTab = ref('locations');

const tabs = [
  { id: 'locations', label: t('SIDEBAR.KANBAN_LOCATIONS_SHORT'), icon: 'i-lucide-map-pin' },
  { id: 'rules', label: t('SIDEBAR.KANBAN_RULES'), icon: 'i-lucide-calendar-days' },
];

const locationsRef = ref(null);
const rulesRef = ref(null);

const handleNewLocation = () => {
  locationsRef.value?.handleNewLocation();
};

const handleNewRule = () => {
  rulesRef.value?.handleNewRule();
};

const headerActions = computed(() => {
  if (activeTab.value === 'locations') {
    return {
      label: t('KANBAN.NEW_LOCATION'),
      action: handleNewLocation,
    };
  } else {
    return {
      label: t('KANBAN.NEW_RULE'),
      action: handleNewRule,
    };
  }
});
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('SIDEBAR.SCHEDULING')"
        :description="t('KANBAN.SCHEDULING_SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            icon="i-lucide-plus"
            :label="headerActions.label"
            color="blue"
            @click="headerActions.action"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div class="w-full">
        <!-- Tabs Navigation -->
        <div class="border-b border-n-slate-6 mb-6">
          <nav class="flex gap-1" aria-label="Tabs">
            <button
              v-for="tab in tabs"
              :key="tab.id"
              :class="[
                'flex items-center gap-2 px-4 py-3 text-sm font-medium rounded-t-lg transition-colors',
                activeTab === tab.id
                  ? 'text-n-blue-11 bg-n-blue-3 border-b-2 border-n-blue-9'
                  : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3'
              ]"
              @click="activeTab = tab.id"
            >
              <i :class="tab.icon" class="w-4 h-4" />
              {{ tab.label }}
            </button>
          </nav>
        </div>

        <!-- Tab Content -->
        <div class="w-full">
          <LocationsContent v-if="activeTab === 'locations'" ref="locationsRef" />
          <RulesContent v-if="activeTab === 'rules'" ref="rulesRef" />
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>

