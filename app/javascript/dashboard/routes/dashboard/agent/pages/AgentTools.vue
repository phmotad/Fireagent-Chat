<template>
  <div class="flex flex-col h-full p-6">
    <div class="max-w-5xl">
      <div class="mb-6">
        <h2 class="text-2xl font-semibold mb-2 text-n-slate-12">Ferramentas</h2>
        <p class="text-n-slate-11">
          Configure as ferramentas que o agente pode usar
        </p>
      </div>

      <!-- Add Tool -->
      <div class="bg-n-background rounded-lg border border-n-weak p-6 mb-6">
        <h3 class="text-lg font-medium mb-4">Adicionar Ferramenta</h3>

        <form @submit.prevent="addTool" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <Input
              v-model="newTool.name"
              label="Nome"
              placeholder="Ex: handover_to_human"
            />

            <div>
              <label class="block text-sm font-medium mb-2 text-n-slate-12">Tipo</label>
              <select
                v-model="newTool.tool_type"
                class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
                required
              >
                <option value="chatwoot">Chatwoot</option>
                <option value="mcp">MCP</option>
                <option value="custom">Custom</option>
              </select>
            </div>
          </div>

          <Input
            v-model="newTool.description"
            label="Descrição"
            placeholder="O que esta ferramenta faz?"
          />

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Configuração (JSON)</label>
            <textarea
              v-model="newTool.configuration"
              rows="4"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 font-mono text-sm"
              placeholder='{"param": "value"}'
            />
          </div>

          <!-- Conditions Section -->
          <div class="border-t border-n-weak pt-4">
            <h4 class="text-md font-medium mb-3 text-n-slate-12">Critérios de Execução (Opcional)</h4>
            <p class="text-sm text-n-slate-11 mb-4">
              Defina quando esta ferramenta deve ser executada
            </p>

            <div class="space-y-4">
              <!-- Keywords -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Palavras-chave (separadas por vírgula)
                </label>
                <Input
                  v-model="conditions.keywords"
                  placeholder="urgente, ajuda, problema"
                  customInputClass="w-full"
                />
                <p class="text-xs text-n-slate-10 mt-1">
                  A mensagem deve conter pelo menos uma destas palavras
                </p>
              </div>

              <!-- Sentiment -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Sentimento
                </label>
                <select
                  v-model="conditions.sentiment"
                  class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
                >
                  <option value="">Qualquer</option>
                  <option value="positive">Positivo</option>
                  <option value="neutral">Neutro</option>
                  <option value="negative">Negativo</option>
                </select>
              </div>

              <!-- Unanswered Messages -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Mensagens sem resposta (mínimo)
                </label>
                <Input
                  v-model.number="conditions.unanswered_messages"
                  type="number"
                  min="0"
                  placeholder="3"
                  customInputClass="w-full"
                />
                <p class="text-xs text-n-slate-10 mt-1">
                  Execute apenas se houver X ou mais mensagens sem resposta
                </p>
              </div>

              <!-- Regex Pattern -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Padrão Regex
                </label>
                <Input
                  v-model="conditions.regex"
                  placeholder="\d{3}-\d{4}"
                  customInputClass="w-full font-mono text-sm"
                />
                <p class="text-xs text-n-slate-10 mt-1">
                  Expressão regular para validar o conteúdo da mensagem
                </p>
              </div>

              <!-- Time-based -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium mb-2 text-n-slate-12">
                    Horário inicial
                  </label>
                  <Input
                    v-model="conditions.start_time"
                    type="time"
                    customInputClass="w-full"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium mb-2 text-n-slate-12">
                    Horário final
                  </label>
                  <Input
                    v-model="conditions.end_time"
                    type="time"
                    customInputClass="w-full"
                  />
                </div>
              </div>

              <!-- Message Count -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Contagem de mensagens (mínimo)
                </label>
                <Input
                  v-model.number="conditions.message_count"
                  type="number"
                  min="0"
                  placeholder="5"
                  customInputClass="w-full"
                />
                <p class="text-xs text-n-slate-10 mt-1">
                  Total de mensagens na conversa
                </p>
              </div>

              <!-- Status -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Status da Conversa
                </label>
                <select
                  v-model="conditions.status"
                  class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
                >
                  <option value="">Qualquer</option>
                  <option value="open">Aberta</option>
                  <option value="resolved">Resolvida</option>
                  <option value="pending">Pendente</option>
                </select>
              </div>

              <!-- Custom Expression -->
              <div>
                <label class="block text-sm font-medium mb-2 text-n-slate-12">
                  Expressão Customizada (Python)
                </label>
                <textarea
                  v-model="conditions.custom_expression"
                  rows="3"
                  class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 font-mono text-sm"
                  placeholder="len(history) > 5 and sentiment == 'negative'"
                />
                <p class="text-xs text-n-slate-10 mt-1">
                  Expressão Python avançada com acesso a: message, history, sentiment, status
                </p>
              </div>
            </div>
          </div>

          <div class="flex justify-end">
            <Button
              type="submit"
              :is-loading="adding"
              label="Adicionar Ferramenta"
            />
          </div>
        </form>
      </div>

      <!-- Tools List -->
      <div class="bg-n-background rounded-lg border border-n-weak">
        <div v-if="loading" class="p-8 text-center">
          <woot-loading-state message="Carregando..." />
        </div>

        <div v-else-if="!tools.length" class="p-8 text-center text-n-slate-10">
          Nenhuma ferramenta configurada ainda
        </div>

        <div v-else class="divide-y divide-n-weak">
          <div
            v-for="tool in tools"
            :key="tool.id"
            class="p-4 hover:bg-n-solid-2"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-1">
                  <h4 class="font-medium text-n-slate-12">{{ tool.name }}</h4>
                  <span class="text-xs px-2 py-1 rounded bg-n-solid-3 text-n-slate-11">
                    {{ tool.tool_type }}
                  </span>
                </div>
                <p class="text-sm text-n-slate-11 mb-2">
                  {{ tool.description }}
                </p>

                <!-- Conditions Summary -->
                <div v-if="hasConditions(tool)" class="mb-2">
                  <div class="flex flex-wrap gap-1">
                    <span class="text-xs px-2 py-1 rounded bg-amber-100 text-amber-800">
                      Com critérios
                    </span>
                    <span v-if="tool.conditions?.keywords" class="text-xs px-2 py-1 rounded bg-blue-100 text-blue-800">
                      Keywords
                    </span>
                    <span v-if="tool.conditions?.sentiment" class="text-xs px-2 py-1 rounded bg-purple-100 text-purple-800">
                      Sentimento
                    </span>
                    <span v-if="tool.conditions?.time_based" class="text-xs px-2 py-1 rounded bg-green-100 text-green-800">
                      Horário
                    </span>
                    <span v-if="tool.conditions?.regex" class="text-xs px-2 py-1 rounded bg-red-100 text-red-800">
                      Regex
                    </span>
                  </div>
                </div>

                <details class="text-xs mb-2">
                  <summary class="cursor-pointer text-n-slate-10 hover:text-n-slate-12">
                    Ver configuração
                  </summary>
                  <pre class="mt-2 p-2 bg-n-solid-2 rounded overflow-x-auto text-n-slate-11">{{ formatJSON(tool.configuration) }}</pre>
                </details>

                <details v-if="hasConditions(tool)" class="text-xs">
                  <summary class="cursor-pointer text-n-slate-10 hover:text-n-slate-12">
                    Ver critérios
                  </summary>
                  <pre class="mt-2 p-2 bg-n-solid-2 rounded overflow-x-auto text-n-slate-11">{{ formatJSON(tool.conditions) }}</pre>
                </details>
              </div>

              <Button
                variant="ghost"
                color="ruby"
                size="sm"
                icon="i-lucide-trash-2"
                label="Remover"
                @click="removeTool(tool.id)"
              />
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
  name: 'AgentTools',
  components: {
    Button,
    Input,
  },
  data() {
    return {
      loading: false,
      adding: false,
      tools: [],
      newTool: {
        name: '',
        tool_type: 'chatwoot',
        description: '',
        configuration: '{}',
      },
      conditions: {
        keywords: '',
        sentiment: '',
        unanswered_messages: null,
        regex: '',
        start_time: '',
        end_time: '',
        message_count: null,
        status: '',
        custom_expression: '',
      },
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
  },
  mounted() {
    this.fetchTools();
  },
  methods: {
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

    async addTool() {
      try {
        this.adding = true;

        // Validate JSON
        let config = {};
        try {
          config = JSON.parse(this.newTool.configuration);
        } catch (e) {
          useAlert('Configuração JSON inválida');
          return;
        }

        // Build conditions object (only include non-empty values)
        const conditionsObj = {};

        if (this.conditions.keywords.trim()) {
          conditionsObj.keywords = this.conditions.keywords
            .split(',')
            .map(k => k.trim())
            .filter(k => k);
        }

        if (this.conditions.sentiment) {
          conditionsObj.sentiment = this.conditions.sentiment;
        }

        if (this.conditions.unanswered_messages !== null && this.conditions.unanswered_messages > 0) {
          conditionsObj.unanswered_messages = this.conditions.unanswered_messages;
        }

        if (this.conditions.regex.trim()) {
          conditionsObj.regex = this.conditions.regex;
        }

        if (this.conditions.start_time && this.conditions.end_time) {
          conditionsObj.time_based = {
            start: this.conditions.start_time,
            end: this.conditions.end_time,
          };
        }

        if (this.conditions.message_count !== null && this.conditions.message_count > 0) {
          conditionsObj.message_count = this.conditions.message_count;
        }

        if (this.conditions.status) {
          conditionsObj.status = this.conditions.status;
        }

        if (this.conditions.custom_expression.trim()) {
          conditionsObj.custom_expression = this.conditions.custom_expression;
        }

        await axios.post(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools`,
          {
            ...this.newTool,
            configuration: config,
            conditions: conditionsObj,
          }
        );

        // Reset form
        this.newTool = {
          name: '',
          tool_type: 'chatwoot',
          description: '',
          configuration: '{}',
        };
        this.conditions = {
          keywords: '',
          sentiment: '',
          unanswered_messages: null,
          regex: '',
          start_time: '',
          end_time: '',
          message_count: null,
          status: '',
          custom_expression: '',
        };

        useAlert('Ferramenta adicionada com sucesso');
        this.fetchTools();
      } catch (error) {
        useAlert('Erro ao adicionar ferramenta');
      } finally {
        this.adding = false;
      }
    },

    async removeTool(id) {
      try {
        await axios.delete(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools/${id}`
        );
        useAlert('Ferramenta removida com sucesso');
        this.fetchTools();
      } catch (error) {
        useAlert('Erro ao remover ferramenta');
      }
    },

    formatJSON(obj) {
      try {
        return JSON.stringify(obj, null, 2);
      } catch (e) {
        return obj;
      }
    },

    hasConditions(tool) {
      return tool.conditions && Object.keys(tool.conditions).length > 0;
    },
  },
};
</script>
