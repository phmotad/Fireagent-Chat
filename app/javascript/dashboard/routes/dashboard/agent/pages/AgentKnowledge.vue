<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header -->
    <div class="border-b border-n-weak p-6">
      <div class="flex items-center gap-3 mb-2">
        <router-link
          :to="{ name: 'agent_knowledge' }"
          class="text-n-slate-11 hover:text-n-slate-12 transition-colors"
        >
          <i class="i-lucide-arrow-left text-xl" />
        </router-link>
        <div>
          <h2 class="text-2xl font-semibold text-n-slate-12">Base de Conhecimento</h2>
          <p v-if="currentAgent" class="text-sm text-n-slate-11 mt-1">
            Agente: {{ currentAgent.name }}
          </p>
        </div>
      </div>
      <p class="text-n-slate-11">
        Gerencie os documentos e fontes de conhecimento do agente
      </p>
    </div>

    <div class="flex-1 overflow-auto p-6">
      <div class="max-w-5xl mx-auto">

      <!-- Add Knowledge Source -->
      <div class="bg-n-background rounded-lg border border-n-weak p-6 mb-6">
        <h3 class="text-lg font-medium mb-4">Adicionar Fonte de Conhecimento</h3>

        <form @submit.prevent="addKnowledge" class="space-y-4">
          <div class="grid grid-cols-1 gap-4">
            <!-- Upload File Option -->
            <div>
              <label class="block text-sm font-medium mb-2 text-n-slate-12">
                Upload de Arquivo
              </label>
              <input
                ref="fileInput"
                type="file"
                accept=".pdf,.txt,.md,.html,.csv,.json,.doc,.docx"
                @change="handleFileSelect"
                class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:text-sm file:font-medium file:bg-n-solid-3 file:text-n-slate-12 hover:file:bg-n-solid-4"
              />
              <p v-if="selectedFile" class="mt-2 text-sm text-n-slate-11">
                Arquivo selecionado: {{ selectedFile.name }}
              </p>
            </div>

            <!-- OR divider -->
            <div class="flex items-center gap-4">
              <div class="flex-1 border-t border-n-weak"></div>
              <span class="text-sm text-n-slate-10">OU</span>
              <div class="flex-1 border-t border-n-weak"></div>
            </div>

            <!-- URL/Path Option -->
            <div>
              <label class="block text-sm font-medium mb-2 text-n-slate-12">
                URL ou Caminho
              </label>
              <Input
                v-model="newKnowledgePath"
                placeholder="https://exemplo.com/documento.pdf ou /caminho/arquivo.txt"
                customInputClass="w-full"
              />
            </div>
          </div>

          <div class="flex justify-end">
            <Button
              type="submit"
              :is-loading="adding"
              :disabled="!selectedFile && !newKnowledgePath.trim()"
              label="Adicionar"
            />
          </div>
        </form>
      </div>

      <!-- Knowledge List -->
      <div class="bg-n-background rounded-lg border border-n-weak">
        <div v-if="loading" class="p-8 text-center">
          <woot-loading-state message="Carregando..." />
        </div>

        <div v-else-if="!knowledgeSources.length" class="p-12 text-center">
          <div class="max-w-sm mx-auto">
            <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-n-solid-3 flex items-center justify-center">
              <i class="i-lucide-book text-3xl text-n-slate-10"></i>
            </div>
            <h3 class="text-lg font-medium text-n-slate-12 mb-2">
              Nenhuma fonte de conhecimento
            </h3>
            <p class="text-sm text-n-slate-11 mb-4">
              Adicione documentos, PDFs ou URLs para treinar o agente com conhecimento específico
            </p>
            <p class="text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded p-3">
              ⚠️ <strong>Nota:</strong> O processamento usa a API do Gemini. Certifique-se de ter quota disponível.
            </p>
          </div>
        </div>

        <div v-else class="divide-y divide-n-weak">
          <div
            v-for="source in knowledgeSources"
            :key="source.id"
            class="p-4 flex items-center justify-between hover:bg-n-solid-2 cursor-pointer"
            @click="viewSource(source)"
          >
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-1">
                <i
                  class="text-lg"
                  :class="{
                    'i-lucide-file-text text-blue-600': source.file_path.endsWith('.txt') || source.file_path.endsWith('.md'),
                    'i-lucide-file-type text-red-600': source.file_path.endsWith('.pdf'),
                    'i-lucide-link text-green-600': source.file_path.startsWith('http'),
                    'i-lucide-file text-gray-600': true
                  }"
                ></i>
                <p class="font-medium text-n-slate-12">{{ source.file_path }}</p>
              </div>
              <div class="flex items-center gap-3 text-sm">
                <span class="text-n-slate-11">Status:</span>
                <span
                  class="inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium"
                  :class="{
                    'bg-green-100 text-green-700': source.status === 'ready',
                    'bg-yellow-100 text-yellow-700': source.status === 'processing',
                    'bg-red-100 text-red-700': source.status === 'failed',
                  }"
                >
                  <i
                    class="text-sm"
                    :class="{
                      'i-lucide-check-circle': source.status === 'ready',
                      'i-lucide-loader-2 animate-spin': source.status === 'processing',
                      'i-lucide-x-circle': source.status === 'failed',
                    }"
                  ></i>
                  {{ getStatusLabel(source.status) }}
                </span>
                <span v-if="source.status === 'failed' && source.metadata && source.metadata.error" class="text-xs text-red-600">
                  {{ source.metadata.error }}
                </span>
              </div>
            </div>

            <div class="flex gap-2" @click.stop>
              <Button
                variant="ghost"
                size="sm"
                icon="i-lucide-eye"
                label="Ver"
                @click="viewSource(source)"
              />
              <Button
                variant="ghost"
                color="ruby"
                size="sm"
                icon="i-lucide-trash-2"
                label="Remover"
                @click="removeKnowledge(source.id)"
              />
            </div>
          </div>
        </div>
      </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global axios */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

export default {
  name: 'AgentKnowledge',
  components: {
    Button,
    Input,
  },
  data() {
    return {
      loading: false,
      adding: false,
      knowledgeSources: [],
      newKnowledgePath: '',
      selectedFile: null,
      currentAgent: null,
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
  },
  mounted() {
    this.fetchAgent();
    this.fetchKnowledge();
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

    async fetchKnowledge() {
      try {
        this.loading = true;
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/knowledge`
        );
        this.knowledgeSources = response.data;
      } catch (error) {
        useAlert('Erro ao carregar fontes de conhecimento');
      } finally {
        this.loading = false;
      }
    },

    handleFileSelect(event) {
      const file = event.target.files[0];
      if (file) {
        this.selectedFile = file;
        // Clear path input when file is selected
        this.newKnowledgePath = '';
      }
    },

    async addKnowledge() {
      try {
        this.adding = true;

        // Create FormData for multipart/form-data
        const formData = new FormData();

        if (this.selectedFile) {
          // Upload file
          formData.append('document', this.selectedFile);
          formData.append('file_path', this.selectedFile.name);
        } else if (this.newKnowledgePath.trim()) {
          // Use URL or path
          formData.append('file_path', this.newKnowledgePath);
        } else {
          useAlert('Selecione um arquivo ou informe um caminho/URL');
          return;
        }

        await axios.post(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/knowledge`,
          formData,
          {
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          }
        );

        // Clear form
        this.newKnowledgePath = '';
        this.selectedFile = null;
        if (this.$refs.fileInput) {
          this.$refs.fileInput.value = '';
        }

        useAlert('Fonte adicionada com sucesso. O processamento iniciará em breve.');
        this.fetchKnowledge();
      } catch (error) {
        useAlert('Erro ao adicionar fonte');
      } finally {
        this.adding = false;
      }
    },

    async removeKnowledge(id) {
      try {
        await axios.delete(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/knowledge/${id}`
        );
        useAlert('Fonte removida com sucesso');
        this.fetchKnowledge();
      } catch (error) {
        useAlert('Erro ao remover fonte');
      }
    },

    getStatusLabel(status) {
      const labels = {
        ready: 'Pronto',
        processing: 'Processando',
        failed: 'Falhou',
      };
      return labels[status] || status;
    },

    viewSource(source) {
      // TODO: Implement modal/drawer to view source details
      console.log('View source:', source);
    },
  },
};
</script>
