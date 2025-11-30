<script setup>
/* global axios */
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { isAdmin } = useAdmin();
const { accountId } = useAccount();

const agents = ref([]);
const loading = ref(true);
const deleteLoading = ref({});

const showDeletePopup = ref(false);
const selectedAgent = ref({});

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

const openDelete = agent => {
  showDeletePopup.value = true;
  selectedAgent.value = agent;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedAgent.value = {};
};

const deleteAgent = async () => {
  try {
    deleteLoading.value[selectedAgent.value.id] = true;
    await axios.delete(`/api/v1/accounts/${accountId.value}/ai_agents/${selectedAgent.value.id}`);
    useAlert('Agente excluído com sucesso');
    await fetchAgents();
  } catch (error) {
    useAlert('Erro ao excluir agente');
    console.error(error);
  } finally {
    deleteLoading.value[selectedAgent.value.id] = false;
    closeDelete();
  }
};

onMounted(() => {
  fetchAgents();
});
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header -->
    <div class="border-b border-n-weak p-6">
      <div class="flex items-center justify-between mb-2">
        <div>
          <h2 class="text-2xl font-semibold text-n-slate-12">Agentes de IA</h2>
          <p class="text-sm text-n-slate-11 mt-1">
            Gerencie seus agentes de IA personalizados com integração Gemini
          </p>
        </div>
        <router-link v-if="isAdmin" :to="{ name: 'agent_settings_new' }">
          <Button
            icon="i-lucide-circle-plus"
            label="Novo Agente"
          />
        </router-link>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto p-6">
      <div class="max-w-5xl mx-auto">
      <woot-loading-state
        v-if="loading"
        message="Carregando agentes..."
      />
      <p
        v-else-if="!agents.length"
        class="flex flex-col items-center justify-center h-full text-base p-8"
      >
        Nenhum agente criado ainda. Clique em "Novo Agente" para começar.
      </p>

      <table v-else class="min-w-full divide-y divide-n-weak">
        <tbody class="divide-y divide-n-weak">
          <tr
            v-for="agent in agents"
            :key="agent.id"
            class="cursor-pointer hover:bg-n-solid-2 transition-colors"
            @click="$router.push({ name: 'agent_settings_edit', params: { agentId: agent.id } })"
          >
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span class="block font-medium capitalize">{{ agent.name }}</span>
              <p class="mb-0 text-sm text-n-slate-10">{{ agent.description }}</p>
              <div class="mt-1 flex gap-2 text-xs text-n-slate-9">
                <span>Modelo: {{ agent.model }}</span>
                <span>•</span>
                <span>Memória: {{ agent.memory_window_size }} msgs</span>
              </div>
            </td>

            <td class="py-4 flex justify-end gap-1" @click.stop>
              <router-link
                :to="{
                  name: 'agent_settings_edit',
                  params: { agentId: agent.id },
                }"
              >
                <Button
                  v-if="isAdmin"
                  v-tooltip.top="'Configurar agente'"
                  icon="i-lucide-settings"
                  slate
                  xs
                  faded
                />
              </router-link>

              <Button
                v-if="isAdmin"
                v-tooltip.top="'Excluir agente'"
                icon="i-lucide-trash-2"
                xs
                ruby
                faded
                :is-loading="deleteLoading[agent.id]"
                @click="openDelete(agent)"
              />
            </td>
          </tr>
        </tbody>
      </table>
      </div>
    </div>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="`Excluir ${selectedAgent.name}?`"
      message="Tem certeza que deseja excluir este agente? Esta ação não pode ser desfeita."
      :confirm-text="`Sim, excluir ${selectedAgent.name}`"
      reject-text="Cancelar"
      :confirm-value="selectedAgent.name"
      :confirm-place-holder-text="`Digite '${selectedAgent.name}' para confirmar`"
      @on-confirm="deleteAgent"
      @on-close="closeDelete"
    />
  </div>
</template>
