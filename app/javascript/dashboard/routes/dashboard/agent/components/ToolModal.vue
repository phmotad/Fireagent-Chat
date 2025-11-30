<template>
  <div class="p-6">
    <h2 class="text-2xl font-semibold mb-6 text-n-slate-12">
      {{ isEdit ? 'Editar Ferramenta' : 'Nova Ferramenta' }}
    </h2>

    <form @submit.prevent="saveTool">
      <!-- Tool Type Selection -->
      <div class="mb-6">
        <label class="block text-sm font-medium mb-2 text-n-slate-12">Tipo de Ferramenta</label>
        <div class="grid grid-cols-3 gap-3">
          <button
            v-for="type in toolTypes"
            :key="type.value"
            type="button"
            @click="form.tool_type = type.value"
            :class="[
              'p-4 border-2 rounded-lg transition-all',
              form.tool_type === type.value
                ? 'border-n-brand bg-brand-50'
                : 'border-n-weak hover:border-n-alpha-3'
            ]"
          >
            <i :class="[type.icon, 'text-2xl mb-2', form.tool_type === type.value ? 'text-n-brand' : 'text-n-slate-10']"></i>
            <h4 class="font-medium text-sm" :class="form.tool_type === type.value ? 'text-n-brand' : 'text-n-slate-12'">
              {{ type.label }}
            </h4>
            <p class="text-xs text-n-slate-11 mt-1">{{ type.description }}</p>
          </button>
        </div>
      </div>

      <!-- Basic Info -->
      <div class="space-y-4 mb-6">
        <Input
          v-model="form.name"
          label="Nome da Ferramenta"
          placeholder="Ex: handover_to_human"
          required
        />

        <div>
          <label class="block text-sm font-medium mb-2 text-n-slate-12">Descrição</label>
          <textarea
            v-model="form.description"
            rows="3"
            class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
            placeholder="Descreva o que esta ferramenta faz..."
            required
          />
        </div>
      </div>

      <!-- Configuration based on tool type -->
      <div class="mb-6 p-4 border border-n-weak rounded-lg bg-n-solid-1">
        <h3 class="text-lg font-medium mb-4 text-n-slate-12">Configuração</h3>

        <!-- Native Tool Configuration -->
        <div v-if="form.tool_type === 'native'" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Tipo de Ferramenta Nativa</label>
            <select
              v-model="form.configuration.native_type"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
              required
            >
              <option value="">Selecione...</option>
              <option value="macro">Macro do Chatwoot</option>
              <option value="schedule">Agendamento</option>
              <option value="handover">Transferência para Humano</option>
            </select>
          </div>

          <!-- Macro Selection -->
          <div v-if="form.configuration.native_type === 'macro'">
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Macro</label>
            <select
              v-model="form.configuration.macro_id"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
              required
            >
              <option value="">Carregando macros...</option>
              <!-- Macros will be loaded dynamically -->
            </select>
            <p class="text-xs text-n-slate-10 mt-1">
              Selecione a macro que será executada pelo agente
            </p>
          </div>

          <!-- Schedule Configuration -->
          <div v-if="form.configuration.native_type === 'schedule'" class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-2 text-n-slate-12">Ação do Agendamento</label>
              <select
                v-model="form.configuration.schedule_action"
                class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
                required
              >
                <option value="create">Criar Agendamento</option>
                <option value="list">Listar Agendamentos</option>
                <option value="delete">Deletar Agendamento</option>
                <option value="reschedule">Reagendar</option>
              </select>
            </div>
          </div>

          <!-- Handover Configuration -->
          <div v-if="form.configuration.native_type === 'handover'">
            <div class="flex items-center gap-2 mb-2">
              <input
                v-model="form.configuration.auto_assign"
                type="checkbox"
                id="auto_assign"
                class="rounded"
              />
              <label for="auto_assign" class="text-sm text-n-slate-12">
                Atribuir automaticamente ao primeiro agente disponível
              </label>
            </div>
          </div>
        </div>

        <!-- HTTP/HTTPS Tool Configuration -->
        <div v-else-if="form.tool_type === 'http' || form.tool_type === 'https'" class="space-y-4">
          <Input
            v-model="form.configuration.url"
            label="URL do Endpoint"
            :placeholder="`https://api.example.com/endpoint`"
            required
          />

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Método HTTP</label>
            <select
              v-model="form.configuration.method"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
              required
            >
              <option value="GET">GET</option>
              <option value="POST">POST</option>
              <option value="PUT">PUT</option>
              <option value="PATCH">PATCH</option>
              <option value="DELETE">DELETE</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Autenticação</label>
            <select
              v-model="form.configuration.auth_type"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
            >
              <option value="none">Nenhuma</option>
              <option value="bearer">Bearer Token</option>
              <option value="api_key">API Key</option>
              <option value="basic">Basic Auth</option>
            </select>
          </div>

          <Input
            v-if="form.configuration.auth_type === 'bearer'"
            v-model="form.configuration.auth_token"
            type="password"
            label="Bearer Token"
            placeholder="Token de autenticação"
          />

          <Input
            v-if="form.configuration.auth_type === 'api_key'"
            v-model="form.configuration.api_key"
            type="password"
            label="API Key"
            placeholder="Sua chave de API"
          />

          <div v-if="form.configuration.auth_type === 'basic'" class="grid grid-cols-2 gap-4">
            <Input
              v-model="form.configuration.basic_username"
              label="Usuário"
              placeholder="username"
            />
            <Input
              v-model="form.configuration.basic_password"
              type="password"
              label="Senha"
              placeholder="password"
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Headers (JSON)</label>
            <textarea
              v-model="form.configuration.headers_json"
              rows="3"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 font-mono text-sm"
              placeholder='{"Content-Type": "application/json"}'
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Body Template (JSON)</label>
            <textarea
              v-model="form.configuration.body_template"
              rows="4"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 font-mono text-sm"
              placeholder='{"message": "{{message}}", "context": "{{context}}"}'
            />
            <p class="text-xs text-n-slate-10 mt-1">
              Use {{variavel}} para inserir valores dinâmicos
            </p>
          </div>
        </div>

        <!-- MCP Tool Configuration -->
        <div v-else-if="form.tool_type === 'mcp'" class="space-y-4">
          <Input
            v-model="form.configuration.server_url"
            label="URL do Servidor MCP"
            placeholder="stdio://path/to/server or ws://localhost:3000"
            required
          />

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Protocolo</label>
            <select
              v-model="form.configuration.protocol"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12"
              required
            >
              <option value="stdio">STDIO</option>
              <option value="ws">WebSocket</option>
              <option value="sse">Server-Sent Events</option>
            </select>
          </div>

          <Input
            v-model="form.configuration.tool_name"
            label="Nome da Ferramenta no Servidor"
            placeholder="Ex: get_weather"
            required
          />

          <div>
            <label class="block text-sm font-medium mb-2 text-n-slate-12">Argumentos (JSON Schema)</label>
            <textarea
              v-model="form.configuration.arguments_schema"
              rows="6"
              class="w-full px-3 py-2 border border-n-weak rounded bg-n-background text-n-slate-12 font-mono text-sm"
              placeholder='{"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]}'
            />
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end gap-3">
        <Button
          variant="ghost"
          label="Cancelar"
          @click="$emit('close')"
        />
        <Button
          type="submit"
          :is-loading="saving"
          :label="isEdit ? 'Salvar Alterações' : 'Criar Ferramenta'"
        />
      </div>
    </form>
  </div>
</template>

<script>
/* global axios */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

export default {
  name: 'ToolModal',
  components: {
    Button,
    Input,
  },
  props: {
    tool: {
      type: Object,
      default: null,
    },
    agentId: {
      type: [String, Number],
      required: true,
    },
  },
  emits: ['save', 'close'],
  data() {
    return {
      saving: false,
      form: {
        name: '',
        description: '',
        tool_type: 'native',
        configuration: {},
      },
      toolTypes: [
        {
          value: 'native',
          label: 'Nativa',
          icon: 'i-lucide-sparkles',
          description: 'Macros e agendamentos do Chatwoot',
        },
        {
          value: 'http',
          label: 'HTTP/HTTPS',
          icon: 'i-lucide-globe',
          description: 'APIs e serviços externos',
        },
        {
          value: 'mcp',
          label: 'MCP',
          icon: 'i-lucide-plug',
          description: 'Model Context Protocol',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    isEdit() {
      return !!this.tool;
    },
  },
  mounted() {
    if (this.tool) {
      this.form = {
        ...this.tool,
        configuration: { ...this.tool.configuration },
      };
    }
  },
  methods: {
    async saveTool() {
      try {
        this.saving = true;

        const endpoint = this.isEdit
          ? `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools/${this.tool.id}`
          : `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/tools`;

        const method = this.isEdit ? 'put' : 'post';

        await axios[method](endpoint, this.form);

        useAlert(this.isEdit ? 'Ferramenta atualizada com sucesso' : 'Ferramenta criada com sucesso');
        this.$emit('save');
      } catch (error) {
        useAlert('Erro ao salvar ferramenta');
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>
