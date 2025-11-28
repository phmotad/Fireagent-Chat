<template>
  <div class="flex flex-col h-full">
    <!-- Header with Agent Name -->
    <div class="border-b border-n-weak bg-n-background px-6 py-4">
      <div v-if="currentAgent" class="max-w-7xl mx-auto">
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ currentAgent.name }}
        </h1>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ currentAgent.description }}
        </p>
      </div>
      <div v-else class="max-w-7xl mx-auto">
        <woot-loading-state message="Carregando agente..." />
      </div>
    </div>

    <!-- Tabs Navigation -->
    <div class="border-b border-n-weak bg-n-background">
      <div class="max-w-7xl mx-auto px-6">
        <woot-tabs :index="activeTabIndex" @change="onTabChange">
          <woot-tabs-item
            v-for="tab in tabs"
            :key="tab.key"
            :name="tab.name"
            :show-badge="false"
          />
        </woot-tabs>
      </div>
    </div>

    <!-- Tab Content -->
    <div class="flex-1 overflow-auto bg-n-solid-1">
      <router-view :key="$route.fullPath" />
    </div>
  </div>
</template>

<script>
/* global axios */
import { mapGetters } from 'vuex';

export default {
  name: 'AgentWrapper',
  data() {
    return {
      currentAgent: null,
      loading: false,
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
    tabs() {
      return [
        {
          key: 'settings',
          name: 'Configurações',
          route: 'agent_settings',
        },
        {
          key: 'inboxes',
          name: 'Inboxes',
          route: 'agent_inboxes',
        },
        {
          key: 'knowledge',
          name: 'Base de Conhecimento',
          route: 'agent_knowledge',
        },
        {
          key: 'tools',
          name: 'Ferramentas',
          route: 'agent_tools',
        },
      ];
    },
    activeTabIndex() {
      const currentRouteName = this.$route.name;
      const index = this.tabs.findIndex(tab => tab.route === currentRouteName);
      return index >= 0 ? index : 0;
    },
  },
  watch: {
    agentId: {
      immediate: true,
      handler() {
        this.fetchAgent();
      },
    },
  },
  methods: {
    async fetchAgent() {
      if (!this.agentId) return;

      try {
        this.loading = true;
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}`
        );
        this.currentAgent = response.data;
      } catch (error) {
        console.error('Error loading agent:', error);
      } finally {
        this.loading = false;
      }
    },
    onTabChange(index) {
      const selectedTab = this.tabs[index];
      if (selectedTab && selectedTab.route !== this.$route.name) {
        this.$router.push({
          name: selectedTab.route,
          params: { accountId: this.accountId, agentId: this.agentId },
        });
      }
    },
  },
};
</script>
