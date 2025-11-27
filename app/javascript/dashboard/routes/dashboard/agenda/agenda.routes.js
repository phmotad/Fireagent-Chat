import { frontendURL } from 'dashboard/helper/URLHelper';
import AgendaPage from './pages/AgendaPage.vue';
import {
  ROLES,
} from 'dashboard/constants/permissions.js';

const commonMeta = {
  permissions: [...ROLES],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/agenda'),
      name: 'agenda_index',
      component: AgendaPage,
      meta: commonMeta,
    },
  ],
};

