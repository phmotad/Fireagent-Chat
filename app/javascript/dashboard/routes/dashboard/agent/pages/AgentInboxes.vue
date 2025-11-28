<template>
  <div class="flex flex-col h-full p-6">
    <div class="max-w-5xl">
      <div class="mb-6">
        <h2 class="text-2xl font-semibold mb-2 text-n-slate-12">
          Caixas de Entrada
        </h2>
        <p class="text-n-slate-11">
          Conecte o agente às caixas de entrada para atendimento automático
        </p>
      </div>

      <!-- Connected Inboxes -->
      <div class="bg-n-background rounded-lg border border-n-weak p-6 mb-6">
        <h3 class="text-lg font-medium mb-4 text-n-slate-12">Conectadas</h3>

        <div v-if="loading" class="text-center py-8">
          <woot-loading-state message="Carregando..." />
        </div>

        <div v-else-if="!connectedInboxes.length" class="text-center text-n-slate-10 py-8">
          Nenhuma inbox conectada ainda
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="inbox in connectedInboxes"
            :key="inbox.id"
            class="flex items-center justify-between p-4 border border-n-weak rounded-lg bg-n-solid-2"
          >
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-n-brand flex items-center justify-center text-white font-medium">
                {{ inbox.name.charAt(0).toUpperCase() }}
              </div>
              <div>
                <p class="font-medium text-n-slate-12">{{ inbox.name }}</p>
                <p class="text-sm text-n-slate-11">{{ inbox.channel_type }}</p>
              </div>
            </div>

            <Button
              v-if="isAdmin"
              variant="ghost"
              color="ruby"
              size="sm"
              icon="i-lucide-unlink"
              label="Desconectar"
              :is-loading="disconnecting[inbox.id]"
              @click="disconnectInbox(inbox.id)"
            />
          </div>
        </div>
      </div>

      <!-- Available Inboxes -->
      <div class="bg-n-background rounded-lg border border-n-weak p-6">
        <h3 class="text-lg font-medium mb-4 text-n-slate-12">Disponíveis</h3>

        <div v-if="loading" class="text-center py-8">
          <woot-loading-state message="Carregando..." />
        </div>

        <div v-else-if="!availableInboxes.length" class="text-center text-n-slate-10 py-8">
          Todas as inboxes já estão conectadas
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="inbox in availableInboxes"
            :key="inbox.id"
            class="flex items-center justify-between p-4 border border-n-weak rounded-lg hover:bg-n-solid-2 transition-colors"
          >
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-n-slate-6 flex items-center justify-center text-n-slate-12 font-medium">
                {{ inbox.name.charAt(0).toUpperCase() }}
              </div>
              <div>
                <p class="font-medium text-n-slate-12">{{ inbox.name }}</p>
                <p class="text-sm text-n-slate-11">{{ inbox.channel_type }}</p>
              </div>
            </div>

            <Button
              v-if="isAdmin"
              size="sm"
              icon="i-lucide-link"
              label="Conectar"
              :is-loading="connecting[inbox.id]"
              @click="connectInbox(inbox.id)"
            />
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
import { useAdmin } from 'dashboard/composables/useAdmin';
import Button from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'AgentInboxes',
  components: {
    Button,
  },
  data() {
    return {
      loading: false,
      connectedInboxes: [],
      availableInboxes: [],
      connecting: {},
      disconnecting: {},
    };
  },
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    agentId() {
      return this.$route.params.agentId;
    },
    isAdmin() {
      return useAdmin().isAdmin.value;
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    async fetchData() {
      try {
        this.loading = true;

        // Fetch connected inboxes
        const connectedRes = await axios.get(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/inboxes`
        );
        this.connectedInboxes = connectedRes.data;

        // Fetch all account inboxes
        const allRes = await axios.get(
          `/api/v1/accounts/${this.accountId}/inboxes`
        );

        // Filter out connected ones
        const connectedIds = new Set(this.connectedInboxes.map(i => i.id));
        this.availableInboxes = allRes.data.payload.filter(
          inbox => !connectedIds.has(inbox.id)
        );
      } catch (error) {
        useAlert('Erro ao carregar inboxes');
        console.error(error);
      } finally {
        this.loading = false;
      }
    },

    async connectInbox(inboxId) {
      try {
        this.$set(this.connecting, inboxId, true);

        await axios.post(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/inboxes`,
          { inbox_id: inboxId }
        );

        useAlert('Inbox conectada com sucesso');
        await this.fetchData();
      } catch (error) {
        useAlert('Erro ao conectar inbox');
        console.error(error);
      } finally {
        this.$set(this.connecting, inboxId, false);
      }
    },

    async disconnectInbox(inboxId) {
      try {
        this.$set(this.disconnecting, inboxId, true);

        await axios.delete(
          `/api/v1/accounts/${this.accountId}/ai_agents/${this.agentId}/inboxes/${inboxId}`
        );

        useAlert('Inbox desconectada');
        await this.fetchData();
      } catch (error) {
        useAlert('Erro ao desconectar inbox');
        console.error(error);
      } finally {
        this.$set(this.disconnecting, inboxId, false);
      }
    },
  },
};
</script>
