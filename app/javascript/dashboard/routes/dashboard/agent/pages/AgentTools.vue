<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header -->
    <div class="border-b border-n-weak p-6">
      <div class="flex items-center gap-3 mb-2">
        <router-link
          :to="{ name: 'agent_tools' }"
          class="text-n-slate-11 hover:text-n-slate-12 transition-colors"
        >
          <i class="i-lucide-arrow-left text-xl" />
        </router-link>
        <div class="flex-1">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-2xl font-semibold text-n-slate-12">Ferramentas do Agente</h2>
              <p v-if="currentAgent" class="text-sm text-n-slate-11 mt-1">
                Agente: {{ currentAgent.name }}
              </p>
            </div>
            <Button
              icon="i-lucide-plus"
              label="Nova Ferramenta"
              @click="openToolModal()"
            />
          </div>
        </div>
      </div>
      <p class="text-n-slate-11">
        Configure as ferramentas que o agente pode usar durante as conversas
      </p>
    </div>

    <!-- Main Content -->
    <div class="flex-1 overflow-auto p-6">
      <div class="max-w-5xl mx-auto">

      <!-- Tools List -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <woot-loading-state message="Carregando ferramentas..." />
      </div>

      <div v-else-if="!tools.length" class="flex items-center justify-center py-20">
        <div class="max-w-md text-center">
          <div class="w-20 h-20 mx-auto mb-6 rounded-full bg-n-solid-3 flex items-center justify-center">
            <i class="i-lucide-wrench text-4xl text-n-slate-10"></i>
          </div>
          <h3 class="text-xl font-medium text-n-slate-12 mb-2">
            Nenhuma ferramenta configurada
          </h3>
          <p class="text-n-slate-11 mb-6">
            Adicione ferramentas para expandir as capacidades do seu agente
          </p>
          <Button
            icon="i-lucide-plus"
            label="Adicionar Primeira Ferramenta"
            @click="openToolModal()"
          />
        </div>
      </div>

      <div v-else class="space-y-4">
        <!-- Native Tools Section -->
        <div v-if="nativeTools.length" class="bg-n-background rounded-lg border border-n-weak">
          <div class="px-6 py-4 border-b border-n-weak bg-n-solid-2">
            <h3 class="text-lg font-medium text-n-slate-12 flex items-center gap-2">
              <i class="i-lucide-sparkles text-n-brand"></i>
              Ferramentas Nativas
            </h3>
            <p class="text-sm text-n-slate-11 mt-1">
              Ferramentas integradas do Chatwoot
            </p>
          </div>
          <div class="divide-y divide-n-weak">
            <ToolCard
              v-for="tool in nativeTools"
              :key="tool.id"
              :tool="tool"
              @edit="openToolModal(tool)"
              @delete="confirmDelete(tool)"
              @toggle="toggleTool(tool)"
            />
          </div>
        </div>

        <!-- HTTP/HTTPS Tools Section -->
        <div v-if="httpTools.length" class="bg-n-background rounded-lg border border-n-weak">
          <div class="px-6 py-4 border-b border-n-weak bg-n-solid-2">
            <h3 class="text-lg font-medium text-n-slate-12 flex items-center gap-2">
              <i class="i-lucide-globe text-blue-500"></i>
              Ferramentas HTTP/HTTPS
            </h3>
            <p class="text-sm text-n-slate-11 mt-1">
              APIs e serviços externos via HTTP
            </p>
          </div>
          <div class="divide-y divide-n-weak">
            <ToolCard
              v-for="tool in httpTools"
              :key="tool.id"
              :tool="tool"
              @edit="openToolModal(tool)"
              @delete="confirmDelete(tool)"
              @toggle="toggleTool(tool)"
            />
          </div>
        </div>

        <!-- MCP Tools Section -->
        <div v-if="mcpTools.length" class="bg-n-background rounded-lg border border-n-weak">
          <div class="px-6 py-4 border-b border-n-weak bg-n-solid-2">
            <h3 class="text-lg font-medium text-n-slate-12 flex items-center gap-2">
              <i class="i-lucide-plug text-purple-500"></i>
              Model Context Protocol (MCP)
            </h3>
            <p class="text-sm text-n-slate-11 mt-1">
              Servidores MCP integrados
            </p>
          </div>
          <div class="divide-y divide-n-weak">
            <ToolCard
              v-for="tool in mcpTools"
              :key="tool.id"
              :tool="tool"
              @edit="openToolModal(tool)"
              @delete="confirmDelete(tool)"
              @toggle="toggleTool(tool)"
            />
          </div>
        </div>
      </div>
      </div>
    </div>

    <!-- Tool Modal -->
    <woot-modal
      v-model:show="showToolModal"
      :on-close="closeToolModal"
      size="large"
    >
      <ToolModal
        :tool="selectedTool"
        :agent-id="agentId"
        @save="handleToolSaved"
        @close="closeToolModal"
      />
    </woot-modal>

    <!-- Delete Confirmation -->
    <woot-delete-modal
      v-model:show="showDeleteModal"
      :title="`Excluir ${toolToDelete?.name}?`"
      :message="`Tem certeza que deseja excluir esta ferramenta? Esta ação não pode ser desfeita.`"
      :confirm-text="'Excluir Ferramenta'"
      :reject-text="'Cancelar'"
      @confirm="deleteTool"
    />
  </div>
</template>

<script>
/* global axios */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ToolCard from '../components/ToolCard.vue';
import ToolModal from '../components/ToolModal.vue';

export default {
  name: 'AgentTools',
  components: {
    Button,
    ToolCard,
    ToolModal,
  },
  data() {
    return {
      loading: false,
      tools: [],
      showToolModal: false,
      selectedTool: null,
      showDeleteModal: false,
      toolToDelete: null,
      currentAgent: null,
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
    nativeTools() {
      return this.tools.filter(t => t.tool_type === 'native');
    },
    httpTools() {
      return this.tools.filter(t => t.tool_type === 'http' || t.tool_type === 'https');
    },
    mcpTools() {
      return this.tools.filter(t => t.tool_type === 'mcp');
    },
  },
  mounted() {
    this.fetchAgent();
    this.fetchTools();
  },
  methods: {
    async fetchAgent() {
      try {
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}`
        );
        this.currentAgent = response.data;
      } catch (error) {
        useAlert('Erro ao carregar agente');
      }
    },

    async fetchTools() {
      try {
        this.loading = true;
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools`
        );
        this.tools = response.data;
      } catch (error) {
        useAlert('Erro ao carregar ferramentas');
      } finally {
        this.loading = false;
      }
    },

    openToolModal(tool = null) {
      this.selectedTool = tool;
      this.showToolModal = true;
    },

    closeToolModal() {
      this.showToolModal = false;
      this.selectedTool = null;
    },

    handleToolSaved() {
      this.closeToolModal();
      this.fetchTools();
    },

    confirmDelete(tool) {
      this.toolToDelete = tool;
      this.showDeleteModal = true;
    },

    async deleteTool() {
      try {
        await axios.delete(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools/${this.toolToDelete.id}`
        );
        useAlert('Ferramenta removida com sucesso');
        this.fetchTools();
      } catch (error) {
        useAlert('Erro ao remover ferramenta');
      } finally {
        this.showDeleteModal = false;
        this.toolToDelete = null;
      }
    },

    async toggleTool(tool) {
      try {
        await axios.patch(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools/${tool.id}`,
          { enabled: !tool.enabled }
        );
        useAlert(tool.enabled ? 'Ferramenta desativada' : 'Ferramenta ativada');
        this.fetchTools();
      } catch (error) {
        useAlert('Erro ao alterar ferramenta');
      }
    },
  },
};
</script>
