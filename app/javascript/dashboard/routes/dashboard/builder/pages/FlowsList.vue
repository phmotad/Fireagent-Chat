<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

// State
const searchQuery = ref('');
const loading = ref(true);

// Computed
const flows = computed(() => store.getters['whatsappFlows/getFlows']);

const filteredFlows = computed(() => {
  if (!searchQuery.value) return flows.value;

  const query = searchQuery.value.toLowerCase();
  return flows.value.filter(flow =>
    flow.name.toLowerCase().includes(query) ||
    flow.description?.toLowerCase().includes(query)
  );
});

const statusBadgeClass = (status) => {
  const classes = {
    draft: 'badge--draft',
    active: 'badge--active',
    archived: 'badge--archived',
  };
  return classes[status] || '';
};

// Methods
const loadFlows = async () => {
  loading.value = true;
  try {
    await store.dispatch('whatsappFlows/get');
  } catch (error) {
    console.error('Error loading flows:', error);
    useAlert('Error loading flows');
  } finally {
    loading.value = false;
  }
};

const createFlow = () => {
  router.push({ name: 'builder_flows_new' });
};

const editFlow = (flowId) => {
  router.push({ name: 'builder_flows_edit', params: { flowId } });
};

const duplicateFlow = async (flow) => {
  try {
    const duplicated = {
      ...flow,
      name: `${flow.name} (Copy)`,
      status: 'draft',
    };
    delete duplicated.id;

    await store.dispatch('whatsappFlows/create', duplicated);
    useAlert('Flow duplicated successfully');
    await loadFlows();
  } catch (error) {
    useAlert('Error duplicating flow');
  }
};

const deleteFlow = async (flowId) => {
  if (!confirm('Are you sure you want to delete this flow?')) return;

  try {
    await store.dispatch('whatsappFlows/delete', flowId);
    useAlert('Flow deleted successfully');
  } catch (error) {
    useAlert('Error deleting flow');
  }
};

const toggleStatus = async (flow) => {
  const newStatus = flow.status === 'active' ? 'draft' : 'active';

  try {
    await store.dispatch('whatsappFlows/update', {
      id: flow.id,
      status: newStatus,
    });
    useAlert(`Flow ${newStatus === 'active' ? 'activated' : 'deactivated'}`);
  } catch (error) {
    useAlert('Error updating flow status');
  }
};

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

onMounted(() => {
  loadFlows();
});
</script>

<template>
  <div class="flows-list">
    <!-- Header -->
    <div class="list-header">
      <div class="header-content">
        <h1 class="page-title">
          {{ $t('BUILDER.FLOWS.TITLE') }}
        </h1>
        <p class="page-description">
          {{ $t('BUILDER.FLOWS.DESCRIPTION') }}
        </p>
      </div>
      <div class="header-actions">
        <woot-button
          icon="add"
          @click="createFlow"
        >
          {{ $t('BUILDER.HEADER_BTN_TXT') }}
        </woot-button>
      </div>
    </div>

    <!-- Search Bar -->
    <div class="search-bar">
      <input
        v-model="searchQuery"
        type="text"
        class="search-input"
        :placeholder="$t('BUILDER.FLOWS.LIST.SEARCH')"
      />
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <spinner size="" />
      <p>Loading flows...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="flows.length === 0" class="empty-state">
      <div class="empty-icon">
        <i class="icon-git-branch" />
      </div>
      <h3 class="empty-title">
        {{ $t('BUILDER.FLOWS.LIST.NO_FLOWS') }}
      </h3>
      <p class="empty-description">
        {{ $t('BUILDER.FLOWS.LIST.CREATE') }}
      </p>
      <woot-button
        icon="add"
        @click="createFlow"
      >
        {{ $t('BUILDER.HEADER_BTN_TXT') }}
      </woot-button>
    </div>

    <!-- Flows Table -->
    <div v-else class="flows-table-container">
      <table class="flows-table">
        <thead>
          <tr>
            <th>{{ $t('BUILDER.FLOWS.LIST.TABLE.NAME') }}</th>
            <th>{{ $t('BUILDER.FLOWS.LIST.TABLE.STATUS') }}</th>
            <th>{{ $t('BUILDER.FLOWS.LIST.TABLE.INBOX') }}</th>
            <th>{{ $t('BUILDER.FLOWS.LIST.TABLE.TRIGGER') }}</th>
            <th>{{ $t('BUILDER.FLOWS.LIST.TABLE.UPDATED') }}</th>
            <th>{{ $t('BUILDER.FLOWS.LIST.TABLE.ACTIONS') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="flow in filteredFlows"
            :key="flow.id"
            class="flow-row"
            @click="editFlow(flow.id)"
          >
            <td class="flow-name-cell">
              <div class="flow-info">
                <span class="flow-name">{{ flow.name }}</span>
                <span v-if="flow.description" class="flow-description">
                  {{ flow.description }}
                </span>
              </div>
            </td>
            <td>
              <span
                class="status-badge"
                :class="statusBadgeClass(flow.status)"
              >
                {{ $t(`BUILDER.FLOWS.LIST.STATUS.${flow.status.toUpperCase()}`) }}
              </span>
            </td>
            <td>
              <span v-if="flow.inbox">
                {{ flow.inbox.name }}
              </span>
              <span v-else class="text-muted">
                All inboxes
              </span>
            </td>
            <td>
              <span class="trigger-type">
                {{ flow.trigger_type || 'Manual' }}
              </span>
            </td>
            <td>
              <span class="date-text">
                {{ formatDate(flow.updated_at) }}
              </span>
            </td>
            <td class="actions-cell" @click.stop>
              <div class="action-buttons">
                <woot-button
                  variant="smooth"
                  size="tiny"
                  icon="edit"
                  @click="editFlow(flow.id)"
                />
                <woot-button
                  variant="smooth"
                  size="tiny"
                  :icon="flow.status === 'active' ? 'pause' : 'play'"
                  @click="toggleStatus(flow)"
                />
                <woot-button
                  variant="smooth"
                  size="tiny"
                  icon="copy"
                  @click="duplicateFlow(flow)"
                />
                <woot-button
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="delete"
                  @click="deleteFlow(flow.id)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- No Results -->
      <div v-if="filteredFlows.length === 0" class="no-results">
        <p>No flows match your search</p>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.flows-list {
  padding: var(--space-normal);
  max-width: 1400px;
  margin: 0 auto;
}

.list-header {
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

.search-bar {
  margin-bottom: var(--space-normal);

  .search-input {
    width: 100%;
    max-width: 400px;
    padding: var(--space-small);
    border: 1px solid var(--s-200);
    border-radius: var(--border-radius-normal);
    font-size: var(--font-size-small);

    &:focus {
      outline: none;
      border-color: var(--w-500);
    }
  }
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-larger);
  color: var(--s-500);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-larger) var(--space-normal);
  text-align: center;
  background: var(--white);
  border-radius: var(--border-radius-large);
  box-shadow: var(--shadow-small);

  .empty-icon {
    font-size: 64px;
    color: var(--s-300);
    margin-bottom: var(--space-normal);

    i {
      font-size: inherit;
    }
  }

  .empty-title {
    margin: 0 0 var(--space-small) 0;
    font-size: var(--font-size-medium);
    font-weight: var(--font-weight-bold);
  }

  .empty-description {
    margin: 0 0 var(--space-normal) 0;
    color: var(--s-600);
    font-size: var(--font-size-small);
  }
}

.flows-table-container {
  background: var(--white);
  border-radius: var(--border-radius-large);
  box-shadow: var(--shadow-small);
  overflow: hidden;
}

.flows-table {
  width: 100%;
  border-collapse: collapse;

  thead {
    background: var(--s-50);

    th {
      padding: var(--space-small) var(--space-normal);
      text-align: left;
      font-weight: var(--font-weight-medium);
      font-size: var(--font-size-mini);
      color: var(--s-700);
      text-transform: uppercase;
      border-bottom: 1px solid var(--s-100);
    }
  }

  tbody {
    .flow-row {
      cursor: pointer;
      transition: background-color 0.2s ease;

      &:hover {
        background: var(--s-25);
      }

      &:not(:last-child) {
        border-bottom: 1px solid var(--s-50);
      }

      td {
        padding: var(--space-normal);
        font-size: var(--font-size-small);
      }

      .flow-name-cell {
        .flow-info {
          display: flex;
          flex-direction: column;
          gap: var(--space-micro);

          .flow-name {
            font-weight: var(--font-weight-medium);
            color: var(--s-900);
          }

          .flow-description {
            font-size: var(--font-size-mini);
            color: var(--s-500);
          }
        }
      }

      .status-badge {
        display: inline-flex;
        align-items: center;
        padding: var(--space-micro) var(--space-small);
        border-radius: var(--border-radius-small);
        font-size: var(--font-size-mini);
        font-weight: var(--font-weight-medium);

        &.badge--draft {
          background: var(--s-100);
          color: var(--s-700);
        }

        &.badge--active {
          background: var(--g-100);
          color: var(--g-800);
        }

        &.badge--archived {
          background: var(--y-100);
          color: var(--y-800);
        }
      }

      .trigger-type {
        color: var(--s-600);
        font-size: var(--font-size-mini);
      }

      .date-text {
        color: var(--s-600);
        font-size: var(--font-size-mini);
      }

      .text-muted {
        color: var(--s-400);
        font-style: italic;
      }

      .actions-cell {
        .action-buttons {
          display: flex;
          gap: var(--space-micro);
          opacity: 0;
          transition: opacity 0.2s ease;
        }
      }

      &:hover .action-buttons {
        opacity: 1;
      }
    }
  }
}

.no-results {
  padding: var(--space-large);
  text-align: center;
  color: var(--s-500);
}
</style>
