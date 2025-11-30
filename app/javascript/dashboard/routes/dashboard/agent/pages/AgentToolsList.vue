<script setup>
/* global axios */
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { computed, ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const { accountId } = useAccount();
const router = useRouter();

const agents = ref([]);
const loading = ref(true);

const fetchAgents = async () => {
  try {
    loading.value = true;
    const response = await axios.get(`/api/v1/accounts/${accountId.value}/ai_agents`);
    agents.value = response.data;
  } catch (error) {
    useAlert('Erro ao carregar agentes');
    console.error(error);
  } finally {
    loading.value = false;
  }
};

const selectAgent = (agentId) => {
  router.push({
    name: 'agent_tools_edit',
    params: { accountId: accountId.value, agentId },
  });
};

onMounted(() => {
  fetchAgents();
});
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header -->
    <div class="flex items-center justify-between p-6 border-b border-n-weak">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          Ferramentas
        </h1>
        <p class="mt-1 text-sm text-n-slate-11">
          Selecione um agente para gerenciar suas ferramentas
        </p>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto p-6">
      <woot-loading-state
        v-if="loading"
        message="Carregando agentes..."
      />
      <div
        v-else-if="!agents.length"
        class="flex flex-col items-center justify-center h-full text-base"
      >
        <i class="i-lucide-bot text-6xl text-n-slate-9 mb-4" />
        <p class="text-n-slate-11">
          Nenhum agente criado ainda. Crie um agente em "Configurações" primeiro.
        </p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="agent in agents"
          :key="agent.id"
          class="p-6 border border-n-weak rounded-lg cursor-pointer hover:bg-n-solid-2 hover:border-n-blue-7 transition-all"
          @click="selectAgent(agent.id)"
        >
          <div class="flex items-start gap-4">
            <div class="flex-shrink-0">
              <i class="i-lucide-bot text-3xl text-n-blue-9" />
            </div>
            <div class="flex-1 min-w-0">
              <h3 class="text-lg font-semibold text-n-slate-12 mb-1">
                {{ agent.name }}
              </h3>
              <p class="text-sm text-n-slate-11 mb-2">
                {{ agent.description }}
              </p>
              <div class="flex gap-2 text-xs text-n-slate-9">
                <span>Modelo: {{ agent.model }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
