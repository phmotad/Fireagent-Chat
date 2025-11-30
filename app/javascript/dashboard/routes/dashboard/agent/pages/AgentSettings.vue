<template>
  <div class="flex h-full gap-6 p-8">
    <!-- Left Column: Configuration Form -->
    <div class="flex-1 overflow-auto pr-6">
      <form @submit.prevent="saveAgent">
        <div class="space-y-6">
          <!-- Basic Info -->
          <div class="bg-n-background rounded-lg border border-n-weak p-6">
            <h3 class="text-lg font-medium mb-4 text-n-slate-12">Informações Básicas</h3>
            
            <div class="space-y-4">
              <Input
                v-model="agent.name"
                label="Nome do Agente"
                placeholder="Ex: Assistente de Vendas"
              />

              <Input
                v-model="agent.description"
                label="Descrição"
                placeholder="Breve descrição do agente"
              />
            </div>
          </div>

          <!-- Model Configuration -->
          <div class="bg-n-background rounded-lg border border-n-weak p-6">
            <h3 class="text-lg font-medium mb-4 text-n-slate-12">Configuração do Modelo</h3>

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">Modelo</label>
                <select
                  v-model="agent.model"
                  class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
                >
                  <option value="gemini-2.5-pro">Gemini 2.5 Pro</option>
                  <option value="gemini-2.5-flash">Gemini 2.5 Flash</option>
                  <option value="gemini-2.5-flash-lite">Gemini 2.5 Flash Lite</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Temperatura: {{ agent.temperature }}
                </label>
                <input
                  v-model.number="agent.temperature"
                  type="range"
                  min="0"
                  max="2"
                  step="0.1"
                  class="w-full"
                />
                <p class="text-xs text-n-slate-10 mt-1">
                  Controla a criatividade (0 = conservador, 2 = muito criativo)
                </p>
              </div>

              <Input
                v-model="agent.memory_window_size"
                type="number"
                label="Janela de Memória"
                placeholder="10"
                min="1"
                max="100"
                message="Número de mensagens anteriores que o agente lembrará"
              />
            </div>
          </div>

          <!-- System Prompt -->
          <div class="bg-n-background rounded-lg border border-n-weak p-6">
            <h3 class="text-lg font-medium mb-4 text-n-slate-12">Prompt do Sistema</h3>

            <textarea
              v-model="agent.system_prompt"
              rows="8"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 font-mono text-sm"
              placeholder="Você é um assistente útil que..."
            />
          </div>

          <!-- API Key -->
          <div class="bg-n-background rounded-lg border border-n-weak p-6">
            <h3 class="text-lg font-medium mb-4 text-n-slate-12">Autenticação</h3>
            
            <Input
              v-model="agent.api_key"
              type="password"
              label="API Key do Gemini"
              placeholder="Deixe em branco para manter a atual"
              message="Sua chave de API do Google Gemini (será criptografada)"
            />
          </div>

          <!-- Actions -->
          <div class="flex justify-end gap-2">
            <Button
              variant="ghost"
              label="Cancelar"
              @click="goBack"
            />
            <Button
              type="submit"
              :is-loading="saving"
              :label="isNew ? 'Criar Agente' : 'Salvar Alterações'"
            />
          </div>
        </div>
      </form>
    </div>

    <!-- Right Column: Test Chat Panel -->
    <div v-if="!isNew" class="w-[480px] flex flex-col border-l border-n-weak bg-n-solid-2 pl-6">
      <div class="flex-1 flex flex-col">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium flex items-center gap-2 text-n-slate-12">
            <i class="i-lucide-message-square text-xl" />
            Testar Agente
          </h3>
          <Button
            size="sm"
            variant="ghost"
            color="ruby"
            label="Limpar"
            @click="clearTestContext"
          />
        </div>

        <!-- Messages -->
        <div
          ref="messagesContainer"
          class="flex-1 bg-n-background rounded-lg border border-n-weak overflow-y-auto p-4 mb-4"
        >
          <div
            v-for="(msg, index) in testMessages"
            :key="index"
            :class="[
              'mb-3 flex',
              msg.role === 'user' ? 'justify-end' : 'justify-start'
            ]"
          >
            <div
              :class="[
                'max-w-[80%] rounded-lg px-4 py-2',
                msg.role === 'user'
                  ? 'bg-n-brand text-white'
                  : 'bg-n-solid-3 text-n-slate-12'
              ]"
            >
              <p class="text-sm whitespace-pre-wrap">{{ msg.content }}</p>
              <div v-if="msg.tool_calls && msg.tool_calls.length" class="mt-2 text-xs opacity-75">
                🔧 Tools: {{ msg.tool_calls.map(t => t.name).join(', ') }}
              </div>
              <div v-if="msg.context_used" class="mt-1 text-xs opacity-75">
                📚 Usou base de conhecimento
              </div>
            </div>
          </div>
          <div v-if="testLoading" class="flex justify-start">
            <div class="bg-n-solid-3 rounded-lg px-4 py-2">
              <span class="text-sm text-n-slate-11">●●●</span>
            </div>
          </div>
        </div>

        <!-- Input -->
        <div class="flex gap-2">
          <input
            v-model="testMessage"
            type="text"
            placeholder="Digite uma mensagem para testar..."
            class="flex-1 px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 text-sm"
            @keydown.enter="sendTestMessage"
            :disabled="testLoading"
          />
          <Button
            size="sm"
            icon="i-lucide-send"
            label="Enviar"
            :disabled="!testMessage.trim() || testLoading"
            @click="sendTestMessage"
          />
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
  name: 'AgentSettings',
  components: {
    Button,
    Input,
  },
  data() {
    return {
// ... (rest of data)
      loading: false,
      saving: false,
      agent: {
        name: '',
        description: '',
        model: 'gemini-2.5-flash',
        temperature: 0.7,
        memory_window_size: 10,
        system_prompt: '',
        api_key: '',
      },
      testMessages: [],
      testMessage: '',
      testLoading: false,
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
    isNew() {
      return !this.agentId;
    },
  },
  mounted() {
    if (!this.isNew) {
      this.fetchAgent();
    }
  },
  methods: {
    async fetchAgent() {
      try {
        this.loading = true;
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}`
        );
        this.agent = response.data;
      } catch (error) {
        useAlert('Erro ao carregar agente');
      } finally {
        this.loading = false;
      }
    },

    async saveAgent() {
      try {
        this.saving = true;
        if (this.isNew) {
          const response = await axios.post(
            `/api/v1/accounts/${this.accountId}/ai_agents`,
            { ai_agent: this.agent }
          );
          useAlert('Agente criado com sucesso');
          this.$router.push({
            name: 'agent_settings',
            params: { accountId: this.accountId, agentId: response.data.id },
          });
        } else {
          await axios.put(
            `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}`,
            { ai_agent: this.agent }
          );
          useAlert('Agente atualizado com sucesso');
        }
      } catch (error) {
        useAlert('Erro ao salvar agente');
      } finally {
        this.saving = false;
      }
    },

    async sendTestMessage() {
      if (!this.testMessage.trim() || this.testLoading) return;

      const message = this.testMessage.trim();
      this.testMessages.push({
        role: 'user',
        content: message,
      });
      this.testMessage = '';
      this.testLoading = true;

      this.$nextTick(() => {
        this.scrollToBottom();
      });

      try {
        const response = await axios.post(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/test`,
          { message }
        );

        this.testMessages.push({
          role: 'assistant',
          content: response.data.response,
          tool_calls: response.data.tool_calls,
          context_used: response.data.context_used,
        });

        this.$nextTick(() => {
          this.scrollToBottom();
        });
      } catch (error) {
        useAlert(error?.response?.data?.error || 'Erro ao testar agente');
      } finally {
        this.testLoading = false;
      }
    },

    async clearTestContext() {
      try {
        await axios.delete(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/test/context`
        );
        this.testMessages = [];
        useAlert('Contexto limpo com sucesso');
      } catch (error) {
        useAlert('Erro ao limpar contexto');
      }
    },

    scrollToBottom() {
      const container = this.$refs.messagesContainer;
      if (container) {
        container.scrollTop = container.scrollHeight;
      }
    },

    goBack() {
      this.$router.push({
        name: 'agent_index',
        params: { accountId: this.accountId },
      });
    },
  },
};
</script>
