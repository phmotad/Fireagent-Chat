import { frontendURL } from '../../../helper/URLHelper';
import SettingsContent from '../settings/Wrapper.vue';
import SettingWrapper from '../settings/SettingsWrapper.vue';

const AgentIndex = () => import('./pages/AgentIndex.vue');
const AgentSettings = () => import('./pages/AgentSettings.vue');
const AgentInboxes = () => import('./pages/AgentInboxes.vue');
const AgentKnowledge = () => import('./pages/AgentKnowledge.vue');
const AgentTools = () => import('./pages/AgentTools.vue');

export default {
    routes: [
        {
            path: frontendURL('accounts/:accountId/agents'),
            component: SettingWrapper,
            children: [
                {
                    path: '',
                    name: 'agent_index',
                    component: AgentIndex,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
            ],
        },
        {
            path: frontendURL('accounts/:accountId/agents'),
            component: SettingsContent,
            props: () => ({
                headerTitle: 'AGENT.HEADER',
                icon: 'bot',
                showBackButton: true,
            }),
            children: [
                {
                    path: 'new',
                    name: 'agent_new',
                    component: AgentSettings,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                {
                    path: ':agentId',
                    redirect: to => ({
                        name: 'agent_settings',
                        params: to.params,
                    }),
                },
                {
                    path: ':agentId/settings',
                    name: 'agent_settings',
                    component: AgentSettings,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                {
                    path: ':agentId/inboxes',
                    name: 'agent_inboxes',
                    component: AgentInboxes,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                {
                    path: ':agentId/knowledge',
                    name: 'agent_knowledge',
                    component: AgentKnowledge,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
                {
                    path: ':agentId/tools',
                    name: 'agent_tools',
                    component: AgentTools,
                    meta: {
                        permissions: ['administrator'],
                    },
                },
            ],
        },
    ],
};
