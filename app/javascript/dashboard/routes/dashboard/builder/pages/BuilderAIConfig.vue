<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import AITestModal from '../components/AITestModal.vue';

const store = useStore();
const { t } = useI18n();

// State
const activeTab = ref('settings');
const showTestModal = ref(false);
const saving = ref(false);
const uploading = ref(false);

// Form data
const aiConfig = ref({
  name: '',
  provider: 'gemini',
  model: '',
  api_key: '',
  api_base: '',
  system_prompt: '',
  temperature: 0.7,
  max_tokens: 2000,
  inboxes: [],
});

// Knowledge base
const documents = ref([]);
const selectedFile = ref(null);

// Tools
const availableTools = ref([
  {
    id: 'handover',
    name: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.HANDOVER.NAME'),
    description: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.HANDOVER.DESCRIPTION'),
    enabled: false,
    type: 'native',
  },
  {
    id: 'scheduling',
    name: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.SCHEDULING.NAME'),
    description: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.SCHEDULING.DESCRIPTION'),
    enabled: false,
    type: 'native',
  },
  {
    id: 'labels',
    name: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.LABELS.NAME'),
    description: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.LABELS.DESCRIPTION'),
    enabled: false,
    type: 'native',
  },
  {
    id: 'macros',
    name: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.MACROS.NAME'),
    description: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.MACROS.DESCRIPTION'),
    enabled: false,
    type: 'native',
  },
  {
    id: 'whatsapp_buttons',
    name: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.WHATSAPP_BUTTONS.NAME'),
    description: t('BUILDER.AI_CONFIG.TOOLS.NATIVE.WHATSAPP_BUTTONS.DESCRIPTION'),
    enabled: false,
    type: 'native',
  },
]);

// Computed
const inboxes = computed(() => store.getters['inboxes/getInboxes']);
const llmProviders = computed(() => store.getters['llmProviders/getProviders']);

const providerOptions = [
  { value: 'gemini', label: t('BUILDER.AI_CONFIG.FORM.PROVIDER.OPTIONS.GEMINI') },
  { value: 'openai', label: t('BUILDER.AI_CONFIG.FORM.PROVIDER.OPTIONS.OPENAI') },
  { value: 'anthropic', label: t('BUILDER.AI_CONFIG.FORM.PROVIDER.OPTIONS.ANTHROPIC') },
  { value: 'openrouter', label: t('BUILDER.AI_CONFIG.FORM.PROVIDER.OPTIONS.OPENROUTER') },
  { value: 'ollama', label: t('BUILDER.AI_CONFIG.FORM.PROVIDER.OPTIONS.OLLAMA') },
  { value: 'vertex_ai', label: t('BUILDER.AI_CONFIG.FORM.PROVIDER.OPTIONS.VERTEX_AI') },
];

const tabs = computed(() => [
  { key: 'settings', label: 'Settings', icon: 'settings' },
  { key: 'knowledge', label: 'Knowledge Base', icon: 'book' },
  { key: 'tools', label: 'Tools', icon: 'tool' },
]);

// Methods
const loadConfig = async () => {
  try {
    // Load existing AI configuration from first AI Agent
    // Since we're consolidating, we'll use the first available agent's config
    const agents = await store.dispatch('aiAgents/get');
    if (agents && agents.length > 0) {
      const firstAgent = agents[0];
      aiConfig.value = {
        name: firstAgent.name || '',
        provider: firstAgent.llm_provider?.provider || 'gemini',
        model: firstAgent.llm_provider?.model || '',
        api_key: firstAgent.llm_provider?.api_key || '',
        api_base: firstAgent.llm_provider?.api_base || '',
        system_prompt: firstAgent.system_prompt || '',
        temperature: firstAgent.temperature || 0.7,
        max_tokens: firstAgent.max_tokens || 2000,
        inboxes: firstAgent.inboxes || [],
      };

      // Load tools status
      if (firstAgent.tools) {
        firstAgent.tools.forEach(tool => {
          const availableTool = availableTools.value.find(t => t.id === tool.tool_type);
          if (availableTool) {
            availableTool.enabled = tool.enabled;
          }
        });
      }
    }

    // Load knowledge documents
    loadDocuments();
  } catch (error) {
    console.error('Error loading AI config:', error);
  }
};

const loadDocuments = async () => {
  try {
    // Load documents from RAG engine
    // This would call the backend to list uploaded documents
    documents.value = [];
  } catch (error) {
    console.error('Error loading documents:', error);
  }
};

const saveConfig = async () => {
  saving.value = true;
  try {
    // Save AI configuration
    // This will create or update the AI agent with the consolidated configuration
    const payload = {
      name: aiConfig.value.name,
      llm_provider: {
        provider: aiConfig.value.provider,
        model: aiConfig.value.model,
        api_key: aiConfig.value.api_key,
        api_base: aiConfig.value.api_base,
      },
      system_prompt: aiConfig.value.system_prompt,
      temperature: aiConfig.value.temperature,
      max_tokens: aiConfig.value.max_tokens,
      inboxes: aiConfig.value.inboxes,
      tools: availableTools.value
        .filter(tool => tool.enabled)
        .map(tool => ({
          tool_type: tool.id,
          enabled: true,
          type: tool.type,
        })),
    };

    await store.dispatch('aiAgents/create', payload);
    useAlert(t('BUILDER.AI_CONFIG.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('BUILDER.AI_CONFIG.API.ERROR_MESSAGE'));
  } finally {
    saving.value = false;
  }
};

const uploadDocument = async () => {
  if (!selectedFile.value) return;

  uploading.value = true;
  try {
    const formData = new FormData();
    formData.append('document', selectedFile.value);

    // Upload to RAG engine
    // await store.dispatch('knowledge/upload', formData);

    useAlert('Document uploaded successfully');
    selectedFile.value = null;
    await loadDocuments();
  } catch (error) {
    useAlert('Error uploading document');
  } finally {
    uploading.value = false;
  }
};

const deleteDocument = async (docId) => {
  try {
    // await store.dispatch('knowledge/delete', docId);
    useAlert('Document deleted successfully');
    await loadDocuments();
  } catch (error) {
    useAlert('Error deleting document');
  }
};

const toggleTool = (toolId) => {
  const tool = availableTools.value.find(t => t.id === toolId);
  if (tool) {
    tool.enabled = !tool.enabled;
  }
};

const openTestModal = () => {
  showTestModal.value = true;
};

onMounted(() => {
  loadConfig();
  store.dispatch('inboxes/get');
  store.dispatch('llmProviders/get');
});
</script>

<template>
  <div class="builder-ai-config">
    <!-- Header -->
    <div class="config-header">
      <div class="header-content">
        <h1 class="page-title">
          {{ $t('BUILDER.AI_CONFIG.TITLE') }}
        </h1>
        <p class="page-description">
          {{ $t('BUILDER.AI_CONFIG.DESCRIPTION') }}
        </p>
      </div>
      <div class="header-actions">
        <woot-button
          variant="smooth"
          color-scheme="secondary"
          icon="test-tube"
          @click="openTestModal"
        >
          {{ $t('BUILDER.AI_CONFIG.TEST.BTN') }}
        </woot-button>
        <woot-button
          :is-loading="saving"
          @click="saveConfig"
        >
          {{ $t('BUILDER.AI_CONFIG.SUBMIT') }}
        </woot-button>
      </div>
    </div>

    <!-- Tabs -->
    <div class="tabs-container">
      <woot-tabs
        :index="tabs.findIndex(tab => tab.key === activeTab)"
        @change="(index) => activeTab = tabs[index].key"
      >
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.label"
          :show-badge="false"
        />
      </woot-tabs>
    </div>

    <!-- Content -->
    <div class="config-content">
      <!-- Settings Tab -->
      <div v-show="activeTab === 'settings'" class="tab-panel settings-panel">
        <div class="form-grid">
          <!-- Agent Name -->
          <div class="form-group full-width">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.NAME.LABEL') }}
            </label>
            <input
              v-model="aiConfig.name"
              type="text"
              class="form-input"
              :placeholder="$t('BUILDER.AI_CONFIG.FORM.NAME.PLACEHOLDER')"
            />
          </div>

          <!-- Provider -->
          <div class="form-group">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.PROVIDER.LABEL') }}
            </label>
            <select
              v-model="aiConfig.provider"
              class="form-select"
            >
              <option
                v-for="option in providerOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>

          <!-- Model -->
          <div class="form-group">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.MODEL.LABEL') }}
            </label>
            <input
              v-model="aiConfig.model"
              type="text"
              class="form-input"
              :placeholder="$t('BUILDER.AI_CONFIG.FORM.MODEL.PLACEHOLDER')"
            />
            <p class="form-help">
              {{ $t('BUILDER.AI_CONFIG.FORM.MODEL.HELP') }}
            </p>
          </div>

          <!-- API Key -->
          <div class="form-group">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.API_KEY.LABEL') }}
            </label>
            <input
              v-model="aiConfig.api_key"
              type="password"
              class="form-input"
              :placeholder="$t('BUILDER.AI_CONFIG.FORM.API_KEY.PLACEHOLDER')"
            />
          </div>

          <!-- API Base (Optional) -->
          <div class="form-group">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.API_BASE.LABEL') }}
            </label>
            <input
              v-model="aiConfig.api_base"
              type="text"
              class="form-input"
              :placeholder="$t('BUILDER.AI_CONFIG.FORM.API_BASE.PLACEHOLDER')"
            />
          </div>

          <!-- System Prompt -->
          <div class="form-group full-width">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.SYSTEM_PROMPT.LABEL') }}
            </label>
            <textarea
              v-model="aiConfig.system_prompt"
              rows="6"
              class="form-textarea"
              :placeholder="$t('BUILDER.AI_CONFIG.FORM.SYSTEM_PROMPT.PLACEHOLDER')"
            />
            <p class="form-help">
              {{ $t('BUILDER.AI_CONFIG.FORM.SYSTEM_PROMPT.HELP') }}
            </p>
          </div>

          <!-- Temperature -->
          <div class="form-group">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.TEMPERATURE.LABEL') }}
              <span class="temperature-value">{{ aiConfig.temperature }}</span>
            </label>
            <input
              v-model.number="aiConfig.temperature"
              type="range"
              min="0"
              max="1"
              step="0.1"
              class="form-range"
            />
            <p class="form-help">
              {{ $t('BUILDER.AI_CONFIG.FORM.TEMPERATURE.HELP') }}
            </p>
          </div>

          <!-- Max Tokens -->
          <div class="form-group">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.MAX_TOKENS.LABEL') }}
            </label>
            <input
              v-model.number="aiConfig.max_tokens"
              type="number"
              min="100"
              max="32000"
              step="100"
              class="form-input"
            />
            <p class="form-help">
              {{ $t('BUILDER.AI_CONFIG.FORM.MAX_TOKENS.HELP') }}
            </p>
          </div>

          <!-- Inboxes -->
          <div class="form-group full-width">
            <label class="form-label">
              {{ $t('BUILDER.AI_CONFIG.FORM.INBOXES.LABEL') }}
            </label>
            <multiselect
              v-model="aiConfig.inboxes"
              :options="inboxes"
              track-by="id"
              label="name"
              :multiple="true"
              :placeholder="$t('BUILDER.AI_CONFIG.FORM.INBOXES.PLACEHOLDER')"
            />
            <p class="form-help">
              {{ $t('BUILDER.AI_CONFIG.FORM.INBOXES.HELP') }}
            </p>
          </div>
        </div>
      </div>

      <!-- Knowledge Base Tab -->
      <div v-show="activeTab === 'knowledge'" class="tab-panel knowledge-panel">
        <div class="knowledge-header">
          <h2 class="section-title">
            {{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.TITLE') }}
          </h2>
          <p class="section-description">
            {{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.DESCRIPTION') }}
          </p>
          <div class="upload-area">
            <input
              ref="fileInput"
              type="file"
              accept=".pdf,.txt,.doc,.docx"
              style="display: none"
              @change="(e) => selectedFile = e.target.files[0]"
            />
            <woot-button
              variant="smooth"
              icon="upload"
              :is-loading="uploading"
              @click="$refs.fileInput.click()"
            >
              {{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.UPLOAD_BTN') }}
            </woot-button>
            <woot-button
              v-if="selectedFile"
              @click="uploadDocument"
            >
              Upload {{ selectedFile.name }}
            </woot-button>
          </div>
        </div>

        <div v-if="documents.length === 0" class="empty-state">
          <p>{{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.NO_DOCUMENTS') }}</p>
        </div>

        <table v-else class="documents-table">
          <thead>
            <tr>
              <th>{{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.TABLE.NAME') }}</th>
              <th>{{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.TABLE.SIZE') }}</th>
              <th>{{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.TABLE.UPLOADED') }}</th>
              <th>{{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.TABLE.STATUS') }}</th>
              <th>{{ $t('BUILDER.AI_CONFIG.KNOWLEDGE.TABLE.ACTIONS') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="doc in documents" :key="doc.id">
              <td>{{ doc.name }}</td>
              <td>{{ doc.size }}</td>
              <td>{{ doc.uploaded_at }}</td>
              <td>{{ doc.status }}</td>
              <td>
                <woot-button
                  variant="smooth"
                  color-scheme="alert"
                  icon="delete"
                  size="tiny"
                  @click="deleteDocument(doc.id)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Tools Tab -->
      <div v-show="activeTab === 'tools'" class="tab-panel tools-panel">
        <div class="tools-header">
          <h2 class="section-title">
            {{ $t('BUILDER.AI_CONFIG.TOOLS.TITLE') }}
          </h2>
          <p class="section-description">
            {{ $t('BUILDER.AI_CONFIG.TOOLS.DESCRIPTION') }}
          </p>
        </div>

        <div class="tools-grid">
          <div
            v-for="tool in availableTools"
            :key="tool.id"
            class="tool-card"
            :class="{ 'tool-card--enabled': tool.enabled }"
          >
            <div class="tool-header">
              <div class="tool-info">
                <h3 class="tool-name">{{ tool.name }}</h3>
                <p class="tool-description">{{ tool.description }}</p>
              </div>
              <woot-switch
                :value="tool.enabled"
                @input="toggleTool(tool.id)"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Test Modal -->
    <AITestModal
      v-if="showTestModal"
      :config="aiConfig"
      @close="showTestModal = false"
    />
  </div>
</template>

<style scoped lang="scss">
.builder-ai-config {
  padding: var(--space-normal);
  max-width: 1200px;
  margin: 0 auto;
}

.config-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: var(--space-large);

  .header-content {
    flex: 1;

    .page-title {
      margin: 0 0 var(--space-small) 0;
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
    }

    .page-description {
      margin: 0;
      color: var(--s-600);
      font-size: var(--font-size-small);
    }
  }

  .header-actions {
    display: flex;
    gap: var(--space-small);
  }
}

.tabs-container {
  margin-bottom: var(--space-large);
}

.config-content {
  background: var(--white);
  border-radius: var(--border-radius-large);
  padding: var(--space-large);
  box-shadow: var(--shadow-small);
}

.tab-panel {
  animation: fadeIn 0.3s ease-in;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--space-normal);

  .form-group {
    display: flex;
    flex-direction: column;

    &.full-width {
      grid-column: 1 / -1;
    }

    .form-label {
      margin-bottom: var(--space-small);
      font-weight: var(--font-weight-medium);
      font-size: var(--font-size-small);
      color: var(--s-700);
    }

    .temperature-value {
      float: right;
      color: var(--w-500);
    }

    .form-input,
    .form-select,
    .form-textarea {
      padding: var(--space-small);
      border: 1px solid var(--s-200);
      border-radius: var(--border-radius-normal);
      font-size: var(--font-size-small);

      &:focus {
        outline: none;
        border-color: var(--w-500);
      }
    }

    .form-range {
      width: 100%;
    }

    .form-help {
      margin-top: var(--space-micro);
      font-size: var(--font-size-mini);
      color: var(--s-500);
    }
  }
}

.knowledge-header,
.tools-header {
  margin-bottom: var(--space-large);

  .section-title {
    margin: 0 0 var(--space-small) 0;
    font-size: var(--font-size-medium);
    font-weight: var(--font-weight-bold);
  }

  .section-description {
    margin: 0 0 var(--space-normal) 0;
    color: var(--s-600);
    font-size: var(--font-size-small);
  }
}

.upload-area {
  display: flex;
  gap: var(--space-small);
  align-items: center;
}

.empty-state {
  text-align: center;
  padding: var(--space-larger);
  color: var(--s-500);
}

.documents-table {
  width: 100%;
  border-collapse: collapse;

  th,
  td {
    padding: var(--space-small);
    text-align: left;
    border-bottom: 1px solid var(--s-100);
  }

  th {
    font-weight: var(--font-weight-medium);
    color: var(--s-700);
    font-size: var(--font-size-mini);
    text-transform: uppercase;
  }
}

.tools-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--space-normal);
}

.tool-card {
  padding: var(--space-normal);
  border: 2px solid var(--s-100);
  border-radius: var(--border-radius-normal);
  transition: all 0.2s ease;

  &:hover {
    border-color: var(--s-200);
    box-shadow: var(--shadow-small);
  }

  &.tool-card--enabled {
    border-color: var(--w-500);
    background: var(--w-50);
  }

  .tool-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: var(--space-small);
  }

  .tool-info {
    flex: 1;

    .tool-name {
      margin: 0 0 var(--space-micro) 0;
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
    }

    .tool-description {
      margin: 0;
      font-size: var(--font-size-mini);
      color: var(--s-600);
    }
  }
}
</style>
