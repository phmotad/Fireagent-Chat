<template>
  <div class="flex flex-col h-full p-6">
    <div class="max-w-5xl">
      <div class="mb-6">
        <h2 class="text-2xl font-semibold mb-2 text-n-slate-12">Base de Conhecimento</h2>
        <p class="text-n-slate-11">
          Gerencie os documentos e fontes de conhecimento do agente
        </p>
      </div>

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

        <div v-else-if="!knowledgeSources.length" class="p-8 text-center text-n-slate-10">
          Nenhuma fonte de conhecimento adicionada ainda
        </div>

        <div v-else class="divide-y divide-n-weak">
          <div
            v-for="source in knowledgeSources"
            :key="source.id"
            class="p-4 flex items-center justify-between hover:bg-n-solid-2"
          >
            <div class="flex-1">
              <p class="font-medium text-n-slate-12">{{ source.file_path }}</p>
              <p class="text-sm text-n-slate-11">
                Status: 
                <span
                  :class="{
                    'text-green-600': source.status === 'ready',
                    'text-yellow-600': source.status === 'processing',
                    'text-red-600': source.status === 'failed',
                  }"
                >
                  {{ getStatusLabel(source.status) }}
                </span>
              </p>
            </div>

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
</template>

<script>
import { mapGetters } from 'vuex';
import axios from 'axios';
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
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
  },
  mounted() {
    this.fetchKnowledge();
  },
  methods: {
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
  },
};
</script>
