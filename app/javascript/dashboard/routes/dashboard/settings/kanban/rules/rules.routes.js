import { frontendURL } from '../../../../../helper/URLHelper';

import SettingsWrapper from '../../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/kanban/rules'),
      component: SettingsWrapper,
      props: {
        fullWidth: false,
      },
      children: [
        {
          path: '',
          name: 'kanban_rules_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};

