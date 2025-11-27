import { frontendURL } from 'dashboard/helper/URLHelper';
import KanbanIndexPage from './pages/KanbanIndexPage.vue';
import KanbanBoardView from './pages/KanbanBoardView.vue';
import KanbanBookingsPage from './pages/KanbanBookingsPage.vue';
import KanbanSchedulingSettingsPage from './pages/KanbanSchedulingSettingsPage.vue';
import KanbanArchivedCardsPage from './pages/KanbanArchivedCardsPage.vue';
import {
  ROLES,
} from 'dashboard/constants/permissions.js';

const commonMeta = {
  permissions: [...ROLES],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/kanban'),
      name: 'kanban_index',
      component: KanbanIndexPage,
      meta: commonMeta,
    },
    {
      path: frontendURL('accounts/:accountId/kanban/:boardId'),
      name: 'kanban_board',
      component: KanbanBoardView,
      meta: commonMeta,
    },
    {
      path: frontendURL('accounts/:accountId/kanban/:boardId/archived'),
      name: 'kanban_archived_cards',
      component: KanbanArchivedCardsPage,
      meta: commonMeta,
    },
    {
      path: frontendURL('accounts/:accountId/kanban/bookings'),
      name: 'kanban_bookings',
      component: KanbanBookingsPage,
      meta: commonMeta,
    },
    {
      path: frontendURL('accounts/:accountId/kanban/settings/scheduling'),
      name: 'kanban_scheduling_settings',
      component: KanbanSchedulingSettingsPage,
      meta: commonMeta,
    },
  ],
};

