import { frontendURL } from '../../../../../helper/URLHelper';

import SettingsWrapper from '../../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/kanban/locations'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'kanban_locations_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};

