<template>
  <div class="flex flex-col h-full">
    <!-- Header with Agent Selector -->
    <div class="border-b border-n-weak bg-n-background px-8 py-4">
      <div class="flex items-center justify-between">
        <div class="flex-1">
          <div class="flex items-center gap-3">
            <label class="text-sm font-medium text-n-slate-11">Agente:</label>
            <select
              v-if="agents.length"
              v-model="selectedAgentId"
              @change="onAgentChange"
              class="text-lg font-semibold bg-n-background border border-n-weak rounded px-3 py-1 cursor-pointer text-n-slate-12"
            >
              <option v-for="agent in agents" :key="agent.id" :value="agent.id">
                {{ agent.name }}
              </option>
            </select>
            <span v-else class="text-lg font-semibold text-n-slate-12">
              {{ currentAgent?.name || 'Carregando...' }}
            </span>
          </div>
          <p v-if="currentAgent" class="text-sm text-n-slate-11 mt-1 ml-20">
            {{ currentAgent.description }}
          </p>
        </div>
      </div>
    </div>

    <!-- Tabs Navigation -->
    <div class="border-b border-n-weak bg-n-background px-8">
      <woot-tabs :index="activeTabIndex" @change="onTabChange">
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>
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
      agents: [],
      loading: false,
      selectedAgentId: null,
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
      handler(newId) {
        this.selectedAgentId = newId;
        this.fetchAgent();
      },
    },
  },
  mounted() {
    this.fetchAgents();
  },
  methods: {
    async fetchAgents() {
      try {
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents`
        );
        this.agents = response.data;
      } catch (error) {
        console.error('Error loading agents:', error);
      }
    },
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
    onAgentChange() {
      if (this.selectedAgentId && this.selectedAgentId !== this.agentId) {
        // Navigate to the same tab but with the new agent
        this.$router.push({
          name: this.$route.name,
          params: { accountId: this.accountId, agentId: this.selectedAgentId },
        });
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
